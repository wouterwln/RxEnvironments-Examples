using CoordinateTransformations
using LinearAlgebra

function directional_intensity(action_direction::Real, current_velocity::Real)
    current_velocity = abs(current_velocity)
    return (
        0.5 * (cos(action_direction / 2)^2 + cos(action_direction)^2)
    )^(1 + current_velocity)
end

function running_acceleration(
    current_velocity::Real,
    acceleration_stat::Real,
    max_sprint_speed::Real,
)
    relative_current_speed = current_velocity / max_sprint_speed
    relative_current_speed = (1 - sqrt(relative_current_speed))
    normalized_acc = 1.0 / (1.0 + exp(-(acceleration_stat / 50)))
    player_acceleration = 13 * normalized_acc * relative_current_speed
    return player_acceleration
end

function running_cartesian_acceleration(
    player,
    current_orientation::Real,
    current_vx::Real,
    current_vy::Real,
)
    movement_action = run_action(player)
    current_movement = PolarFromCartesian()([current_vx, current_vy])

    current_velocity = norm(current_movement)
    available_intensity = directional_intensity(
        angle(movement_action) - current_orientation,
        current_velocity,
    )

    movement = Polar(
        available_intensity *
        norm(movement_action) *
        running_acceleration(
            current_velocity,
            acceleration(stats(player)),
            max_sprint_speed(stats(player)),
        ),
        angle(movement_action),
    )

    cartesian_action = CartesianFromPolar()(movement)
    return cartesian_action
end

function running_cartesian_constant_deceleration(
    player,
    currrent_vx::Real,
    current_vy::Real,
)
    α = agility(stats(player))
    return SA[(-α*currrent_vx)/150, (-α*current_vy)/150]
end

"""
    max_running_angular_turn(ratio::Real, agility::Int)

Return the maximal change in direction a player can make given his agility and current speed as a ratio of his maximum sprint speed.
"""
function max_running_angular_turn(
    current_velocity::Real,
    max_sprint_speed::Real,
    agility::Int,
)
    ## parameters to to control direction, speed relation
    λ = 20                              ## λ: constant (steepness)
    a = 0.20 + 0.15 * agility / 100     ## a: agility influence (offset)

    ratio = current_velocity / max_sprint_speed
    ## ϕ: maximal Δdirection
    if ratio < 0.01
        ϕ = convert(Float64, pi)
    elseif ratio > 0.99
        ϕ = 0.0
    else
        ϕ = (1 - 1 / (1 + exp(-λ * (ratio - a)))) * π
    end

    return ϕ
end

function delta_orientation(player, cartesian_momentum, current_orientation)
    desired_direction = turn_action(player)

    max_turn = max_running_angular_turn(
        norm(cartesian_momentum),
        max_sprint_speed(stats(player)),
        agility(stats(player)),
    )
    Δorientation = desired_delta_orientation(desired_direction, current_orientation)

    if abs(Δorientation) > max_turn
        Δorientation = sign(Δorientation) * max_turn
    end

    return convert(Float64, Δorientation)::Float64
end

desired_delta_orientation(desired_direction::Real, current_orientation::Real) =
    mod2pi(convert(Float64, desired_direction - current_orientation + π)) - π

"""
    player_running_dynamics(u, p, t)

Describe the dynamics of a player running. The state vector `u` is 
interpreted as follows:

    u[1:3] = cartesian position
    u[4:5] = cartesian momentum
    u[6]   = angular momentum in z axis (0)
    u[7]   = current orientation
    u[8]   = change in orientation
"""
function player_running_dynamics(u, player, t)
    cartesian_momentum = view(u, 4:5)
    polar_momentum = Polar(cartesian_momentum[1], cartesian_momentum[2])

    current_orientation = u[7]
    dx, dy =
        running_cartesian_acceleration(
            player,
            current_orientation,
            cartesian_momentum[1],
            cartesian_momentum[2],
        ) + running_cartesian_constant_deceleration(
            player,
            cartesian_momentum[1],
            cartesian_momentum[2],
        )

    Δorientation = delta_orientation(player, cartesian_momentum, current_orientation)
    return SA[
        cartesian_momentum[1],
        cartesian_momentum[2],
        0.0,
        dx,
        dy,
        0.0,
        Δorientation,
    ]::SVector{7,Float64}
end
