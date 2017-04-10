local META = FindMetaTable( "Player" )

function META:IsStuck()
	
	local pos = self:GetPos()
	local mins = self:OBBMins()
	local maxs = self:OBBMaxs()
	local len = 128

	for j = 1 , maxs.z do
		
		for i = 1 , 10 do 
			
			local tr = util.TraceHull({
				
				start  = pos + Vector( 0 , 0 , j ),
				endpos = pos + Vector( 0 , 0 , j ) + Angle( 0 , i*36 - 180 , 0 ):Forward() * len,
				maxs   = maxs,
				mins   = mins,
				filter = self 
			
			})

			if self:GetMoveType() != MOVETYPE_NOCLIP and self:Alive() and !self:Crouching() then
				
				if tr.StartSolid then

					return true 

				end
			
			end
		
		end
	
	end

	return false 

end
