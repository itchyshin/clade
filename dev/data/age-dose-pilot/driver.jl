include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay, Statistics, Serialization
const BA=MixtureAssay.BehaviourAssay
const PA=MixtureAssay.PerformanceAssay
const MF=MixtureAssay.MatchedFounders
function mix64(x::UInt64)
 z=x+0x9e3779b97f4a7c15;z=(z⊻(z>>30))*0xbf58476d1ce4e5b9;z=(z⊻(z>>27))*0x94d049bb133111eb;z⊻(z>>31)
end
out=ARGS[1];seed=parse(Int,ARGS[2]);mode=ARGS[3];mkpath(out)
doses=mode=="smoke" ? (0,50,100) : mode=="replay" ? (0,) : (0,25,50,75,100)
monos=mode=="smoke" ? (0,) : 0:8
h=mode=="smoke" ? 60 : 1000
ss=BA.specs(1,.2,seed;max_ticks=1000);ss["n_agents_init"]=100;ss["max_agents"]=700;ss["min_repro_energy"]=80
source=PA.trial(ss);e=source.env;n=length(e.agents);t=Int(e.t)
open(joinpath(out,"source.csv"),"w") do f
 println(f,"seed,tick,agents,min_population,status")
 println(f,join((seed,t,n,minimum(source.npost[1:t]),n>=8 && t==1000 ? "ok" : "insufficient"),','))
end
n>=8 && t==1000 || exit(0)
brains=[a.brain for a in e.agents];BA.fixed_ploidy(e.agents,1) || error("source ploidy")
panel=brains[MixtureAssay.panel(brains,8,seed)];ph=MF.digest(panel);serialize(joinpath(out,"source.jls"),(seed=seed,brains=brains))
open(joinpath(out,"runs.csv"),"w") do io
 open(joinpath(out,"events.csv"),"w") do ev
  open(joinpath(out,"deaths.csv"),"w") do de
   println(io,"seed,dose,threshold,food,mono,physical,panel,tick,final,min_population,exposure,births,deaths")
   println(ev,"seed,dose,threshold,food,mono,tick,id,age,energy_before,blocked,births,energy_after")
   println(de,"seed,dose,threshold,food,mono,id,death_tick")
   for threshold in (80,120),rate in (.05,.025),mono in monos
    physical=nothing
    for dose in doses
     ENV["CLADE_FACTORIAL_AGE"]="fixed"
     pending=NamedTuple[];before=Set{Int64}();count_births=Ref(0)
     function gate(a,env)
      key=(UInt64(seed)<<40) ⊻ (UInt64(a.id)<<10) ⊻ UInt64(env.t)
      u=Float64(mix64(key)>>11)*0x1.0p-53
      blocked=a.age<50 && u<dose/100
      push!(pending,(id=a.id,age=Int(a.age),energy=Float64(a.energy),blocked=blocked))
      !blocked
     end
     function observe(phase,env)
      if phase==:after_agents
       empty!(before);union!(before,(a.id for a in env.agents));empty!(pending)
      elseif phase==:after_tick
       newborn=[a for a in env.agents if !(a.id in before)]
       length(newborn)==env.n_births || error("newborn ledger")
       byparent=Dict{Int64,Int}()
       for a in newborn;byparent[a.parent_id]=get(byparent,a.parent_id,0)+1;end
       eligible=Set(x.id for x in pending);all(id in eligible for id in keys(byparent)) || error("birth without gate")
       live=Dict(a.id=>a for a in env.agents)
       for x in pending
        haskey(live,x.id) || error("eligible parent missing")
        b=get(byparent,x.id,0);x.blocked && b>0 && error("blocked birth")
        println(ev,join((seed,dose,threshold,rate,mono,Int(env.t),x.id,x.age,x.energy,Int(x.blocked),b,Float64(live[x.id].energy)),','))
       end
       count_births[]+=length(newborn)
      end
     end
     r=MixtureAssay.trial(panel,1,seed,"demography",mono;horizon=h,overrides=Dict("n_agents_init"=>48,"min_repro_energy"=>threshold,"max_agents"=>700,"grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)),repro_gate=gate,extra_observe=observe)
     physical===nothing && (physical=r.physical);physical==r.physical || error("initial physical mismatch")
     count_births[]==r.births || error("run birth mismatch")
     println(io,join((seed,dose,threshold,rate,mono,r.physical,ph,r.env.t,length(r.env.agents),minimum(r.post[1:Int(r.env.t)]),r.exposure,r.births,r.deaths),','));flush(io);flush(ev)
     for (id,dt) in zip(r.env.deaths["id"],r.env.deaths["t"]);println(de,join((seed,dose,threshold,rate,mono,id,dt),','));end
     flush(de)
    end
   end
  end
 end
end
