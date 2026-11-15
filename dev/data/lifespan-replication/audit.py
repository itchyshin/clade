import collections,csv,gzip,itertools,json,math,pathlib,sys
root=pathlib.Path(sys.argv[1]);stage=sys.argv[2];prior=pathlib.Path(sys.argv[3]);life=int(sys.argv[4]);out=root/'audited';out.mkdir(exist_ok=True)
seeds=([*range(86001,86006)] if stage=='validate' else [*range(85001,85101),*range(87001,87101)] if stage=='full' else [84001])
def aj(data):
 nb=len(data);S=1.;fb=fd=0.;births=deaths=cens=0;counts=[[0,0,0] for _ in range(51)]
 for t,k in data:assert 0<=t<=50 and k in (0,1,2);counts[t][k]+=1
 for c,e1,e2 in counts:
  if e1+e2+c:
   assert nb>=e1+e2+c and nb>0
   fb+=S*e1/nb;fd+=S*e2/nb;S*=1-(e1+e2)/nb;nb-=e1+e2+c;births+=e1;deaths+=e2;cens+=c
 assert nb==0 and math.isclose(S+fb+fd,1.,abs_tol=1e-9)
 return fb,fd,births,deaths,cens
z=aj([(0,1),(1,2),(1,0),(2,1)]);assert abs(z[0]-.75)<1e-12 and abs(z[1]-.25)<1e-12
runs=[];stats=[];sources=[];total_events=0;total_cohorts=0
for seed in seeds:
 d=root/str(life)/str(seed)
 with open(d/'source.csv') as f:s=list(csv.DictReader(f));assert len(s)==1;sources+=s
 if s[0]['status']!='ok':print('FAILED SOURCE',seed);continue
 with open(d/'runs.csv') as f:rr=list(csv.DictReader(f))
 key=lambda x:(int(x['threshold']),float(x['food']),x['age_mode'],int(x['mono']))
 rmap={key(x):x for x in rr};assert len(rmap)==len(rr)==72
 assert set(rmap)==set(itertools.product((80,120),(.025,.05),('fixed','staggered'),range(9)));runs+=rr
 for age,food in itertools.product(('fixed','staggered'),(.025,.05)):
  cells=[x for k,x in rmap.items() if k[1:3]==(food,age)];assert len(cells)==18
  assert len({x['panel'] for x in cells})==1
  for q in (80,120):assert len({x['physical'] for x in cells if int(x['threshold'])==q})==1
 for r in rr:
  assert int(r['final'])==96+int(r['births'])-int(r['deaths'])
  assert int(r['dose'])==0 and int(r['blocked'])==0 and int(r['tick'])<=1000
  assert sum(int(r['birth_age'+str(j)]) for j in range(1,5))==int(r['births'])
 dead=collections.defaultdict(dict)
 with open(d/'deaths.csv') as f:
  for x in csv.DictReader(f):
   k=key(x);i=int(x['id']);assert i not in dead[k];dead[k][i]=int(x['death_tick'])
 for k,r in rmap.items():assert len(dead[k])==int(r['deaths'])
 cohorts=collections.defaultdict(dict)
 with open(d/'cohorts.csv') as f:
  for c in csv.DictReader(f):
   k=key(c);i=int(c['id']);t=int(c['entry_tick']);age=int(c['entry_age']);b=int(c['birth_tick']);death=int(c['death_tick']);end=int(c['end_tick']);total_cohorts+=1
   assert k in rmap and i not in cohorts[k] and age<50 and 0<t<=end==int(rmap[k]['tick']) and int(c['first_blocked'])==0
   assert death==dead[k].get(i,0) and (death==0 or t<death<=end)
   assert b==0 or t<=b<=end
   assert not b or not death or b<death
   cohorts[k][i]=c
 if stage!='full':
  first=collections.defaultdict(dict);firstbirth=collections.defaultdict(dict);evt=collections.defaultdict(lambda:[0,0,0,0,0,0]);bytick=collections.defaultdict(collections.Counter)
  with open(d/'events.csv') as f:
   for x in csv.DictReader(f):
    total_events+=1;k=key(x);i=int(x['id']);t=int(x['tick']);age=int(x['age']);b=int(x['births']);bl=int(x['blocked']);assert k in rmap and bl==0
    v=evt[k];v[0]+=int(age<50);v[1]+=b;v[2+(0 if age<50 else 1 if age<100 else 2 if age<150 else 3)]+=b;bytick[k][t]+=b
    if age<50 and i not in first[k]:first[k][i]=(t,age,float(x['energy_before']),bl)
    if b and i in first[k] and i not in firstbirth[k]:firstbirth[k][i]=(t,age,float(x['energy_before']),float(x['energy_after']))
  for k,r in rmap.items():
   assert evt[k]==[int(r['eligible']),int(r['births'])]+[int(r['birth_age'+str(j)]) for j in range(1,5)]
   assert set(first[k])==set(cohorts[k])
   for i,c in cohorts[k].items():
    assert first[k][i]==(int(c['entry_tick']),int(c['entry_age']),float(c['entry_energy']),int(c['first_blocked']))
    assert firstbirth[k].get(i,(0,0,0.,0.))==(int(c['birth_tick']),int(c['birth_age']),float(c['birth_energy_before']),float(c['birth_energy_after']))
   deaths=collections.Counter(dead[k].values());n=96;trace=[]
   for tick in range(1,int(r['tick'])+1):n+=bytick[k][tick]-deaths[tick];trace.append(n)
   assert n==int(r['final']) and min(trace)==int(r['min_population']) and max(trace)==int(r['max_population'])
   for t in (200,400,600,800):assert (trace[t-1] if t<=len(trace) else 0)==int(r['pop'+str(t)])
 for k,r in rmap.items():
  cs=cohorts[k];assert len(cs)<=int(r['eligible']);obs=[];complete=[];ents=[];birthages=[]
  for c in cs.values():
   start=int(c['entry_tick']);end=int(c['end_tick']);b=int(c['birth_tick']);death=int(c['death_tick']);candidates=[(50,0),(end-start,0)]
   if b:candidates.append((b-start,1))
   if death:candidates.append((death-start,2))
   time,kind=min(candidates,key=lambda x:(x[0],-x[1]));obs.append((time,kind));ents.append(int(c['entry_age']))
   if kind==1:birthages.append(int(c['birth_age']))
   if start<=end-50:complete.append((time,kind))
  for name,dat in [('all',obs),('complete',complete)]:
   v=aj(dat) if dat else (float('nan'),)*5
   stats.append(dict(seed=seed,threshold=k[0],food=k[1],age_mode=k[2],mono=k[3],cohort=name,n=len(dat),cif_birth50=v[0],cif_death50=v[1],births50=v[2],deaths50=v[3],censored_before50=sum(1 for t,j in dat if j==0 and t<50),entry_age=sum(ents)/len(ents) if ents else float('nan'),birth_age50=sum(birthages)/len(birthages) if birthages else float('nan')))
if stage=='replay':
 with open(prior) as f:old=list(csv.DictReader(f))
 o={key(x):x for x in old};assert len(o)==len(runs)==72
 for r in runs:
  x=o[key(r)]
  for name in ('physical','panel','tick','final','min_population','max_population','cap_ticks','exposure','births','deaths','pop200','pop400','pop600','pop800','birth_age1','birth_age2','birth_age3','birth_age4','eligible','blocked'):
   assert r[name]==x[name],(name,r[name],x[name])
for name,rows in [('runs',runs),('source',sources),('timing',stats)]:
 if rows:
  with open(out/(str(life)+'-'+name+'.csv'),'w') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
counts={'stage':stage,'life':life,'source_blocks':len(sources),'source_failed':sum(x['status']!='ok' for x in sources),'source_viable':sum(int(x['agents'])>=50 for x in sources),'source_low':sum(int(x['min_population'])<20 for x in sources),'source_cap_ticks':sum(int(x['cap_ticks']) for x in sources),'cohorts':total_cohorts,'pilot_events':total_events,'thresholds':{}}
for q in (80,120):
 v=[r for r in runs if int(r['threshold'])==q];groups={}
 for food,age in itertools.product((.05,.025),('fixed','staggered')):
  zz=[r for r in v if float(r['food'])==food and r['age_mode']==age]
  groups[f'{food}-{age}']={'runs':len(zz),'viable':sum(int(x['final'])>=48 for x in zz),'no_bottleneck':sum(int(x['min_population'])>=20 for x in zz)}
 counts['thresholds'][q]={'runs':len(v),'viable':sum(int(x['final'])>=48 for x in v),'no_bottleneck':sum(int(x['min_population'])>=20 for x in v),'cap_ticks':sum(int(x['cap_ticks']) for x in v),'tick_total':sum(int(x['tick']) for x in v),'groups':groups}
(out/(str(life)+'-audit.json')).write_text(json.dumps(counts,indent=2)+'\n');print(json.dumps(counts,indent=2))
