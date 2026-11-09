# test_ctrnn.jl — unit tests for brains/ctrnn.jl (CTRNNBrain)

@testset "CTRNN brain (ctrnn.jl)" begin

    @testset "ctrnn_n_params" begin
        arch = Int32[2, 4, 3]
        @test Clade.ctrnn_n_params(arch) == 4 + 16 + 4
    end

    @testset "make_ctrnn_brain rejects wrong weight length" begin
        arch = Int32[2, 4, 3]
        @test_throws ErrorException Clade.make_ctrnn_brain(Float32[0.0], arch)
    end

    @testset "tau is exp(log_tau) clamped to [0.1, 10]" begin
        arch = Int32[2, 4, 3]
        n = 4
        expected = Clade.ctrnn_n_params(arch)
        w = zeros(Float32, expected)
        # log(tau) = -5 → exp(-5) ≈ 0.0067, clamped to 0.1
        w[1] = -5.0f0
        w[2] = 0.0f0   # tau = 1
        brain = Clade.make_ctrnn_brain(w, arch)
        @test brain.tau[1] == 0.1f0
        @test brain.tau[2] ≈ 1.0f0
        @test all(0.1f0 .<= brain.tau .<= 10.0f0)
        @test all(brain.y .== 0.0f0)
    end

    @testset "forward: softmax actions and episodic state update" begin
        rng  = MersenneTwister(11)
        arch = Int32[2, 4, 3]
        w    = Float32.(0.01 .* randn(rng, Clade.ctrnn_n_params(arch)))
        brain = Clade.make_ctrnn_brain(w, arch)
        inp   = Float32[0.7, -0.3]
        y0    = copy(brain.y)
        out   = Clade.forward(brain, inp)
        @test length(out) == 3
        @test sum(out) ≈ 1.0f0
        @test all(out .>= 0.0f0)
        @test brain.y != y0
        # Second tick with the same input further updates state (temporal memory).
        y1 = copy(brain.y)
        Clade.forward(brain, inp)
        @test brain.y != y1
    end

    @testset "flatten ↔ make_ctrnn_brain round-trip on parameters" begin
        rng  = MersenneTwister(12)
        arch = Int32[3, 5, 3]
        w    = Float32.(0.05 .* randn(rng, Clade.ctrnn_n_params(arch)))
        b0   = Clade.make_ctrnn_brain(w, arch)
        flat = Clade.flatten(b0)
        @test length(flat) == Clade.ctrnn_n_params(arch)
        b1 = Clade.make_ctrnn_brain(flat, arch)
        @test b1.tau ≈ b0.tau
        @test b1.W ≈ b0.W
        @test b1.theta ≈ b0.theta
        @test Clade.brain_size(b0) == Clade.ctrnn_n_params(arch)
    end

    @testset "mutate and crossover reset state; crossover preserves arch" begin
        rng   = MersenneTwister(13)
        arch  = Int32[2, 4, 3]
        w     = zeros(Float32, Clade.ctrnn_n_params(arch))
        b1    = Clade.make_ctrnn_brain(w, arch)
        b2    = Clade.mutate(b1, 0.1f0, rng)
        @test all(b2.y .== 0.0f0)
        @test b2.arch == arch
        child = Clade.crossover(b1, b2, Int[], rng)
        @test child isa Clade.CTRNNBrain
        @test all(child.y .== 0.0f0)
        @test child.arch == arch
    end

    @testset "make_ctrnn_brain_from_genome (haploid)" begin
        specs = Clade.normalize_specs(Dict{String,Any}(
            "ploidy" => 1,
            "brain_type" => "ctrnn",
            "hidden_layers" => [6],
            "n_agents_init" => 1,
            "grid_rows" => 5,
            "grid_cols" => 5,
            "random_seed" => 9,
        ))
        arch = Clade._build_arch(specs)
        env  = Clade.create_environment(specs)
        ag   = env.agents[1]
        @test ag.brain isa Clade.CTRNNBrain
        g_brain = Clade.make_ctrnn_brain_from_genome(ag.genome, specs)
        @test g_brain.arch == ag.genome.architecture
        @test g_brain.tau ≈ ag.brain.tau
    end

    @testset "run_clade with brain_type ctrnn" begin
        res = Clade.run_clade(Dict{String,Any}(
            "brain_type" => "ctrnn",
            "hidden_layers" => [8],
            "max_ticks" => 2,
            "n_agents_init" => 4,
            "random_seed" => 21,
            "move_cost" => 0.0,
        ))
        @test res.t == 2
        @test !isempty(res.agents)
        @test res.progress.n_agents[end] > 0
    end
end
