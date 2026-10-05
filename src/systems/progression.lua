local Progression = {}

function Progression.threshold(level)
    return level * 30
end

function Progression.stats(level)
    return {maxHP=36+(level-1)*6, maxEnergy=24+(level-1)*3,
            logic=7+(level-1)*2, focus=5+(level-1)}
end

function Progression.addXP(state, amount)
    if type(amount) ~= "number" or amount ~= amount or amount < 0
        or amount > 100000 or amount % 1 ~= 0 then return 0 end
    local p, gained = state.player, 0
    p.xp = p.xp + amount
    while p.level < 20 and p.xp >= Progression.threshold(p.level) do
        p.xp = p.xp - Progression.threshold(p.level)
        p.level, gained = p.level + 1, gained + 1
    end
    if p.level == 20 then p.xp = 0 end
    if gained > 0 then
        for key,value in pairs(Progression.stats(p.level)) do p[key] = value end
        p.hp, p.energy = p.maxHP, p.maxEnergy
    end
    return gained
end

return Progression
