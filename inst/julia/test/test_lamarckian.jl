# test_lamarckian.jl
# Unit tests for Lamarckian genome write-back (lamarck_genome_update!)

@testset "Lamarckian genome update" begin

    # A real haploid agent from create_environment(), so the test does not
    # depend on Agent's field list (it has no keyword constructor and has
    # grown since this test was written). Only `brain` and `genome` are
    # read by lamarck_genome_update!, so those two are replaced.
    function _real_haploid_agent()
        specs = Clade.get_default_specs()
        specs["ploidy"] = 1; specs["brain_type"] = "ann"
        specs["n_agents_init"] = 1; specs["grid_rows"] = 5; specs["grid_cols"] = 5
        specs["random_seed"] = 1
        Clade.create_environment(specs).agents[1]
    end

    function _haploid_genome(weights::Vector{Float32}, arch::Vector{Int32}, template)
        Clade.DiploidGenome(
            copy(weights),                   # maternal_weights
            Float32[],                       # paternal_weights (haploid = empty)
            copy(template.maternal_traits),  # maternal_traits
            Float32[],                       # paternal_traits
            arch,
            template.n_chromosomes,
        )
    end

    function _make_haploid_agent(arch::Vector{Int32}, rng::AbstractRNG)
        weights  = randn(rng, Float32, Clade.arch_to_n_weights(arch))
        ag       = _real_haploid_agent()
        ag.genome = _haploid_genome(weights, arch, ag.genome)
        ag.brain  = Clade.make_ann_brain(weights, arch)
        ag
    end

    @testset "lamarck_genome_update! writes phenotype to maternal_weights (haploid)" begin
        rng  = MersenneTwister(3)
        arch = Int32[4, 8, 3]
        ag   = _make_haploid_agent(arch, rng)

        # Manually perturb brain weights (simulating RL update)
        for (W, b) in ag.brain.layers
            W .+= 0.5f0
            b .+= 0.2f0
        end
        phenotype_flat = Clade.flatten(ag.brain)

        # Genome was set from the original weights — should differ from phenotype
        @test ag.genome.maternal_weights != phenotype_flat

        Clade.lamarck_genome_update!(ag)

        # After update, genome should match phenotype
        n = min(length(phenotype_flat), length(ag.genome.maternal_weights))
        @test ag.genome.maternal_weights[1:n] ≈ phenotype_flat[1:n]
    end

    @testset "lamarck_genome_update! is no-op for RandomBrain" begin
        rng  = MersenneTwister(4)
        arch = Int32[4, 3]
        ag    = _real_haploid_agent()
        ag.genome = _haploid_genome(
            rand(rng, Float32, Clade.arch_to_n_weights(arch)), arch, ag.genome)
        ag.brain  = Clade.make_random_brain(arch)
        original_weights = copy(ag.genome.maternal_weights)
        Clade.lamarck_genome_update!(ag)
        @test ag.genome.maternal_weights == original_weights   # unchanged
    end

end
