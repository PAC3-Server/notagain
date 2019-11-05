if CLIENT then
	local jfx = requirex("jfx")

	local spike_model = jfx.CreateModel({
		Path = "models/props_combine/tprotato1.mdl",
		Scale = Vector(0.1, 0.02, 0.3),
		NoCull = true,
	})
	local m = Matrix()
	m:Scale(Vector(0.1,0.02,0.3))
	spike_model:EnableMatrix("RenderMultiply", m)

	local ring_model = jfx.CreateModel({
		Path = "models/props_combine/breentp_rings.mdl",
		Scale = Vector(1, 1, 4),
		Material = "models/gibs/combine_helicopter_gibs/combine_helicopter01",
	})

	do

		local glyph_disc = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/disc.png",
			VertexColor = 1,
			VertexAlpha = 1,
		})

		local ring = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/ring2.png",
			Additive = 0,
			VertexColor = 1,
			VertexAlpha = 1,
		})

		local hand = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/clock_hand.png",
			Additive = 0,
			VertexColor = 1,
			VertexAlpha = 1,
			BaseTextureTransform = "center .5 .5 scale 1 5 rotate 0 translate 0 1.25",
		})

		local glow = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/glow.png",
			Additive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
		})

		local glow2 = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "sprites/light_glow02",
			Additive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
			Translucent = 1,
			IgnoreZ = 1,
		})

		local META = {}
		META.Name = "something"

		function META:Initialize()
			self.pixvis = util.GetPixelVisibleHandle()

			self.color = self.color or Color(255, 217, 104, 255)
			self.size = self.size or (self.ent:IsValid() and (self.ent:BoundingRadius()/70) or 0.6)
			self.something = self.something or 1

		end

		function META:DrawSprites(time, f, f2)
			local s = self.size*1.5
			local c = Color(self.color.r^1.15, self.color.g^1.15, self.color.b^1.15)
			c.a = 200*f2^5

			local dark =  Color(0,0,0,c.a)

			cam.Start3D(EyePos(), EyeAngles())

				local pos = self.ent:GetPos()

				render.SetMaterial(glyph_disc)
				render.DrawQuadEasy(pos, Vector(0,0,1), (95*s) - f*5, (95*s) - f*5, dark, f*45)


				render.SetMaterial(ring)
				render.DrawQuadEasy(pos, Vector(0,0,1), 105*s, 105*s, dark, f*-45)

				render.SetMaterial(glow2)
				render.DrawQuadEasy(pos, Vector(0,0,1), 420*s, 420*s, c, f*45)

				render.SetMaterial(hand)

				dark.a = dark.a*self.something

				local hands = 6
				for i = 1, hands do
					render.DrawQuadEasy(pos, Vector(0,0,1), 10*s, 250*s, dark, (i/hands)*360 + (f*150 * (math.sin(1+i/hands*math.pi)*i%3*(f^0.01))))
				end

				render.SetMaterial(glow)
				render.DrawQuadEasy(self.position, -EyeVector(), 10*s, 10*s, c, f*-45)

				render.SetMaterial(glow2)
				render.DrawQuadEasy(self.position, -EyeVector(), 220*s, 220*s, c, f*45)

			cam.End3D()
		end

		function META:DrawGlow(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 30*f2*self.visible

			cam.Start3D(EyePos(), EyeAngles())
			cam.IgnoreZ(true)
				render.SetMaterial(glow)
				local size = 500*s
				render.DrawSprite(self.position, size, size, c)
			cam.IgnoreZ(false)
			cam.End3D()
		end

		function META:DrawRefraction(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 100*f2*self.something

			cam.Start3D(EyePos(), EyeAngles())
				render.SetMaterial(jfx.materials.refract)
				render.DrawQuadEasy(self.position, -EyeVector(), 128*s, 128*s, c, f*45)
			cam.End3D()
		end

		function META:DrawRefraction2(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = (self.something*100)*f2

			cam.Start3D(EyePos(), EyeAngles())
				render.SetMaterial(jfx.materials.refract2)
				render.DrawQuadEasy(self.position, -EyeVector(), 130*s, 130*s, c, f*45)
			cam.End3D()
		end

		function META:DrawSunbeams(time, f, f2)
			local s = self.size
			local pos = self.position
			local screen_pos = pos:ToScreen()

			DrawSunbeams(0, (f2*self.visible*0.05)*self.something, 30 * (1/pos:Distance(EyePos()))*s, screen_pos.x / ScrW(), screen_pos.y / ScrH())
		end

		function META:DrawDownBeam(time, f, f2)
			local s = self.size
			local c = Color(self.color.r, self.color.g, self.color.b)
			c.a = 150*f2*self.something

			--cam.Start3D(EyePos(), EyeAngles())
				local ang = EyeAngles()
				ang.p = 0

				render.SetMaterial(jfx.materials.beam)
				render.DrawQuadEasy(self.position+ Vector(0,0,300), -ang:Forward(), 100*s, 2500, Color(255,255,255,100*f2*self.something), 0)

				render.SetMaterial(glow)
				render.DrawQuadEasy(self.position+ Vector(0,0,300*f2), -ang:Forward(), 200*f2*s, 2500/f, c, 0)
			--cam.End3D()
		end

		function META:DrawTranslucent(time, f, f2)
			self.visible = util.PixelVisible(self.position, 50, self.pixvis)
			self:DrawDownBeam(time, f, f2)
			self:DrawSprites(time, f, f2)

			self:DrawRefraction(time, f, f2)
			self:DrawRefraction2(time, f, f2)
			self:DrawGlow(time, f, f2)
			self:DrawSunbeams(time, f, f2)
		end

		function META:DrawOpaque(time, f, f2)
			self:DrawRefraction2(time, f, f2)

			local dlight = DynamicLight( self.ent:EntIndex() )
			if dlight then
				dlight.pos = self.ent:GetPos()
				dlight.r = self.color.r
				dlight.g = self.color.g
				dlight.b = self.color.b
				dlight.brightness = 2
				dlight.Decay = 1000
				dlight.Size = self.size*300
				dlight.DieTime = CurTime() + 1
			end
		end

		jfx.RegisterEffect(META)
	end

	do
		local trail = jfx.CreateMaterial({
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
				self.trails[i] = self.trails[i] or {}
				self.trails[i].vec = self.trails[i].vec or VectorRand()
				self.trails[i].vec2 = self.trails[i].vec2 or VectorRand()
				local v = self.trails[i].vec
				local v2 = self.trails[i].vec2

				local s = (i/8) * math.pi * 2
				local offset = Vector(math.sin(s+v.x), math.cos(s+v.y), math.sin(-s+v.z)) * 30
				local t = RealTime()*500
				offset:Rotate(Angle(t*v2.x, t*v2.y, t*v2.z))

				jfx.DrawTrail(self.trails[i], 1, 2, self.position2 + offset, trail, self.color.r, self.color.g, self.color.b, 255*(f2^2), self.color.r*2, self.color.g*2, self.color.b*2, 0, 10, 10, f2)
			end
		end

		jfx.RegisterEffect(META)
	end
end


local SWEP = {Primary = {Automatic = true}, Secondary = {}}

SWEP.ClassName = "weapon_magic"
SWEP.PrintName = "magic"
SWEP.Spawnable = true
SWEP.Category = "JRPG"
SWEP.RenderGroup = RENDERGROUP_TRANSLUCENT
SWEP.WorldModel = "models/Gibs/HGIBS.mdl"
SWEP.IsWeaponMagic = true

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
		if wep:IsValid() and wep:GetOwner():IsValid() and wep.IsWeaponMagic and wep.DeployMagic then
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

				if pos and ang then
					self:SetPos(pos)
					self:SetAngles(ang)
				end
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
	local jfx = requirex("jfx")

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
		jfx.CreateEffect("something", {
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
		jfx.CreateEffect("something", {
			ent = self.Owner,
			color = Color(r, g, b, 50),
			size = nil,
			something = 0,
			length = 1,
		})

		jfx.CreateEffect("trails", {
			ent = self.Owner,
			color = Color(r, g, b, 50),
			length = 2,
		})
	end
end

if SERVER then
	util.AddNetworkString(SWEP.ClassName)
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

local function manip_angles(ply, id, ang)
	if CLIENT then
		ply:InvalidateBoneCache()
	end
	if pac and pac.ManipulateBoneAngles then
		pac.ManipulateBoneAngles(ply, id, ang)
	else
		ply:ManipulateBoneAngles(id, ang)
	end
end

function SWEP:ThrowAnimation(left_hand)
	jrpg.PlayGestureAnimation(self.Owner, {
		seq = "zombie_attack_0" .. (left_hand and 3 or 2),
		--seq = "wos_bs_shared_throw_star",
		start = 0.2,
		stop = 1,
		speed = 1.5,
		weight = math.Rand(0.45, 0.75),
		slot = GESTURE_SLOT_GRENADE,
		callback =  function(f)
			manip_angles(self.Owner, self.Owner:LookupBone("ValveBiped.Bip01_Head1"), Angle(0,Lerp(f, -65, -0),0))
		end,
		done = function()
			manip_angles(self.Owner, self.Owner:LookupBone("ValveBiped.Bip01_Head1"), Angle(0,0,0))
		end,
	})
end

function SWEP:Cast(target)
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

		if CPPI then ent:CPPISetOwner(self.Owner) end
		ent:SetProjectileData(self.Owner, self.Owner:GetShootPos(), self.Owner:GetAimVector(), 50, self)

		if target then
			ent:SetOwner()
			ent.pos = self:GetOwner()
			ent.lpos = Vector(0,0,50)
		end

		ent:Spawn()

		if bone_id then
			ent:FollowBone(self.Owner, bone_id)
			ent:SetLocalPos(Vector(0,0,0))
		end

		timer.Simple(0.2, function()
			ent:SetParent(NULL)
			local pos

			if bone_id then
				pos = self.Owner:GetBonePosition(bone_id)
			else
				pos = self.Owner:EyePos() + self.Owner:GetVelocity()/4
			end

			ent:SetProjectileData(self.Owner, pos, self.Owner:GetAimVector(), 50, self)
		end)
	end
end

function SWEP:PrimaryAttack()
	if self:GetNextPrimaryFire() > CurTime() or not self.wepstats then return end

	self:SetNextPrimaryFire(CurTime() + 0.6)

	self:Cast()
end

function SWEP:SecondaryAttack()
	self:Cast(self:GetOwner())
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