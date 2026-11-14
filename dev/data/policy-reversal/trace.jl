include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay
using Statistics,Serialization
function trial(brains,seed,mono,io;horizon=1000)
 ids=mono==0 ? MixtureAssay.assignments(8,48,seed) : fill(mono,48)
 labels=Dict{Int64,Int}();known=Set{Int64}();before=Set{Int64}();births=zeros(Int,8);deaths=zeros(Int,8);exposure=zeros(Int,8)
 t0grass=Ref(0.0);food=Ref(0.0);envref=Ref{Any}();physical=Ref("")
 function init(s)
  env=MixtureAssay.initialize(s,brains,ids,seed);envref[]=env;physical[]=MixtureAssay.physical_digest(env)
  for (i,a) in enumerate(env.agents);labels[a.id]=ids[i];push!(known,a.id);end
  env
 end
 function snap(env,t)
  n=zeros(Int,8);energy=zeros(Float64,8)
  for a in env.agents
   k=labels[a.id];a.brain.mu==brains[k].mu || error("policy changed or mutated")
   n[k]+=1;energy[k]+=a.energy
  end
  sum(n)==length(env.agents) || error("count mismatch")
  for k in 1:8
   println(io,join((seed,mono,t,k,n[k],length(env.agents),births[k],deaths[k],exposure[k],sum(Float64,env.grass),food[],energy[k],physical[]),','))
  end
  fill!(births,0);fill!(deaths,0);fill!(exposure,0);food[]=0
 end
 function observe(phase,env)
  t=Int(env.t)
  if phase==:before_agents
   empty!(before);union!(before,(a.id for a in env.agents));t0grass[]=sum(Float64,env.grass)
   for a in env.agents;exposure[labels[a.id]]+=1;end
  elseif phase==:after_agents
   food[]+=t0grass[]-sum(Float64,env.grass)
  elseif phase==:after_tick
   alive=Set(a.id for a in env.agents)
   for id in setdiff(before,alive);deaths[labels[id]]+=1;end
   born=[a for a in env.agents if !(a.id in known)]
   length(born)==env.n_births || error("birth count mismatch")
   for a in born
    haskey(labels,a.parent_id) || error("unknown parent")
    k=labels[a.parent_id];a.brain.mu==brains[k].mu || error("offspring is not exact haploid policy clone")
    labels[a.id]=k;push!(known,a.id);births[k]+=1
   end
   sum(deaths)<=length(known) || error("death ledger")
   if t%50==0;snap(env,t);end
  end
 end
 s=MixtureAssay.specs(1,seed,"demography";horizon=horizon)
 result=Clade._run_clade(s,init;observe=observe)
 # Empty populations after early extinction remain zero at remaining checkpoints.
 env=envref[];last=Int(env.t)
 if last<horizon
  for t in (50*cld(last+1,50)):50:horizon;snap(env,t);end
 end
 result,physical[]
end
function study(n,firstseed,out,states)
 mkpath(out)
 open(joinpath(out,"trace.csv"),"w") do io
  println(io,"seed,mono,tick,policy,n_policy,n_total,births,deaths,exposure,grass,food,energy,physical_hash")
  for seed in firstseed:firstseed+n-1
   src=deserialize(joinpath(states,"p1-m0.2-s$(seed).jls"));idx=MixtureAssay.panel(src.brains,8,seed);brains=src.brains[idx]
   length(unique([MixtureAssay.MatchedFounders.digest(b.mu) for b in brains]))==8 || error("duplicate policies")
   ph=nothing
   for mono in 0:8
    result,h=trial(brains,seed,mono,io);ph===nothing && (ph=h);h==ph || error("initial physical states differ")
   end
   println("completed seed ",seed);flush(stdout)
  end
 end
end
length(ARGS)==4 || error("usage N FIRST OUT STATES")
study(parse(Int,ARGS[1]),parse(Int,ARGS[2]),ARGS[3],ARGS[4])
