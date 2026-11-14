using Test, Random, Statistics
if !isdefined(@__MODULE__, :Clade)
    include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
end
using .Clade

@testset "genetic pair sampler" begin
    specs = Clade.get_default_specs()
    specs["n_agents_init"] = 5; specs["random_seed"] = 23
    env = Clade.create_environment(specs)
    agents = env.agents
    d12 = Float64(Clade.genome_distance(agents[1].genome, agents[2].genome))
    @test d12 > 0
    @test all(Clade._sample_genetic_diversity(agents[1:2], Xoshiro(s)) == d12 for s in 1:30)
    @test Clade._sample_genetic_diversity(agents[1:1], Xoshiro(1)) == 0
    @test Clade._sample_genetic_diversity(agents[1:0], Xoshiro(1)) == 0
    exact = mean(Float64(Clade.genome_distance(agents[i].genome, agents[j].genome)) for i in 1:5 for j in (i+1):5)
    rng = Xoshiro(912)
    draws = [Clade._sample_genetic_diversity(agents, rng) for _ in 1:10000]
    @test mean(draws) ≈ exact rtol=0.01
    @test Clade._sample_genetic_diversity(agents, Xoshiro(19)) == Clade._sample_genetic_diversity(agents, Xoshiro(19))
end
