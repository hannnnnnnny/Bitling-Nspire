import unittest
from support import engine


class SaveTests(unittest.TestCase):
    def setUp(self):
        self.lua, req = engine()
        self.save = req("core.save")
        self.state = req("core.state").new()

    def test_roundtrip_is_an_independent_snapshot(self):
        self.state.player.level = 4
        self.state.pet.bond = 44
        self.state.flags.forest = True
        self.state.map = "valley"
        raw = self.save.encode(self.state)
        restored, notice = self.save.decode(raw)
        self.assertIsNone(notice)
        self.assertEqual(restored.player.level,4)
        self.assertEqual(restored.pet.bond,44)
        self.assertEqual(restored.map,"valley")
        self.assertTrue(restored.flags.forest)
        self.state.pet.bond = 1
        self.assertEqual(restored.pet.bond,44)
        self.assertIsNone(raw.battle)

    def test_missing_wrong_version_and_corrupt_fields(self):
        for value in (None, "garbage", 3, self.lua.table_from({"version":99})):
            state, notice = self.save.decode(value)
            self.assertEqual(state.player.hp,36)
            self.assertTrue(notice)
        raw = self.save.encode(self.state)
        raw.player.level = float("nan")
        raw.player.hp = -1
        raw.pet.bond = 100000
        raw.pet.mood = "evil"
        raw.flags.boss = "true"
        raw.inventory.patch = -10
        raw.inventory.bad = 3
        raw.inventory.order = 1
        raw.x, raw.y = 1, 1
        raw.seed = float("inf")
        state, notice = self.save.decode(raw)
        self.assertEqual(state.player.level,1)
        self.assertEqual(state.pet.bond,10)
        self.assertEqual(state.pet.mood,"idle")
        self.assertIsNone(state.inventory.bad)
        self.assertIsNone(state.inventory.order)
        self.assertEqual((state.x,state.y),(3,5))
        self.assertFalse(state.flags.boss)
        self.assertTrue(notice)

    def test_dead_player_recovers_without_granting_quest_progress(self):
        raw = self.save.encode(self.state)
        raw.player.hp = 0
        raw.map = "nonsense"
        raw.flags.ended = True
        state, notice = self.save.decode(raw)
        self.assertEqual(state.player.hp,state.player.maxHP)
        self.assertEqual(state.map,"forest")
        self.assertFalse(state.flags.ended)
        self.assertTrue(notice)
