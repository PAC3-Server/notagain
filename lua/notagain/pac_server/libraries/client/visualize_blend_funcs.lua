return function()
    if IsValid(BLEND_MODE_VISUALIZER) then
        BLEND_MODE_VISUALIZER:Remove()
    end

    local state = {}

    local frame = vgui.Create("DFrame") BLEND_MODE_VISUALIZER = frame
    frame:SetSize(512,220)
    
    local form = vgui.Create("DForm", frame)
    form:Dock(FILL)
    local function add_blend_modes(title, enums, default)
        local pnl = form:ComboBox(title)
      
        for _, mode in ipairs(enums) do
            pnl:AddChoice(mode, _G[mode])
        end

        pnl.OnSelect = function( panel, index, value, enum )
            state[title] = enum
        end

        for i, v in ipairs(enums) do
            if v == default then
                pnl:ChooseOptionID(i)
            end
        end
    end

      
    local blend = {
        "BLEND_ZERO",
        "BLEND_ONE",
        "BLEND_DST_COLOR",
        "BLEND_ONE_MINUS_DST_COLOR",
        "BLEND_SRC_ALPHA",
        "BLEND_ONE_MINUS_SRC_ALPHA",
        "BLEND_DST_ALPHA",
        "BLEND_ONE_MINUS_DST_ALPHA",
        "BLEND_SRC_ALPHA_SATURATE",
        "BLEND_SRC_COLOR",
        "BLEND_ONE_MINUS_SRC_COLOR",
    }
    
    local blend_func = {
        "BLENDFUNC_ADD",
        "BLENDFUNC_SUBTRACT",
        "BLENDFUNC_REVERSE_SUBTRACT",
    }

    add_blend_modes("srcBlend", blend, "BLEND_SRC_ALPHA")
    --add_blend_modes("srcBlendAlpha", blend, "BLEND_SRC_ALPHA")

    add_blend_modes("dstBlend", blend, "BLEND_ONE_MINUS_SRC_ALPHA")
    --add_blend_modes("dstBlendAlpha", blend, "BLEND_ONE_MINUS_SRC_ALPHA")

    add_blend_modes("blendFunc", blend_func, "BLENDFUNC_ADD")
    --add_blend_modes("blendFuncAlpha", blend_func, "BLENDFUNC_ADD")

    return function()
        return 
            state.srcBlend, state.dstBlend, state.blendFunc
            --,state.srcBlendAlpha, state.dstBlendAlpha, state.blendFuncAlpha
    end
end
