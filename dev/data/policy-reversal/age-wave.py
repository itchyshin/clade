import csv,collections,statistics,sys
from pathlib import Path
p=Path(sys.argv[1]);out=Path(sys.argv[2]);d=collections.defaultdict(dict)
with open(p,newline='') as f:
 for r in csv.DictReader(f):
  if r['ploidy']=='1' and float(r['food_rate'])==.05:
   d[(r['age_mode'],int(r['seed']),int(r['hi']))][int(r['mono'])]=int(r['nend'])
with open(out,'w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['seed','tick','fixed_advantage','staggered_advantage','staggered_minus_fixed']);w.writeheader()
 for seed in range(20001,20101):
  for tick in range(50,1001,50):
   vals=[]
   for age in ('fixed','staggered'):
    z=d[(age,seed,tick)];assert set(z)==set(range(9));vals.append(z[0]-sum(z[i] for i in range(1,9))/8)
   w.writerow(dict(seed=seed,tick=tick,fixed_advantage=vals[0],staggered_advantage=vals[1],staggered_minus_fixed=vals[1]-vals[0]))
print('Matched fixed and staggered 50-tick advantages reconstructed for 100 seeds.')
