local Maps = require("data.maps")
local World = require("world.world")
local Animation = require("systems.animation")
local Screen = {}

local function wall(w,x,y,t,color)
    w:rect(x,y,t-1,t-1,"line")
    w:rect(x+2,y+2,t-5,t-5,color)
    w:rect(x+4,y+3,t-9,2,"dim")
    w:rect(x+math.floor(t/2),y+math.floor(t/2),2,t-4-math.floor(t/2),"panel")
end

local function object(w,obj,x,y,t,state,tick,color)
    if obj.kind=="npc" then w:sprite("npc",x+1,y+1,1)
    elseif obj.kind=="boss" then w:sprite("sentinel",x+1,y+1,1)
    elseif obj.kind=="node" then
        w:rect(x+3,y+2,t-6,t-4,state.flags[obj.id] and "mint" or color)
        w:rect(x+5,y+4,t-10,t-8,"ink")
        if tick%10<5 then w:rect(x+6,y+5,2,2,"text") end
    elseif obj.kind=="rest" then
        w:rect(x+2,y+2,t-4,t-4,"dim")
        w:rect(x+4,y+4,t-8,t-9,"mint")
        w:rect(x+5,y+t-5,t-10,1,"ink")
    elseif not state.flags[obj.id] then
        w:rect(x+math.floor(t/2),y+t-4,2,1,"amber")
    end
end

function Screen.paint(game,w)
    local state=game.data
    local map=Maps[state.map]
    local t=math.min(16,math.floor((w.h-52)/11))
    local ox,oy=math.floor((w.w-16*t)/2),25
    w:header(map.name,"HP "..state.player.hp)
    for y,row in ipairs(map.rows) do
        for x=1,#row do
            local px,py=ox+(x-1)*t,oy+(y-1)*t
            local tile=string.sub(row,x,x)
            if tile=="#" then wall(w,px,py,t,map.color)
            elseif tile=="~" then
                w:rect(px,py,t-1,t-1,"panel")
                w:rect(px+3,py+5,t-6,1,"violet")
                w:rect(px+5,py+9,t-8,1,"dim")
            else w:rect(px,py,t-1,t-1,"bg") end
        end
    end
    for _,portal in ipairs(map.portals) do
        w:rect(ox+(portal.x-1)*t+3,oy+(portal.y-1)*t+2,t-6,t-4,"violet")
    end
    for _,obj in ipairs(map.objects) do
        object(w,obj,ox+(obj.x-1)*t,oy+(obj.y-1)*t,t,state,game.tick,map.color)
    end
    w:sprite(Animation.frame(game.walk>0 and "walk" or "idle",game.tick),
        ox+(state.x-1)*t+1,oy+(state.y-1)*t+1,1)
    local nearby=World.interact(state)
    w:footer(nearby and ("Enter: "..(nearby.kind=="cache" and "search" or nearby.kind).."    M: menu")
        or "Arrows: move    Enter: interact    M: menu")
end

return Screen
