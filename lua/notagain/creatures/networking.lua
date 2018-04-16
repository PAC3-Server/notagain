AddCSLuaFile()

local MOVED = {}
local MOVE_REF = {}

local PACK_ANGLES = true
local PACK_ANGLES2 = true

--local cell_size = game.GetWorld():GetModelRadius()/4

local function net_write(ent, vec, ang)
	net.WriteEntity(ent)

	if PACK_ANGLES then
		local ang = ang:Forward():Angle()
		ang:Normalize()
		net.WriteInt((ang.p/180)*127, 8)
		net.WriteInt((ang.y/180)*127, 8)
		--net.WriteInt((ang.r/180)*127, 8)
	else
		net.WriteInt(ang.x, 9)
		net.WriteInt(ang.y, 9)
		net.WriteInt(ang.z, 9)
	end

	net.WriteInt(vec.x, 16)
	net.WriteInt(vec.y, 16)
	net.WriteInt(vec.z, 16)

	--[[

	local x,y,z = vec.x, vec.y, vec.z

	local pos = vec + Vector(32767, 32767, 32767)
	local cell = Vector(math.ceil(pos.x/cell_size), math.ceil(pos.y/cell_size), math.ceil(pos.z/cell_size))
	local lpos = Vector(pos.x%cell_size, pos.y%cell_size, pos.z%cell_size)
	local wpos = lpos + (cell * cell_size) - Vector(cell_size, cell_size, cell_size)
	--vec = vec - (cell * cell_size)

	print("===========")
	print("POS :", pos)
	print("CELL:", (cell * cell_size))
	print("LPOS:", lpos)
	print("WPOS:", wpos)
	print("REAL:", vec)

	net.WriteInt(lpos.x, 16)
	net.WriteInt(lpos.y, 16)
	net.WriteInt(lpos.z, 16)

	if ent.last_cell ~= cell then
		net.WriteBit(1)
		net.WriteInt(cell.x, 4)
		net.WriteInt(cell.y, 4)
		net.WriteInt(cell.z, 4)
		ent.last_cell = cell
	end

	]]
end

local function net_read(len)
	local ent = net.ReadEntity()

	if not ent:IsValid() then return end

	local ang
	if PACK_ANGLES2 then
		local p = (net.ReadInt(8)/127)*180
		local y = (net.ReadInt(8)/127)*180
		--local r = (net.ReadInt(8)/127)*180
		ang = Angle(p,y,0)
	else
		local p = net.ReadInt(9)
		local y = net.ReadInt(9)
		local r = net.ReadInt(9)
		ang = Angle(p,y,r)
	end

	local x = net.ReadInt(16)
	local y = net.ReadInt(16)
	local z = net.ReadInt(16)
	local pos = Vector(x,y,z)

	--[[

	if len ~= 96 then
		local x = net.ReadInt(4)
		local y = net.ReadInt(4)
		local z = net.ReadInt(4)
		local cell = Vector(x,y,z) * cell_size
		ent.cell_pos = cell
	end

	if ent.cell_pos then
		pos = pos + ent.cell_pos - Vector(cell_size, cell_size, cell_size)
	end]]

	return ent, pos, ang
end

local function WRITE_COUNT(n)
	net.WriteUInt(n, 16)
end

local function READ_COUNT()
	return net.ReadUInt(16)
end

if SERVER then
	local next_print = 0
	local bytes_written = 0
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

		local available = math.min(table.Count(MOVED), 25)
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

		bytes_written = bytes_written + net.BytesWritten()

		if next_print < RealTime() then
			print("creatures: ", string.NiceSize(bytes_written), " per second")
			bytes_written = 0
			next_print = RealTime() + 1
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
	net.Receive("creature_update", function(len)
		local count = READ_COUNT()
		for i = 1, count do
			local self, pos, ang = net_read(len)
			if not self then return end

			self.net_pos = pos
			self.net_ang = ang
		end
	end)
end
