using Statistics
using Printf
using Random
if !isdefined(@__MODULE__, :Clade)
    using Clade
end
function sample_environments(n_envs::Int, seeds::Vector{Int}, out_file::String;
                             run_simulation=Clade.run_clade)
    n_envs > 0 || throw(ArgumentError("n_envs must be positive"))
    !isempty(seeds) && all(>=(0), seeds) && allunique(seeds) ||
        throw(ArgumentError("seeds must be nonempty, nonnegative and unique"))
    max_t = 1000
    snapshots = [50, 100, 200, 500, 1000]
    println("Environments: $n_envs | Seeds per env: $(length(seeds))")
    println("Output file: $out_file")
    design_rng = Random.Xoshiro(42)
    open(out_file, "w") do io
        header = "env_id,move_cost,grass_max,min_repro_energy,energy_init,mutation_sd,seed," *
                 "final_tick,final_agents,final_predators,final_genetic_diversity,extinct," *
                 join(["agents_$t" for t in snapshots], ",") * "," *
                 join(["div_$t" for t in snapshots], ",")
        println(io, header)
        for env_id in 1:n_envs
            mc  = rand(design_rng) * 12.0                 # move_cost [0.0, 12.0]
            gm  = 5.0 + (rand(design_rng) * 45.0)         # grass_max [5.0, 50.0]
            mre = 50.0 + (rand(design_rng) * 150.0)       # min_repro_energy [50.0, 200.0]
            ei  = 10.0 + (rand(design_rng) * 90.0)        # energy_init [10.0, 100.0]
            msd = 0.01 + (rand(design_rng) * 0.19)        # mutation_sd [0.01, 0.20]
            for s in seeds
                specs = Dict{String, Any}(
                    "random_seed"       => s,
                    "max_ticks"         => max_t, 
                    "n_agents_init"     => 50,
                    "n_predators_init"  => 0, 
                    "move_cost"         => mc,
                    "grass_max"         => gm,
                    "min_repro_energy"  => mre,
                    "energy_init"       => ei,
                    "mutation_sd"       => msd,
                    "grass_growth_mode" => "stochastic"
                )
                res = run_simulation(specs)
                t_final = res.t
                prog = res.progress
                agents_final = t_final > 0 ? prog.n_agents[t_final] : 0
                preds_final  = t_final > 0 ? prog.n_predators[t_final] : 0
                div_final    = t_final > 0 ? prog.genetic_diversity[t_final] : 0.0
                extinct      = agents_final == 0
                ag_snaps  = [t <= t_final ? string(prog.n_agents[t]) : "NA" for t in snapshots]
                div_snaps = [t <= t_final ? @sprintf("%.6f", prog.genetic_diversity[t]) : "NA" for t in snapshots]
                @printf(io, "%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%d,%d,%d,%.6f,%s,",
                        env_id, mc, gm, mre, ei, msd, s, t_final, agents_final, preds_final, div_final, extinct)
                print(io, join(ag_snaps, ","))
                print(io, ",")
                println(io, join(div_snaps, ","))
            end
        end
    end
    println("Done! Data successfully written to $out_file")
end
if abspath(PROGRAM_FILE) == @__FILE__
    n_envs_arg = length(ARGS) > 0 ? parse(Int, ARGS[1]) : 1
    out_file_arg = length(ARGS) > 1 ? ARGS[2] : "smoke_test.csv"
    seeds_list = [101, 102, 103, 104, 105] 
    sample_environments(n_envs_arg, seeds_list, out_file_arg)
end
