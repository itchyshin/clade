# test_ann_quantization.jl
# Unit tests for discrete/quantized ANN weights (_snap_to_nearest!, _quantize_brain_weights!)

@testset "ANN weight quantization" begin

    @testset "_snap_to_nearest! ternary {-1, 0, 1}" begin
        pv = Float32[-1.0, 0.0, 1.0]
        v  = Float32[-0.9, -0.4, 0.0, 0.3, 0.7, 1.5, -2.0]
        Clade._snap_to_nearest!(v, pv)
        @test v == Float32[-1.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0]
    end

    @testset "_snap_to_nearest! binary {-1, 1}" begin
        pv = Float32[-1.0, 1.0]
        v  = Float32[-0.5, 0.0, 0.5, 2.0]
        Clade._snap_to_nearest!(v, pv)
        # 0.0 is equidistant; implementation picks first in sorted order = -1
        @test all(w -> w ∈ (-1.0f0, 1.0f0), v)
    end

    @testset "ANNBrain ternary quantization" begin
        rng  = MersenneTwister(42)
        arch = Int32[4, 8, 3]
        # Build brain via make_ann_brain with random weights
        weights = randn(rng, Float32, Clade.arch_to_n_weights(arch))
        brain   = Clade.make_ann_brain(weights, arch)

        # Before quantization: weights are continuous
        all_w_before = vcat([vcat(vec(W), b) for (W, b) in brain.layers]...)
        @test !all(w -> w ∈ (-1.0f0, 0.0f0, 1.0f0), all_w_before)

        Clade._quantize_brain_weights!(brain, Float32[-1.0, 0.0, 1.0])
        all_w_after = vcat([vcat(vec(W), b) for (W, b) in brain.layers]...)
        @test all(w -> w ∈ (-1.0f0, 0.0f0, 1.0f0), all_w_after)
    end

    @testset "No-op for unsupported brain type" begin
        struct _TestDummyBrain <: Clade.AbstractBrain end
        dummy = _TestDummyBrain()
        # Should not throw
        Clade._quantize_brain_weights!(dummy, Float32[-1.0, 0.0, 1.0])
        @test true
    end

end
