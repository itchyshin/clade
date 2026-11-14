import csv,collections,math,sys
from pathlib import Path
trace=Path(sys.argv[1]);factorial=Path(sys.argv[2]);out=Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
prior={}
with open(factorial,newline='') as f:
 for r in csv.DictReader(f):
  if r['ploidy']=='1' and float(r['food_rate'])==.05 and r['age_mode']=='fixed':prior[(int(r['seed']),int(r['mono']),int(r['hi']))]=r
assert len(prior)==18000
g=collections.defaultdict(list)
with open(trace,newline='') as f:
 for r in csv.DictReader(f):g[(int(r['seed']),int(r['mono']),int(r['tick']))].append(r)
assert set(g)==set(prior)
for k,rows in g.items():
 rows.sort(key=lambda x:int(x['policy']));assert len(rows)==8 and [int(x['policy']) for x in rows]==list(range(1,9))
 w=prior[k];n=int(w['nend']);assert all(int(x['n_total'])==n for x in rows)
 for field,old in [('n_policy','nend'),('births','births'),('deaths','deaths'),('exposure','pre_exposure')]:assert sum(int(x[field]) for x in rows)==int(w[old]),(k,field)
 assert abs(float(rows[0]['food'])-float(w['food']))<1e-7
 assert len({x['physical_hash'] for x in rows})==1
for seed in range(20001,20101):
 assert len({g[(seed,mono,50)][0]['physical_hash'] for mono in range(9)})==1
fields=['seed','tick','n_mix','n_control','advantage','density_mix','density_control','grass_mix','grass_control','food_mix','food_control','surviving_policies','effective_policies','dominant_frequency','composition','residual']
with open(out/'blocks.csv','w',newline='') as f:
 writer=csv.DictWriter(f,fieldnames=fields);writer.writeheader()
 for seed in range(20001,20101):
  for tick in range(50,1001,50):
   mix=g[seed,0,tick];monos=[g[seed,j,tick] for j in range(1,9)]
   ns=[int(x['n_policy']) for x in mix];n=sum(ns);ms=[int(x[0]['n_total']) for x in monos];base=sum(ms)/8
   if n:
    freq=[x/n for x in ns];effective=1/sum(x*x for x in freq);dom=max(freq);weighted=sum(a*b for a,b in zip(freq,ms));comp=weighted-base;resid=n-weighted
    assert math.isclose(comp+resid,n-base,abs_tol=1e-9)
   else:effective=dom=comp=resid=math.nan
   writer.writerow(dict(seed=seed,tick=tick,n_mix=n,n_control=base,advantage=n-base,density_mix=n/900,density_control=base/900,
    grass_mix=float(mix[0]['grass'])/900,grass_control=sum(float(x[0]['grass']) for x in monos)/8/900,
    food_mix=float(mix[0]['food']),food_control=sum(float(x[0]['food']) for x in monos)/8,
    surviving_policies=sum(x>0 for x in ns),effective_policies=effective,dominant_frequency=dom,composition=comp,residual=resid))
print(f'PASS: {len(g)} matched prior windows and {sum(map(len,g.values()))} policy rows satisfy counts, births, deaths, exposures, food and initial-state checks; decomposition identity holds')
