using RxEnvironments

abstract type PlayerAgent end

RxEnvironments.receive!(agent::PlayerAgent, obs) = nothing
RxEnvironments.what_to_send(agent::PlayerAgent, any) = nothing
RxEnvironments.update!(agent::PlayerAgent, Δt::Real) = nothing

mutable struct EmptyAgent <: PlayerAgent end

function RxEnvironments.emits(agent::EmptyAgent, world, obs)
    return false
end
