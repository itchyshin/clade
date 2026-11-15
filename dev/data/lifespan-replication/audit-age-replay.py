import collections,csv,pathlib,sys
root=pathlib.Path(sys.argv[1]);main=pathlib.Path(sys.argv[2]);out=root/'agebands.csv';seeds=[*range(85001,85101),*range(87001,87101)]
key=lambda x:(int(x['threshold']),float(x['food']),x['age_mode'],int(x['mono']))
fields=('physical','panel','tick','final','min_population','max_population','cap_ticks','exposure','births','deaths','pop200','pop400','pop600','pop800','birth_age1','birth_age2','birth_age3','birth_age4','eligible','blocked')
rows=[];event_count=0
for seed in seeds:
 replay=root/'400'/str(seed);original=main/'400'/str(seed)
 with open(replay/'runs.csv') as f:a={key(x):x for x in csv.DictReader(f)}
 with open(original/'runs.csv') as f:b={key(x):x for x in csv.DictReader(f)}
 assert len(a)==len(b)==72 and set(a)==set(b)
 for k in a:
  for x in fields:assert a[k][x]==b[k][x],(seed,k,x)
 counts=collections.defaultdict(lambda:[0,0,0,0,0]);
 with open(replay/'events.csv') as f:
  for x in csv.DictReader(f):
   event_count+=1;k=key(x);age=int(x['age']);n=int(x['births']);assert k in a
   band=0 if age<50 else 1 if age<100 else 2 if age<150 else 3 if age<300 else 4
   counts[k][band]+=n
 for k,r in a.items():
  v=counts[k];assert v[:3]==[int(r['birth_age'+str(i)]) for i in (1,2,3)] and v[3]+v[4]==int(r['birth_age4']) and sum(v)==int(r['births'])
  rows.append(dict(seed=seed,threshold=k[0],food=k[1],age_mode=k[2],mono=k[3],young=v[0],age50_99=v[1],age100_149=v[2],age150_299=v[3],age300_plus=v[4]))
with open(out,'w') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
print(f'PASS: {len(rows)} matched replays and {event_count} individual opportunities; five age bands reconstruct all births')
