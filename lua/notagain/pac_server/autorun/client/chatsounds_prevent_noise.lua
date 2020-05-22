hook.Add("PreChatSound", "chatsounds_prevent_commands", function(info)
    local ply, str = info.ply, info.line

    if str:find("^%p") then return false end

    --if ply:IsDormant() then return end
    --if LocalPlayer():EyePos():Distance(ply:EyePos()) > 2500 then return end
end)