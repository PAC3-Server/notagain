AddCSLuaFile()

if SERVER then
	EMF = EMF or {}
	EMF.Ents = EMF.Ents or {}

	local BigValue = 100000

	EMF.Topology = EMF.Topology or {}
	EMF.ActiveEnts = EMF.ActiveEnts or {}
	EMF.MaxDistToRef = 1000 
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

	function EMF.SetValidPos( ent , ref ) 

		if !EMF.Topology[ref] or !ent or !IsValid(ent) then return end 

		local refpos = EMF.Topology[ref]
		local randpos = RandPosToRef( refpos , EMF.MinDistToRef , EMF.MaxDistToRef )

		local tr = util.TraceLine({
			start = randpos,
			endpos = randpos.z >= 0 and randpos - Vector( 0 , 0 , refpos.z )  * BigValue or randpos + Vector( 0 , 0 , refpos.z )  * BigValue,
			mask = MASK_PLAYERSOLID,
		})

		if ent:IsInWorld() and tr.HitTexture != "TOOLS/TOOLSNODRAW" and tr.HitTexture != "TOOLS/TOOLSSKYBOX" and tr.HitTexture != "**empty**" then

			ent:SetPos( tr.HitPos )
			ent:SetPos( ent:NearestPoint( ent:GetPos().z >= 0 and ent:GetPos() - Vector( 0 , 0 , -BigValue ) or ent:GetPos() + Vector( 0 , 0 , -BigValue ) ) )  
			ent:DropToFloor() 

		else
				EMF.SetValidPos( ent , ref )
		end

		table.remove(EMF.Topology,ref)

	end

	function EMF.GenerateEnts()
		local MaxEntries = #EMF.Topology
		local AmScale = math.Round(MaxEntries / 25 * 1.25)

		for i = 1 , AmScale do
			local ent = ents.Create( EMF.Ents[math.random( 1 , #EMF.Ents )] )
			ent:Spawn()

			EMF.SetValidPos( ent , math.random( 1 , #EMF.Topology ) )
			EMF.ActiveEnts[#EMF.ActiveEnts + 1] = ent
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
