# test_ann_regularization.jl
# Unit tests for ANN weight regularisation (_ann_weight_magnitude, _ann_weight_count)

@testset "ANN weight regularization" begin

    @testset "_ann_weight_magnitude ANNBrain" begin
        arch  = Int32[2, 4, 2]
        # Build a brain where all weights = 1.0 so we know the expected sum
        n = Clade.arch_to_n_weights(arch)
        brain = Clade.make_ann_brain(ones(Float32, n), arch)
        expected = Float32(n)   # all weights = 1.0, so sum(|w|) = n
        @test Clade._ann_weight_magnitude(brain) ≈ expected
    end

    @testset "_ann_weight_magnitude is 0 for RandomBrain" begin
        arch  = Int32[3, 2]
        brain = Clade.make_random_brain(arch)
        @test Clade._ann_weight_magnitude(brain) == 0.0f0
    end

    @testset "_ann_weight_count ANNBrain counts only active weights" begin
        arch  = Int32[2, 4, 2]
        n = Clade.arch_to_n_weights(arch)
        # Half weights = 0.5 (active), half = 0.0 (inactive below threshold)
        w = Float32[i <= n÷2 ? 0.5f0 : 0.0f0 for i in 1:n]
        brain = Clade.make_ann_brain(w, arch)
        c = Clade._ann_weight_count(brain)
        @test c ≈ Float32(n ÷ 2)
    end

    @testset "weight_magnitude > weight_count for typical brain" begin
        rng   = MersenneTwister(1)
        arch  = Int32[4, 8, 3]
        n     = Clade.arch_to_n_weights(arch)
        brain = Clade.make_ann_brain(randn(rng, Float32, n), arch)
        # weight_magnitude = sum(|w|); weight_count = number of non-zero weights
        # For random weights, magnitude >> count (magnitudes >> 1 on average)
        mag   = Clade._ann_weight_magnitude(brain)
        count = Clade._ann_weight_count(brain)
        @test mag > count   # sum(|w|) > n_nonzero when mean |w| > 1
    end

end
