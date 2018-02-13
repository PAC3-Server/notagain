do
	local META = FindMetaTable("Player")

	function META:IsAFK()
		return self:GetNWFloat("afk") > 0
	end

	function META:GetAFKTime()
		return CurTime() - self:GetNWFloat("afk")
	end
end

if CLIENT then
	local cl_afk_time = CreateConVar("cl_afk_time", "90", FCVAR_USERINFO)

	local last_keys = {}
	local last_mouse_x = 0
	local last_mouse_y = 0
	local last_focus = nil
	local last_moved = 0
	local is_afk = false

	timer.Create("afk", 0.25, 0, function()
		local time = RealTime()

		for i = KEY_FIRST, KEY_LAST do
			local is_down = input.IsKeyDown(i)
			if last_keys[i] ~= is_down then
				last_moved = time
				last_keys[i] = is_down
			end
		end

		do
			local x,y = gui.MousePos()

			if x ~= last_mouse_x then
				last_moved = time
			end

			last_mouse_x = x

			if y ~= last_mouse_y then
				last_moved = time
			end

			last_mouse_y = y
		end

		do
			local focus = system.HasFocus()

			if focus ~= last_focus then
				last_moved = time
			end

			last_focus = focus
		end

		if time - last_moved > cl_afk_time:GetFloat() then
			if not is_afk then
				net.Start("on_afk") net.WriteFloat(CurTime()) net.SendToServer()
				is_afk = true
			end
		else
			if is_afk then
				net.Start("on_afk") net.WriteFloat(-1) net.SendToServer()
				is_afk = false
			end
		end
	end)
end

if SERVER then
	util.AddNetworkString("on_afk")
	util.AddNetworkString("cl_on_afk")

	net.Receive("on_afk", function(_, ply)
		local time = net.ReadFloat()
		local bool = (time > 0)

		hook.Run("OnPlayerAFK", ply, bool, ply:GetAFKTime())

		net.Start("cl_on_afk")
		net.WriteEntity(ply)
		net.WriteBool(bool)
		net.WriteFloat(ply:GetAFKTime())
		net.Broadcast()

		ply:SetNWFloat("afk", time)
	end)
end

if CLIENT then
	net.Receive("cl_on_afk", function()
		local ply = net.ReadEntity()
		local bool = net.ReadBool()
		local time = net.ReadFloat()

		hook.Run("OnPlayerAFK", ply, bool, time)
	end)
end
