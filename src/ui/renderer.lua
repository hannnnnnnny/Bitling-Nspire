local W = require("ui.widgets")
local Home = require("ui.home")
local World = require("ui.world")
local Battle = require("ui.battle")
local Details = require("ui.details")
local Renderer = {}
local screens={HOME=Home.home,PET=Home.pet,MENU=Home.menu,GAME_OVER=Home.gameOver,
    WORLD=World.paint,BATTLE=Battle.paint,INVENTORY=Details.inventory,
    STATUS=Details.status,SAVE=Details.save,DIALOGUE=Details.dialogue}

function Renderer.paint(game,gc,width,height)
    local w=W.new(gc,width,height)
    w:rect(0,0,width,height,"bg")
    if width<280 or height<200 then
        w:wrap("Bitling needs a full-page view. Restore the single-page layout.",
            8,8,width-16,"mint",10,5)
        return
    end
    if screens[game.mode] then screens[game.mode](game,w)
    else w:text("Initializing memory...",10,32,"mint",11) end
end

return Renderer
