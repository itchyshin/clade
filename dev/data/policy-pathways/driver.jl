include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay,Serialization,Statistics
const MF=MixtureAssay.MatchedFounders
ageband(x)=x<50 ? 1 : x<100 ? 2 : x<150 ? 3 : 4
out=ARGS[1];firstseed=parse(Int,ARGS[2]);nseeds=parse(Int,ARGS[3]);states=ARGS[4];mkpath(out)
function trial(brains,seed,ninit,threshold,rate,age,mono,io)
 ids=mono==0 ? MixtureAssay.assignments(8,ninit,seed) : fill(mono,ninit)
 s=MixtureAssay.specs(1,seed,"demography";horizon=1000)
 merge!(s,Dict("n_agents_init"=>ninit,"min_repro_energy"=>threshold,"max_agents"=>700,"grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)))
 ENV["CLADE_FACTORIAL_AGE"]=age
 labels=Dict{Int64,Int}(); known=Set{Int64}();before=Dict{Int64,Int}();envref=Ref{Any}();physical=Ref("")
 births=zeros(Int,8,4);deaths=zeros(Int,8,4);exposure=zeros(Int,8,4);food=zeros(Float64,8,4);tickfood=Ref(0.0);grassbefore=Ref(0.0);nstart=Ref(ninit);lasttick=Ref(0)
 function init(spec)
  e=MixtureAssay.initialize(spec,brains,ids,seed);envref[]=e;physical[]=MixtureAssay.physical_digest(e)
  for (i,a) in enumerate(e.agents);labels[a.id]=ids[i];push!(known,a.id);end
  e
 end
 function bite(a,x)
  k=labels[a.id];food[k,ageband(Int(a.age))]+=Float64(x);tickfood[]+=Float64(x)
 end
 function snap(t,e)
  finish=length(e.agents);sum(births)-sum(deaths)==finish-nstart[] || error("window population balance")
  println(io,join((ninit,threshold,rate,age,seed,mono,t-49,t,nstart[],finish,physical[],sum(exposure),sum(births),sum(deaths),sum(food),join(vec(exposure),':'),join(vec(births),':'),join(vec(deaths),':'),join(vec(food),':')),','))
  nstart[]=finish;fill!(births,0);fill!(deaths,0);fill!(exposure,0);fill!(food,0)
 end
 function observe(phase,e)
  if phase==:before_agents
   grassbefore[]=sum(Float64,e.grass);tickfood[]=0
  elseif phase==:after_agents
   abs((grassbefore[]-sum(Float64,e.grass))-tickfood[])<=1e-6 || error("tick food ledger")
   empty!(before)
   for a in e.agents
    before[a.id]=Int(a.age);exposure[labels[a.id],ageband(Int(a.age))]+=1
   end
  elseif phase==:after_tick
   alive=Set(a.id for a in e.agents);dead=setdiff(Set(keys(before)),alive);born=[a for a in e.agents if !haskey(before,a.id)]
   length(dead)==e.n_deaths && length(born)==e.n_births || error("tick event counters")
   for id in dead;deaths[labels[id],ageband(before[id])]+=1;end
   for a in born
    haskey(before,a.parent_id) || error("missing parent");k=labels[a.parent_id]
    births[k,ageband(before[a.parent_id])]+=1;a.brain.mu==brains[k].mu || error("policy changed")
    labels[a.id]=k;push!(known,a.id)
   end
   length(unique((a.x,a.y) for a in e.agents))==length(e.agents) || error("occupied cell collision")
   lasttick[]=Int(e.t);e.t%50==0 && snap(Int(e.t),e)
  end
 end
 Clade._run_clade(s,init;observe=observe,intake_observer=bite)
 e=envref[];last=lasttick[]
 if last<1000
  isempty(e.agents) || error("unexpected early stop")
  for t in (50*cld(last+1,50)):50:1000;snap(t,e);end
 end
 physical[]
end
open(joinpath(out,"windows.csv"),"w") do io
 println(io,"density,threshold,food_rate,age_mode,seed,mono,lo,hi,nstart,nend,physical_hash,exposure,births,deaths,food,exposure_by_policy_age,births_by_policy_age,deaths_by_policy_age,food_by_policy_age")
 for seed in firstseed:firstseed+nseeds-1
  path=joinpath(states,"threshold80-p1-m0.2-s$(seed).jls");src=deserialize(path);brains=src.brains[MixtureAssay.panel(src.brains,8,seed)]
  for density in (48,96),threshold in (120,80),rate in (.05,.025),age in ("fixed","staggered"),mono in 0:8
   trial(brains,seed,density,threshold,rate,age,mono,io)
  end
  flush(io);println("completed seed ",seed);flush(stdout)
 end
end
