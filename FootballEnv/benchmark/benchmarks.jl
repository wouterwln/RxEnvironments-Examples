using BenchmarkTools

const SUITE = BenchmarkGroup()
include("ball.jl")
SUITE["ball"] = ball_benchmarks()