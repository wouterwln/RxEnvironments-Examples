module test_newtonian

using Test
using TestSetExtensions
using FootballSimulation
using Quaternions

@testset ExtendedTestSet "Newtonian Physics" begin
    @testset "air_resistance" begin
        import FootballSimulation: air_resistance
        @test isapprox(air_resistance(0.7673, 11, 1), 56.87; rtol = 0.1)
        @test isapprox(air_resistance(0.03918, 10, 10), 24; rtol = 0.1)
        @test isapprox(air_resistance(0.03918, 0, 1), 0; rtol = 0.1)
    end

    @testset "gravity" begin
        import FootballSimulation: gravity
        @test isapprox(gravity(0.45), 4.0; rtol = 0.1)
        @test isapprox(gravity(0.5), 4.9; rtol = 0.1)
        @test isapprox(gravity(0.55), 5.4; rtol = 0.1)
    end

    @testset "magnus effect" begin
        import FootballSimulation: magnus
        @test magnus(0.11, Quaternion(1), 10) ≈ 0
        @test magnus(0.11, Quaternion(0, 0, 0, 1), 10) ≈ 0.32184286
    end

    @testset "kinetic_energy" begin
        import FootballSimulation: kinetic_energy
        @test isapprox(kinetic_energy(0.45, 10), 22.5; rtol = 0.1)
        @test isapprox(kinetic_energy(0.5, 10), 25; rtol = 0.1)
        @test isapprox(kinetic_energy(0.55, 10), 27.5; rtol = 0.1)
    end
end

end
