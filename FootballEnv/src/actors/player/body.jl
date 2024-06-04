using StaticArrays
using Static
using CoordinateTransformations
using DifferentialEquations

import RxEnvironments: decorated, RxEntity

struct PlayerID
    name::String
    team::Symbol
    shirt_number::Int
end

getname(id::PlayerID) = id.name
team(id::PlayerID) = id.team

mutable struct PlayerTrajectory <: Trajectory
    solution::Any
    trajectory_end::Real
    elapsed_time::Real
    recompute::Bool
end

should_recompute(trajectory::PlayerTrajectory) = trajectory.recompute
time_left(trajectory::PlayerTrajectory) =
    trajectory.trajectory_end - trajectory.elapsed_time
position(trajectory::PlayerTrajectory) =
    SVector{3}(trajectory.solution(elapsed_time(trajectory))[1:3])
momentum(trajectory::PlayerTrajectory) =
    SVector{3}(trajectory.solution(elapsed_time(trajectory))[4:6])
orientation(trajectory::PlayerTrajectory) = trajectory.solution(elapsed_time(trajectory))[7]

set_recompute!(trajectory::PlayerTrajectory, recompute::Bool) =
    trajectory.recompute = recompute


PlayerTrajectory() = PlayerTrajectory(nothing, 0.0, 0.0, true)


mutable struct PlayerState
    position::SVector{3,Float64}
    momentum::SVector{3,Float64}
    in_posession::Union{True,False}
    kick_cooldown::Real
    orientation::Real
    run_action::Polar{Float64,Float64}
    turn_action::Real
    trajectory::PlayerTrajectory
end


position(state::PlayerState) = state.position
momentum(state::PlayerState) = state.momentum
orientation(state::PlayerState) = state.orientation

run_action(state::PlayerState) = state.run_action
turn_action(state::PlayerState) = state.turn_action

set_position!(state::PlayerState, position::SVector{3,Float64}) = state.position = position
set_momentum!(state::PlayerState, momentum::SVector{3,Float64}) = state.momentum = momentum
set_orientation!(state::PlayerState, orientation::Real) = state.orientation = orientation

trajectory(state::PlayerState) = state.trajectory
set_trajectory!(state::PlayerState, trajectory::PlayerTrajectory) =
    state.trajectory = trajectory

function set_run_action!(state::PlayerState, run_action::SVector{2,T} where {T<:Real})
    current_orientation = orientation(state)
    absolute_action = mod2pi(run_action[2] + current_orientation)
    state.run_action = Polar(run_action[1], absolute_action)
end

function set_turn_action!(state::PlayerState, turn_action::Real)
    current_orientation = orientation(state)
    absolute_action = mod2pi(turn_action + current_orientation)
    state.turn_action = absolute_action
end

function observable_state(state::PlayerState)
    return vcat(
        position(state),
        momentum(state),
        SVector{1}(orientation(state)),
    )::SVector{7,Float64}
end

PlayerState(position::Vector{Float64}, momentum::Vector{Float64}, orientation::Real) =
    PlayerState(
        position,
        momentum,
        false,
        0.0,
        orientation,
        Polar(0.0, 0.0),
        orientation,
        PlayerTrajectory(),
    )

struct PlayerBody <: Actor
    id::PlayerID
    stats::PlayerStats{Int}
    state::PlayerState
end

getname(body::PlayerBody) = getname(body.id)
team(body::PlayerBody) = team(body.id)

state(body::PlayerBody) = body.state
stats(body::PlayerBody) = body.stats

position(body::PlayerBody) = position(state(body))
momentum(body::PlayerBody) = momentum(state(body))
orientation(body::PlayerBody) = orientation(state(body))

run_action(body::PlayerBody) = run_action(state(body))
turn_action(body::PlayerBody) = turn_action(state(body))

set_position!(body::PlayerBody, position::SVector{3,Float64}) =
    set_position!(state(body), position)
set_momentum!(body::PlayerBody, momentum::SVector{3,Float64}) =
    set_momentum!(state(body), momentum)
set_orientation!(body::PlayerBody, orientation::Real) =
    set_orientation!(state(body), orientation)

set_run_action!(body::PlayerBody, run_action::SVector{2,T} where {T<:Real}) =
    set_run_action!(state(body), run_action)
set_run_action!(body::PlayerBody, run_action::Vector{T} where {T<:Real}) =
    set_run_action!(body, SVector{2}(run_action))
set_turn_action!(body::PlayerBody, turn_action::Real) =
    set_turn_action!(state(body), turn_action)

can_kick(body::PlayerBody) = state(body).kick_cooldown <= 0

trajectory(body::PlayerBody) = trajectory(state(body))
set_trajectory!(body::PlayerBody, trajectory::PlayerTrajectory) =
    set_trajectory!(state(body), trajectory)


function __add_player!(
    world::RxEntity{<:World},
    player::PlayerBody,
    interface::PlayerAgent,
    agent::RxEntity{<:PlayerAgent},
)
    decorated(world).agent_mapping[interface] = player
    add_actor!(decorated(world), player)
    RxEnvironments.add!(world, agent)
    return agent
end


function add_player!(
    world::RxEntity{<:World,S} where {S<:RxEnvironments.ContinuousEntity},
    player::PlayerBody,
    interface::PlayerAgent,
    is_active=false,
)
    rxagent = create_entity(
        interface;
        real_time_factor=RxEnvironments.real_time_factor(RxEnvironments.clock(world)),
        is_active=is_active,
        is_discrete=false,
    )
    return __add_player!(world, player, interface, rxagent)
end

function add_player!(
    world::RxEntity{<:World,S} where {S<:RxEnvironments.DiscreteEntity},
    player::PlayerBody,
    interface::PlayerAgent,
    is_active=false,
)
    rxagent = create_entity(interface; is_discrete=true, is_active=is_active)
    return __add_player!(world, player, interface, rxagent)
end



"""
    recompute_trajectory!(player::PlayerBody)

Recompute the trajectory of the player if there are no external impulses acting on the player.
"""
function recompute_trajectory!(player::PlayerBody)
    T = 2.0
    initial_state = observable_state(state(player))
    tspan = (0.0, T)
    prob = ODEProblem(player_running_dynamics, initial_state, tspan, player)
    sol = solve(prob, Tsit5())
    set_trajectory!(player, PlayerTrajectory(sol, T, 0.0, false))
end

function update!(player::PlayerBody, world::World, Δt::Real)
    if should_recompute(trajectory(player)) || time_left(trajectory(player)) < Δt
        recompute_trajectory!(player)
    end
    update_position!(player, Δt)
end

update!(player::PlayerBody, world::World) =
    update!(player, world, time_interval(world::World))

"""
    update_position(player::PlayerBody, Δt::Real)

Update the position of the player according to the saved trajectory. This function is called with the 
assumption that the trajectory is valid and potential collisions have been checked.
"""
function update_position!(player::PlayerBody, Δt::Real)
    player_trajectory = trajectory(player)
    advance!(player_trajectory, Δt)
    set_position!(player, position(player_trajectory))
    set_momentum!(player, momentum(player_trajectory))
    set_orientation!(player, mod2pi(orientation(player_trajectory)))
end

function receive!(player::PlayerBody, action::PlayerRunAction)
    set_run_action!(player, [norm(action), angle(action)])
    recompute_trajectory!(player)
end

function receive!(player::PlayerBody, action::PlayerTurnAction)
    set_turn_action!(player, angle(action))
    recompute_trajectory!(player)
end

function receive!(player::PlayerBody, action::PlayerMovementAction)
    r_action = run_action(action)
    set_run_action!(player, [clamp(norm(r_action), -1, 1), angle(r_action)])
    set_turn_action!(player, angle(turn_action(action)))
    recompute_trajectory!(player)
end

function receive!(player::PlayerBody, ball::Ball, action::PlayerKickAction)
    # Shoot if closer than 1 meter to ball
    if norm(position(player) - position(ball)) < 1
        shot = CartesianFromPolar()(Polar(action.intensity, action.direction))
        shot = push!(Vector(shot), 0)
        kick!(ball, shot, Quaternion(1.0, 0, 0, 0.0))
    end
end

receive!(player::PlayerBody, world::World, action::PlayerKickAction) =
    receive!(player, get_ball(world), action)


receive!(player::PlayerBody, world::World, action::PlayerRunAction) =
    receive!(player, action)
receive!(player::PlayerBody, world::World, action::PlayerTurnAction) =
    receive!(player, action)
receive!(player::PlayerBody, world::World, action::PlayerMovementAction) =
    receive!(player, action)

# Fallback receive! option
receive!(player::PlayerBody, world::World, something) = something
