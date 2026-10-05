import unittest
from collections import deque
from support import engine


class WorldTests(unittest.TestCase):
    def setUp(self):
        _, self.require = engine()
        self.world = self.require("world.world")
        self.state = self.require("core.state").new()
        self.maps = self.require("data.maps")

    def test_walls_and_npc_block(self):
        self.state.x, self.state.y = 2, 2
        self.assertFalse(self.world.move(self.state, -1, 0))
        self.state.x, self.state.y = 4, 4
        self.assertFalse(self.world.move(self.state, 0, -1))
        self.assertFalse(self.world.move(self.state, 2, 0))

    def test_portals_are_reversible(self):
        self.state.x, self.state.y = 14, 5
        self.assertEqual(self.world.move(self.state, 1, 0), "portal")
        self.assertEqual(self.state.map, "valley")
        self.assertEqual(self.world.move(self.state, -1, 0), "portal")
        self.assertEqual(self.state.map, "forest")

    def test_each_interactive_object_is_reachable(self):
        for name in ("forest", "valley", "matrix"):
            self.state.map = name
            seen, queue = {(3, 5)}, deque([(3, 5)])
            while queue:
                x, y = queue.popleft()
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    p = x + dx, y + dy
                    if p not in seen and self.world.walkable(name, *p):
                        seen.add(p)
                        queue.append(p)
            for obj in self.maps[name].objects.values():
                self.assertTrue(any((obj.x+dx, obj.y+dy) in seen
                                    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))))

    def test_interaction_and_encounters_use_data(self):
        self.state.x, self.state.y = 10, 4
        self.assertEqual(self.world.interact(self.state).kind, "node")
        self.state.x, self.state.y = 12, 7
        self.assertEqual(self.world.interact(self.state).kind, "cache")
        self.state.x, self.state.y, self.state.steps = 7, 8, 100
        found = {self.world.encounter(self.state) for _ in range(200)}
        self.assertIn("syntax", found)
        self.assertIn("overflow", found)
