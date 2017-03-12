do
	local ENT = {}
	ENT.Type = "anim"
	ENT.Base = "base_anim"
	ENT.ClassName = "shield"

	local models = {
		{
			mdl = "models/hunter/plates/plate1x1.mdl",
			translate = function(pos, ang)
				return pos, ang
			end,
		},
		{
			mdl = "models/gibs/gunship_gibs_eye.mdl",
			translate = function(pos, ang)
				ang:RotateAroundAxis(ang:Forward(), 100)
				ang:RotateAroundAxis(ang:Right(), 35)

				return pos, ang
			end,
		},
		{
			mdl = "models/props_junk/sawblade001a.mdl",
			translate = function(pos, ang)
				return pos, ang
			end,
		},
		{
			mdl = "models/hunter/plates/plate1x2.mdl",
			translate = function(pos, ang)
				ang:RotateAroundAxis(ang:Up(), 90)
				return pos, ang
			end,
			csmdl = "models/props_combine/tprotato2.mdl",
			csmdl_scale = 0.7,
			csmdl_translate = function(pos, ang)
				ang:RotateAroundAxis(ang:Up(), -90)
				ang:RotateAroundAxis(ang:Right(), 90)
				return pos, ang
			end,
		},
		{
			mdl = "models/hunter/plates/plate1x1.mdl",
			translate = function(pos, ang)
				return pos, ang
			end,
			csmdl = "models/gibs/scanner_gib02.mdl",
			csmdl_scale = 4.5,
			csmdl_translate = function(pos, ang)
				pos = pos + ang:Forward()*-4
				ang:RotateAroundAxis(ang:Up(), -180)
				ang:RotateAroundAxis(ang:Right(), 45)
				ang:RotateAroundAxis(ang:Forward(), 45)
				return pos, ang
			end,
		},
		{
			mdl = "models/XQM/panel360.mdl",
			translate = function(pos, ang)
				ang:RotateAroundAxis(ang:Right(), -90)

				return pos, ang
			end,
			csmdl = "models/gibs/shield_scanner_gib2.mdl",
			csmdl_scale = 3.5,
			csmdl_translate = function(pos, ang)
				ang:RotateAroundAxis(ang:Up(), 180)
				ang:RotateAroundAxis(ang:Right(), 90)
				return pos, ang
			end,
		},
		{
			mdl = "models/props_phx/mechanics/medgear.mdl",
		},
		{
			mdl = "models/props_phx/gears/spur24.mdl",
		},
		{
			mdl = "models/props_phx/gears/spur36.mdl",
		},
		{
			mdl = "models/mechanics/wheels/wheel_spike_48.mdl",
		},
		{
			mdl = "models/xeon133/offroad/off-road-50.mdl",
			translate = function(pos, ang)
				ang:RotateAroundAxis(ang:Right(), -90)

				return pos, ang
			end,
		},
		{
			mdl = "models/Mechanics/wheels/rim_1.mdl",

		},
		{
			translate = function(pos, ang)
				pos = pos + ang:Up() * -8
				ang:RotateAroundAxis(ang:Up(), -90)

				return pos, ang
			end,
			mdl = "models/props_combine/combine_mine01.mdl",
		}
	}

	if SERVER then
		function ENT:Initialize()
			self:SetSkin(2)
			self:SetModel(models[self:GetSkin()].mdl)
			self:SetMoveType(MOVETYPE_NONE)
			self:SetSolid(SOLID_VPHYSICS)
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:StartMotionController()

			local phys = self:GetPhysicsObject()
			--phys:SetMass(100)
			phys:EnableGravity(false)

			phys:SetPos(self:GetOwner():WorldSpaceCenter())

			--self:SetPhysicsAttacker(self:GetOwner(), 10000)
		end

		function ENT:PhysicsSimulate(phys, dt)
			local pos, ang = self:GetPosAng()

			phys:Wake()
			phys:ComputeShadowControl({
				pos = pos,
				angle = ang,
				deltatime = dt,
				teleportdistance = 50,
				dampfactor = 0.9,
				maxspeeddamp = 1000000,
				maxspeed = 1000000,
				maxangulardamp = 1000000,
				maxangular = 1000000,
				secondstoarrive = 0.001,
			})
		end

		function ENT:Think()
			self:PhysWake()
		end

		function ENT:OnTakeDamage(dmginfo)
			local ply = self:GetOwner()
			if jattributes.HasStamina(ply) then
				jattributes.SetStamina(ply, math.max(jattributes.GetStamina(ply) - dmginfo:GetDamage(), 0))
				if jattributes.GetStamina(ply) == 0 then
					ply.shield_timer = CurTime() + 2
					self:Remove()
					self:EmitSound("physics/glass/glass_largesheet_break3.wav", 75, math.random(90,110))
					ply:SetNWBool("shield_stunned", true)
					ply:Freeze(true)
					timer.Simple(2, function()
						ply:Freeze(false)
						ply:SetNWBool("shield_stunned", false)
					end)
				end
			end
		end
	end

	function ENT:GetPosAng(pos, ang)
		local ply = self:GetOwner()

		pos = pos or ply:WorldSpaceCenter()
		ang = ang or ply:EyeAngles()

		ang.p = math.Clamp(ang.p + 90, -10, 90)

		pos = pos + ang:Up()*(30 + ang.p/50)
		pos = pos + ang:Forward()*-(10 - (-ang.p+90)/5)

		local info = models[self:GetSkin()]

		if info.translate then
			pos, ang = info.translate(pos, ang)
		end

		return pos, ang
	end

	if CLIENT then
		function ENT:Initialize()
			local ply = self:GetOwner()

			if not ply:IsValid() then return end

			self:SetRenderBounds(ply:OBBMins(), ply:OBBMaxs())

			local info = models[self:GetSkin()]

			if info.csmdl then
				self.csent = ClientsideModel(info.csmdl)
				self.csent:SetPos(self:GetPos())
				self.csent:SetNoDraw(true)
				if info.csmdl_scale then
					self.csent:SetModelScale(info.csmdl_scale)
				end
			end
		end

		function ENT:Draw()
			local info = models[self:GetSkin()]
			local ply = self:GetOwner()
			if not ply:IsValid() then return end
			if not ply.shield_wield_time then return end

			local pos, ang

			if (CurTime() - ply.shield_wield_time) < 0.3 then
				pos, ang = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_L_Hand"))
			end

			pos, ang = self:GetPosAng(pos, ang)

			if true then
				self:SetPos(pos)
				self:SetAngles(ang)
				self:SetupBones()
				self:DrawModel()
			end

			if self.csent then
				if info.csmdl_translate then
					pos, ang = info.csmdl_translate(pos, ang)
				end

				self.csent:SetPos(pos)
				self.csent:SetAngles(ang)
				self.csent:DrawModel()
			end
		end

		function ENT:OnRemove()
			SafeRemoveEntity(self.csent)
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end

hook.Add("SetupMove", "shield", function(ply, ucmd)
	local shield = ply:GetNWEntity("shield")
	if not shield:IsValid() then return end

	if ucmd:KeyDown(IN_ATTACK) then
		ucmd:SetButtons(bit.band(ucmd:GetButtons(), bit.bnot(IN_ATTACK)))
	end
	if ucmd:KeyDown(IN_ATTACK2) then
		ucmd:SetButtons(bit.band(ucmd:GetButtons(), bit.bnot(IN_ATTACK2)))
	end

	local wep = ply:GetActiveWeapon()
	if wep:IsValid() then
		wep:SetNextPrimaryFire(CurTime()+0.25)
		wep:SetNextSecondaryFire(CurTime()+0.25)
	end
end)
if SERVER then
	hook.Add("KeyPress", "shield", function(ply, key)
		if not ply:GetNWBool("rpg") then return end
		if key ~= IN_WALK then return end
		if ply.shield_timer and ply.shield_timer > CurTime() then return end
		if jattributes.GetStamina(ply) == 0 then return end
		local shield = ply:GetNWEntity("shield")

		if not shield:IsValid() then
			shield = ents.Create("shield")
			shield:SetOwner(ply)
			shield:SetPos(ply:GetPos())
			shield:Spawn()
			ply:SetNWEntity("shield", shield)
		end
	end)

	hook.Add("KeyRelease", "shield", function(ply, key)
		if key ~= IN_WALK then return end

		SafeRemoveEntity(ply:GetNWEntity("shield"))
	end)
end

local function manip_angles(ply, id, ang)
	if pac then
		pac.ManipulateBoneAngles(ply, id, ang)
	else
		ply:ManipulateBoneAngles(id, ang)
	end
end

hook.Add("UpdateAnimation", "shield", function(ply)
	if ply:GetNWEntity("shield"):IsValid() then
		ply.shield_unwield_time = nil
		ply.shield_wield_time = ply.shield_wield_time or CurTime()
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_bow"), math.min((CurTime() - ply.shield_wield_time)*1.25, 0.3), false)

		if CLIENT then
			manip_angles(ply, ply:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(math.Clamp(math.NormalizeAngle(ply:EyeAngles().p - 90), -180,-90),0,0))
		end

		return true

	elseif ply.shield_wield_time then
		ply.shield_unwield_time = ply.shield_unwield_time or CurTime()
		local cycle = -math.min((CurTime() - ply.shield_unwield_time)*1.25, 0.3)+0.3
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_bow"), cycle, false)
		if cycle == 0 then
			ply.shield_wield_time = nil
			ply.shield_unwield_time = nil
			ply:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, 0)
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(0,0,0))
		end

		if CLIENT then
			manip_angles(ply, ply:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(0,0,0))
		end
	end

	if ply:GetNWBool("shield_stunned") then
		ply.shield_stunned = ply.shield_stunned or CurTime()
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("taunt_persistence"), math.min((CurTime() - ply.shield_stunned)*0.25 + 0.2, 0.5), true)
	else
		ply.shield_stunned = nil
	end
end)

hook.Add("EntityTakeDamage", "shield", function(ent, dmginfo)
	local shield = ent:GetNWEntity("shield")
	if shield:IsValid() then
		local type = dmginfo:GetDamageType()

		if type == DMG_CRUSH or type == DMG_SLASH then
			shield:OnTakeDamage(dmginfo)
			dmginfo:SetDamage(0)
			ent:ChatPrint("block!")
			return
		end

		local data = util.TraceLine({start = dmginfo:GetDamagePosition(), endpos = ent:WorldSpaceCenter(), filter = {dmginfo:GetAttacker()}})

		if data.Entity == shield then
			shield:OnTakeDamage(dmginfo)
			dmginfo:SetDamage(0)
		end
	end
end)