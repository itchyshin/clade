include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay, Statistics, Serialization
const BA=MixtureAssay.BehaviourAssay
const PA=MixtureAssay.PerformanceAssay
const MF=MixtureAssay.MatchedFounders
function mix64(x::UInt64)
 z=x+0x9e3779b97f4a7c15;z=(z⊻(z>>30))*0xbf58476d1ce4e5b9;z=(z⊻(z>>27))*0x94d049bb133111eb;z⊻(z>>31)
end
out=ARGS[1];seed=parse(Int,ARGS[2]);mode=ARGS[3];life=parse(Int,ARGS[4]);mkpath(out)
doses=(0,)
monos=mode=="smoke" ? (0,) : 0:8
h=mode=="smoke" ? 60 : 1000
ss=BA.specs(1,.2,seed;max_ticks=1000);ss["n_agents_init"]=100;ss["max_agents"]=700;ss["min_repro_energy"]=80
source=PA.trial(ss);e=source.env;n=length(e.agents);t=Int(e.t)
open(joinpath(out,"source.csv"),"w") do f
 println(f,"seed,tick,agents,min_population,max_population,cap_ticks,status")
 println(f,join((seed,t,n,minimum(source.npost[1:t]),maximum(source.npost[1:t]),count(>=(700),source.npost[1:t]),n>=8 && t==1000 ? "ok" : "insufficient"),','))
end
n>=8 && t==1000 || exit(0)
brains=[a.brain for a in e.agents];BA.fixed_ploidy(e.agents,1) || error("source ploidy")
panel=brains[MixtureAssay.panel(brains,8,seed)];ph=MF.digest(panel);serialize(joinpath(out,"source.jls"),(seed=seed,brains=brains))
open(joinpath(out,"runs.csv"),"w") do io
 open(joinpath(out,"events.csv"),"w") do ev
  open(joinpath(out,"deaths.csv"),"w") do de
  open(joinpath(out,"cohorts.csv"),"w") do co
   println(io,"seed,dose,threshold,food,age_mode,mono,physical,panel,tick,final,min_population,max_population,cap_ticks,exposure,births,deaths,pop200,pop400,pop600,pop800,birth_age1,birth_age2,birth_age3,birth_age4,eligible,blocked")
   println(ev,"seed,dose,threshold,food,age_mode,mono,tick,id,age,energy_before,blocked,births,energy_after")
   println(de,"seed,dose,threshold,food,age_mode,mono,id,death_tick")
   println(co,"seed,dose,threshold,food,age_mode,mono,id,entry_tick,entry_age,entry_energy,first_blocked,birth_tick,birth_age,birth_energy_before,birth_energy_after,death_tick,end_tick")
   for threshold in (80,120),rate in (.05,.025),age_mode in ("fixed","staggered"),mono in monos
    physical=nothing
    for dose in doses
     ENV["CLADE_FACTORIAL_AGE"]=age_mode
     pending=NamedTuple[];before=Set{Int64}();parentage=Dict{Int64,Int}();byage=zeros(Int,4);count_births=Ref(0);counts=zeros(Int,2);cohort=Dict{Int64,Any}()
     function gate(a,env)
      key=(UInt64(seed)<<40) ⊻ (UInt64(a.id)<<10) ⊻ UInt64(env.t)
      u=Float64(mix64(key)>>11)*0x1.0p-53
      blocked=a.age<50 && u<dose/100
      if a.age<50
       counts[1]+=1;counts[2]+=Int(blocked)
       if !haskey(cohort,a.id)
        cohort[a.id]=(entry=Int(env.t),age=Int(a.age),energy=Float64(a.energy),blocked=Int(blocked),birth=0,birthage=0,birthbefore=0.,birthafter=0.)
       end
      end
      push!(pending,(id=a.id,age=Int(a.age),energy=Float64(a.energy),blocked=blocked))
      !blocked
     end
     function observe(phase,env)
      if phase==:after_agents
       empty!(before);union!(before,(a.id for a in env.agents));empty!(pending);empty!(parentage);for a in env.agents;parentage[a.id]=Int(a.age);end
      elseif phase==:after_tick
       newborn=[a for a in env.agents if !(a.id in before)]
       length(newborn)==env.n_births || error("newborn ledger")
       byparent=Dict{Int64,Int}()
       for a in newborn
        byparent[a.parent_id]=get(byparent,a.parent_id,0)+1
        haskey(parentage,a.parent_id) || error("missing parent age")
        age=parentage[a.parent_id];band=age<50 ? 1 : age<100 ? 2 : age<150 ? 3 : 4;byage[band]+=1
       end
       eligible=Set(x.id for x in pending);all(id in eligible for id in keys(byparent)) || error("birth without gate")
       live=Dict(a.id=>a for a in env.agents)
       for x in pending
        haskey(live,x.id) || error("eligible parent missing")
        b=get(byparent,x.id,0);x.blocked && b>0 && error("blocked birth")
        if mode!="full"
         println(ev,join((seed,dose,threshold,rate,age_mode,mono,Int(env.t),x.id,x.age,x.energy,Int(x.blocked),b,Float64(live[x.id].energy)),','))
        end
        if b>0 && haskey(cohort,x.id) && cohort[x.id].birth==0
         cohort[x.id]=merge(cohort[x.id],(birth=Int(env.t),birthage=x.age,birthbefore=x.energy,birthafter=Float64(live[x.id].energy)))
        end
       end
       count_births[]+=length(newborn)
      end
     end
     r=MixtureAssay.trial(panel,1,seed,"demography",mono;horizon=h,overrides=Dict("n_agents_init"=>96,"max_age"=>life,"min_repro_energy"=>threshold,"max_agents"=>700,"grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)),repro_gate=gate,extra_observe=observe)
     physical===nothing && (physical=r.physical);physical==r.physical || error("initial physical mismatch")
     count_births[]==r.births==sum(byage) || error("run birth mismatch")
     tt=Int(r.env.t);deathmap=Dict(Int(id)=>Int(dt) for (id,dt) in zip(r.env.deaths["id"],r.env.deaths["t"]))
     for (id,c) in cohort
      death=get(deathmap,id,0);death==0 || death>c.entry || error("death precedes entry")
      c.birth==0 || c.birth>=c.entry || error("birth precedes entry")
      c.birth==0 || death==0 || c.birth<death || error("birth after death")
      println(co,join((seed,dose,threshold,rate,age_mode,mono,id,c.entry,c.age,c.energy,c.blocked,c.birth,c.birthage,c.birthbefore,c.birthafter,death,tt),','))
     end
     println(io,join((seed,dose,threshold,rate,age_mode,mono,r.physical,ph,tt,length(r.env.agents),minimum(r.post[1:tt]),maximum(r.post[1:tt]),count(>=(700),r.post[1:tt]),r.exposure,r.births,r.deaths,(tt>=200 ? r.post[200] : 0),(tt>=400 ? r.post[400] : 0),(tt>=600 ? r.post[600] : 0),(tt>=800 ? r.post[800] : 0),byage...,counts...),','));flush(io);flush(ev);flush(co)
     for (id,dt) in zip(r.env.deaths["id"],r.env.deaths["t"]);println(de,join((seed,dose,threshold,rate,age_mode,mono,id,dt),','));end
     flush(de)
    end
   end
  end
 end
end
end
