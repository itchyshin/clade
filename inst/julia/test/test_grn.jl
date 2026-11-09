# test_grn.jl — unit tests for brains/grn.jl (GRNBrain)

@testset "GRN brain (grn.jl)" begin

    @testset "grn_n_params and n_genes" begin
        arch = Int32[2, 4, 3]
        @test Clade.grn_n_params(arch) == 16
        brain = Clade.make_grn_brain(zeros(Float32, 16), arch)
        @test Clade.n_genes(brain) == 4
    end

    @testset "make_grn_brain rejects wrong weight length" begin
        arch = Int32[2, 3, 2]
        @test_throws ErrorException Clade.make_grn_brain(Float32[1.0, 2.0], arch)
    end

    @testset "initial expression is 0.5 for every gene" begin
        arch = Int32[2, 5, 3]
        w    = zeros(Float32, Clade.grn_n_params(arch))
        brain = Clade.make_grn_brain(w, arch)
        @test all(brain.g .== 0.5f0)
    end

    @testset "forward: sensory drive, softmax actions, in-place g" begin
        rng  = MersenneTwister(31)
        arch = Int32[2, 4, 2]
        w    = Float32.(0.02 .* randn(rng, Clade.grn_n_params(arch)))
        brain = Clade.make_grn_brain(w, arch)
        g0    = copy(brain.g)
        inp   = Float32[1.0, -0.5]
        out   = Clade.forward(brain, inp)
        @test length(out) == 2
        @test sum(out) ≈ 1.0f0
        @test all(out .>= 0.0f0)
        @test brain.g != g0
        @test all(0.0f0 .< brain.g .< 1.0f0)
    end

    @testset "flatten ↔ make_grn_brain round-trip on W" begin
        rng  = MersenneTwister(32)
        arch = Int32[2, 3, 2]
        w    = Float32.(0.1 .* randn(rng, Clade.grn_n_params(arch)))
        b0   = Clade.make_grn_brain(w, arch)
        flat = Clade.flatten(b0)
        b1   = Clade.make_grn_brain(flat, arch)
        @test b1.W ≈ b0.W
        @test Clade.brain_size(b0) == 9
    end

    @testset "mutate and crossover reset expression to 0.5" begin
        rng   = MersenneTwister(33)
        arch  = Int32[2, 3, 2]
        w     = zeros(Float32, Clade.grn_n_params(arch))
        b1    = Clade.make_grn_brain(w, arch)
        b1.g .= 0.9f0
        b2    = Clade.mutate(b1, 0.05f0, rng)
        @test all(b2.g .== 0.5f0)
        child = Clade.crossover(b1, b2, Int[], rng)
        @test all(child.g .== 0.5f0)
        @test child.arch == arch
    end

    @testset "make_grn_brain_from_genome (haploid)" begin
        specs = Clade.normalize_specs(Dict{String,Any}(
            "ploidy" => 1,
            "brain_type" => "grn",
            "n_genes" => 10,
            "n_agents_init" => 1,
            "grid_rows" => 5,
            "grid_cols" => 5,
            "random_seed" => 8,
        ))
        env = Clade.create_environment(specs)
        ag  = env.agents[1]
        @test ag.brain isa Clade.GRNBrain
        g_brain = Clade.make_grn_brain_from_genome(ag.genome, specs)
        @test g_brain.W ≈ ag.brain.W
    end

    @testset "run_clade with brain_type grn" begin
        res = Clade.run_clade(Dict{String,Any}(
            "brain_type" => "grn",
            "n_genes" => 12,
            "max_ticks" => 2,
            "n_agents_init" => 3,
            "random_seed" => 17,
            "move_cost" => 0.0,
        ))
        @test res.t == 2
        @test !isempty(res.agents)
        @test res.progress.n_agents[end] > 0
    end
end
