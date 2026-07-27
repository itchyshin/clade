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

@testset "Movement Logging" begin
    # 1. Disabled state
    res_off = Clade.run_clade(Dict("max_ticks" => 5, "n_agents_init" => 10, "log_movement" => false))
    @test isempty(res_off.specs["_movement_log"]["tick"])

    # 2. Enabled state & Frequency
    res_on = Clade.run_clade(Dict(
        "max_ticks" => 10, 
        "n_agents_init" => 10, 
        "log_movement" => true, 
        "log_movement_freq" => 2
    ))
    log_on = res_on.specs["_movement_log"]
    
    # Expected fields exist and lengths match
    @test length(log_on["tick"]) > 0
    @test length(log_on["tick"]) == length(log_on["id"]) == length(log_on["x"]) == length(log_on["y"]) == length(log_on["age"]) == length(log_on["energy"]) == length(log_on["alive"])
    
    # Frequency is respected (only even ticks recorded)
    @test all(t -> t % 2 == 0, log_on["tick"])

    # 3. Determinism check (logging doesn't change outcome for same seed)
    res_det1 = Clade.run_clade(Dict("max_ticks" => 15, "random_seed" => 42, "log_movement" => false))
    res_det2 = Clade.run_clade(Dict("max_ticks" => 15, "random_seed" => 42, "log_movement" => true))
    
    # The final state of the agents should be completely identical
    @test length(res_det1.agents) == length(res_det2.agents)
    if length(res_det1.agents) > 0
        @test res_det1.agents[1].x == res_det2.agents[1].x
        @test res_det1.agents[1].energy == res_det2.agents[1].energy
    end
end
