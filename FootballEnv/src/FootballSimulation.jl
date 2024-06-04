module FootballSimulation

include("math/geometry/rotations.jl")
include("math/geometry/coordinatetransformations.jl")
include("math/physics/newtonian.jl")

include("actors/trajectory.jl")
include("actors/abstractactor.jl")
include("actors/player/agent.jl")

include("world.jl")

include("actors/ball.jl")

include("actors/player/actions.jl")
include("actors/player/stats.jl")
include("actors/player/movement.jl")
include("actors/player/body.jl")

include("addons/FifaStatsExt.jl")

include("visualization.jl")
end
