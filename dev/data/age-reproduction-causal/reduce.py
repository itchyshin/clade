import csv,sys,math,collections
from pathlib import Path
p=Path(sys.argv[1]);read=lambda name:list(csv.DictReader(open(p/(name+'.csv'),newline='')))
sources=read('sources');runs=read('runs');seeds=sorted(int(x['seed']) for x in sources)
assert len(sources)==len(set(seeds)) and all(x['status']=='ok' and int(x['distinct_mu'])==8 and float(x['mean_deterministic'])>0 and int(x['final_tick'])==1000 and int(x['final_agents'])>=8 for x in sources),'incomplete or invalid source cohort'
key=lambda x:(x['gate'],int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode'],int(x['seed']),int(x['mono']))
r={key(x):x for x in runs};assert len(r)==len(runs)==len(seeds)*576
expected={(g,n,q,f,a,s,m) for g in ('sham','young','old','both') for n in (48,96) for q in (80,120) for f in (.05,.025) for a in ('fixed','staggered') for s in seeds for m in range(9)};assert set(r)==expected
panel={int(x['seed']):x['panel_hash'] for x in sources}
for seed in seeds:
 for n in (48,96):
  for q in (80,120):
   for f in (.05,.025):
    for age in ('fixed','staggered'):
     z=[r[(gate,n,q,f,age,seed,m)] for gate in ('sham','young','old','both') for m in range(9)]
     assert len({x['physical_hash'] for x in z})==1 and all(x['panel_hash']==panel[seed] for x in z)
wg={};gate_events=collections.defaultdict(lambda:[0,0,0,0]);rows=0
with open(p/'windows.csv',newline='') as f:
 for x in csv.DictReader(f):
  k=key(x);assert k in r;rows+=1
  z=wg.setdefault(k,{'last':k[1],'i':0,'births':0,'deaths':0,'food':0.0,'exposure':0,'byage':[0]*4,'eligible_young':0,'blocked_young':0,'eligible_old':0,'blocked_old':0,'n800':None})
  i=z['i'];assert i<20 and int(x['lo'])==i*50+1 and int(x['hi'])==i*50+50 and int(x['nstart'])==z['last']
  end=int(x['nend']);birth=int(x['births']);death=int(x['deaths']);exp=int(x['pre_exposure']);post=int(x['post_exposure'])
  assert end==z['last']+birth-death and exp==post+z['last']-end
  ages=[int(x[f'birth_age{j}']) for j in range(1,5)];assert sum(ages)==birth
  for j,v in enumerate(ages):z['byage'][j]+=v
  for group in ('young','old'):
   eligible=int(x['eligible_'+group]);blocked=int(x['blocked_'+group]);assert 0<=blocked<=eligible
   assert k[0] in (group,'both') or blocked==0
   z['eligible_'+group]+=eligible;z['blocked_'+group]+=blocked
  z['births']+=birth;z['deaths']+=death;z['food']+=float(x['food']);z['exposure']+=exp;z['last']=end;z['i']+=1
  if i==15:z['n800']=end
  ge=gate_events[k[0]]
  for j,name in enumerate(('eligible_young','blocked_young','eligible_old','blocked_old')):ge[j]+=int(x[name])
assert rows==20*len(r) and set(wg)==set(r)
for k,z in wg.items():
 x=r[k];assert z['i']==20 and z['n800'] is not None and z['last']==int(x['final_agents']) and z['births']==int(x['births']) and z['deaths']==int(x['deaths']) and z['exposure']==int(x['exposure'])
 assert math.isclose(z['food'],float(x['food']),rel_tol=1e-10,abs_tol=1e-5)
for gate,vals in gate_events.items():
 for idx,band in ((0,'young'),(2,'old')):
  e,b=vals[idx:idx+2];target=gate in (band,'both')
  if target:assert e>0 and .45<=b/e<=.55,(gate,band,e,b)
  else:assert b==0
with open(p/'gate-events.csv','w',newline='') as f:
 out=csv.writer(f);out.writerow(['gate','eligible_young','blocked_young','eligible_old','blocked_old'])
 for gate in ('sham','young','old','both'):out.writerow([gate,*gate_events[gate]])
with open(p/'blocks.csv','w',newline='') as f:
 fields=['seed','gate','density','threshold','food_rate','age_mode','population800','population1000','births','deaths','food','exposure','birth_age1','birth_age2','birth_age3','birth_age4','all9_viable','all9_stable'];o=csv.DictWriter(f,fieldnames=fields);o.writeheader()
 for seed in seeds:
  for gate in ('sham','young','old','both'):
   for n in (48,96):
    for q in (120,80):
     for rate in (.05,.025):
      for age in ('fixed','staggered'):
       keys=[(gate,n,q,rate,age,seed,m) for m in range(9)];x=[wg[k] for k in keys];rr=[r[k] for k in keys]
       calc=lambda a:a[0]-sum(a[1:])/8
       row={'seed':seed,'gate':gate,'density':n,'threshold':q,'food_rate':rate,'age_mode':age,'population800':calc([z['n800'] for z in x]),'population1000':calc([z['last'] for z in x])}
       for name in ('births','deaths','food','exposure'):row[name]=calc([z[name] for z in x])
       for j in range(4):row[f'birth_age{j+1}']=calc([z['byage'][j] for z in x])
       row['all9_viable']=all(int(v['final_agents'])>=20 and int(v['final_agents'])/n>=.5 for v in rr);row['all9_stable']=all(int(v['min_population'])>=20 for v in rr)
       assert math.isclose(row['population1000'],row['births']-row['deaths'],abs_tol=1e-8);o.writerow(row)
with open(p/'viability-summary.csv','w',newline='') as f:
 fields=['gate','density','threshold','food_rate','age_mode','runs','viable','weak','crashed','extinct','stable','cap_ticks'];o=csv.DictWriter(f,fieldnames=fields);o.writeheader()
 for gate in ('sham','young','old','both'):
  for n in (48,96):
   for q in (120,80):
    for rate in (.05,.025):
     for age in ('fixed','staggered'):
      z=[x for k,x in r.items() if k[:5]==(gate,n,q,rate,age)]
      categories=collections.Counter('crashed' if int(x['final_agents'])<20 or int(x['final_agents'])/n<.2 else 'weak' if int(x['final_agents'])/n<.5 else 'viable' for x in z)
      o.writerow(dict(gate=gate,density=n,threshold=q,food_rate=rate,age_mode=age,runs=len(z),viable=categories['viable'],weak=categories['weak'],crashed=categories['crashed'],extinct=sum(int(x['final_agents'])==0 for x in z),stable=sum(int(x['min_population'])>=20 for x in z),cap_ticks=sum(int(x['cap_ticks']) for x in z)))
with open(p/'age-births-by-seed.csv','w',newline='') as f:
 fields=['seed','gate','density','threshold','food_rate','age_mode','group','birth_age1','birth_age2','birth_age3','birth_age4','population1000'];o=csv.DictWriter(f,fieldnames=fields);o.writeheader()
 for seed in seeds:
  for gate in ('sham','young','old','both'):
   for n in (48,96):
    for q in (120,80):
     for rate in (.05,.025):
      for age in ('fixed','staggered'):
       for group in ('mixture','control'):
        ms=(0,) if group=='mixture' else range(1,9);z=[wg[(gate,n,q,rate,age,seed,m)] for m in ms]
        row=dict(seed=seed,gate=gate,density=n,threshold=q,food_rate=rate,age_mode=age,group=group,population1000=sum(v['last'] for v in z)/len(z))
        for j in range(4):row[f'birth_age{j+1}']=sum(v['byage'][j] for v in z)/len(z)
        o.writerow(row)
bycell=collections.defaultdict(lambda:{'runs':0,'ages':[0]*4,'eligible_young':0,'blocked_young':0,'eligible_old':0,'blocked_old':0})
for k,z in wg.items():
 gate,n,q,rate,age,seed,mono=k;group='mixture' if mono==0 else 'control'
 v=bycell[(gate,n,q,rate,age,group)];v['runs']+=1
 for j in range(4):v['ages'][j]+=z['byage'][j]
 for name in ('eligible_young','blocked_young','eligible_old','blocked_old'):v[name]+=z[name]
with open(p/'age-births-by-cell.csv','w',newline='') as f:
 fields=['gate','density','threshold','food_rate','age_mode','group','runs','mean_birth_age1','mean_birth_age2','mean_birth_age3','mean_birth_age4','eligible_young','blocked_young','eligible_old','blocked_old'];o=csv.DictWriter(f,fieldnames=fields);o.writeheader()
 for key,z in sorted(bycell.items()):
  gate,n,q,rate,age,group=key;row=dict(gate=gate,density=n,threshold=q,food_rate=rate,age_mode=age,group=group,runs=z['runs']);row.update({f'mean_birth_age{i+1}':v/z['runs'] for i,v in enumerate(z['ages'])});row.update({name:z[name] for name in ('eligible_young','blocked_young','eligible_old','blocked_old')});o.writerow(row)
print(f'PASS: {len(seeds)} source blocks, {len(r)} assays and {rows} windows; all gate eligibility, matching, population and age-birth ledgers checked.')
