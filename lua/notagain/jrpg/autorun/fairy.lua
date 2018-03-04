local ENT = {}

ENT.ClassName = "fairy"
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Size = 1
ENT.Visibility = 0

if CLIENT then

	function jrpg.DrawFairySunbeams()
		local ents = ents.FindByClass(ENT.ClassName)
		local count = #ents
		for key, ent in ipairs(ents) do
			ent:DrawSunbeams(ent:GetPos(), 0.05/count, 0.025)
		end
	end

	local function VectorRandSphere()
		return Angle(math.Rand(-180,180), math.Rand(-180,180), math.Rand(-180,180)):Up()
	end

	function ENT:SetFairyHue(hue)
		self.Color = HSVToColor(hue, 0.4, 1)
	end

	function ENT:SetFairyColor(color)
		self.Color = color
	end

	do -- sounds
		ENT.next_sound = 0

		function ENT:CalcSoundQueue(play_next_now)
			if #self.SoundQueue > 0 and (play_next_now or self.next_sound < CurTime()) then

				-- stop any previous sounds
				if self.current_sound then
					self.current_sound:Stop()
				end

				-- remove and get the first sound from the queue
				local data = table.remove(self.SoundQueue, 1)

				if data.snd and data.pitch then
					data.snd:PlayEx(100, data.pitch)

					-- pulse the fairy a bit so it looks like it's talking
					self:PulseSize(1.3, 1.8)

					-- store the sound so we can stop it before we play the next sound
					self.current_sound = data.snd
				end

				-- store when to play the next sound
				self.next_sound = CurTime() + data.duration
			end
		end

		function ENT:AddToSoundQueue(path, pitch, play_now)

			-- if play_now is true don't add to the old queue
			local queue = play_now and {} or self.SoundQueue

			if path == "." then
				table.insert(
					queue,
					{
						duration = 0.5,
					}
				)
			else
				table.insert(
					queue,
					{
						snd = CreateSound(self, path),
						pitch = pitch,

						-- get the sound length of the sound and scale it with the pitch above
						-- the sounds have a little empty space at the end so subtract 0.05 seconds from their time
						duration = SoundDuration(path) * (pitch / 100) - 0.05,
					}
				)
			end

			self.SoundQueue = queue

			if play_now then
				self:CalcSoundQueue(true)
			end
		end

		-- makes the fairy talk without using a real language
		-- it's using sounds from a zelda game which does the same thing
		function ENT:PlayPhrase(text)
			text = text:lower()
			text = text .. " "

			local queue = {}
			local total_duration = 0

			-- split the sentence up in chunks
			for chunk in (" "..text.." "):gsub("%p", "%1 "):gmatch("(.-)[%s]") do
				if chunk:Trim() ~= "" then
					if chunk == "." then
						self:AddToSoundQueue(chunk)
					else
						-- this will use each chunk as random seed to make sure it picks the same sound for each chunk every time
						local path = "alan/midna/speech"..tostring(math.max(tonumber(util.CRC(chunk))%47, 1))..".wav"

						-- randomize pitch a little, makes it sound less static
						local pitch = math.random(120,125)

						self:AddToSoundQueue(path, pitch)
					end
				end
			end
		end

		function ENT:Laugh()
			local path = "alan/nymph/NymphGiggle_0"..math.random(9)..".wav"
			local pitch = math.random(95,105)

			self:AddToSoundQueue(path, pitch, true)

			self.Laughing = true
		end

		function ENT:Ouch(time)
			time = time or 0

			local path = "alan/nymph/NymphHit_0"..math.random(4)..".wav"
			local pitch = math.random(95,105)

			self:AddToSoundQueue(path, pitch, true)

			-- make the fairy hurt for about 1-2 seconds
			self.Hurting = true

			timer.Simple(time, function()
				if self:IsValid() then
					self.Hurting = false
				end
			end)
		end

		-- this doesn't need to use the sound queue
		function ENT:Bounce()
			local csp = CreateSound(self, "alan/bonk.wav")
			csp:PlayEx(100, math.random(150, 220))
			csp:FadeOut(math.random()*0.75)
		end
	end

	local wing_mdl = Model("models/python1320/wing.mdl")

	ENT.WingSpeed = 6.3
	ENT.FlapLength = 30
	ENT.WingSize = 0.4

	ENT.SizePulse = 1

	local function CreateEntity(mdl)
		local ent = ClientsideModel(mdl)

		ent:SetMaterial("alan/wing")

		function ent:RenderOverride()
			if self.scale then
				local matrix = Matrix()
				matrix:Scale(self.scale)
				self:EnableMatrix("RenderMultiply", matrix)
			end

			render.CullMode(1)
			self:DrawModel()
			render.CullMode(0)
			self:DrawModel()
		end

		return ent
	end

	function ENT:Initialize()
		self.SoundQueue = {}

		self.Emitter = ParticleEmitter(vector_origin)
		self.Emitter:SetNoDraw(true)

		self:InitWings()

		self.light = DynamicLight(self:EntIndex())
		self.light.Decay = -0
		self.light.DieTime = 9999999

		self.flap = CreateSound(self, "alan/flap.wav")
        self.float = CreateSound(self, "alan/float.wav")

        self.flap:Play()
        self.float:Play()

        self.flap:ChangeVolume(0.2)

		-- randomize the fairy hue
		self:SetFairyHue(tonumber(util.CRC(self:EntIndex()))%360)

		-- random size
		self.Size = (tonumber(util.CRC(self:EntIndex()))%100/100) + 0.5

		self.pixvis = util.GetPixelVisibleHandle()

		if render.SupportsPixelShaders_2_0() then
			hook.Add("RenderScreenspaceEffects", "fairy_sunbeams", jrpg.DrawFairySunbeams)
		end
	end

	function ENT:InitWings()
		self.leftwing = CreateEntity(wing_mdl)
		self.rightwing = CreateEntity(wing_mdl)
		self.bleftwing = CreateEntity(wing_mdl)
		self.brightwing = CreateEntity(wing_mdl)

		self.leftwing:SetNoDraw(true)
		self.rightwing:SetNoDraw(true)
		self.bleftwing:SetNoDraw(true)
		self.brightwing:SetNoDraw(true)
	end

	-- draw after transparent stuff
	ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

	function ENT:DrawTranslucent()
		self:CalcAngles()

		self:DrawParticles()
		self:DrawWings(0)
		self:DrawSprites()
	end

	function ENT:Draw()
		self:DrawTranslucent()
	end

	function ENT:Think()
		self:CalcSounds()
		self:CalcLight()
		self:CalcPulse()

		self:NextThink(CurTime())
		return true
	end

	function ENT:PulseSize(min, max)
		self.SizePulse = math.Rand(min or 1.3, max or 1.8)
	end

	function ENT:CalcPulse()
		self.SizePulse = math.Clamp(self.SizePulse + ((1 - self.SizePulse) * FrameTime() * 5), 1, 3)
	end

	function ENT:CalcAngles()
		if self.Hurting then return end

		local vel = self:GetVelocity()
		if vel:Length() > 10 then
			local ang = vel:Angle()
			self:SetAngles(ang)
			self:SetRenderAngles(ang)
			self.last_ang = ang
		elseif self.last_ang then
			self:SetAngles(self.last_ang)
		end
	end

	function ENT:CalcSounds()
		local own = self:GetOwner()

		if own:IsValid() and own.VoiceVolume then
			self.SizePulse = (own:VoiceVolume() * 10) ^ 0.5
		end

		if self.Hurting then
			self.flap:Stop()
		else
			self.flap:Play()
			self.flap:ChangeVolume(0.2)
		end

	    local length = self:GetVelocity():Length()

        self.float:ChangePitch(length/50+100)
        self.float:ChangeVolume(length/100)

        self.flap:ChangePitch((length/50+100) + self.SizePulse * 20)
		self.flap:ChangeVolume(0.1+(length/100))

		self:CalcSoundQueue()
	end

	function ENT:CalcLight()
		if self.light then
			self.light.Pos = self:GetPos()

			self.light.r = self.Color.r/8
			self.light.g = self.Color.g/8
			self.light.b = self.Color.b/8

			self.light.Brightness = self.Size * 0.5
			self.light.Size = math.Clamp(self.Size * 512/2, 0, 1000)
		end
	end

	local glow = Material("sprites/light_glow02_add")
	local warp = Material("particle/warp2_warp")
	local mouth = Material("icon16/add.png")
	local blur = Material("sprites/heatwave")

	local eye_hurt = Material("sprites/key_12")
	local eye_idle = Material("icon16/tick.png")
	local eye_happy = Material("icon16/error.png")
	local eye_heart = Material("icon16/heart.png")

	ENT.Blink = math.huge

	function ENT:DrawSprites()
		local pos = self:GetPos()
		local pulse = math.sin(CurTime()*2) * 0.5

		render.SetMaterial(warp)
			render.DrawSprite(
				pos, 12 * self.Size + pulse,
				12 * self.Size + pulse,
				Color(self.Color.r, self.Color.g, self.Color.b, 100)
			)

		render.SetMaterial(blur)
			render.DrawSprite(
				pos, (1-self.SizePulse) * 20,
				(1-self.SizePulse) * 20,
				Color(10,10,10, 1)
			)

		render.SetMaterial(glow)
			render.DrawSprite(
				pos,
				50 * self.Size,
				50 * self.Size,
				Color(self.Color.r, self.Color.g, self.Color.b, 150)
			)
			render.DrawSprite(
				pos,
				30 * self.Size,
				30 * self.Size,
				self.Color
			)

		local fade_mult = math.Clamp(-self:GetForward():Dot((self:GetPos() - EyePos()):GetNormalized()), 0, 1)

		if fade_mult ~= 0 then

			if self.Hurting then
				render.SetMaterial(eye_hurt)
			else
				render.SetMaterial(eye_heart)
			end

			if self.Blink > CurTime() then
				for i = 0, 1 do
					render.DrawSprite(
						pos + (self:GetRight() * (i == 0 and 0.8 or -0.8) + self:GetUp() * 0.7) * self.Size,

						0.5 * fade_mult * self.Size,
						0.5 * fade_mult * self.Size,

						Color(10,10,10,200 * fade_mult)
					)
				end
			else
				self.Blink = math.random() < 0.99 and CurTime()-0.2 or math.huge
			end

			render.SetMaterial(mouth)

			render.DrawSprite(
				pos + (self:GetRight() * -0.05 -self:GetUp() * 0.7) * self.Size,

				0.6 * fade_mult * self.Size * self.SizePulse ^ 1.5,
				0.6 * fade_mult * self.Size * self.SizePulse,

				Color(10,10,10,200*fade_mult)
			)

		end
	end

	function ENT:DrawSunbeams(pos, mult, siz)
		local ply = LocalPlayer()
		local eye = EyePos()

		self.Visibility = util.PixelVisible(self:GetPos(), self.Size * 4, self.pixvis)

		if self.Visibility > 0 then
			local spos = pos:ToScreen()
			DrawSunbeams(
				0.25,
				math.Clamp(mult * (math.Clamp(EyeVector():DotProduct((pos - eye):GetNormalized()) - 0.5, 0, 1) * 2) ^ 5, 0, 1),
				siz,
				spos.x / ScrW(),
				spos.y / ScrH()
			)
		end
	end

	function ENT:DrawParticles()
		local particle = self.Emitter:Add("particle/fire", self:GetPos() + (VectorRandSphere() * self.Size * 4 * math.random()))
		local mult = math.Clamp((self:GetVelocity():Length() * 0.1), 0, 1)

		particle:SetDieTime(math.Rand(0.5, 2)*self.SizePulse*5)
		particle:SetColor(self.Color.r, self.Color.g, self.Color.b)


		if self.Hurting then
			particle:SetGravity(physenv.GetGravity())
			particle:SetVelocity((self:GetVelocity() * 0.1) + (VectorRandSphere() * math.random(20, 30)))
			particle:SetAirResistance(math.Rand(1,3))
		else
			particle:SetAirResistance(math.Rand(5,15)*10)
			particle:SetVelocity((self:GetVelocity() * 0.1) + (VectorRandSphere() * math.random(2, 5))*(self.SizePulse^5))
			particle:SetGravity(VectorRand() + physenv.GetGravity():GetNormalized() * (math.random() > 0.9 and 10 or 1))
		end

		particle:SetStartAlpha(0)
		particle:SetEndAlpha(255)

		--particle:SetEndLength(self.Size * 3)
		particle:SetStartSize(math.Rand(1, self.Size*8)/3)
		particle:SetEndSize(0)

		particle:SetCollide(true)
		particle:SetRoll(math.random())
		particle:SetBounce(0.8)

		self.Emitter:Draw()
	end

	function ENT:DrawWings(offset)
		if not self.leftwing:IsValid() then
			self:InitWings()
		return end

		local size = self.Size * self.WingSize * 0.4
		local ang = self:GetAngles()
		ang:RotateAroundAxis(self:GetUp(), -90)
		--ang:RotateAroundAxis(Vector(0,0,1), -90)
		--ang:RotateAroundAxis(Vector(1,0,0), -90)

		offset = offset or 0
		self.WingSpeed = 6.3 * (self.Hurting and 0 or 1)

		local leftposition, leftangles = LocalToWorld(Vector(0, 0, 0), Angle(0,TimedSin(self.WingSpeed,self.FlapLength*2,0,offset), 0), self:GetPos(), ang)
		local rightposition, rightangles = LocalToWorld(Vector(0, 0, 0), Angle(0, -TimedSin(self.WingSpeed,self.FlapLength*2,0,offset), 0), self:GetPos(), ang)


		self.leftwing:SetPos(leftposition)
		self.rightwing:SetPos(rightposition)

		self.leftwing:SetAngles(leftangles)
		self.rightwing:SetAngles(rightangles)

		local bleftposition, bleftangles = LocalToWorld(Vector(0, 0, -0.5), Angle(30, TimedSin(self.WingSpeed,self.FlapLength,0,offset+math.pi)/2, 50), self:GetPos(), ang)
		local brightposition, brightangles = LocalToWorld(Vector(0, 0, -0.5), Angle(-30, -TimedSin(self.WingSpeed,self.FlapLength,0,offset+math.pi)/2, 50), self:GetPos(), ang)

		self.bleftwing:SetPos(bleftposition)
		self.brightwing:SetPos(brightposition)

		self.bleftwing:SetAngles(bleftangles)
		self.brightwing:SetAngles(brightangles)

		render.SuppressEngineLighting(true)
		render.SetColorModulation(self.Color.r/200, self.Color.g/200, self.Color.b/200)

		self.leftwing.scale = Vector(0.75,1.25,2.5)*size
		self.rightwing.scale = Vector(0.75,1.25,2.5)*size

		self.bleftwing.scale = Vector(0.25,0.75,2)*size
		self.brightwing.scale = Vector(0.25,0.75,2)*size

		self.leftwing:SetupBones()
		self.rightwing:SetupBones()
		self.bleftwing:SetupBones()
		self.brightwing:SetupBones()

		self.leftwing:DrawModel()
		self.rightwing:DrawModel()
		self.bleftwing:DrawModel()
		self.brightwing:DrawModel()

		render.SetColorModulation(0,0,0)
		render.SuppressEngineLighting(false)
	end

	function ENT:OnRemove()
        SafeRemoveEntity(self.leftwing)
        SafeRemoveEntity(self.rightwing)
        SafeRemoveEntity(self.bleftwing)
        SafeRemoveEntity(self.brightwing)

		self.flap:Stop()
		self.float:Stop()

		self.light.Decay = 0
		self.light.DieTime = 0

		if #ents.FindByClass(ENT.ClassName) == 1 then
			hook.Remove("RenderScreenspaceEffects", "fairy_sunbeams")
		end
	end

	net.Receive("fairy_func_call", function()
		local ent = net.ReadEntity()
		local func = net.ReadString()
		local args = net.ReadTable()

		if ent:IsValid() then
			ent[func](ent, unpack(args))
		end
	end)
end

if SERVER then

	function ENT:Initialize()
		self:SetModel("models/dav0r/hoverball.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:PhysWake()

		self:StartMotionController()

		self:GetPhysicsObject():SetMass(0.1)
		self:GetPhysicsObject():EnableGravity(false)
	end

	function ENT:MoveTo(pos)
		self.MovePos = pos
	end

	function ENT:HasReachedTarget()
		return self.MovePos and self:GetPos():Distance(self.MovePos) < 50
	end

	function ENT:PhysicsSimulate(phys)
		if self.GravityOn then return end

		if self.MovePos and not self:HasReachedTarget() then
			phys:AddVelocity(self.MovePos - phys:GetPos())
			phys:AddVelocity(self:GetVelocity() * -0.4)
			self.MovePos = nil
		end
	end

	function ENT:Think()
		self:PhysWake()
	end

	function ENT:EnableGravity(time)
		local phys = self:GetPhysicsObject()
		phys:EnableGravity(true)
		self.GravityOn = true

		timer.Simple(time, function()
			if self:IsValid() and phys:IsValid() then
				phys:EnableGravity(false)
				self.GravityOn = false
			end
		end)
	end

	util.AddNetworkString("fairy_func_call")

	function ENT:CallClientFunction(func, ...)
		net.Start("fairy_func_call")
			net.WriteEntity(self)
			net.WriteString(func)
			net.WriteTable({...})
		net.Broadcast()
	end

	function ENT:OnTakeDamage(dmg)
		local time = math.Rand(1,2)
		self:EnableGravity(time)
		self:CallClientFunction("Ouch", time)

		self.Hurting = true

		timer.Simple(time, function()
			if self:IsValid() then
				self.Hurting = false
			end
		end)

		local phys = self:GetPhysicsObject()
		phys:AddVelocity(dmg:GetDamageForce())

		-- local ply = dmg:GetAttacker()
		-- if ply:IsPlayer() and (not ply.alan_last_hurt or ply.alan_last_hurt < CurTime()) then
		-- 	self:PlayerSay(ply, ply:Nick() .. table.Random(hurt_list))
		-- 	ply.alan_last_hurt = CurTime() + 1
		-- 	self:Smite(ply)
		-- end
	end

	function ENT:PhysicsCollide(data, phys)

		if not self.last_collide  or self.last_collide < CurTime() then
			local ent = data.HitEntity
			if ent:IsValid() and not ent:IsPlayer() and ent:GetModel() then
				self.last_collide = CurTime() + 1
			end
		end

		if data.Speed > 50 and data.DeltaTime > 0.2 then
			local time = math.Rand(0.5,1)
			self:EnableGravity(time)
			self:CallClientFunction("Ouch", time)
			self:CallClientFunction("Bounce")
			self.follow_ent = NULL
		end

		self:LaughAtMe()

		phys:SetVelocity(phys:GetVelocity():GetNormalized() * data.OurOldVelocity:Length() * 0.99)
	end

	function ENT:LaughAtMe()
		local fairies = ents.FindByClass("fairy")
		for	key, ent in pairs(fairies) do
			if ent ~= self and math.random() < 1 / #fairies then
				ent:CallClientFunction("Laugh")
			end
		end
	end

	function ENT:Say(str)
		self:CallClientFunction("Say", answer)
	end

end

scripted_ents.Register(ENT, ENT.ClassName)