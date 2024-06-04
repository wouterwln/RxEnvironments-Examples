abstract type Trajectory end

solution(trajectory::Trajectory) = trajectory.solution
elapsed_time(trajectory::Trajectory) = trajectory.elapsed_time
advance!(trajectory::Trajectory, Δt::Real) = trajectory.elapsed_time += Δt

end_of_trajectory(x, Δt) = true
end_of_trajectory(trajectory::Trajectory, Δt) =
    elapsed_time(trajectory) + Δt > end_time(trajectory)


peek(trajectory::Trajectory, Δt::Real) = solution(trajectory)(elapsed_time(trajectory) + Δt)

position(trajectory::Trajectory) =
    SVector{3}(trajectory.solution(elapsed_time(trajectory))[1:3])
momentum(trajectory::Trajectory) =
    SVector{3}(trajectory.solution(elapsed_time(trajectory))[4:6])

position(trajectory::Trajectory, time::Real) = solution(trajectory)(time)[1:3]
momentum(trajectory::Trajectory, time::Real) = solution(trajectory)(time)[4:6]
