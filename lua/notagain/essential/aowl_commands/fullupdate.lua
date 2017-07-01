aowl.AddCommand({"fullupdate","update"},function(ply,line,target)
    target = easylua.FindEntity(target)
    if target and IsValid(target) and IsValid(ply) and target:IsPlayer() then
      target:ConCommand("record 1;stop")
    end
end)
