local DermaPanel
local ReHookMenu = function() end
local timeout = GetConVar("cl_timeout"):GetInt()

if timeout < 60 then
	RunConsoleCommand("cl_timeout", "60")
end

local function BuildPanel()
	if IsValid(DermaPanel) then DermaPanel:Remove() end

	DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetPos( 0, 0 )
	DermaPanel:SetSize( ScrW(), ScrH() )
	DermaPanel:SetTitle( "Uh Oh!" )
	DermaPanel:SetDraggable( false )
	DermaPanel:MakePopup()

	local prog = vgui.Create( "DProgress", DermaPanel )
	prog:SetPos( 0, 0 )
	prog:SetSize( ScrW(), 20 )
	prog:SetFraction( 0 )

	local logs = vgui.Create( "DListView", DermaPanel )
	logs:SetMultiSelect( false )
	logs:AddColumn( "Status" )

	logs:SetPos( 20, 0 )
	logs:SetSize( (ScrW() - (ScrW()/4))-20, ScrH()-40 )
	logs:Dock( LEFT )

	logs:AddLine( "YOU HAVE TIMEDOUT! - Reconnecting in 60 seconds!" )

	local buttons = {
		[1] = {
			text = "RECONNECT", 
			call = function() RunConsoleCommand( "retry" ) end
		},
		[2] = {
			text = "Copy Discord Link", 
			call = function() 
				SetClipboardText("https://discord.gg/utpR3gJ")
				logs:AddLine( "https://discord.gg/utpR3gJ copied to clipboard!" )
			end
		},
		[3] = {
			text = "DISCONNECT", 
			call = function() RunConsoleCommand( "disconnect" ) end
		},
	}

	for k,v in next, buttons do
		buttons[k] = vgui.Create( "DButton", DermaPanel )
		buttons[k]:SetText( v.text )
		buttons[k]:SetSize( ScrW()/4, (ScrH()/5)-20 )
		buttons[k]:SetPos((ScrW() - (ScrW()/4))-10, k*(ScrH()/5))
		buttons[k].DoClick = v.call
	end

	local api_changed = 0
	hook.Add("CrashTick", "UpdateProgress", function(is_crashing, length, api_response)
		if is_crashing then
			prog:SetFraction( length/60 )

			if api_changed ~= api_response then
				if api_response == 2 then
					logs:AddLine( "SteamAPI: Server Not Responding!" )
				elseif api_response == 3 then
					logs:AddLine( "SteamAPI: No response from Steam! - Check your internet?" )
				elseif api_response == 4 then
					logs:AddLine( "SteamAPI: Looks like the server is back! - Try reconnecting!" )
				end

				if #logs:GetLines() >= 255 then
					logs:Clear()
				end

				api_changed = api_response
			end

			if (length/60) >= 1 then
				RunConsoleCommand( "retry" )
				hook.Remove("CrashTick", "UpdateProgress")
			end
		else
			hook.Remove("CrashTick", "UpdateProgress")
			ReHookMenu()
		end
	end)
end

function ReHookMenu()
	if IsValid(DermaPanel) then DermaPanel:Remove() end
	hook.Add("CrashTick", "CreateGUI", function(is_crashing, length, api_response) 
		if is_crashing then
			BuildPanel()
			hook.Remove("CrashTick", "CreateGUI")
		end
	end)
end

ReHookMenu()
