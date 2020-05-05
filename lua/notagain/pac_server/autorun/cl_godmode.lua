if engine.ActiveGamemode() ~= "sandbox" then return end

-- Original cl_godmode: https://github.com/PAC3-Server/notagain/commit/8b141b0760c620045593701f89869f289b985e0b

local help = [[(o)ff = disable, (a)ll = godmode, (w)orld = no world damage, (e)nemy = no non-friend damage, (f)riend = no friend damage, (n)pc = no npc damage, (s)elf = no self damage

 -- Separate using any symbol you'd like! ( , | & * + % ), they should all work!
 -- You may combine variables for diffrent results for example `world,enemy`, means god against world damage, and non-friend damage.
 -- Note, that `off` disables everything, and `all` enables full godmode. (Both 0 and 1 work as well.)]]

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
	local infoTable = {}
	local infoStr = ValidString( ply:GetInfo("cl_godmode") ) or "0"
	-- Maybe we should store this as a variable on the player and only update with the command, so we don't have to poll the client on every hit.
	-- Maybe it's done internally?

	local v = string.sub(string.lower(infoStr), 1, 1)

	if check(v,'off') then
		return false
	elseif check(v,'all') then
		return true
	end

	string.gsub(infoStr, "(%w+)", function(char) table.insert(infoTable, char) end)

	if table.Count(infoTable) > 7 then
		return false
	end

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

	return false
end

if CLIENT then
	local cvar = CreateClientConVar("cl_godmode", "w/e/n/s", true, true, help)
	CreateClientConVar("cl_godmode_reflect", "1", true, true, help)

	local checkboxes = {}
	local last = 50

	local function update()
		local infoTable = {}
		local infoStr = ValidString( cvar:GetString() ) or "0"
		string.gsub(infoStr, "(%w+)", function(char) table.insert(infoTable, char) end)

		local v = string.sub(string.lower(infoStr), 1, 1)

		if check(v,'off') then
			for _,v in next, checkboxes do
				if v.SetChecked then
					v:SetChecked(false)
				end
			end
			return
		elseif check(v,'all') then
			for _,v in next, checkboxes do
				if v.SetChecked then
					v:SetChecked(true)
				end
			end
			return
		end

		if table.Count(infoTable) > 7 then
			cvar:SetString('w/e/n/s')
			print('Too much information in `cl_godmode`, resetting defaults.')
			return
		end

		if checkboxes and next(checkboxes) then
			for _,v in next, infoTable do
				local v = string.sub(string.lower(v), 1, 1)

				if IsValid(checkboxes.world) and check(v,'world') then
					checkboxes.world:SetChecked(true)
				elseif IsValid(checkboxes.enemy) and check(v,'enemy') then
					checkboxes.enemy:SetChecked(true)
				elseif IsValid(checkboxes.friend) and check(v,'friend') then
					checkboxes.friend:SetChecked(true)
				elseif IsValid(checkboxes.npc) and check(v,'npc') then
					checkboxes.npc:SetChecked(true)
				elseif IsValid(checkboxes.self) and check(v,'self') then
					checkboxes.self:SetChecked(true)
				end
			end
		end
	end

	cvars.AddChangeCallback('cl_godmode', update)

	local function AddCheckbox(pnl, label, var)
		local box = vgui.Create( "DCheckBoxLabel", pnl )

		box:SetPos(25, last)
		box:SetText(label)
		box:SetValue(0)

		box.var = var

		function box:OnChange(bool)
			local info = {}

			for _,box in next, checkboxes do
				if box:GetChecked() then
					table.insert(info, box.var)
				end
			end

			local str = table.concat(info, "/")
			cvar:SetString(str)
		end

		last = last + 25
		return box
	end

	local function AddButton(pnl, label, var)
		local button = vgui.Create( "DButton", pnl )

		button:SetPos(25, last)
		button:SetSize(pnl:GetWide()-50,20)
		button:SetText(label)

		function button:Think()
			self:SetSize(pnl:GetWide()-50,20)
		end

		if var == "all" then
			function button:DoClick()
				cvar:SetString("all")
				update()
			end
		else
			function button:DoClick()
				cvar:SetString("off")
				update()
			end
		end

		last = last + 25
		return button
	end

	local function GodmodeUI(pnl)
		pnl:AddControl("Header", { Description = "Godmode Settings" })

		checkboxes = {
			world  = AddCheckbox(pnl, "Block damage from The World.", "world"),
			enemy  = AddCheckbox(pnl, "Block damage from Enemies.",   "enemy"),
			friend = AddCheckbox(pnl, "Block damage from Friends.",   "friend"),
			npc    = AddCheckbox(pnl, "Block damage from NPCs.",      "npc"),
			self   = AddCheckbox(pnl, "Block damage from myself.",    "self"),
		}

		AddButton(pnl, 'Disable Godmode', 'off')
		AddButton(pnl, 'Enable Full Godmode', 'all')

		local b = AddButton(pnl, 'Refresh Values', 'update')
		function b:DoClick()
			update()
		end

		update()
	end

	hook.Add("PopulateToolMenu", "cl_godmode", function()
		last = 50
		spawnmenu.AddToolMenuOption( "Utilities", "User", "cl_godmode", "Godmode", "", "", GodmodeUI)
	end)

	net.Receive("cl_godmode_clearDecals", function()
		local ent = net.ReadEntity()
		if ent:IsValid() then
			ent:RemoveAllDecals()
		end
	end)

	hook.Add("PlayerTraceAttack", "cl_godmode", function(ply, dmginfo)
		local actor = dmginfo:GetAttacker() or dmginfo:GetInflictor()
		if GodCheck(ply, dmginfo, actor) then
			return true
		end
	end)
end

if SERVER then
	util.AddNetworkString("cl_godmode_clearDecals")

	timer.Simple(0.3, function()
		RunConsoleCommand("sbox_godmode", "0")
	end)

	hook.Add("InitPostEntity", "cl_godmode", function()
		scripted_ents.Register({Base = "base_brush", Type = "brush"}, "god_reflect_damage")
		timer.Simple(0, function()
			local e = ents.Create("god_reflect_damage")
			e:Spawn()
			e:SetPos(Vector(0,0,0))
			e:Initialize()
		end)
	end)

	hook.Add("PostCleanupMap", "cl_godmode", function()
		local e = ents.Create("god_reflect_damage")
		e:Spawn()
		e:SetPos(Vector(0,0,0))
		e:Initialize()
	end)

	local suppress = false

	hook.Add("EntityTakeDamage", "cl_godmode", function(ply, dmginfo)
		if suppress then return end

		if IsPlayer(ply) and ply.GetInfo then
			if ply.haltgodmode or (ply:GetNWBool("rpg") and not ply.rpg_cheat) then return end

			local actor = dmginfo:GetAttacker() or dmginfo:GetInflictor()

			if GodCheck(ply, dmginfo, actor) then
				if ply.bloodcolor then
					ply:SetBloodColor(ply.bloodcolor)
					ply.bloodcolor = nil
				end

				if ply == actor then
					if ( not ply:IsOnGround() ) then
						ply:SetVelocity( dmginfo:GetDamageForce()*0.03 )
					end
				else
					if tobool( ply:GetInfo("cl_godmode_reflect") ) and IsValid(actor) then
						suppress = true
						local mirror = ents.FindByClass('god_reflect_damage')[1]

						dmginfo:SetAttacker(ply)
						dmginfo:SetInflictor(mirror or actor)

						actor:TakeDamageInfo(dmginfo)
						suppress = false
					end
				end

				net.Start("cl_godmode_clearDecals")
				net.WriteEntity(ply)
				net.Broadcast()

				if not ply.bloodcolor then
					ply.bloodcolor = ply:GetBloodColor()
					ply:SetBloodColor(DONT_BLEED)
				end

				return true
			end
		end
	end)
end
