import csv,gzip,hashlib,pathlib,sys
new=pathlib.Path(sys.argv[1]);old=pathlib.Path(sys.argv[2]);key=lambda x:(int(x['seed']),int(x['threshold']),float(x['food']),x['age_mode'],int(x['mono']))
with gzip.open(old,'rt') as f:a={key(x):x for x in csv.DictReader(f)}
with open(new) as f:b={key(x):x for x in csv.DictReader(f) if 85001<=int(x['seed'])<=85100}
assert len(a)==len(b)==7200 and set(a)==set(b)
for k in a:
 for v in ('physical','panel'):assert a[k][v]==b[k][v],(k,v)
print('PASS: 7,200 paired assay starts have identical physical and policy panel hashes across lifespans')

newroot=pathlib.Path(sys.argv[3]);oldroot=pathlib.Path(sys.argv[4])
for seed in range(85001,85101):
 a=newroot/'400'/str(seed)/'source.jls';b=oldroot/'300'/str(seed)/'source.jls'
 assert hashlib.sha256(a.read_bytes()).digest()==hashlib.sha256(b.read_bytes()).digest(),seed
print('PASS: all 100 paired source-state files have identical SHA-256 hashes')
