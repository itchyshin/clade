import csv, collections, itertools, math, pathlib, sys, json
root=pathlib.Path(sys.argv[1]);old=pathlib.Path(sys.argv[2]);out=root/'audited';out.mkdir(exist_ok=True)
seeds=list(range(81001,81006));runs={};sources=[]
for seed in seeds+[71001]:
 p=root/str(seed)
 with open(p/'source.csv') as f: s=list(csv.DictReader(f));assert len(s)==1 and s[0]['status']=='ok';sources+=s
 with open(p/'runs.csv') as f:
  rr=list(csv.DictReader(f));assert len(rr)==(36 if seed==71001 else 180)
  for r in rr:
   key=tuple(int(r[x]) for x in ('seed','dose','threshold'))+(float(r['food']),int(r['mono']))
   assert key not in runs;runs[key]=r
   assert int(r['final'])==48+int(r['births'])-int(r['deaths'])
   assert int(r['tick'])==1000
 for q,food,mono in itertools.product((80,120),(.05,.025),range(9)):
  cells=[v for k,v in runs.items() if k[0]==seed and k[2:]==(q,food,mono)]
  assert len(cells)==(1 if seed==71001 else 5)
  assert len({x['physical'] for x in cells})==1 and len({x['panel'] for x in cells})==1
panel_checks={}
with open(root/'source-panel-check.csv') as f:
 for r in csv.DictReader(f):
  assert int(r['distinct'])==8 and float(r['mean_disagreement'])>0
  panel_checks[int(r['seed'])]=r['panel_hash']
assert set(panel_checks)==set(seeds)
for seed,q,food in itertools.product(seeds,(80,120),(.05,.025)):
 cells=[v for k,v in runs.items() if k[0]==seed and k[2]==q and k[3]==food]
 assert len(cells)==45 and len({x['physical'] for x in cells})==1
 assert {x['panel'] for x in cells}=={panel_checks[seed]}
prior={}
with open(old) as f:
 for r in csv.DictReader(f):
  if r['seed']=='71001' and r['gate']=='sham' and r['density']=='48' and r['age_mode']=='fixed':prior[(int(r['threshold']),float(r['food_rate']),int(r['mono']))]=r
assert len(prior)==36
for q,food,mono in prior:
 a=runs[(71001,0,q,food,mono)];b=prior[(q,food,mono)]
 for x,y in [('physical','physical_hash'),('panel','panel_hash'),('tick','final_tick'),('final','final_agents'),('min_population','min_population'),('exposure','exposure'),('births','births'),('deaths','deaths')]:assert a[x]==b[y],(q,food,mono,x,a[x],b[y])
mask=(1<<64)-1
def mix(x):
 z=(x+0x9e3779b97f4a7c15)&mask;z=((z^(z>>30))*0xbf58476d1ce4e5b9)&mask;z=((z^(z>>27))*0x94d049bb133111eb)&mask;return z^(z>>31)
def followup_status(t, death, next_tick):
 if next_tick <= t+50: return "birth"
 if death <= t+50: return "death"
 if t+50 <= 1000: return "no_birth"
 return "censored"
# Boundary fixtures prevent a missing event from masquerading as a tick-1001 birth.
assert followup_status(980,10**9,10**9)=="censored"
assert followup_status(950,10**9,10**9)=="no_birth"
assert followup_status(980,990,10**9)=="death"
assert followup_status(980,10**9,995)=="birth"
rows=[];eventcount=0
for seed in seeds+[71001]:
 p=root/str(seed);dead=collections.defaultdict(dict)
 with open(p/'deaths.csv') as f:
  for d in csv.DictReader(f):
   k=(seed,int(d['dose']),int(d['threshold']),float(d['food']),int(d['mono']));i=int(d['id']);assert i not in dead[k];dead[k][i]=int(d['death_tick'])
 with open(p/'events.csv') as f:
  reader=csv.DictReader(f)
  def key(r):return (seed,int(r['dose']),int(r['threshold']),float(r['food']),int(r['mono']))
  seen=set()
  for k,group in itertools.groupby(reader,key):
   assert k not in seen and k in runs;seen.add(k);r=runs[k];assert len(dead[k])==int(r['deaths'])
   birth_total=0;eligible=blocked=youngbirths=allbirths=0;ener_before=ener_after=0.;block_before=block_after=0.;first={};nextbirth={}
   for x in group:
    eventcount+=1;t=int(x['tick']);i=int(x['id']);age=int(x['age']);b=int(x['births']);bl=int(x['blocked'])
    u=(mix((seed<<40)^(i<<10)^t)>>11)/(1<<53)
    assert bl==int(age<50 and u<k[1]/100);assert not (bl and b);assert t<=int(r['tick'])
    if i in dead[k]:assert t<dead[k][i]
    birth_total+=b;allbirths+=b
    if age<50:
     eligible+=1;blocked+=bl;youngbirths+=b;ener_before+=float(x['energy_before']);ener_after+=float(x['energy_after'])
     if bl:block_before+=float(x['energy_before']);block_after+=float(x['energy_after'])
    if bl and i not in first:first[i]=(t, float(x["energy_before"]))
    if b and i in first and t>first[i][0] and i not in nextbirth:nextbirth[i]=(t,age,float(x["energy_before"]),float(x["energy_after"]))
   assert birth_total==int(r['births']), (k,birth_total,r['births'])
   mature=follow=deadcens=endcens=0;delay_sum=late_age=first_energy=later_pre=later_post=0.
   for i,(t,energy) in first.items():
    death=dead[k].get(i,10**9);nxt=nextbirth.get(i,(10**9,0,0.,0.))
    status=followup_status(t,death,nxt[0])
    if status=="birth":
     follow+=1;mature+=1;delay_sum+=nxt[0]-t;late_age+=int(nxt[1]>=50);first_energy+=energy;later_pre+=nxt[2];later_post+=nxt[3]
    elif status=="death":mature+=1;deadcens+=1
    elif status=="no_birth":mature+=1
    else:endcens+=1
   assert mature+endcens==len(first)
   if k[1]==100:assert late_age==follow
   rows.append(dict(seed=seed,dose=k[1],threshold=k[2],food=k[3],mono=k[4],eligible=eligible,blocked=blocked,young_births=youngbirths,births=allbirths,energy_before=ener_before,energy_after=ener_after,blocked_energy_before=block_before,blocked_energy_after=block_after,first_blocked_individuals=len(first),followed_50=mature,subsequent_birth_50=follow,death_within_50=deadcens,end_censored=endcens,follow_delay_sum=delay_sum,follow_age_50plus=late_age,follow_first_energy=first_energy,follow_birth_energy_before=later_pre,follow_birth_energy_after=later_post,final=int(r['final']),min_population=int(r['min_population'])))
  assert len(seen)==(36 if seed==71001 else 180)
with open(out/'source.csv','w') as f:w=csv.DictWriter(f,fieldnames=sources[0].keys());w.writeheader();w.writerows(sources)
with open(out/'runs.csv','w') as f:w=csv.DictWriter(f,fieldnames=next(iter(runs.values())).keys());w.writeheader();w.writerows(runs.values())
with open(out/'individual-summary.csv','w') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
(out/'audit.json').write_text(json.dumps({'source_blocks':5,'pilot_runs':900,'replay_runs':36,'events':eventcount,'replay_matched_fields':8,'verified':'initial hashes, all gate decisions, births, deaths, survival censoring, population balance'},indent=2)+'\n')
print((out/'audit.json').read_text())
