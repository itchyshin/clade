using Test,Random
if !isdefined(@__MODULE__,:MixtureAssay)
 include(joinpath(@__DIR__,"..","scripts","mixture_assay.jl"))
end
@testset "Balanced mixture construction" begin
 s=Clade.normalize_specs(BehaviourAssay.specs(1,.05,31;max_ticks=1))
 env=Clade.create_environment(s);brains=[deepcopy(a.brain) for a in env.agents[1:8]]
 ids=MixtureAssay.assignments(8,48,31)
 @test sort(ids)==repeat(1:8,inner=6)
 @test_throws ArgumentError MixtureAssay.assignments(7,48,31)
 @test_throws ArgumentError MixtureAssay.panel(brains,9,31)
 for p in (1,2)
  specs=MixtureAssay.specs(p,31,"forage")
  a=MixtureAssay.initialize(Clade.normalize_specs(specs),brains,ids,31)
  b=MixtureAssay.initialize(Clade.normalize_specs(specs),brains,fill(1,48),31)
  @test MixtureAssay.physical_digest(a)==MixtureAssay.physical_digest(b)
  @test length(Set((x.x,x.y) for x in a.agents))==48
  @test all(x.age==50 && x.energy==70 for x in a.agents)
  @test BehaviourAssay.fixed_ploidy(a.agents,p)
  @test all(x.brain.mu==Clade.express_weights(x.genome,"additive") for x in a.agents)
  @test all(all(==(.5f0),x.brain.sigma) for x in a.agents)
 end
 before=MatchedFounders.digest(brains)
 equal=fill(brains[1],8)
 a=MixtureAssay.trial(equal,1,31,"forage",0;horizon=5)
 b=MixtureAssay.trial(equal,1,31,"forage",1;horizon=5)
 @test isequal(a.result,b.result)
 @test a.food==b.food && a.net==b.net
 @test a.exposure==240 && a.births==0 && a.deaths==0
 @test a.clipping>=-1e-3
 full=MixtureAssay.trial(equal,1,31,"forage",0)
 @test full.exposure==48*50 && full.births==full.deaths==0
 demographic=MixtureAssay.trial(equal,2,31,"demography",0;horizon=110,
   overrides=Dict("max_age"=>55,"min_repro_energy"=>20.0,"max_agents"=>100))
 @test demographic.births>0
 @test any(c.follow<=110 for c in demographic.cohorts)
 @test all(c.survived==0 for c in demographic.cohorts if c.follow<=110)
 @test all(c.survived==-1 for c in demographic.cohorts if c.follow>110)
 @test 48+demographic.births-demographic.deaths==length(demographic.env.agents)
 init(s)=MixtureAssay.initialize(s,equal,MixtureAssay.assignments(8,48,31),31)
 @test isequal(a.result,Clade._run_clade(MixtureAssay.specs(1,31,"forage";horizon=5),init))
 @test MatchedFounders.digest(brains)==before
 @test_throws ArgumentError MixtureAssay.specs(1,31,"bad")
end
