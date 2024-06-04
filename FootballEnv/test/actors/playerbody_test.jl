@testitem "PlayerTrajectory" begin
    using FootballSimulation
    import FootballSimulation: PlayerTrajectory, should_recompute, elapsed_time

    trajectory = PlayerTrajectory(nothing, 0.0, 0.0, true)
    @test should_recompute(trajectory)
    @test elapsed_time(trajectory) === 0.0
end

@testitem "PlayerState" begin
    using FootballSimulation
    import FootballSimulation: PlayerState, position, momentum

    state = PlayerState(zeros(3), zeros(3), 0.0)
    @test position(state) == zeros(3)
    @test momentum(state) == zeros(3)
end

@testitem "PlayerBody" begin
    using FootballSimulation
    import FootballSimulation:
        player, position, momentum, PlayerID, PlayerStats, PlayerState, LeftFoot

    body = player("Virgil van Dijk")

    @test position(body) == zeros(3)
    @test momentum(body) == zeros(3)

    body = player("Virgil van Dijk"; position = [10.0, 0.0, 0.0])

    @test position(body) == [10.0, 0.0, 0.0]
    @test momentum(body) == zeros(3)
end

@testitem "update!" begin
    using FootballSimulation
    using RxEnvironments
    using StaticArrays
    import FootballSimulation: player, update!, position, momentum, recompute_trajectory!

    world = FootballSimulation.create_world()
    body = player("Virgil van Dijk")
    FootballSimulation.add_player!(world, body, FootballSimulation.EmptyAgent())

    update!(body, RxEnvironments.decorated(world), 0.1)

    @test position(body) == zeros(3)
    @test momentum(body) == zeros(3)

    FootballSimulation.set_run_action!(body, [1.0, 1.0])
    recompute_trajectory!(body)

    update!(body, RxEnvironments.decorated(world), 0.1)

    @test position(body) != zeros(3)
    @test momentum(body) != zeros(3)
end

@testitem "update_position!" begin
    using FootballSimulation, RxEnvironments
    import FootballSimulation:
        player, update_position!, position, momentum, recompute_trajectory!

    body = player("Virgil van Dijk")
    recompute_trajectory!(body)

    update_position!(body, 0.1)

    @test position(body) == zeros(3)
    @test momentum(body) == zeros(3)

    FootballSimulation.set_run_action!(body, [1.0, 1.0])
    recompute_trajectory!(body)

    update_position!(body, 0.1)

    @test position(body) != zeros(3)
    @test momentum(body) != zeros(3)
end

@testitem "recompute_trajectory!" begin
    using FootballSimulation
    using StaticArrays

    import FootballSimulation: player, recompute_trajectory!, trajectory, peek

    body = player("Virgil van Dijk")
    recompute_trajectory!(body)

    @test peek(trajectory(body), 1.0) == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    FootballSimulation.set_run_action!(body, SA[1.0, 1.0])
    recompute_trajectory!(body)
    @test peek(trajectory(body), 1.0) != [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
end


@testitem "set_turn_action!" begin
    using FootballSimulation

    import FootballSimulation: player, set_turn_action!, turn_action, set_orientation!

    body = player("Virgil van Dijk")
    set_turn_action!(body, 1.0)
    @test turn_action(body) ≈ 1.0

    set_orientation!(body, 1.0)
    set_turn_action!(body, 1.0)
    @test turn_action(body) ≈ 2.0

    set_orientation!(body, 2.0)
    set_turn_action!(body, -1.0)
    @test turn_action(body) ≈ 1.0

    set_turn_action!(body, π)
    @test turn_action(body) ≈ π + 2

    set_orientation!(body, π + 2.0)
    set_turn_action!(body, π)
    @test turn_action(body) ≈ 2.0
end

@testitem "set_run_action!" begin
    using FootballSimulation
    using StaticArrays
    using CoordinateTransformations

    import FootballSimulation: player, set_run_action!, run_action, set_orientation!

    body = player("Virgil van Dijk")
    set_run_action!(body, SA[1.0, 1.0])
    @test run_action(body) ≈ Polar(1, 1)

    set_orientation!(body, π)
    set_run_action!(body, SA[1.0, 1.0])
    @test run_action(body) ≈ Polar(1.0, π + 1.0)

    set_orientation!(body, π + 2.0)
    set_run_action!(body, SA[1.0, π])
    @test run_action(body) ≈ Polar(1.0, 2.0)
end
