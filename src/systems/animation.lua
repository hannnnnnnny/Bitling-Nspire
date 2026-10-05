local Animation = {}

function Animation.frame(action, tick)
    if action == "walk" then return tick % 6 < 3 and "walk1" or "walk2" end
    if action == "idle" then return tick % 30 == 29 and "blink" or "idle" end
    if action == "excited" or action == "curious" then return "happy" end
    if action == "sad" or action == "angry" then return "hurt" end
    if action == "sleepy" then return "blink" end
    if action == "thinking" then return "idle" end
    return action
end

return Animation
