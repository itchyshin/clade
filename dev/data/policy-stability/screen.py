import csv,sys,collections,math
from pathlib import Path
p=Path(sys.argv[1]);initial=int(sys.argv[3]);source_viable_fraction=float(sys.argv[4]);assay_viable_fraction=float(sys.argv[5]);read=lambda x:list(csv.DictReader(open(p/(x+'.csv'))))
s=read('sources');r=read('runs');w=read('windows');key=lambda z:(int(z['threshold']),float(z['food_rate']),z['age_mode'],int(z['seed']),int(z['mono']))
rm={key(z):z for z in r};assert len(r)==len(rm)
ws=collections.defaultdict(list)
for z in w:ws[key(z)].append(z)
assert set(rm)==set(ws)
for k,z in rm.items():
 q=sorted(ws[k],key=lambda x:int(x['lo']));assert len(q)==20;last=initial
 for i,v in enumerate(q):
  assert int(v['lo'])==1+i*50 and int(v['hi'])==50+i*50 and int(v['nstart'])==last
  assert int(v['nend'])==last+int(v['births'])-int(v['deaths']);last=int(v['nend'])
 assert last==int(z['final_agents']) and sum(int(v['births']) for v in q)==int(z['births']) and sum(int(v['deaths']) for v in q)==int(z['deaths'])
for threshold in (int(x) for x in sys.argv[2].split(":")):
 ss=[x for x in s if int(x['threshold'])==threshold];rr=[x for x in r if int(x['threshold'])==threshold];seeds={int(x['seed']) for x in ss}
 complete=0
 for seed in seeds:
  sr=[x for x in ss if int(x['seed'])==seed][0];runs=[x for x in rr if int(x['seed'])==seed]
  for food in (.05,.025):
   for age in ('fixed','staggered'):
    cell=[x for x in runs if float(x['food_rate'])==food and x['age_mode']==age]
    if len(cell)==9:assert len({x['physical_hash'] for x in cell})==len({x['panel_hash'] for x in cell})==1
  if sr['status']=='ok' and int(sr['min_population'])>=20 and len(runs)==36 and all(int(x['min_population'])>=20 for x in runs):complete+=1
 ok=[x for x in ss if x['status']=='ok'];sm=sum(int(x['min_population'])>=20 for x in ok);stable=sum(int(x['min_population'])>=20 for x in rr);cap=sum(int(x['cap_ticks']) for x in rr)/(len(rr)*1000) if rr else math.nan
 bio=sum(int(x['distinct_mu'])==8 and float(x['mean_deterministic'])>0 and int(x['assay_contexts'])==48 for x in ok)
 sourcecap=sum(int(x['source_cap_ticks']) for x in ok)/(len(ok)*1000) if ok and 'source_cap_ticks' in ok[0] else None
 sourcecap_label=f'{sourcecap:.6f}' if sourcecap is not None else 'not_recorded'
 passed=(sourcecap is None or sourcecap<.01) and sum(int(x['final_agents'])>=50 for x in ss)>=source_viable_fraction*len(ss) and sum(int(x['final_agents'])>=initial/2 for x in rr)>=assay_viable_fraction*len(rr) and len(ss)==5 and len(ok)==sm==bio==5 and len(rr)==180 and stable/len(rr)>=.95 and complete/5>=.90 and cap<.01
 print(f'threshold={threshold} sources_stable={sm}/{len(ss)} valid_panels={bio}/{len(ss)} assays_stable={stable}/{len(rr)} all36_blocks_stable={complete}/5 cap_tick_fraction={cap:.6f} source_cap_fraction={sourcecap_label} PASS={passed}')
print(f'AUDIT PASS: {len(s)} source rows; {len(r)} matched assay rows; {len(w)} demographic windows.')
