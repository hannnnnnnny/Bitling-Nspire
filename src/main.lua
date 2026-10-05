local Game = require("core.game")
local Input = require("core.input")
local Renderer = require("ui.renderer")
local game = Game.new()
local lastMood, lastFrame

local function invalidate()
    platform.window:invalidate()
end

local function dispatch(event)
    local action=Input.translate(event)
    if not action then return end
    game:input(action)
    invalidate()
end

function on.construction()
    timer.start(0.1)
end

function on.activate()
    game.active=true
    require("systems.pet").react(game.data,"return")
    timer.start(0.1)
end

function on.deactivate()
    game.active=false
    timer.stop()
end

function on.resize()
    invalidate()
end

function on.paint(gc)
    Renderer.paint(game,gc,platform.window:width(),platform.window:height())
end

function on.timer()
    if not game.active then return end
    game:update()
    local frame=require("systems.animation").frame(game.data.pet.mood,game.tick)
    if game.mode=="WORLD" or game.mode=="BATTLE" or frame~=lastFrame
        or game.data.pet.mood~=lastMood or game.tick%10==0 then invalidate() end
    lastMood,lastFrame=game.data.pet.mood,frame
end

function on.arrowKey(key) dispatch(key) end
function on.enterKey() dispatch("enter") end
function on.returnKey() dispatch("enter") end
function on.escapeKey() dispatch("escape") end
function on.charIn(char) dispatch(char) end
function on.save() return game:save() end
function on.restore(raw) game:restore(raw) end
