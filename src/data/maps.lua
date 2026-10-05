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
        objects=objects("ada", "forest", "seed"),
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
