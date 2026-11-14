import csv,sys,collections,math
from pathlib import Path
p=Path(sys.argv[1]);read=lambda n:list(csv.DictReader(open(p/(n+'.csv'))));r=read('runs');w=read('windows');src=read('sources');summary=read('summary')
key=lambda z:(int(z['density']),int(z['threshold']),float(z['food_rate']),z['age_mode'],int(z['seed']),int(z['mono']))
a={key(z):z for z in r};assert len(a)==len(r)==len(src)*144
ws=collections.defaultdict(list)
for z in w:ws[key(z)].append(z)
assert set(a)==set(ws)
for k,z in a.items():
 v=sorted(ws[k],key=lambda x:int(x['lo']));assert len(v)==20;last=k[0]
 for i,x in enumerate(v):
  assert int(x['lo'])==50*i+1 and int(x['hi'])==50*i+50 and int(x['nstart'])==last
  assert int(x['nend'])==last+int(x['births'])-int(x['deaths']);last=int(x['nend'])
 assert last==int(z['final_agents']) and sum(int(x['births']) for x in v)==int(z['births']) and sum(int(x['deaths']) for x in v)==int(z['deaths'])
blocks={}
for n,q,f,age,seed,_ in a:
 if (n,q,f,age,seed,800) in blocks:continue
 rr=[a[(n,q,f,age,seed,i)] for i in range(9)];assert len({z['physical_hash'] for z in rr})==len({z['panel_hash'] for z in rr})==1
 for t in (800,1000):
  vals=[int(next(x['nend'] for x in ws[key(z)] if int(x['hi'])==t)) for z in rr]
  blocks[(n,q,f,age,seed,t)]=vals[0]-sum(vals[1:])/8
seeds=sorted(int(z['seed']) for z in src)
for row in summary:
 typ=row['type'];parts=row['label'].split();t=int(row['tick']);d=[]
 for seed in seeds:
  D=lambda n,q,f,age,tick=t:blocks[(n,q,f,age,seed,tick)]
  F=lambda n,q,age:D(n,q,.025,age)-D(n,q,.05,age)
  if typ=='cell':n,q,f,age=int(parts[0]),int(parts[1]),float(parts[2]),parts[3];v=D(n,q,f,age)
  elif typ=='food':n,q,age=int(parts[0]),int(parts[1]),parts[2];v=F(n,q,age)
  elif typ=='threshold_change':n,age=int(parts[0]),parts[1];v=F(n,80,age)-F(n,120,age)
  elif typ=='density_change':q,age=int(parts[0]),parts[1];v=F(96,q,age)-F(48,q,age)
  elif typ=='interaction':age=parts[0];v=(F(96,80,age)-F(96,120,age))-(F(48,80,age)-F(48,120,age))
  elif typ=='time_change':n,q,f,age=int(parts[0]),int(parts[1]),float(parts[2]),parts[3];v=D(n,q,f,age,1000)-D(n,q,f,age,800)
  else:raise ValueError(typ)
  d.append(v)
 assert math.isclose(sum(d)/len(d),float(row['mean']),abs_tol=1e-9),(row, sum(d)/len(d))
print(f'PASS: {len(src)} source blocks, {len(r)} assay runs, {len(w)} windows, physical/panel matches and {len(summary)} summary means independently reconstructed.')
