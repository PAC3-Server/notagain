local last = os.clock()
local last_freeze = os.clock()

hook.Add("Tick", "prevent_spawninside", function()
	local dt = os.clock() - last
	local fps = 1/dt
	if fps < 100 then
		if last_freeze < os.clock()-2 then
			last_freeze = os.clock()
			local count = {}
			local found = 0
			for _, ent in ipairs(ents.GetAll()) do
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() and phys:IsPenetrating() then
					found = found + 1
					phys:EnableMotion(false)
					local owner = ent.CPPIGetOwner and ent:CPPIGetOwner()
					if IsValid(owner) then
						count[owner] = (count[owner] or 0) + 1
					end
				end
			end
			if found > 10 then
				PrintMessage(HUD_PRINTTALK, "Server FPS is under 100, freezing all penetrating physics!" )

				local temp = {}
				for k,v in pairs(count) do table.insert(temp, {ply = k, count = v}) end
				table.sort(temp, function(a, b) return a.count > b.count end)
				PrintTable(temp)
				if temp[1] then
					PrintMessage(HUD_PRINTTALK, temp[1].ply:Nick() .. " owns " .. temp[1].count .. " penetrating props")
				end
			end
		end
	end
	last = os.clock()
end)