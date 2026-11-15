import csv,gzip,sys,math,collections
from pathlib import Path
p=Path(sys.argv[1]);prior=Path(sys.argv[2]);read=lambda f:list(csv.DictReader(open(f,newline='')))
source=[read(p/f'shard-{i}'/'sources.csv')[0] for i in range(5)];assert all(x['seed']=='70001' and x['status']=='ok' and int(x['distinct_mu'])==8 and float(x['mean_deterministic'])>0 and int(x['min_population'])>=20 and int(x['final_agents'])>=50 for x in source[:4]);assert len({x['source_hash'] for x in source[:4]})==len({x['panel_hash'] for x in source[:4]})==1
r=[];w=[]
for i,mode in enumerate(('sham','young','old','both')):
 rr=read(p/f'shard-{i}'/'runs.csv');ww=read(p/f'shard-{i}'/'windows.csv');assert len(rr)==144 and len(ww)==2880 and all(x['gate']==mode and x['seed']=='70001' for x in rr+ww);r+=rr;w+=ww
key=lambda x:(x['gate'],int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode'],int(x['seed']),int(x['mono']))
a={key(x):x for x in r};assert len(a)==576
wg=collections.defaultdict(list)
for x in w:wg[key(x)].append(x)
assert set(a)==set(wg)
for k,x in a.items():
 z=sorted(wg[k],key=lambda v:int(v['lo']));assert len(z)==20;last=k[1]
 for i,y in enumerate(z):
  assert int(y['lo'])==50*i+1 and int(y['hi'])==50*i+50 and int(y['nstart'])==last
  births=int(y['births']);deaths=int(y['deaths']);assert int(y['nend'])==last+births-deaths and births==sum(int(y[f'birth_age{j}']) for j in range(1,5))
  assert int(y['pre_exposure'])==int(y['post_exposure'])+last-int(y['nend']);last=int(y['nend'])
  for b in ('young','old'):assert 0<=int(y[f'blocked_{b}'])<=int(y[f'eligible_{b}'])
  assert k[0] in ('young','both') or int(y['blocked_young'])==0
  assert k[0] in ('old','both') or int(y['blocked_old'])==0
 assert last==int(x['final_agents']) and sum(int(y['births']) for y in z)==int(x['births']) and sum(int(y['deaths']) for y in z)==int(x['deaths'])
for n in (48,96):
 for q in (80,120):
  for f in (.05,.025):
   for age in ('fixed','staggered'):
    z=[a[(gate,n,q,f,age,70001,mono)] for gate in ('sham','young','old','both') for mono in range(9)]
    assert len({x['physical_hash'] for x in z})==len({x['panel_hash'] for x in z})==1
for mode in ('sham','young','old','both'):
 rr=[x for x in r if x['gate']==mode];ww=[x for x in w if x['gate']==mode];viable=sum(int(x['final_agents'])>=20 and int(x['final_agents'])/int(x['density'])>=.5 for x in rr)
 print(mode,'viable',viable,'/144', 'extinct',sum(int(x['final_agents'])==0 for x in rr))
 assert viable/144>=(.95 if mode=='sham' else .80)
 for band in ('young','old'):
  e=sum(int(x['eligible_'+band]) for x in ww);b=sum(int(x['blocked_'+band]) for x in ww);target=mode in ((band,'both'))
  ratio=b/e if e else math.nan
  if target:assert .45<=ratio<=.55
  else:assert b==0
  print(' ',band,'eligible',e,'blocked',b,'ratio',ratio)
ref=read(p/'shard-4'/'runs.csv');refw=read(p/'shard-4'/'windows.csv');assert len(ref)==144 and len(refw)==2880
oldkey=lambda x:(int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode'],int(x['seed']),int(x['mono']))
with gzip.open(prior/'runs.csv.gz','rt') as f:old={oldkey(x):x for x in csv.DictReader(f) if int(x['seed'])==61001}
with gzip.open(prior/'windows.csv.gz','rt') as f:ow={oldkey(x)+(int(x['hi']),):x for x in csv.DictReader(f) if int(x['seed'])==61001}
assert len(old)==144 and len(ow)==2880
for x in ref:
 y=old[oldkey(x)]
 for c in ('physical_hash','panel_hash','final_tick','final_agents','min_population','max_population','cap_ticks','exposure','births','deaths'):assert x[c]==y[c],(c,x,y)
 assert math.isclose(float(x['food']),float(y['food']),rel_tol=1e-11,abs_tol=1e-6)
for x in refw:
 y=ow[oldkey(x)+(int(x['hi']),)]
 for c in ('lo','hi','nstart','nend','pre_exposure','post_exposure','births','deaths'):assert x[c]==y[c]
 assert math.isclose(float(x['food']),float(y['food']),rel_tol=1e-11,abs_tol=1e-6)
srcold=read(prior/'sources.csv');match=[x for x in srcold if x['seed']=='61001'][0];assert source[4]['source_hash']==match['source_hash'] and source[4]['panel_hash']==match['panel_hash']
print('PASS: 576 intervention runs and 11520 ledgers matched; gate accounting passed; prior no-op replay matched all 144 runs and 2880 windows.')
