local Maps = require("data.maps")
local State = require("core.state")
local World = {}

function World.tile(map, x, y)
    local data = Maps[map]
    if not data or not data.rows[y] or x < 1 or x > 16 then return "#" end
    return string.sub(data.rows[y], x, x)
end

function World.walkable(map, x, y)
    if World.tile(map, x, y) == "#" then return false end
    for _, object in ipairs(Maps[map].objects) do
        if object.x == x and object.y == y then return false end
    end
    return true
end

function World.move(state, dx, dy)
    if math.abs(dx) + math.abs(dy) ~= 1 then return false end
    local x, y = state.x + dx, state.y + dy
    if not World.walkable(state.map, x, y) then return false end
    state.x, state.y, state.steps = x, y, state.steps + 1
    for _, portal in ipairs(Maps[state.map].portals) do
        if portal.x == x and portal.y == y then
            state.map, state.x, state.y = portal.map, portal.tx, portal.ty
            state.steps = 0
            return "portal"
        end
    end
    return "step"
end

function World.interact(state)
    for _, object in ipairs(Maps[state.map].objects) do
        if math.abs(object.x-state.x) + math.abs(object.y-state.y) <= 1 then
            return object
        end
    end
    return nil
end

function World.encounter(state)
    if state.steps < 4 or World.tile(state.map,state.x,state.y) ~= "~" then return nil end
    if State.random(state, 5) ~= 1 then return nil end
    local list = Maps[state.map].encounters
    return list[State.random(state, #list)]
end

return World
