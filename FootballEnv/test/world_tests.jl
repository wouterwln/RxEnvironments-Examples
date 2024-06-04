@testitem "World creation" begin
    using FootballSimulation
    import FootballSimulation: World, create_world
    using RxEnvironments

    @test World() isa World

    @test RxEnvironments.decorated(create_world()) isa World
end

@testitem "add ball to world" begin
    using FootballSimulation
    import FootballSimulation: create_world, add_ball!, Ball, n_players, n_balls

    world = create_world()
    ball = add_ball!(world, Ball())
    @test ball isa Ball
    @test n_balls(world) == 1
    @test n_players(world) == 0

end

@testitem "add player to world" begin
    using FootballSimulation
    import FootballSimulation: create_world, add_player!, EmptyAgent, n_players
    using RxEnvironments

    world = create_world()
    agent = EmptyAgent()
    player = add_player!(world, FootballSimulation.player("Virgil van Dijk"), agent)
    @test RxEnvironments.decorated(player) === agent
    @test n_players(world) == 1

end

@testitem "timing in discrete world" begin
    using FootballSimulation
    import FootballSimulation:
        create_discrete_world, add_player!, add_ball!, EmptyAgent, position
    using RxEnvironments
    import RxEnvironments: decorated

    world = create_discrete_world()

    @test time(world) == 0.0
    agent = EmptyAgent()
    player = FootballSimulation.player("Virgil van Dijk")
    rxplayer = add_player!(world, player, agent)
    @test position(player) == [0, 0, 0]
    send!(world, rxplayer, FootballSimulation.PlayerRunAction(1.0, 0.0))
    @test time(world) == RxEnvironments.time_interval(decorated(world))
    FootballSimulation.recompute_trajectory!(player)
    send!(world, rxplayer, nothing)
    @test time(world) == 2 * RxEnvironments.time_interval(decorated(world))
end
