using RxEnvironments
using GLMakie
using CoordinateTransformations

const colormap = (home=:red, away=:blue, ball=:orange)
const shapemap = (home=:rect, away=:star5, ball=:circle)

function RxEnvironments.plot_state(ax, world::World)
    n = 10
    xlims!(ax, -60, 60)
    ylims!(ax, -40, 40)
    for i in 1:(n+2)
        xs = (-80+(110÷n)*i):0.1:(-80+(110÷n)*(i+1))
        if i % 2 == 0
            band!(ax, xs, -40, 40, color=:palegreen)
        else
            band!(ax, xs, -40, 40, color=:palegreen3)
        end
    end
    lines!(ax, [-55, 55, 55, -55, -55], [-35, -35, 35, 35, -35], color=:white, linewidth=3)
    lines!(ax, [-55, -39, -39, -55], [-20.15, -20.15, 20.15, 20.15], color=:white, linewidth=3)
    lines!(ax, [55, 39, 39, 55], [-20.15, -20.15, 20.15, 20.15], color=:white, linewidth=3)
    lines!(ax, [-55, -50, -50, -55], [-9.15, -9.15, 9.15, 9.15], color=:white, linewidth=3)
    lines!(ax, [55, 50, 50, 55], [-9.15, -9.15, 9.15, 9.15], color=:white, linewidth=3)
    lines!(ax, [0, 0], [-35, 35], color=:white, linewidth=3)
    arc!(ax, [0, 0], 9.15, 0, 2π, color=:white, linewidth=3)
    scatter!(ax, 0, 0, color=:white, markersize=10)
    scatter!(ax, -44, 0, color=:white, markersize=10)
    scatter!(ax, 44, 0, color=:white, markersize=10)
    arc!(ax, [-44, 0], 9.15, -1, 1, color=:white, linewidth=3)
    arc!(ax, [44, 0], 9.15, π - 1, π + 1, color=:white, linewidth=3)
    arc!(ax, [-55, -35], 1, 0, π / 2, color=:white, linewidth=3)
    arc!(ax, [55, -35], 1, π / 2, π, color=:white, linewidth=3)
    arc!(ax, [55, 35], 1, π, 3π / 2, color=:white, linewidth=3)
    arc!(ax, [-55, 35], 1, 3π / 2, 2π, color=:white, linewidth=3)
    for agent in actors(world)
        visualize(ax, agent)
    end
end

function visualize(ax, player::PlayerBody)
    pos = position(player)[1:2]
    scatter!(ax, pos..., color=colormap[team(player)], marker=shapemap[team(player)], markersize=20)
    line_endpoint = pos + CartesianFromPolar()(Polar(2.5, orientation(player)))
    line = hcat(pos, line_endpoint)'
    lines!(ax, line[:, 1], line[:, 2], color=colormap[team(player)], linewidth=3)
end

function visualize(ax, ball::Ball)
    scatter!(ax, position(ball)..., color=colormap.ball)
end
