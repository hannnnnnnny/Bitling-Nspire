local Items = {
    order={"patch","cell","root","tonic","shield","lens","treat","fragment","core","seed"},
    patch={name="Byte Patch", kind="heal", amount=24, description="Restore 24 HP."},
    cell={name="Charge Cell", kind="energy", amount=16, description="Restore 16 energy."},
    root={name="Root Packet", kind="rest", amount=12, description="Heal 12 HP + 6 energy."},
    tonic={name="Clear Tonic", kind="cleanse", amount=10, description="Clear glitch + heal 10."},
    shield={name="Guard Shell", kind="shield", amount=3, description="Guard next 3 enemy turns."},
    lens={name="Curio Lens", kind="curiosity", amount=8, description="Raise curiosity by 8."},
    treat={name="Mint Treat", kind="bond", amount=8, description="Raise bond by 8."},
    fragment={name="Node Fragment", kind="key", description="Proof of a restored node."},
    core={name="Quiet Core", kind="key", description="The sentinel is at peace."},
    seed={name="Memory Seed", kind="key", description="A garden's new beginning."}
}

function Items.get(id)
    if type(id) ~= "string" then return nil end
    local item=Items[id]
    if type(item)=="table" and item.kind then return item end
    return nil
end

return Items
