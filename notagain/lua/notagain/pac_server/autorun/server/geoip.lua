-- thanks python
FindMetaTable("Player").GeoIP = function(ply)
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

	if not ply:IP() then
		error(ply:Nick().." has no IP address??")
	end

	return GeoIP.Get(ply:IP())
end