# Same-machine exact replay and independent cohort truth from canonical deaths.
include(joinpath(@__DIR__,"..","..","..","inst","julia","scripts","performance_assay.jl"))
length(ARGS)==1 || error("usage: replay.jl NEW_OUTDIR")
PerformanceAssay.study(1,ARGS[1];draws=64,max_ticks=1000)
checked=0
open(joinpath(ARGS[1],"cohort_truth.csv"),"w") do io
 println(io,"ploidy,mutation_sd,seed,id,birth_tick,followup_tick,followup_observed,death_tick,expected_survived_100")
 for p in (1,2),m in (0.0,.05,.2)
  specs=BehaviourAssay.specs(p,m,20001)
  r=PerformanceAssay.trial(specs)
  isequal(r.result,Clade.run_clade(specs)) || error("observer changed canonical corrected result")
  ids=r.env.deaths["id"];ticks=r.env.deaths["t"]
  length(unique(ids))==length(ids) || error("duplicate canonical death IDs")
  deaths=Dict(Int(id)=>Int(t) for (id,t) in zip(ids,ticks))
  final=Set(a.id for a in r.env.agents)
  for c in r.cohorts
   observed=c.followup_tick<=1000
   if haskey(deaths,c.id)
    deaths[c.id]>c.birth_tick || error("death preceded birth")
   else
    c.id in final || error("unaccounted cohort ID")
   end
   expected=observed ? Int(get(deaths,c.id,typemax(Int))>c.followup_tick) : NaN
   if observed
    c.survived_100==expected || error("cohort observer disagrees with canonical death record")
   else
    c.survived_100==-1 || error("censored cohort was filled")
   end
   MatchedFounders.row(io,(p,m,20001,c.id,c.birth_tick,c.followup_tick,observed,get(deaths,c.id,NaN),expected))
   global checked+=1
  end
 end
end
println("Independent canonical-death audit passed for $checked birth records")
