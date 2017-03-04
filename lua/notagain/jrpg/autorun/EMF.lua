AddCSLuaFile()

if SERVER then
	
	EMF = EMF or {}
	EMF.Ents = EMF.Ents or {}

	local BigValue = 100000

	EMF.Topology = EMF.Topology or {}
	EMF.ActiveEnts = EMF.ActiveEnts or {}
	EMF.MaxDistToRef = 1000 
	EMF.MinDistToRef = 100

	local function IsInMapBounds( pos )
		
		local bound = 16000
		
		return ( pos.x < bound and pos.x > -bound and pos.y < bound and pos.y > -bound and pos.z < bound and pos.z > -bound )
	
	end
	
	function EMF.GenerateTopology()

		local ToIgnore = {

			sky_camera = true,
			env_fog_controller = true,
			worldspawn = true,
			predicted_viewmodel = true,
			func_physbox_multiplayer = true,
			info_particle_system = true,
			game_text = true,
			soundent = true,
			scene_manager = true,
			env_skypaint = true,

		}

		for _ , ent in pairs( ents.GetAll() ) do

			if ent:IsInWorld() and !ToIgnore[ent:GetClass()] and !ent:IsWeapon() and IsInMapBounds( ent:GetPos() ) then

				local tr = util.TraceLine({
					start = ent:GetPos(),
					endpos = ent:GetPos() - ent:GetAngles():Up() * BigValue,
					mask = MASK_PLAYERSOLID,
				})

				if tr.HitPos and !tr.HitNoDraw and !tr.HitSky and tr.HitWorld then
					
					EMF.Topology[#EMF.Topology + 1] = tr.HitPos
				
				end
			
			end

		end
	
	end

	function EMF.AddTopology( pos )
		
		local add = true
		
		for _ , topo in pairs( EMF.Topology ) do
			
			if pos:Distance( topo ) < EMF.MaxDistToRef then
				
				add = false
			
			end
		
		end

		if add then
			
			EMF.Topology[#EMF.Topology+1] = pos 
		
		end
	
	end

	timer.Create("AddTopology",20,0,function()

		local count = 0
		
		for _ , ply in pairs( player.GetAll() ) do
			
			if ply:IsInWorld() then
				
				if ply:OnGround() then
					
					EMF.AddTopology( ply:GetPos() )
					count = count + 1
				
				else

					local tr = util.TraceLine({
						start = ent:GetPos(),
						endpos = ent:GetPos() - ent:GetAngles():Up() * BigValue,
						mask = MASK_PLAYERSOLID,
					})

					if !tr.HitNoDraw and !tr.HitSky and tr.HitWorld and !tr.AllSolid then
						
						EMF.AddTopology( tr.HitPos )
						count = count + 1
					
					end

				end
			
			end
		
		end

		for _ = 1 , count do
			
			table.remove( EMF.Topology , 1 )
		
		end

	end)

	local function RandPosToRef( pos , min , max )
		
		local randpos = Vector( math.random( -max , max ) , math.random( -max , max ) , 5 )
		local arearandpos = pos + randpos
		local finalpos = ( pos:Distance( arearandpos ) < min and ( pos + ( pos - arearandpos ) ) or arearandpos )

		return finalpos
	
	end

	function EMF.SetValidPos( ent , ref ) 

		if !EMF.Topology[ref] or !ent or !IsValid( ent ) then return end 

		local refpos = EMF.Topology[ref]
		local randpos = RandPosToRef( refpos , EMF.MinDistToRef , EMF.MaxDistToRef )

		local tr = util.TraceLine({
			start = randpos,
			endpos = randpos.z >= 0 and randpos - Vector( 0 , 0 , refpos.z )  * BigValue or randpos + Vector( 0 , 0 , refpos.z )  * BigValue,
			mask = MASK_PLAYERSOLID,
		})

		if ent:IsInWorld() and !tr.HitNoDraw and !tr.HitSky and tr.HitWorld and !tr.AllSolid then

			ent:SetPos( tr.HitPos )
			ent:SetPos( ent:NearestPoint( ent:GetPos().z >= 0 and ent:GetPos() - Vector( 0 , 0 , -BigValue ) or ent:GetPos() + Vector( 0 , 0 , -BigValue ) ) )  
			ent:DropToFloor() 

		else
			
			ent.EMFTryPos = ent.EMFTryPos and ent.EMFTryPos + 1 or 1
			
			if ent.EMFTryPos <= 30 then
				
				EMF.SetValidPos( ent , ref )
			
			else
				
				SafeRemoveEntity( ent )
			
			end
		
		end

		table.remove( EMF.Topology ,ref )

	end

	function EMF.SetValidAngle( ent )
		
		if !ent or !IsValid( ent ) then return end
		
		local refpos = ent:GetPos()
		local refangle = ent:GetAngles()
		local angs = { refangle:Forward() , -refangle:Forward() , refangle:Right() , -refangle:Right() }
		local closest = BigValue
		local finalangle = Angle()

		for i = 1 , #angs do
			
			local tr = util.TraceLine({
				start = refpos,
				endpos = refpos + angs[i] * BigValue,
				mask = MASK_PLAYERSOLID,
			})

			if closest > refpos:Distance( tr.HitPos ) and EMF.MinDistToRef >= refpos:Distance( tr.HitPos ) then
				
				closest = refpos:Distance( tr.HitPos )
				finalangle = angs[i]:Angle()
			
			end
		
		end

		-- TODO: z difference detection
		
		--[[if closest == BigValue then
			for i = 1 , #angs do
				
			end
		end]]--

		ent:SetAngles( finalangle )
		
	end

	function EMF.GenerateEnts()
		
		local MaxEntries = #EMF.Topology
		local AmScale = math.Round( MaxEntries / 25 * 1.25 )

		for i = 1 , AmScale do
			
			local ent = ents.Create( EMF.Ents[math.random( 1 , #EMF.Ents )] )
			ent:Spawn()

			EMF.SetValidPos( ent , math.random( 1 , #EMF.Topology ) )
			EMF.SetValidAngle( ent )
			EMF.ActiveEnts[#EMF.ActiveEnts + 1] = ent
		
		end
	
	end

	function EMF.RegenEnts()
		
		for _ , ent in pairs( EMF.ActiveEnts ) do
			
			SafeRemoveEntity( ent )
		
		end

		table.Empty( EMF.ActiveEnts )

		EMF.GenerateEnts()
	
	end

	function EMF.AddEnt( class )

		local add = true

		for _ , eclass in pairs( EMF.Ents ) do
			
			if eclass == class then
				
				add = false
			
			end
		
		end
		
		if add then
			
			EMF.Ents[#EMF.Ents + 1] = class
		
		end
	
	end

	function EMF.Initialize()
		
		EMF.GenerateTopology()
		EMF.GenerateEnts()

		timer.Create( "EMFRegen" , 600 , 0 , function()
			
			EMF.RegenEnts()
		
		end )
	
	end

	hook.Add("InitPostEntity" , "EMFInit" , function()
		
		EMF.Initialize()
	
	end)

end

for _ , fl in ipairs( ( file.Find( "notagain/jrpg/entities/*" , "LUA" ) ) ) do
	
	include( "notagain/jrpg/entities/" .. fl )

end
