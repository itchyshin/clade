import csv,hashlib,json,os,pathlib,signal,subprocess,sys,time
root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-14-policy-stability')/sys.argv[1]
first=int(sys.argv[2]);count=int(sys.argv[3]);deadline=int(sys.argv[4]);thresholds=sys.argv[5];root.mkdir(parents=True,exist_ok=False)
src=pathlib.Path('/home/snakagaw/hsq_work/clade-stability');env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4');children=[];logs=[];start=time.monotonic();nw=min(8,count)
def interrupted(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupted)
try:
 offset=0
 for k in range(nw):
  n=count//nw+(k<count%nw);out=root/f'shard-{k}';log=open(root/f'shard-{k}.log','w');logs.append(log)
  cmd=['/usr/bin/time','-v','-o',str(root/f'shard-{k}.time'),'/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','driver.jl',str(out),str(first+offset),str(n),thresholds];offset+=n
  children.append(subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True))
 while any(p.poll() is None for p in children):
  if any(p.poll() not in (None,0) for p in children):raise RuntimeError('worker failed; retain partial rows and logs')
  if time.monotonic()-start>deadline:raise TimeoutError('time estimate exceeded')
  time.sleep(2)
 if any(p.returncode for p in children):raise RuntimeError('worker failed')
 combined=root/'combined';combined.mkdir()
 for name in ('sources','runs','windows'):
  with open(combined/(name+'.csv'),'w') as dest:
   header=None
   for k in range(nw):
    with open(root/f'shard-{k}'/(name+'.csv')) as f:
     line=f.readline()
     if header is None:header=line;dest.write(line)
     elif header!=line:raise ValueError('header mismatch')
     for line in f:dest.write(line)
 with open(combined/'sources.csv') as f:sources=list(csv.DictReader(f))
 assert len(sources)==count*len(thresholds.split(':'))
 good=sum(x['status']=='ok' for x in sources)
 for name,n in [('runs',good*36),('windows',good*36*20)]:
  with open(combined/(name+'.csv')) as f:assert sum(1 for _ in csv.DictReader(f))==n
 (root/'execution.json').write_text(json.dumps({'wall_seconds':time.monotonic()-start,'first_seed':first,'seed_count':count,'thresholds':thresholds,'source_commit':'2b6ea12bbbccf06f62e700edf5653eeb7c950cc6','driver_sha256':hashlib.sha256((src/'driver.jl').read_bytes()).hexdigest(),'assay_sha256':hashlib.sha256((src/'inst/julia/scripts/mixture_assay.jl').read_bytes()).hexdigest(),'workers':nw,'julia_threads':4,'blas_threads':1},indent=2)+'\n')
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
