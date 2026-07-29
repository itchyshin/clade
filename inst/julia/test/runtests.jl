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

@testset "Movement Logger" begin
    # Test 1: ArgumentError for invalid frequency
    s_err = Dict("log_movement" => true, "log_movement_freq" => 0)
    @test_throws ArgumentError Clade.run_clade(s_err)

    # Test 2: Deterministic state check and logging features
    # Set energy_init low and move_cost high so agents die quickly, ensuring we capture alive = false
    s1 = Dict("log_movement" => false, "n_agents_init" => 10, "max_ticks" => 5, "energy_init" => 2.0, "move_cost" => 5.0)
    s2 = Dict("log_movement" => true, "log_movement_freq" => 2, "n_agents_init" => 10, "max_ticks" => 5, "energy_init" => 2.0, "move_cost" => 5.0)
    
    Random.seed!(42)
    res_off = Clade.run_clade(s1)
    
    Random.seed!(42)
    res_on = Clade.run_clade(s2)
    
    # Check complete final agent state matches for identical seeds
    @test length(res_off.agents) == length(res_on.agents)
    if length(res_off.agents) > 0
        for (a_off, a_on) in zip(res_off.agents, res_on.agents)
            @test a_off.id == a_on.id
            @test a_off.x == a_on.x
            @test a_off.y == a_on.y
            @test a_off.energy == a_on.energy
            @test a_off.age == a_on.age
            @test a_off.alive == a_on.alive
        end
    end
    
    # Disabled state has no log
    @test res_off.movement_log === nothing
    
    # Enabled state has expected fields
    log = res_on.movement_log
    @test log !== nothing
    @test haskey(log, "tick")
    @test haskey(log, "id")
    @test haskey(log, "x")
    @test haskey(log, "y")
    @test haskey(log, "age")
    @test haskey(log, "energy")
    @test haskey(log, "alive")
    
    # Ticks selected by log_movement_freq (should only be even ticks: 2, 4)
    if !isempty(log["tick"])
        ticks = unique(log["tick"])
        @test all(t -> t % 2 == 0, ticks)
    end

    # Check for at least one alive = false record (agents should starve by tick 2 or 4)
    if !isempty(log["alive"])
        @test any(alive -> alive == false, log["alive"])
    end
end

@testset "Clade Julia unit tests" begin
    include("test_ann_quantization.jl")
    include("test_ann_regularization.jl")
    include("test_lamarckian.jl")
end
