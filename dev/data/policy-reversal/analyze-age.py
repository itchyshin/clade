import csv,collections,math,sys
from pathlib import Path
age=Path(sys.argv[1]);baseline=Path(sys.argv[2]);out=Path(sys.argv[3]);extra={'pre_count','pre_age_sum','pre_energy_sum','pre_ready','pre_age150'}
g=collections.defaultdict(list);bg={}
with open(baseline,newline='') as f:
 for r in csv.DictReader(f):bg[(int(r['seed']),int(r['mono']),int(r['tick']),int(r['policy']))]=r
with open(age,newline='') as f:
 for r in csv.DictReader(f):
  key=(int(r['seed']),int(r['mono']),int(r['tick']),int(r['policy']));assert {k:v for k,v in r.items() if k not in extra}==bg[key],key
  g[key[:3]].append(r)
assert len(bg)==144000 and len(g)==18000
fields=['seed','tick','mean_age_mix','mean_age_control','mean_age_difference','old_fraction_mix','old_fraction_control','old_fraction_difference','ready_fraction_mix','ready_fraction_control','ready_fraction_difference','pre_energy_mix','pre_energy_control','pre_energy_difference']
with open(out/'age-blocks.csv','w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
 for seed in range(20001,20101):
  for tick in range(50,1001,50):
   group=[g[(seed,m,tick)] for m in range(9)];vals=[]
   for rows in group:
    n=sum(int(r['pre_count']) for r in rows);assert n>0
    age=sum(float(r['pre_age_sum']) for r in rows)/n;energy=sum(float(r['pre_energy_sum']) for r in rows)/n;ready=sum(int(r['pre_ready']) for r in rows)/n;old=sum(int(r['pre_age150']) for r in rows)/n
    assert 0<=ready<=1 and 0<=old<=1
    vals.append((age,old,ready,energy))
   row={'seed':seed,'tick':tick}
   for i,name in enumerate(('mean_age','old_fraction','ready_fraction','pre_energy')):
    mix=vals[0][i];control=sum(x[i] for x in vals[1:])/8;row[name+'_mix']=mix;row[name+'_control']=control;row[name+'_difference']=mix-control
   w.writerow(row)
print('PASS: all 144000 age-replay rows exactly reproduce previous trace fields; 18000 group snapshots have valid pre-reproduction ages, energy and eligibility counts.')
