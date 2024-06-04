using Quaternions
using Rotations

const ρ = 1.225
const g = 9.807

function air_resistance(C_air::Real, velocity::Real, surface::Real)
    return 0.5 * C_air * ρ * velocity^2 * surface
end

function gravity(mass::Real)
    return g * mass
end

function magnus(radius::Real, rotation::Quaternion, speed::Real)
    angular_velocity = rotation_angle(QuatRotation(rotation))
    v_r = radius * angular_velocity
    G = 2π * radius * v_r
    return ρ * radius * G * speed
end

function kinetic_energy(mass::Real, velocity::Real)
    return 0.5 * mass * velocity^2
end
