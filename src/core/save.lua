local State = require("core.state")
local Maps = require("data.maps")
local World = require("world.world")
local Items = require("data.items")
local Progression = require("systems.progression")
local Save = {}
local flagNames = {"started","forest","valley","matrix","boss","ended",
                   "forest_cache","valley_cache","matrix_cache"}

local function number(value, fallback, low, high, integer, report)
    if type(value) ~= "number" or value ~= value or value < low or value > high
        or (integer and value % 1 ~= 0) then
        report.bad = true
        return fallback
    end
    return value
end

local function player(raw, state, report)
    local source,p = type(raw.player)=="table" and raw.player or {},state.player
    p.level = number(source.level,1,1,20,true,report)
    for key,value in pairs(Progression.stats(p.level)) do p[key] = value end
    p.hp = number(source.hp,p.maxHP,0,p.maxHP,true,report)
    p.energy = number(source.energy,p.maxEnergy,0,p.maxEnergy,true,report)
    p.xp = number(source.xp,0,0,Progression.threshold(p.level)-1,true,report)
    if p.level == 20 then p.xp=0 end
    if p.hp == 0 then p.hp=p.maxHP; report.bad=true end
end

local function pet(raw, state, report)
    local source = type(raw.pet)=="table" and raw.pet or {}
    for _, key in ipairs({"bond","curiosity"}) do
        state.pet[key] = number(source[key],state.pet[key],0,100,true,report)
    end
    state.pet.age = number(source.age,0,0,100000000,false,report)
    state.pet.experience = number(source.experience,0,0,100000000,true,report)
    state.pet.idle = number(source.idle,0,0,100000000,false,report)
    -- Transient emotion/cooldown intentionally restart after restoring a document.
end

local function inventory(raw, state, report)
    if type(raw.inventory) ~= "table" then report.bad=true; return end
    state.inventory = {}
    for id,value in pairs(raw.inventory) do
        if Items[id] then
            local count = number(value,0,0,99,true,report)
            if count > 0 then state.inventory[id] = count end
        else report.bad=true end
    end
end

local function flags(raw, state, report)
    local source = type(raw.flags)=="table" and raw.flags or {}
    if type(raw.flags) ~= "table" then report.bad=true end
    for _,key in ipairs(flagNames) do
        state.flags[key] = source[key] == true
        if source[key] ~= nil and type(source[key]) ~= "boolean" then report.bad=true end
    end
    if state.flags.boss and not (state.flags.forest and state.flags.valley
        and state.flags.matrix) then state.flags.boss=false; report.bad=true end
    if state.flags.ended and not state.flags.boss then
        state.flags.ended=false; report.bad=true
    end
end

local function location(raw, state, report)
    if Maps[raw.map] then state.map=raw.map else report.bad=true end
    state.x = number(raw.x,3,1,16,true,report)
    state.y = number(raw.y,5,1,11,true,report)
    if not World.walkable(state.map,state.x,state.y) then
        state.x,state.y,report.bad=3,5,true
    end
    state.seed = number(raw.seed,1701,1,2147483646,true,report)
    state.ticks = number(raw.ticks,0,0,100000000,true,report)
    state.steps = number(raw.steps,0,0,100000000,true,report)
end

function Save.decode(raw)
    local state = State.new()
    if type(raw) ~= "table" or raw.version ~= 1 then
        return state, raw == nil and "New memory. No saved game yet."
            or "Unreadable save. A safe new memory was created."
    end
    local report = {bad=false}
    player(raw,state,report)
    pet(raw,state,report)
    inventory(raw,state,report)
    flags(raw,state,report)
    location(raw,state,report)
    return state, report.bad and "Save repaired. Check STATUS before saving." or nil
end

function Save.encode(state)
    local raw = {version=1}
    for _,key in ipairs({"player","pet","inventory","flags"}) do
        raw[key] = {}
        for field,value in pairs(state[key]) do raw[key][field] = value end
    end
    for _,key in ipairs({"map","x","y","seed","ticks","steps"}) do raw[key]=state[key] end
    return raw
end

return Save
