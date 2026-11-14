using Clade, Test
rows = [split(s, ',') for s in readlines(ARGS[1])[2:end]]
selected = [rows[1], first(filter(r -> r[12] == "true", rows))]
@testset "saved campaign input replay" begin
    for row in selected
        specs = Dict{String,Any}("random_seed"=>parse(Int,row[7]),
            "max_ticks"=>1000,"n_agents_init"=>50,"n_predators_init"=>0,
            "grass_growth_mode"=>"stochastic")
        for (i,k) in enumerate(("move_cost","grass_max","min_repro_energy","energy_init","mutation_sd"))
            specs[k] = parse(Float64,row[i+1])
        end
        result = Clade.run_clade(specs)
        t = result.t
        @test t == parse(Int,row[8])
        @test result.progress.n_agents[t] == parse(Int,row[9])
        @test result.progress.n_predators[t] == parse(Int,row[10])
        @test abs(result.progress.genetic_diversity[t]-parse(Float64,row[11])) <= 0.00000050001
    end
end
