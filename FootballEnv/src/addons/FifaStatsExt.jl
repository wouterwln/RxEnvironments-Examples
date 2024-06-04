using CSV, DataFrames

function player(name::String; team=:home, position=zeros(3), orientation=0.0)
    df = CSV.read(
        Base.Filesystem.joinpath(@__DIR__, "../..", "data", "fifastats.csv"),
        DataFrame,
    )
    row = filter(row -> row.full_name == name, df)
    if first(size(row)) == 0
        error("Player not found")
    end
    row = first(row)
    id = PlayerID(row.full_name, team, 0)

    pace = Pace(row.acceleration, row.sprint_speed)
    shooting = Shooting(
        row.positioning_shooting,
        row.finishing,
        row.shot_power,
        row.long_shots,
        row.volleys,
        row.penalties,
    )
    passing = Passing(
        row.vision,
        row.crossing,
        row.free_kick_accuracy,
        row.short_passing,
        row.long_passing,
        row.curve,
    )
    dribbling = Dribbling(
        row.agility,
        row.balance,
        row.reactions,
        row.ball_control,
        row.dribbling,
        row.composure,
    )
    defending = Defending(
        row.interceptions,
        row.heading_accuracy,
        row.defense_awareness,
        row.standing_tackle,
        row.sliding_tackle,
    )
    physical = Physical(row.jumping, row.stamina, row.strength, row.aggression)

    strong_foot = row.foot == "Right" ? RightFoot() : LeftFoot()
    att_work_rate =
        row.att_work_rate == "High" ? HighWorkRate() :
        row.att_work_rate == "Med" ? MediumWorkRate() : LowWorkRate()
    def_work_rate =
        row.def_work_rate == "High" ? HighWorkRate() :
        row.def_work_rate == "Med" ? MediumWorkRate() : LowWorkRate()
    auxiliary = AuxiliaryStats(
        strong_foot,
        row.skill_moves,
        row.weak_foot,
        def_work_rate,
        att_work_rate,
    )

    stats = PlayerStats(pace, shooting, passing, dribbling, defending, physical, auxiliary)
    state = PlayerState(position, zeros(3), orientation)
    return PlayerBody(id, stats, state)
end
