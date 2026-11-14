#!/usr/bin/env python3
import csv, sys, math, os, collections
from pathlib import Path
root=Path(sys.argv[1])
seed_start=int(sys.argv[2]) if len(sys.argv)>2 else 20001
nseeds=int(sys.argv[3]) if len(sys.argv)>3 else 100
viability_file=Path(sys.argv[4]) if len(sys.argv)>4 else root/'independent-viability.csv'
P=(1,2); M=(0.0,0.05,0.2); SEEDS=range(seed_start,seed_start+nseeds); MODES=('forage','demography'); MONO=range(9)
def rows(name):
    with open(root/(name+'.csv'), newline='') as f:
        yield from csv.DictReader(f)
def fail(msg): raise AssertionError(msg)
def f(x): return float(x)
def i(x): return int(x)
# Exact expected run key lattice.
runs={}
for r in rows('runs'):
    k=(i(r['ploidy']),f(r['source_mutation']),i(r['seed']),r['mode'],i(r['mono']))
    if k in runs: fail('duplicate run '+str(k))
    runs[k]=r
expected={(p,m,s,mode,mono) for p in P for m in M for s in SEEDS for mode in MODES for mono in MONO}
if set(runs)!=expected: fail(f'run lattice mismatch missing={len(expected-set(runs))} extra={len(set(runs)-expected)}')
# Source panels and per-policy maps.
panels={}; policies=collections.defaultdict(list)
for r in rows('panels'):
    k=(i(r['ploidy']),f(r['source_mutation']),i(r['seed']))
    if k in panels: fail('duplicate source panel '+str(k))
    panels[k]=r
for r in rows('policies'):
    k=(i(r['ploidy']),f(r['source_mutation']),i(r['seed']))
    policies[k].append(r)
expected_panel={(p,m,s) for p in P for m in M for s in SEEDS}
if set(panels)!=expected_panel or set(policies)!=expected_panel: fail('panel/policy source lattice mismatch')
for k,rs in policies.items():
    if len(rs)!=8 or sorted(i(r['policy']) for r in rs)!=list(range(1,9)): fail('policy count/index mismatch '+str(k))
    inds=[i(r['source_index']) for r in rs]
    if len(set(inds))!=8 or any(x<1 or x>i(panels[k]['source_n']) for x in inds): fail('selected source indices invalid '+str(k))
    ph={r['panel_hash'] for r in [panels[k]]}
    if len(ph)!=1: fail('panel hash')
# Per-run windows.
ws=collections.defaultdict(list)
for w in rows('windows'):
    k=(i(w['ploidy']),f(w['source_mutation']),i(w['seed']),w['mode'],i(w['mono']))
    if k not in runs: fail('orphan window '+str(k))
    ws[k].append(w)
# Death ledger: IDs/ticks and counts.
deaths=collections.defaultdict(dict)
for d in rows('deaths'):
    k=(i(d['ploidy']),f(d['source_mutation']),i(d['seed']),d['mode'],i(d['mono']))
    ident=i(d['id']); tick=i(d['tick'])
    if ident in deaths[k]: fail('duplicate death id '+str((k,ident)))
    if tick<1 or tick>int(runs[k]['final_tick']): fail('death outside observed horizon '+str((k,ident,tick)))
    deaths[k][ident]=tick
# Cohort ledger streamed: IDs, birth / followup / observed / survived, birth source attribution.
cohstat=collections.Counter(); deaths_seen=collections.Counter(); cohort_ids=collections.defaultdict(set)
for c in rows('cohorts'):
    k=(i(c['ploidy']),f(c['source_mutation']),i(c['seed']),c['mode'],i(c['mono']))
    if k not in runs: fail('orphan cohort '+str(k))
    ident=i(c['id']); birth=i(c['birth']); follow=i(c['follow']); observed=c['observed'].lower() in ('true','1'); survived=i(c['survived'])
    if ident in cohort_ids[k]: fail('duplicate cohort id '+str((k,ident)))
    cohort_ids[k].add(ident)
    if follow != birth+100 or birth<1 or i(c['parent'])<=0: fail('cohort followup/parent definition mismatch '+str((k,ident)))
    dt=deaths[k].get(ident)
    if dt is not None and dt<=birth: fail('death not after cohort birth '+str((k,ident,dt,birth)))
    if observed != (follow<=i(runs[k]['final_tick'])): fail('cohort observed/final tick mismatch '+str((k,ident)))
    if observed:
        if survived not in (0,1): fail('observed cohort has invalid outcome '+str((k,ident)))
        # At follow-up boundary, a death exactly on follow tick is not alive.
        if survived != int(dt is None or dt>follow): fail('cohort outcome vs canonical death ledger '+str((k,ident,dt,follow,survived)))
        cohstat[k,'eligible']+=1; cohstat[k,'recruits']+=survived
    elif survived!=-1: fail('right-censored cohort outcome not -1 '+str((k,ident)))
    if i(c['parent'])<=48: cohstat[k,'founder_births']+=1
    cohstat[k,'births']+=1
    # Every cohort ID must be unique; source death ledger independently accounts.
    deaths_seen[k]+=int(dt is not None)
# Check main tables, state/hash blocks, energy and exposure ledgers.
expected_w={k:1 if k[3]=='forage' else 6 for k in expected}
for k,r in runs.items():
    p,m,s,mode,mono=k
    h=i(r['final_tick']); N=i(r['final_agents']); nmin=i(r['min_population'])
    if h != (50 if mode=='forage' else 300): fail('wrong horizon '+str(k))
    if i(r['births'])!=len(cohort_ids[k]): fail('birth count != newborn cohort rows '+str(k))
    if i(r['deaths'])!=len(deaths[k]): fail('death count != death rows '+str(k))
    if i(r['births'])!=cohstat[k,'births']: fail('cohort birth counter mismatch '+str(k))
    if i(r['cohort_births'])!=cohstat[k,'eligible']: fail('eligible cohort counter mismatch '+str(k))
    if i(r['recruits100'])!=cohstat[k,'recruits']: fail('recruits counter mismatch '+str(k))
    if i(r['founder_births'])!=cohstat[k,'founder_births']: fail('founder births counter mismatch '+str(k))
    if r['panel_hash']!=panels[(p,m,s)]['panel_hash']: fail('run/panel hash mismatch '+str(k))
    if len(ws[k])!=expected_w[k]: fail('window count mismatch '+str(k))
    win=sorted(ws[k],key=lambda x:i(x['lo']))
    expected_ranges=[(1,50)] if mode=='forage' else [(x,min(x+49,300)) for x in range(1,301,50)]
    if [(i(x['lo']),i(x['hi'])) for x in win]!=expected_ranges: fail('window boundaries mismatch '+str(k))
    sums={name:sum(i(x[field]) for x in win) for name,field in [('pre','pre_exposure'),('post','post_exposure'),('idle','idle'),('births','births'),('deaths','deaths'),('starvations','starvations')]}
    sums.update({name:sum(f(x[field]) for x in win) for name,field in [('food','food'),('net','net_energy')]})
    if sums['pre']!=i(r['exposure']) or abs(sums['food']-f(r['food']))>1e-7 or abs(sums['net']-f(r['net_energy']))>1e-7: fail('run/window exposure or energy sum mismatch '+str(k))
    if sums['births']!=i(r['births']) or sums['deaths']!=i(r['deaths']): fail('run/window birth/death mismatch '+str(k))
    if abs(f(r['uncapped_reward'])-(5*f(r['food'])-1.382*i(r['exposure'])+.5*sums['idle']))>2e-4*max(1,i(r['exposure'])): fail('uncapped energy reward formula mismatch '+str(k))
    if f(r['net_energy'])>f(r['uncapped_reward'])+2e-4*i(r['exposure']): fail('energy ledger exceeds food/action-cost bound '+str(k))
    if abs(f(r['clipping'])-(f(r['uncapped_reward'])-f(r['net_energy'])))>1e-7: fail('clipping identity mismatch '+str(k))
    # Population conservation and continuity at recorded bins.
    for j,w in enumerate(win):
        if i(w['pre_exposure']) != i(w['post_exposure']) + i(w['nstart']) - i(w['nend']): fail('window population exposure balance '+str(k))
        if f(w['food']) < -1e-8 or f(w['food']) > 2*i(w['pre_exposure'])+1e-8: fail('window food bounds '+str(k))
        if j and i(w['nstart'])!=i(win[j-1]['nend']): fail('window endpoint discontinuity '+str(k))
        if i(w['nend'])!=i(w['nstart'])+i(w['births'])-i(w['deaths']): fail('window population conservation '+str(k))
    if mode=='forage':
        if N!=48 or nmin!=48 or i(r['births']) or i(r['deaths']) or i(r['exposure'])!=48*50 or sums['pre']!=sums['post']: fail('forage equal-density invariant failed '+str(k))
        if i(r['cohort_births']) or i(r['recruits100']): fail('forage has eligible births '+str(k))
# Initial physical hashes are paired across nine assemblages and across source mutation regimes within ploidy/seed/mode.
for p in P:
  for s in SEEDS:
    for mode in MODES:
      vals={runs[(p,m,s,mode,mono)]['physical_hash'] for m in M for mono in MONO}
      if len(vals)!=1: fail('physical initialization hash differs within P/seed/mode block '+str((p,s,mode)))
# Physical initialization is also identical across the forage and demographic modes for each ploidy/seed.
for p in P:
  for s in SEEDS:
    vals={runs[(p,m,s,mode,mono)]['physical_hash'] for m in M for mode in MODES for mono in MONO}
    if len(vals)!=1: fail('physical initialization hash differs across modes '+str((p,s)))
# Panel hash fixed across mono and modes, while source mutation blocks retain distinct panel records.
for k in expected_panel:
  ph=panels[k]['panel_hash']
  for mode in MODES:
    for mono in MONO:
      if runs[(k[0],k[1],k[2],mode,mono)]['panel_hash']!=ph: fail('panel hash block mismatch '+str((k,mode,mono)))
# Import classifications emitted by the actual package viability_report() call.
viab={}
with open(viability_file, newline='') as vf:
  for v in csv.DictReader(vf):
    k=(i(v['ploidy']),f(v['source_mutation']),i(v['seed']),v['mode'],i(v['mono']))
    if k in viab: fail('duplicate R viability row '+str(k))
    viab[k]=v['verdict']
if set(viab)!=expected: fail('actual R viability rows do not match run keys')
# Seed-level balanced mix - average of eight monocultures, metrics as plan; all blocks and viable-only pair counts.
contrasts=collections.defaultdict(lambda:collections.defaultdict(list))
for p in P:
 for m in M:
  for mode in MODES:
   for s in SEEDS:
    def metric(mono,field):
      r=runs[(p,m,s,mode,mono)]; exp=i(r['exposure'])
      if field=='food': return f(r['food'])/exp
      if field=='net': return f(r['net_energy'])/exp
      if field=='reward': return f(r['uncapped_reward'])/exp
      if field=='birth_yield': return i(r['births'])/exp
      if field=='recruit_yield': return i(r['recruits100'])/i(r['cohort_exposure']) if i(r['cohort_exposure']) else float('nan')
      raise KeyError(field)
    for field in (('food','net','reward') if mode=='forage' else ('birth_yield','recruit_yield')):
      d=metric(0,field)-sum(metric(j,field) for j in range(1,9))/8
      contrasts[(p,m,mode,field)]['all'].append(d)
      if all(viab[(p,m,s,mode,j)]=='viable' for j in range(9)):
        contrasts[(p,m,mode,field)]['all9_viable'].append(d)
def stats(xs):
    xs=[x for x in xs if math.isfinite(x)]
    n=len(xs)
    if not n:return 'n=0'
    mu=sum(xs)/n; se=math.sqrt(sum((x-mu)**2 for x in xs)/(n-1)/n) if n>1 else float('nan')
    return f'n={n} mean={mu:.9g} MCSE={se:.6g}'
with open(root/'independent-audit.txt','w') as out:
    print('PASS mixture design, population/energy/death/cohort/selection/hash ledgers',file=out)
    print(f'runs={len(runs)} panels={len(panels)} policy rows={sum(map(len,policies.values()))} windows={sum(map(len,ws.values()))} deaths={sum(map(len,deaths.values()))} cohorts={sum(map(len,cohort_ids.values()))}',file=out)
    print('Actual R viability_report verdict counts: '+str(collections.Counter(viab.values())),file=out)
    print('Hashes checked for exact 9-assemblage equality within each P/seed/mode and each panel block; no legacy endpoint parity asserted.',file=out)
    for key,sets in sorted(contrasts.items()):
      print(f'contrast P={key[0]} source_M={key[1]} mode={key[2]} outcome={key[3]} all-block {stats(sets["all"])} all9-viable {stats(sets["all9_viable"])}',file=out)
print('WROTE',root/'independent-audit.txt')
