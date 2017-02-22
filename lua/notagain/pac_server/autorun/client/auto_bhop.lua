local bhop_convar = CreateClientConVar( "auto_bhop", "0", true, false )

hook.Add("CreateMove","bizzahop",function( cmd )
	if bhop_convar:GetInt() == 1 then
		if bit.band( cmd:GetButtons() , IN_JUMP ) != 0 then
			if !LocalPlayer():IsOnGround() and LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP and LocalPlayer():WaterLevel() <= 1 then
				cmd:SetButtons( bit.band( cmd:GetButtons(), bit.bnot( IN_JUMP ) ) )
			end
		end
	end
end)
