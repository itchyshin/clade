using Statistics
using Printf
using Random
using Clade

function run_sampler(n_envs::Int, seeds::Vector{Int}, out_file::String)
    max_t = 1000
    snapshots = [50, 100, 200, 500, 1000]

    println("Environments: $n_envs | Seeds per env: $(length(seeds))")
    println("Output file: $out_file")

    # Seed the global RNG for reproducible environment sampling
    Random.seed!(42) 

    open(out_file, "w") do io
        # Print CSV Header to file
        header = "env_id,move_cost,grass_max,repro_threshold,energy_init,mutation_sd,seed," *
                 "final_tick,final_agents,final_predators,final_genetic_diversity,extinct," *
                 join(["agents_$t" for t in snapshots], ",") * "," *
                 join(["div_$t" for t in snapshots], ",")
        println(io, header)

        for env_id in 1:n_envs
            # Sample parameters
            mc  = rand() * 20.0                 # move_cost [0.0, 20.0]
            gm  = 5.0 + (rand() * 45.0)         # grass_max [5.0, 50.0]
            rt  = 50.0 + (rand() * 150.0)       # repro_threshold [50.0, 200.0]
            ei  = 10.0 + (rand() * 90.0)        # energy_init [10.0, 100.0]
            msd = 0.01 + (rand() * 0.19)        # mutation_sd [0.01, 0.20]
            
            for s in seeds
                specs = Dict{String, Any}(
                    "random_seed"      => s,
                    "max_ticks"        => max_t, 
                    "n_agents_init"    => 50,
                    "n_predators_init" => 0, 
                    "move_cost"        => mc,
                    "grass_max"        => gm,
                    "repro_threshold"  => rt,
                    "energy_init"      => ei,
                    "mutation_sd"      => msd
                )
                
                res = Clade.run_clade(specs)
                t_final = res.t
                prog = res.progress
                
                agents_final = length(prog.n_agents) > 0 ? prog.n_agents[end] : 0
                preds_final  = length(prog.n_predators) > 0 ? prog.n_predators[end] : 0
                div_final    = length(prog.genetic_diversity) > 0 ? prog.genetic_diversity[end] : 0.0
                extinct      = agents_final == 0
                
                ag_snaps  = [t <= length(prog.n_agents) ? prog.n_agents[t] : 0 for t in snapshots]
                div_snaps = [t <= length(prog.genetic_diversity) ? prog.genetic_diversity[t] : 0.0 for t in snapshots]
                
                @printf(io, "%d,%.2f,%.2f,%.2f,%.2f,%.4f,%d,%d,%d,%d,%.6f,%s,", 
                        env_id, mc, gm, rt, ei, msd, s, t_final, agents_final, preds_final, div_final, extinct)
                
                print(io, join([Int(a) for a in ag_snaps], ","))
                print(io, ",")
                println(io, join([@sprintf("%.6f", d) for d in div_snaps], ","))
            end
        end
    end
    println("Done! Data successfully written to $out_file")
end

# CLI Argument Parsing for Cluster Execution
if abspath(PROGRAM_FILE) == @__FILE__
    # Default to 1 environment and "smoke_test.csv" if no arguments provided
    n_envs_arg = length(ARGS) > 0 ? parse(Int, ARGS[1]) : 1
    out_file_arg = length(ARGS) > 1 ? ARGS[2] : "smoke_test.csv"
    seeds_list = [101, 102, 103, 104, 105] 
    
    run_sampler(n_envs_arg, seeds_list, out_file_arg)
end