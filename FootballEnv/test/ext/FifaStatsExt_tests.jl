@testitem "Find players in dataset" begin
    using FootballSimulation
    import FootballSimulation:
        player,
        stats,
        strong_foot,
        att_work_rate,
        def_work_rate,
        skill_moves,
        weak_foot_rating

    @test_throws ErrorException player("NotAPlayer")
    p = player("Virgil van Dijk")
    @test FootballSimulation.getname(p) == "Virgil van Dijk"
    @test strong_foot(stats(p)) == FootballSimulation.RightFoot()
    @test att_work_rate(stats(p)) == FootballSimulation.MediumWorkRate()
    @test def_work_rate(stats(p)) == FootballSimulation.HighWorkRate()
    @test weak_foot_rating(stats(p)) == 3
    @test skill_moves(stats(p)) == 2
end
