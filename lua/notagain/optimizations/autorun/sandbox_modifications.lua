hook.Add("InitPostEntity", "sandbox_modifications", function()
	if engine.ActiveGamemode() ~= "sandbox" then return end

	function GAMEMODE:CreateMove()

	end

	function GAMEMODE:Move( ply, mv )

	end

	function GAMEMODE:SetupMove( ply, mv, cmd )

	end


	function GAMEMODE:FinishMove( ply, mv )

	end


	function GAMEMODE:CalcView( ply, origin, angles, fov, znear, zfar )


		local view = {}
		view.origin		= origin
		view.angles		= angles
		view.fov		= fov
		view.znear		= znear
		view.zfar		= zfar
		view.drawviewer	= false

		local Vehicle	= ply:GetVehicle()

		if Vehicle:IsValid() then return hook.Run( "CalcVehicleView", Vehicle, ply, view ) end

		local Weapon = ply:GetActiveWeapon()

		-- Give the active weapon a go at changing the viewmodel position
		if Weapon:IsValid() then
			if Weapon.CalcView then
				view.origin, view.angles, view.fov = Weapon.CalcView( Weapon, ply, origin * 1, angles * 1, fov ) -- Note: *1 to copy the object so the child function can't edit it.
			end
		end

		return view

	end

	function GAMEMODE:ShouldDrawLocalPlayer( ply )

	end

	function GAMEMODE:PreDrawViewModel( ViewModel, Player, Weapon )
		if Weapon and Weapon.PreDrawViewModel then
			return Weapon:PreDrawViewModel( ViewModel, Weapon, Player )
		end
	end

	function GAMEMODE:PostDrawViewModel( ViewModel, Player, Weapon )
		if Weapon and Weapon:IsValid() then
			if Weapon.UseHands or not Weapon:IsScripted() then
				local hands = Player:GetHands()
				if hands:IsValid() then
					if not hook.Call("PreDrawPlayerHands", self, hands, ViewModel, Player, Weapon) then
						if Weapon.ViewModelFlip then
							render.CullMode( MATERIAL_CULLMODE_CW )
						end

						hands:DrawModel()

						if Weapon.ViewModelFlip then
							render.CullMode( MATERIAL_CULLMODE_CCW )
						end
					end

					hook.Call("PostDrawPlayerHands", self, hands, ViewModel, Player, Weapon)
				end
			end

			if not Weapon.PostDrawViewModel then return false end

			return Weapon:PostDrawViewModel( ViewModel, Weapon, Player )
		end
	end

	hook.Remove("InitPostEntity", "sandbox_modifications")
end)