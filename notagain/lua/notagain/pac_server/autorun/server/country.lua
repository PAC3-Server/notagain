-- meta --
local meta = FindMetaTable("Player")

function meta:IP()
    return string.Split(self:IPAddress(), ":")[1]
end

function meta:GeoIP()
	if not GeoIP then
		pcall(require, "geoip")
	end

	if not GeoIP then
		return {
			longitude = 0,
			latitude = 0,
			city = "GeoIP Not Found",
			org = "GeoIP Not Found",
			region = "00",
			speed = 0,
			netmask = 0,
			country_code = "XX",
			country_name = "GeoIP NotFound",
			postal_code = "00000",
			asn = "GeoIP NotFound",
		}
	end

	if not self:IP() then
		error(self:Nick().." has no IP address??")
	end

	return GeoIP.Get(self:IP())
end

function meta:GetCountryCode()
    return self:GeoIP().country_code
end

function meta:GetCountryName()
    return self:GeoIP().country_name
end

function meta:GetCity()
    return self:GeoIP().city
end


-- country table thing --
local CountryTable = {}

-- local function DebugInitializeCountryData()
--     local players = player.GetAll()
--     if not players then return end
--     for _,ply in ipairs(players) do
--         local tbl = {}
--         tbl.country_code = ply:GetCountryCode()
--         tbl.country_name = ply:GetCountryName()
--         tbl.country_city = ply:GetCity()
--         util.SetPData(ply:SteamID(),"CountryTable",tbl)
--         CountryTable[ply:SteamID()] = tbl
--     end
-- end

-- DebugInitializeCountryData()

hook.Add("PlayerInitialSpawn","SetPlayerCountry",function(ply)
    if CountryTable[ply:SteamID()] or not IsValid(ply) then return end -- don't need to store multiple times
    local tbl = {}
    tbl.country_code = ply:GetCountryCode()
    tbl.country_name = ply:GetCountryName()
    tbl.country_city = ply:GetCity()
    CountryTable[ply:SteamID()] = tbl
end)
hook.Add("PlayerDisconnected","CountryTableCleanupPly",function(ply)
    if not CountryTable or not IsValid(ply) then return end
    CountryTable[ply:SteamID()] = nil
end)

-- networking --
util.AddNetworkString("CountryReq")
util.AddNetworkString("CountryRes")

local lastrefresh = lastrefresh or CurTime()
net.Receive("CountryReq",function(len,ply)
    if CurTime() - lastrefresh < 10 then return end -- never trust the client etc
    net.Start("CountryRes")
    net.WriteTable(CountryTable)
    net.Send(ply)
    lastrefresh = CurTime()
end)



