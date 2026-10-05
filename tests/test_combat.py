import unittest
from support import engine


class CombatTests(unittest.TestCase):
    def setUp(self):
        self.lua, self.req = engine()
        self.state = self.req("core.state").new()
        self.combat = self.req("systems.combat")

    def test_catalogue_and_invalid_actions(self):
        enemies = self.req("data.enemies")
        self.assertEqual(len(list(enemies.keys())), 6)
        battle = self.combat.new(self.state, "syntax")
        self.state.player.energy = 0
        self.assertFalse(self.combat.act(battle, "skill", "solve"))
        self.assertEqual(battle.turn, 0)
        self.assertFalse(self.combat.act(battle, "skill", "unknown"))
        self.assertFalse(self.combat.act(battle, "skill", "order"))
        self.assertFalse(self.combat.act(battle, "item", "core"))

    def test_skills_have_distinct_effects(self):
        b = self.combat.new(self.state, "sentinel")
        defense = b.defense
        self.combat.act(b, "skill", "factor")
        self.assertLess(b.defense, defense)
        self.combat.act(b, "skill", "graph")
        self.assertTrue(b.revealed)
        self.combat.act(b, "skill", "analyze")
        self.assertEqual(b.boost, 2)
        self.state.player.energy = 100
        hp = b.hp
        self.combat.act(b, "skill", "solve")
        self.assertLess(b.hp, hp)
        self.assertEqual(b.boost, 0)
        b = self.combat.new(self.req("core.state").new(), "sentinel")
        b.glitch = 3
        self.combat.act(b, "skill", "debug")
        self.assertEqual(b.glitch, 0)

    def test_each_enemy_can_be_defeated_and_rewarded_once(self):
        for enemy in self.req("data.enemies").keys():
            self.state = self.req("core.state").new()
            self.req("systems.progression").addXP(self.state, 90)
            b = self.combat.new(self.state, enemy)
            for _ in range(100):
                if b.done:
                    break
                if self.state.player.hp < 20:
                    self.combat.act(b, "item", "patch")
                elif self.state.player.energy >= 5:
                    self.combat.act(b, "skill", "solve")
                else:
                    self.combat.act(b, "attack")
            self.assertEqual(b.done, "won", enemy)
            self.assertTrue(self.combat.reward(self.state, b))
            xp = self.state.player.xp
            self.assertFalse(self.combat.reward(self.state, b))
            self.assertEqual(self.state.player.xp, xp)

    def test_loss_run_and_boss_restriction(self):
        b = self.combat.new(self.state, "sentinel")
        self.assertFalse(self.combat.act(b, "run"))
        self.assertEqual(b.turn, 0)
        self.state.player.hp = 1
        self.combat.act(b, "attack")
        self.combat.act(b, "attack")
        self.assertEqual(b.done, "lost")
        self.assertFalse(self.combat.reward(self.state, b))
        b = self.combat.new(self.req("core.state").new(), "syntax")
        for _ in range(10):
            if b.done:
                break
            self.combat.act(b, "run")
        self.assertEqual(b.done, "ran")
