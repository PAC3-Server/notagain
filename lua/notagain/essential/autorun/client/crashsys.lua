if game.SinglePlayer() then return end

local API_RESPONSE = 0 -- Idle, not waiting for a response.

local api_retry = 5
local api_retry_delay = 12

local lastPong = 0
local pong = 0

local crash_status
local crash_time

local delay = 0
local times = 1

local function CrashTick(is_crashing, length, api_response)
	if is_crashing then
		crash_status = true
		crash_time = math.Round(length)

		if delay < RealTime() and times <= api_retry then
			API_RESPONSE = 1 -- Waiting for Response.

			http.Fetch(string.format("https://api.steampowered.com/ISteamApps/GetServersAtAddress/v1/?addr=%s&format=json", tostring( game.GetIPAddress() )),
				function( body, len, headers, code )
					local data = util.JSONToTable(body)
					if data and next(data) then
						data = data["response"] and data["response"]["servers"]
						if data and next(data) then
							if data[1]["addr"] then
								API_RESPONSE = 4 -- Server Is Up Again
							end
						else
							API_RESPONSE = 2 -- Server Not Responding.
						end
					else
						API_RESPONSE = 2 -- Server Not Responding.
					end
				end,
				function( error )
					API_RESPONSE = 3 -- No Internet Connection or API Down.
				end
			)

			delay = RealTime() + api_retry_delay
			times = times + 1
		end
	else
		times = 1
		crash_status = false

		crash_time = 0
		API_RESPONSE = 0 -- Idle, not waiting for a response.
	end

	hook.Run("CrashTick", is_crashing, length, api_response)
end

hook.Add("Tick", "crashsys", function()
	if not lastPong then return end
	local timeout = RealTime() - lastPong

	if timeout > 1.3 then
		CrashTick(true, timeout, API_RESPONSE)
	else
		CrashTick(false)
	end
end)


net.Receive("crashsys", function()
	if pong < 5 then
		pong = pong + 1
	else
		lastPong = RealTime()
	end
end)

local function pong()
	if lastPong then
		lastPong = RealTime()
	end
end

hook.Add("Move", "crashsys", pong)
hook.Add("VehicleMove", "crashsys", pong)

do
	local META = FindMetaTable("Player")

	function META:IsTimingOut()
		if self == LocalPlayer() then
			return crash_status
		end
	end

	function META:GetTimeoutSeconds()
		if self == LocalPlayer() then
			return crash_time
		else
			return 0
		end
	end
end

do -- gui
	local DermaPanel
	local timeout_cvar = GetConVar("cl_timeout")

	local function ShowMenu()
		if IsValid(DermaPanel) then
			DermaPanel:Remove()
		end

		DermaPanel = vgui.Create( "DFrame" )
		DermaPanel:SetSize( ScrW()/4, ScrH()/4 )
		DermaPanel:Center()
		DermaPanel:SetTitle( "Uh Oh!" )
		DermaPanel:SetDraggable( true )
		DermaPanel:MakePopup()

		DermaPanel.OnClose = function()
			hook.Remove("CrashTick", "crashsys")
			print("?!")
		end

		local prog = vgui.Create( "DProgress", DermaPanel )
		prog:SetFraction( 0 )
		prog:Dock(TOP)

		DermaPanel.prog = prog

		local logs = vgui.Create( "DListView", DermaPanel )
		logs:SetMultiSelect( false )
		logs:AddColumn( "Status" )
		logs:Dock(FILL)

		logs:AddLine( "YOU HAVE TIMEDOUT! - Reconnecting in "..timeout_cvar:GetInt().." seconds!" )

		DermaPanel.logs = logs

		local bottom = vgui.Create("DPanel", DermaPanel)
		bottom:Dock(BOTTOM)

		local buttons = {
			{
				text = "RECONNECT",
				call = function() RunConsoleCommand( "retry" ) end
			},
			{
				text = "Copy Discord Link",
				call = function()
					SetClipboardText("https://discord.gg/utpR3gJ")
					logs:AddLine( "https://discord.gg/utpR3gJ copied to clipboard!" )
				end
			},
			{
				text = "DISCONNECT",
				call = function() RunConsoleCommand( "disconnect" ) end
			},
		}

		for i, v in ipairs(buttons) do
			local pnl = vgui.Create( "DButton", bottom )
			pnl:SetText( v.text )
			pnl:SetSize( DermaPanel:GetWide()/#buttons, 20 )
			pnl.DoClick = v.call
			pnl:Dock(RIGHT)
		end
	end

	local api_changed = 0

	hook.Add("CrashTick", "crashsys", function(is_crashing, length, api_response)
		if is_crashing then
			if IsValid(DermaPanel) then
				local prog = DermaPanel.prog
				local logs = DermaPanel.logs
				local timeout = math.max(timeout_cvar:GetInt(), 10)

				prog:SetFraction( length/timeout )

				if api_changed ~= api_response then
					if api_response == 2 then
						logs:AddLine( "SteamAPI: Server Not Responding!" )
					elseif api_response == 3 then
						logs:AddLine( "SteamAPI: No response from Steam! - Check your internet?" )
					elseif api_response == 4 then
						logs:AddLine( "SteamAPI: Looks like the server is back! - Try reconnecting!" )
					end

					api_changed = api_response
				end

				if length > timeout then
				--	RunConsoleCommand( "retry" )
				end
			else
				api_changed = 0
				ShowMenu()
			end
		else
			if IsValid(DermaPanel) then
				DermaPanel:Remove()
			end
		end
	end)

end