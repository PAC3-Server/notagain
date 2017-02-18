require("geoip")

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

    local gip = GeoIP_get(input) -- default action
    return {
        longitude = gip.longitude or 0,
        latitude = gip.latitude or 0,
        city = gip.city or "GeoIP city Not Found",
        org = gip.org or "GeoIP org Not Found",
        region = gip.region or "00",
        speed = gip.speed or 0,
        netmask = gip.netmask or 0,
        country_code = gip.country_code or "XX",
        country_name = gip.country_name or "GeoIP country name NotFound",
        postal_code = gip.postal_code or "00000",
        asn = gip.asn or "GeoIP asn NotFound"
    }
end

return GeoIP