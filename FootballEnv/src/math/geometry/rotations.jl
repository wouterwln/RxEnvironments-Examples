using Rotations
using Quaternions

function scale_rotation(rotation::Rotation, scale::Real)
    angle = scale * rotation_angle(rotation)
    axis = rotation_axis(rotation)
    return QuatRotation(AngleAxis(angle, axis...))
end

scale_rotation(rotation::Quaternion, scale::Real) =
    scale_rotation(QuatRotation(rotation), scale)
