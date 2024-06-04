module test_rotations

using Test
using TestSetExtensions
using Rotations
using Quaternions

@testset ExtendedTestSet "math_rotations" begin
    @testset "scale_rotation" begin
        import FootballSimulation: scale_rotation
        rotation = AngleAxis(pi / 4, 1, 0, 0)
        scaled_rotation = scale_rotation(rotation, 2)
        expected_rotation = QuatRotation(AngleAxis(pi / 2, 1, 0, 0))
        @test scaled_rotation ≈ expected_rotation

        rotation = QuatRotation(Quaternion(1))
        scaled_rotation = scale_rotation(rotation, 0.5)
        expected_rotation = QuatRotation(Quaternion(1))
        @test scaled_rotation ≈ expected_rotation

        rotation = QuatRotation(AngleAxis(pi / 4, 0, 0, 1))
        scaled_rotation = scale_rotation(rotation, -1)
        expected_rotation = QuatRotation(AngleAxis(-pi / 4, 0, 0, 1))
        @test scaled_rotation ≈ expected_rotation

        rotation = Quaternion(1)
        scaled_rotation = scale_rotation(rotation, 0.5)
        expected_rotation = QuatRotation(Quaternion(1))
        @test scaled_rotation ≈ expected_rotation
    end
end

end
