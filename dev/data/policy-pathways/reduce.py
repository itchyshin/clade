import csv,gzip,sys,math,collections
from pathlib import Path
p=Path(sys.argv[1]);prior=Path(sys.argv[2]);pilot_seed=int(sys.argv[3]) if len(sys.argv)>3 else None
op=lambda path: gzip.open(path,'rt',newline='') if str(path).endswith('.gz') else open(path,newline='')
def key(r):return (int(r['seed']),int(r['density']),int(r['threshold']),float(r['food_rate']),r['age_mode'],int(r['mono']))
old={};physical={}
with op(prior/'windows.csv.gz') as f:
 for x in csv.DictReader(f):
  if pilot_seed is not None and int(x['seed'])!=pilot_seed:continue
  old[key(x)+(int(x['hi']),)]=(int(x['nstart']),int(x['nend']),int(x['pre_exposure']),int(x['births']),int(x['deaths']),float(x['food']))
with op(prior/'runs.csv.gz') as f:
 for x in csv.DictReader(f):
  if pilot_seed is not None and int(x['seed'])!=pilot_seed:continue
  physical[key(x)]=x['physical_hash']
metrics=('exposure','births','deaths','food');groups={};seen=set();rows=0
with op(p/'windows.csv') as f:
 for x in csv.DictReader(f):
  k=key(x);t=int(x['hi']);k2=k+(t,);assert k2 not in seen and k2 in old;seen.add(k2);rows+=1
  vals=(int(x['nstart']),int(x['nend']),int(x['exposure']),int(x['births']),int(x['deaths']),float(x['food']))
  o=old[k2];assert vals[:5]==o[:5] and math.isclose(vals[5],o[5],rel_tol=1e-10,abs_tol=1e-5),(k2,vals,o)
  assert x['physical_hash']==physical[k] and vals[0]+vals[3]-vals[4]==vals[1]
  z=groups.setdefault(k,{'count':0,'times':set(),'vectors':{m:[0.0]*32 for m in metrics},'nend':None})
  z['count']+=1;z['times'].add(t)
  for m,total in zip(metrics,vals[2:]):
   arr=list(map(float,x[m+'_by_policy_age'].split(':')));assert len(arr)==32 and all(math.isfinite(a) and a>=0 for a in arr)
   assert math.isclose(sum(arr),total,rel_tol=1e-10,abs_tol=1e-5),(k2,m,sum(arr),total)
   for i,a in enumerate(arr):z['vectors'][m][i]+=a
  if t==1000:z['nend']=vals[1]
assert set(old)==seen and len(groups)==len(physical) and rows==20*len(groups)
for k,z in groups.items():assert z['count']==20 and z['times']==set(range(50,1001,50)) and z['nend'] is not None
seeds=sorted({k[0] for k in groups});assert len(groups)==len(seeds)*144
basecols=['seed','density','threshold','food_rate','age_mode'];fields=basecols+['population']
for m in metrics:
 fields += [m]+[f'{m}_age{a}' for a in range(1,5)]+[f'{m}_policy{k}' for k in range(1,9)]+[f'{m}_policy{k}_age{a}' for a in range(1,5) for k in range(1,9)]
fields += [name for m in ('food','births','deaths') for name in ([f'{m}_rate_per1000']+[f'{m}_rate_age{a}_per1000' for a in range(1,5)])]+['mix_birth_dominance','mix_food_dominance']
with open(p/'blocks.csv','w',newline='') as f:
 out=csv.DictWriter(f,fieldnames=fields);out.writeheader()
 for seed in seeds:
  for n in (48,96):
   for q in (120,80):
    for rate in (.05,.025):
     for age in ('fixed','staggered'):
      cell=(seed,n,q,rate,age);mix=groups[cell+(0,)];controls=[groups[cell+(k,)] for k in range(1,9)]
      row=dict(zip(basecols,cell));row['population']=mix['nend']-sum(z['nend'] for z in controls)/8
      for m in metrics:
       mv=mix['vectors'][m];cv=[z['vectors'][m] for z in controls]
       for k in range(8):
        assert all(abs(cv[k][a*8+j])<1e-8 for a in range(4) for j in range(8) if j!=k)
       diff=[mv[a*8+k]-cv[k][a*8+k]/8 for a in range(4) for k in range(8)]
       row[m]=sum(diff)
       for a in range(4):row[f'{m}_age{a+1}']=sum(diff[a*8:a*8+8])
       for k in range(8):row[f'{m}_policy{k+1}']=sum(diff[a*8+k] for a in range(4))
       for a in range(4):
        for k in range(8):row[f'{m}_policy{k+1}_age{a+1}']=diff[a*8+k]
      assert math.isclose(row['births']-row['deaths'],row['population'],abs_tol=1e-8)
      for m in ('food','births','deaths'):
       for a in (None,0,1,2,3):
        ix=list(range(32)) if a is None else list(range(a*8,a*8+8))
        mf=sum(mix['vectors'][m][i] for i in ix);me=sum(mix['vectors']['exposure'][i] for i in ix)
        cf=sum(c['vectors'][m][i] for c in controls for i in ix);ce=sum(c['vectors']['exposure'][i] for c in controls for i in ix)
        name=f'{m}_rate_per1000' if a is None else f'{m}_rate_age{a+1}_per1000'
        row[name]=1000*(mf/me-cf/ce) if me and ce else ''
      for metric,label in (('births','mix_birth_dominance'),('food','mix_food_dominance')):
       v=[sum(mix['vectors'][metric][a*8+k] for a in range(4)) for k in range(8)];row[label]=max(v)/sum(v) if sum(v)>0 else ''
      out.writerow(row)
print(f'PASS: exact replay of {rows} windows in {len(groups)} runs; policy-age sums and population identities checked; {len(seeds)} seed blocks retained.')
