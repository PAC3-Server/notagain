local dmgvar = CreateClientConVar("cl_godmode", "1", true, true)

if CLIENT then
	local victim = NULL

	timer.Create("cl_godmode", 0.1, 0, function()
		local ply = LocalPlayer()
		victim = ply:GetEyeTrace().Entity -- todo: fatter trace?
	end)

	local last_play = 0
	local mat = CreateMaterial("cl_dmg_mode_block", "UnlitGeneric", {
		["$BaseTexture"] = "vgui/cursors/no",
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})


	hook.Add("PostDrawHUD", "cl_godmode", function()
		if last_play > RealTime() then
			surface.SetDrawColor(255,0,0,200 + math.sin(RealTime()*10)*50)
			surface.SetMaterial(mat)
			surface.DrawTexturedRect(ScrW()/2 - 32, ScrH()/2 - 32, 64, 64)
		end
	end)

	hook.Add("CreateMove", "cl_godmode", function(cmd)
		if not victim:IsPlayer() or victim:GetNWBool("cl_godmode", 1) == false then return end

		local attacker = LocalPlayer()
		local wep = attacker:GetActiveWeapon()

		if wep:GetNWBool("cl_godmode_lethal") then
			if cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2) then
				local buttons = cmd:GetButtons()
				if cmd:KeyDown(IN_ATTACK) then
					buttons = bit.band(buttons, bit.bnot(IN_ATTACK))
				end
				if cmd:KeyDown(IN_ATTACK2) then
					buttons = bit.band(buttons, bit.bnot(IN_ATTACK2))
				end
				cmd:SetButtons(buttons)
				if last_play < RealTime() then
					surface.PlaySound("buttons/button11.wav")
					last_play = RealTime() + 0.5

					net.Start("cl_godmode_ask")
					net.WriteEntity(victim)
					net.SendToServer()
				end
				return true
			end
		end
	end)

	net.Receive("cl_godmode_clear_decals", function()
		local ent = net.ReadEntity()
		if ent:IsValid() then
			ent:RemoveAllDecals()
		end
	end)
end

hook.Add("PlayerTraceAttack", "cl_godmode", function(victim, dmginfo)
	if victim:GetNWBool("cl_godmode", 1) == true  then
		return false
	end
end)

if SERVER then
	RunConsoleCommand("sbox_godmode", "0")

	util.AddNetworkString("cl_godmode_ask")
	util.AddNetworkString("cl_godmode_clear_decals")

	net.Receive("cl_godmode_ask", function(len, attacker)
		local victim = net.ReadEntity()
		if victim:IsValid() and attacker:GetEyeTrace().Entity == victim then
			attacker.cl_dmg_mode_want_attack = attacker.cl_dmg_mode_want_attack or {}
			attacker.cl_dmg_mode_want_attack[victim] = true

			if victim.cl_dmg_mode_want_attack and victim.cl_dmg_mode_want_attack[attacker] then
				victim:SetNWBool("cl_godmode", false)
			end
		end
	end)

	hook.Add("PlayerSpawn", "cl_godmode", function(ply)
		ply.cl_dmg_mode_want_attack = nil
	end)

	local suppress = false

	hook.Add("EntityTakeDamage", "cl_godmode", function(victim, dmginfo)
		if suppress then return end

		local attacker = dmginfo:GetAttacker()

		if victim:IsPlayer() then
			if attacker:IsPlayer() then
				attacker.cl_dmg_mode_want_attack = attacker.cl_dmg_mode_want_attack or {}
				attacker.cl_dmg_mode_want_attack[victim] = true
			end

			if attacker:IsPlayer() and victim.cl_dmg_mode_want_attack and victim.cl_dmg_mode_want_attack[attacker] then
				victim:SetNWBool("cl_godmode", false)
				return
			else
				victim:SetNWBool("cl_godmode", victim:GetInfoNum("cl_godmode", 1) == 1)
			end

			if victim:GetInfoNum("cl_godmode", 1) == 1 then
				if attacker:IsPlayer() then
					attacker.cl_dmg_mode_want_attack = attacker.cl_dmg_mode_want_attack or {}
					attacker.cl_dmg_mode_want_attack[victim] = true

					local wep = attacker:GetActiveWeapon()
					if wep:IsValid() then
						wep:SetNWBool("cl_godmode_lethal", true)
					end

					suppress = true
					dmginfo:SetAttacker(victim)
					attacker:TakeDamageInfo(dmginfo)
					suppress = false
				end

				dmginfo:SetDamage(0)
				dmginfo:SetDamageForce(vector_origin)

				net.Start("cl_godmode_clear_decals", true) net.WriteEntity(victim) net.Broadcast()

				-- no blood
				if not victim.damage_mode_bleed_color then
					victim.damage_mode_bleed_color = victim:GetBloodColor()
					victim:SetBloodColor(DONT_BLEED)
				end

				return false
			end

			if victim.damage_mode_bleed_color then
				victim:SetBloodColor(victim.damage_mode_bleed_color)
				victim.damage_mode_bleed_color = nil
			end
		end
	end)

	local function PassGoddedVarToPhysChild(data, physobj)
		if IsValid(data.Entity) and not data.Entity:IsWorld() and IsValid(data.Entity:GetPhysicsObject()) and not data.Entity.cl_godmode_dropped then
			data.Entity.cl_godmode_dropped = true
			local phys = data.Entity:GetPhysicsObject()
			if phys:IsValid() then
				phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
				data.Entity:AddCallback("PhysicsCollide", PassGoddedVarToPhysChild)
			end
		end
	end

	local function PreventGoddedPropKills(ply,ent)
		if ply:GetInfoNum("cl_godmode", 1) == 1 then
			if not ent.cl_godmode_dropped then
				ent.cl_godmode_dropped = true
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					ent:AddCallback("PhysicsCollide", PassGoddedVarToPhysChild)
				end
			elseif ent.cl_godmode_dropped then
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
				end
				ent.cl_godmode_dropped = false
			end
		end
	end

	local function AddGoddedVarToSpawnedProps(ply, mdl, ent)
		if ply:GetInfoNum("cl_godmode",1) == 1 then
			if not ent.cl_godmode_dropped then
				ent.cl_godmode_dropped = true
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
					ent:AddCallback("PhysicsCollide", PassGoddedVarToPhysChild)
				end
			end
		end
	end

	hook.Add("PhysgunPickup", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PhysgunDrop", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PlayerSpawnedSENT", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PlayerSpawnedVehicle", "cl_godmode", PreventGoddedPropKills)
	hook.Add("PlayerSpawnedProp", "cl_godmode", AddGoddedVarToSpawnedProps)
	hook.Add("PlayerSpawnedRagdoll", "cl_godmode", AddGoddedVarToSpawnedProps)
	hook.Add("PlayerSpawnedSWEP", "cl_godmode", AddGoddedVarToSpawnedProps)

end
