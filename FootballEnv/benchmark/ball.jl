using BenchmarkTools
import FootballSimulation: Ball, update!, World

function ball_benchmarks()
    SUITE = BenchmarkGroup(["ball"])
    ball = Ball((0.0, 0.0, 0.11), (10.0, 0.0, 0.0))
    world = World([ball])
    SUITE["update bouncing ball"] = @benchmarkable update!($ball, $world, 0.01)
    return SUITE
end