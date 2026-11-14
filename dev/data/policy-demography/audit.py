import csv,sys,math
from pathlib import Path
p=Path(sys.argv[1]); rows=list(csv.DictReader(open(p/'runs.csv'))); old=list(csv.DictReader(open(p/'prior-runs.csv')))
key=lambda r:(int(r['seed']),r['mode'],int(r['tick']))
a={key(r):r for r in rows};b={key(r):r for r in old}
assert len(rows)==len(a)==len(old)==len(b)==6000 and a.keys()==b.keys()
for k,x in a.items():
 assert all(x[col]==v for col,v in b[k].items())
 for field in ('births_parent_age','deaths_age','exposure_age','age_bins'):
  z=[int(v) for v in x[field].split(':')];assert len(z)==4 and min(z)>=0
 assert sum(map(int,x['age_bins'].split(':')))==int(x['n'])
for seed in range(20001,20101):
 for mode in ('natural','shuffle','balanced'):
  prev=48
  for tick in range(50,1001,50):
   x=a[(seed,mode,tick)];born=sum(map(int,x['births_parent_age'].split(':')));dead=sum(map(int,x['deaths_age'].split(':')))
   assert prev+born-dead==int(x['n']);prev=int(x['n'])
summary=list(csv.DictReader(open(p/'summary.csv')))
def value(row,metric):
 if metric in ('n','births','deaths','net'):
  born=sum(map(int,row['births_parent_age'].split(':')));dead=sum(map(int,row['deaths_age'].split(':')))
  return {'n':int(row['n']),'births':born,'deaths':dead,'net':born-dead}[metric]
 for field in ('births_parent_age','deaths_age','exposure_age'):
  if metric.startswith(field):return int(row[field].split(':')[int(metric[len(field):])-1])
 raise ValueError(metric)
for line in summary:
 t=int(line['tick']); periods=[t] if line['period']=='interval' else list(range(650,t+1,50));m=line['metric'];assert int(line['n'])==100
 vals=[]
 for mode in ('balanced','shuffle'):
  vals.append(sum(value(a[(seed,mode,tick)],m) for seed in range(20001,20101) for tick in periods)/100)
 assert math.isclose(vals[0],float(line['balanced']),abs_tol=1e-9) and math.isclose(vals[1],float(line['shuffle']),abs_tol=1e-9)
 assert math.isclose(vals[0]-vals[1],float(line['difference']),abs_tol=1e-9)
print(f'PASS: {len(a)} exact prior replays; 6000 interval conservation checks; {len(summary)} independently reconstructed demographic summary means.')
