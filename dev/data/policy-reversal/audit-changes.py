import csv,math,sys
from pathlib import Path
p=Path(sys.argv[1]);blocks={(int(r['seed']),int(r['tick'])):r for r in csv.DictReader(open(p/'blocks.csv'))}
rows=list(csv.DictReader(open(p/'demography-blocks.csv')));assert len(rows)==300
for r in rows:
 seed=int(r['seed']);lo=int(r['lo']);hi=int(r['hi']);left=float(blocks[(seed,lo)]['advantage']);right=float(blocks[(seed,hi)]['advantage'])
 assert math.isclose(right-left,float(r['net_difference']),abs_tol=1e-9),(seed,lo,hi)
 assert math.isclose(float(r['birth_difference'])-float(r['death_difference']),float(r['net_difference']),abs_tol=1e-9)
print('PASS: all 300 seed/interval changes exactly equal the independent birth-minus-death accounting and endpoint advantage differences.')
