import csv,hashlib,json,os,pathlib,signal,subprocess,sys,time
stage=sys.argv[1];deadline=int(sys.argv[2]);root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-15-age-reproduction-causal')/stage;root.mkdir(parents=True,exist_ok=False)
src=pathlib.Path('/home/snakagaw/hsq_work/clade-age-causal');env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4');children=[];logs=[];start=time.monotonic()
if stage=='pilot': jobs=[(70001,1,g) for g in ('sham','young','old','both')]+[(61001,1,'sham')]
elif stage=='full':
 jobs=[];first=71001
 for k in range(24):
  n=100//24+(k<100%24);jobs.append((first,n,'sham:young:old:both'));first+=n
else:raise ValueError('invalid stage')
def interrupted(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupted)
try:
 for k,(first,n,modes) in enumerate(jobs):
  out=root/f'shard-{k}';log=open(root/f'shard-{k}.log','w');logs.append(log)
  cmd=['/usr/bin/time','-v','-o',str(root/f'shard-{k}.time'),'/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','driver.jl',str(out),str(first),str(n),modes]
  children.append(subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True))
 while any(p.poll() is None for p in children):
  if any(p.poll() not in (None,0) for p in children):raise RuntimeError('worker failed; retain partial logs')
  if time.monotonic()-start>deadline:raise TimeoutError('time estimate exceeded')
  time.sleep(2)
 if any(p.returncode for p in children):raise RuntimeError('worker failed')
 if stage=='full':
  combined=root/'combined';combined.mkdir()
  for name in ('sources','runs','windows'):
   with open(combined/(name+'.csv'),'w') as dest:
    header=None
    for k in range(len(jobs)):
     with open(root/f'shard-{k}'/(name+'.csv')) as f:
      line=f.readline()
      if header is None:header=line;dest.write(line)
      elif header!=line:raise ValueError('header mismatch')
      for line in f:dest.write(line)
  with open(combined/'sources.csv') as f:sources=list(csv.DictReader(f))
  assert len(sources)==100
  good=sum(x['status']=='ok' for x in sources)
  for name,n in [('runs',good*576),('windows',good*576*20)]:
   with open(combined/(name+'.csv')) as f:assert sum(1 for _ in csv.DictReader(f))==n
 (root/'execution.json').write_text(json.dumps({'wall_seconds':time.monotonic()-start,'stage':stage,'source_commit':'2b6ea12bbbccf06f62e700edf5653eeb7c950cc6','driver_sha256':hashlib.sha256((src/'driver.jl').read_bytes()).hexdigest(),'assay_sha256':hashlib.sha256((src/'inst/julia/scripts/mixture_assay.jl').read_bytes()).hexdigest(),'kernel_sha256':hashlib.sha256((src/'inst/julia/src/Clade.jl').read_bytes()).hexdigest(),'reproduce_sha256':hashlib.sha256((src/'inst/julia/src/reproduce.jl').read_bytes()).hexdigest(),'workers':len(jobs),'julia_threads':4,'blas_threads':1},indent=2)+'\n')
 (root/'job.done').write_text('compute complete; audit pending\n')
finally:
 for p in children:
  if p.poll() is None:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
 for p in children:
  try:p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
 for f in logs:f.close()
