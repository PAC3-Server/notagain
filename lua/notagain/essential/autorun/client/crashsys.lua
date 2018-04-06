if game.SinglePlayer() then return end

local GRACE_TIME = 3.5 -- How many seconds of lag should we have before showing the panel?
local PING_MISS = 2 -- How many pings can we miss on join?

local CHAT_LINK = "https://discord.gg/utpR3gJ" -- The link to copy, when requesting a chat link. (Set to nil if you don't have one!)
local CHAT_PLATFORM = "Discord" -- The platform you use for chat. (Set to nil if you're not sure!)

local API_RESPONSE = 0 -- Idle, not waiting for a response.
local api_retry = 5
local api_retry_delay = 12

local lastPong = false
local crash_status
local crash_time

local delay = 0
local times = 1

-- Ping the server when the client is ready.
timer.Create("crashsys_startup", 0.01, 0, function()
	local ply = LocalPlayer()
	if ply:IsValid() then
		net.Start("crashsys")
		net.SendToServer()
		print("Initializing CrashSys...")
		timer.Remove("crashsys_startup")
	end
end)

-- Delay Function
local function delaycall(time, callback)
	local wait = RealTime() + time
	hook.Add("Tick", "crashsys_delay", function()
		if RealTime() > wait then
			callback()
			hook.Remove("Tick", "crashsys_delay")
		end
	end)
end

local cl_timeout = GetConVar("cl_timeout"):GetInt()

if cl_timeout < 80 then
	local str = string.format("CRASHSYS: Your cl_timeout value, '%s' has been changed to '80'! (See Console for more info.)", cl_timeout)
	RunConsoleCommand("cl_timeout", "80")
	print(str, "\nCrashSys has detected that your cl_timeout value was too low. Make sure it's set to atleast 80 as servers may sometimes recover after 30 seconds!")
end

cvars.AddChangeCallback( "cl_timeout", function(_, _, timeout)
	cl_timeout = tonumber( timeout )
	if cl_timeout <= 0 then
		cl_timeout = 120
	end
end )

local function CrashTick(is_crashing, length, api_response)
	if is_crashing then
		crash_status = true
		crash_time = math.Round(length)

		if delay == 0 then
			delay = RealTime() + api_retry_delay -- Give the API some time to update.
		end

		if API_RESPONSE ~= 4 then
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
	if not LocalPlayer():IsValid() then return end -- disconnected or connecting

	local timeout = RealTime() - lastPong

	if timeout > GRACE_TIME then
		CrashTick(true, timeout, API_RESPONSE)
	else
		CrashTick(false)
	end
end)

local function halt()
	lastPong = false
	hook.Remove("Tick", "crashsys")
	hook.Remove("Move", "crashsys")
	hook.Remove("VehicleMove", "crashsys")
end

hook.Add("ShutDown", "crashsys", function()
	halt() -- Kill CrashSys, remove all active CrashSys hooks.
end)

net.Receive("crashsys", function()
	local shutdown = ( net.ReadBit() == 1 )
	if shutdown then
		halt()
	else
		if PING_MISS < 1 then -- Allow some pings before actually starting crash systems. (Avoid bugs on join stutter.)
			PING_MISS = PING_MISS - 1
		else
			lastPong = RealTime()
		end
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
	local menu_closed = false

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
			menu_closed = true
		end

		local prog = vgui.Create( "DProgress", DermaPanel )
		prog:SetFraction( 0 )
		prog:Dock(TOP)

		DermaPanel.prog = prog

		local logs = vgui.Create( "DListView", DermaPanel )

		logs.Head = logs:AddColumn( "Status" )
		function logs.Head.DoClick() end

		logs:SetMultiSelect( false )
		logs:Dock(FILL)

		logs:AddLine( "YOU HAVE TIMED OUT! - Reconnecting in " .. cl_timeout .. " seconds!" )

		logs.OldAddLine = logs.OldAddLine or logs.AddLine
		function logs:AddLine(...)
			local vbar = self.VBar
			local line = self:OldAddLine(...)

			self:ClearSelection()
			self:SelectItem(line)

			delaycall(0.01, function()
				if IsValid(vbar) then
					vbar:SetScroll(vbar.CanvasSize)
				end
			end)

			return line
		end

		DermaPanel.logs = logs

		local bottom = vgui.Create("DPanel", DermaPanel)
		bottom:Dock(BOTTOM)

		local buttons = {
			{
				text = "RECONNECT",
				enable = true,
				call = function(button)
					button:SetDisabled( true )
					delaycall(1, function()
						RunConsoleCommand( "snd_restart" )
						RunConsoleCommand( "retry" ) 
					end)
				end
			},
			{
				text = CHAT_LINK and ( "Copy " .. ( CHAT_PLATFORM or "Chat" ) .. " Link" ) or "",
				enable = ( CHAT_LINK ~= nil ),
				call = function()
					if CHAT_LINK then
						SetClipboardText( CHAT_LINK )
						logs:AddLine( CHAT_LINK .. " copied to clipboard!" )
					else
						logs:AddLine( "No link is specified :(" )
					end
				end
			},
			{
				text = "DISCONNECT",
				enable = true,
				call = function() RunConsoleCommand( "disconnect" ) end
			},
		}

		for i, v in ipairs(buttons) do
			local pnl = vgui.Create( "DButton", bottom )
			pnl:SetText( v.text )
			pnl:SetSize( DermaPanel:GetWide()/#buttons, 20 )
			function pnl:DoClick() v.call(self) end
			pnl:Dock(RIGHT)
			pnl:SetEnabled( v.enable )
		end
	end

	local api_changed = 0

	local canned_messages = {
		[1] = {
			"Guh... what? Impossible!?",
			"Suffer like G did?",
			"Playtime has ended...",
			"The password is Wild Rose.",
			"Blaming Staff...",
			"Attempting to multiply by zero...",
			"It was you wasn't it?",
			"Recovering recoverables...",
			"Chasing tail...",
			"Filling out crash reports...",
			"404 no server found...",
			"Feeding the chocobos...",
			"Sleeping on the job?",
			"Taming the dragons...",
		},
		[2] = {
			"Sure is taking a while...",
			"So how's your day been?",
			"Spam pinging the admins...",
			"Atleast the weather's nice...",
			"What have you done?",
			"Don't blame the operator.",
			"Looking for a way out...",
			"Reinstalling Garry's Mod",
			"Looks like it's your (un)lucky day.",
			"Yup we're still timing out.",
			"Blaming the devs...",
			"Using escape rope...",
			"Pushing on daisies...",
			"Increase dramatical power!!!!"
		},
		[3] = {
			"Fear not! Our word is our bond! We shall return!",
			"You should double check to see if the server is up again.",
			"Taking way longer then expected... blame devs.",
			"Retrying soon...",
			"Checking your watch...",
			"Don't worry we'll retry soon...",
			"The end draws near..."
		}
	}

	local last_per = 0 -- So we don't spam.
	hook.Add("CrashTick", "crashsys", function(is_crashing, length, api_response)
		if is_crashing then
			if IsValid(DermaPanel) then
				local prog = DermaPanel.prog
				local logs = DermaPanel.logs

				local timeout = cl_timeout
				local fraction = length/timeout
				local per = math.floor(fraction*100)

				prog:SetFraction( fraction )

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

				if per%3 == 0 and per ~= last_per then
					last_per = per

					local key = per < 60 and 1 or per < 65 and 2 or per >= 80 and 3
					local msg = canned_messages[key]

					if msg then
						DermaPanel:SetTitle( msg[math.random(1,#msg)] )
					end

					if per == 96 then
						logs:AddLine( "Attempting to auto-reconnect in 3 seconds!" )
					end
				end

				if per >= 99 then
					DermaPanel:Close()
					delaycall(0.03, function()
						RunConsoleCommand("snd_restart")
						RunConsoleCommand("retry")
					end)
				end
			elseif not menu_closed then
				api_changed = 0
				ShowMenu()
			end
		else
			delay = 0
			last_per = 0
			api_changed = 0
			menu_closed = false
			if IsValid(DermaPanel) then
				DermaPanel:Remove()
			end
		end
	end)

end
