 if game.GetMap() ~= "gm_bluehills_test3" then return end

local easylua = requirex("easylua")

easylua.StartEntity("bluehill_theater_screen")
	ENT.PrintName = "Bluehill Theater Screen"

	ENT.Type = "anim"

	ENT.Base = "mediaplayer_base"

	ENT.RenderGroup = RENDERGROUP_OPAQUE

	ENT.PlayerConfig = {
		offset	= Vector(0,-.2,0),
		angle	= Angle(0,180,90),
		width = 704,
		height = 352
	}

	function ENT:Initialize()
		if SERVER then
			self:InstallMediaPlayer( "entity" )

			local mp = self:GetMediaPlayer()

			function mp:UpdateListeners()
				local listeners = {}
				for k, v in pairs(player.GetAll()) do
					if v:GetPos():Distance(Vector(766.525879, 600, 77.898056)) < 600 then --This really needs to be redone
						table.insert(listeners, v)
					end
				end
				self:SetListeners(listeners)
			end
		end
	end

	if CLIENT then
		function ENT:Draw()
		end
	end
easylua.EndEntity()

if SERVER then
	hook.Add("InitPostEntity", "SpawnTheaterScreen", function()
		for k,v in pairs(ents.FindByClass("bluehill_theater_screen")) do v:Remove() end

		local screen = ents.Create( "bluehill_theater_screen" )
		screen:SetPos(Vector(416,1176,352))
		screen:SetAngles(Angle(0,180,0))
		screen:Spawn()
	end)
else
	--This is a very ugly way to do it
	hook.Add("OnContextMenuOpen", "CinemaMediaplayer", function()
		local ent = ents.FindByClass("bluehill_theater_screen")[1]
		if IsValid(ent) then
			mp = MediaPlayer.GetByObject( ent )
			if IsValid( mp ) then
				MediaPlayer.ShowSidebar( mp )
			end
		end
	end)
end