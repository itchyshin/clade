import hashlib,json,os,pathlib,signal,subprocess,sys,time
stage=sys.argv[1];life=400;root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-15-lifespan-replication')/stage;root.mkdir(parents=True,exist_ok=False)
src=pathlib.Path('/home/snakagaw/hsq_work/clade-lifespan-replication');env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4')
if stage=='validate':jobs=[(s,'pilot') for s in range(86001,86006)]+[(84001,'replay')];limit=240;workers=6
elif stage=='full':jobs=[(s,'full') for s in list(range(85001,85101))+list(range(87001,87101))];limit=1500;workers=24
else:raise ValueError('stage')
children={};logs=[];start=time.monotonic();todo=iter(jobs);finished=0
(root/'launcher.pid').write_text(str(os.getpid())+'\n')
def interrupt(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupt)
try:
 while True:
  while len(children)<workers:
   try:seed,mode=next(todo)
   except StopIteration:break
   log=open(root/f'{seed}.log','w');logs.append(log);out=root/str(life)/str(seed)
   cmd=['/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','driver.jl',str(out),str(seed),mode,str(life)]
   p=subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);children[p]=seed
  for p,seed in list(children.items()):
   code=p.poll()
   if code is not None:
    if code:raise RuntimeError(f'worker {seed} failed: {code}')
    (root/f'{seed}.done').write_text('process completed; audit pending\n');finished+=1;del children[p]
  if not children and finished==len(jobs):break
  if time.monotonic()-start>limit:raise TimeoutError('time estimate exceeded')
  time.sleep(2)
 (root/'execution.json').write_text(json.dumps({'stage':stage,'life':life,'seconds':time.monotonic()-start,'workers':workers,'julia_threads':4,'blas_threads':1,'jobs':len(jobs),'driver_sha256':hashlib.sha256((src/'driver.jl').read_bytes()).hexdigest()},indent=2)+'\n')
finally:
 for p in children:
  if p.poll() is None:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
 for p in children:
  try:p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
 for f in logs:f.close()
