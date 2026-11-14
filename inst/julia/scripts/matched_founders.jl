# Factorial matched-start experiment. Uses the canonical simulation loop.
# Run from repo root: julia --project=inst/julia inst/julia/scripts/matched_founders.jl 100 OUTDIR 1000
if !isdefined(@__MODULE__, :Clade)
    using Clade
end
module MatchedFounders
import ..Clade
using Random, Statistics, SHA, Serialization, Printf

const REFERENCE_SD = 0.05
const FOUNDER_SDS = (0.0, 0.05, 0.20)
const MUTATION_SDS = (0.0, 0.05, 0.20)
const EXPLORATION = ("fixed", "heterozygosity")
const WORLDS = (("benign", 1.0), ("costly", 6.0))

# Canonical key order makes hashes comparable across processes on the pinned
# Julia version. The digest never draws from the simulation RNG.
function canonical(x)
    if x isa AbstractDict
        return (:dict, Tuple((canonical(k), canonical(x[k])) for k in sort!(collect(keys(x)); by=repr)))
    elseif x isa AbstractArray
        return (:array, size(x), Tuple(canonical(v) for v in x))
    elseif x isa NamedTuple
        return (keys(x), Tuple(canonical(v) for v in values(x)))
    elseif x isa Tuple
        return Tuple(canonical(v) for v in x)
    elseif x isa Number || x isa AbstractString || x isa Symbol || x === nothing
        return x
    end
    (string(typeof(x)), Tuple(canonical(getfield(x, i)) for i in 1:fieldcount(typeof(x))))
end
function digest(x)
    io = IOBuffer()
    serialize(io, canonical(x))
    bytes2hex(sha256(take!(io)))
end
function initial_digest(env)
    excluded = (:specs, :progress, :deaths, :genome_log)
    names = filter(n -> n ∉ excluded, fieldnames(typeof(env)))
    digest(Tuple((n, getfield(env, n)) for n in names))
end

# Enumerate every distinct pair, preserving the source metric's Float32
# accumulation and sqrt. Precompute expression once to avoid pairwise copies.
function exact_diversity(agents)
    weights = [Clade.express_weights(a.genome, "additive") for a in agents if a.alive]
    n = length(weights)
    n < 2 && return NaN
    total = 0.0
    for i in 1:(n-1), j in (i+1):n
        s = 0.0f0
        @inbounds for k in eachindex(weights[i])
            d = weights[i][k] - weights[j][k]
            s += d*d
        end
        total += Float64(sqrt(s / Float32(length(weights[i]))))
    end
    total / (n*(n-1)/2)
end
mean_sigma(agents) = isempty(agents) ? NaN :
    mean(Float64(mean(a.brain.sigma)) for a in agents)

function trial(user_specs, founder_sd::Real)
    isfinite(founder_sd) && founder_sd >= 0 || throw(ArgumentError("founder_sd must be finite and nonnegative"))
    initial = Ref{Any}()
    environment = Ref{Any}()
    function initialize(specs)
        # All scalar traits and RNG draws come from one reference population.
        reference = copy(specs)
        reference["mutation_sd"] = REFERENCE_SD
        env = Clade.create_environment(reference)
        if founder_sd != REFERENCE_SD
            scale = Float32(founder_sd / REFERENCE_SD)
            for a in env.agents
                a.genome.maternal_weights .*= scale
                a.genome.paternal_weights .*= scale
                a.brain = Clade.make_brain(a.genome, reference)
            end
        end
        initial[] = (fingerprint=initial_digest(env),
                     diversity=exact_diversity(env.agents),
                     mean_sigma=mean_sigma(env.agents))
        env.specs = specs # subsequent inheritance reads treatment mutation_sd
        environment[] = env
        env
    end
    result = Clade._run_clade(user_specs, initialize)
    (result=result, env=environment[], initial=initial[])
end

value(x::AbstractString) = x
value(x::Bool) = string(x)
value(x::Integer) = string(x)
value(x::Real) = isfinite(x) ? @sprintf("%.17g", x) : "NA"
row(io, xs) = println(io, join(value.(xs), ','))

function run_study(n_seeds::Int, outdir::AbstractString; max_ticks::Int=1000)
    n_seeds > 0 || throw(ArgumentError("n_seeds must be positive"))
    max_ticks > 0 || throw(ArgumentError("max_ticks must be positive"))
    isdir(outdir) && !isempty(readdir(outdir)) && throw(ArgumentError("output directory must be empty"))
    mkpath(outdir)
    snapshots = sort!(unique([0,1,2,5,10,20,50,100,200,500,max_ticks]))
    filter!(t -> t <= max_ticks, snapshots)
    completed = 0
    open(joinpath(outdir,"runs.csv"),"w") do runs
        open(joinpath(outdir,"trajectories.csv"),"w") do traces
            println(runs,"exploration,world,move_cost,founder_sd,mutation_sd,seed,initial_fingerprint,initial_diversity,initial_mean_sigma,final_tick,final_agents,final_diversity,diversity_gain,mean_population,min_population,tick_of_min,total_births,final_haploid_fraction,final_mean_sigma")
            println(traces,"exploration,world,founder_sd,mutation_sd,seed,t,n_agents,diversity_sampled,diversity_exact")
            for exploration in EXPLORATION, (world,move_cost) in WORLDS, founder_sd in FOUNDER_SDS, seed in 10001:(10000+n_seeds)
                expected_hash = nothing
                for mutation_sd in MUTATION_SDS
                    specs = Dict{String,Any}("random_seed"=>seed,"max_ticks"=>max_ticks,
                        "grid_rows"=>30,"grid_cols"=>30,"n_agents_init"=>50,
                        "brain_type"=>"bnn","bnn_sigma_source"=>exploration,
                        "bnn_sigma_init"=>0.5,"move_cost"=>move_cost,
                        "grass_max"=>20.0,"min_repro_energy"=>120.0,
                        "energy_init"=>70.0,"mutation_sd"=>mutation_sd,
                        "grass_growth_mode"=>"stochastic","sense_mode"=>"per_cell")
                    run = trial(specs, founder_sd)
                    init = run.initial; env = run.env; t_final = Int(env.t)
                    expected_hash === nothing && (expected_hash = init.fingerprint)
                    init.fingerprint == expected_hash || error("founder mismatch at $exploration/$world/$founder_sd/$seed")
                    n_final = length(env.agents)
                    d_final = exact_diversity(env.agents)
                    ns = env.progress["n_agents"][1:t_final]
                    if founder_sd == 0 && mutation_sd == 0
                        all(iszero, env.progress["genetic_diversity"][1:t_final]) || error("zero-variation control failed")
                        (n_final < 2 || d_final == 0) || error("zero-variation endpoint failed")
                    end
                    haploid = n_final == 0 ? NaN : mean(Clade.is_haploid(a.genome) for a in env.agents)
                    row(runs,(exploration,world,move_cost,founder_sd,mutation_sd,seed,
                        init.fingerprint,init.diversity,init.mean_sigma,t_final,n_final,
                        d_final,d_final-init.diversity,sum(ns)/max_ticks,minimum(ns),
                        argmin(ns),sum(env.progress["n_births"][1:t_final]),haploid,mean_sigma(env.agents)))
                    for t in sort!(unique(vcat(snapshots,t_final)))
                        n = t == 0 ? 50 : (t <= t_final ? Int(env.progress["n_agents"][t]) : NaN)
                        sampled = t > 0 && t <= t_final && n >= 2 ? env.progress["genetic_diversity"][t] : NaN
                        exact = t == 0 ? init.diversity : (t == t_final ? d_final : NaN)
                        row(traces,(exploration,world,founder_sd,mutation_sd,seed,t,n,sampled,exact))
                    end
                    completed += 1
                    flush(runs); flush(traces)
                    completed % 100 == 0 && println("completed $completed / $(36*n_seeds)")
                end
            end
        end
    end
    println("completed $completed runs in $outdir")
    completed
end
end # module

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) in (2,3) || error("usage: matched_founders.jl N_SEEDS OUTDIR [MAX_TICKS]")
    MatchedFounders.run_study(parse(Int,ARGS[1]), ARGS[2];
        max_ticks=length(ARGS)==3 ? parse(Int,ARGS[3]) : 1000)
end
