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
