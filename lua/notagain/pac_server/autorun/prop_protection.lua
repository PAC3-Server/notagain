if engine.ActiveGamemode() ~= "sandbox" then return end

proptect = {}
proptect.Version = 1.7

CPPI = {}
CPPI_NOTIMPLEMENTED = 26
CPPI_DEFER = 16

------------------------------------
--	Simple Prop Protection
--	By Spacetech, Maintained by Donkie
-- 	https://github.com/Donkie/SimplePropProtection
------------------------------------

function CPPI:GetName()
	return "Simple Prop Protection"
end

function CPPI:GetVersion()
	return proptect.Version
end

function CPPI:GetInterfaceVersion()
	return 1.3
end

function CPPI:GetNameFromUID(uid)
	return CPPI_NOTIMPLEMENTED
end

local plymeta = FindMetaTable("Player")
if not plymeta then
	error("Couldn't find Player metatable")
	return
end

local entmeta = FindMetaTable("Entity")
if not entmeta then
	print("Couldn't find Entity metatable")
	return
end

function entmeta:CPPIGetOwner()
	local ply = self:GetNWEntity("OwnerObj", false)

	if SERVER then
		if proptect.Props[self:EntIndex()] then
			ply = proptect.Props[self:EntIndex()].Owner
		end
	end

	if not IsValid(ply) then
		return nil, CPPI_NOTIMPLEMENTED
	end

	local UID = CPPI_NOTIMPLEMENTED

	if SERVER then
		UID = ply:UniqueID()
	end

	return ply, UID
end

if SERVER then
	function entmeta:CPPISetOwner(ply)
		if not ply then
			return proptect.UnOwnProp(self)
		end

		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end
		return proptect.PlayerMakePropOwner(ply, self)
	end

	function entmeta:CPPISetOwnerUID(uid)
		if not uid then
			return proptect.UnOwnProp(self)
		end

		local ply = player.GetByUniqueID(tostring(uid))
		if not IsValid(ply) then
			return false
		end

		return proptect.PlayerMakePropOwner(ply, self)
	end

	function entmeta:CPPICanTool(ply, toolmode)
		if not IsValid(ply) or not toolmode then
			return false
		end

		local entidx = self:EntIndex()

		if not proptect.KVcanuse[entidx] then proptect.KVcanuse[entidx] = -1 end

		if not proptect.PlayerCanTouch(ply, self) or proptect.KVcantool[entidx] == 0 or (proptect.KVcantool[entidx] == 1 and not ply:IsAdmin()) then
			return false
		elseif toolmode == "remover" then
			if ply:KeyDown(IN_ATTACK2) or ply:KeyDownLast(IN_ATTACK2) then
				if not proptect.CheckConstraints(ply, self) then
					return false
				end
			end
		end

		return true
	end

	function entmeta:CPPICanPhysgun(ply)
		if not IsValid(ply) then
			return false
		end
		if proptect.PhysGravGunPickup(ply, self) == false then
			return false
		end
		return true
	end
	entmeta.CPPICanPickup = entmeta.CPPICanPhysgun
	entmeta.CPPICanPunt = entmeta.CPPICanPhysgun

	function entmeta:CPPICanUse(ply)
		if not IsValid(ply) then
			return false
		end
		if proptect.PlayerUse(ply, self) == false then
			return false
		end
		return true
	end

	function entmeta:CPPICanDamage(ply)
		if not IsValid(ply) then
			return false
		end

		if tonumber(proptect.Config["edmg"]) == 0 then
			return true
		end

		return proptect.PlayerCanTouch(ply, self)
	end

	function entmeta:CPPIDrive(ply)
		if not IsValid(ply) then
			return false
		end

		if proptect.CanDrive(ply, self) == false then
			return false
		end

		return true
	end

	function entmeta:CPPICanProperty(ply, prop)
		if not IsValid(ply) then
			return false
		end

		if proptect.CanProperty(ply, prop, self) == false then
			return false
		end

		return true
	end

	function entmeta:CPPICanEditVariable(ply, key, val, edit)
		if not IsValid(ply) then
			return false
		end

		if proptect.CanEditVariable(self, ply, key, val, edit) == false then
			return false
		end

		return true
	end
end

local function CPPIInitGM()
	function GAMEMODE:CPPIAssignOwnership(ply, ent)
	end
	function GAMEMODE:CPPIFriendsChanged(ply, ent)
	end
end
hook.Add("Initialize", "prop_protection", CPPIInitGM)


if CLIENT then
		------------------------------------
	--	Simple Prop Protection
	--	By Spacetech, Maintained by Donkie
	-- 	https://github.com/Donkie/SimplePropProtection
	------------------------------------

	proptect.AdminCPanel = nil
	proptect.ClientCPanel = nil

	CreateClientConVar("spp_check", 1, false, true)
	CreateClientConVar("spp_admin", 1, false, true)
	CreateClientConVar("spp_use", 1, false, true)
	CreateClientConVar("spp_edmg", 1, false, true)
	CreateClientConVar("spp_pgr", 1, false, true)
	CreateClientConVar("spp_awp", 1, false, true)
	CreateClientConVar("spp_dpd", 1, false, true)
	CreateClientConVar("spp_dae", 0, false, true)
	CreateClientConVar("spp_delay", 120, false, true)

	local ent = NULL

	timer.Create("proptect_owner_label", 0.25, 0, function()
		ent = NULL

		if not IsValid(LocalPlayer()) then
			return
		end
		local tr = util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
		if tr.HitNonWorld then
			if IsValid(tr.Entity) and not tr.Entity:IsPlayer() and not LocalPlayer():InVehicle() then
				ent = tr.Entity
				hook.Add("HUDPaint", "prop_protection", function()
					if not ent:IsValid() then return end

					local PropOwner = "Owner: "
					local OwnerObj = ent:GetNWEntity("OwnerObj", false)
					if IsValid(OwnerObj) and OwnerObj:IsPlayer() then
						PropOwner = PropOwner .. OwnerObj:Name()
					else
						OwnerObj = ent:GetNWString("Owner", "N/A")
						if type(OwnerObj) == "string" then
							PropOwner = PropOwner .. OwnerObj
						elseif IsValid(OwnerObj) and OwnerObj:IsPlayer() then
							PropOwner = PropOwner .. OwnerObj:Name()
						else
							PropOwner = PropOwner .. "N/A"
						end
					end
					surface.SetFont("Default")
					local w, h = surface.GetTextSize(PropOwner)
					w = w + 25
					draw.RoundedBox(4, ScrW() - (w + 8), (ScrH() / 2 - 200) - (8), w + 8, h + 8, Color(0, 0, 0, 150))
					draw.SimpleText(PropOwner, "Default", ScrW() - (w / 2) - 7, ScrH() / 2 - 200, Color(255, 255, 255, 255), 1, 1)
				end)
			end
		end

		if not ent:IsValid() then
			hook.Remove("HUDPaint", "prop_protection")
		end
	end)

	function proptect.AdminPanel(Panel)
		Panel:ClearControls()

		if not LocalPlayer():IsAdmin() then
			Panel:AddControl("Label", {Text = "You are not an admin"})
			return
		end

		if not proptect.AdminCPanel then
			proptect.AdminCPanel = Panel
		end

		Panel:AddControl("Label", {Text = "SPP - Admin Panel - Spacetech"})

		Panel:AddControl("CheckBox", {Label = "Prop Protection", Command = "spp_check"})
		Panel:AddControl("CheckBox", {Label = "Admins Can Do Everything", Command = "spp_admin"})
		Panel:AddControl("CheckBox", {Label = "+Use Protection", Command = "spp_use"})
		Panel:AddControl("CheckBox", {Label = "Entity Damage Protection", Command = "spp_edmg"})
		Panel:AddControl("CheckBox", {Label = "Physgun Reload Protection", Command = "spp_pgr"})
		Panel:AddControl("CheckBox", {Label = "Admins Can Touch World Prop", Command = "spp_awp"})
		Panel:AddControl("CheckBox", {Label = "Disconnect Prop Deletion", Command = "spp_dpd"})
		Panel:AddControl("CheckBox", {Label = "Delete Admin Entities", Command = "spp_dae"})
		Panel:AddControl("Slider", {Label = "Deletion Delay (Seconds)", Command = "spp_delay", Type = "Integer", Min = "10", Max = "500"})
		Panel:AddControl("Button", {Text = "Apply Settings", Command = "spp_apply"})

		Panel:AddControl("Label", {Text = "Cleanup Panel"})

		for k, ply in pairs(player.GetAll()) do
			if IsValid(ply) then
				Panel:AddControl("Button", {Text = ply:Nick(), Command = "spp_cleanupprops " .. ply:EntIndex()})
			end
		end

		Panel:AddControl("Label", {Text = "Other Cleanup Options"})
		Panel:AddControl("Button", {Text = "Cleanup Disconnected Players Props", Command = "spp_cdp"})
	end

	function proptect.ClientPanel(Panel)
		Panel:ClearControls()

		if not proptect.ClientCPanel then
			proptect.ClientCPanel = Panel
		end

		Panel:AddControl("Label", {Text = "SPP - Client Panel - Spacetech"})

		Panel:AddControl("Button", {Text = "Cleanup Props", Command = "spp_cleanupprops"})
	end

	function proptect.SpawnMenuOpen()
		if IsValid(proptect.AdminCPanel) then
			proptect.AdminPanel(proptect.AdminCPanel)
		end

		if IsValid(proptect.ClientCPanel) then
			proptect.ClientPanel(proptect.ClientCPanel)
		end
	end
	hook.Add("SpawnMenuOpen", "prop_protection", proptect.SpawnMenuOpen)

	function proptect.PopulateToolMenu()
		spawnmenu.AddToolMenuOption("Utilities", "Simple Prop Protection", "Admin", "Admin", "", "", proptect.AdminPanel)
		spawnmenu.AddToolMenuOption("Utilities", "Simple Prop Protection", "Client", "Client", "", "", proptect.ClientPanel)
	end
	hook.Add("PopulateToolMenu", "prop_protection", proptect.PopulateToolMenu)
end

if SERVER then
	------------------------------------
	--	Simple Prop Protection
	--	By Spacetech, Maintained by Donkie
	-- 	https://github.com/Donkie/SimplePropProtection
	------------------------------------

	proptect.Props = {}
	proptect.WeirdTraces = {
		"wire_winch",
		"wire_hydraulic",
		"slider",
		"hydraulic",
		"winch",
		"muscle"
	}

	function proptect.SetupSettings()
		if not sql.TableExists("prop_protection") then
			sql.Query("CREATE TABLE IF NOT EXISTS spropprotection(toggle INTEGER NOT NULL, admin INTEGER NOT NULL, use INTEGER NOT NULL, edmg INTEGER NOT NULL, pgr INTEGER NOT NULL, awp INTEGER NOT NULL, dpd INTEGER NOT NULL, dae INTEGER NOT NULL, delay INTEGER NOT NULL);")
			sql.Query("INSERT INTO spropprotection(toggle, admin, use, edmg, pgr, awp, dpd, dae, delay) VALUES(1, 1, 1, 1, 1, 1, 1, 0, 120)")
		end
		return sql.QueryRow("SELECT * FROM spropprotection LIMIT 1")
	end

	proptect.Config = proptect.SetupSettings()

	function proptect.NotifyAll(str)
		aowl.Message(player.GetAll(), str, "generic")
	end

	function proptect.Notify(ply, str)
		aowl.Message(ply, str, "generic")
	end

	function proptect.AdminReloadPlayer(ply)
		if not IsValid(ply) then
			return
		end
		for k,v in pairs(proptect.Config) do
			local stuff = k
			if stuff == "toggle" then
				stuff = "check"
			end
			ply:ConCommand("spp_" .. stuff .. " " .. v .. "\n")
		end
	end

	function proptect.AdminReload(ply)
		if ply then
			proptect.AdminReloadPlayer(ply)
		else
			for k,v in pairs(player.GetAll()) do
				proptect.AdminReloadPlayer(v)
			end
		end
	end

	function proptect.UnOwnProp(ent)
		if not IsValid(ent) then return false end

		proptect.Props[ent:EntIndex()] = nil
		ent:SetNWString("Owner", nil)
		ent:SetNWEntity("OwnerObj", nil)

		return true
	end

	function proptect.PlayerMakePropOwner(ply, ent)
		if ent:IsPlayer() then
			return false
		end

		local ret = hook.Run("CPPIAssignOwnership", ply, ent, ply:UniqueID())
		if ret == false then return end

		proptect.Props[ent:EntIndex()] = {
			Ent = ent,
			Owner = ply,
			SteamID = ply:SteamID()
		}
		ent:SetNWString("Owner", ply:Nick())
		ent:SetNWEntity("OwnerObj", ply)

		return true
	end

	if cleanup then
		local Clean = cleanup.Add
		function cleanup.Add(ply, Type, ent)
			if ent then
				if ply:IsPlayer() and IsValid(ent) then
					proptect.PlayerMakePropOwner(ply, ent)
				end
			end
			Clean(ply, Type, ent)
		end
	end

	local plymeta = FindMetaTable("Player")
	if plymeta.AddCount then
		local Backup = plymeta.AddCount
		function plymeta:AddCount(Type, ent)
			proptect.PlayerMakePropOwner(self, ent)
			Backup(self, Type, ent)
		end
	end

	function proptect.CheckConstraints(ply, ent)
		for k,v in pairs(constraint.GetAllConstrainedEntities(ent) or {}) do
			if IsValid(v) then
				if not proptect.PlayerCanTouch(ply, v) then
					return false
				end
			end
		end
		return true
	end

	function proptect.IsFriend(ply, ent)
		return ply:CanAlter(ent)
	end

	function proptect.PlayerCanTouch(ply, ent)
		if tonumber(proptect.Config["toggle"]) == 0 or ent:GetClass() == "worldspawn" then
			return true
		end

		if not ent:GetNWString("Owner") or ent:GetNWString("Owner") == "" and not ent:IsPlayer() then
			return true
		end

		if ent:GetNWString("Owner") == "World" then
			if ply:IsAdmin() and tonumber(proptect.Config["awp"]) == 1 and tonumber(proptect.Config["admin"]) == 1 then
				return true
			end
		elseif ply:IsAdmin() and tonumber(proptect.Config["admin"]) == 1 then
			return true
		end

		if proptect.Props[ent:EntIndex()] then
			if proptect.Props[ent:EntIndex()].SteamID == ply:SteamID() or proptect.IsFriend(ply, ent) then
				return true
			end
		end
		return false
	end

	function proptect.DRemove(SteamID, PlayerName)
		for k,v in pairs(proptect.Props) do
			if IsValid(v.Ent) and v.SteamID == SteamID then
				v.Ent:Remove()
				proptect.Props[k] = nil
			end
		end
		proptect.NotifyAll(tostring(PlayerName) .. "'s props have been cleaned up")
	end

	function proptect.PlayerInitialSpawn(ply)
		proptect[ply:SteamID()] = {}
		proptect.AdminReload(ply)
		local TimerName = "prop_protection" .. ply:SteamID()
		if timer.Exists(TimerName) then
			timer.Remove(TimerName)
		end
	end
	hook.Add("PlayerInitialSpawn", "prop_protection", proptect.PlayerInitialSpawn)

	function proptect.Disconnect(ply)
		if tonumber(proptect.Config["dpd"]) == 1 then
			if ply:IsAdmin() and tonumber(proptect.Config["dae"]) == 0 then
				return
			end
			local sid = ply:SteamID()
			local nick = ply:Nick()

			timer.Create("prop_protection" .. sid, tonumber(proptect.Config["delay"]), 1, function()
				proptect.DRemove(sid, nick)
			end)
		end
	end
	hook.Add("PlayerDisconnected", "prop_protection", proptect.Disconnect)

	function proptect.PhysGravGunPickup(ply, ent)
		if not IsValid(ent) then
			return
		end
		if not proptect.KVcanuse[ent:EntIndex()] then proptect.KVcanuse[ent:EntIndex()] = -1 end
		if proptect.KVcantouch[ent:EntIndex()] == 0 then
			return false
		end
		if proptect.KVcantouch[ent:EntIndex()] == 2 or (proptect.KVcantouch[ent:EntIndex()] == 1 and ply:IsAdmin()) then
			return
		end
		if ent:IsPlayer() and ply:IsAdmin() and tonumber(proptect.Config["admin"]) == 1 then
			return
		end
		if not proptect.PlayerCanTouch(ply, ent) then
			return false
		end
	end
	hook.Add("GravGunPunt", "prop_protection", proptect.PhysGravGunPickup)
	hook.Add("GravGunPickupAllowed", "prop_protection", proptect.PhysGravGunPickup)
	hook.Add("PhysgunPickup", "prop_protection", proptect.PhysGravGunPickup)

	function proptect.CanTool(ply, tr, mode)
		if tr.HitWorld then
			return
		end
		local ent = tr.Entity
		if not IsValid(ent) or ent:IsPlayer() then
			return false
		end

		if not proptect.KVcanuse[ent:EntIndex()] then proptect.KVcanuse[ent:EntIndex()] = -1 end

		if not proptect.PlayerCanTouch(ply, ent) or proptect.KVcantool[ent:EntIndex()] == 0 or (proptect.KVcantool[ent:EntIndex()] == 1 and not ply:IsAdmin()) then
			return false
		elseif mode == "remover" then
			if ply:KeyDown(IN_ATTACK2) or ply:KeyDownLast(IN_ATTACK2) then
				if not proptect.CheckConstraints(ply, ent) then
					return false
				end
			end
		elseif mode == "nail" or table.HasValue(proptect.WeirdTraces, mode) then
			local Trace = {}
			Trace.start = tr.HitPos
			if mode == "nail" then
				Trace.endpos = tr.HitPos + (ply:GetAimVector() * 16.0)
				Trace.filter = {ply, tr.Entity}
			else
				Trace.endpos = Trace.start + (tr.HitNormal * 16384)
				Trace.filter = {ply}
			end

			local tr2 = util.TraceLine(Trace)
			if not proptect.KVcanuse[tr2.Entity:EntIndex()] then proptect.KVcanuse[tr2.Entity:EntIndex()] = -1 end
			if tr2.Hit and IsValid(tr2.Entity) and not tr2.Entity:IsPlayer() then
				if not proptect.PlayerCanTouch(ply, tr2.Entity) or proptect.KVcantool[tr2.Entity:EntIndex()] == 0 or (proptect.KVcantool[tr2.Entity:EntIndex()] == 1 and not ply:IsAdmin()) then
					return false
				end
			end
		end
	end
	hook.Add("CanTool", "prop_protection", proptect.CanTool)

	function proptect.EntityTakeDamageFireCheck(ent)
		if not IsValid(ent) then
			return
		end
		if ent:IsOnFire() then
			ent:Extinguish()
		end
	end

	function proptect.EntityTakeDamage(ent, dmginfo)
		local attacker = dmginfo:GetAttacker()
		if tonumber(proptect.Config["edmg"]) == 0 then
			return
		end
		if not IsValid(ent) or ent:IsPlayer() or not attacker:IsPlayer() then
			return
		end
		if not proptect.PlayerCanTouch(attacker, ent) then
			dmginfo:SetDamage(0)
			timer.Simple(0.1,
				function()
					if IsValid(ent) then proptect.EntityTakeDamageFireCheck(ent) end
				end)
		end
	end
	hook.Add("EntityTakeDamage", "prop_protection", proptect.EntityTakeDamage)

	function proptect.PlayerUse(ply, ent)
		if not proptect.KVcanuse[ent:EntIndex()] then proptect.KVcanuse[ent:EntIndex()] = -1 end
		if proptect.KVcanuse[ent:EntIndex()] == 0 or (proptect.KVcantouch[ent:EntIndex()] == 1 and not ply:IsAdmin()) then
			return false
		end
		if proptect.KVcanuse[ent:EntIndex()] == 2 then
			return
		end
		if IsValid(ent) and tonumber(proptect.Config["use"]) == 1 then
			if not proptect.PlayerCanTouch(ply, ent) and ent:GetNWString("Owner") ~= "World" then
				return false
			end
		end
	end
	--hook.Add("PlayerUse", "prop_protection", proptect.PlayerUse)

	function proptect.OnPhysgunReload(weapon, ply)
		if tonumber(proptect.Config["pgr"]) == 0 then
			return
		end
		local tr = util.TraceLine(util.GetPlayerTrace(ply))
		if not tr.HitNonWorld or not IsValid(tr.Entity) or tr.Entity:IsPlayer() then
			return
		end
		if not proptect.PlayerCanTouch(ply, tr.Entity) then
			return false
		end
	end
	hook.Add("OnPhysgunReload", "prop_protection", proptect.OnPhysgunReload)

	function proptect.EntityRemoved(ent)
		proptect.Props[ent:EntIndex()] = nil
	end
	hook.Add("EntityRemoved", "prop_protection", proptect.EntityRemoved)

	function proptect.PlayerSpawnedSENT(ply, ent)
		proptect.PlayerMakePropOwner(ply, ent)
	end
	hook.Add("PlayerSpawnedSENT", "prop_protection", proptect.PlayerSpawnedSENT)

	function proptect.PlayerSpawnedVehicle(ply, ent)
		proptect.PlayerMakePropOwner(ply, ent)
	end
	hook.Add("PlayerSpawnedVehicle", "prop_protection", proptect.PlayerSpawnedVehicle)

	--Thanks to TP Hunter NL for these two hooks
	--Causes ragdolls and weapons dropped by NPCs to be owned by the NPC's owner.
	function proptect.NPCCreatedRagdoll(npc,doll)
		if proptect.Props[npc:EntIndex()] and not proptect.Props[doll:EntIndex()] and IsValid(proptect.Props[npc:EntIndex()].Owner) then
			proptect.PlayerMakePropOwner(proptect.Props[npc:EntIndex()].Owner,doll)
		end
	end
	hook.Add("CreateEntityRagdoll","prop_protection",proptect.NPCCreatedRagdoll)

	function proptect.NPCDeath(npc,attacker,weapon)
		if type(npc) == "NextBot" then return end
		if not IsValid(npc:GetActiveWeapon()) then return end
		if proptect.Props[npc:EntIndex()] and not proptect.Props[npc:GetActiveWeapon():EntIndex()] and IsValid(proptect.Props[npc:EntIndex()].Owner) then
			proptect.PlayerMakePropOwner(proptect.Props[npc:EntIndex()].Owner,npc:GetActiveWeapon())
		end
	end
	hook.Add("OnNPCKilled","prop_protection",proptect.NPCDeath)

	function proptect.WeaponEquip(wep, owner)
		proptect.PlayerMakePropOwner(owner, wep)
	end
	hook.Add("WeaponEquip", "prop_protection", proptect.WeaponEquip)

	function proptect.CDP(ply, cmd, args)
		if IsValid(ply) and not ply:IsAdmin() then
			ply:PrintMessage( HUD_PRINTCONSOLE, "You are not an admin!" )
			return
		end
		for k,v in pairs(proptect.Props) do
			local Found = false
			for k2,v2 in pairs(player.GetAll()) do
				if v.SteamID == v2:SteamID() then
					Found = true
				end
			end
			if not Found then
				local Ent = v.Ent
				if IsValid(Ent) then
					Ent:Remove()
				end
				proptect.Props[k] = nil
			end
		end
		proptect.NotifyAll("Disconnected players props have been cleaned up")
	end
	concommand.Add("spp_cdp", proptect.CDP)

	function proptect.CleanupPlayerProps(ply)
		for k,v in pairs(proptect.Props) do
			if v.SteamID == ply:SteamID() then
				local Ent = v.Ent
				if IsValid(Ent) then
					Ent:Remove()
				end
				proptect.Props[k] = nil
			end
		end
	end

	function proptect.CleanupProps(ply, cmd, args)
		local EntIndex = args[1]
		if not EntIndex or EntIndex == "" then
			if not IsValid(ply) then
				MsgN("usage: spp_cleanupprops <entity_id>")
				return
			end
			proptect.CleanupPlayerProps(ply)
			proptect.Notify(ply, "Your props have been cleaned up")
		elseif not IsValid(ply) or ply:IsAdmin() then
			for k,v in pairs(player.GetAll()) do
				if tonumber(EntIndex) == v:EntIndex() then
					proptect.CleanupPlayerProps(v)
					proptect.NotifyAll(v:Nick() .. "'s props have been cleaned up")
				end
			end
		else
			ply:PrintMessage( HUD_PRINTCONSOLE, "You are not an admin!" )
		end
	end
	concommand.Add("spp_cleanupprops", proptect.CleanupProps)

	function proptect.ApplySettings(ply, cmd, args)
		if not IsValid(ply) then
			MsgN("This command can only be run in-game!")
			return
		end
		if not ply:IsAdmin() then
			return
		end

		local toggle = tonumber(ply:GetInfo("spp_check") or 1)
		local admin = tonumber(ply:GetInfo("spp_admin") or 1)
		local use = tonumber(ply:GetInfo("spp_use") or 1)
		local edmg = tonumber(ply:GetInfo("spp_edmg") or 1)
		local pgr = tonumber(ply:GetInfo("spp_pgr") or 1)
		local awp = tonumber(ply:GetInfo("spp_awp") or 1)
		local dpd = tonumber(ply:GetInfo("spp_dpd") or 1)
		local dae = tonumber(ply:GetInfo("spp_dae") or 1)
		local delay = math.Clamp(tonumber(ply:GetInfo("spp_delay") or 120), 1, 500)

		sql.Query("UPDATE spropprotection SET toggle = " .. toggle .. ", admin = " .. admin .. ", use = " .. use .. ", edmg = " .. edmg .. ", pgr = " .. pgr .. ", awp = " .. awp .. ", dpd = " .. dpd .. ", dae = " .. dae .. ", delay = " .. delay)

		proptect.Config = sql.QueryRow("SELECT * FROM spropprotection LIMIT 1")

		timer.Simple(2, proptect.AdminReload)

		proptect.Notify(ply, "Admin settings have been updated")
	end
	concommand.Add("spp_apply", proptect.ApplySettings)

	function proptect.WorldOwner()
		local WorldEnts = 0
		for k,v in pairs(ents.FindByClass("*")) do
			if not v:IsPlayer() and not v:GetNWString("Owner", false) then
				v:SetNWString("Owner", "World")
				WorldEnts = WorldEnts + 1
			end
		end
		MsgN("=================================================")
		MsgN("Simple Prop Protection: " .. tostring(WorldEnts) .. " props belong to world")
		MsgN("=================================================")
	end
	timer.Simple(2, proptect.WorldOwner)

	function proptect.CanEditVariable( ent, ply, key, val, editor )
		if not proptect.PlayerCanTouch(ply, ent) then return false end
	end
	hook.Add("CanEditVariable", "prop_protection", proptect.CanEditVariable)

	function proptect.AllowPlayerPickup( ply, ent )
		if not proptect.PlayerCanTouch(ply, ent) then return false end
	end
	hook.Add("AllowPlayerPickup", "prop_protection", proptect.AllowPlayerPickup)

	function proptect.CanDrive( ply, ent )
		if not proptect.PlayerCanTouch(ply, ent) then return false end
		if ent:GetNWString("Owner") == "World" then return false end
	end
	hook.Add("CanDrive", "prop_protection", proptect.CanDrive)

	function proptect.CanProperty( ply, property, ent )
		if not proptect.PlayerCanTouch(ply, ent) then return false end
		if ent:GetNWString("Owner") == "World" then return false end
	end
	hook.Add("CanProperty", "prop_protection", proptect.CanProperty)



	-- Modification allowing mappers to add keyvalues to entites that will override settings of spp
	-- so setting spp_canuse to 2 in some entity would make it possible for everyone to use it.
	--
	-- Author: Sebi

	proptect.KVcantouch = {}
	proptect.KVcanuse = {}
	proptect.KVcantool = {}

	function proptect.CheckKeyvalue( ent, key, val )
		if not IsValid(ent) then return end
		if val == nil then return end

		if key == "spp_cantouch" then
			proptect.KVcantouch[ ent:EntIndex() ] = tonumber(val)
		elseif key == "spp_canuse" then
			proptect.KVcanuse[ ent:EntIndex() ] = tonumber(val)
		elseif key == "spp_cantool" then
			proptect.KVcantool[ ent:EntIndex() ] = tonumber(val)
		end
	end

	hook.Add( "EntityKeyValue", "prop_protection", proptect.CheckKeyvalue )
end