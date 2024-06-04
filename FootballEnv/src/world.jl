using RxEnvironments

"""
The World struct contains all the information about the current state of the world. It contains the following fields:

- `actors`: A vector of all the actors in the world
- `time`: A reference to the current time of the simulation
"""
struct World
    actors::AbstractArray{<:Actor}
    agent_mapping::Dict{<:PlayerAgent,<:Actor}
end

World() = World(Actor[], Dict{PlayerAgent,Actor}())
actors(world::World) = world.actors
n_balls(world::World) = length(filter(x -> x isa Ball, actors(world)))
n_players(world::World) = length(world.agent_mapping)

add_actor!(world::World, actor::Actor) = push!(world.actors, actor)

function create_world(emits_every_ms::Int = 1000, real_time_factor::Real = 1.0)
    environment =
        create_entity(World(); real_time_factor = real_time_factor, is_active = true)
    RxEnvironments.add_timer!(environment, emits_every_ms)
    return environment
end

function create_discrete_world(real_time_factor::Real = 1.0)
    environment =
        create_entity(World(); real_time_factor, is_active = true, is_discrete = true)
    return environment
end

RxEnvironments.time_interval(env::World) = 0.1

n_balls(world::RxEnvironments.RxEntity{World}) = n_balls(RxEnvironments.decorated(world))
n_players(world::RxEnvironments.RxEntity{World}) =
    n_players(RxEnvironments.decorated(world))

function get_agent(world::World, agent::PlayerAgent)
    return world.agent_mapping[agent]
end

function get_ball(world::World; index = 1, latest = false)
    if latest
        return collect(filter(x -> x isa Ball, actors(world)))[end]
    else
        return collect(filter(x -> x isa Ball, actors(world)))[index]
    end

end

"""
update!:
    Simulate behaviour of the world from previous timestep up to current timestep
    using states of the previous timestep, or "Catch up".
"""
function RxEnvironments.update!(world::World, Δt::Float64)
    for actor in actors(world)
        update!(actor, world, Δt)
    end
end


function resolve_collision!(actor::Actor, world::World, Δt)
    nothing
end

function RxEnvironments.receive!(world::World, agent::PlayerAgent, action)
    actor = world.agent_mapping[agent]
    receive!(actor, world, action)
end
