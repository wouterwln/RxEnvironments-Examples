using LinearAlgebra

struct PlayerRunAction
    r::Real
    θ::Real
end

LinearAlgebra.norm(p::PlayerRunAction) = p.r
Base.angle(p::PlayerRunAction) = p.θ

struct PlayerTurnAction
    θ::Real
end

LinearAlgebra.angle(p::PlayerTurnAction) = p.θ

struct PlayerMovementAction
    run_action::PlayerRunAction
    turn_action::PlayerTurnAction
end

run_action(action::PlayerMovementAction) = action.run_action
turn_action(action::PlayerMovementAction) = action.turn_action

abstract type Foot end

struct LeftFoot <: Foot end
struct RightFoot <: Foot end


struct PlayerKickAction
    foot::Foot
    direction::Real
    intensity::Real
end

struct PlayerTackeAction end

struct PlayerSlideAction end
