local Enemies = require("data.enemies")
local Skills = require("data.skills")
local State = require("core.state")
local Inventory = require("systems.inventory")
local Progression = require("systems.progression")
local Combat = {}

function Combat.new(state, id)
    local enemy = assert(Enemies[id], "Unknown enemy")
    return {state=state, id=id, enemy=enemy, hp=enemy.hp, defense=enemy.defense,
            turn=0, boost=0, guard=0, glitch=0, charge=0, revealed=false,
            message="A "..enemy.name.." appears.", reply="Choose an action."}
end

local function damage(battle, amount, skill)
    local value = math.max(1, amount - battle.defense)
    if battle.boost > 0 then value, battle.boost = value*2, 0 end
    if skill == battle.enemy.weakness then
        value = value + (battle.revealed and 8 or 4)
    end
    battle.hp = math.max(0,battle.hp-value)
    return value
end

local function skill(b, id)
    local p = b.state.player
    if id == "factor" then
        b.defense = math.max(0,b.defense-3)
        b.message = "Factor: "..damage(b,p.focus+3,id).." damage; armor breaks."
    elseif id == "solve" then
        b.message = "Solve: "..damage(b,p.logic*2+3,id).." damage."
    elseif id == "graph" then
        b.revealed = true
        b.message = "Graph: weak to "..Skills[b.enemy.weakness].name.."."
    elseif id == "analyze" then
        b.boost = 2
        b.message = "Analyze: next hit deals double."
    elseif id == "debug" then
        b.glitch = 0
        p.hp = math.min(p.maxHP,p.hp+12)
        b.message = "Debug: glitch cleared; +12 HP."
    end
end

local function enemyTurn(b)
    local p = b.state.player
    local action = b.enemy.pattern[(b.turn-1) % #b.enemy.pattern+1]
    if action == "charge" then
        b.charge, b.reply = 5, "Enemy gathers a pulse..."
        return
    end
    local value = math.max(1,b.enemy.logic-math.floor(p.focus/2)+b.charge)
    b.charge = 0
    if b.guard > 0 then value, b.guard = math.ceil(value/2), b.guard-1 end
    if action == "glitch" then b.glitch = 2 end
    if action == "drain" then p.energy = math.max(0,p.energy-3) end
    if action == "siphon" then b.hp = math.min(b.enemy.hp,b.hp+4) end
    if b.glitch > 0 then value, b.glitch = value+2,b.glitch-1 end
    p.hp = math.max(0,p.hp-value)
    b.reply = b.enemy.name..": "..action.." (-"..value.." HP)."
    if p.hp == 0 then b.done = "lost" end
end

local function playerAction(b, action, id)
    local p = b.state.player
    if action == "attack" then
        local power = 8+p.level+math.floor(b.state.pet.bond/25)
        b.message = "Pulse: "..damage(b,power).." damage."
    elseif action == "skill" then
        if not Skills.get(id) then return false end
        if p.energy < Skills[id].cost then
            b.message = "Not enough energy. Use a cell."
            return false
        end
        p.energy = p.energy-Skills[id].cost
        skill(b,id)
    elseif action == "item" then
        local ok, message = Inventory.use(b.state,id,b)
        b.message = message
        if not ok then return false end
    elseif action == "run" then
        if b.enemy.boss then b.message="The sentinel blocks escape."; return false end
        if State.random(b.state,4) ~= 1 then b.done="ran"; b.message="Escaped safely."
        else b.message="Escape failed." end
    else return false end
    return true
end

function Combat.act(b, action, id)
    if b.done then return false end
    if not playerAction(b,action,id) then return false end
    b.turn = b.turn+1
    if b.hp == 0 then b.done="won"; b.reply="Memory restored. Enter to continue." end
    if not b.done then enemyTurn(b) end
    return true
end

function Combat.reward(state, b)
    if b.done ~= "won" or b.rewarded then return false end
    b.rewarded = true
    b.levels = Progression.addXP(state,b.enemy.xp)
    state.pet.experience = state.pet.experience+b.enemy.xp
    Inventory.add(state,b.enemy.drop,1)
    if b.enemy.boss then state.flags.boss = true end
    return true
end

return Combat
