local META = FindMetaTable( "Player" )

function META:IsStuck()
	
	local pos = self:GetPos()
	local mins = self:OBBMins()
	local maxs = self:OBBMaxs()
	local len = 128

	for j = 1 , maxs.z do
		
		for i = 1 , 6 do 
			
			local tr = util.TraceHull({
				start = pos + Vector( 0 , 0 , j ),
				endpos = pos + Vector( 0 , 0 , j ) + Angle( 0 , i*60 - 180 , 0 ):Forward() * len,
				maxs = maxs,
				mins = mins,
				filter = self 
			})

			if self:GetMoveType() != MOVETYPE_NOCLIP and self:Alive() then
				
				if !tr.HitWorld and tr.Hit then
					
					local dist = tr.HitPos:Distance( pos + Vector( 0 , 0 , j ) )
					
					if dist < maxs.x or dist < maxs.y or dist < maxs.z then 

						return true

					end

				elseif tr.AllSolid or tr.StartSolid then

					return true 

				end
			
			end
		
		end
	
	end

	return false 

end
