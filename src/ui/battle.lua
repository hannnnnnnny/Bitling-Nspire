local Skills = require("data.skills")
local Items = require("data.items")
local Animation = require("systems.animation")
local Battle = {}
local actions={"Attack","Skill","Item","Run"}

local function choices(game,w,y)
    local list=game.sub=="skill" and Skills.order or game.list
    if not game.sub then
        for i,name in ipairs(actions) do
            local column=(i-1)%2
            local row=math.floor((i-1)/2)
            w:choice(name,12+column*math.floor(w.w/2),y+row*23,
                math.floor(w.w/2)-24,game.selected==i)
        end
    elseif #list==0 then w:text("No usable items.",12,y,"dim",10)
    else
        local start=math.max(1,game.selected-1)
        for i=start,math.min(#list,start+1) do
            local id=list[i]
            local data=game.sub=="skill" and Skills[id] or Items[id]
            local suffix=game.sub=="skill" and (" ["..data.cost.." E]")
                or (" x"..game.data.inventory[id])
            w:choice(data.name..suffix,12,y+(i-start)*23,w.w-24,game.selected==i)
        end
    end
end

function Battle.paint(game,w)
    local b,state=game.battle,game.data
    w:header(b.enemy.name,b.enemy.boss and "BOSS" or "ERROR")
    local frame=(game.effect or 0)>0 and game.action or state.pet.mood
    w:sprite(Animation.frame(frame,game.tick),28,32,3)
    w:sprite(b.enemy.sprite,w.w-75,32+(game.tick%10<5 and 0 or 1),3)
    w:meter("HP",state.player.hp,state.player.maxHP,12,75,135,"mint")
    w:meter("Enemy",b.hp,b.enemy.hp,w.w-145,75,133,"red")
    w:text("Energy "..state.player.energy.." / "..state.player.maxEnergy,12,99,"amber",9)
    if b.revealed then
        w:text("DEF "..b.defense.." / weak "..Skills[b.enemy.weakness].name,
            w.w-145,99,"violet",7,133)
    end
    w:text(b.message,12,110,"text",9,w.w-24)
    w:text(b.reply,12,125,"dim",7,w.w-24)
    if b.done then
        local message=b.done=="won" and ("+"..b.enemy.xp.." XP  /  "..Items[b.enemy.drop].name)
            or (b.done=="lost" and "Mote needs a recovery terminal." or "Back to the garden.")
        w:text(message,12,161,"mint",10)
        w:footer("Enter: continue")
    else
        choices(game,w,w.h-70)
        w:footer("Arrows: choose    Enter: act    Esc: cancel")
    end
end

return Battle
