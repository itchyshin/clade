import csv,collections,math,sys
from pathlib import Path
root=Path(sys.argv[1]);runs=list(csv.DictReader(open(root/'runs.csv')));windows=list(csv.DictReader(open(root/'windows.csv')));summary=list(csv.DictReader(open(root/'factorial_summary.csv')))
key=lambda r:(int(r['ploidy']),float(r['food_rate']),r['age_mode'],int(r['seed']),int(r['mono']))
expected={(p,f,a,s,m) for p in (1,2) for f in (.05,.025,.0125) for a in ('fixed','staggered') for s in range(20001,20101) for m in range(9)}
rm={key(r):r for r in runs};assert len(runs)==len(rm)==10800 and set(rm)==expected
wg=collections.defaultdict(list)
for r in windows:wg[key(r)].append(r)
assert len(windows)==216000 and set(wg)==expected
for k,r in rm.items():
 rows=sorted(wg[k],key=lambda x:int(x['lo']));assert len(rows)==20 and int(rows[0]['nstart'])==48
 assert sum(int(x['births']) for x in rows)==int(r['births']) and sum(int(x['deaths']) for x in rows)==int(r['deaths'])
 assert sum(int(x['pre_exposure']) for x in rows)==int(r['exposure']) and int(rows[-1]['nend'])==int(r['final_agents'])
 for i,x in enumerate(rows):
  assert int(x['lo'])==1+50*i and int(x['hi'])==50*(i+1)
  assert int(x['nend'])==int(x['nstart'])+int(x['births'])-int(x['deaths'])
  assert int(x['pre_exposure'])==int(x['post_exposure'])+int(x['nstart'])-int(x['nend'])
  if i:assert rows[i-1]['nend']==x['nstart']
def delta(p,f,a,s,metric):
 y=[int(rm[(p,f,a,s,j)]['final_agents']) for j in range(9)]
 if metric=='extinct':y=[int(x==0) for x in y]
 return y[0]-sum(y[1:])/8
for row in summary:
 p=int(row['ploidy']);metric=row['metric'];typ=row['type'];labels=row['label'].split();ds=[]
 for seed in range(20001,20101):
  if typ=='cell':v=delta(p,float(labels[0]),labels[1],seed,metric)
  elif typ=='age_effect':
   f=float(labels[0]);v=delta(p,f,'staggered',seed,metric)-delta(p,f,'fixed',seed,metric)
  elif typ=='food_effect':
   f=float(labels[0]);a=labels[1];v=delta(p,f,a,seed,metric)-delta(p,.05,a,seed,metric)
  elif typ=='regrowth_effect':
   a=labels[0];v=delta(p,.0125,a,seed,metric)-delta(p,.025,a,seed,metric)
  elif typ=='regrowth_interaction':
   v=(delta(p,.0125,'staggered',seed,metric)-delta(p,.0125,'fixed',seed,metric))-(delta(p,.025,'staggered',seed,metric)-delta(p,.025,'fixed',seed,metric))
  else:
   f=float(labels[0]);v=(delta(p,f,'staggered',seed,metric)-delta(p,f,'fixed',seed,metric))-(delta(p,.05,'staggered',seed,metric)-delta(p,.05,'fixed',seed,metric))
  ds.append(v)
 assert int(row['n'])==100 and math.isclose(sum(ds)/100,float(row['mean']),abs_tol=1e-10),(typ,labels)
print(f'PASS: {len(runs)} complete keys, {len(windows)} 50-tick windows, all population/birth/death/exposure ledgers and every factorial mean reconstructed independently.')
