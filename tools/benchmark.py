"""Measure the host adapter and Lua heap; never label these as handheld FPS."""
import json
import statistics
import time
from gallery import scene
from build import bundle


def main():
    app=scene("WORLD")
    app.lua.eval("collectgarbage")("collect")
    before=app.lua.eval("collectgarbage")("count")
    timings=[]
    for _ in range(200):
        app.tick()
        start=time.perf_counter()
        app.paint()
        timings.append((time.perf_counter()-start)*1000)
    app.lua.eval("collectgarbage")("collect")
    after=app.lua.eval("collectgarbage")("count")
    report={"runtime":"host Lua 5.1 + Pillow; not handheld",
            "source_bytes":len(bundle().encode("utf-8")),
            "state_json_bytes":len(json.dumps(app.snapshot()).encode("utf-8")),
            "lua_heap_before_kib":round(before,2),"lua_heap_after_kib":round(after,2),
            "median_host_paint_ms":round(statistics.median(timings),3),
            "max_host_paint_ms":round(max(timings),3)}
    print(json.dumps(report,indent=2))


if __name__=="__main__":
    main()
