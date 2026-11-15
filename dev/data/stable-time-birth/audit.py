import collections,csv,gzip,itertools,json,math,pathlib,sys
root=pathlib.Path(sys.argv[1]);stage=sys.argv[2];prior=pathlib.Path(sys.argv[3]);out=root/'audited';out.mkdir(exist_ok=True)
seeds=([*range(82001,82006),51001] if stage=='pilot' else list(range(83001,83101)))
mask=(1<<64)-1
def mix(x):
 z=(x+0x9e3779b97f4a7c15)&mask;z=((z^(z>>30))*0xbf58476d1ce4e5b9)&mask;z=((z^(z>>27))*0x94d049bb133111eb)&mask;return z^(z>>31)
def gate(seed,dose,t,i,age):return int(age<50 and (mix((seed<<40)^(i<<10)^t)>>11)/(1<<53)<dose/100)
def aj(data):
 # (time, type), with type 0 censor, 1 birth, 2 death; events before censor at ties.
 n=len(data);nb=n;S=1.;fb=fd=0.;births=deaths=cens=0
 counts=[[0,0,0] for _ in range(51)]
 for t,k in data:
  assert 0<=t<=50 and k in (0,1,2)
  counts[t][k]+=1
 for t in range(51):
  c,e1,e2=counts[t]
  if e1+e2+c:
   assert nb>=e1+e2+c and nb>0
   fb+=S*e1/nb;fd+=S*e2/nb;S*=1-(e1+e2)/nb;nb-=e1+e2+c;births+=e1;deaths+=e2;cens+=c
 assert nb==0 and math.isclose(S+fb+fd,1.,abs_tol=1e-9)
 return fb,fd,births,deaths,cens
# Hand-calculated competing death and censoring case; time-zero birth is intentional.
x=aj([(0,1),(1,2),(1,0),(2,1)])
assert abs(x[0]-.75)<1e-12 and abs(x[1]-.25)<1e-12 and x[2:]==(2,1,1)
runs=[];stats=[];sources=[];total_events=0;total_cohorts=0;replay=[]
for seed in seeds:
 d=root/str(seed)
 with open(d/'source.csv') as f:s=list(csv.DictReader(f));assert len(s)==1;sources+=s
 if s[0]['status']!='ok':print('FAILED SOURCE',seed);continue
 with open(d/'runs.csv') as f:rr=list(csv.DictReader(f))
 expected=36 if seed==51001 else 180
 assert len(rr)==expected and len({(x['dose'],x['food'],x['age_mode'],x['mono']) for x in rr})==expected
 key=lambda x:(int(x['dose']),float(x['food']),x['age_mode'],int(x['mono']))
 rmap={key(x):x for x in rr};runs+=rr
 doses=(0,) if seed==51001 else (0,25,50,75,100)
 assert set(rmap)==set(itertools.product(doses,(.025,.05),('fixed','staggered'),range(9)))
 for age,food in itertools.product(('fixed','staggered'),(.025,.05)):
  cells=[x for k,x in rmap.items() if k[1:3]==(food,age)];assert len(cells)==(9 if seed==51001 else 45)
  assert len({x['physical'] for x in cells})==len({x['panel'] for x in cells})==1
 for r in rr:
  assert int(r['threshold'])==80 and int(r['final'])==96+int(r['births'])-int(r['deaths'])
  assert int(r['tick'])<=1000 and 0<=int(r['blocked'])<=int(r['eligible'])
  if int(r['dose'])==0:assert int(r['blocked'])==0
  if int(r['dose'])==100:assert int(r['blocked'])==int(r['eligible'])
 dead=collections.defaultdict(dict)
 with open(d/'deaths.csv') as f:
  for x in csv.DictReader(f):
   k=key(x);i=int(x['id']);assert i not in dead[k];dead[k][i]=int(x['death_tick'])
 for k,r in rmap.items():assert len(dead[k])==int(r['deaths'])
 cohorts=collections.defaultdict(dict)
 with open(d/'cohorts.csv') as f:
  for c in csv.DictReader(f):
   k=key(c);i=int(c['id']);t=int(c['entry_tick']);age=int(c['entry_age']);b=int(c['birth_tick']);death=int(c['death_tick']);end=int(c['end_tick']);total_cohorts+=1
   assert k in rmap and i not in cohorts[k] and age<50 and 0<t<=end==int(rmap[k]['tick'])
   assert int(c['first_blocked'])==gate(seed,k[0],t,i,age)
   assert death==dead[k].get(i,0)
   assert death==0 or t<death<=end
   assert b==0 or t<=b<=end
   assert not b or not death or b<death
   if b==t:assert int(c['first_blocked'])==0
   if k[0]==100 and b:assert int(c['birth_age'])>=50
   cohorts[k][i]=c
 events=(stage=='pilot');eventfirst=collections.defaultdict(dict);eventbirth=collections.defaultdict(dict);evtcounts=collections.defaultdict(lambda:[0,0,0])
 if events:
  with open(d/'events.csv') as f:
   for x in csv.DictReader(f):
    total_events+=1;k=key(x);i=int(x['id']);t=int(x['tick']);age=int(x['age']);b=int(x['births']);bl=int(x['blocked'])
    assert k in rmap and bl==gate(seed,k[0],t,i,age) and not(bl and b)
    v=evtcounts[k];v[2]+=b
    if age<50:
     v[0]+=1;v[1]+=bl
     if i not in eventfirst[k]:eventfirst[k][i]=(t,age,float(x['energy_before']),bl)
    if b and i in eventfirst[k] and i not in eventbirth[k]:eventbirth[k][i]=(t,age,float(x['energy_before']),float(x['energy_after']))
  for k,r in rmap.items():
   assert evtcounts[k]==[int(r['eligible']),int(r['blocked']),int(r['births'])]
   assert set(eventfirst[k])==set(cohorts[k])
   for i,c in cohorts[k].items():
    e=eventfirst[k][i];assert e==(int(c['entry_tick']),int(c['entry_age']),float(c['entry_energy']),int(c['first_blocked']))
    b=eventbirth[k].get(i,(0,0,0.,0.));assert b==(int(c['birth_tick']),int(c['birth_age']),float(c['birth_energy_before']),float(c['birth_energy_after']))
 for k,r in rmap.items():
  cs=cohorts[k];assert len(cs)<=int(r['eligible']);obs=[];complete=[];energy=[];energy_complete=[]
  for c in cs.values():
   start=int(c['entry_tick']);end=int(c['end_tick']);b=int(c['birth_tick']);death=int(c['death_tick'])
   candidates=[(50,0),(end-start,0)]
   if b:candidates.append((b-start,1))
   if death:candidates.append((death-start,2))
   time,kind=min(candidates,key=lambda x:(x[0],-x[1]))
   obs.append((time,kind));energy.append((float(c['entry_energy']),float(c['birth_energy_before']) if kind==1 else None))
   if start<=end-50:complete.append((time,kind));energy_complete.append((float(c['entry_energy']),float(c['birth_energy_before']) if kind==1 else None))
  for name,dat,en in [('all',obs,energy),('complete',complete,energy_complete)]:
   z=aj(dat) if dat else (float('nan'),)*5
   stats.append(dict(seed=seed,dose=k[0],food=k[1],age_mode=k[2],mono=k[3],cohort=name,n=len(dat),cif_birth50=z[0],cif_death50=z[1],births50=z[2],deaths50=z[3],censored=z[4],censored_before50=sum(1 for t,k in dat if k==0 and t<50),at_risk50=sum(1 for t,k in dat if t>=50),energy_at_entry=sum(v[0] for v in en)/len(en) if en else float('nan'),energy_at_birth=sum(v[1] for v in en if v[1] is not None)/sum(v[1] is not None for v in en) if any(v[1] is not None for v in en) else float('nan'),final=r['final'],min_population=r['min_population']))
 if seed==51001:replay=rr
if stage=='pilot':
 with gzip.open(prior,'rt') as f:old=[x for x in csv.DictReader(f) if x['seed']=='51001']
 o={(float(x['food_rate']),x['age_mode'],int(x['mono'])):x for x in old};assert len(o)==len(replay)==36
 for r in replay:
  x=o[(float(r['food']),r['age_mode'],int(r['mono']))]
  for a,b in [('physical','physical_hash'),('panel','panel_hash'),('tick','final_tick'),('final','final_agents'),('min_population','min_population'),('max_population','max_population'),('cap_ticks','cap_ticks'),('exposure','exposure'),('births','births'),('deaths','deaths')]:assert r[a]==x[b],(a,r[a],x[b])
for name,rows in [('runs',runs),('source',sources),('timing',stats)]:
 if rows:
  with open(out/(name+'.csv'),'w') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
valid=[r for r in runs if int(r['seed'])!=51001];counts={'stage':stage,'sources':len(sources),'source_failed':sum(x['status']!='ok' for x in sources),'runs':len(valid),'endpoint_viable':sum(int(x['final'])>=48 for x in valid),'no_bottleneck':sum(int(x['min_population'])>=20 for x in valid),'assay_cap_ticks':sum(int(x['cap_ticks']) for x in valid),'source_cap_ticks':sum(int(x['cap_ticks']) for x in sources),'cohorts':total_cohorts,'pilot_events':total_events,'replay_runs':len(replay)}
for dose in (0,25,50,75,100):
 v=[r for r in valid if int(r['dose'])==dose];e=sum(int(r['eligible']) for r in v);blocked=sum(int(r['blocked']) for r in v)
 assert e>0 and abs(blocked/e-dose/100)<=.03,(dose,blocked,e)
 counts['gate_'+str(dose)]={'eligible':e,'blocked':blocked,'fraction':blocked/e}
(out/'audit.json').write_text(json.dumps(counts,indent=2)+'\n');print(json.dumps(counts,indent=2))
if stage=='pilot':
 assert len(valid)==900 and counts['source_failed']==0 and all(int(x['agents'])>=50 for x in sources)
 assert counts['endpoint_viable']>=855 and counts['no_bottleneck']>=855
 assert counts['assay_cap_ticks']<.01*sum(int(x['tick']) for x in valid)
 assert counts['source_cap_ticks']<.01*sum(int(x['tick']) for x in sources)
