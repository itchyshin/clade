import csv,collections,math,sys
from pathlib import Path
trace=Path(sys.argv[1]);baseline=Path(sys.argv[2]);out=Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
g=collections.defaultdict(list);bg=collections.defaultdict(list)
for path,store in ((trace,g),(baseline,bg)):
 with open(path,newline='') as f:
  for r in csv.DictReader(f):store[(int(r['seed']),int(r['mono']),int(r['tick']))].append(r)
expected={(s,m,t) for s in range(20001,20101) for m in range(9) for t in range(50,1001,50)}
assert set(g)==set(bg)==expected
for seed in range(20001,20101):
 for mono in range(9):
  old=[6]*8 if mono==0 else [48 if i+1==mono else 0 for i in range(8)]
  for tick in range(50,1001,50):
   k=(seed,mono,tick);rows=sorted(g[k],key=lambda x:int(x['policy']));base=bg[k]
   assert len(rows)==len(base)==8 and [int(x['policy']) for x in rows]==list(range(1,9))
   assert len({x['physical_hash'] for x in rows})==1 and rows[0]['physical_hash']==base[0]['physical_hash']
   assert len({x['n_total'] for x in rows})==len({x['capacity_ticks'] for x in rows})==len({x['max_population'] for x in rows})==1
   assert 0<=int(rows[0]['capacity_ticks'])<=50 and int(rows[0]['max_population'])<=500
   now=[int(x['n_policy']) for x in rows];assert sum(now)==int(rows[0]['n_total'])
   for i,x in enumerate(rows):
    assert now[i]==old[i]+int(x['births'])-int(x['deaths'])
    assert int(x['exposure'])>=0
   assert 0<=float(rows[0]['food'])<=2*sum(int(x['exposure']) for x in rows)+1e-7
   old=now
   g[k]=rows
fields=['seed','tick','n_mix','n_control','advantage','density_mix','density_control','grass_mix','grass_control','food_mix','food_control','surviving_policies','effective_policies','dominant_frequency','composition','residual','mix_cap_ticks','control_cap_ticks']
with open(out/'high-blocks.csv','w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
 for seed in range(20001,20101):
  for tick in range(50,1001,50):
   mix=g[seed,0,tick];monos=[g[seed,j,tick] for j in range(1,9)];ns=[int(x['n_policy']) for x in mix];n=sum(ns);ms=[int(x[0]['n_total']) for x in monos];base=sum(ms)/8
   if n:
    freq=[x/n for x in ns];eff=1/sum(x*x for x in freq);dominant=max(freq);weighted=sum(a*b for a,b in zip(freq,ms));comp=weighted-base;resid=n-weighted;assert math.isclose(comp+resid,n-base,abs_tol=1e-9)
   else:eff=dominant=comp=resid=math.nan
   w.writerow(dict(seed=seed,tick=tick,n_mix=n,n_control=base,advantage=n-base,density_mix=n/900,density_control=base/900,
    grass_mix=float(mix[0]['grass'])/900,grass_control=sum(float(x[0]['grass']) for x in monos)/8/900,
    food_mix=float(mix[0]['food']),food_control=sum(float(x[0]['food']) for x in monos)/8,
    surviving_policies=sum(x>0 for x in ns),effective_policies=eff,dominant_frequency=dominant,composition=comp,residual=resid,
    mix_cap_ticks=int(mix[0]['capacity_ticks']),control_cap_ticks=sum(int(x[0]['capacity_ticks']) for x in monos)/8))
print('PASS: 18,000 high-regrowth windows, 144,000 policy rows, all group/policy ledgers, cap bounds and exact physical matching to original conditions.')
