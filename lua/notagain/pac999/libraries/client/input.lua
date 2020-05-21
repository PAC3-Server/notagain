local input = {}

function input.IsGrabbing()
    return _G.input.IsMouseDown(MOUSE_LEFT)
end

return input