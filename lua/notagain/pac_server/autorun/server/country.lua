-- meta --
local meta = FindMetaTable("Player")
local GeoIP = requirex("geoip")

function meta:GeoIP()
	if not GeoIP then
		error("[Country] GeoIP not found")
	end

	return GeoIP.Get(self)
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



