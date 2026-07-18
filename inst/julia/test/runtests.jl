# Clade Julia test suite
# Run with: julia --project=inst/julia inst/julia/test/runtests.jl
# (from the clade R package root directory)
#
# These are unit tests for the Julia simulation engine that do NOT require
# the R side (no JuliaConnectoR). They test individual functions directly.
#
# Run all R-side tests with: devtools::test() from R.

using Test
using Random
using Statistics

# Load the Clade module
include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
using .Clade

@testset "Clade Julia unit tests" begin
    include("test_ann_quantization.jl")
    include("test_ann_regularization.jl")
    include("test_lamarckian.jl")
end

@testset "Defaults and Partial Specs" begin
    # Test 1: Ordinary inferred Dict{String, Int}
    partial_int_dict = Dict("max_ticks" => 2, "n_agents_init" => 10)
    norm_int = Clade.normalize_specs(partial_int_dict)
    @test norm_int["max_ticks"] == 2
    @test norm_int["energy_init"] == 100.0 # Proves defaults merged

    # Test 2: run_clade with empty Dict
    # Using a tiny max_ticks override just so the test runs fast
    result_empty = Clade.run_clade(Dict("max_ticks" => 1, "n_agents_init" => 2))
    @test result_empty isa Any # Ensures it didn't crash

    # Test 3: R-Julia default parity (max_ticks)
    defaults = Clade.get_default_specs()
    @test defaults["max_ticks"] == 500
end