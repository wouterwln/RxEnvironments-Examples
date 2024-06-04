using Rocket
using DataStructures
using SampledSignals
using RxEnvironments
using PortAudio

struct BufferedSound <: SampleSource
    buffer::MutableLinkedList{Float32}
    max_buffer_size::Int
end

BufferedSound() = BufferedSound(MutableLinkedList{Float32}(zeros(44100)...), 44100)
Base.show(io::IO, source::BufferedSound) = print(io, "BufferedSound($(length(source.buffer)))")

Base.push!(source::BufferedSound, sample::Float32) = begin
    if length(source) >= source.max_buffer_size
        popfirst!(source.buffer)
    end
    push!(source.buffer, sample)
end

Base.length(source::BufferedSound) = length(source.buffer)

SampledSignals.samplerate(::BufferedSound) = 44100
SampledSignals.nchannels(::BufferedSound) = 1
Base.eltype(::BufferedSound) = Float64

function SampledSignals.unsafe_read!(source::BufferedSound, buf::AbstractArray, frameoffset, framecount)
    for i in 1:framecount
        buf[frameoffset+i] = popfirst!(source.buffer)
    end
    return framecount
end

mutable struct SoundBufferActor <: Rocket.Actor{Any}
    sound::BufferedSound
    stream::PortAudioStream
    sub
end

SoundBufferActor() = SoundBufferActor(BufferedSound(), PortAudioStream(0, 1), nothing)

Rocket.on_next!(actor::SoundBufferActor, sample::RxEnvironments.Observation{E,D}) where {E,D} = begin
    for elem in RxEnvironments.data(sample)
        push!(actor.sound, elem)
    end
end
Rocket.on_next!(actor::SoundBufferActor, sample) = nothing

listen(actor::SoundBufferActor) = @async write(actor.stream, actor.sound)
stop(actor::SoundBufferActor) = begin
    close(actor.stream)
    unsubscribe!(actor.sub)
end
