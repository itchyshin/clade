using Test
using Random
if !isdefined(@__MODULE__, :Clade)
    include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
end
using .Clade

include(joinpath(@__DIR__, "..", "scripts", "sample_env.jl"))

@testset "sample environment campaign" begin
    mktempdir() do dir
        path = joinpath(dir, "out.csv")
        write(path, "do not overwrite")
        @test_throws ArgumentError sample_environments(0, [101], path)
        @test read(path, String) == "do not overwrite"
        @test_throws ArgumentError sample_environments(1, Int[], path)
        @test read(path, String) == "do not overwrite"
        @test_throws ArgumentError sample_environments(1, [-1], path)
        @test_throws ArgumentError sample_environments(1, [101, 101], path)
        @test read(path, String) == "do not overwrite"

        calls = Dict{String,Any}[]
        function fake_run(specs)
            push!(calls, copy(specs))
            rand(100) # simulation must not perturb subsequent design draws
            agents = zeros(Int, 1000); agents[1:49] .= 2
            diversity = zeros(1000); diversity[1:49] .= 0.25
            (t=50, progress=(n_agents=agents, n_predators=zeros(Int, 1000),
                              genetic_diversity=diversity))
        end
        Random.seed!(77)
        sample_environments(2, [101], path; run_simulation=fake_run)
        rows = [split(line, ',') for line in readlines(path)]
        @test length(rows) == 3
        @test length(rows[1]) == 22
        for (row, specs) in zip(rows[2:end], calls)
            @test [parse(Float64, row[i]) for i in 2:6] ==
                  [specs[k] for k in ("move_cost", "grass_max", "min_repro_energy", "energy_init", "mutation_sd")]
            @test row[8:12] == ["50", "0", "0", "0.000000", "true"]
            @test row[13] == "0" && row[18] == "0.000000"
            @test all(==("NA"), row[[14,15,16,17,19,20,21,22]])
        end
        first_design = [row[2:6] for row in rows[2:end]]
        empty!(calls)
        Random.seed!(98)
        sample_environments(2, [101, 102], path; run_simulation=fake_run)
        rows2 = [split(line, ',') for line in readlines(path)]
        @test [rows2[i][2:6] for i in (2, 4)] == first_design
        @test all(rows2[i][2:6] == rows2[i+1][2:6] for i in (2, 4))
    end
end

@testset "real early extinction" begin
    mktempdir() do dir
        path = joinpath(dir, "out.csv")
        function short_lived(specs)
            specs["max_age"] = 1
            Clade.run_clade(specs)
        end
        sample_environments(1, [101], path; run_simulation=short_lived)
        row = split(readlines(path)[2], ',')
        @test parse(Int, row[8]) < 50
        @test row[9] == "0" && row[12] == "true"
        @test all(==("NA"), row[13:22])
    end
end

@testset "grid script include guard" begin
    include(joinpath(@__DIR__, "..", "scripts", "diversity_vald.jl"))
    @test isdefined(@__MODULE__, :diversity_validation)
end
