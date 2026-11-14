using Test, Random
if !isdefined(@__MODULE__, :Clade)
    include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
end
include(joinpath(@__DIR__, "..", "scripts", "matched_founders.jl"))

@testset "Matched founders and mutation intervention" begin
    specs = Dict{String,Any}("random_seed"=>42,"max_ticks"=>4,
        "n_agents_init"=>5,"grid_rows"=>10,"grid_cols"=>10,
        "mutation_sd"=>0.05,"bnn_sigma_source"=>"fixed")
    standard = Clade.run_clade(specs)
    matched = MatchedFounders.trial(specs, 0.05)
    @test isequal(standard, matched.result)
    hashes = String[]
    initial_d = Float64[]
    for mutation in (0.0, 0.05, 0.2)
        s = copy(specs); s["mutation_sd"] = mutation
        r = MatchedFounders.trial(s, 0.2)
        push!(hashes, r.initial.fingerprint)
        push!(initial_d, r.initial.diversity)
        @test r.env.specs["mutation_sd"] == Float32(mutation)
        @test all(a.mutation_sd == Float32(0.05) for a in r.env.agents)
    end
    @test all(==(first(hashes)), hashes)
    @test all(==(first(initial_d)), initial_d)
    r05 = MatchedFounders.trial(specs, 0.05)
    r20 = MatchedFounders.trial(specs, 0.2)
    @test r20.initial.diversity ≈ 4r05.initial.diversity rtol=1e-6
    @test r05.initial.mean_sigma == 0.5
    @test r20.initial.mean_sigma == 0.5
    a = Dict("b"=>2,"a"=>1); b = Dict("a"=>1,"b"=>2)
    @test MatchedFounders.digest(a) == MatchedFounders.digest(b)
    state = copy(r05.env.rng)
    MatchedFounders.exact_diversity(r05.env.agents)
    @test rand(state) == rand(r05.env.rng)
    @test isnan(MatchedFounders.exact_diversity(r05.env.agents[1:1]))
    @test MatchedFounders.exact_diversity(r05.env.agents[1:2]) ==
          Float64(Clade.genome_distance(r05.env.agents[1].genome,r05.env.agents[2].genome))
    @test_throws ArgumentError MatchedFounders.trial(specs, -0.1)
end

@testset "Zero variation control and positive offspring mutation" begin
    for mutation in (0.0, 0.2)
        s = Dict{String,Any}("random_seed"=>31,"max_ticks"=>40,
            "n_agents_init"=>10,"grid_rows"=>10,"grid_cols"=>10,
            "energy_init"=>100.0,"min_repro_energy"=>20.0,
            "move_cost"=>0.1,"grass_rate"=>1.0,"grass_max"=>20.0,
            "mutation_sd"=>mutation,"bnn_sigma_source"=>"fixed")
        r = MatchedFounders.trial(s, 0.0)
        @test r.initial.diversity == 0
        @test sum(r.env.progress["n_births"]) > 0
        @test length(r.env.agents) >= 2
        if mutation == 0
            @test all(iszero, r.env.progress["genetic_diversity"])
            @test MatchedFounders.exact_diversity(r.env.agents) == 0
        else
            @test MatchedFounders.exact_diversity(r.env.agents) > 0
        end
    end
end

@testset "Matched-study output and overwrite guard" begin
    mktempdir() do dir
        @test_throws ArgumentError MatchedFounders.run_study(0, dir)
        @test MatchedFounders.run_study(2, dir; max_ticks=2) == 72
        lines = readlines(joinpath(dir,"runs.csv"))
        @test length(lines) == 73
        @test all(length(split(x,','))==19 for x in lines)
        @test length(readlines(joinpath(dir,"trajectories.csv"))) == 217
        @test_throws ArgumentError MatchedFounders.run_study(1, dir; max_ticks=2)
        @test readlines(joinpath(dir,"runs.csv")) == lines
    end
end
