import unittest
from collections import deque
from support import engine


class GameTests(unittest.TestCase):
    def setUp(self):
        _, self.req = engine()
        self.game = self.req("core.game").new()
        self.world = self.req("world.world")

    def key(self, key):
        self.game.input(self.game,key)

    def dismiss(self):
        for _ in range(20):
            if self.game.mode != "DIALOGUE":
                break
            self.key("ENTER")

    def travel(self, x, y):
        state = self.game.data
        start = int(state.x), int(state.y)
        queue, paths = deque([start]), {start: []}
        for_loop = (("RIGHT",1,0),("LEFT",-1,0),("DOWN",0,1),("UP",0,-1))
        while queue:
            p = queue.popleft()
            if p == (x,y):
                for key in paths[p]:
                    self.key(key)
                    self.assertNotEqual(self.game.mode,"BATTLE")
                return
            for key,dx,dy in for_loop:
                n = p[0]+dx,p[1]+dy
                # Campaign route stays on safe tiles; encounter mechanics tested separately.
                if n not in paths and self.world.walkable(state.map,*n):
                    if self.world.tile(state.map,*n) != "~":
                        paths[n]=paths[p]+[key]
                        queue.append(n)
        self.fail("No route")

    def test_complete_campaign_via_input(self):
        self.assertEqual(self.game.mode,"HOME")
        self.key("ENTER")
        self.dismiss()
        for area in ("forest","valley","matrix"):
            self.assertEqual(self.game.data.map,area)
            self.travel(10,4)
            self.key("ENTER")
            self.dismiss()
            self.assertTrue(self.game.data.flags[area])
            fragments = self.game.data.inventory.fragment
            self.key("ENTER")
            self.dismiss()
            self.assertEqual(self.game.data.inventory.fragment,fragments)
            if area != "matrix":
                self.travel(14,5)
                self.key("RIGHT")
        self.travel(12,5)
        self.key("ENTER")
        self.assertEqual(self.game.mode,"BATTLE")
        b = self.game.battle
        for _ in range(80):
            if b.done:
                break
            if self.game.data.player.hp < 18 and self.game.data.inventory.patch:
                self.game.perform(self.game,"item","patch")
            elif self.game.data.player.energy >= 5:
                self.game.perform(self.game,"skill","solve")
            elif self.game.data.inventory.cell:
                self.game.perform(self.game,"item","cell")
            else:
                self.game.perform(self.game,"attack",None)
        self.assertEqual(b.done,"won")
        self.assertTrue(self.game.data.flags.boss)
        self.key("ENTER")
        for _ in range(2):
            self.travel(3,5)
            self.key("LEFT")
        self.travel(4,4)
        self.key("ENTER")
        self.dismiss()
        self.assertTrue(self.game.data.flags.ended)
        self.assertEqual(self.game.data.inventory.seed,1)
        self.key("ENTER")
        self.dismiss()
        self.assertEqual(self.game.data.inventory.seed,1)

    def test_menus_back_pet_save_and_load(self):
        self.key("DOWN")
        self.key("ENTER")
        self.assertEqual(self.game.mode,"PET")
        self.key("BACK")
        self.assertEqual(self.game.mode,"HOME")
        self.game.open(self.game,"SAVE")
        self.assertEqual(self.game.mode,"SAVE")
        self.key("BACK")
        self.assertEqual(self.game.mode,"HOME")
        self.key("ENTER")
        self.dismiss()
        self.key("MENU")
        self.assertEqual(self.game.mode,"MENU")
        self.key("BACK")
        self.assertEqual(self.game.mode,"WORLD")
        raw = self.game.save(self.game)
        new = self.req("core.game").new()
        new.restore(new,raw)
        self.assertEqual(new.mode,"HOME")
        self.assertTrue(new.data.flags.started)

    def test_locked_boss_cache_and_defeat_recovery(self):
        self.game.mode="WORLD"
        self.game.data.map,self.game.data.x,self.game.data.y="matrix",12,5
        self.key("ENTER")
        self.assertEqual(self.game.mode,"DIALOGUE")
        self.dismiss()
        self.game.data.x,self.game.data.y=12,7
        self.key("ENTER")
        self.dismiss()
        self.assertEqual(self.game.data.inventory.shield,1)
        self.key("ENTER")
        self.dismiss()
        self.assertEqual(self.game.data.inventory.shield,1)
        self.game.startBattle(self.game,"syntax")
        self.game.data.player.hp=1
        self.game.perform(self.game,"attack",None)
        self.key("ENTER")
        self.assertEqual(self.game.mode,"GAME_OVER")
        self.key("ENTER")
        self.assertEqual(self.game.mode,"HOME")
        self.assertEqual(self.game.data.map,"forest")
        self.assertGreater(self.game.data.player.hp,0)
