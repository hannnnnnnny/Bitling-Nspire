-- Bitling-Nspire: Memory Garden | stock TI-Nspire CX CAS | API 2.0
platform.apiLevel = "2.0"
local factories, loaded = {}, {}
local function require(name)
  if loaded[name] then return loaded[name] end
  assert(factories[name], 'Unknown module: '..name)
  loaded[name] = factories[name]()
  return loaded[name]
end
factories["core.game"] = function()
local State = require("core.state")
local Save = require("core.save")
local World = require("world.world")
local Inventory = require("systems.inventory")
local Progression = require("systems.progression")
local Combat = require("systems.combat")
local Pet = require("systems.pet")
local Dialogue = require("systems.dialogue")
local Skills = require("data.skills")
local Game = {}
Game.__index = Game
local home = {"Explore","Pet","Inventory","Status","Save"}
local menu = {"Resume","Pet","Inventory","Status","Save","Home"}
local modes = {BOOT=true,HOME=true,PET=true,WORLD=true,BATTLE=true,MENU=true,
    INVENTORY=true,DIALOGUE=true,GAME_OVER=true,STATUS=true,SAVE=true}
local directions = {LEFT={-1,0},RIGHT={1,0},UP={0,-1},DOWN={0,1}}

function Game.new()
    local self = setmetatable({data=State.new(),mode="BOOT",selected=1,tick=0,
        message="A tiny life behind the numbers.",returnTo="HOME",walk=0,
        active=true,dialogueProvider=Dialogue,notice="New memory. No saved game yet."},Game)
    self:transition("HOME")
    return self
end

function Game:transition(mode)
    assert(modes[mode],"Unknown screen")
    self.mode,self.selected=mode,1
end

function Game:open(mode)
    self.returnTo=self.mode
    self:transition(mode)
    if mode == "INVENTORY" then self.list=Inventory.list(self.data) end
end

function Game:say(lines, back)
    self.lines,self.line,self.dialogueBack=lines,1,back or self.mode
    self:transition("DIALOGUE")
end

function Game:explore()
    self:transition("WORLD")
    if not self.data.flags.started then
        self.data.flags.started=true
        self:say(self.dialogueProvider.lines("boot",self.data),"WORLD")
    end
end

function Game:startBattle(id)
    self.battle=Combat.new(self.data,id)
    self.sub=nil
    self:transition("BATTLE")
end

function Game:perform(action, id)
    local b=self.battle
    if not Combat.act(b,action,id) then return false end
    self.sub,self.selected,self.effect=nil,1,3
    self.action=action=="item" and "happy" or "attack"
    if b.done == "won" then
        Combat.reward(self.data,b)
        Pet.react(self.data,(b.levels or 0)>0 and "level" or "win")
    elseif b.done == "lost" then Pet.react(self.data,"loss") end
    return true
end

local function interact(self, object)
    local state=self.data
    if object.kind == "npc" then
        if object.id == "ada" and state.flags.boss and not state.flags.ended then
            state.flags.ended=true
            Inventory.add(state,"seed",1)
            Pet.react(state,"rare")
            self:say(self.dialogueProvider.lines("ending",state),"WORLD")
        else self:say(self.dialogueProvider.lines(object.id,state),"WORLD") end
    elseif object.kind == "rest" then
        state.player.hp,state.player.energy=state.player.maxHP,state.player.maxEnergy
        Pet.react(state,"return")
        self:say({"Terminal synchronized. HP and energy restored."},"WORLD")
    elseif object.kind == "boss" then
        if state.flags.boss then self:say({"The sentinel rests. Return to Ada."},"WORLD")
        elseif state.flags.forest and state.flags.valley and state.flags.matrix then
            self:startBattle(object.id)
        else self:say({"Three nodes must be restored before the sentinel can listen."},"WORLD") end
    else
        if state.flags[object.id] then self:say({"This memory is already safe."},"WORLD"); return end
        state.flags[object.id]=true
        if object.kind == "node" then
            Inventory.add(state,"fragment",1)
            local gained=Progression.addXP(state,20)
            Pet.react(state,gained>0 and "level" or "node")
            self:say({"Node restored. +20 XP and one Node Fragment.",
                      "A signal points toward the other realms."},"WORLD")
        else
            Inventory.add(state,object.item,1)
            Pet.react(state,"rare")
            self:say({"A hidden cache! Check your inventory."},"WORLD")
        end
    end
end

local function worldInput(self,key)
    if key == "MENU" or key == "BACK" then self:open("MENU"); return end
    if key == "ENTER" then
        local object=World.interact(self.data)
        if object then interact(self,object) else self.message="No signal nearby." end
        return
    end
    local dir=directions[key]
    if not dir then return end
    local result=World.move(self.data,dir[1],dir[2])
    if not result then self.message="That memory is solid."; return end
    self.walk,self.message=4,"Enter: interact    M: menu"
    if result=="portal" then return end
    local id=World.encounter(self.data)
    if id then self:startBattle(id) end
end

local function selection(self,key,count)
    if key == "UP" or key == "LEFT" then self.selected=(self.selected-2)%count+1
    elseif key == "DOWN" or key == "RIGHT" then self.selected=self.selected%count+1 end
end

local function menuInput(self,key)
    local options=self.mode=="HOME" and home or menu
    selection(self,key,#options)
    if key=="BACK" and self.mode=="MENU" then self:transition("WORLD"); return end
    if key~="ENTER" then return end
    local choice=options[self.selected]
    if choice=="Explore" or choice=="Resume" then self:explore()
    elseif choice=="Home" then self:transition("HOME")
    else
        local back=self.mode=="MENU" and "WORLD" or "HOME"
        self:open(string.upper(choice))
        self.returnTo=back
    end
end

local function battleInput(self,key)
    local b=self.battle
    if b.done then
        if key=="ENTER" then
            self:transition(b.done=="lost" and "GAME_OVER" or "WORLD")
        end
        return
    end
    if key=="BACK" or key=="MENU" then self.sub=nil; self.selected=1; return end
    local list=self.sub=="skill" and Skills.order or self.list
    selection(self,key,self.sub and math.max(1,#list) or 4)
    if key~="ENTER" then return end
    if self.sub then
        if #list>0 then self:perform(self.sub,list[self.selected]) end
    elseif self.selected==1 then self:perform("attack")
    elseif self.selected==4 then self:perform("run")
    else
        self.sub=self.selected==2 and "skill" or "item"
        self.selected,self.list=1,Inventory.list(self.data)
    end
end

local function petInput(self,key)
    selection(self,key,3)
    if key=="ENTER" then
        local actions={"talk","play","rest"}
        local _,message=Pet.interact(self.data,actions[self.selected])
        self.message=message
    elseif key=="BACK" then self:transition(self.returnTo) end
end

local function inventoryInput(self,key)
    selection(self,key,math.max(1,#self.list))
    if key=="BACK" then self:transition(self.returnTo)
    elseif key=="ENTER" and #self.list>0 then
        local _,message=Inventory.use(self.data,self.list[self.selected])
        self.message=message
        self.list=Inventory.list(self.data)
        self.selected=math.min(self.selected,math.max(1,#self.list))
    end
end

local function dialogueInput(self,key)
    if key=="ENTER" then
        self.line=self.line+1
        if self.line>#self.lines then self:transition(self.dialogueBack) end
    elseif key=="BACK" then self:transition(self.dialogueBack) end
end

local function recover(self,key)
    if key~="ENTER" then return end
    self.data.map,self.data.x,self.data.y="forest",3,5
    self.data.player.hp=self.data.player.maxHP
    self.data.player.energy=math.ceil(self.data.player.maxEnergy/2)
    self.battle=nil
    self.message="A terminal kept your memory safe."
    self:transition("HOME")
end

local handlers={HOME=menuInput,MENU=menuInput,WORLD=worldInput,
    BATTLE=battleInput,PET=petInput,INVENTORY=inventoryInput,
    DIALOGUE=dialogueInput,GAME_OVER=recover}

function Game:input(key)
    if not key then return end
    self.data.pet.idle=0
    if handlers[self.mode] then handlers[self.mode](self,key)
    elseif key=="BACK" or key=="ENTER" then self:transition(self.returnTo) end
end

function Game:update()
    if not self.active then return end
    self.tick,self.data.ticks=self.tick+1,self.data.ticks+1
    self.walk=math.max(0,self.walk-1)
    self.effect=math.max(0,(self.effect or 0)-1)
    if self.mode~="BATTLE" then Pet.tick(self.data,0.1)
    else self.data.pet.age=self.data.pet.age+0.1 end
end

function Game:save()
    return Save.encode(self.data)
end

function Game:restore(raw)
    self.data,self.notice=Save.decode(raw)
    Pet.react(self.data,"return")
    self.battle,self.sub=nil,nil
    self:transition("HOME")
end

Game.home,Game.menu=home,menu
return Game

end
factories["core.input"] = function()
local Input = {}
local mapping = {
    up="UP", down="DOWN", left="LEFT", right="RIGHT",
    enter="ENTER", escape="BACK", menu="MENU",
    ["8"]="UP", ["2"]="DOWN", ["4"]="LEFT", ["6"]="RIGHT",
    ["5"]="ENTER", ["0"]="BACK", m="MENU"
}

function Input.translate(event)
    if type(event) ~= "string" then return nil end
    return mapping[string.lower(event)]
end

return Input

end
factories["core.save"] = function()
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
        if Items.get(id) then
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

end
factories["core.state"] = function()
local State = {}

function State.new()
    return {
        player = {hp=36, maxHP=36, energy=24, maxEnergy=24, logic=7,
                  focus=5, level=1, xp=0},
        pet = {mood="idle", bond=10, curiosity=5, experience=0,
               age=0, idle=0, emotion=0, cooldown=0},
        inventory = {patch=5, cell=3},
        flags = {}, map="forest", x=3, y=5,
        ticks=0, steps=0, seed=1701
    }
end

function State.random(state, limit)
    -- Small exact-in-double generator: repeatable without Lua bit libraries.
    state.seed = (state.seed * 16807) % 2147483647
    return state.seed % limit + 1
end

return State

end
factories["data.enemies"] = function()
return {
    syntax={name="Syntax Moth", hp=22, logic=6, defense=2, focus=2,
        pattern={"hit","glitch","hit"}, weakness="factor", sprite="syntax",
        animation="blink", xp=12, drop="patch"},
    overflow={name="Overflow Bell", hp=30, logic=8, defense=3, focus=3,
        pattern={"charge","hit","hit"}, weakness="solve", sprite="overflow",
        animation="idle", xp=18, drop="cell"},
    variable={name="Variable Wisp", hp=34, logic=9, defense=4, focus=4,
        pattern={"drain","hit","glitch"}, weakness="factor", sprite="variable",
        animation="blink", xp=22, drop="tonic"},
    loop={name="Loop Knot", hp=40, logic=10, defense=3, focus=4,
        pattern={"hit","hit","charge"}, weakness="solve", sprite="loop",
        animation="idle", xp=25, drop="treat"},
    leak={name="Memory Drip", hp=44, logic=11, defense=5, focus=4,
        pattern={"siphon","drain","hit"}, weakness="factor", sprite="leak",
        animation="idle", xp=28, drop="root"},
    sentinel={name="Null Sentinel", hp=106, logic=13, defense=7, focus=6,
        pattern={"charge","hit","glitch","drain","siphon"}, weakness="solve",
        sprite="sentinel", animation="blink", xp=70, drop="core", boss=true}
}

end
factories["data.items"] = function()
local Items = {
    order={"patch","cell","root","tonic","shield","lens","treat","fragment","core","seed"},
    patch={name="Byte Patch", kind="heal", amount=24, description="Restore 24 HP."},
    cell={name="Charge Cell", kind="energy", amount=16, description="Restore 16 energy."},
    root={name="Root Packet", kind="rest", amount=12, description="Heal 12 HP + 6 energy."},
    tonic={name="Clear Tonic", kind="cleanse", amount=10, description="Clear glitch + heal 10."},
    shield={name="Guard Shell", kind="shield", amount=3, description="Guard next 3 enemy turns."},
    lens={name="Curio Lens", kind="curiosity", amount=8, description="Raise curiosity by 8."},
    treat={name="Mint Treat", kind="bond", amount=8, description="Raise bond by 8."},
    fragment={name="Node Fragment", kind="key", description="Proof of a restored node."},
    core={name="Quiet Core", kind="key", description="The sentinel is at peace."},
    seed={name="Memory Seed", kind="key", description="A garden's new beginning."}
}

function Items.get(id)
    if type(id) ~= "string" then return nil end
    local item=Items[id]
    if type(item)=="table" and item.kind then return item end
    return nil
end

return Items

end
factories["data.maps"] = function()
local function objects(npc, node, item)
    return {
        {kind="npc", id=npc, x=4, y=3},
        {kind="rest", id="rest", x=3, y=7},
        {kind="node", id=node, x=10, y=3},
        {kind="cache", id=node.."_cache", item=item, x=12, y=8}
    }
end

local maps = {
    forest = {
        name="Memory Forest", color="mint",
        rows={"################", "#..............#", "#...##.........#",
              "#..............#", "#..............#", "#..............#",
              "#####..###..####", "#.....~~~~.....#", "#.....~~~~.....#",
              "#..............#", "################"},
        objects=objects("ada", "forest", "root"),
        portals={{x=15,y=5,map="valley",tx=3,ty=5}},
        encounters={"syntax", "overflow"}
    },
    valley = {
        name="Graph Valley", color="amber",
        rows={"################", "#..............#", "#......##......#",
              "#..............#", "#..~......~....#", "#..............#",
              "####...###...###", "#.....~~~~.....#", "#.....~~~~.....#",
              "#..............#", "################"},
        objects=objects("tess", "valley", "lens"),
        portals={{x=2,y=5,map="forest",tx=14,ty=5},
                 {x=15,y=5,map="matrix",tx=3,ty=5}},
        encounters={"variable", "loop"}
    },
    matrix = {
        name="Matrix Dungeon", color="violet",
        rows={"################", "#..............#", "#.....#........#",
              "#..............#", "#.....#........#", "#..............#",
              "####...###...###", "#.....~~~~.....#", "#.....~~~~.....#",
              "#..............#", "################"},
        objects=objects("rowan", "matrix", "shield"),
        portals={{x=2,y=5,map="valley",tx=14,ty=5}},
        encounters={"leak", "loop", "variable"}
    }
}
maps.matrix.objects[5] = {kind="boss", id="sentinel", x=13, y=5}
return maps

end
factories["data.skills"] = function()
local Skills = {
    order={"factor","solve","graph","analyze","debug"},
    factor={name="Factor", cost=3, description="Break defense; chip damage."},
    solve={name="Solve", cost=5, description="Heavy logic damage."},
    graph={name="Graph", cost=2, description="Reveal stats; expose weakness."},
    analyze={name="Analyze", cost=2, description="Double next damaging action."},
    debug={name="Debug", cost=3, description="Clear glitch; heal 12 HP."}
}

function Skills.get(id)
    if type(id)~="string" then return nil end
    local skill=Skills[id]
    if type(skill)=="table" and type(skill.cost)=="number" then return skill end
    return nil
end

return Skills

end
factories["data.sprites"] = function()
local pet = {
    "............","...1....1...","...11..11...","..11111111..",
    ".1112222111.",".1122222211.",".1123223211.",".1122222211.",
    "..11233211..","...111111...","...11..11...","............"
}
local sprites = {
    idle=pet,
    syntax={"............","..5......5..",".555....555.","..555..555..",
        "...553355...","....5335....","...555555...", "..55.55.55..",
        ".55..55..55.","......5.....",".....5......","............"},
    overflow={"....4444....","...444444...","..44111444..",".4441111444.",
        ".4413113144.",".4441111444.", "..44444444..","...444444...",
        "....4..4....","...44..44...","..44....44..","............"},
    variable={"............",".....55.....","....5555....","...552255...",
        "..55233255..","...552255...","....5555....",".....55.....",
        "....5.......",".....5......","......55....","............"},
    loop={"............","...444444...", "..44....44..",".44..44..44.",
        ".44.4334.44.",".44..44..44.","..44....44..","...444444...",
        "....4..4....","...44..44...","............","............"},
    leak={".....1......","....111.....","...11111....","..1111111...",
        "..1122211...","..1132311...","..1122211...","...11111....",
        "....111.....",".....1......","...11..11...","............"},
    sentinel={"..5......5..","..55555555..",".5555555555.",".5522222255.",
        ".5523223255.",".5522222255.",".5555445555.", "..55444455..",
        "..55.55.55..",".55..55..55.",".55......55.","............"},
    npc={".....44.....","....4444....","...422224...", "...423324...",
        "....4444....","...555555...","..55555555..","..55555555..",
        "...555555...","....5..5....","...55..55...","............"}
}

local function variant(name, edits)
    local copy={}
    for i,row in ipairs(pet) do copy[i]=edits[i] or row end
    sprites[name]=copy
end
variant("blink",{[7]=".1123333211."})
variant("walk1",{[11]="..11....11.."})
variant("walk2",{[10]="...111111...",[11]="....11.11..."})
variant("happy",{[7]=".1124224211.",[9]="..11222211.."})
variant("hurt",{[7]=".1126226211.",[9]="..11233211..",[2]="...1........"})
variant("attack",{[2]="...4....4...",[7]=".1124224211.",[11]="..44....44.."})
return sprites

end
factories["systems.animation"] = function()
local Animation = {}

function Animation.frame(action, tick)
    if action == "walk" then return tick % 6 < 3 and "walk1" or "walk2" end
    if action == "idle" then return tick % 30 == 29 and "blink" or "idle" end
    if action == "excited" or action == "curious" then return "happy" end
    if action == "sad" or action == "angry" then return "hurt" end
    if action == "sleepy" then return "blink" end
    if action == "thinking" then return "idle" end
    return action
end

return Animation

end
factories["systems.combat"] = function()
local Enemies = require("data.enemies")
local Skills = require("data.skills")
local State = require("core.state")
local Inventory = require("systems.inventory")
local Progression = require("systems.progression")
local Combat = {}

function Combat.new(state, id)
    local enemy = assert(Enemies[id], "Unknown enemy")
    return {state=state, id=id, enemy=enemy, hp=enemy.hp, defense=enemy.defense,
            turn=0, boost=0, guard=0, glitch=0, charge=0, revealed=false,
            message="A "..enemy.name.." appears.", reply="Choose an action."}
end

local function damage(battle, amount, skill)
    local value = math.max(1, amount - battle.defense)
    if battle.boost > 0 then value, battle.boost = value*2, 0 end
    if skill == battle.enemy.weakness then
        value = value + (battle.revealed and 8 or 4)
    end
    battle.hp = math.max(0,battle.hp-value)
    return value
end

local function skill(b, id)
    local p = b.state.player
    if id == "factor" then
        b.defense = math.max(0,b.defense-3)
        b.message = "Factor: "..damage(b,p.focus+3,id).." damage; armor breaks."
    elseif id == "solve" then
        b.message = "Solve: "..damage(b,p.logic*2+3,id).." damage."
    elseif id == "graph" then
        b.revealed = true
        b.message = "Graph: weak to "..Skills[b.enemy.weakness].name.."."
    elseif id == "analyze" then
        b.boost = 2
        b.message = "Analyze: next hit deals double."
    elseif id == "debug" then
        b.glitch = 0
        p.hp = math.min(p.maxHP,p.hp+12)
        b.message = "Debug: glitch cleared; +12 HP."
    end
end

local function enemyTurn(b)
    local p = b.state.player
    local action = b.enemy.pattern[(b.turn-1) % #b.enemy.pattern+1]
    if action == "charge" then
        b.charge, b.reply = 5, "Enemy gathers a pulse..."
        return
    end
    local value = math.max(1,b.enemy.logic-math.floor(p.focus/2)+b.charge)
    b.charge = 0
    if b.guard > 0 then value, b.guard = math.ceil(value/2), b.guard-1 end
    if action == "glitch" then b.glitch = 2 end
    if action == "drain" then p.energy = math.max(0,p.energy-3) end
    if action == "siphon" then b.hp = math.min(b.enemy.hp,b.hp+4) end
    if b.glitch > 0 then value, b.glitch = value+2,b.glitch-1 end
    p.hp = math.max(0,p.hp-value)
    b.reply = b.enemy.name..": "..action.." (-"..value.." HP)."
    if p.hp == 0 then b.done = "lost" end
end

local function playerAction(b, action, id)
    local p = b.state.player
    if action == "attack" then
        local power = 8+p.level+math.floor(b.state.pet.bond/25)
        b.message = "Pulse: "..damage(b,power).." damage."
    elseif action == "skill" then
        if not Skills.get(id) then return false end
        if p.energy < Skills[id].cost then
            b.message = "Not enough energy. Use a cell."
            return false
        end
        p.energy = p.energy-Skills[id].cost
        skill(b,id)
    elseif action == "item" then
        local ok, message = Inventory.use(b.state,id,b)
        b.message = message
        if not ok then return false end
    elseif action == "run" then
        if b.enemy.boss then b.message="The sentinel blocks escape."; return false end
        if State.random(b.state,4) ~= 1 then b.done="ran"; b.message="Escaped safely."
        else b.message="Escape failed." end
    else return false end
    return true
end

function Combat.act(b, action, id)
    if b.done then return false end
    if not playerAction(b,action,id) then return false end
    b.turn = b.turn+1
    if b.hp == 0 then b.done="won"; b.reply="Memory restored. Enter to continue." end
    if not b.done then enemyTurn(b) end
    return true
end

function Combat.reward(state, b)
    if b.done ~= "won" or b.rewarded then return false end
    b.rewarded = true
    b.levels = Progression.addXP(state,b.enemy.xp)
    state.pet.experience = state.pet.experience+b.enemy.xp
    Inventory.add(state,b.enemy.drop,1)
    if b.enemy.boss then state.flags.boss = true end
    return true
end

return Combat

end
factories["systems.dialogue"] = function()
local LocalDialogueProvider = {}
local lines = {
    boot={"You wake behind the numbers. Your name is Mote.",
          "Three memory nodes have gone quiet. Find the caretakers; restore the garden.",
          "Arrows move. Enter interacts. M opens your menu. Blue ripples hide errors."},
    ada={"I am Ada, the garden archivist. The mint node is northeast of here.",
         "Restore a node in each realm. Then quiet the Null Sentinel in Matrix Dungeon.",
         "Return to me when the garden remembers. Terminals heal you for free."},
    tess={"I am Tess. This valley used to draw constellations.",
          "Graph reveals weaknesses. Analyze doubles your next damaging action.",
          "The amber node is northeast. The east portal leads to Matrix Dungeon."},
    rowan={"I am Rowan, keeper of the rows. Our violet node still has a pulse.",
           "The sentinel waits to the east. All three nodes must be awake.",
           "Factor breaks armor. Debug clears glitch. Heal before a heavy pulse."},
    ending={"The sentinel's noise becomes a quiet heartbeat.",
            "Ada plants a Memory Seed. The garden is alive because you listened.",
            "MEMORY GARDEN RESTORED. Keep exploring; Mote's story continues."}
}

function LocalDialogueProvider.lines(id, state)
    if id == "ada" and state.flags.ended then
        return {"Your Memory Seed is growing. There is room for more worlds."}
    end
    return lines[id] or {"A quiet signal. No words yet."}
end

return LocalDialogueProvider

end
factories["systems.inventory"] = function()
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

end
factories["systems.pet"] = function()
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

end
factories["systems.progression"] = function()
local Progression = {}

function Progression.threshold(level)
    return level * 30
end

function Progression.stats(level)
    return {maxHP=36+(level-1)*6, maxEnergy=24+(level-1)*3,
            logic=7+(level-1)*2, focus=5+(level-1)}
end

function Progression.addXP(state, amount)
    if type(amount) ~= "number" or amount ~= amount or amount < 0
        or amount > 100000 or amount % 1 ~= 0 then return 0 end
    local p, gained = state.player, 0
    p.xp = p.xp + amount
    while p.level < 20 and p.xp >= Progression.threshold(p.level) do
        p.xp = p.xp - Progression.threshold(p.level)
        p.level, gained = p.level + 1, gained + 1
    end
    if p.level == 20 then p.xp = 0 end
    if gained > 0 then
        for key,value in pairs(Progression.stats(p.level)) do p[key] = value end
        p.hp, p.energy = p.maxHP, p.maxEnergy
    end
    return gained
end

return Progression

end
factories["ui.battle"] = function()
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

end
factories["ui.details"] = function()
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
    w:text(game.message,12,w.h-38,"dim",7)
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

end
factories["ui.home"] = function()
local Animation = require("systems.animation")
local Home = {}

function Home.home(game,w)
    w:header("BITLING / MEMORY GARDEN","Lv."..game.data.player.level)
    w:text("A LIFE BEHIND THE NUMBERS",12,32,"dim",7)
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

end
factories["ui.renderer"] = function()
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

end
factories["ui.widgets"] = function()
local Sprites = require("data.sprites")
local W = {}
W.__index = W
local palette = {
    bg={15,23,36},panel={25,37,53},ink={5,13,24},text={221,234,233},
    dim={132,156,166},mint={107,218,180},amber={245,190,96},
    violet={157,139,220},red={236,123,133},line={49,68,85}
}
local spriteColors = {["1"]="mint",["2"]="text",["3"]="ink",["4"]="amber",
                      ["5"]="violet",["6"]="red"}
local cache={}

local function compile(rows)
    local runs={}
    for y,row in ipairs(rows) do
        local x=1
        while x<=#row do
            local pixel=string.sub(row,x,x)
            local finish=x+1
            while finish<=#row and string.sub(row,finish,finish)==pixel do finish=finish+1 end
            if spriteColors[pixel] then
                runs[#runs+1]={x=x-1,y=y-1,width=finish-x,color=spriteColors[pixel]}
            end
            x=finish
        end
    end
    return runs
end
for name,rows in pairs(Sprites) do cache[name]=compile(rows) end

function W.new(gc,width,height)
    return setmetatable({gc=gc,w=width,h=height},W)
end

function W:color(name)
    local p=palette[name] or palette.text
    self.gc:setColorRGB(p[1],p[2],p[3])
end

function W:rect(x,y,width,height,color,outline)
    self:color(color)
    if outline then self.gc:drawRect(x,y,width,height)
    else self.gc:fillRect(x,y,width,height) end
end

function W:text(text,x,y,color,size,maxWidth)
    self:color(color or "text")
    self.gc:setFont("sansserif","r",size or 10)
    text=tostring(text)
    local width=maxWidth or self.w-x-8
    if self.gc:getStringWidth(text)>width then
        while #text>0 and self.gc:getStringWidth(text.."...")>width do
            text=string.sub(text,1,-2)
        end
        text=text.."..."
    end
    self.gc:drawString(text,x,y,"top")
end

function W:wrap(text,x,y,width,color,size,limit)
    self.gc:setFont("sansserif","r",size or 10)
    local line,count="",0
    for word in string.gmatch(text,"%S+") do
        local candidate=line=="" and word or line.." "..word
        if self.gc:getStringWidth(candidate)>width and line~="" then
            self:text(line,x,y,color,size,width)
            y,count=y+17,count+1
            line=word
            if count>=(limit or 5) then return end
        else line=candidate end
    end
    if line~="" then self:text(line,x,y,color,size,width) end
end

function W:sprite(name,x,y,scale)
    for _,run in ipairs(cache[name] or cache.idle) do
        self:rect(x+run.x*scale,y+run.y*scale,run.width*scale,scale,run.color)
    end
end

function W:meter(label,value,maximum,x,y,width,color)
    self:text(label.." "..math.floor(value).."/"..maximum,x,y,"dim",9,width)
    self:rect(x,y+16,width,5,"line")
    self:rect(x,y+16,math.floor(width*math.max(0,math.min(value/maximum,1))),5,color)
end

function W:header(title,right)
    self:rect(0,0,self.w,24,"panel")
    self:text(title,9,5,"mint",10,self.w-110)
    if right then self:text(right,self.w-100,6,"text",9,92) end
end

function W:footer(text)
    self:rect(0,self.h-21,self.w,21,"panel")
    self:text(text,8,self.h-17,"dim",9,self.w-16)
end

function W:choice(text,x,y,width,chosen)
    if chosen then self:rect(x,y,width,21,"line") end
    self:text((chosen and "> " or "  ")..text,x+4,y+3,chosen and "mint" or "text",10,width-8)
end

W.palette=palette
return W

end
factories["ui.world"] = function()
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

end
factories["world.world"] = function()
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

end
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

