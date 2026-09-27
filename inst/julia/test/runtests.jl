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

@testset "Dead predators are removed" begin
    result = Clade.run_clade(Dict(
        "max_ticks" => 1,
        "n_agents_init" => 0,
        "n_predators_init" => 1,
        "predator_energy_init" => 1.0,
        "predator_live_energy" => 2.0,
        "predator_move_energy" => 0.0,
        "predator_max_age" => 100
    ))
    @test isempty(result.agents)
    @test result.progress.n_predators[end] == 0
end

@testset "Predators without prey" begin
    result = Clade.run_clade(Dict(
        "max_ticks" => 1,
        "n_agents_init" => 0,
        "n_predators_init" => 1,
        "predator_energy_init" => 500.0,
        "predator_live_energy" => 0.0,
        "predator_move_energy" => 0.0
    ))
    @test result.t == 1
    @test isempty(result.agents)
    @test result.progress.n_predators[end] == 1
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
    @test res_predators.progress.n_predators[end] > 0
    
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

    # 2b. log_movement alone (no log_movement_freq) records every tick
    s_nofreq = Dict{String, Any}("log_movement" => true, "max_ticks" => 3,
                                 "n_agents_init" => 5)
    res_nofreq = Clade.run_clade(s_nofreq)
    @test !isnothing(res_nofreq.movement_log)
    @test Set(res_nofreq.movement_log["tick"]) == Set(Int32(1):Int32(res_nofreq.t))

    # 3. Exact schema, equal column lengths, and exact sampled ticks
    s_sample = Dict{String, Any}(
        "log_movement" => true,
        "log_movement_freq" => 2,
        "max_ticks" => 4,
        "n_agents_init" => 10
    )
    res_sample = Clade.run_clade(s_sample)
    log_sample = res_sample.movement_log
    
    @test log_sample isa Dict{String, Vector}
    @test Set(keys(log_sample)) == Set(["tick", "id", "x", "y", "age", "energy", "alive"])
    
    lens = [length(v) for v in values(log_sample)]
    @test all(l -> l == lens[1], lens)
    @test lens[1] > 0
    @test unique(log_sample["tick"]) == [2, 4]

    # 4. Dead agents (alive=false) are logged before removal
    s_dead = Dict{String, Any}(
        "log_movement" => true,
        "log_movement_freq" => 1,
        "max_ticks" => 2,
        "n_agents_init" => 10,
        "energy_init" => 1.0, # Force instant starvation
        "move_cost" => 50.0
    )
    res_dead = Clade.run_clade(s_dead)
    @test false in res_dead.movement_log["alive"]

    # 5. Identical seeded final state (Recording ON vs OFF)
    s_parity = Dict{String, Any}(
        "random_seed" => 42, 
        "max_ticks" => 2, 
        "n_agents_init" => 5,
        "n_predators_init" => 0,
        "energy_init" => 50.0,
        "min_repro_energy" => 9999.0,   # no births: expressed threshold caps at 1000 > energy_max
        "log_movement_freq" => 1,
        "log_movement" => false,
        "_movement_log" => nothing 
    )

    res_seed_off = Clade.run_clade(s_parity)

    s_parity["log_movement"] = true
    s_parity["_movement_log"] = nothing

    res_seed_on  = Clade.run_clade(s_parity)

    # The comparison is meant to run without reproduction.
    @test all(res_seed_off.progress.n_births .== 0)
    @test all(res_seed_on.progress.n_births .== 0)

    # Compare ALL non-recording returned states
    @test res_seed_off.t == res_seed_on.t
    @test res_seed_off.agents == res_seed_on.agents
    @test res_seed_off.progress == res_seed_on.progress
    @test res_seed_off.deaths == res_seed_on.deaths
    @test res_seed_off.genome_log == res_seed_on.genome_log
    @test res_seed_off.total_carrion == res_seed_on.total_carrion
    @test res_seed_off.total_shelter == res_seed_on.total_shelter
end

@testset "Grass growth mode (#167)" begin
    base = Clade.get_default_specs()
    base["grid_rows"] = 6; base["grid_cols"] = 6
    base["grass_init_prob"] = 0.0
    base["grass_rate"] = 0.3; base["grass_max"] = 1.0
    base["random_seed"] = 7

    # 1. Deterministic: every cell grows by exactly `rate`, capped at gmax,
    #    and no random numbers are drawn.
    sd = copy(base); sd["grass_growth_mode"] = "deterministic"
    env = Clade.create_environment(sd)
    rng_before = copy(env.rng)
    Clade.grow_grass!(env)
    @test all(env.grass .== 0.3f0)
    @test env.rng == rng_before
    for _ in 1:5
        Clade.grow_grass!(env)
    end
    @test all(env.grass .== 1.0f0)

    # 2. Deterministic applies in the niche and seasonal-bias branches too
    #    (no cell is left at 0 after one tick).
    for extra in (Dict("niche_construction" => true),
                  Dict("seasonal_spatial_bias" => 0.5, "season_length" => 100))
        sx = merge(copy(sd), extra)
        envx = Clade.create_environment(sx)
        envx.t = 25   # mid-season so the spatial bias is non-zero
        Clade.grow_grass!(envx)
        @test all(envx.grass .> 0.0f0)
        @test all(envx.grass .<= 1.0f0)
    end

    # 3. Stochastic stays the default: a seeded run is identical with the
    #    mode unset and with it set explicitly to "stochastic".
    r1 = Dict{String,Any}("max_ticks" => 20, "n_agents_init" => 10,
                          "random_seed" => 11)
    r2 = copy(r1); r2["grass_growth_mode"] = "stochastic"
    @test Clade.run_clade(r1).progress == Clade.run_clade(r2).progress

    # 4. grass_density = sum(grass) / (N * gmax); grass_coverage unchanged.
    r3 = Dict{String,Any}("max_ticks" => 5, "n_agents_init" => 5,
                          "random_seed" => 3, "grass_rate" => 0.2,
                          "grass_growth_mode" => "deterministic")
    res = Clade.run_clade(r3)
    @test haskey(res.progress, :grass_density)
    @test all(0.0 .<= res.progress.grass_density .<= 1.0)
    @test all(res.progress.grass_coverage .<= 1.0)

    # 5. Unknown mode is rejected.
    sbad = copy(base); sbad["grass_growth_mode"] = "continuous"
    @test_throws ArgumentError Clade.grow_grass!(Clade.create_environment(sbad))
end


# Test-only brain that always prefers action `a` (1..5).
struct _FixedActionBrain <: Clade.AbstractBrain
    a::Int
    nin::Int32   # copied from the brain it replaces, so sensing is unchanged
end
_FixedActionBrain(a::Int, old::Clade.AbstractBrain) =
    _FixedActionBrain(a, Clade.n_inputs(old))
Clade.n_inputs(b::_FixedActionBrain) = b.nin
function Clade.forward(b::_FixedActionBrain, ::Vector{Float32})
    v = zeros(Float32, 5); v[b.a] = 1.0f0; v
end

@testset "last_action contract (#164)" begin
    # Encoding = the brain's output index: 0 = no action yet,
    # 1 = N, 2 = E, 3 = S, 4 = W, 5 = stay (prey idle; predator
    # stay-and-attack). Death is alive = false, never a code.
    base = Clade.get_default_specs()
    base["grid_rows"] = 10; base["grid_cols"] = 10
    base["random_seed"] = 5
    base["brain_energy_mode"] = "none"

    # 1. Founders start at 0.
    env = Clade.create_environment(copy(base))
    @test !isempty(env.agents)
    @test all(ag -> ag.last_action == Int8(0), env.agents)

    # 2. Real brains: after one tick every living agent holds a code in 1..5.
    Clade.tick_agents!(env)
    @test all(ag -> ag.last_action in Int8(1):Int8(5),
              filter(ag -> ag.alive, env.agents))

    # 3. Each code is recorded exactly, with the matching move.
    #    Direction deltas as in tick.jl: N = row-1, E = col+1, S = row+1, W = col-1.
    deltas = Dict(1 => (-1, 0), 2 => (0, 1), 3 => (1, 0), 4 => (0, -1), 5 => (0, 0))
    for a in 1:5
        s1 = copy(base); s1["n_agents_init"] = 1
        e1 = Clade.create_environment(s1)
        ag = e1.agents[1]
        ag.x = Int32(5); ag.y = Int32(5)
        ag.brain = _FixedActionBrain(a, ag.brain)
        Clade.tick_agents!(e1)
        @test ag.last_action == Int8(a)
        @test (ag.x, ag.y) == (Int32(5 + deltas[a][1]), Int32(5 + deltas[a][2]))
    end

    # 4. A blocked move still records the choice (intent, not outcome).
    s2 = copy(base); s2["n_agents_init"] = 2; s2["random_tick_order"] = false
    e2 = Clade.create_environment(s2)
    mover, blocker = e2.agents[1], e2.agents[2]
    mover.x, mover.y = Int32(5), Int32(5)
    blocker.x, blocker.y = Int32(5), Int32(6)          # east of mover
    mover.brain = _FixedActionBrain(2, mover.brain)                 # tries E
    blocker.brain = _FixedActionBrain(5, blocker.brain)               # stays
    Clade.tick_agents!(e2)
    @test mover.last_action == Int8(2)
    @test (mover.x, mover.y) == (Int32(5), Int32(5))

    # 5. Offspring start at 0.
    s3 = copy(base); s3["n_agents_init"] = 20
    e3 = Clade.create_environment(s3)
    n0 = length(e3.agents)
    for ag in e3.agents
        ag.energy = 190.0f0; ag.age = Int32(50); ag.last_action = Int8(3)
    end
    Clade.create_offspring!(e3)
    newborns = e3.agents[(n0 + 1):end]
    @test !isempty(newborns)
    @test all(ag -> ag.last_action == Int8(0), newborns)

    # 6. Predators: founders 0, each chosen code recorded, offspring 0.
    s4 = copy(base); s4["n_predators_init"] = 3
    e4 = Clade.create_environment(s4)
    Clade.seed_predators!(e4)
    @test length(e4.predators) == 3
    @test all(p -> p.last_action == Int8(0), e4.predators)
    real_brains = [p.brain for p in e4.predators]
    for (p, a) in zip(e4.predators, (1, 4, 5))
        p.brain = _FixedActionBrain(a, p.brain)
    end
    Clade.tick_predators!(e4)
    for (p, a) in zip(e4.predators, (1, 4, 5))
        p.alive && @test p.last_action == Int8(a)
    end
    np0 = length(e4.predators)
    for (p, b) in zip(e4.predators, real_brains)
        p.brain = b      # reproduction mutates a copy of the parent brain
        p.alive = true; p.energy = 1000.0f0; p.age = Int32(100)
    end
    Clade._predator_reproduction!(e4)
    pups = e4.predators[(np0 + 1):end]
    @test !isempty(pups)
    @test all(p -> p.last_action == Int8(0), pups)
end

# Warning messages emitted by `f()`. Uses Test.TestLogger directly:
# on Julia 1.10.0 a failing @test_logs crashes while recording the
# failure (Test.scrub_backtrace MethodError), hiding the real cause.
function _warnings(f)
    tl = Test.TestLogger()
    Base.CoreLogging.with_logger(f, tl)
    [string(l.message) for l in tl.logs if l.level == Base.CoreLogging.Warn]
end

@testset "Unknown spec keys warn (#185)" begin
    # A key the kernel never reads is almost always a typo or a name from
    # another codebase (e.g. A-life's `repro_threshold`; clade uses
    # `min_repro_energy`). It must not pass silently.
    w = _warnings(() -> Clade.normalize_specs(
        Dict{String,Any}("repro_threshold" => 150.0)))
    @test length(w) == 1
    @test occursin("repro_threshold", w[1])
    @test occursin("min_repro_energy", w[1])   # names the clade spec

    # One warning per unknown key.
    w2 = _warnings(() -> Clade.normalize_specs(
        Dict{String,Any}("foo_a" => 1, "foo_b" => 2)))
    @test length(w2) == 2
    @test any(m -> occursin("foo_a", m), w2)
    @test any(m -> occursin("foo_b", m), w2)

    # Known keys, keys R sends, and Julia-internal `_` keys stay silent.
    @test isempty(_warnings(() -> Clade.normalize_specs(Dict{String,Any}(
        "max_ticks" => 5, "log_movement" => true, "log_movement_freq" => 2,
        "grass_growth_mode" => "deterministic", "_movement_log" => nothing))))

    # Unknown keys still pass through (warn, not error).
    kept = Ref{Any}(nothing)
    _warnings(() -> kept[] = Clade.normalize_specs(
        Dict{String,Any}("repro_threshold" => 1.0)))
    @test kept[]["repro_threshold"] == 1.0
end

@testset "Clade Julia unit tests" begin
    include("test_ann_quantization.jl")
    include("test_ann_regularization.jl")
    include("test_lamarckian.jl")
end
