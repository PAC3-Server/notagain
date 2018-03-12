--
if SERVER then
	util.AddNetworkString("creact")
	util.AddNetworkString("sreact")
	net.Receive( "creact", function()
		net.Start("sreact")
		net.WriteTable(net.ReadTable())
		net.Send(player.GetHumans())
	end)
end

if CLIENT then
	local iconlist = 
	{"icon16/accept.png","icon16/award_star_gold_1.png","icon16/bomb.png",
	"icon16/bin_empty.png","icon16/box.png","icon16/cake.png",
	"icon16/cancel.png","icon16/computer_error.png","icon16/emoticon_evilgrin.png","icon16/emoticon_grin.png",
	"icon16/emoticon_happy.png","icon16/emoticon_smile.png","icon16/emoticon_surprised.png","icon16/emoticon_tongue.png",
	"icon16/emoticon_unhappy.png","icon16/emoticon_waii.png","icon16/emoticon_wink.png","icon16/error.png",
	"icon16/fire.png","icon16/music.png","icon16/exclamation.png","icon16/help.png",
	"icon16/information.png","icon16/rainbow.png","icon16/sound_mute.png","icon16/star.png",
	"icon16/thumb_down.png","icon16/thumb_up.png","icon16/tick.png","icon16/water.png",
	"icon16/bell.png","icon16/camera.png","icon16/clock_red.png","icon16/comment.png",
	"icon16/cross.png","icon16/cup.png","icon16/door_open.png","icon16/heart.png",
	"icon16/eye.png","icon16/monkey.png"}
	
	net.Receive( "sreact", function()
		tbl = net.ReadTable()
		DrawReaction(tbl[1],tbl[2])
	end)

	local Cmenumenu = nil

	hook.Add("OnContextMenuOpen","ReactionMenuOpen",function()
		if(Cmenumenu == nil)then
			Cmenumenu = SelectReaction()
		end
		Cmenumenu:Show()
	end)

	hook.Add("OnContextMenuClose","ReactionMenuClose",function()
		Cmenumenu:Hide()
	end)
	
	function SelectReaction()
		local ReactionSelectionFrame = vgui.Create( "DFrame" )
		local y = 29
		for i = 1,math.ceil(table.Count(iconlist)/10) do
			y = y+26
		end
		ReactionSelectionFrame:SetSize( 266, y )
		ReactionSelectionFrame:SetTitle( "Select reaction" )
		ReactionSelectionFrame:ShowCloseButton(false)
		ReactionSelectionFrame:SetDraggable(true)
		ReactionSelectionFrame:MakePopup()
		ReactionSelectionFrame:SetPos(0,ScrH()-y)
		ReactionSelectionFrame:SetDeleteOnClose(false)
		ReactionSelectionFrame:SetKeyboardInputEnabled(false)
		ReactionSelectionFrame:SetMouseInputEnabled(true)
		ReactionSelectionFrame:MakePopup()

		local y = 27
		local x = 4
		
		for k,v in pairs(iconlist) do
			if(x == 264)then
				x = 4
				y = y+26
			end
			local bttn = vgui.Create( "DButton", ReactionSelectionFrame )
			bttn:SetText("")
			bttn:SetSize(24,24)
			bttn:SetPos(x,y)
			bttn:SetIcon(v)
			bttn.DoClick = function()
				SendReaction(LocalPlayer():EntIndex(),k)
			end
			x = x+26
		end
		return ReactionSelectionFrame
	end

	function SendReaction(target,num)
		net.Start("creact")
		net.WriteTable({target,num})
		net.SendToServer()
	end

	function DrawReaction(target,matr)
		local stime = SysTime()
		local minus = 0
		hook.Add( "PostDrawTranslucentRenderables", tostring(target), function()
			if(matr <= table.Count(iconlist))then
				local mat1 = Material(iconlist[matr])
				mat1 = Material(iconlist[matr])
				render.SetMaterial( mat1 )
				local ltimeex = math.Clamp(((math.sin((SysTime()-stime)*(math.pi/5))*10)*64)-64,-64,0)
				local timeex = math.Clamp((math.sin((SysTime()-stime)*(math.pi/5))*10)*255,0,255)
				if(target == LocalPlayer():EntIndex())then
					cam.Start2D()
					render.DrawScreenQuadEx( ltimeex, (ScrH()/2)-16, 64, 64 )
					cam.End2D()
				end
				local spos,ang = Entity(target):GetBonePosition(Entity(target):LookupBone( "ValveBiped.Bip01_Head1" ))
				spos = spos+Vector(0,0,3)
				render.DrawQuadEasy( spos+ang:Right():Angle():Forward()*8,ang:Right():Angle():Forward(), 8, 8, Color( 255, 255, 255, timeex ),180)

			end
		end )
		timer.Create( tostring(target).."alpha0", 6, 1, function()
			hook.Remove("PostDrawTranslucentRenderables", tostring(target))
		end )
	end
end