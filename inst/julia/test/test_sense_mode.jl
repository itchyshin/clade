using Test

if !isdefined(@__MODULE__, :Clade)
    include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
end

@testset "Sense mode" begin
    specs = Clade.get_default_specs()
    specs["input_radius"] = 2
    specs["sense_mode"] = "weighted_sum"
    specs["n_agents_init"] = 1
    specs["grid_rows"] = 9
    specs["grid_cols"] = 9

    @test Clade._compute_n_inputs(specs) == 11
    env = Clade.create_environment(specs)
    ag = env.agents[1]
    ag.x = Int32(5)
    ag.y = Int32(5)
    ag.energy = 100.0f0
    ag.age = Int32(20)
    env.grass .= 0.0f0
    env.agent_map .= 0

    # Radius-two grass values are normalised per cell, then summed with 1/d
    # weights. North: .4 + .8/2; east: .2 + 1/2; south: .6 + .4/2;
    # west: 1 + .2/2.
    env.grass[4, 5] = 2.0f0
    env.grass[3, 5] = 4.0f0
    env.grass[5, 6] = 1.0f0
    env.grass[5, 7] = 5.0f0
    env.grass[6, 5] = 3.0f0
    env.grass[7, 5] = 2.0f0
    env.grass[5, 4] = 5.0f0
    env.grass[5, 3] = 1.0f0

    # Occupancy is collapsed independently, preserving the same 1/d rule.
    env.agent_map[4, 5] = 2
    env.agent_map[3, 5] = 3
    env.agent_map[5, 7] = 4

    input = Clade.sense_agent(ag, env)
    @test input[3:6] ≈ Float32[0.8, 0.7, 0.8, 1.1]
    @test input[7:10] ≈ Float32[1.5, 0.5, 0.0, 0.0]
    @test input[11] == 1.0f0
    @test length(input) == Int(ag.brain.arch[1])
end

@testset "Radius-one weighted sensing matches per-cell sensing" begin
    outputs = Vector{Vector{Float32}}()
    for mode in ("per_cell", "weighted_sum")
        specs = Clade.get_default_specs()
        specs["input_radius"] = 1
        specs["sense_mode"] = mode
        specs["random_seed"] = 17
        specs["n_agents_init"] = 1
        specs["grid_rows"] = 7
        specs["grid_cols"] = 7
        env = Clade.create_environment(specs)
        ag = env.agents[1]
        ag.x = Int32(4)
        ag.y = Int32(4)
        ag.energy = 73.0f0
        ag.age = Int32(19)
        env.grass .= 0.0f0
        env.grass[3, 4] = 3.0f0
        env.grass[4, 5] = 1.0f0
        env.grass[5, 4] = 2.0f0
        env.grass[4, 3] = 4.0f0
        env.agent_map .= 0
        env.agent_map[3, 4] = 2
        push!(outputs, Clade.sense_agent(ag, env))
    end
    @test outputs[1] == outputs[2]
end

@testset "Sense mode edge handling and optional channels" begin
    for toroidal in (true, false)
        specs = Clade.get_default_specs()
        specs["input_radius"] = 2
        specs["sense_mode"] = "weighted_sum"
        specs["n_agents_init"] = 1
        specs["n_predators_init"] = 1
        specs["signal_dims"] = 2
        specs["parental_care"] = true
        specs["toroidal"] = toroidal
        specs["grid_rows"] = 7
        specs["grid_cols"] = 7
        env = Clade.create_environment(specs)
        ag = env.agents[1]
        ag.x = Int32(1)
        ag.y = Int32(1)
        env.grass .= 0.0f0
        env.agent_map .= 0
        env.predator_map .= 0
        env.grass[1, 1] = 5.0f0
        ag.signal .= Float32[0.25, 0.75]

        if toroidal
            env.grass[7, 1] = 2.5f0
            env.grass[6, 1] = 5.0f0
            env.agent_map[7, 1] = 2
            env.agent_map[6, 1] = 3
            env.predator_map[7, 1] = 1
            env.predator_map[6, 1] = 1
        else
            # Clamped north coordinates both resolve to row 1.
            env.grass[1, 1] = 5.0f0
            env.agent_map[1, 1] = 2
            env.predator_map[1, 1] = 1
        end

        input = Clade.sense_agent(ag, env)
        @test length(input) == 19
        @test length(input) == Int(ag.brain.arch[1])
        @test input[3] ≈ (toroidal ? 1.0f0 : 1.5f0)
        @test input[7] ≈ 1.5f0 # The clamped coordinate resolves to row 1.
        @test input[11] == 1.0f0 # bias remains before optional channels
        @test input[12] ≈ 0.5f0 + (1.0f0 / 3) / 2
        @test input[16:17] == Float32[0.0, 0.0] # Care slots stay in place.
        @test input[18:19] == Float32[0.25, 0.75]
    end
end

@testset "Per-cell sensing stays the default and unsupported modes fail" begin
    specs = Clade.get_default_specs()
    @test specs["sense_mode"] == "per_cell"
    specs["input_radius"] = 2
    @test Clade._compute_n_inputs(specs) == 19
    specs["sense_mode"] = "mystery"
    @test_throws ArgumentError Clade._compute_n_inputs(specs)

    for brain_type in ("ann", "bnn", "random", "ctrnn", "grn")
        valid = Clade.get_default_specs()
        valid["input_radius"] = 2
        valid["sense_mode"] = "weighted_sum"
        valid["brain_type"] = brain_type
        valid["n_agents_init"] = 1
        valid["grid_rows"] = 7
        valid["grid_cols"] = 7
        env = Clade.create_environment(valid)
        input = Clade.sense_agent(env.agents[1], env)
        @test length(input) == 11
        @test Int(env.agents[1].brain.arch[1]) == 11
    end
end


@testset "Sense mode rejects nonpositive radii" begin
    for mode in ("per_cell", "weighted_sum"), radius in (0, -1)
        specs = Clade.get_default_specs()
        specs["sense_mode"] = mode
        specs["input_radius"] = radius
        @test_throws ArgumentError Clade._compute_n_inputs(specs)
    end
end


@testset "Optional tails preserve nonzero care and signals" begin
    for predators in (0, 1), care in (false, true), mode in ("per_cell", "weighted_sum")
        specs = Clade.get_default_specs()
        specs["sense_mode"] = mode
        specs["input_radius"] = 2
        specs["n_agents_init"] = 1
        specs["n_predators_init"] = predators
        specs["parental_care"] = care
        specs["max_clutch_size"] = 2
        specs["signal_dims"] = 2
        env = Clade.create_environment(specs)
        ag = env.agents[1]
        ag.signal .= Float32[0.2, 0.8]
        if care
            child = deepcopy(ag)
            child.energy = 40.0f0
            push!(ag.carried_offspring, child)
            ag.care_load = 1
        end
        input = Clade.sense_agent(ag, env)
        @test length(input) == Clade._compute_n_inputs(specs)
        @test input[end-1:end] ≈ Float32[0.2, 0.8]
        if care
            @test input[end-3:end-2] ≈ Float32[0.5, 0.2]
        end
    end
end
