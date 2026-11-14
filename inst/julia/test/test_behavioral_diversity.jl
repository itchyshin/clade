using Test, Random
if !isdefined(@__MODULE__, :Clade)
    include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
end
using .Clade

@testset "behavioral diversity" begin
    specs = Clade.get_default_specs()
    specs["n_agents_init"] = 7; specs["n_predators_init"] = 3
    specs["grid_rows"] = 10; specs["grid_cols"] = 10
    specs["random_seed"] = 9; specs["max_ticks"] = 3
    env = Clade.create_environment(specs)
    Clade.seed_predators!(env)
    @test all(isnan, env.progress["behavioral_diversity"])
    @test all(isnan, env.progress["predator_behavioral_diversity"])
    @test all(iszero, env.progress["n_behavioral_agents"])
    for (ag, action) in zip(env.agents, (1,2,3,4,5,0,1))
        ag.last_action = Int8(action)
    end
    env.agents[7].alive = false
    state = copy(env.rng)
    entropy, count = Clade._behavioral_diversity(env.agents)
    @test entropy ≈ log(5)
    @test count == 5
    @test rand(env.rng) == rand(state)
    env.t = 1; Clade.log_tick!(env)
    @test env.progress["behavioral_diversity"][1] ≈ log(5)
    @test env.progress["n_behavioral_agents"][1] == 5
    @test isnan(env.progress["predator_behavioral_diversity"][1])
    @test env.progress["n_behavioral_predators"][1] == 0
    for (ag, action) in zip(env.agents, (1,1,2,0,0,0,0))
        ag.last_action = Int8(action)
    end
    entropy, count = Clade._behavioral_diversity(env.agents)
    @test count == 3
    @test entropy ≈ -(2/3 * log(2/3) + 1/3 * log(1/3))
    env.agents[3].last_action = 1
    @test Clade._behavioral_diversity(env.agents) == (0.0, 3)
    for ag in env.agents; ag.last_action = 0; end
    entropy, count = Clade._behavioral_diversity(env.agents)
    @test isnan(entropy) && count == 0
    empty!(env.agents)
    for (p, action) in zip(env.predators, (1, 2, 0)); p.last_action = Int8(action); end
    env.t = 1
    Clade.log_tick!(env)
    @test isnan(env.progress["behavioral_diversity"][1])
    @test env.progress["n_behavioral_agents"][1] == 0
    @test env.progress["predator_behavioral_diversity"][1] ≈ log(2)
    @test env.progress["n_behavioral_predators"][1] == 2
    env.predators[1].alive = false
    env.t = 2; Clade.log_tick!(env)
    @test env.progress["predator_behavioral_diversity"][2] == 0
    @test env.progress["n_behavioral_predators"][2] == 1
    empty!(env.predators)
    env.t = 3; Clade.log_tick!(env)
    @test isnan(env.progress["predator_behavioral_diversity"][3])
    @test env.progress["n_behavioral_predators"][3] == 0
end
