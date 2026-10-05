local Items = require("data.items")
local Progression = require("systems.progression")
local Details = {}

function Details.inventory(game,w)
    w:header("INVENTORY","ITEMS")
    if #game.list==0 then w:text("Your pockets are quiet.",20,58,"dim",11)
    else
        local start=math.max(1,game.selected-3)
        for i=start,math.min(#game.list,start+4) do
            local id=game.list[i]
            w:choice(Items[id].name.." x"..game.data.inventory[id],12,31+(i-start)*23,
                w.w-24,game.selected==i)
        end
        local item=Items[game.list[game.selected]]
        w:text(item.description,12,w.h-59,"amber",9)
    end
    w:text(game.message,12,w.h-38,"dim",8)
    w:footer("Arrows: choose    Enter: use    Esc: back")
end

function Details.status(game,w)
    local s=game.data
    w:header("MOTE / STATUS","Lv."..s.player.level)
    w:meter("HP",s.player.hp,s.player.maxHP,14,33,135,"mint")
    w:meter("Energy",s.player.energy,s.player.maxEnergy,w.w-153,33,135,"amber")
    w:text("Logic "..s.player.logic.."    Focus "..s.player.focus,14,68,"text",10)
    w:text("XP "..s.player.xp.." / "..Progression.threshold(s.player.level),
        14,91,"violet",10)
    w:text("Bond "..s.pet.bond.."    Curiosity "..s.pet.curiosity,w.w-160,91,"text",9)
    local nodes=(s.flags.forest and 1 or 0)+(s.flags.valley and 1 or 0)+(s.flags.matrix and 1 or 0)
    w:text("Memory nodes: "..nodes.." / 3",14,117,"mint",11)
    w:text(s.flags.ended and "Garden restored. Thank you."
        or (s.flags.boss and "Return to Ada in Memory Forest."
        or "Goal: restore nodes; quiet the sentinel."),14,145,"amber",9)
    w:text("Active age: "..math.floor(s.pet.age/60).." min   Pet XP: "..s.pet.experience,
        14,w.h-41,"dim",9)
    w:footer("Enter / Esc: back")
end

function Details.save(game,w)
    w:header("SAVE MEMORY","DOCUMENT")
    w:text("Save this game document",18,39,"mint",12)
    w:wrap("On the calculator, press Ctrl+S now. The TI document stores your game through on.save.",
        18,69,w.w-36,"text",10,3)
    w:wrap("Then close and reopen this same document to continue. Desktop simulator: Ctrl+S writes its own JSON save.",
        18,126,w.w-36,"dim",9,3)
    w:footer("Ctrl+S: persist    Esc: return")
end

function Details.dialogue(game,w)
    w:header("MEMORY SIGNAL",game.line.."/"..#game.lines)
    w:sprite(game.data.flags.ended and "happy" or "npc",15,39,2)
    w:rect(49,35,w.w-63,w.h-72,"panel")
    w:wrap(game.lines[game.line],60,49,w.w-85,"text",11,7)
    w:footer("Enter: next    Esc: close")
end

return Details
