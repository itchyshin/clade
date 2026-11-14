import csv,collections,sys
from pathlib import Path
p=Path(sys.argv[1]);g=collections.defaultdict(list)
with open(p/'trace.csv') as f:
 for r in csv.DictReader(f):g[(int(r['seed']),int(r['mono']),int(r['tick']))].append(r)
fields=['seed','lo','hi','birth_difference','death_difference','net_difference','birth_yield_difference','death_yield_difference','food_rate_difference','exposure_difference']
with open(p/'demography-blocks.csv','w',newline='') as f:
 wr=csv.DictWriter(f,fieldnames=fields);wr.writeheader()
 for seed in range(20001,20101):
  for lo,hi in ((300,600),(600,1000),(300,1000)):
   births=[];deaths=[];expo=[];food=[]
   for mono in range(9):
    rows=[r for t in range(lo+50,hi+1,50) for r in g[seed,mono,t]]
    births.append(sum(int(r['births']) for r in rows));deaths.append(sum(int(r['deaths']) for r in rows));expo.append(sum(int(r['exposure']) for r in rows));food.append(sum(float(r['food']) for r in rows if int(r['policy'])==1))
   diff=lambda x:x[0]-sum(x[1:])/8
   by=[1000*b/e if e else float('nan') for b,e in zip(births,expo)];dy=[1000*d/e if e else float('nan') for d,e in zip(deaths,expo)]
   wr.writerow(dict(seed=seed,lo=lo,hi=hi,birth_difference=diff(births),death_difference=diff(deaths),net_difference=diff(births)-diff(deaths),birth_yield_difference=diff(by),death_yield_difference=diff(dy),food_rate_difference=diff([f/e if e else float('nan') for f,e in zip(food,expo)]),exposure_difference=diff(expo)))
