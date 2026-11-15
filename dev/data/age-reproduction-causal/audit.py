import csv,sys,math,collections
from pathlib import Path
p=Path(sys.argv[1]);read=lambda n:list(csv.DictReader(open(p/(n+'.csv'),newline='')));runs=read('runs');blocks=read('blocks');summary=read('summary');events=read('gate-events')
key=lambda x:(x['gate'],int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode'],int(x['seed']),int(x['mono']))
r={key(x):x for x in runs};seeds=sorted({int(x['seed']) for x in runs});assert len(r)==len(runs)==576*len(seeds)
sources={int(x['seed']):x for x in read('sources')};assert set(sources)==set(seeds)
for seed in seeds:
 for n in (48,96):
  for q in (120,80):
   for f in (.05,.025):
    for age in ('fixed','staggered'):
     z=[r[(gate,n,q,f,age,seed,mono)] for gate in ('sham','young','old','both') for mono in range(9)]
     assert len({x['physical_hash'] for x in z})==1 and all(x['panel_hash']==sources[seed]['panel_hash'] for x in z)
g={};sumevents=collections.defaultdict(lambda:[0,0,0,0]);rows=0
with open(p/'windows.csv',newline='') as f:
 for x in csv.DictReader(f):
  k=key(x);assert k in r;z=g.setdefault(k,{'step':0,'last':k[1],'n800':None,'births':0,'deaths':0,'food':0.0,'exposure':0,'age':[0]*4,'gate_counts':[0]*4});i=z['step'];assert int(x['lo'])==i*50+1 and int(x['hi'])==i*50+50 and int(x['nstart'])==z['last'];end=int(x['nend']);birth=int(x['births']);death=int(x['deaths']);assert end==z['last']+birth-death
  vals=[int(x[f'birth_age{i}']) for i in range(1,5)];assert sum(vals)==birth
  for j,v in enumerate(vals):z['age'][j]+=v
  for j,name in enumerate(('eligible_young','blocked_young','eligible_old','blocked_old')):
   v=int(x[name]);sumevents[k[0]][j]+=v;z['gate_counts'][j]+=v
   if name=='blocked_young' and k[0] not in ('young','both'):assert v==0
   if name=='blocked_old' and k[0] not in ('old','both'):assert v==0
  z['births']+=birth;z['deaths']+=death;z['food']+=float(x['food']);z['exposure']+=int(x['pre_exposure']);z['last']=end;z['step']+=1;rows+=1
  if i==15:z['n800']=end
assert len(g)==len(r) and rows==len(r)*20
for k,z in g.items():
 x=r[k];assert z['step']==20 and z['last']==int(x['final_agents']) and z['births']==int(x['births']) and z['deaths']==int(x['deaths']) and z['exposure']==int(x['exposure']) and math.isclose(z['food'],float(x['food']),abs_tol=1e-5,rel_tol=1e-10)
for e in events:
 assert [int(e[x]) for x in ('eligible_young','blocked_young','eligible_old','blocked_old')]==sumevents[e['gate']]
def bc(x):return (x['gate'],int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode'],int(x['seed']))
b={bc(x):x for x in blocks};assert len(b)==len(blocks)==64*len(seeds)
for k,x in b.items():
 zs=[g[k+(i,)] for i in range(9)]
 value=lambda z,m: z['n800'] if m=='population800' else z['last'] if m=='population1000' else z['age'][int(m[-1])-1] if m.startswith('birth_age') else z[m]
 for m in ('population800','population1000','births','deaths','food','exposure','birth_age1','birth_age2','birth_age3','birth_age4'):
  v=[value(z,m) for z in zs];assert math.isclose(v[0]-sum(v[1:])/8,float(x[m]),abs_tol=1e-7,rel_tol=1e-10)
cellcheck=collections.defaultdict(lambda:{'n':0,'age':[0]*4,'gate_counts':[0]*4})
for k,z in g.items():
 gate,n,q,food,age,seed,mono=k;group='mixture' if mono==0 else 'control';v=cellcheck[(gate,n,q,food,age,group)];v['n']+=1
 for j in range(4):v['age'][j]+=z['age'][j];v['gate_counts'][j]+=z['gate_counts'][j]
cellrows=read('age-births-by-cell');assert len(cellrows)==len(cellcheck)
for x in cellrows:
 k=(x['gate'],int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode'],x['group']);v=cellcheck[k];assert int(x['runs'])==v['n']
 for j in range(4):assert math.isclose(float(x[f'mean_birth_age{j+1}']),v['age'][j]/v['n'],abs_tol=1e-8)
 for j,name in enumerate(('eligible_young','blocked_young','eligible_old','blocked_old')):assert int(x[name])==v['gate_counts'][j]
seedrows=read('age-births-by-seed');seedvalues={}
for x in seedrows:
 gate=x['gate'];n=int(x['density']);q=int(x['threshold']);food=float(x['food_rate']);age=x['age_mode'];seed=int(x['seed']);group=x['group'];kk=(gate,n,q,food,age,seed,group);assert kk not in seedvalues
 ms=(0,) if group=='mixture' else range(1,9);zs=[g[(gate,n,q,food,age,seed,i)] for i in ms]
 for j in range(4):assert math.isclose(float(x[f'birth_age{j+1}']),sum(z['age'][j] for z in zs)/len(zs),abs_tol=1e-8)
 assert math.isclose(float(x['population1000']),sum(z['last'] for z in zs)/len(zs),abs_tol=1e-8);seedvalues[kk]=x
assert len(seedvalues)==len(seeds)*128
gatebirth=read('gate-birth-effects')
for x in gatebirth:
 gate=x['gate'];n=int(x['density']);q=int(x['threshold']);food=float(x['food_rate']);age=x['age_mode'];group=x['group'];metric=x['metric'];v=[float(seedvalues[(gate,n,q,food,age,seed,group)][metric])-float(seedvalues[('sham',n,q,food,age,seed,group)][metric]) for seed in seeds]
 assert int(x['n'])==len(v) and math.isclose(sum(v)/len(v),float(x['mean']),abs_tol=1e-7)
for x in read('viability-summary'):
 gate=x['gate'];n=int(x['density']);q=int(x['threshold']);food=float(x['food_rate']);age=x['age_mode'];z=[r[(gate,n,q,food,age,seed,mono)] for seed in seeds for mono in range(9)]
 classes=collections.Counter('crashed' if int(v['final_agents'])<20 or int(v['final_agents'])/n<.2 else 'weak' if int(v['final_agents'])/n<.5 else 'viable' for v in z)
 for name in ('viable','weak','crashed'):assert int(x[name])==classes[name]
 assert int(x['runs'])==len(z) and int(x['extinct'])==sum(int(v['final_agents'])==0 for v in z) and int(x['stable'])==sum(int(v['min_population'])>=20 for v in z) and int(x['cap_ticks'])==sum(int(v['cap_ticks']) for v in z)
for row in summary:
 typ=row['type'];parts=row['label'].split();m=row['metric'];values=[]
 for seed in seeds:
  D=lambda gate,n,q,food,age:float(b[(gate,n,q,food,age,seed)][m])
  F=lambda gate,n,q,age:D(gate,n,q,.025,age)-D(gate,n,q,.05,age)
  T=lambda gate,n,age:F(gate,n,80,age)-F(gate,n,120,age)
  if typ=='threshold_effect':gate,n,age=parts[0],int(parts[1]),parts[2];v=T(gate,n,age)
  elif typ=='gate_effect_on_threshold':gate,n,age=parts[0],int(parts[1]),parts[2];v=T(gate,n,age)-T('sham',n,age)
  elif typ=='gate_interaction_on_threshold':n,age=int(parts[0]),parts[1];v=T('both',n,age)-T('young',n,age)-T('old',n,age)+T('sham',n,age)
  elif typ=='food_effect':gate,n,q,age=parts[0],int(parts[1]),int(parts[2]),parts[3];v=F(gate,n,q,age)
  else:raise ValueError(typ)
  values.append(v)
 assert int(row['n'])==len(values) and math.isclose(sum(values)/len(values),float(row['mean']),rel_tol=1e-9,abs_tol=1e-7)
print(f'PASS: {len(seeds)} source blocks, {len(r)} runs, {rows} window ledgers, gate counts, all block contrasts and {len(summary)} factorial and {len(gatebirth)} gate-birth means independently reconstructed.')
