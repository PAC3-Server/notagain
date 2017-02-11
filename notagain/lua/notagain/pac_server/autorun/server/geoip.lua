-- thanks python
FindMetaTable("Player").GeoIP = function(ply)
	if not GeoIP then require 'geoip' end
	if not GeoIP then error "GeoIP not found" end
    if not ply:IP() then error(ply:Nick().." has no IP address??") end -- should fix itself over time
	return GeoIP.Get(ply:IP())
end