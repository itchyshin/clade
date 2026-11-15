import csv,sys,math,collections
from pathlib import Path
p=Path(sys.argv[1]);key=lambda r:(int(r['seed']),int(r['density']),int(r['threshold']),float(r['food_rate']),r['age_mode']);totals=collections.defaultdict(lambda:[[0.0]*8,[0.0]*8]);counts=collections.Counter()
with open(p/'windows.csv',newline='') as f:
 for r in csv.DictReader(f):
  if int(r['mono'])!=0:continue
  k=key(r);counts[k]+=1
  for j,m in enumerate(('births','food')):
   a=list(map(float,r[m+'_by_policy_age'].split(':')))
   for i in range(8):totals[k][j][i]+=sum(a[8*g+i] for g in range(4))
blocks={key(x):x for x in csv.DictReader(open(p/'blocks.csv'))};assert set(blocks)==set(totals)
for k,z in totals.items():
 assert counts[k]==20
 for j,m in enumerate(('mix_birth_dominance','mix_food_dominance')):
  total=sum(z[j]);v=max(z[j])/total if total else None
  if v is None:assert blocks[k][m]==''
  else:assert math.isclose(v,float(blocks[k][m]),abs_tol=1e-10)
with open(p/'policy-top-match.csv','w',newline='') as f:
 out=csv.writer(f);out.writerow(['seed','density','threshold','food_rate','age_mode','same_top','birth_tied','food_tied'])
 for k,z in sorted(totals.items()):
  mb=max(z[0]);mf=max(z[1]);bp=[i for i,x in enumerate(z[0]) if x==mb];fp=[i for i,x in enumerate(z[1]) if x==mf]
  out.writerow([*k,int(bp[0]==fp[0]),int(len(bp)>1),int(len(fp)>1)])
s=list(csv.DictReader(open(p/'policy-dominance-food-contrast.csv')))
for r in s:
 n=int(r['density']);q=int(r['threshold']);age=r['age_mode'];metric=r['metric'];seeds=sorted({k[0] for k in blocks});v=[]
 for seed in seeds:
  a=blocks[(seed,n,q,.025,age)][metric];b=blocks[(seed,n,q,.05,age)][metric]
  if a and b:v.append(float(a)-float(b))
 assert len(v)==int(r['n']) and len(seeds)-len(v)==int(r['undefined'])
 if v:assert math.isclose(sum(v)/len(v),float(r['mean']),abs_tol=1e-10)
print(f'PASS: recomputed policy dominance from {sum(counts.values())} mixture windows and independently reconstructed {len(s)} paired dominance means.')
