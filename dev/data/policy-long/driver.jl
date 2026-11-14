include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay
states="/home/snakagaw/sim-archive/clade/2026-11-14-performance-corrected/full-100/states"
out=ARGS[1];mkpath(out); firstseed=parse(Int,ARGS[2]); nseeds=parse(Int,ARGS[3])
open(joinpath(out,"runs.csv"),"w") do io
 open(joinpath(out,"windows.csv"),"w") do win
 println(win,"ploidy,food_rate,seed,mono,lo,hi,nstart,nend,pre_exposure,post_exposure,food,net,births,deaths")
 println(io,"ploidy,food_rate,seed,mono,final_tick,final_agents,min_population,tick_of_min,exposure,food,net,births,deaths")
 for p in (1,2), rate in (.025,.0125), seed in firstseed:(firstseed+nseeds-1)
  src=MixtureAssay.deserialize(joinpath(states,"p$(p)-m0.2-s$(seed).jls")); brains=src.brains[MixtureAssay.panel(src.brains,8,seed)]
  for mono in 0:8
   r=MixtureAssay.trial(brains,p,seed,"demography",mono;horizon=1000,overrides=Dict("grass_rate"=>rate,"grass_init_prob"=>.25))
   println(io,join((p,rate,seed,mono,r.env.t,length(r.env.agents),minimum(r.post),argmin(r.post),r.exposure,r.food,r.net,r.births,r.deaths),','));flush(io)
   for w in r.windows
    println(win,join((p,rate,seed,mono,w.lo,w.hi,w.nstart,w.nend,w.pre,w.post,w.food,w.net,w.births,w.deaths),','))
   end
   flush(win)
  end
 end
end
end
