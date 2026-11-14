include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay,Test
seed=60001;path="/home/snakagaw/sim-archive/clade/2026-11-14-policy-density-factorial/pilot/shard-0/states/threshold80-p1-m0.2-s60001.jls"
src=MixtureAssay.deserialize(path);brains=src.brains[MixtureAssay.panel(src.brains,8,seed)]
for density in (48,96),rate in (.05,.025),age in ("fixed","staggered")
 ENV["CLADE_FACTORIAL_AGE"]=age;ids=MixtureAssay.assignments(8,density,seed);envs=[]
 for threshold in (80,120)
  s=MixtureAssay.specs(1,seed,"demography";horizon=1000);merge!(s,Dict("n_agents_init"=>density,"min_repro_energy"=>threshold,"max_agents"=>700,"grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)));s=Clade.normalize_specs(s)
  e=MixtureAssay.initialize(s,brains,ids,seed);push!(envs,e)
  @test length(e.agents)==density
  @test length(unique((a.x,a.y) for a in e.agents))==density
  @test all(a.repro_threshold==threshold for a in e.agents)
  @test [a.age for a in e.agents]==(age=="fixed" ? fill(50,density) : [24+mod1(i,48) for i in 1:density])
  @test [a.brain.mu for a in e.agents]==[brains[i].mu for i in ids]
 end
 a,b=envs; fields=filter(x->!(x in (:brain,:genome,:repro_threshold)),fieldnames(Clade.Agent))
 @test [Tuple(getfield(x,f) for f in fields) for x in a.agents]==[Tuple(getfield(x,f) for f in fields) for x in b.agents]
 @test all(all(a.agents[i].genome.maternal_traits[j]==b.agents[i].genome.maternal_traits[j] for j in eachindex(a.agents[i].genome.maternal_traits) if j!=Clade.TRAIT_REPRO_THRESHOLD) for i in 1:density)
 @test a.grass==b.grass;@test [(x.x,x.y) for x in a.agents]==[(x.x,x.y) for x in b.agents];@test MixtureAssay.MatchedFounders.digest(a.rng)==MixtureAssay.MatchedFounders.digest(b.rng)
end
println("120 matched threshold and initialization assertions passed")
