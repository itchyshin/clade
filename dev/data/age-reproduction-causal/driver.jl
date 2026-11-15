include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay, Statistics, Serialization
const BA=MixtureAssay.BehaviourAssay
const PA=MixtureAssay.PerformanceAssay
const MF=MixtureAssay.MatchedFounders
function mix64(x::UInt64)
 z=x+0x9e3779b97f4a7c15;z=(z⊻(z>>30))*0xbf58476d1ce4e5b9;z=(z⊻(z>>27))*0x94d049bb133111eb;z⊻(z>>31)
end
ageband(a)=a<50 ? 1 : a<100 ? 2 : a<150 ? 3 : 4
out=ARGS[1];firstseed=parse(Int,ARGS[2]);nseeds=parse(Int,ARGS[3]);modes=split(ARGS[4],':');mkpath(joinpath(out,"states"))
all(m->m in ("sham","young","old","both"),modes) || error("unknown mode")
open(joinpath(out,"sources.csv"),"w") do srcio
 open(joinpath(out,"runs.csv"),"w") do io
  open(joinpath(out,"windows.csv"),"w") do win
   println(srcio,"seed,final_tick,final_agents,min_population,source_max,source_cap_ticks,source_hash,panel_hash,distinct_mu,mean_deterministic,status")
   println(io,"gate,density,threshold,food_rate,age_mode,seed,mono,physical_hash,panel_hash,final_tick,final_agents,min_population,max_population,cap_ticks,exposure,food,births,deaths")
   println(win,"gate,density,threshold,food_rate,age_mode,seed,mono,lo,hi,nstart,nend,pre_exposure,post_exposure,food,births,deaths,birth_age1,birth_age2,birth_age3,birth_age4,eligible_young,blocked_young,eligible_old,blocked_old")
   for seed in firstseed:firstseed+nseeds-1
    ss=BA.specs(1,.2,seed;max_ticks=1000);ss["n_agents_init"]=100;ss["max_agents"]=700;ss["min_repro_energy"]=80
    source=PA.trial(ss);e=source.env;n=length(e.agents);t=Int(e.t)
    if n<8 || t<1000
     println(srcio,join((seed,t,n,minimum(source.npost[1:t]),maximum(source.npost),count(>=(700),source.npost),"NA","NA",0,"NA","insufficient_source"),','));flush(srcio);continue
    end
    brains=[a.brain for a in e.agents];BA.fixed_ploidy(e.agents,1) || error("source ploidy")
    panel=brains[MixtureAssay.panel(brains,8,seed)];sh=MF.digest(brains);ph=MF.digest(panel);distinct=length(unique([MF.digest(b.mu) for b in panel]));rows=BA.assay(panel;draws=64,seed=150000+seed)
    serialize(joinpath(out,"states","seed$(seed).jls"),(ploidy=1,mutation=.2,seed=seed,brains=brains));MF.digest(brains)==sh || error("source changed")
    println(srcio,join((seed,t,n,minimum(source.npost[1:t]),maximum(source.npost),count(>=(700),source.npost),sh,ph,distinct,mean(r.deterministic_disagreement for r in rows),"ok"),','));flush(srcio)
    for mode in modes,density in (48,96),threshold in (120,80),rate in (.05,.025),age in ("fixed","staggered")
     ENV["CLADE_FACTORIAL_AGE"]=age;physical=nothing
     for mono in 0:8
      eligible=zeros(Int,2,1000);blocked=zeros(Int,2,1000);byage=zeros(Int,4,1000);before=Dict{Int64,Int}()
      function gate(a,env)
       band=a.age<50 ? 1 : a.age>=150 ? 2 : 0
       band==0 && return true
       t=Int(env.t);eligible[band,t]+=1
       active=band==1 ? mode in ("young","both") : mode in ("old","both")
       key=(UInt64(seed)<<40) ⊻ (UInt64(a.id)<<10) ⊻ UInt64(t)
       reject=active && (mix64(key)&0x1)==0x0
       if reject;blocked[band,t]+=1;end
       !reject
      end
      function observe(phase,env)
       if phase==:after_agents
        empty!(before);for a in env.agents;before[a.id]=Int(a.age);end
       elseif phase==:after_tick
        born=[a for a in env.agents if !haskey(before,a.id)]
        length(born)==env.n_births || error("birth count mismatch")
        for a in born
         haskey(before,a.parent_id) || error("parent missing");byage[ageband(before[a.parent_id]),Int(env.t)]+=1
        end
       end
      end
      r=MixtureAssay.trial(panel,1,seed,"demography",mono;horizon=1000,overrides=Dict("n_agents_init"=>density,"min_repro_energy"=>threshold,"max_agents"=>700,"grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)),repro_gate=gate,extra_observe=observe)
      physical===nothing && (physical=r.physical);physical==r.physical || error("unmatched physical state")
      println(io,join((mode,density,threshold,rate,age,seed,mono,r.physical,ph,r.env.t,length(r.env.agents),minimum(r.post),maximum(r.post),count(>=(700),r.post),r.exposure,r.food,r.births,r.deaths),','));flush(io)
      for w in r.windows
       inds=w.lo:w.hi;v=[sum(byage[b,inds]) for b in 1:4];sum(v)==w.births || error("age birth ledger")
       println(win,join((mode,density,threshold,rate,age,seed,mono,w.lo,w.hi,w.nstart,w.nend,w.pre,w.post,w.food,w.births,w.deaths,v...,sum(eligible[1,inds]),sum(blocked[1,inds]),sum(eligible[2,inds]),sum(blocked[2,inds])),','))
      end
      flush(win)
     end
    end
    println("completed seed ",seed);flush(stdout)
   end
  end
 end
end
