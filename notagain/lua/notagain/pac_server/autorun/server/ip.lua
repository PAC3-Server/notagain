FindMetaTable("Player").IP = function(ply)
    if not IsValid(ply) then return end
    return string.Split(ply:IPAddress(),":"[1])
end