import unittest
from support import engine


class RenderTests(unittest.TestCase):
    def test_all_screens_render_with_official_graphics_surface(self):
        lua, req = engine()
        game = req("core.game").new()
        renderer = req("ui.renderer")
        gc = lua.execute("""
            local gc={calls=0}
            function gc:setColorRGB(r,g,b) assert(r and g and b) end
            function gc:setFont(f,s,n)
                local sizes={[7]=true,[9]=true,[10]=true,[11]=true,[12]=true,[24]=true}
                assert(f=="sansserif" and sizes[n], "Unsupported Gen1 font size")
            end
            function gc:fillRect(x,y,w,h) assert(w>=0 and h>=0); self.calls=self.calls+1 end
            function gc:drawRect(x,y,w,h) assert(w>=0 and h>=0); self.calls=self.calls+1 end
            function gc:drawString(s,x,y,a) assert(type(s)=="string"); self.calls=self.calls+1 end
            function gc:getStringWidth(s) return #s*6 end
            return gc
        """)
        for width,height in ((320,240),(318,212),(180,100)):
            for mode in ("HOME","PET","WORLD","MENU","INVENTORY","STATUS","SAVE",
                         "DIALOGUE","BATTLE","GAME_OVER"):
                game.mode=mode
                game.list=req("systems.inventory").list(game.data)
                game.lines=lua.table_from(["A test dialogue that must wrap at the screen edge."])
                game.line=1
                game.battle=req("systems.combat").new(game.data,"sentinel")
                renderer.paint(game,gc,width,height)
        self.assertGreater(gc.calls,300)
