local dmgvar = CreateClientConVar("cl_godmode", "3", true, true, "0 = off, 1 = on, 2 = world damage, 3 = friend damage + world damage")

if CLIENT then
	local victim = NULL

	timer.Create("cl_godmode", 0.1, 0, function()
		local ply = LocalPlayer()
		if not ply:IsValid() then return end
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
			local mode = victim:GetInfoNum("cl_godmode", 1)

			victim:SetNWBool("cl_godmode", mode == 0)
		end
	end)

	timer.Simple(0.1, function()
		RunConsoleCommand("sbox_godmode", "0")
	end)

	hook.Add("PlayerSpawn", "cl_godmode", function(ply)
		ply.cl_dmg_mode_want_attack = nil
	end)

	local suppress = false

	hook.Add("EntityTakeDamage", "cl_godmode", function(victim, dmginfo)
		if suppress then return end

		if not victim:IsPlayer() then return end

		local attacker = dmginfo:GetAttacker()

		if victim:GetInfoNum("cl_godmode", 1) == 2 or victim:GetInfoNum("cl_godmode", 1) == 3 then
			if attacker == victim or attacker:IsWorld() or (attacker.CPPIGetOwner and not attacker:CPPIGetOwner()) then
				return
			end
		end

		if (not attacker:IsNPC() and not attacker:IsPlayer()) and attacker.CPPIGetOwner and attacker:CPPIGetOwner() then
			attacker = attacker:CPPIGetOwner()
		end

		local npc

		if attacker:IsNPC() and attacker.CPPIGetOwner and attacker:CPPIGetOwner() then
			npc = attacker
			attacker = attacker:CPPIGetOwner()
		end

		if attacker:IsPlayer() then
			if attacker.CanAlter and attacker:CanAlter(victim) and victim:GetInfoNum("cl_godmode", 1) == 3 then
				return
			end

			if attacker ~= victim then
				attacker.cl_dmg_mode_want_attack = attacker.cl_dmg_mode_want_attack or {}
				attacker.cl_dmg_mode_want_attack[victim] = true
			end
		end

		local godmode = victim:GetInfoNum("cl_godmode", 1) > 0

		if attacker:IsPlayer() and victim.cl_dmg_mode_want_attack and victim.cl_dmg_mode_want_attack[attacker] then
			victim:SetNWBool("cl_godmode", false)
			return
		else
			victim:SetNWBool("cl_godmode", godmode)
		end

		if godmode then
			if attacker:IsPlayer() then
				if attacker ~= victim then
					attacker.cl_dmg_mode_want_attack = attacker.cl_dmg_mode_want_attack or {}
					attacker.cl_dmg_mode_want_attack[victim] = true
				end

				local wep = attacker:GetActiveWeapon()
				if wep:IsValid() then
					wep:SetNWBool("cl_godmode_lethal", true)
				end

				if attacker ~= victim then
					suppress = true
					dmginfo:SetAttacker(victim)
					dmginfo:SetDamageForce(vector_origin)
					attacker:TakeDamageInfo(dmginfo)

					if npc then
						npc:TakeDamageInfo(dmginfo)
					end
					suppress = false
				end
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
	end)

	function _G.cl_godmode_physics_collide(self, data)
		local victim = data.HitEntity
		if not victim:IsPlayer() then return end

		if victim:GetInfoNum("cl_godmode", 1) == 0 then
			return
		end

		local attacker = self:CPPIGetOwner()

		if self:GetOwner():IsPlayer() then
			attacker = self
		end

		if self.cl_godmode_owner_override and self.cl_godmode_owner_override:IsValid() then
			attacker = self.cl_godmode_owner_override
		end

		if victim:IsPlayer() and attacker and attacker:IsPlayer() and not attacker:CanAlter(victim) then
			local dmg = DamageInfo()
			dmg:SetDamageType(DMG_CRUSH)
			dmg:SetAttacker(attacker)
			dmg:SetInflictor(self)
			dmg:SetDamage(data.Speed/10)
			dmg:SetDamageForce(self:GetVelocity())
			suppress = true
			attacker:TakeDamageInfo(dmg)
			suppress = false

			if not victim.cl_godmode_nocollide_hack then
				victim:SetVelocity(Vector(0,0,0))
				local old = victim:GetMoveType()
				victim:SetMoveType(MOVETYPE_NOCLIP)
				victim.cl_godmode_nocollide_hack = true
				timer.Simple(0, function()
					if victim:IsValid() then
						victim:SetMoveType(old)
						victim.cl_godmode_nocollide_hack = nil
						victim:SetVelocity(-victim:GetVelocity())
					end
				end)
			end
		end
	end

	hook.Add("PhysgunPickup", "cl_godmode", function(ply, ent)
		ent.cl_godmode_owner_override = ply
		if not ent.cl_godmode_physics_collide_added and ply.CanAlter and ent.CPPIGetOwner then
			ent.cl_godmode_physics_collide_added = true
			ent:AddCallback("PhysicsCollide", function(...) _G.cl_godmode_physics_collide(...) end)
		end
	end)

	hook.Add("PhysgunDrop", "cl_godmode", function(ply, ent)
		ent.cl_godmode_owner_override = nil
	end)
end
