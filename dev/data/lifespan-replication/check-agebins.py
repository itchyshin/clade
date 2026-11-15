import collections,csv,pathlib,sys
root=pathlib.Path(sys.argv[1]);out=root/'age-bin-audit.csv';rows=[]
for seed in range(86001,86006):
 d=root/'400'/str(seed);key=lambda x:(int(x['threshold']),float(x['food']),x['age_mode'],int(x['mono']))
 runs={key(x):x for x in csv.DictReader(open(d/'runs.csv'))};counts=collections.defaultdict(lambda:[0,0])
 for x in csv.DictReader(open(d/'events.csv')):
  age=int(x['age']);n=int(x['births']);k=key(x)
  if 150<=age<300:counts[k][0]+=n
  elif age>=300:counts[k][1]+=n
 for k,r in runs.items():
  a,b=counts[k];assert a+b==int(r['birth_age4'])
  rows.append(dict(seed=seed,threshold=k[0],food=k[1],age_mode=k[2],mono=k[3],births_150_299=a,births_300_plus=b))
with open(out,'w') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
print(f'PASS: {len(rows)} validation runs reconcile 150+ births into 150–299 and 300+ age bands')
