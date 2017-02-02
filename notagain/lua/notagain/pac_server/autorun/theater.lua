 if game.GetMap() ~= "gm_bluehills_test3" then return end

local easylua = requirex("easylua")

easylua.StartEntity("pac_server_cinema")
	ENT.PrintName = "Theater Screen"

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
					if v:GetPos():Distance(Vector(766.525879, 600, 77.898056)) < 600 then
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
	for k,v in pairs(ents.FindByClass("pac_server_cinema")) do v:Remove() end

	local screen = ents.Create( "pac_server_cinema" )
	screen:SetPos(Vector(416,1176,352))
	screen:SetAngles(Angle(0,180,0))
	screen:Spawn()
else
	--This is a very ugly way to do it
	hook.Add("OnContextMenuOpen", "CinemaMediaplayer", function()
		local ent = ents.FindByClass("pac_server_cinema")[1]
		if IsValid(ent) then
			mp = MediaPlayer.GetByObject( ent )
			if IsValid( mp ) then
				MediaPlayer.ShowSidebar( mp )
			end
		end
	end)
end