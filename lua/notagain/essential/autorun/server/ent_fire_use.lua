if engine.ActiveGamemode() ~= "sandbox" then return end

local DoorFunctions = {

	["func_door"] = function( self )

		return ( self:GetSaveTable().m_toggle_state == 0 )

	end,

	["func_door_rotating"] = function( self )

		return ( self:GetSaveTable().m_toggle_state == 0 )

	end,

	["func_movelinear"] = function( self )

		return ( self:GetSaveTable().m_toggle_state == 0 )

	end,

	["prop_door_rotating"] = function( self )

		return ( self:GetSaveTable().m_eDoorState ~= 0 )

	end,

}

function DoorIsOpen( door )

	local func = DoorFunctions[door:GetClass()]

	if func then

		return func( door )

	end

end

hook.Add( "KeyPress", "OpenDoors", function( ply, key )

		if key == IN_USE then

		local tr = ply:GetEyeTrace()

		if tr.HitPos:Distance(ply:GetPos()) <= 100 and IsValid(tr.Entity) then

			if DoorIsOpen(tr.Entity) then

				tr.Entity:Fire("close")

			else

				tr.Entity:Fire("open")

			end

		end

	end

end)


