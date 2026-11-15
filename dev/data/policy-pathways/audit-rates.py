import csv,sys,math,collections
from pathlib import Path
p=Path(sys.argv[1]);key=lambda r:(int(r['seed']),int(r['density']),int(r['threshold']),float(r['food_rate']),r['age_mode'],int(r['mono']));ms=('exposure','births','deaths','food');g={};seen=0
with open(p/'windows.csv',newline='') as f:
 for x in csv.DictReader(f):
  k=key(x);z=g.setdefault(k,{m:[0.0]*4 for m in ms});seen+=1
  for m in ms:
   v=list(map(float,x[m+'_by_policy_age'].split(':')));assert len(v)==32
   for a in range(4):z[m][a]+=sum(v[a*8:a*8+8])
assert len(g)*20==seen
with open(p/'blocks.csv',newline='') as f:
 for x in csv.DictReader(f):
  seed=int(x['seed']);n=int(x['density']);q=int(x['threshold']);rate=float(x['food_rate']);age=x['age_mode'];base=(seed,n,q,rate,age);mix=g[base+(0,)];controls=[g[base+(i,)] for i in range(1,9)]
  for m in ('births','deaths','food'):
   for a in (None,0,1,2,3):
    ix=range(4) if a is None else (a,);me=sum(mix['exposure'][i] for i in ix);ce=sum(c['exposure'][i] for c in controls for i in ix);name=f'{m}_rate_per1000' if a is None else f'{m}_rate_age{a+1}_per1000'
    if not me or not ce:assert x[name]=='';continue
    actual=1000*(sum(mix[m][i] for i in ix)/me-sum(c[m][i] for c in controls for i in ix)/ce)
    assert math.isclose(actual,float(x[name]),rel_tol=1e-9,abs_tol=1e-8),(base,name,actual,x[name])
print(f'PASS: independently reconstructed pooled-control and mixture rates from {seen} windows across {len(g)} runs.')
