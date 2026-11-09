# test_social_learning.jl — unit tests for modules/social_learning.jl

@testset "Social learning (social_learning.jl)" begin

    function _rebuild_agent_map!(env)
        fill!(env.agent_map, Int64(0))
        for (i, ag) in enumerate(env.agents)
            ag.alive || continue
            env.agent_map[Int(ag.x), Int(ag.y)] = i
        end
    end

    function _ann_brain(arch::Vector{Int32}, rng::AbstractRNG)
        w = randn(rng, Float32, Clade.arch_to_n_weights(arch))
        Clade.make_ann_brain(w, arch)
    end

    @testset "_sl_output_layer_range matches output-layer flat indices" begin
        arch = Int32[4, 8, 3]
        r    = Clade._sl_output_layer_range(arch)
        brain = _ann_brain(arch, MersenneTwister(1))
        flat = Clade.flatten(brain)
        (W, b) = brain.layers[end]
        expected = vcat(vec(W), b)
        @test length(r) == length(expected)
        @test flat[r] ≈ expected
    end

    @testset "_copy_output_layer! blends ANN output layer" begin
        arch = Int32[3, 5, 2]
        rng  = MersenneTwister(2)
        learner = _ann_brain(arch, rng)
        model   = _ann_brain(arch, MersenneTwister(3))
        rate    = 0.4f0
        (W_l0, b_l0) = learner.layers[end]
        (W_m, b_m)   = model.layers[end]
        W_expect = (1.0f0 - rate) .* W_l0 .+ rate .* W_m
        b_expect = (1.0f0 - rate) .* b_l0 .+ rate .* b_m
        Clade._copy_output_layer!(learner, model, rate)
        (W_l1, b_l1) = learner.layers[end]
        @test W_l1 ≈ W_expect
        @test b_l1 ≈ b_expect
    end

    @testset "_copy_output_layer! blends BNNBrain output mu" begin
        specs = Clade.normalize_specs(Dict{String,Any}(
            "brain_type" => "bnn",
            "ploidy" => 1,
            "n_agents_init" => 2,
            "grid_rows" => 5,
            "grid_cols" => 5,
            "random_seed" => 6,
        ))
        env = Clade.create_environment(specs)
        learner, model = env.agents[1], env.agents[2]
        @test learner.brain isa Clade.BNNBrain
        rate = 0.3f0
        rng_out = Clade._sl_output_layer_range(learner.brain.arch)
        expect = (1.0f0 - rate) .* learner.brain.mu[rng_out] .+ rate .* model.brain.mu[rng_out]
        Clade._copy_output_layer!(learner.brain, model.brain, rate)
        @test learner.brain.mu[rng_out] ≈ expect
    end

    @testset "_copy_output_layer! no-op for mismatched arch / non-ANN brains" begin
        arch1 = Int32[3, 4, 2]
        arch2 = Int32[3, 6, 2]
        b1 = _ann_brain(arch1, MersenneTwister(4))
        b2 = _ann_brain(arch2, MersenneTwister(5))
        W0 = copy(b1.layers[end][1])
        Clade._copy_output_layer!(b1, b2, 0.5f0)
        @test b1.layers[end][1] == W0

        ctrnn = Clade.make_ctrnn_brain(
            zeros(Float32, Clade.ctrnn_n_params(Int32[3, 6, 2])),
            Int32[3, 6, 2],
        )
        grn = Clade.make_grn_brain(
            zeros(Float32, Clade.grn_n_params(Int32[3, 6, 2])),
            Int32[3, 6, 2],
        )
        @test Clade._copy_output_layer!(ctrnn, grn, 0.5f0) === nothing
    end

    @testset "apply_social_learning! disabled or rate 0" begin
        specs = Clade.normalize_specs(Dict{String,Any}(
            "social_learning" => false,
            "brain_type" => "ann",
            "n_agents_init" => 2,
            "grid_rows" => 6,
            "grid_cols" => 6,
        ))
        env = Clade.create_environment(specs)
        W_before = copy(env.agents[1].brain.layers[end][1])
        Clade.apply_social_learning!(env)
        @test env.agents[1].brain.layers[end][1] == W_before

        specs2 = Clade.normalize_specs(Dict{String,Any}(
            "social_learning" => true,
            "social_learning_rate" => 0.0,
            "brain_type" => "ann",
            "n_agents_init" => 2,
        ))
        env2 = Clade.create_environment(specs2)
        W2 = copy(env2.agents[1].brain.layers[end][1])
        Clade.apply_social_learning!(env2)
        @test env2.agents[1].brain.layers[end][1] == W2
    end

    @testset "prestige bias: copies highest-energy neighbour only" begin
        specs = Clade.normalize_specs(Dict{String,Any}(
            "social_learning" => true,
            "social_learning_rate" => 1.0f0,
            "n_agents_init" => 3,
            "brain_type" => "ann",
            "grid_rows" => 8,
            "grid_cols" => 8,
            "random_seed" => 5,
        ))
        env = Clade.create_environment(specs)
        focal, midd, model = env.agents[1], env.agents[2], env.agents[3]
        focal.x, focal.y = Int32(4), Int32(4)
        midd.x, midd.y   = Int32(4), Int32(5)
        model.x, model.y = Int32(5), Int32(4)
        focal.energy = 10.0f0
        midd.energy  = 50.0f0
        model.energy = 100.0f0
        for ag in env.agents
            ag.alive = true
        end
        _rebuild_agent_map!(env)

        model_flat = Clade.flatten(model.brain)
        rng_out = Clade._sl_output_layer_range(focal.brain.arch)
        Clade.apply_social_learning!(env)
        focal_flat = Clade.flatten(focal.brain)
        @test focal_flat[rng_out] ≈ model_flat[rng_out]
        # Hidden layers stay distinct from model (only output layer copies).
        hidden_slice = 1:(first(rng_out) - 1)
        @test focal_flat[hidden_slice] != model_flat[hidden_slice]
    end

    @testset "no model when every neighbour has lower or equal energy" begin
        specs = Clade.normalize_specs(Dict{String,Any}(
            "social_learning" => true,
            "social_learning_rate" => 0.8f0,
            "brain_type" => "ann",
            "n_agents_init" => 2,
            "grid_rows" => 6,
            "grid_cols" => 6,
        ))
        env = Clade.create_environment(specs)
        a, b = env.agents[1], env.agents[2]
        a.x, a.y = Int32(3), Int32(3)
        b.x, b.y = Int32(3), Int32(4)
        a.energy = 90.0f0
        b.energy = 80.0f0
        _rebuild_agent_map!(env)
        W0 = copy(a.brain.layers[end][1])
        Clade.apply_social_learning!(env)
        @test a.brain.layers[end][1] == W0
    end
end
