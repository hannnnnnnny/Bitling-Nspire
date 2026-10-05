local State = {}

function State.new()
    return {
        player = {hp=36, maxHP=36, energy=24, maxEnergy=24, logic=7,
                  focus=5, level=1, xp=0},
        pet = {mood="idle", bond=10, curiosity=5, experience=0,
               age=0, idle=0, emotion=0, cooldown=0},
        inventory = {patch=5, cell=3},
        flags = {}, map="forest", x=3, y=5,
        ticks=0, steps=0, seed=1701
    }
end

function State.random(state, limit)
    -- Small exact-in-double generator: repeatable without Lua bit libraries.
    state.seed = (state.seed * 16807) % 2147483647
    return state.seed % limit + 1
end

return State
