import csv,math,sys
from pathlib import Path
p=Path(sys.argv[1]);blocks=list(csv.DictReader(open(p/'blocks.csv')));summary=list(csv.DictReader(open(p/'summary.csv')))
key=lambda x:(int(x['seed']),int(x['density']),int(x['threshold']),float(x['food_rate']),x['age_mode']);b={key(x):x for x in blocks};seeds=sorted({int(x['seed']) for x in blocks});assert len(b)==len(blocks)==16*len(seeds)
for z in blocks:
 assert math.isclose(float(z['population']),float(z['births'])-float(z['deaths']),abs_tol=1e-7)
 for metric in ('births','deaths','food','exposure'):
  assert math.isclose(float(z[metric]),sum(float(z[f'{metric}_age{a}']) for a in range(1,5)),rel_tol=1e-10,abs_tol=1e-6)
  assert math.isclose(float(z[metric]),sum(float(z[f'{metric}_policy{k}']) for k in range(1,9)),rel_tol=1e-10,abs_tol=1e-6)
for x in summary:
 typ=x['type'];parts=x['label'].split();metric=x['metric'];vals=[]
 for seed in seeds:
  def F(n,q,age):
   a=b[(seed,n,q,.025,age)][metric];c=b[(seed,n,q,.05,age)][metric]
   return float(a)-float(c) if a and c else math.nan
  if typ=='food_effect':v=F(int(parts[0]),int(parts[1]),parts[2])
  elif typ=='threshold_change':v=F(int(parts[0]),80,parts[1])-F(int(parts[0]),120,parts[1])
  elif typ=='density_change':v=F(96,int(parts[0]),parts[1])-F(48,int(parts[0]),parts[1])
  elif typ=='interaction':
   age=parts[0];v=(F(96,80,age)-F(96,120,age))-(F(48,80,age)-F(48,120,age))
  else:raise ValueError(typ)
  if math.isfinite(v):vals.append(v)
 assert len(vals)==int(x['n']) and len(seeds)-len(vals)==int(x['undefined'])
 if len(vals)>=2:assert math.isclose(sum(vals)/len(vals),float(x['mean']),rel_tol=1e-9,abs_tol=1e-7),(x,sum(vals)/len(vals))
print(f'PASS: {len(seeds)} seed blocks; age and policy contributions, population identities and {len(summary)} factorial summary means independently reconstructed.')
