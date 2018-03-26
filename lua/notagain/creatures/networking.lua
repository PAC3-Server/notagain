AddCSLuaFile()

local MOVED = {}
local MOVE_REF = {}

local function net_write(ent, vec, ang)
	net.WriteEntity(ent)

	net.WriteInt(vec.x, 16)
	net.WriteInt(vec.y, 16)
	net.WriteInt(vec.z, 16)

	net.WriteInt(ang.x, 9)
	net.WriteInt(ang.y, 9)
	net.WriteInt(ang.z, 9)
end

local function net_read()
	local ent = net.ReadEntity()

	if not ent:IsValid() then return end

	local x = net.ReadInt(16)
	local y = net.ReadInt(16)
	local z = net.ReadInt(16)

	local p = net.ReadInt(9)
	local yaw = net.ReadInt(9)
	local r = net.ReadInt(9)

	return ent, Vector(x,y,z), Angle(p,yaw,r)
end

local function WRITE_COUNT(n)
	net.WriteUInt(n, 16)
end

local function READ_COUNT()
	return net.ReadUInt(16)
end

if SERVER then
	hook.Add("Think", "creatures_network", function()
		for _, self in ipairs(creatures.GetAll()) do
			if self.AlternateNetworking then
				--[[if not self.creature_untransmit then
					self.creature_untransmit_timer = self.creature_untransmit_timer or CurTime() + 1
					if self.creature_untransmit_timer < CurTime() then
						for i,v in ipairs(player.GetAll()) do
							self:SetPreventTransmit(v, true)
						end
						self.creature_untransmit = true
					end
				end]]

				if not self.notransmit then
					function self:UpdateTransmitState()
						return TRANSMIT_NEVER
					end

					self.notransmit = true
					self.checktransmit = CurTime() + 1
				end

				if self.checktransmit < CurTime() then
					self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
				end

				local updatedPos = false

				local curPos = self:GetPos() --curPos.x = math.Round(curPos.x) curPos.y = math.Round(curPos.y)
				if self.LastStoredPos ~= curPos then
					self.LastStoredPos = curPos
					updatedPos = true
				end

				local curAng = self:GetAngles() --curAng.x = math.Round(curAng.x) curAng.y = math.Round(curAng.y) curAng.z = math.Round(curAng.z)
				if self.LastStoredAng ~= curAng then
					self.LastStoredAng = curAng
					updatedPos = true
				end


				-- when the seagull is standing still emit the data once
				local important = false

				if self.VelocityLength and self.VelocityLength < 5 then
					if not self.creature_sent_important then
						updatedPos = true
						self.LastStoredPos = curPos
						self.LastStoredAng = curAng
						important = true
						self.creature_sent_important = true
					end
				else
					self.creature_sent_important = false
				end

				if updatedPos == true then
					local tableId = #MOVED + 1
					local data = MOVE_REF[self]
					if data ~= nil then
						data[2] = self:GetPos()
						data[3] = self:GetAngles()
						--print("Updating move record")
					else
						-- Insert new queue record, keep order.
						table.insert(MOVED, {self, self:GetPos(), self:GetAngles(), tableId} )
						MOVE_REF[self] = MOVED[tableId]
						--print("Added move record")
					end
				else
					--print("No update")
				end
			else
				if self.notransmit then
					self.UpdateTransmitState = nil
					self.notransmit = nil
				end
			end
		end

		local available = math.min(table.Count(MOVED), 10)
		if available == 0 then
			return
		end
		if important then
			net.Start("creature_update", false)
		else
			net.Start("creature_update", true)
		end
		WRITE_COUNT(available)
		local centerPos = Vector(0, 0, 0)
		for i = 1, available do
			local data = MOVED[1]

			net_write(data[1], data[2], data[3])

			centerPos = centerPos + data[2]
			MOVE_REF[data[1]] = nil

			table.remove(MOVED, 1)
		end

		if important then
			net.Broadcast()
		else
			net.SendPVS(centerPos / available)
		end
	end)

	util.AddNetworkString("creature_update")
end

if CLIENT then
	net.Receive("creature_update", function()
		local count = READ_COUNT()
		for i = 1, count do
			local self, pos, ang = net_read()
			if not self then return end

			self.net_pos = pos
			self.net_ang = ang
		end
	end)
end
