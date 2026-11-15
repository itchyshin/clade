import hashlib,json,os,pathlib,signal,subprocess,sys,time
stage=sys.argv[1];life=int(sys.argv[2]) if len(sys.argv)>2 else 0
base=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-15-stable-food-threshold');root=base/stage;root.mkdir(parents=True,exist_ok=False)
src=pathlib.Path('/home/snakagaw/hsq_work/clade-food-threshold');env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4')
if stage=='screen':jobs=[(a,s,'pilot') for a in (250,300,400) for s in range(84001,84006)]+[(200,51001,'replay')];limit=480;workers=16
elif stage=='validate':jobs=[(life,s,'pilot') for s in range(84011,84016)];limit=300;workers=5
elif stage=='full':jobs=[(life,s,'full') for s in range(85001,85101)];limit=1500;workers=24
else:raise ValueError('stage')
children={};logs=[];start=time.monotonic();todo=iter(jobs);finished=0
(root/'launcher.pid').write_text(str(os.getpid())+'\n')
def interrupt(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupt)
try:
 while True:
  while len(children)<workers:
   try:a,seed,mode=next(todo)
   except StopIteration:break
   log=open(root/f'{a}-{seed}.log','w');logs.append(log);out=root/str(a)/str(seed)
   cmd=['/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','driver.jl',str(out),str(seed),mode,str(a)]
   p=subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);children[p]=(a,seed)
  for p,(a,seed) in list(children.items()):
   code=p.poll()
   if code is not None:
    if code:raise RuntimeError(f'worker {a}-{seed} failed: {code}')
    (root/f'{a}-{seed}.done').write_text('process completed; audit pending\n');finished+=1;del children[p]
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
