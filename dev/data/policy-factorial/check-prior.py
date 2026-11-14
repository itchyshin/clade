import csv,gzip,sys
from collections import defaultdict
from pathlib import Path
p=Path(sys.argv[1]);previous=Path('dev/data/policy-long/results');earlier=Path('dev/data/policy-mixture/results')
for name in ('runs','windows'):
 with gzip.open(previous/(name+'.csv.gz'),'rt',newline='') as f:a=list(csv.DictReader(f))
 with open(p/(name+'.csv')) as f:b=[{k:v for k,v in x.items() if k!='age_mode'} for x in csv.DictReader(f) if x['age_mode']=='staggered' and float(x['food_rate'])!=.05]
 key=lambda r:(int(r['ploidy']),float(r['food_rate']),int(r['seed']),int(r['mono']),int(r.get('lo',0)))
 a.sort(key=key);b.sort(key=key);assert a==b,(name,len(a),len(b))
 print(f'{name}: all {len(a)} prior staggered limited-food rows and fields match exactly')
with gzip.open(earlier/'runs.csv.gz','rt',newline='') as f:old=[r for r in csv.DictReader(f) if r['mode']=='demography' and float(r['source_mutation'])==.2]
with open(p/'windows.csv') as f:rows=[r for r in csv.DictReader(f) if r['age_mode']=='fixed' and float(r['food_rate'])==.05 and int(r['hi'])<=300]
g=defaultdict(list)
for r in rows:g[(r['ploidy'],r['seed'],r['mono'])].append(r)
for r in old:
 ws=sorted(g[(r['ploidy'],r['seed'],r['mono'])],key=lambda x:int(x['lo']))
 assert len(ws)==6 and int(ws[-1]['nend'])==int(r['final_agents']) and sum(int(x['births']) for x in ws)==int(r['births']) and sum(int(x['deaths']) for x in ws)==int(r['deaths'])
assert len(old)==1800
print('All 1800 earlier 300-tick baseline runs match population, births and deaths')
