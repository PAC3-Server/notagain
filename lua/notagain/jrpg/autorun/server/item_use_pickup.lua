hook.Add("KeyPress", "item_use_pickup", function(ply, key)
	if not ply.item_use_pickup then return end
	if key == IN_USE then
		local found = {}
		for ent in pairs(ply.item_use_pickup) do
			if ent:IsValid() and not ent:GetOwner():IsValid() and ent:GetPos():Distance(ply:GetPos()) < 100 then
				table.insert(found, ent)
			else
				ply.item_use_pickup[ent] = nil
			end
		end

		local wep
		local tr = ply:GetEyeTrace()

		for _, ent in ipairs(found) do
			if tr.Entity == ent then
				wep = ent
				break
			end
		end

		if not wep then
			if tr.HitWorld and tr.HitPos:Distance(ply:GetShootPos()) < 100 then
				local look_pos = tr.HitPos
				table.sort(found, function(a, b) return a:NearestPoint(look_pos):Distance(look_pos) < b:NearestPoint(look_pos):Distance(look_pos) end)
				wep = found[1]
			end
		end

		if not wep then
			local look_pos = ply:GetShootPos()
			table.sort(found, function(a, b) return a:NearestPoint(look_pos):Distance(look_pos) < b:NearestPoint(look_pos):Distance(look_pos) end)

			for _, ent in ipairs(found) do
				local dir = ent:NearestPoint(ply:GetShootPos()) - ply:GetShootPos()
				local dot = ply:GetAimVector():Dot(dir) / dir:Length()

				if dot > 0 then
					wep = ent
					break
				end
			end
		end

		if wep then
			wep.item_use_pickup_allow = true
			timer.Simple(0, function()
				if wep:IsValid() then
					wep.item_use_pickup_allow = nil
				end
			end)
		end
	end
end)

local function disallow(ply, wep)
	if wep:GetPos() == ply:GetPos() then
		return
	end

	if wep.item_use_pickup_allow then
		local active = ply:GetActiveWeapon()
		local old_class = active:IsValid() and active:GetClass()

		if wep.wepstats or (old_class == wep:GetClass() and active.wepstats) then
			local pos = wep:GetPos()
			local ang = wep:GetAngles()

			for _, ent in pairs(ply:GetWeapons()) do
				if ent:GetClass() == wep:GetClass() then
					ply:DropWeapon(ent)
					ent:SetPos(pos)
					ent:SetAngles(ang)
					ent:GetPhysicsObject():SetVelocity(Vector(0,0,0))
					break
				end
			end
			wep.item_use_pickup_allow = nil

			if old_class then
				timer.Simple(0, function()
					if ply:IsValid() then
						ply:SelectWeapon(old_class)
					end
				end)
			end
		end

		return
	end

	ply.item_use_pickup = ply.item_use_pickup or {}
	ply.item_use_pickup[wep] = wep

	return false
end

hook.Add("PlayerCanPickupItem", "item_use_pickup", disallow)
hook.Add("PlayerCanPickupWeapon", "item_use_pickup", disallow)