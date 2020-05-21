local camera = {}

function camera.GetViewRay()
    local mx,my = gui.MousePos()

    if not vgui.CursorVisible() then
        mx = ScrW()/2
        my = ScrH()/2
    end

    return gui.ScreenToVector(mx, my)
end

function camera.GetViewMatrix()
    local m = Matrix()

    m:SetAngles(camera.GetViewRay():Angle())
    m:SetTranslation(EyePos())

    return m
end

return camera