"""Four isolated seed-block shards; stop owned process groups on failure/overrun."""
import csv,hashlib,json,os,pathlib,signal,subprocess,sys,time
archive=pathlib.Path(sys.argv[1]).resolve();revision=sys.argv[2]
source=pathlib.Path.cwd();archive.mkdir(parents=True,exist_ok=True)
state_dir=pathlib.Path('/home/snakagaw/sim-archive/clade/2026-11-14-performance-corrected/full-100/states')
env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',JULIA_NUM_THREADS='4')
base=[str(pathlib.Path.home()/'.juliaup/bin/julia'),'+1.10.0','--project=inst/julia','inst/julia/scripts/mixture_assay.jl']
children=[];logs=[];commands=[];started=time.time();deadline=time.monotonic()+1200

def interrupted(signum,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupted);signal.signal(signal.SIGINT,interrupted)
try:
    for k in range(4):
        command=['/usr/bin/time','-v','-o',str(archive/f'shard-{k}.time')]+base+['25',str(archive/f'shard-{k}'),str(state_dir),str(20001+25*k)]
        log=open(archive/f'shard-{k}.log','w');logs.append(log)
        p=subprocess.Popen(command,cwd=source,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
        children.append(p);commands.append(dict(pid=p.pid,command=command))
    while any(p.poll() is None for p in children):
        if any(p.poll() not in (None,0) for p in children):raise RuntimeError('worker failed; inspect shard logs')
        if time.monotonic()>deadline:raise TimeoutError('20-minute estimate exceeded')
        for k,p in enumerate(children):
            if p.poll()==0:(archive/f'shard-{k}.done').touch()
        time.sleep(2)
    if any(p.returncode!=0 for p in children):raise RuntimeError('worker failed')
    full=archive/'full-100';full.mkdir()
    for name in ['runs','windows','cohorts','deaths','panels','policies']:
        with open(full/(name+'.csv'),'w') as output:
            header=None
            for k in range(4):
                with open(archive/f'shard-{k}'/(name+'.csv')) as part:
                    first=part.readline()
                    if header is None:header=first;output.write(first)
                    elif first!=header:raise ValueError('shard header mismatch: '+name)
                    for line in part:output.write(line)
    with open(full/'runs.csv') as f:rows=list(csv.DictReader(f))
    keys={(int(r['ploidy']),float(r['source_mutation']),int(r['seed']),r['mode'],int(r['mono'])) for r in rows}
    expected={(p,m,s,mode,mono) for p in (1,2) for m in (0,.05,.2) for s in range(20001,20101) for mode in ('forage','demography') for mono in range(9)}
    assert len(rows)==len(keys)==10800 and keys==expected
    info=dict(source_revision=revision,source_root=str(source),commands=commands,wall_seconds=time.time()-started,workers=4,julia_threads_per_worker=4,blas_threads=1,orchestrator_sha256=hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest())
    (archive/'execution.json').write_text(json.dumps(info,indent=2)+'\n')
    (archive/'job.done').write_text('compute completed; scientific checks remain separate\n')
finally:
    for p in children:
        if p.poll() is None:
            try:os.killpg(p.pid,signal.SIGTERM)
            except ProcessLookupError:pass
    for p in children:
        try:p.wait(timeout=10)
        except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
    for f in logs:f.close()
