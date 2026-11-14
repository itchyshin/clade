import csv,collections,math,sys
from pathlib import Path
p=Path(sys.argv[1]);runs=list(csv.DictReader(open(p/'runs.csv')));prior={(int(r['seed']),int(r['tick'])):r for r in csv.DictReader(open(p/'prior-blocks.csv'))};blocks={(int(r['seed']),int(r['tick'])):r for r in csv.DictReader(open(p/'blocks.csv'))};summary=list(csv.DictReader(open(p/'summary.csv')))
k=lambda r:(int(r['seed']),r['mode'],int(r['tick']))
rm={k(r):r for r in runs};assert len(runs)==len(rm)==6000 and len(prior)==len(blocks)==2000
for s in range(20001,20101):
 arms=[rm[(s,m,600)] for m in ('natural','shuffle','balanced')];assert len({x['pre_hash'] for x in arms})==1
 before=[[int(v) for v in x['counts_before'].split(':')] for x in arms];after=[[int(v) for v in x['counts_after'].split(':')] for x in arms]
 assert before[0]==before[1]==before[2] and before[0]==after[0]==after[1] and max(after[2])-min(after[2])<=1
 for mode in ('natural','shuffle','balanced'):
  for t in range(50,1001,50):
   z=rm[(s,mode,t)];assert z['pre_hash']==z['post_hash'];assert sum(map(int,z['policy_counts'].split(':')))==int(z['n'])
   if mode=='natural' or t<=600:assert int(z['n'])==int(prior[(s,t)]['n_mix']) and math.isclose(float(z['grass'])/900,float(prior[(s,t)]['grass_mix']),abs_tol=1e-8)
   row=blocks[(s,t)];assert int(row['n_'+mode])==int(z['n'])

for r in summary:
 tick=int(r['tick']);m=r['metric'];v=[float(blocks[(s,tick)][m]) for s in range(20001,20101)]
 assert int(r['n'])==100 and math.isclose(sum(v)/100,float(r['mean']),abs_tol=1e-10),(tick,m)
print('PASS: 6000 unique arm/checkpoint rows; matched physical hashes, exact policy assignments, prior trajectory, and all summary means independently reconstructed.')
