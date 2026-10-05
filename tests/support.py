from lupa.lua51 import LuaRuntime
from build import bundle


def engine():
    lua = LuaRuntime(unpack_returned_tuples=True)
    require = lua.execute(bundle(entry=False))
    return lua, require
