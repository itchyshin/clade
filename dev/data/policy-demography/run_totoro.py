import csv,hashlib,json,os,pathlib,signal,subprocess,time
root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-14-policy-demography');src=pathlib.Path('/home/snakagaw/hsq_work/clade-demography');states='/home/snakagaw/sim-archive/clade/2026-11-14-performance-corrected/full-100/states';env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4');children=[];logs=[];start=time.monotonic()
def interrupted(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupted)
try:
 for k in range(8):
  out=root/f'shard-{k}';log=open(root/f'shard-{k}.log','w');logs.append(log)
  cmd=['/usr/bin/time','-v','-o',str(root/f'shard-{k}.time'),'/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','intervene.jl',str(13 if k<4 else 12),str(20001+12*k+min(k,4)),str(out),states]
  children.append(subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True))
 while any(p.poll() is None for p in children):
  if any(p.poll() not in (None,0) for p in children):raise RuntimeError('worker failed')
  if time.monotonic()-start>480:raise TimeoutError('eight-minute estimate exceeded')
  time.sleep(2)
 if any(p.returncode for p in children):raise RuntimeError('worker failed')
 full=root/'full';full.mkdir()
 with open(full/'runs.csv','w') as out:
  header=None
  for k in range(8):
   with open(root/f'shard-{k}'/'runs.csv') as f:
    line=f.readline()
    if header is None:header=line;out.write(line)
    elif line!=header:raise ValueError('header mismatch')
    for line in f:out.write(line)
 with open(full/'runs.csv') as f:rows=list(csv.DictReader(f))
 keys={(int(x['seed']),x['mode'],int(x['tick'])) for x in rows}
 expected={(s,m,t) for s in range(20001,20101) for m in ('natural','shuffle','balanced') for t in range(50,1001,50)}
 assert len(rows)==len(keys)==6000 and keys==expected
 (root/'execution.json').write_text(json.dumps({'wall_seconds':time.monotonic()-start,'source_commit':'2b6ea12bbbccf06f62e700edf5653eeb7c950cc6','driver_sha256':hashlib.sha256((src/'intervene.jl').read_bytes()).hexdigest(),'hooked_kernel_sha256':hashlib.sha256((src/'inst/julia/src/Clade.jl').read_bytes()).hexdigest(),'workers':8,'julia_threads':4,'blas_threads':1},indent=2)+'\n')
 (root/'job.done').write_text('compute complete; scientific audit pending\n')
finally:
 for p in children:
  if p.poll() is None:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
 for p in children:
  try:p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
 for f in logs:f.close()
