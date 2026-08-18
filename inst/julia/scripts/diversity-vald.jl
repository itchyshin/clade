using Statistics
using Printf
using Clade

# 1. Parameter Grid (Defining the "Harshness Mechanism")
# We proxy "harshness" through two axes: metabolic movement cost and resource (grass) abundance.
move_costs  = [0.0, 5.0, 10.0]  # Higher = harsher environment
grass_maxes = [5.0, 10.0, 20.0] # Lower = harsher environment

# 2. Fixed Seeds (5 runs per cell)
seeds = [101, 102, 103, 104, 105]

# 3. Outcome Definition
# The genetic_diversity metric at the final tick of the simulation.
function get_outcome(res)
    # Use dot notation for NamedTuples
    div_array = res.progress.genetic_diversity
    return length(div_array) > 0 ? div_array[end] : 0.0
end

println("Runs per cell: 5 (Seeds: $seeds)")
println("---------------------------------------------------------")
@printf("%-12s | %-12s | %-20s\n", "move_cost", "grass_max", "GenDiv (Mean ± SE)")
println("---------------------------------------------------------")

# Run the Grid
for mc in move_costs
    for gm in grass_maxes
        cell_results = Float64[]
        
        for s in seeds
            specs = Dict{String, Any}(
                "random_seed"   => s,
                "max_ticks"     => 100, 
                "n_agents_init" => 50,
                "move_cost"     => mc,
                "grass_max"     => gm
            )
            
            res = Clade.run_clade(specs)
            push!(cell_results, get_outcome(res))
        end
        
        # 4. Calculate Mean ± SE
        cell_mean = mean(cell_results)
        cell_se   = std(cell_results) / sqrt(length(cell_results))
        
        @printf("%-12.1f | %-12.1f | %.4f ± %.4f\n", mc, gm, cell_mean, cell_se)
    end
end
println("Validation complete.")