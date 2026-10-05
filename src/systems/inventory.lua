local Items = require("data.items")
local Inventory = {}

function Inventory.add(state, id, count)
    if not Items.get(id) or type(count) ~= "number" or count ~= count
        or count < 1 or count > 100000 or count % 1 ~= 0 then return false end
    state.inventory[id] = math.min(99, (state.inventory[id] or 0) + count)
    return true
end

local function apply(state, item, battle)
    local p, pet = state.player, state.pet
    if item.kind == "heal" or item.kind == "rest" or item.kind == "cleanse" then
        p.hp = math.min(p.maxHP, p.hp + item.amount)
    end
    if item.kind == "energy" then p.energy = math.min(p.maxEnergy,p.energy+item.amount) end
    if item.kind == "rest" then p.energy = math.min(p.maxEnergy,p.energy+6) end
    if item.kind == "cleanse" and battle then battle.glitch = 0 end
    if item.kind == "shield" then battle.guard = item.amount end
    if item.kind == "bond" then pet.bond = math.min(100,pet.bond+item.amount) end
    if item.kind == "curiosity" then
        pet.curiosity = math.min(100,pet.curiosity+item.amount)
    end
end

function Inventory.use(state, id, battle)
    local item = Items.get(id)
    if not item or not state.inventory[id] or state.inventory[id] < 1 then
        return false, "You do not have that item."
    end
    if item.kind == "key" then return false, "Keep this memory safe." end
    if item.kind == "shield" and not battle then return false, "Use during battle." end
    apply(state,item,battle)
    state.inventory[id] = state.inventory[id] - 1
    if state.inventory[id] == 0 then state.inventory[id] = nil end
    return true, item.name.." used."
end

function Inventory.list(state)
    local list = {}
    for _, id in ipairs(Items.order) do
        if (state.inventory[id] or 0) > 0 then list[#list+1] = id end
    end
    return list
end

return Inventory
