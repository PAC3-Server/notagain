NPCS = {}

local insert = function()
  for k,v in pairs(scripted_ents.GetList()) do
    if string.match(k,"npc_*") then
      table.insert(NPCS,k)
    end
  end
end

hook.Add("Initialize","storenpcsnames",insert)
