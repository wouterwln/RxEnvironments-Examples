using CoordinateTransformations
using LinearAlgebra

LinearAlgebra.norm(p::Polar) = p.r
Base.angle(p::Polar) = p.θ
