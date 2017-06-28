local API_RESPONSE = 0 -- Idle, not waiting for a response.
local api = string.format("https://api.steampowered.com/ISteamApps/GetServersAtAddress/v1/?addr=%s&format=json", tostring( game.GetIPAddress() ))

local api_retry = 5
local api_retry_delay = 12

local RealTime = RealTime
local hookAdd = hook.Add
local hookRun = hook.Run

local lastPong
local pong = 0

local crash_status
local crash_time

net.Receive("pingpong", function()
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
hookAdd("Move", "pingpong", pong)
hookAdd("VehicleMove", "pingpong", pong)

local function checkServer()
	API_RESPONSE = 1 -- Waiting for Response.
	http.Fetch(api,
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
end

local delay = RealTime() + api_retry_delay
local times = 1
local function CrashTick(is_crashing, length, api_response)
	if is_crashing then
		crash_status = true
		crash_time = math.Round(length)

		if delay < RealTime() and times <= api_retry then
			checkServer()

			delay = RealTime() + api_retry_delay
			times = times + 1
		end
	else
		times = 1
		crash_status = false

		crash_time = 0
		API_RESPONSE = 0 -- Idle, not waiting for a response.
	end
	hookRun("CrashTick", is_crashing, length, api_response)
end

hookAdd("Tick", "pingpong", function() 
	if not lastPong then return end
	local timeout = RealTime() - lastPong

	if timeout > 1.3 then
		CrashTick(true, timeout, API_RESPONSE)
	else
		CrashTick(false)
	end
end)

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
