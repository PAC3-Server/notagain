local easylua = requirex("easylua")
local mute = "aowl_mute_draw"
local unmute = "aowl_unmute_draw"

if SERVER then
  util.AddNetworkString(mute)
  util.AddNetworkString(unmute)
  aowl.AddCommand({"mute","block"},function(ply,line,cmd,target)
    target = easylua.FindEntity(target)

    if target and IsValid(target) and Isvalid(ply) and target:IsPlayer() then

      net.Start(mute)
      net.WriteEntity(target)
      net.Send(ply)

    end

  end)
  aowl.AddCommand({"unmute","unblock"},function(ply,line,cmd,target)
    target = easylua.FindEntity(target)

    if target and IsValid(target) and Isvalid(ply) and target:IsPlayer() then

      net.Start(unmute)
      net.WriteEntity(target)
      net.Send(ply)

    end

  end)
end

if CLIENT then
  local muteds = {}

  net.Receive(mute,function()
    local ent = net.ReadEntity()
    muteds[ent:GetName()] = ent 
  end)

  net.Receive(unmute,function()
    local ent = net.ReadEntity()
    muteds[ent:GetName()] = nil
  end)

  hook.Add("OnPlayerChat",mute,function(ply)
    if IsValid(ply) and muteds[ply:GetName()] then
      return ""
    end
  end)

end
