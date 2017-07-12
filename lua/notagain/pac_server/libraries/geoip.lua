pcall(require, "geoip")

if not _G.GeoIP then
	MsgC(Color(255, 127, 127), debug.getinfo(1).source .. " could not find the GeoIP binary module!\n")
end

local GeoIP = _G.GeoIP or {}
_G.GeoIP = nil

local GeoIP_get = GeoIP.Get

function GeoIP.Get(input)
    local input = input
    if isentity(input) then
        if IsValid(input) and input:IsPlayer() then
            input = string.Split(input:IPAddress(), ":")[1]
        end
    end
    if not isstring(input) then -- don't do shit if it's not a string
        error("[GeoIP] input is not a string!")
        return
    end

    local gip

	if GeoIP_get then
		gip = GeoIP_get(input) -- default action
	else
		gip = {}
		MsgC(Color(255, 127, 127), debug.getinfo(2).source .. " could not find the GeoIP binary module!\n")
	end

    return {
        longitude = gip.longitude or 0,
        latitude = gip.latitude or 0,
        city = gip.city or "[city not found]",
        org = gip.org or "[org not found]",
        region = gip.region or "00",
        speed = gip.speed or 0,
        netmask = gip.netmask or 0,
        country_code = gip.country_code or "XX",
        country_name = gip.country_name or "[country_name not found]",
        postal_code = gip.postal_code or "00000",
        asn = gip.asn or "[asn not found]"
    }
end

return GeoIP