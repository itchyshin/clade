import csv,collections,sys
from pathlib import Path
path=Path(sys.argv[1]);out=Path(sys.argv[2]);groups=collections.defaultdict(list)
with open(path,newline='') as f:
 for r in csv.DictReader(f):groups[(int(r['seed']),int(r['mono']),int(r['tick']))].append(r)
fields=['seed','tick','mixture_food_rate','control_food_rate','food_rate_difference','grass_difference']
with open(out,'w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
 for seed in range(20001,20101):
  for tick in range(50,1001,50):
   a=[groups[(seed,m,tick)] for m in range(9)];rates=[];grass=[]
   for rows in a:
    expo=sum(int(x['exposure']) for x in rows);rates.append(float(rows[0]['food'])/expo if expo else float('nan'));grass.append(float(rows[0]['grass'])/900)
   c=sum(rates[1:])/8;w.writerow(dict(seed=seed,tick=tick,mixture_food_rate=rates[0],control_food_rate=c,food_rate_difference=rates[0]-c,grass_difference=grass[0]-sum(grass[1:])/8))
