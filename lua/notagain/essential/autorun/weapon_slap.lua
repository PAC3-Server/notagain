SWEP = {}
SWEP.Base = "weapon_base"
SWEP.PrintName = "Slap"
SWEP.Slot = 1
SWEP.SlotPos = 4
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.UseHands = false

SWEP.DrawWeaponInfoBox	= false
SWEP.BounceWeaponIcon = false
SWEP.Author = "TW1STaL1CKY"
SWEP.Instructions = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.IconLetter = ""

SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV = 72
SWEP.ViewModelFlip = false

SWEP.Spawnable = true
SWEP.AutoSwitchTo = false

local function Sound2(snd)
	local ret = Sound(snd)
	if ret and SERVER then
		resource.AddSingleFile("sound/"..snd)
	end
	return ret
end

SWEP.Sound = Sound2("chatsounds/autoadd/wurm/slap.ogg")
SWEP.Sound2 = Sound2("chatsounds/autoadd/cartoon_sfx/slap2.ogg")
SWEP.SwingSound = Sound("weapons/iceaxe/iceaxe_swing1.wav")

SWEP.Primary = {}
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = ""
SWEP.Primary.Delay = 0.3

SWEP.Primary.Damage = 3

SWEP.Secondary = {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Delay = 1
--SWEP.Secondary.Allowed = false

SWEP.Secondary.Force = 1200

SWEP.LastSecretSay = 0
SWEP.SecretSays = {
	"vo/npc/alyx/al_combat_grim_04.wav",
	"vo/npc/alyx/al_combat_grim_05.wav",
	"vo/npc/alyx/al_excuse03.wav",
	"vo/npc/alyx/uggh02.wav",
	"vo/eli_lab/al_laugh01.wav",
	"vo/eli_lab/al_laugh02.wav",
	"vo/k_lab2/al_whee_b.wav",
	"vo/k_lab/al_careful.wav",
	"vo/k_lab/al_carefulthere.wav",
	"vo/k_lab/al_thatsit.wav",
	"vo/k_lab/al_wontlook.wav",
	"vo/novaprospekt/al_elevator02.wav",
	"vo/novaprospekt/al_gladtoseeyou.wav",
	"vo/novaprospekt/al_warmeditup.wav",
	"vo/streetwar/alyx_gate/al_thatsit.wav",
	"vo/npc/female01/pain06.wav"
}

if CLIENT then
	function SWEP:DrawWorldModel()
		local sonr = self:GetOwner()

		if not IsValid(sonr) then
			self:DrawModel()
			return
		else
			self:DrawShadow(false)
		end
	end
end

function SWEP:Initialize()
	self:SetHoldType("melee")
end

function SWEP:OnDrop()
	SafeRemoveEntity(self)
end

function SWEP:PrimaryAttack()
	local now = CurTime()
	self:SetNextPrimaryFire(now+self.Primary.Delay)
	self:SetNextSecondaryFire(now+self.Primary.Delay)

	local sonr = self:GetOwner()

	sonr:SetAnimation(PLAYER_ATTACK1)

	local _ = SERVER and sonr:LagCompensation(true)

	local tr = util.TraceHull({
		start = sonr:GetShootPos(),
		endpos = sonr:GetShootPos()+(sonr:GetAimVector()*80),
		filter = sonr,
		mins = Vector(-4,-4,-4),
		maxs = Vector(4,4,4),
		mask = MASK_SHOT_HULL
	})
	local v = tr.Entity

	local _ = SERVER and sonr:LagCompensation(false)

	if SERVER then

		if tr.Hit then
			if IsValid(v) and (v:GetClass() == "lua_npc" and string.match(v:GetModel(),"alyx")) then
				local rnd = math.random(1,3)

				if rnd == 1 and self.LastSecretSay < now then
					local precisetr = sonr:GetEyeTrace()		--TraceHull doesn't give PhysicsBone >:C
					local bne = (precisetr.Entity == v) and v:TranslatePhysBoneToBone(precisetr.PhysicsBone) or -1

					local sayns = self.SecretSays

					for _,x in next,{"pelvis","thigh","clavicle"} do
						if string.match(string.lower(v:GetBoneName(bne)),x) then
							local sy = sayns[math.random(1,table.Count(sayns))]

							v:EmitSound(sy,75,math.random(99,101))

							self.LastSecretSay = now+3
							break
						end
					end
				end
			else
				local dmg = DamageInfo()
				dmg:SetAttacker(sonr)
				dmg:SetInflictor(self)
				dmg:SetDamage(self.Primary.Damage)
				dmg:SetDamageType(DMG_GENERIC)
				dmg:SetDamageForce(sonr:GetAimVector()*(175*self.Primary.Damage))
				dmg:SetDamagePosition(tr.HitPos)

				v:TakeDamageInfo(dmg)
			end

			local mscale = pac and (pac.GetPlayerSize and pac.GetPlayerSize(sonr)) or sonr:GetModelScale()
			local ptch = 135+(math.Clamp(1-mscale,-0.5,1)*100)

			sonr:EmitSound(self.Sound,75,math.random(ptch-7,ptch+7))
		else
			sonr:EmitSound(self.SwingSound,75,math.random(99,105),0.6)
		end

	end


	sonr:ViewPunch(tr.Hit and Angle(0.5,1.5,0) or Angle(0.3,0.5,0))
end

function SWEP:DrawWeaponSelection(x,y,w,t,a)

    draw.SimpleText("⚡","creditslogo",x+w/2,y,Color(255, 220, 0,a),TEXT_ALIGN_CENTER)

end

function SWEP:SecondaryAttack()
	local sonr = self:GetOwner()

	if sonr.in_rpland then return end
	if self.Secondary.Allowed == nil then
		if not sonr:IsAdmin() then return end
	else
		if not self.Secondary.Allowed then return end
	end

	local now = CurTime()
	self:SetNextPrimaryFire(now+math.max(self.Secondary.Delay-0.3,0.3))
	self:SetNextSecondaryFire(now+self.Secondary.Delay)

	sonr:SetAnimation(PLAYER_ATTACK1)

	local _ = SERVER and sonr:LagCompensation(true)

	local tr = util.TraceHull({
		start = sonr:GetShootPos(),
		endpos = sonr:GetShootPos()+(sonr:GetAimVector()*80),
		filter = sonr,
		mins = Vector(-4,-4,-4),
		maxs = Vector(4,4,4),
		mask = MASK_SHOT_HULL
	})
	local v = tr.Entity

	local _ = SERVER and sonr:LagCompensation(false)

	if SERVER then

		if tr.Hit then
			local vph = IsValid(tr.Entity) and tr.Entity:GetPhysicsObject()

			if IsValid(v) and (IsValid(vph) and vph:IsMotionEnabled()) then
				local force = sonr:GetAimVector()*self.Secondary.Force

				if v:IsPlayer() then
					if not v:GetParent():IsValid() then

						if v:GetMoveType() == MOVETYPE_NOCLIP then v:SetMoveType(MOVETYPE_WALK) end

						v:SetVelocity(force)

					end

					if IsValid(sonr) then
						net.Start("weapon_slap",true)
							net.WriteEntity(sonr)
						net.Send(v)
					end
				else
					vph:AddVelocity(force)
				end
			else
				sonr:SetVelocity(sonr:GetAimVector()*(-self.Secondary.Force/3))
			end

			sonr:EmitSound(self.Sound2,85,math.random(92,96))
		else
			sonr:EmitSound(self.SwingSound,75,math.random(68,74),0.675)
		end


	end


	sonr:ViewPunch(tr.Hit and Angle(1.5,10,0) or Angle(0.6,2.6,0))
end

function SWEP:Reload() end


if CLIENT then
	local epos,eyepos,eyeang,aimvec, eyetoent,cross
	local norm
	local elapsed=9999
	local len=0.1
	local angcount=30

	local function Move( ply, cmd )
	--hook.Add("InputMouseApply","a",function(cmd,x,y,ang)
		local ft=FrameTime()
		elapsed=elapsed+ft
		local f=elapsed/len
		if f>1 then
			hook.Remove( "Move", "weapon_slap")
			return
		end
		f=f<0 and 0 or f>1 and 1 or f

		local ang=ply:EyeAngles()


		local prev = angcount
		angcount = (angcount*(0.99-4*ft))

		local diff=prev-angcount

		ang:RotateAroundAxis(norm,diff)
		ang.r=0

		ply:SetEyeAngles( ang )
	end

	net.Receive("weapon_slap",function()
		local pl = net.ReadEntity()

		if not pl:IsValid() or not pl:IsPlayer() then return end

		epos=pl:EyePos()
		eyepos=LocalPlayer():EyePos()
		aimvec=LocalPlayer():GetAimVector()
		eyetoent=epos-eyepos
		cross=eyetoent:Cross(aimvec)


		norm = cross
		norm:Normalize()

		eyetoent:Normalize()
		aimvec.z=aimvec.z*2

		local ff=eyetoent:Dot(aimvec)
		ff=ff-0.1
		ff=ff<0.0001 and 0 or ff>1 and 1 or ff

		elapsed=0
		len=2
		angcount=45*ff

		hook.Add( "Move", "weapon_slap", Move)
	end)
end

weapons.Register(SWEP,"weapon_slap")
