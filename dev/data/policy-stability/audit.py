import csv,sys,collections,math
from pathlib import Path
p=Path(sys.argv[1]);read=lambda name:list(csv.DictReader(open(p/(name+'.csv'))))
r=read('runs');w=read('windows');sources=read('sources');summary=read('summary');key=lambda x:(x['food_rate'],x['age_mode'],int(x['seed']),int(x['mono']))
a={key(x):x for x in r};assert len(a)==len(r)==36*len(sources)
ws=collections.defaultdict(list)
for x in w:ws[key(x)].append(x)
assert set(a)==set(ws)
for k,x in a.items():
 v=sorted(ws[k],key=lambda z:int(z['lo']));assert len(v)==20
 last=96
 for i,z in enumerate(v):
  assert int(z['lo'])==i*50+1 and int(z['hi'])==i*50+50 and int(z['nstart'])==last
  assert int(z['nend'])==last+int(z['births'])-int(z['deaths']);last=int(z['nend'])
 assert last==int(x['final_agents']) and sum(int(z['births']) for z in v)==int(x['births']) and sum(int(z['deaths']) for z in v)==int(x['deaths'])
blocks={}
for rate,age,seed,_ in a:
 k=(rate,age,seed)
 if k in blocks:continue
 rr=[a[(rate,age,seed,i)] for i in range(9)];assert len({x['physical_hash'] for x in rr})==1 and len({x['panel_hash'] for x in rr})==1
 for t in (800,1000):
  vals=[int(next(z['nend'] for z in ws[key(x)] if int(z['hi'])==t)) for x in rr]
  blocks[(rate,age,seed,t)]=vals[0]-sum(vals[1:])/8
for row in summary:
 typ=row['type'];t=int(row['tick']);seeds=sorted(int(x['seed']) for x in sources)
 d=[]
 for seed in seeds:
  g=lambda rate,age:blocks[(rate,age,seed,t)]
  if typ in ('cell','change'):
   rate,age=row['label'].split();v=g(rate,age)-(blocks[(rate,age,seed,800)] if typ=='change' else 0)
  elif typ=='food':v=g('0.025',row['label'])-g('0.05',row['label'])
  elif typ=='age':v=g(row['label'],'staggered')-g(row['label'],'fixed')
  elif typ=='interaction':v=(g('0.025','staggered')-g('0.025','fixed'))-(g('0.05','staggered')-g('0.05','fixed'))
  else:raise ValueError(typ)
  d.append(v)
 assert math.isclose(sum(d)/len(d),float(row['mean']),abs_tol=1e-10)
print(f'PASS: {len(sources)} source seeds, {len(a)} runs, {len(w)} window ledgers, all physical/panel matches and all summary means independently reconstructed.')
