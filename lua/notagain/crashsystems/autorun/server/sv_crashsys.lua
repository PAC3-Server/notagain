util.AddNetworkString("pingpong")

local loaded = {}

hook.Add("PlayerCanHearPlayersVoice", "pingpong", function(ply)
  if not table.HasValue(loaded,ply) then
    table.insert(loaded, ply)
  end
end)

hook.Add("PlayerDisconnected", "pingpong", function(ply)
  table.RemoveByValue(loaded, ply)
end)

timer.Create("pingpong", 0.5, 0, function()
  if next(loaded) then
    net.Start("pingpong", true)
    net.Send(loaded)
  end
end)
