module test_player

using Test
using TestSetExtensions
using FootballSimulation
import FootballSimulation:
    Player, set_position!, set_momentum!, position, momentum, rotation

@testset ExtendedTestSet "player" begin

    @testset "get_kick_direction" begin
        import FootballSimulation: get_kick_direction, Kick, IsRight, IsInside
        player = Player()
        kick = Kick(IsRight(), IsInside(), 0, 0, 1, 0)
        @show get_kick_direction(player, kick, 1)
    end
end

end
