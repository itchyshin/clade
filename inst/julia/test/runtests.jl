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

@testset "Early Termination (#165)" begin
    # 1. Early termination when BOTH agents and predators are extinct
    s_extinct = Dict{String, Any}(
        "max_ticks" => 50,
        "n_agents_init" => 10,
        "n_predators_init" => 0,
        "energy_init" => 1.0, 
        "move_cost" => 50.0
    )
    res_extinct = Clade.run_clade(s_extinct)
    @test res_extinct.t < 50
    @test isempty(res_extinct.agents)
    @test res_extinct.progress.n_predators[end] == 0

    # 2. Normal execution while ONLY AGENTS remain
    s_agents = Dict{String, Any}(
        "max_ticks" => 10,
        "n_agents_init" => 10,
        "n_predators_init" => 0,
        "energy_init" => 500.0, 
        "move_cost" => 0.0
    )
    res_agents = Clade.run_clade(s_agents)
    @test res_agents.t == 10
    @test !isempty(res_agents.agents)
    @test res_agents.progress.n_predators[end] == 0
    
    # 3. Normal execution while ONLY PREDATORS remain
    s_predators = Dict{String, Any}(
        "max_ticks" => 3, 
        "n_agents_init" => 0,
        "n_predators_init" => 5,
        "energy_init" => 5000.0,
        "predator_energy_init" => 5000.0,
        "move_cost" => 0.0,
        "predator_move_energy" => 0.0,
        "predator_live_energy" => 0.0,
        "max_age" => 500,
        "predator_max_age" => 500
    )
    res_predators = Clade.run_clade(s_predators)
    @test res_predators.t == 3
    @test isempty(res_predators.agents)
    @test isempty(res_predators.deaths.id)
    
    # 4. Normal execution until seeded predator dies from starvation
    s_pred_dies = Dict{String, Any}(
        "max_ticks" => 50,
        "n_agents_init" => 0,
        "n_predators_init" => 1,
        "energy_init" => 1.0,
        "predator_energy_init" => 1.0,
        "move_cost" => 50.0,
        "predator_move_energy" => 50.0,
        "predator_live_energy" => 50.0
    )
    res_pred_dies = Clade.run_clade(s_pred_dies)
    @test res_pred_dies.t < 50
    @test isempty(res_pred_dies.agents)
    @test res_pred_dies.progress.n_predators[end] == 0
end

@testset "Movement Logging Contract (#176)" begin
    # 1. Disabled recording returns no log
    s_off = Dict{String, Any}("log_movement" => false, "max_ticks" => 5)
    res_off = Clade.run_clade(s_off)
    @test isnothing(res_off.movement_log)

    # 2. Invalid frequency throws ArgumentError before the loop
    s_err = Dict{String, Any}("log_movement" => true, "log_movement_freq" => 0)
    @test_throws ArgumentError Clade.run_clade(s_err)

    # 3 & 4. Exact schema, sampled ticks, and dead agents (alive=false)
    s_on = Dict{String, Any}(
        "log_movement" => true,
        "log_movement_freq" => 2,
        "max_ticks" => 4,
        "n_agents_init" => 10,
        "energy_init" => 1.0, # Force instant starvation
        "move_cost" => 50.0
    )
    res_on = Clade.run_clade(s_on)
    log = res_on.movement_log
    
    @test log isa Dict{String, Vector}
    @test haskey(log, "tick") && haskey(log, "alive")
    @test all(t -> t % 2 == 0, log["tick"]) # Sampled only on even ticks
    @test length(log["tick"]) > 0
    @test false in log["alive"] # Dead agents successfully logged before removal

    # 5. Identical seeded final state (Recording ON vs OFF)
    Random.seed!(42)
    res_seed_off = Clade.run_clade(Dict{String, Any}("max_ticks" => 5, "log_movement" => false))

    Random.seed!(42)
    res_seed_on = Clade.run_clade(Dict{String, Any}("max_ticks" => 5, "log_movement" => true, "log_movement_freq" => 1))

    @test length(res_seed_off.agents) == length(res_seed_on.agents)
    @test res_seed_off.progress.n_deaths[end] == res_seed_on.progress.n_deaths[end]
end

@testset "Clade Julia unit tests" begin
    include("test_ann_quantization.jl")
    include("test_ann_regularization.jl")
    include("test_lamarckian.jl")
end

@testset "Clade Julia unit tests" begin
    include("test_ann_quantization.jl")
    include("test_ann_regularization.jl")
    include("test_lamarckian.jl")
end
