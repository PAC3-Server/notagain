do
	local function get_effect(ply)
		local hp = ply:GetNWFloat("hp_overload", 0)
		local mp = ply:GetNWFloat("mp_overload", 0)
		local sp = ply:GetNWFloat("sp_overload", 0)

		if hp <= 0 and mp <= 0 and sp <= 0 then return end

		local factor = hp+mp+sp

		local color = Vector(1,1,1)
		color = color + (Vector(0,1,0) * hp)
		color = color + (Vector(0,0,1) * mp)
		color = color + (Vector(1,1,0) * sp)

		return factor, color
	end


	if CLIENT then
		hook.Add("RenderScreenspaceEffects", "potion_overload", function()
			local factor, color = get_effect(LocalPlayer())

			if not factor then return end

			factor = factor / 10
			color = color * 0.02

			local params = {}
			params[ "$pp_colour_addr" ] = color.r*factor
			params[ "$pp_colour_addg" ] = color.g*factor
			params[ "$pp_colour_addb" ] = color.b*factor
			params[ "$pp_colour_brightness" ] = -0.2*factor
			params[ "$pp_colour_contrast" ] = 1
			params[ "$pp_colour_colour" ] = 1-(0.2*factor)
			params[ "$pp_colour_mulr" ] = 0
			params[ "$pp_colour_mulg" ] = 0
			params[ "$pp_colour_mulb" ] = 0
			DrawBloom( 0.4*factor, 3.39*factor, 11.21, 9, 2, 1.96, color.r, color.g, color.b)
			DrawColorModify(params)
			DrawMotionBlur(0.1,1*factor,0)
			DrawSharpen(5*factor, 0.2)
		end)

		local PUKE = {}

		function PUKE:Init(data)
			self.ply = data:GetEntity()
			if self.ply:IsValid() then
				self.force = data:GetScale()
				self.duration = data:GetRadius()

				self.emitter = ParticleEmitter(self.ply:GetPos())
				self.ply.pukeactive = true
			end
		end

		function PUKE:Think()
			self.duration = self.duration - 1
			local ply = self.ply

			if not IsValid(ply) then self.emitter:Finish() return false end
			if self.duration < 0 then ply.pukeactive = false self.emitter:Finish() return false end

			if math.random(10) == 1 then ply:EmitSound("npc/barnacle/barnacle_die"..math.random(1,2)..".wav",75, math.random(125,200)) end

			local factor, color = get_effect(ply)
			if not factor then return end
			color = color * 255 / factor

			local bonenum = ply:LookupBone( "ValveBiped.Bip01_Head1" )
			local pos = bonenum and ply:GetBonePosition( bonenum ) or ply:EyePos()

			local particle = self.emitter:Add("particle/fire", pos)
			particle:SetVelocity(ply:GetAimVector() * self.force + (VectorRand() * 20))
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( self.duration )
			particle:SetEndAlpha( 0 )
			particle:SetStartLength(20)
			particle:SetStartSize( math.Rand( 1, 2 ) )
			particle:SetEndSize( math.Rand( 20, 30 ) )
			particle:SetColor( math.min(color.r, 255), math.min(color.g, 255), math.min(color.b, 255) )
			particle:SetCollide( true )
			particle:SetBounce(0.1)
			particle:SetGravity( Vector( 0, 0, -400 ) )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetCollideCallback( function(self, hitpos, normal)
				if math.random() > 0.95 then
					util.DecalEx(Material("decals/decal_paintsplatterpink001"), Entity(0), hitpos, normal, Color(color.r, color.g, color.b, 255), 0.5,0.5)
				end
			end )
			return true
		end

		function PUKE:Render() end

		effects.Register(PUKE, "potion_overload")
	end

	if SERVER then
		local random_words = {
			"ganon",
			"link",
			"squadilah",
			"du",
			"princess",
			"i love you",
			"wtf!!!!!",
			"thanks to you two",
			"kiss",
			"we gotta save the",
		}

		local function calc(ply, what)
			local factor = ply:GetNWFloat(what, 0)
			if factor > 0 then
				if factor > 10 and math.random() > 0.5 then
					if factor >= 10 then
						local data = EffectData()
						data:SetEntity(ply)
						data:SetScale(100)
						data:SetRadius(300)
						util.Effect("potion_overload", data)
					end
					factor = math.max(factor - 5, 0)
				end
				ply:SetNWFloat(what, factor - 0.1)
			end
		end

		hook.Add("Think", "potion_overload", function()
			if math.random() > 0.94 then
				for key, ply in ipairs(player.GetAll()) do
					calc(ply, "hp_overload")
					calc(ply, "mp_overload")
					calc(ply, "sp_overload")
				end
			end
		end)

		hook.Add("PlayerSay", "potion_overload", function(ply, text)
			local factor = get_effect(ply)

			-- drunk?
			if not factor or factor <= 5 then return end

			factor = factor * 5

			-- blow up our chat into words.
			local words = string.Explode( " ", text )

			if factor > 20 then
				-- swap out some words.
				local amt = math.Clamp( ( #words / 3 ) * ( factor / 100 ) , 1 , 10 )
				for i = 1 , amt do
					local a = math.random( 1 , #words )
					local b = math.random( 1 , #words )
					local aword = words[a]
					local bword = words[b]
					words[a] = bword
					words[b] = aword
				end
			end

			if factor > 35 then
				-- inject words
				local amt = math.Clamp( ( #words / 6 ) * ( factor / 100 ) , 1 , 10 )
				for i = 1 , amt do
					local num = math.random( 1 , #random_words )
					local pos = math.random( 1 , #words )
					local word = random_words[num]
					table.insert( words , pos , word )
				end
			end

			-- letters we want to slur.
			local letters = {
				'a','e','i','o','u','y','z','s'
			}

			-- slur!
			for i = 1 , #words do
				local word = words[i]
				local j
				for j = 1 , string.len( word ) do
					local letter = string.sub( word , j , j )
					if table.HasValue( letters , letter ) and math.random( 3 ) == 1 then
						local slur = math.ceil( ( factor / 100 ) * math.random( 2 , 5 ) )
						local first = string.sub( word , 1 , j - 1 )
						local last = string.sub( word , j + 1 )
						word = first .. string.rep( letter , slur ) .. last
					end
				end
				words[i] = word
			end

			return table.concat( words , " " )
		end)
	end
end

do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "potion_base"

	SWEP.Color = Vector(2, 1, 0.5)

	SWEP.PrintName = "potion"
	SWEP.Spawnable = false
	SWEP.WorldModel = "models/healthvial.mdl"

	SWEP.ViewModel = Model( "models/weapons/c_medkit.mdl" )
	SWEP.UseHands = true

	SWEP.RenderGroup = RENDERGROUP_TRANSLUCENT
	SWEP.is_potion = true

	if CLIENT then
		local shiny = CreateMaterial(tostring({}) .. os.clock(), "VertexLitGeneric", {
			["$Additive"] = 1,
			--["$Translucent"] = 1,
			--["$VertexAlpha"] = 1,
			--["$VertexColor"] = 1,

			["$Phong"] = 1,
			["$PhongBoost"] = 6,
			["$PhongExponent"] = 5,
			["$PhongFresnelRange"] = Vector(0,0.5,1),
			["$PhongTint"] = Vector(1,1,1),


			["$Rimlight"] = 1,
			["$RimlightBoost"] = 10,
			["$RimlightExponent"] = 5,

			["$BaseTexture"] = "models/debug/debugwhite",
			["$BumpMap"] = "dev/bump_normal",

			Proxies = {
				Equals = {
					SrcVar1 = "$color",
					ResultVar = "$phongtint",
				},
			},
		})

		hook.Add("UpdateAnimation", "potion", function(ply)
			local self = ply:GetActiveWeapon()
			if not self.is_potion then return end

			if self.anim_time then
				local f = self.anim_time - RealTime()
				f = f / self.anim_duration

				ply:SetPoseParameter("head_pitch", math.sin(f*math.pi*2)*100)
				ply:SetPoseParameter("head_yaw", 0)

				if f < 0.5 then
					self.anim_time = nil
				end
			end
		end)


		local suppress_player_draw = false

		hook.Add("PrePlayerDraw", "potion", function(ply)
			if suppress_player_draw and ply == LocalPlayer() then
				return true
			end
		end)

		function SWEP:DrawWorldModelTranslucent()
			local ply = self:GetOwner()

			if ply:IsValid() then
				local id = ply:LookupBone("ValveBiped.Bip01_L_Hand")
				if id then
					local m = ply:GetBoneMatrix(id)
					pos = m:GetTranslation()
					ang = m:GetAngles()

					pos = pos + (ang:Forward() * 5)
					pos = pos + (ang:Right() * 3)
					pos = pos + (ang:Up() * -7)

					self:SetPos(pos)
					self:SetAngles(ang)
					self:SetupBones()
				end
			end

			suppress_player_draw = true
			self:DrawModel()
			suppress_player_draw = false

			--render.SetColorModulation()
			shiny:SetVector("$color2", self.Color)
			render.ModelMaterialOverride(shiny)

			suppress_player_draw = true
			self:DrawModel()
			suppress_player_draw = false

			render.ModelMaterialOverride()
			render.SetColorModulation(1,1,1)
		end

		net.Receive("potion", function()
			local wep = net.ReadEntity()
			if not IsValid(wep) or not wep.Animation then return end

			wep:Animation()
		end)
	end

	function SWEP:Initialize()
		self:SetHoldType("normal")

		--self:DrawShadow(false)
	end

	function SWEP:Animation()
		if not IsValid(self.Owner) then return end
		local seq, time = self.Owner:LookupSequence("gesture_salute")
		self.Owner:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, seq, 0.3, true)
		self.anim_time = RealTime() + time
		self.anim_duration = time
	end

	if SERVER then
		util.AddNetworkString("potion")
	end

	function SWEP:PrimaryAttack()
		if SERVER then
			self:Animation()
			net.Start("potion", true)
				net.WriteEntity(self)
			net.SendOmit(self.Owner)

			self.Owner:SetNWBool("drinking_potion", true)

			timer.Simple(0.5, function()
				if not self:IsValid() or not self.Owner:IsValid() then return end
				self.Owner:EmitSound("ambient/levels/canals/toxic_slime_gurgle"..table.Random({2,4,7})..".wav")

				self:OnDrink(self.Owner)

				self.Owner:SetNWBool("drinking_potion", false)
			end)
		end

		if CLIENT then
			self:Animation()
		end

		self:SetNextPrimaryFire(CurTime() + 0.25)
	end


	function SWEP:SecondaryAttack()

	end

	function SWEP:OnDrink()

	end

	weapons.Register(SWEP, SWEP.ClassName)
end

local function make_potion(name, color, func)
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.Spawnable = true
	SWEP.AdminSpawnable = false
	SWEP.PrintName = name .. " potion"
	SWEP.ClassName = "potion_" .. name
	SWEP.Category = "JRPG"
	SWEP.Base = "potion_base"
	SWEP.Color = color
	SWEP.OnDrink = func

	weapons.Register(SWEP, SWEP.ClassName)
end

make_potion("health", Vector(0, 2, 0.5), function(wep, ply)
	ply:SetHealth(math.min(ply:Health() + 50, ply:GetMaxHealth()))

	if ply:Health() == ply:GetMaxHealth() then
		ply:SetNWFloat("hp_overload", ply:GetNWFloat("hp_overload", 0) + 1)
	end
end)
make_potion("mana", Vector(0, 0, 2), function(wep, ply)
	jattributes.SetMana(ply, math.min(jattributes.GetMana(ply) + 50, jattributes.GetMaxMana(ply)))

	if jattributes.GetMana(ply) == jattributes.GetMaxMana(ply) then
		ply:SetNWFloat("mp_overload", ply:GetNWFloat("mp_overload", 0) + 2)
	end
end)

make_potion("stamina", Vector(2, 2, 0), function(wep, ply)
	jattributes.SetStamina(ply, math.min(jattributes.GetStamina(ply) + 50, jattributes.GetMaxStamina(ply)))

	if jattributes.GetStamina(ply) == jattributes.GetMaxStamina(ply) then
		ply:SetNWFloat("sp_overload", ply:GetNWFloat("sp_overload", 0) + 3)
	end
end)

if SERVER then

	jrpg.AddPlayerHook("PlayerSpawn", "potion", function(ply)
		ply:SetNWFloat("hp_overload", 0)
		ply:SetNWFloat("mp_overload", 0)
		ply:SetNWFloat("sp_overload", 0)
	end)

	if me then
		local name = "potion_stamina"
		SafeRemoveEntity(me:GetWeapon(name))
		timer.Simple(0.1, function()
		me:Give(name)
		me:SelectWeapon(name)
		end)
	end
end
