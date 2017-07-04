aowl.AddCommand({"fullupdate","update"},function(ply,line)
    if IsValid(ply) then
      ply:ConCommand("record 1;stop")
    end
end)
