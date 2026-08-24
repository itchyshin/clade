using Statistics
using Printf
using Random
using Clade

function run_test()
    n_envs = 1
    seeds = [101, 102, 103, 104, 105]
    max_t = 1000
    snapshots = [50, 100, 200, 500, 1000]
    
    # Print CSV Header
    header = "env_id,move_cost,grass_max,repro_threshold,energy_init,mutation_sd,seed," *
             "final_tick,final_agents,final_predators,final_genetic_diversity,extinct," *
             join(["agents_$t" for t in snapshots], ",") * "," *
             join(["div_$t" for t in snapshots], ",")
    println(header)

    # Seed the global RNG just for reproducible environment sampling in this script
    Random.seed!(42) 

    for env_id in 1:n_envs
        # Sample parameters for this environment
        mc  = rand() * 20.0                 # move_cost [0.0, 20.0]
        gm  = 5.0 + (rand() * 45.0)         # grass_max [5.0, 50.0]
        rt  = 50.0 + (rand() * 150.0)       # repro_threshold [50.0, 200.0]
        ei  = 10.0 + (rand() * 90.0)        # energy_init [10.0, 100.0]
        msd = 0.01 + (rand() * 0.19)        # mutation_sd [0.01, 0.20]
        
        for s in seeds
            specs = Dict{String, Any}(
                "random_seed"      => s,    # Engine-level RNG
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
            
            # Final Metrics
            agents_final = length(prog.n_agents) > 0 ? prog.n_agents[end] : 0
            preds_final  = length(prog.n_predators) > 0 ? prog.n_predators[end] : 0
            div_final    = length(prog.genetic_diversity) > 0 ? prog.genetic_diversity[end] : 0.0
            extinct      = agents_final == 0
            
            # Safe snapshots (returns 0 if the population died before the snapshot tick)
            ag_snaps  = [t <= length(prog.n_agents) ? prog.n_agents[t] : 0 for t in snapshots]
            div_snaps = [t <= length(prog.genetic_diversity) ? prog.genetic_diversity[t] : 0.0 for t in snapshots]
            
            # Print Machine-Readable Row
            @printf("%d,%.2f,%.2f,%.2f,%.2f,%.4f,%d,%d,%d,%d,%.6f,%s,", 
                    env_id, mc, gm, rt, ei, msd, s, t_final, agents_final, preds_final, div_final, extinct)
            
            print(join([Int(a) for a in ag_snaps], ","))
            print(",")
            println(join([@sprintf("%.6f", d) for d in div_snaps], ","))
        end
    end
end

run_test()