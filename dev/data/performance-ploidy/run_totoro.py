"""Four isolated Julia shards; preserve raw outputs and terminate owned groups on failure."""
import csv,hashlib,json,os,pathlib,signal,subprocess,sys,time
archive=pathlib.Path(sys.argv[1]).resolve();revision=sys.argv[2]
source=pathlib.Path.cwd();archive.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS="1",JULIA_NUM_THREADS="4")
julia=str(pathlib.Path.home()/".juliaup/bin/julia")
base=[julia,"+1.10.0","--project=inst/julia","inst/julia/scripts/performance_assay.jl"]
children=[];logs=[];commands=[];started=time.time();deadline=time.monotonic()+1800

def launch(args,label):
    command=["/usr/bin/time","-v","-o",str(archive/(label+".time"))]+args
    log=open(archive/(label+".log"),"w");logs.append(log)
    child=subprocess.Popen(command,cwd=source,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    children.append(child);commands.append(dict(label=label,pid=child.pid,command=command))
    return child

def wait_for(active):
    while any(p.poll() is None for p in active):
        if any(p.poll() not in (None,0) for p in active):raise RuntimeError("worker failed; inspect shard logs")
        if time.monotonic()>deadline:raise TimeoutError("30-minute estimate exceeded")
        time.sleep(2)
    if any(p.returncode!=0 for p in active):raise RuntimeError("worker failed")

def interrupted(signum,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,interrupted);signal.signal(signal.SIGINT,interrupted)
try:
    workers=[]
    for k in range(4):
        workers.append(launch(base+["25",str(archive/f"shard-{k}"),"64","1000",str(20001+25*k)],f"shard-{k}"))
    wait_for(workers)
    full=archive/"full-100";full.mkdir();(full/"states").mkdir()
    for name in ["runs.csv","windows.csv","cohorts.csv","garden.csv","behavior.csv"]:
        with open(full/name,"w") as output:
            header=None
            for k in range(4):
                with open(archive/f"shard-{k}"/name) as part:
                    first=part.readline()
                    if header is None:header=first;output.write(first)
                    elif first!=header:raise ValueError("shard header mismatch: "+name)
                    for line in part:output.write(line)
    with open(full/"runs.csv") as f:
        rows=list(csv.DictReader(f))
    keys={(r["ploidy"],r["mutation_sd"],r["seed"]) for r in rows}
    expected={(str(p),str(m),str(seed)) for p in (1,2) for m in (0,.05,.2) for seed in range(20001,20101)}
    # Julia prints round-trip floats, so compare numeric treatment values.
    numeric={(int(p),float(m),int(s)) for p,m,s in keys}
    assert len(rows)==len(keys)==600 and numeric=={(int(p),float(m),int(s)) for p,m,s in expected}
    for k in range(4):
        for p in (archive/f"shard-{k}"/"states").glob("*.jls"):
            dest=full/"states"/p.name
            dest.symlink_to(os.path.relpath(p,dest.parent))
    assert len(list((full/"states").glob("*.jls")))==600
    repeated=launch(base+["reassay",str(full/"states"),str(full/"reassay.csv"),"10","256"],"reassay")
    wait_for([repeated])
    info=dict(source_revision=revision,source_root=str(source),commands=commands,wall_seconds=time.time()-started,workers=4,julia_threads_per_worker=4,blas_threads=1,orchestrator_sha256=hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest())
    (archive/"execution.json").write_text(json.dumps(info,indent=2)+"\n")
    (archive/"job.done").write_text("compute completed; scientific checks remain separate\n")
finally:
    for p in children:
        if p.poll() is None:
            try:os.killpg(p.pid,signal.SIGTERM)
            except ProcessLookupError:pass
    for p in children:
        try:p.wait(timeout=10)
        except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
    for f in logs:f.close()
