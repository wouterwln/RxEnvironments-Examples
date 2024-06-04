using Quaternions
using Rotations
using LinearAlgebra
using StaticArrays
using GeometryBasics
using DifferentialEquations
using Static

const T = 7.0

"""
The struct BallProperties contains all the constant information of the ball
"""
struct BallProperties{T}
    radius::T
    mass::T
    bouncing_coefficient::T
    C_air::T
    C_rolling::T
end

radius(properties::BallProperties) = properties.radius
mass(properties::BallProperties) = properties.mass
bouncing_coefficient(properties::BallProperties) = properties.bouncing_coefficient
air_resistance_coefficient(properties::BallProperties) = properties.C_air
rolling_resistance_coefficient(properties::BallProperties) = properties.C_rolling

mutable struct BallTrajectoryEnd
    time::Real
    bounces::Any
    normal::Vector
    resistance_coefficient::Real
end

mutable struct RollingTrajectory <: Trajectory
    solution::Any
    trajectory_end::BallTrajectoryEnd
    elapsed_time::Real
end

mutable struct AirTrajectory <: Trajectory
    solution::Any
    trajectory_end::BallTrajectoryEnd
    elapsed_time::Real
end

position(trajectory::Nothing, time::Real) = error("No trajectory calculated")
momentum(trajectory::Nothing, time::Real) = error("No trajectory calculated")
bounces(trajectory::Trajectory) = trajectory.trajectory_end.bounces
end_time(trajectory::Trajectory) = trajectory.trajectory_end.time
normal_vector(trajectory::Trajectory) = trajectory.trajectory_end.normal
resistance_coefficient(trajectory::Trajectory) =
    trajectory.trajectory_end.resistance_coefficient

"""
The mutable struct BallState contains all the information about the current state of the ball that are subject to change as the simulation progresses. 
"""
mutable struct BallState{T<:Real}
    position::SVector{3,T}
    momentum::SVector{3,T}
    rotation::Quaternion{T}
    calculate_trajectory::Bool
    trajectory::Any
end

position(state::BallState) = state.position
momentum(state::BallState) = state.momentum
rotation(state::BallState) = state.rotation
trajectory(state::BallState) = state.trajectory

set_position!(state::BallState, position::SVector{3,T} where {T<:Real}) =
    state.position = position
set_momentum!(state::BallState, momentum::SVector{3,T} where {T<:Real}) =
    state.momentum = momentum
set_rotation!(state::BallState, rotation::Quaternion) = state.rotation = rotation

"""
The Ball struct contains all the information about the ball. It contains the following fields:

- `properties`: A BallProperties struct containing all constant information of the ball
- `state`: A BallState struct containing all the information about the current state of the ball
"""
struct Ball <: Actor
    properties::BallProperties{Float64}
    state::BallState{Float64}
end

state(ball::Ball) = ball.state
properties(ball::Ball) = ball.properties

position(ball::Ball) = position(state(ball))
momentum(ball::Ball) = momentum(state(ball))
rotation(ball::Ball) = rotation(state(ball))
trajectory(ball::Ball) = trajectory(state(ball))
air_resistance_coefficient(ball::Ball) = air_resistance_coefficient(properties(ball))
rolling_resistance_coefficient(ball::Ball) =
    rolling_resistance_coefficient(properties(ball))
bouncing_coefficient(ball::Ball) = bouncing_coefficient(properties(ball))
radius(ball::Ball) = radius(properties(ball))
mass(ball::Ball) = mass(properties(ball))
time_bounce(ball::Ball) = end_time(trajectory(ball))
is_touched(ball::Ball) = state(ball).calculate_trajectory

end_of_trajectory(ball::Ball, Δt) = end_of_trajectory(trajectory(ball), Δt)

set_position!(ball::Ball, position::SVector{3,T} where {T<:Real}) =
    set_position!(state(ball), position)
set_position!(ball::Ball, position::Vector{T} where {T<:Real}) =
    set_position!(ball, SVector{3}(position))

set_momentum!(ball::Ball, momentum::SVector{3,T} where {T<:Real}) =
    set_momentum!(state(ball), momentum)
set_momentum!(ball::Ball, momentum::Vector{T} where {T<:Real}) =
    set_momentum!(ball, SVector{3}(momentum))

set_rotation!(ball::Ball, rotation::Quaternion) = set_rotation!(state(ball), rotation)

set_trajectory!(ball::Ball, trajectory) = ball.state.trajectory = trajectory

Ball(location::SVector{3,T} where {T<:Real}, momentum::SVector{3,T} where {T<:Real}) = Ball(
    BallProperties(0.11, 0.430, 0.9, 0.47, 1.0),
    BallState(location, momentum, Quaternion(1.0, 0.0, 0.0, 0.0), true, nothing),
)

Ball(location::SVector{3,T} where {T<:Real}) = Ball(location, SA[0.0, 0.0, 0.0])

Ball() = Ball(SA[0.0, 0.0, 0.11], SA[0.0, 0.0, 0.0])

"""
Sets the rotation of the ball to the amount of radians per second in the x, y and z direction.
"""
function set_rotation!(ball::Ball, x::Real, y::Real, z::Real)
    ball.state.rotation =
        Quaternion(Rotations.params(QuatRotation(RotX(x) * RotY(y) * RotZ(z)))...)
end

function kick!(ball::Ball, new_momentum::Vector, new_rotation::Quaternion)
    old_momentum = momentum(ball)
    set_momentum!(ball, new_momentum + old_momentum)
    set_rotation!(ball, new_rotation)
    ball.state.calculate_trajectory = true
end

function air_resistance(ball::Ball, momentum::AbstractArray{T} where {T<:Real})
    if norm(momentum) == 0
        return SA[0.0, 0.0, 0.0]
    end
    resistance_direction = -(SVector{3}(normalize(momentum)))
    return air_resistance(
        air_resistance_coefficient(ball),
        norm(momentum),
        pi * radius(ball)^2,
    ) * resistance_direction
end

function magnus(ball::Ball, momentum::AbstractArray{T} where {T<:Real})
    magnus_direction = GeometryBasics.orthogonal_vector(
        SA[0.0, 0.0, 0.0],
        rotation_axis(QuatRotation(rotation(ball))),
        momentum,
    )
    return magnus(radius(ball), rotation(ball), norm(momentum)) * magnus_direction
end

gravity(ball::Ball) = SA[0.0, 0.0, -gravity(mass(ball))]
net_force_air(ball::Ball, momentum) =
    gravity(ball) + magnus(ball, momentum) + air_resistance(ball, momentum)


function air_dynamics(u, integrator, t) # Differential equation describing the dynamics of the ball
    ball = integrator[1]
    momentum = SVector{3}(view(u, 4:6))
    force = net_force_air(ball, momentum)
    return vcat(momentum, force / mass(ball))
end

function bounce_condition(out, u, t, integrator) # Event when event_f(u,t) == 0
    out[1] = u[3] - radius(integrator.p[1])
end

function set_bounce_time!(integrator, idx)
    ball, trajectory_end = integrator.p
    trajectory_end.time = integrator.t
    trajectory_end.bounces = True()
    trajectory_end.normal = [0, 0, 1]
    trajectory_end.resistance_coefficient = 0.95
end

function calculate_air_trajectory!(ball::Ball)
    set_trajectory!(ball, nothing)
    cb = VectorContinuousCallback(bounce_condition, set_bounce_time!, 1)
    initial_state = vcat(position(ball), momentum(ball))
    tspan = (0.0, T)
    trajectory_end = BallTrajectoryEnd(T, False(), [0, 0, 0], 0.0)
    prob = ODEProblem(air_dynamics, initial_state, tspan, (ball, trajectory_end))
    sol = solve(prob, Tsit5(), callback = cb)
    set_trajectory!(ball, AirTrajectory(sol, trajectory_end, 0.0))
    ball.state.calculate_trajectory = false
end

function rolling_resistance(ball::Ball, momentum)
    if norm(momentum) == 0
        return SA[0.0, 0.0, 0.0]
    end
    resistance_direction = -normalize(momentum)
    return rolling_resistance_coefficient(ball) *
           gravity(mass(ball)) *
           radius(ball) *
           resistance_direction *
           norm(momentum)
end

net_force_rolling(ball::Ball, momentum) =
    air_resistance(ball, momentum) + rolling_resistance(ball, momentum)

function rolling_dynamics(u, ball, t) # Differential equation describing the dynamics of the ball
    momentum = SVector{3}(u[4:6])
    force = net_force_rolling(ball, momentum)
    return vcat(momentum, force / mass(ball))
end

function calculate_rolling_trajectory!(ball::Ball)
    set_trajectory!(ball, nothing)
    initial_state = vcat(position(ball), momentum(ball))
    tspan = (0.0, T)
    trajectory_end = BallTrajectoryEnd(T, False(), [0, 0, 0], 0.0)
    prob = ODEProblem(rolling_dynamics, initial_state, tspan, ball)
    sol = solve(prob, Tsit5())
    set_trajectory!(ball, RollingTrajectory(sol, trajectory_end, 0.0))
    ball.state.calculate_trajectory = false
end


function adjust_momentum_bounce!(ball::Ball, ball_trajectory::Trajectory)
    ball_momentum = momentum(ball)
    nv = normal_vector(ball_trajectory)
    rc = resistance_coefficient(ball_trajectory)
    reflection_vector = ball_momentum - 2 * dot(ball_momentum, nv) * nv
    new_momentum = (reflection_vector * rc) .* (1, 1, bouncing_coefficient(ball))
    set_momentum!(ball, new_momentum)
    return new_momentum
end

function adjust_rotation_bounce!(ball::Ball)
    set_rotation!(ball, 0, 0, 0)
end

bounce!(ball::Ball, t::Trajectory) = bounce!(ball, bounces(t), t)
bounce!(ball::Ball, ::False, t) = nothing

function bounce!(ball::Ball, ::True, ball_trajectory::Trajectory)
    adjust_momentum_bounce!(ball, ball_trajectory)
    adjust_rotation_bounce!(ball)
end

function rolls(ball::Ball)
    return abs(momentum(ball)[3]) < 0.01 && position(ball)[3] ≈ radius(ball)
end

function recompute_trajectory!(ball::Ball)
    if rolls(ball)
        m = momentum(ball)
        set_momentum!(ball, [m[1], m[2], 0.0])
        calculate_rolling_trajectory!(ball)
    else
        calculate_air_trajectory!(ball)
    end
    return trajectory(ball)::Union{RollingTrajectory,AirTrajectory}
end

function move_to_end!(ball::Ball, ball_trajectory::Trajectory, Δt)
    time_left = end_time(ball_trajectory) - elapsed_time(ball_trajectory)
    set_position!(ball, position(ball_trajectory, end_time(ball_trajectory)))
    set_momentum!(ball, momentum(ball_trajectory, end_time(ball_trajectory)))
    return Δt - time_left
end

function update!(ball::Ball, world::World, Δt::Float64)
    if is_touched(ball)
        recompute_trajectory!(ball)
    end
    while end_of_trajectory(trajectory(ball), Δt)
        Δt = move_to_end!(ball, trajectory(ball), Δt)
        bounce!(ball, trajectory(ball))
        recompute_trajectory!(ball)
    end
    advance!(trajectory(ball), Δt)
    set_position!(ball, position(trajectory(ball)))
    set_momentum!(ball, momentum(trajectory(ball)))
end

observe!(ball::Ball, world::World) = nothing #Ball cannot observe anything
act!(actor::Ball, world::World) = nothing # Ball cannot act


function add_ball!(world::RxEnvironments.RxEntity{World}, ball::Ball)
    add_actor!(decorated(world), ball)
    return ball
end
