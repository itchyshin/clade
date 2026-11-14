import csv,collections,math,sys
from pathlib import Path
p=Path(sys.argv[1]);b={};h={}
for name,d in [('blocks.csv',b),('high-blocks.csv',h)]:
 with open(p/name,newline='') as f:
  for r in csv.DictReader(f):d[(int(r['seed']),int(r['tick']))]=r
assert len(b)==len(h)==2000 and set(b)==set(h)
with open(p/'regrowth-effects.csv') as f:
 for r in csv.DictReader(f):
  tick=int(r['tick']);m=r['metric'];v=[float(h[(s,tick)][m])-float(b[(s,tick)][m]) for s in range(20001,20101)]
  assert int(r['n'])==len(v) and math.isclose(sum(v)/len(v),float(r['mean']),abs_tol=1e-10),(tick,m)
print('PASS: all paired higher-minus-original regrowth means independently reconstructed from 2,000 matched blocks.')
