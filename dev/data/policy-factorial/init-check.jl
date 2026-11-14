include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay,Test
states="/home/snakagaw/sim-archive/clade/2026-11-14-performance-corrected/full-100/states"
for p in (1,2),rate in (.05,.025,.0125)
 seed=20001;src=MixtureAssay.deserialize(joinpath(states,"p$(p)-m0.2-s$(seed).jls"));brains=src.brains[MixtureAssay.panel(src.brains,8,seed)];ids=MixtureAssay.assignments(8,48,seed)
 spec=MixtureAssay.specs(p,seed,"demography";horizon=1000);merge!(spec,Dict("grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)));s=Clade.normalize_specs(spec)
 ENV["CLADE_FACTORIAL_AGE"]="fixed";fixed=MixtureAssay.initialize(s,brains,ids,seed)
 ENV["CLADE_FACTORIAL_AGE"]="staggered";stagger=MixtureAssay.initialize(s,brains,ids,seed)
 @test all(a.age==50 for a in fixed.agents)
 @test sort([a.age for a in stagger.agents])==collect(25:72)
 @test fixed.grass==stagger.grass
 @test [(a.x,a.y) for a in fixed.agents]==[(a.x,a.y) for a in stagger.agents]
 @test MixtureAssay.MatchedFounders.digest(fixed.rng)==MixtureAssay.MatchedFounders.digest(stagger.rng)
 @test all(fixed.agents[i].brain.mu==stagger.agents[i].brain.mu for i in 1:48)
 @test BehaviourAssay.fixed_ploidy(stagger.agents,p)
end
println("42 matched age-treatment initialization assertions passed")
