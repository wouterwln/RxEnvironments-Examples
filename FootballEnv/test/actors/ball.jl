module test_ball

using Test
using TestSetExtensions
using Quaternions
using Rotations
using StaticArrays
using LinearAlgebra
using Static

@testset ExtendedTestSet "Ball" begin

    @testset "set_position!" begin
        import FootballSimulation: Ball, set_position!
        ball = Ball()
        set_position!(ball, (1, 2, 3))
        @test ball.state.position == [1, 2, 3]

        set_position!(ball, (0, 0, 0))
        @test ball.state.position == [0, 0, 0]

        set_position!(ball, (-1, -2, -3))
        @test ball.state.position == [-1, -2, -3]
    end

    @testset "set_momentum!" begin
        import FootballSimulation: Ball, set_momentum!
        ball = Ball()
        set_momentum!(ball, (1, 2, 3))
        @test ball.state.momentum == [1, 2, 3]
    end

    @testset "set_rotation!" begin
        import FootballSimulation: Ball, set_rotation!
        ball = Ball()
        set_rotation!(ball, Quaternion(1, 2, 3, 4))
        @test ball.state.rotation == Quaternion(1, 2, 3, 4)

        set_rotation!(ball, Quaternion(0, 0, 0, 0))
        @test ball.state.rotation == Quaternion(0, 0, 0, 0)

        set_rotation!(ball, Quaternion(-1, -2, -3, -4))
        @test ball.state.rotation == Quaternion(-1, -2, -3, -4)
    end


    @testset "position" begin
        import FootballSimulation: Ball, position, set_position!
        ball = Ball()
        @test position(ball) == [0, 0, 0.11]

        set_position!(ball, (1, 2, 3))
        @test position(ball) == [1, 2, 3]

        set_position!(ball, (0, 0, 0))
        @test position(ball) == [0, 0, 0]

        set_position!(ball, (-1, -2, -3))
        @test position(ball) == [-1, -2, -3]
    end

    @testset "momentum" begin
        import FootballSimulation: Ball, momentum, set_momentum!
        ball = Ball()
        @test momentum(ball) == [0, 0, 0]

        set_momentum!(ball, (1, 2, 3))
        @test momentum(ball) == [1, 2, 3]

        set_momentum!(ball, (0, 0, 0))
        @test momentum(ball) == [0, 0, 0]
    end

    @testset "rotation" begin
        import FootballSimulation: Ball, rotation, set_rotation!
        ball = Ball()
        @test rotation(ball) == Quaternion(1, 0, 0, 0)

        set_rotation!(ball, Quaternion(1, 2, 3, 4))
        @test rotation(ball) == Quaternion(1, 2, 3, 4)

        set_rotation!(ball, Quaternion(0, 0, 0, 0))
        @test rotation(ball) == Quaternion(0, 0, 0, 0)

        set_rotation!(ball, Quaternion(-1, -2, -3, -4))
        @test rotation(ball) == Quaternion(-1, -2, -3, -4)
    end

    @testset "end_of_trajectory" begin
        import FootballSimulation:
            Ball, end_of_trajectory, AirTrajectory, TrajectoryEnd, set_trajectory!
        ball = Ball()
        @test end_of_trajectory(ball, 0.1) == true
        trajectory = AirTrajectory(0.1, TrajectoryEnd(0.05, False(), [0, 0, 1], 0.1), 0)
        set_trajectory!(ball, trajectory)
        @test end_of_trajectory(ball, 0.1) == true
        @test end_of_trajectory(ball, 0.01) == false
    end

    @testset "calculate_air_trajectory!" begin
        import FootballSimulation: Ball, calculate_air_trajectory!, trajectory, time_bounce
        ball = Ball((0.0, 0.0, 10.0))

        # Test 1: falling ball that touches ground in ≈ 1.48 seconds
        calculate_air_trajectory!(ball)
        @test time_bounce(ball) ≈ 1.4804447
    end

    @testset "calculate_rolling_trajectory!" begin
        import FootballSimulation: Ball, calculate_rolling_trajectory!

        # Test 1: rolling ball
        ball = Ball((0.0, 0.0, 0.11), (10.0, 10.0, 0.0))
        calculate_rolling_trajectory!(ball)
        @test position(ball)[3] ≈ 0.11
        @test trajectory(ball).trajectory_end.time == 7
    end

    @testset "bounce!" begin
        import FootballSimulation: Ball, World, bounce!

        # Test 1: falling ball that touches ground in ≈ 1.48 seconds
        ball = Ball((0.0, 0.0, 0.1101), (0.0, 0.0, -1.0))
        calculate_air_trajectory!(ball)
        world = World([ball])
        bounce!(ball, trajectory(ball))
        @test momentum(ball)[3] > 0.0
    end

    @testset "rolls" begin
        import FootballSimulation: Ball, rolls
        ball = Ball((0.0, 0.0, 1.0))
        @test rolls(ball) == false
        ball = Ball((0.0, 0.0, 0.11))
        @test rolls(ball) == true
        ball = Ball((0.0, 0.0, 0.11), (0.0, 0.0, 1.0))
        @test rolls(ball) == false
    end

    @testset "move_to_end!" begin
        import FootballSimulation: Ball, move_to_end!

        # Test 1: falling ball that touches ground in ≈ 0.43 seconds

        ball = Ball((0.0, 0.0, 1.0))
        calculate_air_trajectory!(ball)
        @test move_to_end!(ball, trajectory(ball), 0.5) ≈ 0.072358791
        @test isapprox(position(ball)[3], 0.11; atol = 1e-4)

        # Test 2: rolling ball
        ball = Ball((0.0, 0.0, 0.11), (10.0, 10.0, 0.0))
        calculate_rolling_trajectory!(ball)
        @test move_to_end!(ball, trajectory(ball), 7.1) ≈ 0.1
    end

    @testset "update!" begin
        import FootballSimulation: Ball, update!, World, position
        # Test 1: falling ball
        ball = Ball((0.0, 0.0, 100.0))
        world = World([ball])
        for Δt = 0.1:0.1:1.0
            ball = Ball((0.0, 0.0, 100.0))
            for t = Δt:Δt:5.0
                update!(ball, world, Δt)
                @test all(position(ball) .≈ position(trajectory(ball), t))
            end
        end
        # Test 2: rolling ball keeps rolling.
        ball = Ball((0.0, 0.0, 0.11), (10.0, 10.0, 0.0))
        world = World([ball])
        previous_position = position(ball)
        for t = 0:0.1:10
            update!(ball, world, 0.1)
            @test all(previous_position .<= position(ball))
            previous_position = position(ball)
        end
    end




end

end
