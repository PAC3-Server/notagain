if (SERVER) then
	AddCSLuaFile()
	resource.AddWorkshop("727161410")
end

sound.Add({
	name = "Witcher.Teleport",
	channel = CHAN_STREAM,
	volume = 1,
	level = 75,
	pitch = {100, 110},
	sound = "portal/portal_teleport.wav"
})

sound.Add({
	name = "Witcher.PortalOpen",
	channel = CHAN_STREAM,
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "portal/portal_open.wav"
})

sound.Add({
	name = "Witcher.PortalClose",
	channel = CHAN_STREAM,
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "portal/portal_dissipate.wav"
})

local clamp = math.Clamp
local abs = math.abs
local min, max = math.min, math.max

local function HSLToColor(H,S,L)
	local H = clamp(H, 0, 360)
	local S = clamp(S, 0, 1)
	local L = clamp(L, 0, 1)
	local C = (1 - abs(2 * L - 1)) * S
	local X = C * (1 - abs((H / 60) % 2 - 1))
	local m = L - C / 2
	local R1, G1, B1 = 0, 0, 0

	if H < 60 or H >= 360 then
		R1, G1, B1 = C, X, 0
	elseif H < 120 then
		R1, G1, B1 = X, C, 0
	elseif H < 180 then
		R1, G1, B1 = 0, C, X
	elseif H < 240 then
		R1, G1, B1 = 0, X, C
	elseif H < 300 then
		R1, G1, B1 = X, 0, C
	else
		R1, G1, B1 = C, 0, X -- H < 360
	end

	return Color((R1 + m) * 255, (G1 + m) * 255, (B1 + m) * 255)
end

local function ColorToHSL(R,G,B)
	if type(R) == "table" then
		R, G, B = clamp(R.r, 0, 255) / 255, clamp(R.g, 0, 255) / 255, clamp(R.b, 0, 255) / 255
	else
		R, G, B = R / 255, G / 255, B / 255
	end

	local max, min = max(R, G, B), min(R, G, B)
	local del = max - min
	-- Hue
	local H = 0

	if del <= 0 then
		H = 0
	elseif max == R then
		H = 60 * (((G - B) / del) % 6)
	elseif max == G then
		H = 60 * (((B - R) / del + 2) % 6)
	else
		H = 60 * (((R - G) / del + 4) % 6)
	end

	-- Lightness
	local L = (max + min) / 2
	-- Saturation
	local S = 0

	if del ~= 0 then
		S = del / (1 - abs(2 * L - 1))
	end

	return H, S, L
end

local function DistanceToPlane(object_pos, plane_pos, plane_forward)
	local vec = object_pos - plane_pos
	plane_forward:Normalize()

	return plane_forward:Dot(vec)
end

local function VectorAngles(forward, up)
	local angles = Angle(0, 0, 0)
	local left = up:Cross(forward)
	left:Normalize()
	local xydist = math.sqrt(forward.x * forward.x + forward.y * forward.y)

	if (xydist > 0.001) then
		angles.y = math.deg(math.atan2(forward.y, forward.x))
		angles.p = math.deg(math.atan2(-forward.z, xydist))
		angles.r = math.deg(math.atan2(left.z, (left.y * forward.x) - (left.x * forward.y)))
	else
		angles.y = math.deg(math.atan2(-left.x, left.y))
		angles.p = math.deg(math.atan2(-forward.z, xydist))
		angles.r = 0
	end

	return angles
end

properties.Add("portal_persist", {
	MenuLabel = "Save Portal",
	MenuIcon = "icon16/disk.png",
	Order = 1,

	Filter = function(self, ent, player)
		if (not IsValid(ent)) then return false end
		if (not player:IsSuperAdmin()) then return false end
		if (ent:GetClass() ~= "witcher_gateway") then return false end
		if (SERVER and not IsValid(ent:GetOther())) then player:ChatPrint("This portal does not have an exit!") return false end

		return true
	end,

	Action = function(self, ent)

	end,

	SetPersist = function(self, ent, mode)
		self:MsgStart()
		net.WriteEntity(ent)
		net.WriteUInt(mode or 0, 8)
		self:MsgEnd()
	end,

	Receive = function(self, length, player)
		local ent = net.ReadEntity()

		if (not self:Filter(ent, player)) then return end

		local mode = net.ReadUInt(8)

		ent:SetNWInt("SaveMode", mode)
		ent:GetOther():SetNWInt("SaveMode", mode)

		if (mode == 1) then
			ent:Enable()
			ent:GetOther():Enable()
			ent:SetKeyValue("DisallowUse", "1")
			ent:GetOther():SetKeyValue("DisallowUse", "1")
		elseif (mode == 3) then
			ent:SetKeyValue("DisallowUse", "1")
			ent:GetOther():SetKeyValue("DisallowUse", "1")
		else
			ent:SetKeyValue("DisallowUse", "0")
			ent:GetOther():SetKeyValue("DisallowUse", "0")
		end
	end,

	MenuOpen = function(self, option, ent, trace)
		local subMenu = option:AddSubMenu()

		local option = subMenu:AddOption("None", function()
			self:SetPersist(ent, 0)
		end)

		option:SetChecked(ent:GetNWInt("SaveMode", 0) == 0)

		option = subMenu:AddOption("Always On", function()
			self:SetPersist(ent, 1)
		end)

		option:SetChecked(ent:GetNWInt("SaveMode", 0) == 1)

		option = subMenu:AddOption("Toggleable", function()
			self:SetPersist(ent, 2)
		end)

		option:SetChecked(ent:GetNWInt("SaveMode", 0) == 2)

		option = subMenu:AddOption("Toggleable (Admin Only)", function()
			self:SetPersist(ent, 3)
		end)

		option:SetChecked(ent:GetNWInt("SaveMode", 0) == 3)
	end,
})

if (SERVER) then
	numpad.Register("PortalToggle", function(player, portal)
		if (not IsValid(portal)) then return false end
		if (portal:GetEnabled()) then
			portal:Disable()
		else
			portal:Enable()
		end
	end)

	local function SavePortals()
		local buffer = {}

		for k, v in pairs(ents.FindByClass("witcher_gateway")) do
			if IsValid(v) and v:GetNWInt("SaveMode", 0) >= 1 and not v.saved then
				if not IsValid(v:GetOther()) then continue end

				local other = v:GetOther()

				if not IsValid(other) then continue end

				buffer[#buffer + 1] = {
					portals = {
						[1] = {
							origin = v:GetPos(),
							angles = v:GetAngles()
						},

						[2] = {
							origin = other:GetPos(),
							angles = other:GetAngles()
						}
					},

					color = v:GetColor(),
					DisallowUse = v.DisallowUse or false,
					mode = v:GetNWInt("SaveMode", 0),
					enabled = v:GetEnabled()
				}

				v.saved = true
				other.saved = true
			end
		end

		if table.Count(buffer) > 0 then
			local JSON = util.TableToJSON(buffer)
			file.CreateDir("witchergates")
			file.Write("witchergates/" .. game.GetMap() .. ".txt", JSON)
		end

		for k, v in pairs(ents.FindByClass("witcher_gateway")) do
			if v.saved then
				v.saved = nil
			end
		end
	end

	local function LoadPortals()
		if (not file.Exists("witchergates/" .. game.GetMap() .. ".txt", "DATA")) then return end
		local buffer = file.Read("witchergates/" .. game.GetMap() .. ".txt", "DATA")

		if (buffer and buffer:len() > 1) then
			local portals = util.JSONToTable(buffer)

			if (portals) then
				for k, info in pairs(portals) do
					local firstInfo = info.portals[1]
					local secondInfo = info.portals[2]
					local bDisallowUse = info.DisallowUse and "1" or "0"
					local portal1 = ents.Create("witcher_gateway")
					local portal2 = ents.Create("witcher_gateway")

					portal1:SetPos(firstInfo.origin)
					portal1:SetAngles(firstInfo.angles)
					portal1:SetColor(info.color)
					portal1:Spawn()
					portal1:SetNWInt("SaveMode", info.mode)
					portal1:SetKeyValue("DisallowUse", bDisallowUse)
					portal1:PhysicsDestroy()

					portal2:SetPos(secondInfo.origin)
					portal2:SetAngles(secondInfo.angles)
					portal2:SetColor(info.color)
					portal2:Spawn()
					portal2:SetNWInt("SaveMode", info.mode)
					portal2:SetKeyValue("DisallowUse", bDisallowUse)
					portal2:PhysicsDestroy()

					portal1:SetOther(portal2)
					portal2:SetOther(portal1)

					if (info.mode == 1 or info.enabled) then
						portal1:Enable()
						portal2:Enable()
					end
				end
			end
		end
	end

	timer.Create("witcher_SavePortals", 180, 0, function()
		local win, msg = pcall(SavePortals)

		if (not win) then
			ErrorNoHalt("[WITCHERGATES] Something went wrong when saving portals! \n" .. msg)
		end
	end)

	hook.Add("ShutDown", "witcher_SavePortals", function()
		local win, msg = pcall(SavePortals)

		if (not win) then
			ErrorNoHalt("[WITCHERGATES] Something went wrong when saving portals! \n" .. msg)
		end
	end)

	local SpawnPortals = function()
		timer.Simple(5, function()
			local win, msg = pcall(LoadPortals)

			if (not win) then
				ErrorNoHalt("[WITCHERGATES] Something went wrong when loading portals! \n" .. msg)
			end
		end)
	end

	--hook.Add("InitPostEntity","witcher_LoadPortals",SpawnPortals)
	--hook.Add("PostCleanupMap","witcher_LoadPortals",SpawnPortals)

	hook.Add("ShouldCollide", "witcher_RPGFix", function(a, b)
		local aClass = a:GetClass()
		local bClass = b:GetClass()
		if (aClass == "rpg_missile" and (bClass == "witcher_door" or bClass == "witcher_gateway")) then
			return false
		elseif (bClass == "rpg_missile" and (aClass == "witcher_door" or aClass == "witcher_gateway")) then
			return false
		end
	end)
end

if CLIENT then
	local EFFECT = {}

	function EFFECT:Init(fx)
		self.emitter = ParticleEmitter(fx:GetOrigin())
		self.ent = fx:GetEntity()
	end

	function EFFECT:GetEntity()
		return IsValid(self.ent) and self.ent or false
	end

	function EFFECT:Think()
		if (self:GetEntity()) then
			if (self:GetEntity():GetEnabled()) then
				local curTime = CurTime()

				if ((self.nextParticle or 0) < curTime) then
					local ent = self:GetEntity()
					self.nextParticle = curTime + 0.1

					local randPos = ent:GetPos() + (ent:GetUp() * math.random(7, 70)) + (ent:GetRight() * math.random(-47, 47)) + (ent:GetForward() * math.random(-24, 24))
					local normal = self:GetEntity():GetUp() * -1
					local particle = self.emitter:Add("particle/particle_glow_05_addnofog", randPos)
					local color = (self:GetEntity():GetRealColor() / 2) * 255
					particle:SetDieTime(1.2)
					particle:SetGravity(normal * 100)
					particle:SetVelocity(normal * 50)
					particle:SetColor(color.x, color.y, color.z)
					particle:SetAirResistance(100)
					particle:SetStartAlpha(255)
					particle:SetRoll(math.random(0, 360))
					particle:SetStartSize(math.random(1, 2))
					particle:SetEndSize(0)
					particle:SetVelocityScale(true)
					particle:SetLighting(false)
				end
			end

			return true
		else
			self.emitter:Finish()
			return false
		end
	end

	function EFFECT:Render()
	end

	effects.Register(EFFECT,"portal_inhale")
end

local ENT = {}
DEFINE_BASECLASS("base_entity")

ENT.Type		= "anim"
ENT.PrintName		= "Witcher Gateway"
ENT.Category		= "Portals"
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.Model			= Model("models/hunter/blocks/cube1x2x025.mdl")
ENT.RenderGroup 	= RENDERGROUP_BOTH

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enabled")
	self:NetworkVar("Vector", 0, "TempColor")
	self:NetworkVar("Vector", 1, "RealColor")
	self:NetworkVar("Entity", 0, "Other")
	self:NetworkVar("Float", 0, "AnimStart")

	if (SERVER) then
		self:NetworkVarNotify("TempColor", function(ent, name, old, new)
			local color = HSVToColor(new.x, new.y, new.z)
			local r = (color.r * 2) / 255
			local g = (color.g * 2) / 255
			local b = (color.b * 2) / 255

			self:SetRealColor(Vector(r, g, b))
		end)
	end
end

local function InFront(posA, posB, normal)
	local Vec1 = (posB - posA):GetNormalized()

	return (normal:Dot(Vec1) >= 0)
end

if SERVER then

	function ENT:SpawnFunction(player, trace, class)
		if (not trace.Hit) then return end
		local entity = ents.Create(class)

		entity:SetPos(trace.HitPos + trace.HitNormal)
		entity:Spawn()
		entity:SetPos(entity:GetPos() + Vector(0, 0, entity:OBBMaxs().y))
		entity:SetAngles(Angle(0, player:EyeAngles().y + 90, -90))

		return entity
	end

	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMaterial("vgui/black")
		self:DrawShadow(false)
		self:SetTrigger(true)
		self:SetEnabled(false)
		self:SetUseType(SIMPLE_USE)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		self:SetCustomCollisionCheck(true)

		local phys = self:GetPhysicsObject()

		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end
	end

	function ENT:Enable()
		if (self:GetEnabled()) then return end
		self:SetEnabled(true)
		self:EmitSound("Witcher.PortalOpen")

		if (not self.ambient) then
			local filter = RecipientFilter()
			filter:AddAllPlayers()

			self.ambient = CreateSound(self, "portal/portal_ambient.wav", filter)
		end

		self.ambient:Play()

		self:SetAnimStart(CurTime())
	end

	function ENT:Disable()
		if (not self:GetEnabled()) then return end
		self:SetEnabled(false)
		self:EmitSound("Witcher.PortalClose")

		if (self.ambient) then
			self.ambient:Stop()
		end

		self:SetAnimStart(CurTime())
	end

	function ENT:SetColour(color)
		local h, s, v = ColorToHSV(color)

		self:SetTempColor(Vector(h, s, v))

		if (IsValid(self:GetOther())) then
			self:GetOther():SetTempColor(Vector(h, s, v))
		end
	end

	function ENT:OnRemove()
		if (self.ambient) then
			self.ambient:Stop()
		end
	end

	function ENT:AcceptInput(input, activator, caller, data)
		local other = self:GetOther()
		if (input == "TurnOn") then
			self:Enable()

			if (IsValid(other)) then
				other:Enable()
			end
		elseif (input == "TurnOff") then
			self:Disable()

			if (IsValid(other)) then
				other:Disable()
			end
		elseif (input == "Toggle") then
			if (self:GetEnabled()) then
				self:Disable()

				if (IsValid(other)) then
					other:Disable()
				end
			else
				self:Enable()

				if (IsValid(other)) then
					other:Enable()
				end
			end
		end
	end

	function ENT:Think()
		self:SetColor(ColorAlpha(self:GetColor(), 255))

		if (IsValid(self)) then
			local color = self:GetTempColor()
			color = HSVToColor(color.x, color.y, color.z)

			local selfCol = self:GetColor()

			if (color.r ~= selfCol.r or color.g ~= selfCol.g or color.b ~= selfCol.b) then
				local newCol = ColorAlpha(selfCol, 0)
				self:SetColour(newCol)

				if (IsValid(self:GetOther())) then
					self:GetOther():SetColor(newCol)
				end
			end
		end

		self:NextThink(CurTime() + 1)
		return true
	end

	function ENT:OnRemove()
		if (self.ambient) then
			self.ambient:Stop()
		end
	end

	function ENT:AcceptInput(input, activator, caller, data)
		local other = self:GetOther()
		if (input == "TurnOn") then
			self:Enable()

			if (IsValid(other)) then
				other:Enable()
			end
		elseif (input == "TurnOff") then
			self:Disable()

			if (IsValid(other)) then
				other:Disable()
			end
		elseif (input == "Toggle") then
			if (self:GetEnabled()) then
				self:Disable()

				if (IsValid(other)) then
					other:Disable()
				end
			else
				self:Enable()

				if (IsValid(other)) then
					other:Enable()
				end
			end
		end
	end

	function ENT:KeyValue(key, value)
		if (key == "color") then
			local args = string.Explode(" ", value, false)
			self.Portal:SetColour(Color(args[1], args[2], args[3]))
		elseif (key == "DisallowUse") then
			self.DisallowUse = tobool(value)
		end
	end

	function ENT:Use(player)
		if (not IsValid(self:GetOther()) and player:KeyDown(IN_WALK) and player:IsAdmin()) then
			if (not IsValid(player.Portal)) then
				player.Portal = self
				player:ChatPrint("First portal selected!  Press ALT + E on another portal to link! ")
			elseif (player.Portal ~= self) then
				player.Portal:SetOther(self)
				self:SetOther(player.Portal)
				player:ChatPrint("Successfully linked the two portals!")

				player.Portal = nil
			end

			return
		end

		if ((self.DisallowUse and not player:IsAdmin()) or self:GetNWInt("SaveMode", 0) == 1) then return end

		if (CurTime() > (self.nextUse or 0)) then
			self.nextUse = CurTime() + 1

			if (self:GetEnabled()) then
				self:Disable()
			else
				self:Enable()
			end

			if (IsValid(self:GetOther())) then
				local other = self:GetOther()

				if (self:GetEnabled()) then
					other:Enable()
				else
					other:Disable()
				end
			end
		end
	end

	function ENT:TransformOffset(v, a1, a2)
		return (v:Dot(a1:Right()) * a2:Right() + v:Dot(a1:Up()) * (-a2:Up()) - v:Dot(a1:Forward()) * a2:Forward())
	end

	function ENT:GetFloorOffset(pos1, height)
		local offset = Vector(0, 0, 0)
		local pos = Vector(0, 0, 0)
		pos:Set(pos1) --stupid pointers...
		pos = self:GetOther():WorldToLocal(pos)
		pos.y = pos.y + height
		pos.z = pos.z + 10

		for i = 0, 30 do
			local openspace = util.IsInWorld(self:GetOther():LocalToWorld(pos - Vector(0, i, 0)))
			--debugoverlay.Box(self:GetOther():LocalToWorld(pos - Vector(0, i, 0)), Vector(-2, -2, 0), Vector(2, 2, 2), 5)

			if (openspace) then
				offset.z = i
				break
			end
		end

		return offset
	end

	function ENT:GetOffsets(portal, ent)
		local pos

		if (ent:IsPlayer()) then
			pos = ent:EyePos()
		else
			pos = ent:GetPos()
		end

		local offset = self:WorldToLocal(pos)
		offset.x = -offset.x
		offset.y = offset.y
		local output = portal:LocalToWorld(offset)

		if (ent:IsPlayer() and SERVER) then
			return output + self:GetFloorOffset(output, (ent:EyePos() - ent:GetPos()).z)
		else
			return output
		end
	end

	function ENT:GetPortalAngleOffsets(portal, ent)
		local angles = ent:GetAngles()
		local normal = self:GetUp()
		local forward = -angles:Forward()
		local up = angles:Up()
		-- reflect forward
		local dot = forward:Dot(normal)
		forward = forward + (-2 * dot) * normal
		-- reflect up
		dot = up:Dot(normal)
		up = up + (-2 * dot) * normal
		-- convert to angles
		angles = VectorAngles(forward, up)
		local LocalAngles = self:WorldToLocalAngles(angles)
		-- repair
		LocalAngles.x = -LocalAngles.x
		LocalAngles.y = -LocalAngles.y

		return portal:LocalToWorldAngles(LocalAngles)
	end

	function ENT:StartTouch(ent)

	end

	function ENT:Touch(ent)
		if (IsValid(self:GetOther()) and self:GetEnabled()) then
			if (InFront(ent:GetPos(), self:GetPos() - self:GetUp() * 2.8, self:GetUp())) then return end
			if (ent:IsPlayer()) then
				if (CurTime() < (ent.lastPort or 0) + 0.4) then return end

				local color = self:GetRealColor()
				local vel = ent:GetVelocity()
				local other = self:GetOther()

				local normVel = vel:GetNormalized()
				local dir = self:GetUp():Dot(normVel)

				-- If they aren't approaching the portal or they aren't moving fast enough, don't teleport.
				if (dir > 0 or (self:GetUp().z <= 0.5 and vel:Length() < 1)) then return end

				local newPos = self:GetOffsets(other, ent)
				local newVel = self:TransformOffset(vel, self:GetAngles(), other:GetAngles())
				local newAngles = self:GetPortalAngleOffsets(other, ent)
				newAngles.z = 0

				-- Correct for if player is crouched
				newPos.z = newPos.z - (ent:EyePos() - ent:GetPos()).z

				-- If the portal is slanted, account for it
				if (other:GetAngles().z > -60) then
					newPos = newPos + Angle(0, other:GetAngles().y + 90, 0):Forward() * 50
				end

				local offset = Vector()

				-- Correcting for eye height usually ends up getting us stuck in slanted portals. Find open space for us
				for i = 0, 20 do
					local openspace = util.IsInWorld(newPos + Vector(0, 0, i))

					if (openspace) then
						offset.z = i
						break
					end
				end

				newPos = newPos + offset + other:GetUp() * 3

				local planeDist = DistanceToPlane(newPos, other:GetPos(), other:GetUp())
				if (planeDist <= 16) then
					newPos = newPos + other:GetUp() * planeDist
				end

				-- This trace allows 100% less getting stuck in things. It traces from the portal to the desired position using the player's hull.
				-- If it hits, it'll set you somewhere safe-ish most of the time.
				local up = other:GetUp()
				local nearestPoint = other:NearestPoint(newPos)
				local nearNormal = (newPos - nearestPoint):GetNormalized()
				local foundSpot = false
				local trace

				for i = 0, 30 do
					trace = util.TraceEntity({
						start = nearestPoint + up * (up.z > 0 and up.z * 30 or 16) + nearNormal * 5 + other:GetRight() * i,
						endpos = newPos + up + other:GetRight() * i,
						filter = other
					}, ent)

					if (not trace.AllSolid) then
						foundSpot = true
						break
					end
				end

				if (not foundSpot) then return end

				ent:SetPos(trace.HitPos + up * 2)
				ent:SetLocalVelocity(newVel)
				ent:SetEyeAngles(newAngles)
				ent.lastPort = CurTime()

				sound.Play("portal/portal_teleport.wav", other:WorldSpaceCenter())
				sound.Play("portal/portal_teleport.wav", self:WorldSpaceCenter())

				ent:ScreenFade(SCREENFADE.IN, color_black, 0.2, 0.03)
			else
				if (CurTime() < (ent.lastPort or 0) + 0.4) then return end

				if (ent:GetClass():find("door") or ent:GetClass():find("func_")) then return end
				if (not IsValid(ent:GetPhysicsObject())) then return end

				if (IsValid(self:GetParent())) then
					for k, v in pairs(constraint.GetAllConstrainedEntities(self:GetParent())) do
						if (v == ent) then
							return
						end
					end
				end

				local vel = ent:GetVelocity()
				local other = self:GetOther()

				local newPos = self:GetOffsets(other, ent)
				local newVel = self:TransformOffset(vel, self:GetAngles(), other:GetAngles())
				local newAngles = self:GetPortalAngleOffsets(other, ent)

				ent:SetPos(newPos)

				if (IsValid(ent:GetPhysicsObject())) then
					ent:GetPhysicsObject():SetVelocity(newVel)
				end

				ent:SetAngles(newAngles)
				ent.lastPort = CurTime()

				sound.Play("portal/portal_teleport.wav", self:WorldSpaceCenter())
				sound.Play("portal/portal_teleport.wav", other:WorldSpaceCenter())
			end
		end
	end

end

if CLIENT then

	local function DefineClipBuffer(ref)
		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.SetStencilWriteMask(254)
		render.SetStencilTestMask(254)
		render.SetStencilReferenceValue(ref or 43)
	end

	local function DrawToBuffer()
		render.SetStencilCompareFunction(STENCIL_EQUAL)
	end

	local function EndClipBuffer()
		render.SetStencilEnable(false)
		render.ClearStencil()
	end

	function ENT:Initialize()
		self.PixVis = util.GetPixelVisibleHandle()
		local matrix = Matrix()
		matrix:Scale(Vector(1, 1, 0.01))
		local offset = 1.8

		local effectData = EffectData()
		effectData:SetEntity(self)
		effectData:SetOrigin(self:GetPos())
		util.Effect("portal_inhale", effectData)

		self:SetSolid(SOLID_VPHYSICS)

		self.hole = ClientsideModel("models/hunter/plates/plate1x2.mdl", RENDERGROUP_BOTH)
		self.hole:SetPos(self:GetPos() - self:GetUp() * (1 + offset))
		self.hole:SetAngles(self:GetAngles())
		self.hole:SetParent(self)
		self.hole:SetNoDraw(true)
		self.hole:EnableMatrix("RenderMultiply", matrix)

		self.top = ClientsideModel("models/hunter/plates/plate075x1.mdl", RENDERGROUP_BOTH)
		self.top:SetMaterial("portal/border")
		self.top:SetPos(self:GetPos() + self:GetRight() * 44.5 - self:GetUp() * (12.5 + offset))
		self.top:SetParent(self)
		self.top:SetLocalAngles(Angle(-75, -90, 0))
		self.top:SetNoDraw(true)
		self.top:EnableMatrix("RenderMultiply", matrix)

		self.bottom = ClientsideModel("models/hunter/plates/plate075x1.mdl", RENDERGROUP_BOTH)
		self.bottom:SetMaterial("portal/border")
		self.bottom:SetPos(self:GetPos() - self:GetRight() * 44.5 - self:GetUp() * (12.5 + offset))
		self.bottom:SetParent(self)
		self.bottom:SetLocalAngles(Angle(-75, 90, 0))
		self.bottom:SetNoDraw(true)
		self.bottom:EnableMatrix("RenderMultiply", matrix)

		self.left = ClientsideModel("models/hunter/plates/plate075x2.mdl", RENDERGROUP_BOTH)
		self.left:SetMaterial("portal/border")
		self.left:SetPos(self:GetPos() + self:GetForward() * 20.8 - self:GetUp() * (12.5 + offset))
		self.left:SetParent(self)
		self.left:SetLocalAngles(Angle(-75, 0, 0))
		self.left:SetNoDraw(true)
		self.left:EnableMatrix("RenderMultiply", matrix)

		self.right = ClientsideModel("models/hunter/plates/plate075x2.mdl", RENDERGROUP_BOTH)
		self.right:SetMaterial("portal/border")
		self.right:SetPos(self:GetPos() - self:GetForward() * 20.8 - self:GetUp() * (12.5 + offset))
		self.right:SetParent(self)
		self.right:SetLocalAngles(Angle(-105, 0, 0))
		self.right:SetNoDraw(true)
		self.right:EnableMatrix("RenderMultiply", matrix)

		self.back = ClientsideModel("models/hunter/plates/plate3x3.mdl", RENDERGROUP_BOTH)
		self.back:SetMaterial("vgui/black")
		self.back:SetPos(self:GetPos() - self:GetUp() * 42)
		self.back:SetParent(self)
		self.back:SetLocalAngles(Angle(0, 0, 0))
		self.back:SetNoDraw(true)

		self.frame = ClientsideModel("models/props_phx/construct/metal_wire1x2b.mdl", RENDERGROUP_BOTH)
		self.frame:SetPos(self:GetPos())
		self.frame:SetParent(self)
		self.frame:SetLocalPos(Vector(0, -27.3, -5))
		self.frame:SetLocalAngles(Angle(0, 0, 0))
		self.frame:SetMaterial("models/props_debris/plasterwall009d")

		local matrix = Matrix()
		matrix:Scale(Vector(1.325, 1.142, 1))

		self.frame:EnableMatrix("RenderMultiply", matrix)

		self.h, self.s, self.l = 0, 1, 1
	end

	function ENT:OnRemove()
		self.top:Remove()
		self.bottom:Remove()
		self.left:Remove()
		self.right:Remove()
		self.hole:Remove()
		self.back:Remove()
		self.frame:Remove()
	end

	function ENT:Draw()

	end

	function ENT:Think()
		if self.BROKEN then return end

		if (self:GetEnabled()) then
			local light = DynamicLight(self:EntIndex())

			if (light) then
				local vecCol = self:GetRealColor()
				light.pos = self:WorldSpaceCenter() + self:GetUp() * 15
				light.Size = 300
				light.style = 5
				light.Decay = 600
				light.brightness = 1
				light.r = (vecCol.x / 2) * 255
				light.g = (vecCol.y / 2) * 255
				light.b = (vecCol.z / 2) * 255
				light.DieTime = CurTime() + 0.1
			end
		end
	end

	local mat = CreateMaterial("witcherGlow", "UnlitGeneric", {
		["$basetexture"] = "sprites/light_glow02",
		["$basetexturetransform"] = "center 0 0 scale 1 1 rotate 0 translate 0 0",
		["$additive"] = 1,
		["$translucent"] = 1,
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$ignorez"] = 1
	})

	function ENT:DrawTranslucent()
		if (InFront(LocalPlayer():EyePos(), self:GetPos() - self:GetUp() * 1.8, self:GetUp())) then return end

		local bEnabled = self:GetEnabled()
		local color = self:GetRealColor()
		local elapsed = CurTime() - self:GetAnimStart()
		local frac = math.Clamp(elapsed / (bEnabled and 0.5 or 0.1), 0, 1)

		if (frac <= 1) then
			self.h, self.s, self.l = ColorToHSL((color.x / 2) * 255, (color.y / 2) * 255, (color.z / 2) * 255)
			self.l = Lerp(frac, self.l or 1, bEnabled and 0 or 1)
			self.col = HSLToColor(self.h, self.s, self.l)
		end

		if (bEnabled) then
			self.lerpr = Lerp(frac, self.lerpr or 255, self.col.r)
			self.lerpg = Lerp(frac, self.lerpg or 255, self.col.g)
			self.lerpb = Lerp(frac, self.lerpb or 255, self.col.b)
		else
			self.lerpr = Lerp(frac, self.lerpr or 0, self.col.r)
			self.lerpg = Lerp(frac, self.lerpg or 0, self.col.g)
			self.lerpb = Lerp(frac, self.lerpb or 0, self.col.b)
		end

		self.top:SetNoDraw(true)

		DefineClipBuffer()

		if ((bEnabled and frac > 0) or (not bEnabled and frac < 1)) then
			self.hole:DrawModel()
		end

		DrawToBuffer()

		render.ClearBuffersObeyStencil(self.lerpr, self.lerpg, self.lerpb, 0, bEnabled)

		if (bEnabled and frac >= 0.1) then
			if (frac >= 1) then
				self.back:DrawModel()
			end
			render.SetColorModulation(color.x * 3, color.y * 3, color.z * 3)
			self.top:DrawModel()
			self.bottom:DrawModel()
			self.left:DrawModel()
			self.right:DrawModel()
			render.SetColorModulation(1, 1, 1)
		end

		EndClipBuffer()

		if (not bEnabled) then return end

		local norm = self:GetUp()
		local viewNorm = (self:GetPos() - EyePos()):GetNormalized()
		local dot = viewNorm:Dot(norm * -1)

		if (dot >= 0) then
			render.SetColorModulation(1, 1, 1)
			local visible = util.PixelVisible(self:GetPos() + self:GetUp() * 3, 20, self.PixVis)

			if (not visible) then return end

			local alpha = math.Clamp((EyePos():Distance(self:GetPos()) / 8) * dot * visible, 0, 80)
			local newColor = Color((color.x / 2) * 255, (color.y / 2) * 255, (color.z / 2) * 255, alpha)

			render.SetMaterial(mat)
			render.DrawSprite(self:GetPos() + self:GetUp() * 2, 600, 600, newColor, visible * dot)
		end
	end
end

scripted_ents.Register(ENT,"witcher_gateway")
