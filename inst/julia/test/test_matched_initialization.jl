using Test

if !isdefined(Main, :Clade)
    include(joinpath(@__DIR__, "..", "src", "Clade.jl"))
end

function _matched_founder_signature(env)
    (
        grass = copy(env.grass),
        agent_map = copy(env.agent_map),
        agents = [(
            id = ag.id,
            x = ag.x,
            y = ag.y,
            energy = ag.energy,
            age = ag.age,
            genome = (
                copy(ag.genome.maternal_weights),
                copy(ag.genome.paternal_weights),
                copy(ag.genome.maternal_traits),
                copy(ag.genome.paternal_traits),
            ),
            brain = Clade.flatten(ag.brain),
            mutation_sd = ag.mutation_sd,
        ) for ag in env.agents],
    )
end

@testset "Default run_clade delegates with canonical initialization" begin
    for seed in 101:105
        specs = Clade.get_default_specs()
        specs["random_seed"] = seed
        specs["max_ticks"] = 3
        specs["n_agents_init"] = 5
        specs["grid_rows"] = 10
        specs["grid_cols"] = 10
        specs["min_repro_energy"] = 10_000.0

        public_result = Clade.run_clade(specs)
        private_result = Clade._run_clade(specs, Clade.create_environment)

        @test isequal(public_result.progress, private_result.progress)
        @test isequal(public_result.agents, private_result.agents)
        @test isequal(public_result.sensory_inputs, private_result.sensory_inputs)
    end
end

@testset "Custom initializer matches founders then restores treatment specs" begin
    treatment = Clade.get_default_specs()
    treatment["random_seed"] = 211
    treatment["max_ticks"] = 3
    treatment["n_agents_init"] = 5
    treatment["grid_rows"] = 10
    treatment["grid_cols"] = 10
    treatment["min_repro_energy"] = 10_000.0
    treatment["mutation_sd"] = 0.5
    fixed_founder_sd = 0.01

    fixed_specs = Clade.normalize_specs(treatment)
    fixed_specs["mutation_sd"] = fixed_founder_sd
    expected_founders = _matched_founder_signature(Clade.create_environment(fixed_specs))
    treatment_founders = _matched_founder_signature(
        Clade.create_environment(Clade.normalize_specs(treatment)))

    captured_founders = Ref{Any}(nothing)
    seen_mutation_sd = Ref{Any}(nothing)
    initializer = function (specs)
        founder_specs = copy(specs)
        founder_specs["mutation_sd"] = fixed_founder_sd
        env = Clade.create_environment(founder_specs)
        captured_founders[] = _matched_founder_signature(env)
        env.specs = specs
        seen_mutation_sd[] = env.specs["mutation_sd"]
        env
    end

    result = Clade._run_clade(treatment, initializer)

    @test isequal(captured_founders[], expected_founders)
    @test !isequal(captured_founders[], treatment_founders)
    @test seen_mutation_sd[] == treatment["mutation_sd"]
    @test result.t == treatment["max_ticks"]
end
