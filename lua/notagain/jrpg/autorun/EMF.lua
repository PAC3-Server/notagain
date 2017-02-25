if SERVER then
	EMF = EMF or {}
	EMF.Ents = EMF.Ents or {}

	local BigValue = 100000

	EMF.Topology = EMF.Topology or {}
	EMF.ActiveEnts = EMF.ActiveEnts or {}
	EMF.MaxDistToRef = 1000 --Do not change those values if you don't know what you're doing
	EMF.MinDistToRef = 100

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

			if ent:IsInWorld() and !ToIgnore[ent:GetClass()] and !ent:IsWeapon()  then

				local tr = util.TraceLine({
					start = ent:GetPos(),
					endpos = ent:GetPos() - ent:GetAngles():Up() * BigValue,
					mask = MASK_PLAYERSOLID,
				})

				if tr.HitPos and tr.HitTexture != "TOOLS/TOOLSNODRAW" and tr.HitTexture != "TOOLS/TOOLSSKYBOX" and tr.HitTexture != "**empty**" then
					EMF.Topology[#EMF.Topology + 1] = tr.HitPos
				end
			end

		end
	end

	function EMF.RegenTopology()
		table.Empty( EMF.Topology )
		EMF.GenerateTopology()
	end

	local function RandPosToRef( pos , min , max )
		local randpos = Vector( math.random( -max , max ) , math.random( -max , max ) , 5 )
		local arearandpos = pos + randpos
		local finalpos = ( pos:Distance( arearandpos ) < min and ( pos + ( pos - arearandpos ) ) or arearandpos )

		return finalpos
	end

	function EMF.SetValidPos( ent , ref ) -- ref is topology index

		if !EMF.Topology[ref] then return end -- prevents invalid indexes

		local refpos = EMF.Topology[ref]
		local randpos = RandPosToRef( refpos , EMF.MinDistToRef , EMF.MaxDistToRef )

		local tr = util.TraceLine({
			start = randpos,
			endpos = randpos.z >= 0 and randpos - Vector( 0 , 0 , refpos.z )  * BigValue or randpos + Vector( 0 , 0 , refpos.z )  * BigValue,
			mask = MASK_PLAYERSOLID,
		})

		if ent:IsInWorld() and tr.HitTexture != "TOOLS/TOOLSNODRAW" and tr.HitTexture != "TOOLS/TOOLSSKYBOX" and tr.HitTexture != "**empty**" then

			ent:SetPos( tr.HitPos )
			ent:SetPos( ent:NearestPoint( ent:GetPos().z >= 0 and ent:GetPos() - Vector( 0 , 0 , -BigValue ) or ent:GetPos() + Vector( 0 , 0 , -BigValue ) ) )  -- so ent isnt part stuck in the ground
			ent:DropToFloor() -- in case nearest point doesnt do its job

		else
			ent.EMFTryPosCount = ent.EMFTryPosCount and ent.EMFTryPosCount + 1 or 1

			if ent.MFTryPosCount < 20 then -- recursion depth limit
				EMF.SetValidPos( ent , ref )
			else
				ent:SetPos(tr.HitPos)
			end

		end

	end

	function EMF.GenerateEnts()
		local MaxEntries = #EMF.Topology
		local AmScale = MaxEntries / 50 * ( #player.GetAll() <= 10 and 1 or math.Round( #player.GetAll() / 10 ) )

		for i = 1 , AmScale do
			local ent = ents.Create( EMF.Ents[math.random( 1 , #EMF.Ents )] )
			ent:Activate()
			ent:Spawn()

			EMF.SetValidPos( ent , math.random( 1 , #EMF.Topology ) )
			EMF.ActiveEnts[ent:EntIndex()] = ent
		end
	end

	function EMF.RegenEnts()
		for _ , v in pairs( EMF.ActiveEnts ) do
			SafeRemoveEntity( v )
		end

		table.Empty( EMF.ActiveEnts )

		EMF.GenerateEnts()
	end

	function EMF.AddEnt( class )
		EMF.Ents[#EMF.Ents + 1] = class
	end

	function EMF.Initialize()
		EMF.GenerateTopology()
		EMF.GenerateEnts()

		timer.Create( "EMFRegen" , 600 , 0 , function()
			EMF.RegenTopology()
			EMF.RegenEnts()
		end )
	end

	hook.Add("InitPostEntity" , "EMFInit" , function()
		EMF.Initialize()
	end)

end

for _ , fl in ipairs((file.Find("notagain/jrpg/entities/*", "LUA"))) do
	include("notagain/jrpg/entities/" .. fl )
end
