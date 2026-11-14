include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay, Statistics, Serialization, SHA
const BA=MixtureAssay.BehaviourAssay
const PA=MixtureAssay.PerformanceAssay
const MF=MixtureAssay.MatchedFounders
out=ARGS[1];mkpath(joinpath(out,"states"));firstseed=parse(Int,ARGS[2]);nseeds=parse(Int,ARGS[3])
open(joinpath(out,"sources.csv"),"w") do srcio
 open(joinpath(out,"runs.csv"),"w") do io
  open(joinpath(out,"windows.csv"),"w") do win
   println(srcio,"seed,final_tick,final_agents,min_population,tick_of_min,total_births,total_deaths,source_hash,panel_hash,distinct_mu,mean_between,mean_deterministic,assay_contexts")
   println(io,"food_rate,age_mode,seed,mono,physical_hash,panel_hash,final_tick,final_agents,min_population,tick_of_min,exposure,food,net,births,deaths")
   println(win,"food_rate,age_mode,seed,mono,lo,hi,nstart,nend,pre_exposure,post_exposure,food,net,births,deaths")
   for seed in firstseed:firstseed+nseeds-1
    source=PA.trial(BA.specs(1,.2,seed;max_ticks=1000));e=source.env;n=length(e.agents);t=Int(e.t)
    n>=8 || error("source has fewer than eight brains, seed=$seed endpoint=$n")
    brains=[a.brain for a in e.agents];all(all(==(.5f0),b.sigma) for b in brains) || error("source sigma")
    BA.fixed_ploidy(e.agents,1) || error("source ploidy")
    indices=MixtureAssay.panel(brains,8,seed); panel=brains[indices]; sh=MF.digest(brains);ph=MF.digest(panel)
    hashes=[MF.digest(b.mu) for b in panel]; distinct=length(unique(hashes));rows=BA.assay(panel;draws=64,seed=150000+seed)
    path=joinpath(out,"states","p1-m0.2-s$(seed).jls");serialize(path,(ploidy=1,mutation=.2,seed=seed,brains=brains))
    MF.digest(brains)==sh || error("source changed")
    println(srcio,join((seed,t,n,minimum(source.npost[1:t]),argmin(source.npost[1:t]),sum(source.births),sum(source.deaths),sh,ph,distinct,mean(r.between for r in rows),mean(r.deterministic_disagreement for r in rows),length(rows)),','));flush(srcio)
    for rate in (.05,.025),age in ("fixed","staggered")
     ENV["CLADE_FACTORIAL_AGE"]=age;physical=nothing
     for mono in 0:8
      r=MixtureAssay.trial(panel,1,seed,"demography",mono;horizon=1000,overrides=Dict("grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)))
      physical===nothing && (physical=r.physical);physical==r.physical || error("unmatched initial physical state")
      println(io,join((rate,age,seed,mono,r.physical,ph,r.env.t,length(r.env.agents),minimum(r.post),argmin(r.post),r.exposure,r.food,r.net,r.births,r.deaths),','));flush(io)
      for w in r.windows
       println(win,join((rate,age,seed,mono,w.lo,w.hi,w.nstart,w.nend,w.pre,w.post,w.food,w.net,w.births,w.deaths),','))
      end
      flush(win)
     end
    end
    println("completed seed ",seed);flush(stdout)
   end
  end
 end
end
