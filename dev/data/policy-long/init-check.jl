include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay,Test
states="/home/snakagaw/sim-archive/clade/2026-11-14-performance-corrected/full-100/states"
for p in (1,2), rate in (.025,.0125)
 seed=20001;src=MixtureAssay.deserialize(joinpath(states,"p$(p)-m0.2-s$(seed).jls"));brains=src.brains[MixtureAssay.panel(src.brains,8,seed)]
 spec=MixtureAssay.specs(p,seed,"demography";horizon=1000);merge!(spec,Dict("grass_rate"=>rate,"grass_init_prob"=>.25));s=Clade.normalize_specs(spec)
 mix=MixtureAssay.initialize(s,brains,MixtureAssay.assignments(8,48,seed),seed)
 @test sort([Int(a.age) for a in mix.agents])==collect(25:72)
 @test length(Set((a.x,a.y) for a in mix.agents))==48
 @test BehaviourAssay.fixed_ploidy(mix.agents,p)
 @test all(a.brain.mu==Clade.express_weights(a.genome,"additive") for a in mix.agents)
 for k in 1:8
  mono=MixtureAssay.initialize(s,brains,fill(k,48),seed)
  @test MixtureAssay.physical_digest(mono)==MixtureAssay.physical_digest(mix)
 end
end
println("48 initialization assertions pass across ploidies and food levels")
