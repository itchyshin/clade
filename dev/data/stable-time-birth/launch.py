import csv, hashlib, json, os, pathlib, signal, subprocess, sys, time
stage=sys.argv[1];root=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-15-stable-time-birth')/stage
root.mkdir(parents=True,exist_ok=False);src=pathlib.Path('/home/snakagaw/hsq_work/clade-stable-time-birth')
env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4')
jobs=([(s,'pilot') for s in range(82001,82006)]+[(51001,'replay')]) if stage=='pilot' else ([(s,'full') for s in range(83001,83101)] if stage=='full' else None)
if jobs is None:raise ValueError('stage')
limit=360 if stage=='pilot' else 2700;workers=6 if stage=='pilot' else 24
children={};logs=[];start=time.monotonic();todo=iter(jobs);finished=0
(root/'launcher.pid').write_text(str(os.getpid())+'\n')
def interrupt(s,f):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupt)
try:
 while True:
  while len(children)<workers:
   try:seed,mode=next(todo)
   except StopIteration:break
   log=open(root/f'{seed}.log','w');logs.append(log)
   cmd=['/home/snakagaw/.juliaup/bin/julia','+1.10.0','--project=inst/julia','driver.jl',str(root/str(seed)),str(seed),mode]
   p=subprocess.Popen(cmd,cwd=src,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);children[p]=(seed,mode)
  for p,(seed,mode) in list(children.items()):
   code=p.poll()
   if code is not None:
    if code:raise RuntimeError(f'worker {seed} failed: {code}')
    (root/f'{seed}.done').write_text('process completed; audit pending\n');finished+=1;del children[p]
  if not children and finished==len(jobs):break
  if time.monotonic()-start>limit:raise TimeoutError('time estimate exceeded')
  time.sleep(2)
 meta={'stage':stage,'seconds':time.monotonic()-start,'workers':workers,'julia_threads':4,'blas_threads':1,'seed_count':len(jobs),'driver_sha256':hashlib.sha256((src/'driver.jl').read_bytes()).hexdigest()}
 (root/'execution.json').write_text(json.dumps(meta,indent=2)+'\n')
finally:
 for p in children:
  if p.poll() is None:
   try:os.killpg(p.pid,signal.SIGTERM)
   except ProcessLookupError:pass
 for p in children:
  try:p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
 for f in logs:f.close()
