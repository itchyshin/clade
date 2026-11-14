using Test
@testset "group_defense module: ghost defenders bug (#199)" begin
    specs = Clade.get_default_specs()
    specs["group_defense"] = true
    specs["group_defense_radius"] = 1
    specs["group_defense_strength"] = 0.5
    specs["n_agents_init"] = 2
    specs["n_predators_init"] = 0
    specs["grid_rows"] = 10
    specs["grid_cols"] = 10
    env = Clade.create_environment(specs)
    # Position agent 1 at (5, 5) and keep alive
    env.agents[1].x = Int32(5)
    env.agents[1].y = Int32(5)
    env.agents[1].alive = true
    env.agent_map .= 0
    env.agent_map[5, 5] = 1
    # Position agent 2 at (5, 6) as a dead ghost
    env.agents[2].x = Int32(5)
    env.agents[2].y = Int32(6)
    env.agents[2].alive = false
    env.agent_map[5, 6] = 2
    # Deal 10 damage to the focal agent (ID 1)
    damage = [10.0f0, 0.0f0]
    Clade.apply_group_defense!(env, damage)
    # Assert damage is unchanged because the only neighbour was a ghost
    @test damage[1] == 10.0f0
    @test env.n_gd_events == 0
    # Now test a dead focal agent doesn't receive damage reduction
    env.agents[1].alive = false
    env.agents[2].alive = true # Make neighbour alive so reduction *would* trigger if focal was alive
    damage = [10.0f0, 0.0f0]
    Clade.apply_group_defense!(env, damage)
    @test damage[1] == 10.0f0
    @test env.n_gd_events == 0
end
