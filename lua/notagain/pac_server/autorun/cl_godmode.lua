-- Original cl_godmode: https://github.com/PAC3-Server/notagain/commit/8b141b0760c620045593701f89869f289b985e0b

local help = [[(o)ff = disable, (a)ll = godmode, (w)orld = no world damage, (e)nemy = no non-friend damage, (f)riend = no friend damage, (n)pc = no npc damage, (s)elf = no self damage

 -- Separate using any symbol you'd like! ( , | & * + % ), they should all work!
 -- You may combine variables for diffrent results for example `world,enemy`, means god against world damage, and non-friend damage.
 -- Note, that `off` disables everything, and `all` enables full godmode. (These work as both 0 and 1 as well.)]]

if CLIENT then
	CreateClientConVar("cl_godmode", "1", true, true, help)
	CreateClientConVar("cl_godmode_reflect", "1", true, true, help)
end

if SERVER then
	timer.Simple(0.3, function()
		RunConsoleCommand("sbox_godmode", "0")
	end)

	local function IsPlayer(ent)
		return IsValid(ent) and ent:GetClass() == "player" or false
	end

	local function ValidString(v)
		return string.Trim(v) ~= "" and v or false
	end


	local d = {
		['off'] = 'o',
		['all'] = 'a',
		['world'] = 'w',
		['enemy'] = 'e',
		['friend'] = 'f',
		['npc'] = 'n',
		['self'] = 's',
	}

	local alias = {
		['0'] = d['off'],
		['1'] = d['all'],
		['on'] = d['all'],
	}

	local function check(v,key)
		local v = alias[v] or v
		return v == d[key]
	end

	local function GodCheck(ply, dmginfo, actor)
		if ply.reflected then return end

		local block = false
		local infoTable = {}
		local infoStr = ValidString( ply:GetInfo("cl_godmode") ) or "0"

		local v = string.sub(string.lower(infoStr), 1, 1)

		if check(v,'off') then
			return false
		elseif check(v,'all') then
			return true
		end

		string.gsub(infoStr, "(%w+)", function(char) table.insert(infoTable, char) end)

		for _,v in next, infoTable do
			local v = string.sub(string.lower(v), 1, 1)

			if actor == game.GetWorld() and check(v,'world') then
				return true
			elseif actor.CanAlter and ( not actor:CanAlter(ply) ) and check(v,'enemy') then
				return true
			elseif actor.CanAlter and ( actor:CanAlter(ply) ) and check(v,'friend') then
				return true
			elseif actor.IsNPC and actor:IsNPC() and check(v,'npc') then
				return true
			elseif actor == ply and check(v,'self') then
				return true
			end
		end

		return block, actor
	end

	hook.Add("InitPostEntity", "cl_godmode", function()
		scripted_ents.Register({Base = "base_brush", Type = "brush"}, "god_reflect_damage")
		timer.Simple(0, function()
			local e = ents.Create("god_reflect_damage")
			e:Spawn()
			e:SetPos(Vector(0,0,0))
			e:Initialize()
		end)
	end)

	local suppress = false

	hook.Add("EntityTakeDamage", "cl_godmode", function(ply, dmginfo)
		if suppress then return end

		if IsPlayer(ply) and ply.GetInfo then
			local actor = dmginfo:GetAttacker() or dmginfo:GetInflictor()
			if GodCheck(ply, dmginfo, actor) then
				if tobool( ply:GetInfo("cl_godmode_reflect") ) and IsValid(actor) then
					suppress = true
					local mirror = ents.FindByClass('god_reflect_damage')[1]
					
					dmginfo:SetAttacker(ply)
					dmginfo:SetInflictor(mirror or actor)

					actor:TakeDamageInfo(dmginfo)
					suppress = false
				end
				return true
			end
		end
	end)
end
