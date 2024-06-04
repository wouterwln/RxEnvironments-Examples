@testitem "max_running_angular_turn" begin
    using FootballSimulation

    import FootballSimulation: max_running_angular_turn
    # Test that the function is monotonic and bounded with extremes at 0 and pi
    @test max_running_angular_turn(0.0, 30.0, 0) ≈ π
    @test max_running_angular_turn(0.0, 30.0, 100) ≈ π
    @test max_running_angular_turn(30.0, 30.0, 0) == 0.0
    @test max_running_angular_turn(30.0, 30.0, 100) == 0.0
    for speed = 0.0:1.0:30.0
        for agility = 0:100
            @test 0 <= max_running_angular_turn(speed, 30.0, agility) <= pi
            @test max_running_angular_turn(speed, 30.0, agility) >=
                  max_running_angular_turn(speed + 0.01, 30.0, agility)
            @test max_running_angular_turn(speed, 30.0, agility) <=
                  max_running_angular_turn(speed, 30.0, agility + 1)
        end
    end
end

@testitem "max_sprint_speed" begin
    using FootballSimulation

    import FootballSimulation: max_sprint_speed

    for i = 1:98
        @test max_sprint_speed(i) < max_sprint_speed(i + 1)
        @test 6 < max_sprint_speed(i) < 10.4
    end
end


@testitem "running_acceleration" begin
    using FootballSimulation

    import FootballSimulation: running_acceleration, player

    virgil = player("Virgil van Dijk")
    stats = FootballSimulation.stats(virgil)
    acc = FootballSimulation.acceleration(stats)
    max_sprint_speed = FootballSimulation.max_sprint_speed(stats)

    @test running_acceleration(0.0, acc, max_sprint_speed) > 5
    @test running_acceleration(max_sprint_speed, acc, max_sprint_speed) == 0.0
end

@testitem "directional_intensity" begin
    using FootballSimulation, ForwardDiff

    import FootballSimulation: directional_intensity
    for v = 1:10
        @test directional_intensity(0.0, v) == 1.0

        #Monotone decreasing on (0, 1.823)
        for θ = 0:0.1:1.823
            @test ForwardDiff.derivative(θ -> directional_intensity(θ, v), θ) <= 0
        end
        #Monotone increasing on (1.823, pi)
        for θ = 1.824:0.1:π
            @test ForwardDiff.derivative(θ -> directional_intensity(θ, v), θ) >= 0
        end

        #Monotone decreasing on (-pi, -1.823)
        for θ = -π:-0.1:-1.823
            @test ForwardDiff.derivative(θ -> directional_intensity(θ, v), θ) <= 0
        end

        #Monotone increasing on (-1.823, 0)
        for θ = -1.823:0.1:0
            @test ForwardDiff.derivative(θ -> directional_intensity(θ, v), θ) >= 0
        end
        #periodic in θ with period 2π
        for θ = -π:0.1:π
            @test directional_intensity(θ, v) ≈ directional_intensity(θ + 2π, v)
        end
    end

end

@testitem "running_cartesian_acceleration" begin
    using FootballSimulation

    import FootballSimulation: running_cartesian_acceleration, player, set_run_action!

    virgil = player("Virgil van Dijk")
    set_run_action!(virgil, [1.0, 0])
    @test running_cartesian_acceleration(virgil, 0.0, 0.0, 0.0) >= [1, 0]
end

@testitem "delta_orientation" begin
    using FootballSimulation

    import FootballSimulation: delta_orientation, player, set_turn_action!, set_orientation!
end


@testitem "desired_delta_orientation" begin
    using FootballSimulation

    import FootballSimulation: desired_delta_orientation

    @test desired_delta_orientation(0.0, 0.0) == 0.0
    @test desired_delta_orientation(0.0, 1.0) == -1.0
    @test desired_delta_orientation(0.0, -1.0) == 1.0

    @test desired_delta_orientation(π, 0.0) ≈ π
    @test desired_delta_orientation(π, 1.0) ≈ π - 1.0

end
