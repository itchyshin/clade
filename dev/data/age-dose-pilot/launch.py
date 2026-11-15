import json, os, pathlib, signal, subprocess, time
root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-15-age-dose-pilot/full')
root.mkdir(parents=True,exist_ok=False)
src=pathlib.Path('/home/snakagaw/hsq_work/clade-age-dose-pilot')
env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4')
children=[];logs=[];start=time.monotonic()
def interrupt(s,f): raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupt)
try:
 for seed,mode in [(x,'pilot') for x in range(81001,81006)]+[(71001,'replay')]:
  log=open(root/f'{seed}.log','w');logs.append(log)
  cmd=['/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','driver.jl',str(root/str(seed)),str(seed),mode]
  children.append(subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True))
 while any(p.poll() is None for p in children):
  if any(p.poll() not in (None,0) for p in children):raise RuntimeError('worker failed')
  if time.monotonic()-start>600:raise TimeoutError('estimate exceeded')
  time.sleep(2)
 if any(p.returncode for p in children):raise RuntimeError('worker failed')
 (root/'execution.json').write_text(json.dumps({'seconds':time.monotonic()-start,'workers':6,'julia_threads':4,'blas_threads':1,'pilot_seeds':list(range(81001,81006)),'replay_seed':71001},indent=2)+'\n')
finally:
 for p in children:
  if p.poll() is None:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
 for p in children:
  try:p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
 for f in logs:f.close()
