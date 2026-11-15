import csv,sys,math
from pathlib import Path
p=Path(sys.argv[1]);prior=Path(sys.argv[2]);a=list(csv.DictReader(open(p/'summary.csv')));b=list(csv.DictReader(open(prior/'summary.csv')))
maptype={'food_effect':'food','threshold_change':'threshold_change','density_change':'density_change','interaction':'interaction'}
old={(x['type'],x['label']):x for x in b if x['tick']=='1000' and x['type'] in maptype.values()}
seen=0
for x in a:
 if x['metric']!='population':continue
 y=old[(maptype[x['type']],x['label'])]
 for z in ('mean','lower','upper'):
  assert math.isclose(float(x[z]),float(y[z]),rel_tol=1e-9,abs_tol=1e-7),(x,y,z)
 seen+=1
assert seen==len(old)==18
print('PASS: all 18 population food and factorial contrasts and paired intervals match the original study.')
