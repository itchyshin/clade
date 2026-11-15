import csv,pathlib,sys
root=pathlib.Path(sys.argv[1]);first=int(sys.argv[2]);last=int(sys.argv[3])
with open(root/'source-panel-check.csv') as f: rows=list(csv.DictReader(f))
assert [int(x['seed']) for x in rows]==list(range(first,last+1))
for x in rows:
 assert int(x['distinct'])==8 and float(x['mean_disagreement'])>0
 with open(root/x['seed']/'runs.csv') as f:r=list(csv.DictReader(f))
 assert len(r)==180 and {z['panel'] for z in r}=={x['panel_hash']}
print(f'PASS: {len(rows)} distinct source panels have positive behaviour disagreement and matching run hashes')
