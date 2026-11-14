import csv,hashlib,json,os,pathlib,signal,subprocess,sys,time
root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-14-policy-factorial');src=pathlib.Path('/home/snakagaw/hsq_work/clade-factorial')
env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4');children=[];logs=[];started=time.monotonic()
def interrupted(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupted)
try:
 for k in range(8):
  out=root/f'shard-{k}'; log=open(root/f'shard-{k}.log','w');logs.append(log)
  cmd=['/usr/bin/time','-v','-o',str(root/f'shard-{k}.time'),'/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','factorial.jl',str(out),str(20001+12*k+min(k,4)),str(13 if k<4 else 12)]
  children.append(subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True))
 while any(p.poll() is None for p in children):
  if any(p.poll() not in (None,0) for p in children):raise RuntimeError('worker failed')
  if time.monotonic()-started>900:raise TimeoutError('15 minute estimate exceeded')
  time.sleep(2)
 if any(p.returncode for p in children):raise RuntimeError('worker failed')
 full=root/'full';full.mkdir()
 for name in ('runs','windows'):
  with open(full/(name+'.csv'),'w') as dest:
   header=None
   for k in range(8):
    with open(root/f'shard-{k}'/(name+'.csv')) as f:
     line=f.readline()
     if header is None:header=line;dest.write(line)
     elif header!=line:raise ValueError('header mismatch')
     for line in f:dest.write(line)
 with open(full/'runs.csv') as f:rows=list(csv.DictReader(f))
 keys={(int(r['ploidy']),float(r['food_rate']),r['age_mode'],int(r['seed']),int(r['mono'])) for r in rows}
 assert len(rows)==len(keys)==10800
 (root/'execution.json').write_text(json.dumps({'wall_seconds':time.monotonic()-started,'source_commit':'2b6ea12bbbccf06f62e700edf5653eeb7c950cc6','driver_sha256':hashlib.sha256((src/'factorial.jl').read_bytes()).hexdigest(),'patched_assay_sha256':hashlib.sha256((src/'inst/julia/scripts/mixture_assay.jl').read_bytes()).hexdigest(),'threads_per_worker':4,'workers':8,'blas_threads':1},indent=2))
 (root/'job.done').write_text('compute complete; analysis and checks pending\n')
finally:
 for p in children:
  if p.poll() is None:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
 for p in children:
  try:p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
 for f in logs:f.close()
