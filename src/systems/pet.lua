local Pet = {}
local moods = {["return"]="happy", win="happy", loss="hurt",
               level="excited", rare="curious", node="thinking"}

function Pet.react(state, event)
    local pet = state.pet
    pet.mood, pet.emotion, pet.idle = moods[event] or "idle", 5, 0
    if event == "win" then pet.bond = math.min(100,pet.bond+1) end
    if event == "rare" or event == "node" then
        pet.curiosity = math.min(100,pet.curiosity+3)
    end
end

function Pet.tick(state, dt)
    if type(dt) ~= "number" or dt < 0 or dt ~= dt or dt > 3600 then return end
    local pet, p = state.pet,state.player
    local oldAge = pet.age
    pet.age, pet.idle = pet.age+dt,pet.idle+dt
    pet.cooldown = math.max(0,pet.cooldown-dt)
    pet.emotion = math.max(0,pet.emotion-dt)
    local drain = math.floor(pet.age/90)-math.floor(oldAge/90)
    p.energy = math.max(0,p.energy-drain)
    if pet.emotion > 0 then return end
    if p.energy <= 4 then pet.mood="sleepy"
    elseif pet.idle >= 120 then pet.mood="sad"
    else pet.mood="idle" end
end

function Pet.interact(state, action)
    local pet,p = state.pet,state.player
    if action ~= "talk" and action ~= "play" and action ~= "rest" then
        return false, "Unknown pet action."
    end
    if pet.cooldown > 0 then
        pet.mood,pet.emotion = "angry",2
        return false, "A moment to think, please."
    end
    pet.cooldown,pet.idle,pet.emotion = 5,0,5
    if action == "talk" then pet.bond=math.min(100,pet.bond+2); pet.mood="thinking"
    elseif action == "play" then
        pet.curiosity=math.min(100,pet.curiosity+2)
        pet.mood="excited"
    else p.energy=math.min(p.maxEnergy,p.energy+4); pet.mood="happy" end
    return true, "Mote feels "..pet.mood.."."
end

return Pet
