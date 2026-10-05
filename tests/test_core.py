import unittest
from support import engine


class CoreTests(unittest.TestCase):
    def test_defaults_are_isolated(self):
        _, require = engine()
        module = require("core.state")
        a, b = module.new(), module.new()
        a.player.hp = 1
        self.assertEqual(b.player.hp, 36)
        self.assertEqual(a.map, "forest")
        self.assertEqual(a.player.level, 1)

    def test_input_rejects_unknown_events(self):
        _, require = engine()
        inputs = require("core.input")
        self.assertEqual(inputs.translate("left"), "LEFT")
        self.assertEqual(inputs.translate("enter"), "ENTER")
        self.assertIsNone(inputs.translate("unexpected"))


if __name__ == "__main__":
    unittest.main()
