AddCSLuaFile()

local creatures = _G.creatures or {}
_G.creatures = creatures
creatures.notagain_autorun = false
creatures.DEBUG = GetConVarNumber("developer") > 0

creatures.active = creatures.active or {}
function creatures.GetAll()
	return creatures.active
end

include("networking.lua")
include("base_creature.lua")

hook.Add("OnEntityCreated", "creatures", function(ent)
	timer.Simple(0.1, function()
		if ent:IsValid() then
			if ent.IsCreature then
				table.insert(creatures.active, ent)
			end
		end
	end)
end)

hook.Add("EntityRemoved", "creatures", function(ent)
	if ent.IsCreature then
		for i,v in ipairs(creatures.active) do
			if v == ent then
				table.remove(creatures.active, i)
			end
		end
	end
end)

if SERVER then
	hook.Add("KeyPress", "creatures_debug", function(ply, key)
		if ply:IsAdmin() and ply:Nick():lower():find("capsadmin") then else return end

		for _, self in ipairs(creatures.GetAll()) do
			if key == IN_ATTACK then
				self:MoveTo({
					trace = ply:GetEyeTrace(),
					priority = 1,
					id = "test",
					waiting_time = 0.25,
					finish = function()
						self:GetPhysicsObject():Sleep()
					end
				})
			end

			if key == IN_RELOAD then
				for _,v in ipairs(creatures.GetAll()) do
					v:Remove()
				end
			end

			if key == IN_ATTACK2 then
				self:CancelMoving()
			end
		end
	end)
end

timer.Simple(0, function() notagain.AutorunDirectory("creatures") end)


function creatures.Create(what, where, count, min,max)
	what = what or "base"
	where = where or there
	count = count or 100
	min = min or 15
	max = max or 75

	for _ = 1, count do
		local ent = ents.Create("creature_" .. what)
		ent:SetPos(where + Vector(math.Rand(-1,1), math.Rand(-1,1), 0)*30 + Vector(0,0,50))
		ent:Spawn()
		ent:SetSize(math.Rand(min, max))
	end
end

return creatures
