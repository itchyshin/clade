using Test,Random
if !isdefined(@__MODULE__,:Clade)
    using Clade
end
@testset "Passive phase observer" begin
    for seed in 1:5
        s=Dict{String,Any}("random_seed"=>seed,"max_ticks"=>12,"n_agents_init"=>8)
        baseline=Clade.run_clade(s)
        phases=Symbol[]
        observed=Clade._run_clade(s,Clade.create_environment;observe=(phase,env)->push!(phases,phase))
        @test isequal(baseline,observed)
        @test phases==repeat([:before_agents,:after_agents,:after_tick],12)
    end
end
if !isdefined(@__MODULE__,:PerformanceAssay)
 include(joinpath(@__DIR__,"..","scripts","performance_assay.jl"))
end
@testset "Canonical food and cost fixtures" begin
 s=Clade.normalize_specs(BehaviourAssay.specs(1,.05,1;max_ticks=1))
 s["grid_rows"]=5;s["grid_cols"]=5;s["n_agents_init"]=1
 env=Clade.create_environment(s)
 arch=Int32[11,5];w=zeros(Float32,60);w[56]=20
 b=Clade.BNNBrain(w,zeros(Float32,60),arch,Float32[],typemax(Int32))
 # Cached opposite action must be discarded before the trial.
 b.last_sample=copy(w);b.last_sample[56]=0;b.last_sample[60]=30;b.ticks_since_sample=0
 r=PerformanceAssay.one_step!(env,b,2,20.0,4)
 @test r.action==1
 @test r.food==2
 @test r.net≈8.78 atol=1e-5
 @test PerformanceAssay.one_step!(env,b,2,.5,4).food==.5
 @test PerformanceAssay.one_step!(env,b,1,20.0,4).food==0
 w[56]=0;w[60]=20
 @test PerformanceAssay.one_step!(env,b,1,20.0,4).food==2
 state=MatchedFounders.digest([b])
 rows=PerformanceAssay.garden([b],1,20001;draws=2)
 @test length(rows)==10
 @test sum(r.food for r in rows)==5
 @test MatchedFounders.digest([b])==state
 @test_throws ArgumentError PerformanceAssay.garden([b],1,1;draws=0)
end
@testset "Observer conservation and extinction" begin
 s=BehaviourAssay.specs(1,.05,31;max_ticks=12)
 r=PerformanceAssay.trial(s)
 @test all(r.npost.==r.npre.+r.births.-r.deaths)
 @test all(0 .<= r.food .<= 2 .* r.npre)
 @test 50+sum(r.births)-sum(r.deaths)==length(r.env.agents)
 s["energy_init"]=0.001;s["grass_init_prob"]=0.0;s["grass_rate"]=0.0
 r=PerformanceAssay.trial(s)
 @test length(r.env.agents)==0
 @test sum(r.deaths)==50
 @test sum(r.births)==0
end
@testset "Oracle food policy and cohort censoring" begin
 arch=Int32[11,5];W=zeros(Float32,5,11)
 for action in 1:4;W[action,2+action]=100;end
 weights=vcat(vec(W),Float32[0,0,0,0,1])
 oracle=Clade.BNNBrain(weights,zeros(Float32,60),arch,Float32[],typemax(Int32))
 @test sum(x.food for x in PerformanceAssay.garden([oracle],1,20001;draws=2))==25
 s=BehaviourAssay.specs(1,.05,31;max_ticks=110)
 merge!(s,Dict("n_agents_init"=>4,"grid_rows"=>5,"grid_cols"=>5,
 "max_agents"=>20,"max_age"=>3,"min_repro_age"=>0,"min_repro_energy"=>20.0,"energy_init"=>150.0))
 r=PerformanceAssay.trial(s)
 eligible=filter(c->c.followup_tick<=110,r.cohorts)
 @test !isempty(eligible)
 @test all(c.survived_100==0 for c in eligible)
 @test length(r.cohorts)==sum(r.births)
 @test all(c.survived_100==-1 for c in r.cohorts if c.followup_tick>110)
end
