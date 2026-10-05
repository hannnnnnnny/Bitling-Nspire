import json
from pathlib import Path
import tempfile
import unittest


class HostTests(unittest.TestCase):
    def test_callbacks_render_and_save_roundtrip(self):
        from host import Application
        app = Application(318,212)
        image = app.paint()
        self.assertEqual(image.size,(318,212))
        self.assertTrue(any("BITLING" in record[0] for record in app.gc.texts))
        app.key("enter")
        app.key("enter")
        app.key("escape")
        with tempfile.TemporaryDirectory() as name:
            path = Path(name)/"game.json"
            app.save(path)
            data = json.loads(path.read_text("utf-8"))
            self.assertTrue(data["flags"]["started"])
            second = Application(318,212)
            second.load(path)
            self.assertTrue(second.snapshot()["flags"]["started"])
            self.assertFalse(path.with_name(path.name+".tmp").exists())

    def test_host_rejects_corrupt_oversize_and_nonfinite_save(self):
        from host import Application
        with tempfile.TemporaryDirectory() as name:
            path = Path(name)/"game.json"
            for raw in ("broken"," "*40000,'{"version":1,"seed":NaN}',
                        '{"version":1,"player":{"level":9223372036854775808}}'):
                path.write_text(raw,"utf-8")
                app=Application()
                self.assertFalse(app.load(path))
                self.assertEqual(app.snapshot()["player"]["hp"],36)

    def test_timer_pauses_while_inactive(self):
        from host import Application
        app = Application()
        app.on.deactivate()
        app.on.timer()
        self.assertEqual(app.snapshot()["pet"]["age"],0)
