local blur_mat = Material( "pp/bokehblur" )
local grad_up = surface.GetTextureID("gui/gradient_up")
local grad_down = surface.GetTextureID("gui/gradient_down")
local mat = Material("particle/Particle_Glow_04_Additive")
local size = 400

local cvars = {
    r_WaterDrawReflection = 1,
    r_3dsky = 1,
}

local old_cvars = {}

hook.Add("OnRPGEnabled", "jrpg_post_process", function()
    print("!")
    for k,v in pairs(cvars) do
        RunConsoleCommand(k,v)
        old_cvars[k] = GetConVar(k):GetString()
    end
end)

hook.Add("OnRPGDisabled", "jrpg_post_process", function()
    for k,v in pairs(old_cvars) do
        RunConsoleCommand(k,v)
    end
end)

jrpg.AddHook("RenderScreenspaceEffects", "post_process", function()


    local f = 1
    local tbl = {}
    tbl[ "$pp_colour_addr" ] = 0.02
    tbl[ "$pp_colour_addg" ] = 0.025
    tbl[ "$pp_colour_addb" ] = 0.05
    tbl[ "$pp_colour_brightness" ] = 0
    tbl[ "$pp_colour_contrast" ] = 0.8
    tbl[ "$pp_colour_colour" ] = 1.15
    tbl[ "$pp_colour_mulr" ] = 0
    tbl[ "$pp_colour_mulg" ] = 0
    tbl[ "$pp_colour_mulb" ] = 0
    DrawColorModify( tbl )

    --DrawBloom( 0.6, 1.2, 11.21, 9, 2, 0.25, 1, 1, 1)

    do return end
    surface.SetDrawColor(0,0,0, 220)

    surface.SetTexture(grad_down)
    surface.DrawTexturedRect(0, 0, ScrW(), ScrH()/2)

    surface.SetTexture(grad_up)
    surface.DrawTexturedRect(0, ScrH()/2, ScrW(), ScrH()/2)
end)