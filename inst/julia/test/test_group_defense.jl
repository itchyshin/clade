# test_group_defense.jl — unit tests for modules/group_defense.jl

@testset "Group defense (group_defense.jl)" begin

    function _rebuild_agent_map!(env)
        fill!(env.agent_map, Int64(0))
        for (i, ag) in enumerate(env.agents)
            ag.alive || continue
            env.agent_map[Int(ag.x), Int(ag.y)] = i
        end
    end

    function _mini_env(n_agents::Int; kwargs...)
        base = Clade.normalize_specs(merge(Dict{String,Any}(
            "n_agents_init" => n_agents,
            "grid_rows" => 12,
            "grid_cols" => 12,
            "n_predators_init" => 0,
            "random_seed" => 42,
        ), Dict{String,Any}(string(k) => v for (k, v) in kwargs)))
        env = Clade.create_environment(base)
        env.n_gd_events = Int32(0)
        env
    end

    @testset "disabled or zero damage is a no-op" begin
        env = _mini_env(2; group_defense = false)
        dmg = Float32[10.0, 5.0]
        orig = copy(dmg)
        Clade.apply_group_defense!(env, dmg)
        @test dmg == orig

        env2 = _mini_env(2; group_defense = true)
        dmg2 = zeros(Float32, 2)
        Clade.apply_group_defense!(env2, dmg2)
        @test dmg2 == zeros(Float32, 2)
        @test env2.n_gd_events == 0
    end

    @testset "Hamilton dilution factor with two Chebyshev neighbours" begin
        strength = 0.3f0
        env = _mini_env(3;
                        group_defense = true,
                        group_defense_strength = strength,
                        group_defense_radius = 2)
        focal, n1, n2 = env.agents[1], env.agents[2], env.agents[3]
        focal.x, focal.y = Int32(6), Int32(6)
        n1.x, n1.y = Int32(6), Int32(7)   # distance 1
        n2.x, n2.y = Int32(7), Int32(6)   # distance 1
        for ag in env.agents
            ag.alive = true
        end
        _rebuild_agent_map!(env)

        dmg = Float32[20.0, 0.0, 0.0]
        n_nearby = 2
        expected_factor = 1.0f0 / (1.0f0 + Float32(n_nearby) * strength)
        Clade.apply_group_defense!(env, dmg)
        @test dmg[1] ≈ 20.0f0 * expected_factor
        @test dmg[2] == 0.0f0
        @test env.n_gd_events == 1
    end

    @testset "isolated focal agent: damage unchanged" begin
        env = _mini_env(1; group_defense = true)
        ag = env.agents[1]
        ag.x, ag.y = Int32(5), Int32(5)
        _rebuild_agent_map!(env)
        dmg = Float32[15.0]
        orig = copy(dmg)
        Clade.apply_group_defense!(env, dmg)
        @test dmg == orig
        @test env.n_gd_events == 0
    end

    @testset "toroidal neighbourhood wraps at grid edge" begin
        rows, cols = 12, 12
        env = _mini_env(2;
                        group_defense = true,
                        group_defense_radius = 1,
                        group_defense_strength = 0.5f0,
                        toroidal = true)
        focal, neigh = env.agents[1], env.agents[2]
        focal.x, focal.y = Int32(1), Int32(1)
        neigh.x, neigh.y = Int32(rows), Int32(1)  # Chebyshev 1 across north wrap
        _rebuild_agent_map!(env)
        dmg = Float32[8.0, 0.0]
        Clade.apply_group_defense!(env, dmg)
        expected = 8.0f0 / (1.0f0 + 0.5f0)  # one neighbour
        @test dmg[1] ≈ expected
        @test env.n_gd_events == 1
    end
end
