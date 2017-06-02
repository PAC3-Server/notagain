local easylua = requirex("easylua")
local ignore = "aowl_ignore_draw"
local unignore = "aowl_unignore_draw"

if SERVER then
  util.AddNetworkString(ignore)
  util.AddNetworkString(unignore)
  aowl.AddCommand({"ignore","undraw"},function(ply,line,target)
    target = easylua.FindEntity(target)

    if target and IsValid(target) and IsValid(ply) and target:IsPlayer() then

      net.Start(ignore)
      net.WriteEntity(target)
      net.Send(ply)

    end

  end)
  aowl.AddCommand({"unignore","draw"},function(ply,line,target)
    target = easylua.FindEntity(target)

    if target and IsValid(target) and IsValid(ply) and target:IsPlayer() then

      net.Start(unignore)
      net.WriteEntity(target)
      net.Send(ply)

    end

  end)
end

if CLIENT then
  local ignoreds = {}

  net.Receive(ignore,function()
    local ent = net.ReadEntity()
    ignoreds[ent:GetName()] = ent 
    ent:SetNoDraw(true)
    ent:SetNotSolid(true)
    if pac and pace then
      pac.IgnoreEntity(ent)
    end
  end)

  net.Receive(unignore,function()
    local ent = net.ReadEntity()
    ignoreds[ent:GetName()] = nil
    ent:SetNoDraw(false)
    ent:SetNotSolid(false)
    if pac and pace then
      pac.UnIgnoreEntity(ent)
    end
  end)

  hook.Add("PrePlayerDraw",ignore,function(ply)
    if IsValid(ply) and ignoreds[ply:GetName()] then
      ply:SetNoDraw(true)
      ply:SetNotSolid(true)
      return true 
    end
  end)

  hook.Add("pac_OnWoreOutfit",unignore,function(_,ply)
    if IsValid(ply) and ignoreds[ply:GetName()] then
      pac.IgnoreEntity(ply)
    end 
  end)
end
