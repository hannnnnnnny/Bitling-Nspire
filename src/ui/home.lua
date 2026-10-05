local Animation = require("systems.animation")
local Home = {}

function Home.home(game,w)
    w:header("BITLING / MEMORY GARDEN","Lv."..game.data.player.level)
    w:text("A LIFE BEHIND THE NUMBERS",12,32,"dim",8)
    w:sprite(Animation.frame(game.data.pet.mood,game.tick),38,60,6)
    w:text("MOTE",58,139,"mint",11,90)
    w:text(game.data.pet.mood,40,156,"dim",9,110)
    for i,option in ipairs(game.home) do
        w:choice(option,159,51+(i-1)*23,w.w-171,game.selected==i)
    end
    local message=game.notice or (game.data.flags.ended and "The garden remembers you."
        or "Restore three nodes. Return to Ada.")
    w:text(message,12,w.h-40,"amber",9,w.w-24)
    w:footer("Arrows: choose    Enter: open    M: menu in world")
end

function Home.pet(game,w)
    local state=game.data
    w:header("MOTE / PET","Lv."..state.player.level)
    w:sprite(Animation.frame(state.pet.mood,game.tick),35,49,6)
    w:text(state.pet.mood,36,131,"mint",11,105)
    w:meter("Energy",state.player.energy,state.player.maxEnergy,158,42,w.w-170,"mint")
    w:meter("Bond",state.pet.bond,100,158,80,w.w-170,"amber")
    w:meter("Curiosity",state.pet.curiosity,100,158,118,w.w-170,"violet")
    local options={"Talk","Play","Rest"}
    for i,option in ipairs(options) do
        w:choice(option,9+(i-1)*math.floor((w.w-18)/3),w.h-64,
            math.floor((w.w-24)/3),game.selected==i)
    end
    w:text(game.message,12,w.h-39,"dim",9)
    w:footer("Arrows: choose    Enter: care    Esc: back")
end

function Home.menu(game,w)
    w:header("MEMORY MENU","MOTE")
    for i,option in ipairs(game.menu) do
        w:choice(option,45,31+(i-1)*23,w.w-90,game.selected==i)
    end
    w:footer("Arrows: choose    Enter: open    Esc: resume")
end

function Home.gameOver(game,w)
    w:header("SIGNAL LOST","RECOVERY")
    w:sprite("hurt",math.floor(w.w/2)-24,42,4)
    w:wrap("Mote's light flickers. A forest terminal kept your memories safe.",
        28,106,w.w-56,"text",11,3)
    w:text("Quest progress and items are kept.",28,w.h-50,"dim",9)
    w:footer("Enter: recover at Memory Forest")
end

return Home
