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
