local Skills = {
    order={"factor","solve","graph","analyze","debug"},
    factor={name="Factor", cost=3, description="Break defense; chip damage."},
    solve={name="Solve", cost=5, description="Heavy logic damage."},
    graph={name="Graph", cost=2, description="Reveal stats; expose weakness."},
    analyze={name="Analyze", cost=2, description="Double next damaging action."},
    debug={name="Debug", cost=3, description="Clear glitch; heal 12 HP."}
}

function Skills.get(id)
    if type(id)~="string" then return nil end
    local skill=Skills[id]
    if type(skill)=="table" and type(skill.cost)=="number" then return skill end
    return nil
end

return Skills
