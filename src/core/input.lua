local Input = {}
local mapping = {
    up="UP", down="DOWN", left="LEFT", right="RIGHT",
    enter="ENTER", escape="BACK", menu="MENU",
    ["8"]="UP", ["2"]="DOWN", ["4"]="LEFT", ["6"]="RIGHT",
    ["5"]="ENTER", ["0"]="BACK", m="MENU"
}

function Input.translate(event)
    if type(event) ~= "string" then return nil end
    return mapping[string.lower(event)]
end

return Input
