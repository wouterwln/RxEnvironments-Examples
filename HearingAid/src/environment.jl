using SampledSignals
using RxEnvironments

struct UserFeedback
    feedback::Float64
end

mutable struct World
    sound::SampleBuf{Float32,2}
    sound_index_start::Int
    sound_index_end::Int
end

function RxEnvironments.update!(world::World, delta_t)
    if world.sound_index_end == length(world.sound)
        world.sound_index_start = 1
    else
        world.sound_index_start = world.sound_index_end + 1
    end
    l = round(Int, delta_t * 44100)
    if world.sound_index_start + l > length(world.sound)
        world.sound_index_end = length(world.sound)
    else
        world.sound_index_end = world.sound_index_start + l
    end
end


mutable struct HearingAid
    parameters::NTuple{2,Float32}
end

RxEnvironments.update!(hearing_aid::HearingAid, delta_t::Float64) = nothing

struct RxInferAgent end
RxEnvironments.update!(agent::RxInferAgent, delta_t::Float64) = nothing

struct User end
RxEnvironments.update!(user::User, delta_t::Float64) = nothing

# The world sends the next sample to the hearing aid
RxEnvironments.what_to_send(hearingaid::HearingAid, world::World) = view(world.sound, world.sound_index_start:world.sound_index_end)
# The hearning aid sends nothing back
RxEnvironments.emits(hearingaid::HearingAid, world::World, any) = false
RxEnvironments.emits(hearingaid::HearingAid, world::World, any::NTuple{2,Float32}) = false

# The hearing aid sends the next sample to the agent
RxEnvironments.what_to_send(agent::RxInferAgent, hearingaid::HearingAid, sample::SubArray{Float32}) = sample
# The agent sends nothing back
RxEnvironments.emits(agent::RxInferAgent, hearingaid::HearingAid, sample::SubArray{Float32}) = false

# The hearing aid sends the next transformed sample to the user
RxEnvironments.what_to_send(user::User, hearingaid::HearingAid, sample::SubArray{Float32}) = hearingaid.parameters[1] .* sample .+ hearingaid.parameters[2]
# The user sends nothing back
RxEnvironments.emits(user::User, hearingaid::HearingAid, sample::SubArray{Float32}) = false

# If the agent emits a new set of parameters, the hearing aid updates its parameters
RxEnvironments.receive!(hearingaid::HearingAid, agent::RxInferAgent, parameters::NTuple{2,Float32}) = hearingaid.parameters = parameters
# When the hearing aid updates its parameters, it sends nothing
RxEnvironments.emits(hearingaid::HearingAid, other, parameters::NTuple{2,Float32}) = false

RxEnvironments.what_to_send(agent::RxInferAgent, hearingaid::HearingAid, feedback::UserFeedback) = feedback.feedback
RxEnvironments.emits(agent::RxInferAgent, hearingaid::HearingAid, feedback::UserFeedback) = false
# RxEnvironments.action_type(::World) = Float32
# RxEnvironments.action_type(::HearingAid) = Float32

using FileIO
file = FileIO.load("data/bbcnews_traffic_0db.wav")
w = World(SampleBuf(file[1], file[2]), 1, 1)
world = create_entity(w; is_active=true)
hearing_aid = create_entity(HearingAid((1.0, 0.0)), is_active=true)
agent = create_entity(RxInferAgent(); is_active=false)
user = create_entity(User(); is_active=false)

add!(world, hearing_aid)
add!(hearing_aid, agent)
add!(hearing_aid, user)
RxEnvironments.add_timer!(world, 1)

function listen(world::RxEnvironments.RxEntity{P,W,H} where {P,W,H})
    s = SoundBufferActor()
    s.sub = subscribe_to_observations!(world, s)
    @async listen(s)
    return s
end
