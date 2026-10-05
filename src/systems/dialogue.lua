local LocalDialogueProvider = {}
local lines = {
    boot={"You wake behind the numbers. Your name is Mote.",
          "Three memory nodes have gone quiet. Find the caretakers; restore the garden.",
          "Arrows move. Enter interacts. M opens your menu. Blue ripples hide errors."},
    ada={"I am Ada, the garden archivist. The mint node is northeast of here.",
         "Restore a node in each realm. Then quiet the Null Sentinel in Matrix Dungeon.",
         "Return to me when the garden remembers. Terminals heal you for free."},
    tess={"I am Tess. This valley used to draw constellations.",
          "Graph reveals weaknesses. Analyze doubles your next damaging action.",
          "The amber node is northeast. The east portal leads to Matrix Dungeon."},
    rowan={"I am Rowan, keeper of the rows. Our violet node still has a pulse.",
           "The sentinel waits to the east. All three nodes must be awake.",
           "Factor breaks armor. Debug clears glitch. Heal before a heavy pulse."},
    ending={"The sentinel's noise becomes a quiet heartbeat.",
            "Ada plants a Memory Seed. The garden is alive because you listened.",
            "MEMORY GARDEN RESTORED. Keep exploring; Mote's story continues."}
}

function LocalDialogueProvider.lines(id, state)
    if id == "ada" and state.flags.ended then
        return {"Your Memory Seed is growing. There is room for more worlds."}
    end
    return lines[id] or {"A quiet signal. No words yet."}
end

return LocalDialogueProvider
