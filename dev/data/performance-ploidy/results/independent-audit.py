#!/usr/bin/env python3
"""Independent stdlib raw-data audit of the corrected performance-ploidy campaign."""
import csv, math, os, random, sys, subprocess
from collections import Counter, defaultdict
ROOT=sys.argv[1] if len(sys.argv)>1 else '/tmp/clade-performance-corrected-full'

def read(name):
    with open(os.path.join(ROOT,name),newline='') as f:return list(csv.DictReader(f))
def num(x):
    if x is None or x.strip() in ('','NA','NaN','nan'):return math.nan
    return float(x)
def key(r):return (int(float(r['ploidy'])),float(r['mutation_sd']),int(float(r['seed'])))
def check(ok,msg):
    if not ok:raise AssertionError(msg)
def near(a,b,tol=1e-8):return math.isfinite(a) and math.isfinite(b) and abs(a-b)<=tol
_tc={}
def stat(x):
    x=[z for z in x if math.isfinite(z)];n=len(x)
    if not n:return (0,math.nan,math.nan,math.nan,math.nan)
    mean=sum(x)/n
    if n==1:return (1,mean,math.nan,math.nan,math.nan)
    se=math.sqrt(sum((z-mean)**2 for z in x)/(n-1)/n)
    if n not in _tc:_tc[n]=float(subprocess.check_output(['Rscript','-e',f'cat(qt(.975,{n-1}))'],text=True))
    h=_tc[n]*se
    return n,mean,se,mean-h,mean+h
def paired_boot(x,y,seed):
    rng=random.Random(seed);n=len(x);z=[]
    for _ in range(2000):
        ix=[rng.randrange(n) for __ in range(n)]
        den=sum(x[i] for i in ix)/n
        if den>0:z.append(100*((sum(y[i] for i in ix)/n)/den-1))
    z.sort()
    return 100*(sum(y)/n/(sum(x)/n)-1),z[int(.025*len(z))],z[min(len(z)-1,int(.975*len(z)))],len(z)

runs=read('runs.csv');windows=read('windows.csv');cohorts=read('cohorts.csv');garden=read('garden.csv');reassay=read('reassay.csv');behavior=read('behavior.csv')
# Strictly allow NA only for survival on censored birth cohorts and undefined
# action metrics when N<2 / haploid fraction at an empty endpoint.
for name,rows in (('runs',runs),('windows',windows),('garden',garden),('reassay',reassay),('behavior',behavior)):
    for row in rows:
        for col,val in row.items():
            allow=(name=='runs' and ((col in ('between','within','deterministic_disagreement') and int(float(row['final_agents']))<2) or (col=='final_haploid_fraction' and int(float(row['final_agents']))==0)))
            if not allow:check(val.strip() not in ('','NA','NaN','nan'),f'unexpected missing {name}.{col}')
for row in cohorts:
    for col,val in row.items():
        allowed=(col=='survived_100' and str(row['followup_observed']).lower()=='false')
        if not allowed:check(val.strip() not in ('','NA','NaN','nan'),f'unexpected missing cohort.{col}')

expected={(p,m,s) for p in (1,2) for m in (0.,.05,.2) for s in range(20001,20101)}
rkeys=[key(r) for r in runs];rmap={key(r):r for r in runs}
check(len(runs)==600 and len(set(rkeys))==600 and set(rkeys)==expected,'runs not complete 2x3x100 factorial')
blocks=defaultdict(list)
for r in runs:blocks[(int(float(r['ploidy'])),int(float(r['seed'])))].append(r)
check(len(blocks)==200 and all(len(z)==3 for z in blocks.values()),'expected 200 ploidy-seed blocks x 3 mutation cells')
for b,z in blocks.items():check(len({r['initial_fingerprint'] for r in z})==1,f'initial fingerprints differ across M {b}')
for k,r in rmap.items():
    n=int(float(r['final_agents']));p=k[0]
    check(int(float(r['final_tick']))<=1000 and int(float(r['final_tick']))>=1,f'invalid final tick {k}')
    check(n>=0 and int(float(r['total_births']))>=0 and int(float(r['total_deaths']))>=0,f'negative run tally {k}')
    check(50+int(float(r['total_births']))-int(float(r['total_deaths']))==n,f'run birth/death conservation {k}')
    h=num(r['final_haploid_fraction'])
    check((math.isnan(h) if n==0 else near(h,1. if p==1 else 0.)),f'endpoint ploidy mismatch {k}')
    check(int(float(r['behavior_draws']))==64,f'behavior draws not 64 {k}')

# Full and late aggregate window design, including the capacity-bound time tally.
wkeys=[(key(w),w['window']) for w in windows];want_w={(k,w) for k in expected for w in ('full','late')}
check(len(windows)==1200 and len(set(wkeys))==1200 and set(wkeys)==want_w,'window table keys incomplete/duplicate')
wmap={(key(w),w['window']):w for w in windows}
for k,wn in wkeys:
    w=wmap[(k,wn)];lo,hi=(1,1000) if wn=='full' else (501,1000)
    check((int(float(w['start_tick'])),int(float(w['end_tick'])))==(lo,hi),f'wrong window limits {k,wn}')
    a=int(float(w['agent_ticks']));post=int(float(w['post_agent_ticks']));ns=int(float(w['n_at_start']));ne=int(float(w['n_at_end']))
    b=int(float(w['births']));d=int(float(w['deaths']));st=int(float(w['starvations']))
    check(ne==ns+b-d,f'window population balance {k,wn}')
    check(a==post+ns-ne,f'window exposure identity {k,wn}')
    check(0<=num(w['food'])<=2*a+1e-8,f'food loss bounds {k,wn}')
    check(0<=st<=d,f'starvation/death counts {k,wn}')
    check(0<=int(float(w['capacity_ticks']))<=hi-lo+1,f'capacity tick bounds {k,wn}')
    check(0<=int(float(w['cohort_births']))<=b,f'cohort births bounds {k,wn}')
    check(0<=int(float(w['recruits_100']))<=int(float(w['cohort_births'])),f'recruit bounds {k,wn}')
    if wn=='full':
        r=rmap[k]
        check(b==int(float(r['total_births'])) and d==int(float(r['total_deaths'])),f'full window totals disagree with run row {k}')
        check(near(num(r['mean_population']),post/1000,1e-10),f'full window mean population mismatch {k}')

# Birth-ID, follow-up and window recruitment conservation.
coh_by=defaultdict(list)
for c in cohorts:coh_by[key(c)].append(c)
for k,r in rmap.items():
    cc=coh_by[k];check(len(cc)==int(float(r['total_births'])),f'birth rows != total births {k}')
    ids=[int(float(c['id'])) for c in cc]
    check(len(set(ids))==len(ids) and all(i>50 for i in ids),f'duplicate/invalid birth ID {k}')
    for c in cc:
        bt=int(float(c['birth_tick']));due=int(float(c['followup_tick']));obs=str(c['followup_observed']).lower()=='true';sv=num(c['survived_100'])
        check(due==bt+100 and obs==(due<=1000),f'cohort censor flag wrong {k,bt}')
        check((math.isfinite(sv) and sv in (0.,1.)) if obs else math.isnan(sv),f'cohort outcome/missingness wrong {k,bt}')
    for wn,lo in (('full',1),('late',501)):
        w=wmap[(k,wn)];selected=[c for c in cc if lo<=int(float(c['birth_tick']))<=int(float(w['cohort_end_tick']))]
        check(len(selected)==int(float(w['cohort_births'])),f'cohort window count mismatch {k,wn}')
        check(sum(int(num(c['survived_100'])) for c in selected)==int(float(w['recruits_100'])),f'cohort recruitment sum mismatch {k,wn}')

# Per-run common-garden cases; empty populations correctly have no garden rows.
def garden_map(rows,draws,first_ten=False):
    m={};seen=set()
    for g in rows:
        k=key(g);n=int(float(rmap[k]['final_agents']))
        check(n>0,f'garden row exists with empty endpoint {k}')
        amount=float(g['amount']);loc=int(float(g['location']));case=(k,amount,loc)
        check(case not in seen,f'duplicate garden case {case}');seen.add(case)
        check(amount in (.5,20.) and 1<=loc<=5,f'invalid garden condition {case}')
        tr=int(float(g['trials']));d=int(float(g['draws']))
        check(tr==n*d and d==draws and tr>0,f'garden trial count wrong {case}')
        suc=int(float(g['successes']));idle=int(float(g['idle_choices']))
        check(0<=suc<=tr and 0<=idle<=tr,f'garden count bounds {case}')
        check(near(num(g['food']),suc*min(amount,2),1e-10),f'food != capped success intake {case}')
        net=5*num(g['food'])-1.382*tr+.5*idle
        check(near(num(g['net_energy']),net,2e-5*tr),f'garden net-energy ledger {case}')
        m[case]=g
    expected={(k,a,l) for k,r in rmap.items() if int(float(r['final_agents']))>0 and (not first_ten or k[2]<=20010) for a in (.5,20.) for l in range(1,6)}
    check(seen==expected,f'garden case coverage wrong: expected {len(expected)}, got {len(seen)}')
    return m
gmap=garden_map(garden,64);rgmap=garden_map(reassay,256,True)

# Independent reconstruction from behavior.csv integer bank totals.
bkeys=[(key(b),int(float(b['context']))) for b in behavior]
behavior_eligible={k for k,r in rmap.items() if int(float(r['final_agents']))>=2}
want_b={(k,c) for k in behavior_eligible for c in range(1,49)}
check(len(behavior)==len(want_b) and len(set(bkeys))==len(bkeys) and set(bkeys)==want_b,'behavior context keys incomplete/duplicated')
bgroups=defaultdict(list);bmetric=defaultdict(list)
for b in behavior:
    k=key(b);n=int(float(b['n']));draws=int(float(b['draws']));R=int(float(rmap[k]['behavior_draws']))
    check(n==int(float(rmap[k]['final_agents'])) and draws==R==64,f'behavior n/draw mismatch {k}')
    A=[int(float(b[f'a{i}'])) for i in range(1,6)];B=[int(float(b[f'b{i}'])) for i in range(1,6)];cross=int(float(b['cross']))
    check(min(A+B)>=0 and sum(A)==n*R and sum(B)==n*R,f"behavior action totals don't conserve n*draws {k}")
    check(0<=cross<=n*R*R,f'cross statistic bound {k}')
    bv=(n*cross-sum(A[i]*B[i] for i in range(5)))/(n*(n-1)*R*R)
    wv=1-cross/(n*R*R)
    check(near(bv,num(b['between']),1e-12) and near(wv,num(b['within']),1e-12),f'B/W recovery failed {k, b["context"]}')
    for c,v in (('between',bv),('within',wv),('deterministic_disagreement',num(b['deterministic_disagreement']))):bmetric[(k,c)].append(v)
    bgroups[k].append(b)
for k,r in rmap.items():
    n=int(float(r['final_agents']))
    for c in ('between','within','deterministic_disagreement'):
        rv=num(r[c])
        if n>=2:
            vals=bmetric[(k,c)];check(len(vals)==48 and near(sum(vals)/48,rv,1e-12),f'run behavior summary mismatch {k,c}')
        else:check(math.isnan(rv) and k not in bgroups,f'behavior missingness for N<2 wrong {k,c}')

# Independent viability from actual package function, computed by companion R script.
vr=read(os.path.join(ROOT,'independent_viability.csv'));vmap={key(r):r for r in vr}
check(set(vmap)==expected,'actual-R viability rows incomplete')

# Aggregate garden rates with equal weight over the ten fixed cases; derive rates from raw tables.
metrics={}
for k,r in rmap.items():
    if int(float(r['final_agents']))>0:
        gf=[num(gmap[(k,a,l)]['food'])/int(float(gmap[(k,a,l)]['trials'])) for a in (.5,20.) for l in range(1,6)]
        gn=[num(gmap[(k,a,l)]['net_energy'])/int(float(gmap[(k,a,l)]['trials'])) for a in (.5,20.) for l in range(1,6)]
        metrics[(k,'garden_food')]=sum(gf)/10;metrics[(k,'garden_net')]=sum(gn)/10
    else:metrics[(k,'garden_food')]=metrics[(k,'garden_net')]=math.nan
    for bm in ('between','within','deterministic_disagreement'):metrics[(k,bm)]=num(r[bm])
    for wn in ('late','full'):
        w=wmap[(k,wn)];ex=int(float(w['agent_ticks']));ce=int(float(w['cohort_agent_ticks']));span=int(float(w['end_tick']))-int(float(w['start_tick']))+1
        ratio=lambda a,b:(a/b if b else math.nan)
        for name,value in (('food',ratio(num(w['food']),ex)),('net',ratio(num(w['net_energy']),ex)),('birth_yield',1000*ratio(int(float(w['births'])),ex)),('death_yield',1000*ratio(int(float(w['deaths'])),ex)),('capacity_fraction',ratio(int(float(w['capacity_ticks'])),span))):metrics[(k,f'{wn}_{name}')]=value
        cb=int(float(w['cohort_births']));rec=int(float(w['recruits_100']))
        metrics[(k,f'{wn}_survival100')]=ratio(rec,cb)
        metrics[(k,f'{wn}_recruit_yield')]=1000*ratio(rec,ce)

print('PASS corrected raw structure, run/window/cohort/garden ledgers, behavior B/W reconstruction')
print(f'runs={len(runs)}; matched hash blocks={len(blocks)}; windows={len(windows)}; cohorts={len(cohorts)}; garden={len(garden)}; behavior contexts={len(behavior)}; reassay={len(reassay)}')
print('Actual R viability:',Counter(x['viability'] for x in vr))
for p in (1,2):
    for m in (.05,.2):
        ks0=[(p,0.,s) for s in range(20001,20101)];ks1=[(p,m,s) for s in range(20001,20101)]
        use=[i for i,(a,b) in enumerate(zip(ks0,ks1)) if vmap[a]['viability']=='viable' and vmap[b]['viability']=='viable']
        print(f'primary ploidy={p} M={m:g} vs 0: both-viable={len(use)}/100')
        for metric in ('late_food','late_net','late_birth_yield','late_capacity_fraction','late_survival100','late_recruit_yield','garden_food','garden_net','between','within','deterministic_disagreement'):
            x=[metrics[(ks0[i],metric)] for i in use];y=[metrics[(ks1[i],metric)] for i in use]
            n,mean,se,lo,hi=stat([b-a for a,b in zip(x,y)])
            msg=f'  {metric}: n={n} mean_diff={mean:.9g} MCSE={se:.9g} 95%t=[{lo:.9g},{hi:.9g}]'
            if len(x)>=5 and metric in ('late_birth_yield','garden_food') and all(math.isfinite(z) and z>0 for z in x):
                rel=paired_boot(x,y,20261114+p*100+int(m*1000));msg+=f' relative={rel[0]:.6g}% bootstrap95%=[{rel[1]:.6g}%,{rel[2]:.6g}%] reps={rel[3]}'
            print(msg)

# First-ten 64/256 garden precision review: same both-viable seed pairs and
# same resampled index vectors for the two draw counts.
print('Independent first-ten 64/256 garden precision checks:')
def garden_runmeans(gm,draws_map):
    ans={}
    present={case[0] for case in gm}
    for k in present:
        vals=[num(gm[(k,a,l)]['food'])/int(float(gm[(k,a,l)]['trials'])) for a in (.5,20.) for l in range(1,6)]
        ans[k]=sum(vals)/10
    return ans
g64=garden_runmeans(gmap,None);g256=garden_runmeans(rgmap,None)
for p in (1,2):
    for m in (.05,.2):
        seeds=[s for s in range(20001,20011) if (p,0.,s) in g64 and (p,m,s) in g64 and vmap[(p,0.,s)]['viability']=='viable' and vmap[(p,m,s)]['viability']=='viable']
        old=[g64[(p,m,s)]-g64[(p,0.,s)] for s in seeds];new=[g256[(p,m,s)]-g256[(p,0.,s)] for s in seeds]
        err=stat([b-a for a,b in zip(old,new)])
        if len(seeds)<5:
            print(f'  ploidy={p} M={m:g}: only {len(seeds)} both-viable first-ten pairs; precision unavailable')
            continue
        rng=random.Random(20261114+p*100+int(m*1000));samples=[[rng.randrange(len(seeds)) for _ in seeds] for __ in range(2000)]
        def ci(table):
            z=[]
            for ix in samples:
                den=sum(table[(p,0.,seeds[i])] for i in ix)/len(ix);numv=sum(table[(p,m,seeds[i])] for i in ix)/len(ix)
                if den>0:z.append(100*(numv/den-1))
            z.sort();return z[int(.025*len(z))],z[min(len(z)-1,int(.975*len(z)))]
        c64=ci(g64);c256=ci(g256)
        cls=lambda x:'above5' if x[0]>5 else ('below_minus5' if x[1]<-5 else ('within5' if x[0]>=-5 and x[1]<=5 else 'uncertain'))
        passed=err[0]>=5 and abs(err[1])<.003125 and err[2]<.003125 and cls(c64)==cls(c256)
        print(f'  ploidy={p} M={m:g}: n={len(seeds)} mean repeat-original={err[1]:.9g} MCSE={err[2]:.9g}; 64/256 CI={c64}/{c256} ({cls(c64)}/{cls(c256)}); pass={passed}')
