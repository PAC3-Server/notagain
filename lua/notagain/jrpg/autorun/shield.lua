do
	local ENT = {}

	ENT.Type = "anim"
	ENT.Base = "base_anim"
	ENT.ClassName = "shield_base"

	ENT.MagicDefence = 0
	ENT.PhysicalDefence = 1

	function ENT:TranslateModelPosAng(pos, ang)
		return pos, ang
	end

	function ENT:GetPosAng(pos, ang)
		local ply = self:GetOwner()
		if not ply:IsValid() then return end

		pos = pos or ply:WorldSpaceCenter()
		ang = ang or ply:EyeAngles()

		ang.p = math.Clamp(ang.p + 90, -10, 90)

		pos = pos + ang:Up()*(30 + ang.p/50)
		pos = pos + ang:Forward()*-(10 - (-ang.p+90)/5)

		pos, ang = self:TranslateModelPosAng(pos, ang)

		return pos, ang
	end

	if SERVER then
		function ENT:Initialize()
			self:SetModel(self.Model)
			self:SetMoveType(MOVETYPE_NONE)
			self:SetSolid(SOLID_VPHYSICS)
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:StartMotionController()

			local phys = self:GetPhysicsObject()
			phys:EnableGravity(false)

			phys:SetPos(self:GetOwner():WorldSpaceCenter() or self:GetOwner():GetPos())
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
			if not jrpg.IsWieldingShield(ply) then return end
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

				ply.shield_suppress_damage = true

				if jdmg.GetDamageType(dmginfo) then
					dmginfo:SetDamage(dmginfo:GetDamage() * (-self.MagicDefence+1))
				end

				dmginfo:SetDamage(dmginfo:GetDamage() * (-self.PhysicalDefence+1))

				if dmginfo:GetDamage() == 0 then
					dmginfo:SetDamage(-1)
				end

				ply:TakeDamageInfo(dmginfo)

				ply.shield_suppress_damage = nil
			end
		end
	end

	if CLIENT then
		function ENT:CSTranslateModelPosAng(pos, ang)
			return pos, ang
		end

		function ENT:Initialize()
			local ply = self:GetOwner()

			if not ply:IsValid() then return end

			self:SetRenderBounds(ply:OBBMins(), ply:OBBMaxs())

			if self.CSModel then
				self.csent = ClientsideModel(self.CSModel)
				self.csent:SetPos(self:GetPos())
				self.csent:SetNoDraw(true)
				if self.CSModelScale then
					self.csent:SetModelScale(self.CSModelScale)
				end
			end
		end

		function ENT:Draw()
			local ply = self:GetOwner()
			if not ply:IsValid() then return end


			local pos, ang = self:GetPosAng()

			local id = ply:LookupBone("ValveBiped.Bip01_L_Hand")

			if id then
				local handpos, handang = ply:GetBonePosition(id)

				pos = LerpVector(0.75, pos, handpos)
				ang = LerpAngle(0.1, ang, handang)

				if not ply.shield_wield_time then

					local pos, ang = ply:GetBonePosition(id)
					local pos, ang = self:TranslateModelPosAng(pos, ang, true)

					self:SetPos(pos)
					self:SetAngles(ang)
					self:SetupBones()
					self:DrawModel()

					return
				end

			end

			if self.csent then
				pos, ang = self:CSTranslateModelPosAng(pos, ang)

				self.csent:SetPos(pos)
				self.csent:SetAngles(ang)
				self.csent:DrawModel()
			else
				self:SetPos(pos)
				self:SetAngles(ang)
				self:SetupBones()
				self:DrawModel()
			end
		end

		function ENT:OnRemove()
			SafeRemoveEntity(self.csent)
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end

do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.Weight = -1
	SWEP.MagicDefence = 0
	SWEP.PhysicalDefence = 1

	SWEP.ClassName = "weapon_shield_base"
	SWEP.Category = "JRPG"

	SWEP.PrintName = "shield"

	SWEP.WorldModel = "models/hunter/plates/plate1x1.mdl"
	SWEP.ViewModel = Model("models/weapons/c_medkit.mdl")
	SWEP.UseHands = false
	SWEP.is_shield = true

	if CLIENT then
		function SWEP:TranslateModelPosAng(pos, ang)
			return pos, ang
		end

		function SWEP:CSTranslateModelPosAng(pos, ang)
			return pos, ang
		end

		function SWEP:Initialize()
			if self.CSModel then
				self.csent = ClientsideModel(self.CSModel)
				self.csent:SetPos(self:GetPos())
				self.csent:SetNoDraw(true)
				if self.CSModelScale then
					self.csent:SetModelScale(self.CSModelScale)
				end
			end
		end

		function SWEP:DrawWorldModel()
			if self:GetOwner():IsValid() then return end

			local pos = self:GetPos()
			local ang = self:GetAngles()

			pos, ang = self:TranslateModelPosAng(pos, ang)

			if self.csent then
				pos, ang = self:CSTranslateModelPosAng(pos, ang)

				self.csent:SetPos(pos)
				self.csent:SetAngles(ang)
				self.csent:DrawModel()
			else
				self:DrawModel()
			end
		end
	end

	function SWEP:PrimaryAttack() end
	function SWEP:SecondaryAttack() end

	if SERVER then
		function SWEP:PrimaryAttack()
			local ply = self:GetOwner()

			for k, v in pairs(ply:GetWeapons()) do
				if v.is_shield then
					v:SecondaryAttack()
				end
			end

			self:OnRemove()
			self:GlobalThink()
			self.active = true
		end

		function SWEP:SecondaryAttack()
			self:OnRemove()
			self.active = false
		end

		function SWEP:ShowShield()
			local ply = self.Owner

			if ply.shield_timer and ply.shield_timer > CurTime() then return end

			if jattributes.GetStamina(ply) == 0 then return end

			ply:SetNWBool("wield_shield", true)
			ply:GetNWEntity("shield"):SetCollisionGroup(COLLISION_GROUP_NONE)
			ply:GetNWEntity("shield"):GetPhysicsObject():EnableCollisions(true)

			return true
		end

		function SWEP:HideShield()
			local ply = self.Owner

			ply:SetNWBool("wield_shield", false)

			ply:GetNWEntity("shield"):GetPhysicsObject():EnableCollisions(false)
			ply:GetNWEntity("shield"):SetCollisionGroup(COLLISION_GROUP_DEBRIS)

			return true
		end

		function SWEP:OnRemove()
			local ply = self.Owner

			SafeRemoveEntity(ply:GetNWEntity("shield"))
		end

		function SWEP:Deploy()
			return true
		end

		function SWEP:Holster()
			return true
		end

		function SWEP:Think() end
		function SWEP:GlobalThink()
			local ply = self:GetOwner()
			if not ply:IsValid() then return end

			if self.active == false then return end

			local shield = ply:GetNWEntity("shield")

			if not shield:IsValid() and self.ShieldName then
				shield = ents.Create(self.ShieldName)
				shield:SetOwner(ply)
				shield:SetPos(ply:GetPos())
				shield:Spawn()

				if CPPI then shield:CPPISetOwner(self:GetOwner()) end
				ply:SetNWEntity("shield", shield)

				self:HideShield()
			end
		end

		hook.Add("Think", "shield", function()
			for _, self in ipairs(ents.GetAll()) do
				if self.is_shield then
					self:GlobalThink()
				end
			end
		end)
	end

	weapons.Register(SWEP, SWEP.ClassName)
end

local function register_shield(tbl)
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ShieldName = "shield_" .. tbl.Name:gsub(" ", "_")
	SWEP.ClassName = "weapon_shield_" .. tbl.Name:gsub(" ", "_")

	SWEP.PrintName = tbl.Name .. " shield"
	SWEP.Category = "JRPG"
	SWEP.Spawnable = true

	SWEP.Base = "weapon_shield_base"
	SWEP.WorldModel = tbl.Model

	for key, val in pairs(tbl) do SWEP[key] = val end
	weapons.Register(SWEP, SWEP.ClassName)

	local ENT = {}
	ENT.is_shield_ent = true
	ENT.ClassName = SWEP.ShieldName
	ENT.Base = "shield_base"
	for key, val in pairs(tbl) do ENT[key] = val end
	scripted_ents.Register(ENT, ENT.ClassName)
end

local shields = {
	{
		Name = "plate 1x1",
		Model = "models/hunter/plates/plate1x1.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			return pos, ang
		end,
	},
	{
		Name = "gunship eye",
		Model = "models/gibs/gunship_gibs_eye.mdl",
		MagicDefence = 1,
		PhysicalDefence = 0,
		TranslateModelPosAng = function(self, pos, ang)
			ang:RotateAroundAxis(ang:Forward(), 100)
			ang:RotateAroundAxis(ang:Right(), 35)

			return pos, ang
		end,
	},
	{
		Name = "sawblade",
		Model = "models/props_junk/sawblade001a.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			return pos, ang
		end,
	},
	{
		Name = "combine",
		Model = "models/hunter/plates/plate1x2.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			ang:RotateAroundAxis(ang:Up(), 90)
			return pos, ang
		end,
		CSModel = "models/props_combine/tprotato2.mdl",
		CSModelScale = 0.7,
		CSTranslateModelPosAng = function(self, pos, ang)
			ang:RotateAroundAxis(ang:Up(), -90)
			ang:RotateAroundAxis(ang:Right(), 90)
			return pos, ang
		end,
	},
	{
		Name = "scanner",
		Model = "models/hunter/plates/plate1x1.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			return pos, ang
		end,
		CSModel = "models/gibs/scanner_gib02.mdl",
		CSModelScale = 4.5,
		CSTranslateModelPosAng = function(self, pos, ang)
			pos = pos + ang:Forward()*-4
			ang:RotateAroundAxis(ang:Up(), -180)
			ang:RotateAroundAxis(ang:Right(), 45)
			ang:RotateAroundAxis(ang:Forward(), 45)
			return pos, ang
		end,
		MagicDefence = 0.5,
		PhysicalDefence = 1,
	},
	{
		Name = "scanner2",
		Model = "models/XQM/panel360.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			ang:RotateAroundAxis(ang:Right(), -90)

			return pos, ang
		end,
		CSModel = "models/gibs/shield_scanner_gib2.mdl",
		CSModelScale = 3.5,
		CSTranslateModelPosAng = function(self, pos, ang)
			ang:RotateAroundAxis(ang:Up(), 180)
			ang:RotateAroundAxis(ang:Right(), 90)
			return pos, ang
		end,
	},
	{
		Name = "gear 1",
		Model = "models/props_phx/mechanics/medgear.mdl",
	},
	{
		Name = "gear 2",
		Model = "models/props_phx/gears/spur24.mdl",
	},
	{
		Name = "gear 3",
		Model = "models/props_phx/gears/spur36.mdl",
	},
	{
		Name = "spike",
		Model = "models/mechanics/wheels/wheel_spike_48.mdl",
	},
	{
		Name = "offroad wheel",
		Model = "models/xeon133/offroad/off-road-50.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			ang:RotateAroundAxis(ang:Right(), -90)

			return pos, ang
		end,
	},
	{
		Name = "wheel",
		Model = "models/Mechanics/wheels/rim_1.mdl",

	},
	{
		Name = "combine mine",
		Model = "models/props_combine/combine_mine01.mdl",
		TranslateModelPosAng = function(self, pos, ang)
			pos = pos + ang:Up() * -8
			ang:RotateAroundAxis(ang:Up(), -90)

			return pos, ang
		end,
	}
}

local shields = {}

local files = file.Find("models/demonssouls/shields/*.mdl", "GAME")
for k,v in pairs(files) do
	table.insert(shields, {
		Name = v:match("(.+)%.mdl"):gsub("shield", ""):gsub("%p", ""):gsub("%s+", " "):Trim(),
		Model = "models/demonssouls/shields/" .. v,
		TranslateModelPosAng = function(self, pos, ang, idle)
			if not idle then
				pos = pos + ang:Up() * -5
				pos = pos + ang:Forward() * -2
			else
				pos = pos + ang:Right() * -1
				ang:RotateAroundAxis(ang:Forward(), -90)
			end

			ang:RotateAroundAxis(ang:Up(), -90)
			ang:RotateAroundAxis(ang:Forward(), 180 + 12.25)

			return pos, ang
		end,
	})
end

for _, tbl in pairs(shields) do
	register_shield(tbl)
end

hook.Add("SetupMove", "shield", function(ply, ucmd)
	if not jrpg.IsWieldingShield(ply) then return end

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
	function EnableShield(ply, b)
		if b then
			for k,v in pairs(ply:GetWeapons()) do
				if v.is_shield and ply:GetActiveWeapon() ~= v then
					v:ShowShield()
					break
				end
			end
		else
			for k,v in pairs(ply:GetWeapons()) do
				if v.is_shield and ply:GetActiveWeapon() ~= v then
					v:HideShield()
					break
				end
			end
		end
	end

	concommand.Add("+jshield", function(ply)
		EnableShield(ply, true)
	end)

	concommand.Add("-jshield", function(ply)
		EnableShield(ply, false)
	end)

	hook.Add("KeyPress", "shield", function(ply, key)
		if key ~= IN_WALK then return end
		EnableShield(ply, true)
	end)

	hook.Add("KeyRelease", "shield", function(ply, key)
		if key ~= IN_WALK then return end
		EnableShield(ply, false)
	end)

	hook.Add("PostPlayerDeath", "shield", function(ply)
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
	if jrpg.IsWieldingShield(ply) then
		ply.shield_unwield_time = nil
		ply.shield_wield_time = ply.shield_wield_time or CurTime()
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_bow"), math.min(((CurTime() - ply.shield_wield_time) ^ 0.3) * 0.4, 0.3), false)

		if CLIENT then
			local id = ply:LookupBone("ValveBiped.Bip01_L_UpperArm")
			if id then
				manip_angles(ply, id, Angle(math.Clamp(math.NormalizeAngle(ply:EyeAngles().p - 90), -180,-90),0,0))
			end
		end

--		return true
	elseif ply.shield_wield_time then
		ply.shield_unwield_time = ply.shield_unwield_time or CurTime()
		local cycle = -math.min(((CurTime() - ply.shield_unwield_time) ^ 1.25)*0.8, 0.3)+0.3
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_bow"), cycle, false)
		if cycle == 0 then
			ply.shield_wield_time = nil
			ply.shield_unwield_time = nil
			ply:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, 0)
			local id = ply:LookupBone("ValveBiped.Bip01_L_UpperArm")
			if id then
				ply:ManipulateBoneAngles(id, Angle(0,0,0))
			end
		end

		if CLIENT then
			local id = ply:LookupBone("ValveBiped.Bip01_L_UpperArm")
			if id then
				manip_angles(ply, id, Angle(0,0,0))
			end
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
	if ent:GetNWBool("shield_stunned") then
		dmginfo:SetDamage(dmginfo:GetDamage() * 3)

		return
	end

	if jrpg.IsWieldingShield(ent) then
		local data = util.TraceLine({
			start = dmginfo:GetDamagePosition(),
			endpos = ent:WorldSpaceCenter(),
			filter = {dmginfo:GetAttacker()}
		})

		if data.Entity == shield then
			shield:OnTakeDamage(dmginfo)
			return true
		end
	end
end)

function jrpg.IsWieldingShield(ply)
	return ply:GetNWEntity("shield"):IsValid() and ply:GetNWBool("wield_shield")
end
