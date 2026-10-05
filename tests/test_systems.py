import unittest
from support import engine


class InventoryProgressionTests(unittest.TestCase):
    def setUp(self):
        _, req = engine()
        self.state = req("core.state").new()
        self.inventory = req("systems.inventory")
        self.progression = req("systems.progression")
        self.items = req("data.items")

    def test_item_catalogue_and_validation(self):
        self.assertEqual(len(self.items.order), 10)
        self.assertFalse(self.inventory.add(self.state, "bogus", 1))
        self.assertFalse(self.inventory.add(self.state, "order", 1))
        self.state.inventory.order = 1
        self.assertFalse(self.inventory.use(self.state, "order")[0])
        self.assertFalse(self.inventory.add(self.state, "patch", -1))
        self.assertFalse(self.inventory.add(self.state, "patch", 1.5))
        self.inventory.add(self.state, "patch", 999)
        self.assertEqual(self.state.inventory.patch, 99)

    def test_heal_energy_and_key_items(self):
        self.state.player.hp, self.state.player.energy = 1, 0
        self.assertTrue(self.inventory.use(self.state, "patch")[0])
        self.assertEqual(self.state.player.hp, 25)
        self.assertTrue(self.inventory.use(self.state, "cell")[0])
        self.assertEqual(self.state.player.energy, 16)
        self.inventory.add(self.state, "seed", 1)
        self.assertFalse(self.inventory.use(self.state, "seed")[0])
        self.assertEqual(self.state.inventory.seed, 1)
        self.assertFalse(self.inventory.use(self.state, "shield")[0])

    def test_xp_rollover_level_and_cap(self):
        self.assertEqual(self.progression.addXP(self.state, 90), 2)
        self.assertEqual(self.state.player.level, 3)
        self.assertEqual(self.state.player.xp, 0)
        self.assertEqual(self.state.player.hp, self.state.player.maxHP)
        self.progression.addXP(self.state, 100000)
        self.assertEqual(self.state.player.level, 20)
        self.assertEqual(self.state.player.xp, 0)
        self.assertEqual(self.progression.addXP(self.state, -10), 0)
