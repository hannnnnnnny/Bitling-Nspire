import unittest
from support import engine
from build import bundle


class CallbackTests(unittest.TestCase):
    def test_real_ti_entrypoint_lifecycle_and_save(self):
        lua, _ = engine()
        lua.execute("""
            platform={window={width=function() return 318 end,
                height=function() return 212 end,invalidate=function() end}}
            timer={start=function(t) assert(t==0.1) end,stop=function() end}
            on={}
        """)
        lua.execute(bundle())
        on = lua.globals().on
        on.construction()
        on.resize(318,212)
        on.activate()
        on.enterKey()
        on.enterKey()
        on.escapeKey()
        on.charIn("m")
        on.timer()
        raw = on.save()
        self.assertEqual(raw.version,1)
        self.assertTrue(raw.flags.started)
        age = raw.pet.age
        on.deactivate()
        for _ in range(50):
            on.timer()
        self.assertEqual(on.save().pet.age,age)
        on.restore(raw)
        on.activate()
        self.assertEqual(on.save().pet.bond,10)
        on.arrowKey("right")
        on.returnKey()
        self.assertEqual(lua.globals().platform.apiLevel,"2.0")
