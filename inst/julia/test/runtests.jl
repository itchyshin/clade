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

@testset "Defaults and Partial Specs" begin
    # Test 1: Ordinary inferred Dict{String, Int}
    partial_int_dict = Dict("max_ticks" => 2, "n_agents_init" => 10)
    norm_int = Clade.normalize_specs(partial_int_dict)
    @test norm_int["max_ticks"] == 2
    @test norm_int["energy_init"] == 100.0 # Proves defaults merged

    # Test 2: Explicitly test normalize_specs with a truly empty Dict
    norm_empty = Clade.normalize_specs(Dict())
    @test norm_empty["max_ticks"] == 500
    @test norm_empty["n_agents_init"] == 50

    # Test 3: run_clade with minimal overrides (meaningful returned fields check)
    result = Clade.run_clade(Dict("max_ticks" => 1, "n_agents_init" => 2))
    @test result.t == 1
    @test hasproperty(result, :agents)
    @test hasproperty(result, :progress)
    @test hasproperty(result, :deaths)
    @test hasproperty(result, :genome_log)
    @test hasproperty(result, :total_carrion)
    @test hasproperty(result, :total_shelter)

    # Test 4: R-Julia default parity (max_ticks)
    defaults = Clade.get_default_specs()
    @test defaults["max_ticks"] == 500
end

@testset "Clade Julia unit tests" begin
    include("test_ann_quantization.jl")
    include("test_ann_regularization.jl")
    include("test_lamarckian.jl")
end
