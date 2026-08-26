using Statistics
using Printf
using Clade

move_costs  = [0.0, 5.0, 10.0]
grass_maxes = [5.0, 10.0, 20.0]
seeds = [101, 102, 103, 104, 105]
max_t = 100

# Store results for the summary table
results = []

println("move_cost,grass_max,seed,genetic_diversity,final_tick,final_agents,final_predators")

for mc in move_costs
    for gm in grass_maxes
        for s in seeds
            specs = Dict{String, Any}(
                "random_seed"   => s,
                "max_ticks"     => max_t, 
                "n_agents_init" => 50,
                "n_predators_init" => 0, 
                "move_cost"     => mc,
                "grass_max"     => gm
            )
            
            res = Clade.run_clade(specs)
            
            # Extract requested observables
            div = length(res.progress.genetic_diversity) > 0 ? res.progress.genetic_diversity[end] : 0.0
            t_final = res.t
            agents_final = length(res.progress.n_agents) > 0 ? res.progress.n_agents[end] : 0
            preds_final  = length(res.progress.n_predators) > 0 ? res.progress.n_predators[end] : 0
            
            push!(results, (mc=mc, gm=gm, seed=s, div=div, t=t_final, agents=agents_final, preds=preds_final))
            
            # Print the machine-readable row
            @printf("%.1f,%.1f,%d,%.6f,%d,%d,%d\n", mc, gm, s, div, t_final, agents_final, preds_final)
        end
    end
end

@printf("%-10s | %-10s | %-18s | %-14s | %-12s\n", "move_cost", "grass_max", "GenDiv (Mean ± SE)", "Surviving Runs", "Mean Agents")
println("-"^75)

for mc in move_costs
    for gm in grass_maxes
        # Filter results for this specific cell
        cell_data = filter(r -> r.mc == mc && r.gm == gm, results)
        
        divs = [r.div for r in cell_data]
        agents = [r.agents for r in cell_data]
        
        cell_mean = mean(divs)
        cell_se   = std(divs) / sqrt(length(divs))
        
        # A run is considered to have "survived" if agents remain at the final tick
        survivors = sum(a > 0 for a in agents)
        mean_agents = mean(agents)
        
        @printf("%-10.1f | %-10.1f | %.4f ± %.4f | %d/%d            | %-10.1f\n", 
                mc, gm, cell_mean, cell_se, survivors, length(cell_data), mean_agents)
    end
end
println("-"^75)
