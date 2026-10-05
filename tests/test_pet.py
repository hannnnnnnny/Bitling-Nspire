import unittest
from support import engine


class PetTests(unittest.TestCase):
    def setUp(self):
        _, req = engine()
        self.state = req("core.state").new()
        self.pet = req("systems.pet")
        self.animation = req("systems.animation")

    def test_event_reactions(self):
        for event, mood in (("return","happy"),("win","happy"),("loss","hurt"),
                            ("level","excited"),("rare","curious")):
            self.pet.react(self.state,event)
            self.assertEqual(self.state.pet.mood,mood)

    def test_active_inactivity_energy_age_and_cooldown(self):
        self.pet.tick(self.state,121)
        self.assertEqual(self.state.pet.mood,"sad")
        self.assertEqual(self.state.pet.age,121)
        before = self.state.pet.bond
        self.assertTrue(self.pet.interact(self.state,"talk")[0])
        self.assertEqual(self.state.pet.bond,before+2)
        self.assertFalse(self.pet.interact(self.state,"talk")[0])
        self.pet.tick(self.state,6)
        self.assertTrue(self.pet.interact(self.state,"rest")[0])
        self.state.player.energy = 0
        self.state.pet.emotion = 0
        self.pet.tick(self.state,1)
        self.assertEqual(self.state.pet.mood,"sleepy")

    def test_required_animation_frames(self):
        self.assertEqual(self.animation.frame("idle",0), "idle")
        self.assertEqual(self.animation.frame("idle",29), "blink")
        self.assertEqual(self.animation.frame("walk",3), "walk2")
        for action in ("happy","hurt","attack"):
            self.assertEqual(self.animation.frame(action,0),action)
