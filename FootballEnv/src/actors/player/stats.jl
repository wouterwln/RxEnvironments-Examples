abstract type WorkRate end

struct LowWorkRate <: WorkRate end
struct MediumWorkRate <: WorkRate end
struct HighWorkRate <: WorkRate end

struct Pace{T<:Real}
    acceleration::T
    sprint_speed::T
end

acceleration(pace::Pace) = pace.acceleration
sprint_speed(pace::Pace) = pace.sprint_speed

"""
    max_sprint_speed(pace::Pace)

Return the maximal sprint speed a player can reach given his sprint speed stat.
This is computed by normalizing the stat and applying a sigmoid function. The minimum value is 20 and the maximum value is 37.5.
"""
max_sprint_speed(pace::Pace) = max_sprint_speed(sprint_speed(pace))

function max_sprint_speed(speed::Int)
    normalized_stat = (speed - 50) / 25
    return 5.5 + 5 * (1 / (1 + exp(-normalized_stat)))
end

struct Shooting{T<:Real}
    positioning::T
    finishing::T
    shot_power::T
    long_shots::T
    volleys::T
    penalties::T
end

positioning(shooting::Shooting) = shooting.positioning
finishing(shooting::Shooting) = shooting.finishing
shot_power(shooting::Shooting) = shooting.shot_power
long_shots(shooting::Shooting) = shooting.long_shots
volleys(shooting::Shooting) = shooting.volleys
penalties(shooting::Shooting) = shooting.penalties

struct Passing{T<:Real}
    vision::T
    crossing::T
    free_kick_accuracy::T
    short_passing::T
    long_passing::T
    curve::T
end

vision(passing::Passing) = passing.vision
crossing(passing::Passing) = passing.crossing
free_kick_accuracy(passing::Passing) = passing.free_kick_accuracy
short_passing(passing::Passing) = passing.short_passing
long_passing(passing::Passing) = passing.long_passing
curve(passing::Passing) = passing.curve

struct Dribbling{T<:Real}
    agility::T
    balance::T
    reactions::T
    ball_control::T
    dribbling::T
    composure::T
end

agility(dribbling::Dribbling) = dribbling.agility
balance(dribbling::Dribbling) = dribbling.balance
reactions(dribbling::Dribbling) = dribbling.reactions
ball_control(dribbling::Dribbling) = dribbling.ball_control
dribbling(dribbling::Dribbling) = dribbling.dribbling
composure(dribbling::Dribbling) = dribbling.composure

struct Defending{T<:Real}
    interceptions::T
    heading_accuracy::T
    marking::T
    standing_tackle::T
    sliding_tackle::T
end

interceptions(defending::Defending) = defending.interceptions
heading_accuracy(defending::Defending) = defending.heading_accuracy
marking(defending::Defending) = defending.marking
standing_tackle(defending::Defending) = defending.standing_tackle
sliding_tackle(defending::Defending) = defending.sliding_tackle

struct Physical{T<:Real}
    jumping::T
    stamina::T
    strength::T
    aggression::T
end

jumping(physical::Physical) = physical.jumping
stamina(physical::Physical) = physical.stamina
strength(physical::Physical) = physical.strength
aggression(physical::Physical) = physical.aggression

struct GKStats{T<:Real}
    diving::T
    handling::T
    kicking::T
    reflexes::T
    speed::T
end

diving(gk_stats::GKStats) = gk_stats.diving
handling(gk_stats::GKStats) = gk_stats.handling
kicking(gk_stats::GKStats) = gk_stats.kicking
reflexes(gk_stats::GKStats) = gk_stats.reflexes
speed(gk_stats::GKStats) = gk_stats.speed

struct AuxiliaryStats
    foot::Foot
    skill_moves::Int
    weak_foot::Int
    def_work_rate::WorkRate
    att_work_rate::WorkRate
end

foot(auxiliary::AuxiliaryStats) = auxiliary.foot
skill_moves(auxiliary::AuxiliaryStats) = auxiliary.skill_moves
weak_foot(auxiliary::AuxiliaryStats) = auxiliary.weak_foot
def_work_rate(auxiliary::AuxiliaryStats) = auxiliary.def_work_rate
att_work_rate(auxiliary::AuxiliaryStats) = auxiliary.att_work_rate

struct PlayerStats{T<:Real}
    pace::Pace{T}
    shooting::Shooting{T}
    passing::Passing{T}
    dribbling::Dribbling{T}
    defending::Defending{T}
    physical::Physical{T}
    auxiliary::AuxiliaryStats
end

pace(stats::PlayerStats) = stats.pace
shooting(stats::PlayerStats) = stats.shooting
passing(stats::PlayerStats) = stats.passing
drib(stats::PlayerStats) = stats.dribbling
defending(stats::PlayerStats) = stats.defending
physical(stats::PlayerStats) = stats.physical

acceleration(stats::PlayerStats) = acceleration(pace(stats))
sprint_speed(stats::PlayerStats) = sprint_speed(pace(stats))
max_sprint_speed(stats::PlayerStats) = max_sprint_speed(pace(stats))

positioning(stats::PlayerStats) = positioning(shooting(stats))
finishing(stats::PlayerStats) = finishing(shooting(stats))
shot_power(stats::PlayerStats) = shot_power(shooting(stats))
long_shots(stats::PlayerStats) = long_shots(shooting(stats))
volleys(stats::PlayerStats) = volleys(shooting(stats))
penalties(stats::PlayerStats) = penalties(shooting(stats))

vision(stats::PlayerStats) = vision(passing(stats))
crossing(stats::PlayerStats) = crossing(passing(stats))
free_kick_accuracy(stats::PlayerStats) = free_kick_accuracy(passing(stats))
short_passing(stats::PlayerStats) = short_passing(passing(stats))
long_passing(stats::PlayerStats) = long_passing(passing(stats))
curve(stats::PlayerStats) = curve(passing(stats))

agility(stats::PlayerStats) = agility(drib(stats))
balance(stats::PlayerStats) = balance(drib(stats))
reactions(stats::PlayerStats) = reactions(drib(stats))
ball_control(stats::PlayerStats) = ball_control(drib(stats))
dribbling(stats::PlayerStats) = dribbling(drib(stats))
composure(stats::PlayerStats) = composure(drib(stats))

interceptions(stats::PlayerStats) = interceptions(defending(stats))
heading_accuracy(stats::PlayerStats) = heading_accuracy(defending(stats))
marking(stats::PlayerStats) = marking(defending(stats))
standing_tackle(stats::PlayerStats) = standing_tackle(defending(stats))
sliding_tackle(stats::PlayerStats) = sliding_tackle(defending(stats))

jumping(stats::PlayerStats) = jumping(physical(stats))
stamina(stats::PlayerStats) = stamina(physical(stats))
strength(stats::PlayerStats) = strength(physical(stats))
aggression(stats::PlayerStats) = aggression(physical(stats))

gk_diving(stats::PlayerStats) = diving(stats.gk_stats)
gk_handling(stats::PlayerStats) = handling(stats.gk_stats)
gk_kicking(stats::PlayerStats) = kicking(stats.gk_stats)
gk_reflexes(stats::PlayerStats) = reflexes(stats.gk_stats)
gk_speed(stats::PlayerStats) = speed(stats.gk_stats)

strong_foot(stats::PlayerStats) = foot(stats.auxiliary)
skill_moves(stats::PlayerStats) = skill_moves(stats.auxiliary)
weak_foot_rating(stats::PlayerStats) = weak_foot(stats.auxiliary)
def_work_rate(stats::PlayerStats) = def_work_rate(stats.auxiliary)
att_work_rate(stats::PlayerStats) = att_work_rate(stats.auxiliary)
