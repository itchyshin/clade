import csv,collections,math,sys
from pathlib import Path
p=Path(sys.argv[1]);runs=list(csv.DictReader(open(p/'runs.csv')));windows=list(csv.DictReader(open(p/'windows.csv')));summ=list(csv.DictReader(open(p/'summary.csv')))
key=lambda r:(int(r['ploidy']),float(r['food_rate']),int(r['seed']),int(r['mono']))
rmap={key(r):r for r in runs};assert len(runs)==len(rmap)==3600
wmap={(key(w),int(w['hi'])):w for w in windows};assert len(windows)==len(wmap)==72000
for k,r in rmap.items():
 ws=[wmap[(k,t)] for t in range(50,1001,50)]
 assert int(ws[0]['nstart'])==48 and int(ws[-1]['nend'])==int(r['final_agents'])
 assert sum(int(w['births']) for w in ws)==int(r['births'])
 assert sum(int(w['deaths']) for w in ws)==int(r['deaths'])
 assert sum(int(w['pre_exposure']) for w in ws)==int(r['exposure'])
 for i,w in enumerate(ws):
  assert int(w['nend'])==int(w['nstart'])+int(w['births'])-int(w['deaths'])
  if i:assert int(w['nstart'])==int(ws[i-1]['nend'])
for row in summ:
 if row['guard']!='all':continue
 p1=int(row['ploidy']);rate=float(row['food_rate']);tick=int(row['tick']);metric=row['metric'];d=[];ms=[];cs=[]
 for seed in range(20001,20101):
  y=[int(wmap[((p1,rate,seed,j),tick)]['nend']) for j in range(9)]
  if metric=='extinct':y=[int(x==0) for x in y]
  m=y[0];c=sum(y[1:])/8;ms.append(m);cs.append(c);d.append(m-c)
 assert len(d)==int(row['n']) and math.isclose(sum(d)/100,float(row['mean']),abs_tol=1e-10)
 assert math.isclose(sum(ms)/100,float(row['mix']),abs_tol=1e-10)
 assert math.isclose(sum(cs)/100,float(row['control']),abs_tol=1e-10)
print('PASS: 3600 unique runs, 72000 windows; population, exposure, births/deaths and every all-block mean independently reconstructed from raw tables.')
