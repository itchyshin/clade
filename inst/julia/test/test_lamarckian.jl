# test_lamarckian.jl
# Unit tests for Lamarckian genome write-back (lamarck_genome_update!)

@testset "Lamarckian genome update" begin

    # Helper: build a minimal haploid agent with an ANNBrain
    function _make_haploid_agent(arch::Vector{Int32}, rng::AbstractRNG)
        n       = Clade.arch_to_n_weights(arch)
        weights = randn(rng, Float32, n)
        brain   = Clade.make_ann_brain(weights, arch)

        genome = Clade.DiploidGenome(
            copy(weights),          # maternal_weights
            Float32[],              # paternal_weights (haploid = empty)
            Float32[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],   # maternal_traits (7 traits)
            Float32[],              # paternal_traits
            arch
        )
        # Minimal Agent construction (enough fields for lamarck_genome_update!)
        Clade.Agent(
            id         = Int64(1),
            x          = Int32(1), y = Int32(1),
            energy     = 100.0f0,
            age        = Int32(0),
            t_birth    = Int32(0),
            alive      = true,
            brain      = brain,
            genome     = genome,
            reproduced = false,
            num_offspring = Int32(0),
            # remaining fields use defaults / zeros
        )
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
        brain = Clade.make_random_brain(arch)
        genome = Clade.DiploidGenome(
            rand(rng, Float32, Clade.arch_to_n_weights(arch)),
            Float32[], Float32[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], Float32[], arch
        )
        original_weights = copy(genome.maternal_weights)
        ag = Clade.Agent(id=Int64(2), x=Int32(1), y=Int32(1),
                          energy=100.0f0, age=Int32(0), t_birth=Int32(0),
                          alive=true, brain=brain, genome=genome,
                          reproduced=false, num_offspring=Int32(0))
        Clade.lamarck_genome_update!(ag)
        @test ag.genome.maternal_weights == original_weights   # unchanged
    end

end
