if CLIENT then
	local jeffects = requirex("jeffects")

	do
		local BASE = {}

		function BASE:Initialize() end
		function BASE:DrawTranslucent() end
		function BASE:DrawOpaque() end

		function BASE:StartEffect(time)
			self.time = RealTime() + time
			self.length = time
		end

		function BASE:Draw(how)
			local time = RealTime()
			local f = -math.max((self.time - RealTime())/self.length, 0)+1

			if f == 1 then
				self:Remove()
			end

			local f2 = math.sin(f*math.pi) ^ 0.5

			if self.ent:IsValid() then
				local m = self.ent:GetBoneMatrix(self.ent:LookupBone("ValveBiped.Bip01_Pelvis"))
				if m then
					self.position = m:GetTranslation()
				else
					self.position = self.ent:GetPos() + self.ent:OBBCenter()
				end
				self.position2 = self.ent:GetPos() + self.ent:OBBCenter()

				if how == "opaque" then
					self:DrawOpaque(time, f, f2)
				else
					self:DrawTranslucent(time, f, f2)
				end
			else
				self:Remove()
			end
		end

		local active = {}

		function BASE:Remove()
			for i, jeffects in ipairs(active) do
				if jeffects == self then
					table.remove(active, i)
					break
				end
			end
		end

		jeffects.effects = jeffects.effects or {}

		function jeffects.RegisterEffect(META)
			META.__index = function(self, key)
				if META[key] then return META[key] end
				if BASE[key] then return BASE[key] end
			end
			jeffects.effects[META.Name] = META
		end

		function jeffects.CreateEffect(name, tbl)
			local jeffects = setmetatable(tbl or {}, jeffects.effects[name])
			jeffects:Initialize()
			jeffects:StartEffect(tbl.length or 1)
			table.insert(active, jeffects)

			hook.Add("PostDrawOpaqueRenderables", "jeffects", function()
				for _, jeffects in ipairs(active) do
					jeffects:Draw("opaque")
				end
			end)

			hook.Add("PostDrawTranslucentRenderables", "jeffects", function()
				for _, jeffects in ipairs(active) do
					jeffects:Draw("translucent")
				end
			end)
		end
	end

	local feather_mat = jeffects.CreateMaterial({
		Name = "magic_feather_mat",
		Shader = "VertexLitGeneric",

		BaseTexture = "effects/spark",
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})

	local spike_model = jeffects.CreateModel({
		Path = "models/props_combine/tprotato1.mdl",
		Scale = Vector(0.1, 0.02, 0.3),
		NoCull = true,
	})
	local m = Matrix()
	m:Scale(Vector(0.1,0.02,0.3))
	spike_model:EnableMatrix("RenderMultiply", m)

	local ring_model = jeffects.CreateModel({
		Path = "models/props_combine/breentp_rings.mdl",
		Scale = Vector(1, 1, 4),
		Material = "models/gibs/combine_helicopter_gibs/combine_helicopter01",
	})

	do
		local META = {}
		META.Name = "something"

		function META:Initialize()
			self.pixvis = util.GetPixelVisibleHandle()

			self.color = self.color or Color(255, 217, 104, 255)
			self.size = self.size or self.ent:BoundingRadius() / 70
			self.something = self.something or 1
		end

		function META:DrawSprites(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 200*f2^5

			cam.Start3D(EyePos(), EyeAngles())
				render.SetMaterial(jeffects.materials.splash_disc)
				render.DrawQuadEasy(self.position, -EyeVector(), (80*s) - f*5, (80*s) - f*5, c, f*45)

				render.SetMaterial(jeffects.materials.splash_disc)
				render.DrawQuadEasy(self.position, Vector(0,0,1), (100*s) - f*5, (100*s) - f*5, c, f*45)

				render.SetMaterial(jeffects.materials.ring)
				render.DrawQuadEasy(self.position, -EyeVector(), 100*s, 100*s, c, f*-45)

				render.SetMaterial(jeffects.materials.glow)
				render.DrawQuadEasy(self.position, -EyeVector(), 64*s, 64*s, c, f*-45)
			cam.End3D()
		end

		function META:DrawGlow(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 30*f2*self.visible

			cam.Start3D(EyePos(), EyeAngles())
			cam.IgnoreZ(true)
				render.SetMaterial(jeffects.materials.glow)
				local size = 500*s
				render.DrawSprite(self.position, size, size, c)
			cam.IgnoreZ(false)
			cam.End3D()
		end

		function META:DrawRefraction(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 200*f2*self.something

			cam.Start3D(EyePos(), EyeAngles())
				render.SetMaterial(jeffects.materials.refract)
				render.DrawQuadEasy(self.position, -EyeVector(), 128*s, 128*s, c, f*45)
			cam.End3D()
		end

		function META:DrawRefraction2(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = (self.something*255)*f2

			cam.Start3D(EyePos(), EyeAngles())
				render.SetMaterial(jeffects.materials.refract2)
				render.DrawQuadEasy(self.position, -EyeVector(), 130*s, 130*s, c, f*45)
			cam.End3D()
		end

		function META:DrawSunbeams(time, f, f2)
			local s = self.size
			local pos = self.position
			local screen_pos = pos:ToScreen()

			DrawSunbeams(0, (f2*self.visible*0.1)*self.something, 30 * (1/pos:Distance(EyePos()))*s, screen_pos.x / ScrW(), screen_pos.y / ScrH())
		end

		function META:DrawSpikes(time, f, f2)
			local s = self.size
			render.SetColorModulation(0,0,0)
			render.SuppressEngineLighting(true)
			render.SetBlend(f2 * (self.something)^6)

			spike_model:SetModelScale(1)

			local max = 10
			for i = 1, max do
				local p = (i / max) * math.pi * 2
				p = p + f
				local dist = 30*s
				local offset = Vector(math.sin(p+i+time)*dist, math.cos(p+i+time)*dist, math.sin(p+time)*dist)
				spike_model:SetPos(self.position + offset)
				spike_model:SetAngles(offset:Angle() + Angle(-90,0,0))
				spike_model:Draw()
			end

			render.SuppressEngineLighting(false)
		end

		function META:DrawRing(time, f, f2)
			local s = self.size
			render.SetColorModulation(self.color.r/255*5,self.color.g/255*5,self.color.b/255*5)
			render.SuppressEngineLighting(true)
			render.SetBlend(f2^3)
			ring_model:ManipulateBoneScale(0, Vector(0,0,0))

			for i = 1, 10 do
				ring_model:ManipulateBoneAngles(i, Angle(0,((i/5)*2-1)*RealTime()*500,0))
				ring_model:ManipulateBoneScale(i, Vector(1,1,math.max(self.something,0.2)))
			end

			ring_model:SetModelScale(0.75*s)
			ring_model:SetPos(self.position)
			ring_model:Draw()

			render.SuppressEngineLighting(false)
		end

		function META:EmitParticle()
			local s = self.size
			local ent = ents.CreateClientProp()
			ent:SetModel("models/pac/default.mdl")
			ent:SetPos(self.position + (VectorRand()*10*s))
			ent:SetAngles(VectorRand():Angle())
			ent:SetModelScale(s)

			local m = Matrix()
			m:Translate(Vector(0,20,0)*s)
			m:Scale(Vector(1,0.25,1))
			ent:EnableMatrix("RenderMultiply", m)

			ent.RenderOverride = function()
				local f = (ent.life_time - RealTime()) / 5

				do
					local h,s,v = ColorToHSV(self.color)
					s = s / 2
					local c = HSVToColor(h,s,v)
					render.SetColorModulation(2*c.r/255, 2*c.g/255, 2*c.b/255)
				end

				render.SetBlend(f^0.5)

				render.SuppressEngineLighting(true)
				render.MaterialOverride(feather_mat)
				render.SetMaterial(feather_mat)
				render.CullMode(MATERIAL_CULLMODE_CW)
				ent:DrawModel()
				render.CullMode(MATERIAL_CULLMODE_CCW)
				ent:DrawModel()
				render.MaterialOverride()
				render.SuppressEngineLighting(false)

				local phys = ent:GetPhysicsObject()
				phys:AddVelocity(Vector(0,0,-FrameTime()*100)*s)

				local vel = phys:GetVelocity()

				if vel.z < 0 then
					local delta= FrameTime()*2
					phys:AddVelocity(Vector(-vel.x*delta,-vel.y*delta,-vel.z*delta*2)*s)
				end
			end

			ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
			ent:PhysicsInitSphere(5)

			local phys = ent:GetPhysicsObject()
			phys:EnableGravity(false)
			phys:AddVelocity(Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(1, 2))*80*s)
			phys:AddAngleVelocity(VectorRand()*50)
			ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
			ent.life_time = RealTime() + 5

			SafeRemoveEntityDelayed(ent, 5)
		end

		function META:DrawDownBeam(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 150*f2*self.something

			--cam.Start3D(EyePos(), EyeAngles())
				local ang = EyeAngles()
				ang.p = 0

				render.SetMaterial(jeffects.materials.beam)
				render.DrawQuadEasy(self.position+ Vector(0,0,300), -ang:Forward(), 100*s, 2500, Color(255,255,255,100*f2*self.something), 0)

				render.SetMaterial(jeffects.materials.glow)
				render.DrawQuadEasy(self.position+ Vector(0,0,300*f2), -ang:Forward(), 200*f2*s, 2500/f, c, 0)
			--cam.End3D()
		end

		function META:DrawTranslucent(time, f, f2)
			if f < 0.25 and self.something == 1 then
				if not self.emitted then
					for i = 1, math.random(5,10) do
						self:EmitParticle()
					end
					self.emitted = true
				end
			else
				self.emitted = false
			end

			self.visible = util.PixelVisible(self.position, 50, self.pixvis)
			self:DrawDownBeam(time, f, f2)
			self:DrawSprites(time, f, f2)

			self:DrawRefraction(time, f, f2)
			self:DrawRefraction2(time, f, f2)
			self:DrawGlow(time, f, f2)
			self:DrawSunbeams(time, f, f2)
		end

		function META:DrawOpaque(time, f, f2)
			self:DrawSpikes(time, f, f2)
			self:DrawRefraction2(time, f, f2)
			self:DrawRing(time, f, f2)
		end

		jeffects.RegisterEffect(META)
	end

	do
		local trail = jeffects.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "particle/fire",
			Additive = 1,
			GlowAlpha = 1,
			VertexColor = 1,
			VertexAlpha = 1,
			Translucent = 1,
		})

		local META = {}
		META.Name = "trails"

		function META:DrawTranslucent(time, f, f2)
			self.trails = self.trails or {}
			for i = 1, 3 do
				self.trails[i] = self.trails[i] or {data = {}}
				self.trails[i].vec = self.trails[i].vec or VectorRand()
				self.trails[i].vec2 = self.trails[i].vec2 or VectorRand()
				local v = self.trails[i].vec
				local v2 = self.trails[i].vec2

				local s = (i/8) * math.pi * 2
				local offset = Vector(math.sin(s+v.x), math.cos(s+v.y), math.sin(-s+v.z)) * 30
				local t = RealTime()*500
				offset:Rotate(Angle(t*v2.x, t*v2.y, t*v2.z))

				jeffects.DrawTrail(self.trails[i], 1, 2, self.position2 + offset, trail, Color(self.color.r, self.color.g, self.color.b, 255*(f2^2)), Color(self.color.r*2, self.color.g*2, self.color.b*2, 0), 10, 10, f2)
			end
		end

		jeffects.RegisterEffect(META)
	end
end


local SWEP = {Primary = {}, Secondary = {}}

SWEP.ClassName = "weapon_magic"
SWEP.PrintName = "magic"
SWEP.Spawnable = true
SWEP.RenderGroup = RENDERGROUP_TRANSLUCENT
SWEP.WorldModel = "models/Gibs/HGIBS.mdl"

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "DamageTypesInternal")
end

function SWEP:GetDamageTypes()
	local types = self:GetDamageTypesInternal()
	if types ~= self.last_damage_types then
		self.damage_types = types:Split(",")
		if not self.damage_types[1] then
			table.insert(self.damage_types, "generic")
		end
		self.last_damage_types = self.damage_types
	end
	return self.last_damage_types
end

if CLIENT then
	net.Receive(SWEP.ClassName, function(len, ply)
		local wep = net.ReadEntity()
		if wep:IsValid() and wep:GetClass() == SWEP.ClassName and wep.DeployMagic then
			if net.ReadBool() then
				wep:DeployMagic()
			else
				local ply = wep:GetOwner()
				local left_hand = net.ReadBool()
				wep:ThrowAnimation(left_hand)

				wep:ShootMagic()
			end
		end
	end)

	function SWEP:DrawWorldModel()

	end

	function SWEP:DrawWorldModelTranslucent()

		for _, bone_name in ipairs({"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand"}) do
			local pos, ang

			if self.Owner:IsValid() then
				local id = self.Owner:LookupBone(bone_name)
				if id then
					pos, ang = self.Owner:GetBonePosition(id)
					pos = pos + ang:Forward()*2
				end

				self:SetPos(pos)
				self:SetAngles(ang)
			end

			for _, name in ipairs(self:GetDamageTypes()) do
				if jdmg.types[name] and jdmg.types[name].draw_projectile then
					jdmg.types[name].draw_projectile(self, 40, true)
				end
			end

			if not self.Owner:IsValid() then
				return
			end
		end


		if CurTime()%0.5 < 0.25 then
			if not self.lol then
				self.Owner:AnimResetGestureSlot(GESTURE_SLOT_VCD)
				self.Owner:AnimRestartGesture(GESTURE_SLOT_VCD,  self.Owner:GetSequenceActivity(self.Owner:LookupSequence("jump_land")), true)
				self.Owner:AnimRestartGesture(GESTURE_SLOT_CUSTOM,  self.Owner:GetSequenceActivity(self.Owner:LookupSequence("flinch_stomach_02")), true)
				self.Owner:AnimSetGestureWeight(GESTURE_SLOT_VCD, math.Rand(0.2,0.35))
				self.Owner:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, math.Rand(0.2,0.35))
				self.lol = true
			end
		elseif self.lol then
			self.lol = false
		end

	end
end

function SWEP:TranslateActivity(act)
	if act == ACT_MP_STAND_IDLE then
		return  ACT_HL2MP_IDLE_MELEE_ANGRY
	elseif act == ACT_MP_RUN then
		return ACT_HL2MP_RUN_FAST
	end

	return -1
end

function SWEP:Initialize()

	self:SetHoldType("melee")

	self:DrawShadow(false)

	if SERVER and not self.wepstats then
		wepstats.AddToWeapon(self, "legendary", "+5", "holy")
	end
end

if CLIENT then
	local jeffects = requirex("jeffects")

	function SWEP:GetMagicColor()
		local r = 0
		local g = 0
		local b = 0
		local div = 1
		for _, name in ipairs(self:GetDamageTypes()) do
			if jdmg.types[name] and jdmg.types[name].color then
				r = r + jdmg.types[name].color.r
				g = g + jdmg.types[name].color.g
				b = b + jdmg.types[name].color.b
				div = div + 1
			end
		end

		r = r / div
		g = g / div
		b = b / div

		return r,g,b
	end

	function SWEP:DeployMagic()
		local r,g,b = self:GetMagicColor()
		jeffects.CreateEffect("something", {
			ent = self.Owner,
			color = Color(r, g, b, 255),
			size = nil,
			something = 1,
			length = 2,
		})

		local snd = CreateSound(self.Owner, "music/hl2_song10.mp3")
		snd:PlayEx(0.5, 150)
		snd:FadeOut(2)

		self:EmitSound("ambient/water/distant_drip2.wav", 75, 75, 1)
	end

	function SWEP:ShootMagic()
		local r,g,b = self:GetMagicColor()
		jeffects.CreateEffect("something", {
			ent = self.Owner,
			color = Color(r, g, b, 50),
			size = nil,
			something = 0,
			length = 1,
		})

		jeffects.CreateEffect("trails", {
			ent = self.Owner,
			color = Color(r, g, b, 50),
			length = 2,
		})
	end
end

function SWEP:Deploy()
	if SERVER then
		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteBool(true)
		net.Broadcast()

		local ugh = {}
		for name, dmgtype in pairs(self.wepstats) do
			if dmgtype.Elemental then
				table.insert(ugh, name)
			end
		end
		self:SetDamageTypesInternal(table.concat(ugh, ","))
	end

	self:SetHoldType("melee")

	return true
end

function SWEP:ThrowAnimation(left_hand)
	self.Owner:AddVCDSequenceToGestureSlot(left_hand and GESTURE_SLOT_GRENADE or GESTURE_SLOT_ATTACK_AND_RELOAD, self.Owner:LookupSequence("zombie_attack_0" .. (left_hand and 3 or 2)), 0.25, true)
end

function SWEP:PrimaryAttack()
	if self:GetNextPrimaryFire() > CurTime() or not self.wepstats then return end

	self:SetNextPrimaryFire(CurTime() + 0.6)

	if SERVER then
		if jattributes.DrainMana(self.Owner, self, 50) == false then return end

		self.left_hand_anim = not self.left_hand_anim

		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteBool(false)
			net.WriteBool(self.left_hand_anim)
		net.Broadcast()

		self:ThrowAnimation(self.left_hand_anim)

		local snd = CreateSound(self, "music/hl2_song10.mp3")
		snd:PlayEx(0.5, 255)
		snd:FadeOut(2)

		local bone_id = self.Owner:LookupBone(self.left_hand_anim and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand")

		local ent = ents.Create("jprojectile_bullet")
		ent:SetOwner(self.Owner)
		ent:SetProjectileData(self.Owner, self.Owner:GetShootPos(), self.Owner:GetAimVector(), 1, self)

		if bone_id then
			ent:FollowBone(self.Owner, bone_id)
			ent:SetLocalPos(Vector(0,0,0))
		end

		ent:Spawn()

		timer.Simple(0.25, function()
			ent:SetParent(NULL)
			local pos

			if bone_id then
				pos = self.Owner:GetBonePosition(bone_id)
			else
				pos = self.Owner:EyePos() + self.Owner:GetVelocity()/4
			end

			ent:SetProjectileData(self.Owner, pos, self.Owner:GetAimVector(), 1, self)
		end)
	end
end

function SWEP:SecondaryAttack()

end

weapons.Register(SWEP, SWEP.ClassName)

if SERVER then
	if me then
		local name = SWEP.ClassName
		SafeRemoveEntity(me:GetWeapon(name))
		timer.Simple(0.1, function()
			me:Give(name)
			me:SelectWeapon(name)
		end)
	end
end