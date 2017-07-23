AddCSLuaFile()

local netstring = "AOWL_GUI_LOGS"
local netsendcmds = "AOWL_GUI_SEND_CMDS"
local netrequestsync = "AOWL_GUI_REQUEST_SYNC"
local tag = "aowl_gui"

if _G.aowlgui and _G.aowlgui.GUI then
    _G.aowlgui.GUI:Remove()
end

local aowlgui = {}
_G.aowlgui = aowlgui

if SERVER then
    util.AddNetworkString(netstring)
    util.AddNetworkString(netsendcmds)
    util.AddNetworkString(netrequestsync)

    hook.Add("AowlCommand",tag,function(command, alias, ply, arg_line,...)
        local args = {...}
        net.Start(netstring)
        net.WriteEntity(ply)
        net.WriteString(alias)
        net.WriteTable(args)
        local tbl = {}
        table.insert(tbl,ply)
        for k,v in pairs(player.GetAll()) do
            if v:IsAdmin() and v ~= ply then
                table.insert(tbl,v)
            end
        end
        net.Send(tbl)
    end)

    local SendCmdsToClient = function(ply)
        if not IsValid(ply) or not _G.aowl then return end
        local tbl = {}
        for k,v in pairs(_G.aowl.commands) do
            if ply:CheckUserGroupLevel(v.group or "players") then
                tbl[k] = {
                    aliases = v.aliases,
                    argtypes = v.argtypes,
                }
            end
        end
        net.Start(netsendcmds)
        net.WriteTable(tbl)
        net.Send(ply)
    end

    hook.Add("PlayerInitialSpawn",tag,SendCmdsToClient)

    net.Receive(netrequestsync,function(len,ply)
        SendCmdsToClient(ply)
    end)

	aowl.AddCommand("menu|aowl|aowlgui=nil",function(ply)
		ply:ConCommand("aowlgui")
	end)
end

if CLIENT then

    aowlgui.Commands = aowlgui.Commands or {}

    function aowlgui.UpdateCommands()
		net.Start(netrequestsync)
		net.SendToServer()
	end

    function aowlgui.Init()
		local swidth,sheight = ScrW(),ScrH()

		local frame = vgui.Create("DFrame")

		frame:SetSize(700,500)
		frame:SetPos(swidth/2-frame:GetWide()/2,sheight/2-frame:GetTall()/2)
		frame:ShowCloseButton(true)
		frame:SetDraggable(true)
		frame:SetSizable(true)
		frame:SetTitle("")
		frame.Paint = function(self,w,h)
		    surface.SetDrawColor(220,220,220)
		    surface.DrawRect(0,0,w,h)
		    surface.SetDrawColor(255,255,255)
		    surface.DrawOutlinedRect(0,0,w,h)
		    surface.DrawLine(0,25,w,25)
		    surface.SetDrawColor(175,175,175)
		    surface.DrawRect(1,1,w-2,24)
		    surface.SetTextColor(255,255,255)
		    surface.SetFont("DermaDefaultBold")
		    local x,y = surface.GetTextSize("AOWL Menu")
		    surface.SetTextPos(w/2-x/2,25/2-y/2)
		    surface.DrawText("AOWL Menu")
		end

		frame.btnMaxim:Hide()
		frame.btnMinim:Hide()

		frame.btnClose.DoClick = aowlgui.Close
		frame.btnClose.PaintOver = function(self,w,h)
		    surface.SetDrawColor(255,255,255)
		    surface.DrawOutlinedRect(0,3,w-2,h-13)
		end

		local list = frame:Add("DListView")
		frame.list = list
		list:Dock(LEFT)
		list:DockMargin(5,5,5,5)
		list:SetWide(frame:GetWide()/5)
		list:SetMultiSelect(false)
		list:AddColumn("Commands")
		list.PaintOver = function(self,w,h)
		    surface.SetDrawColor(200,200,200)
		    surface.DrawRect(0,0,w,15)
		    surface.SetDrawColor(255,255,255)
		    surface.DrawOutlinedRect(0,0,w,h)
		    surface.DrawLine(0,15,w,15)
		    surface.SetTextColor(80,80,80)
		    local x,y = surface.GetTextSize("Commands")
		    surface.SetTextPos(w/2-x/2,15/2-y/2)
		    surface.DrawText("Commands")
		end

		local log = frame:Add("RichText")
		frame.log = log
		log:Dock(BOTTOM)
		log:DockMargin(5,5,5,5)
		log:SetTall(frame:GetTall()/6)
		log.Paint = function(self,w,h)
		    surface.SetDrawColor(0,0,0)
		    surface.DrawRect(0,0,w,h)
		    surface.SetDrawColor(255,255,255)
		    surface.DrawOutlinedRect(0,0,w,h)
		end

		local setup = frame:Add("DScrollPanel")
		frame.setup = setup
		setup:Dock(FILL)
		setup:DockMargin(5,5,5,5)
		setup.Paint = function(self,w,h)
		    surface.SetDrawColor(240,240,240)
		    surface.DrawRect(0,0,w,h)
		    surface.SetDrawColor(200,200,200)
		    surface.DrawRect(0,0,w,50)
		    surface.SetDrawColor(255,255,255)
		    surface.DrawOutlinedRect(0,0,w,h)
		    surface.DrawLine(0,50,w,50)
		end

		local lsearch = setup:Add("DLabel")
		frame.lsearch = lsearch
		lsearch:SetText("Search command:")
		lsearch:SetPos(6,5)
		lsearch:SetSize(150,20)
		lsearch:SetTextColor(Color(80,80,80))

		local search = setup:Add("DTextEntry")
		search:SetSize(150,20)
		search:SetPos(5,lsearch:GetTall())
		search.OnKeyCodeTyped = function(self,code)
		    aowlgui.UpdateCmdList(self:GetText())
		end

		local error = setup:Add("DLabel")
		error:SetText("Sorry it seems that this command does not have a documentation yet")
		error:SetTextColor(Color(220,40,40))
		error:SetPos(5,60)
		error:SetSize(500,40)
		error:Hide()

		local atitle = setup:Add("DLabel")
		atitle:SetText("Aliases:")
		atitle:SetPos(50+lsearch:GetWide(),5)
		atitle:SetSize(150,35)
		atitle:SetTextColor(Color(80,80,80))

		local updatecmds = setup:Add("DButton")
		updatecmds:SetPos(270+atitle:GetWide(),10)
		updatecmds:SetSize(100,30)
		updatecmds:SetText("Update Commands")
		updatecmds:SetTextColor(Color(80,80,80))

		updatecmds.DoClick = aowlgui.UpdateCommands()

		updatecmds.Paint = function(self,w,h)
		    local col1 = Color(220,220,220)
		    local col2 = Color(255,255,255)
		    if self:IsHovered() then
			col1 = Color(220,255,220)
			col2 = Color(0,255,0)
		    end
		    surface.SetDrawColor(col1)
		    surface.DrawRect(0,0,w,h)
		    surface.SetDrawColor(col2)
		    surface.DrawOutlinedRect(0,0,w,h)
		end

		list.OnRowSelected = function(self,index,panel)
		    local cmd = panel:GetColumnText(1)
		    aowlgui.UpdateAliases(cmd)
		    if not aowlgui.Commands[cmd].desc then
			error:Show()
		    else
			error:Hide()
		    end
		end

		frame:MakePopup()
		frame:Hide()
		aowlgui.GUI = frame
    	end

	function aowlgui.Open()
		if IsValid(aowlgui.GUI) then
		    aowlgui.GUI:Show()
		else
		    aowlgui.Init()
		    aowlgui.GUI:Show()
		end
		aowlgui.UpdateCommands()
	end

	function aowlgui.Close()
		aowlgui.GUI:Hide()
	end

	function aowlgui.IsOpened()
		return IsValid(aowlgui.GUI) and aowlgui.GUI:IsVisible()
	end

	local GetProperName = function(self)
		if not IsValid(self) then return nil end
		local name,_ = string.gsub(self:Nick(),"(%^%d+)","")
		name,_ = string.gsub(name,"(<.->)","")
		return name
	end

	function aowlgui.LogCommand(ply,cmd,args)
		if not aowlgui.IsOpened() then return end

		local log = aowlgui.GUI.log
		log:InsertColorChange(220,220,220,255)
		log:AppendText(os.date("%H:%M:%S").." - ")
		local tcol = team.GetColor(ply:Team())
		log:InsertColorChange(tcol.r,tcol.g,tcol.b,255)
		log:AppendText(GetProperName(ply))
		log:InsertColorChange(175,175,175,255)
		log:AppendText(" -> ")
		log:InsertColorChange(244,167,66,255)
		log:AppendText("CMD["..cmd.."]")
		if args and #args > 0 then
			log:InsertColorChange(220,220,220,255)
			log:AppendText(" { ")
			log:InsertColorChange(0,200,240,255)
			for k,v in pairs(args) do
				if k > 1 then log:AppendText("  ") end
				log:AppendText("#"..k)
				log:AppendText("["..tostring(v).."]")
			end
			log:InsertColorChange(220,220,220,255)
			log:AppendText(" } ")
		end
		log:AppendText("\n")
	end

	function aowlgui.UpdateCmdList(search)
		if not aowlgui.IsOpened() then return end
		local list = aowlgui.GUI.list
		list:Clear()
		if not search then
		    for k,v in pairs(aowlgui.Commands) do
			list:AddLine(k)
		    end
		else
		    local search = string.PatternSafe(search)
		    for k,v in pairs(aowlgui.Commands) do
			if string.match(k,search) then
			    list:AddLine(k)
			end
		    end
		end
	end

	local last_labels_aliases = {}
    	function aowlgui.UpdateAliases(cmd)
		if not aowlgui.IsOpened() then return end

		for k,v in pairs(last_labels_aliases) do
		    v:Remove()
		end
		local aliases = aowlgui.GetAliases(cmd)
		local i = 1
		for k,v in pairs(aliases) do
		    if v ~= cmd then
			local lbl = aowlgui.GUI.setup:Add("DLabel")
			lbl:SetText("⮞ "..v)
			lbl:SetTextColor(Color(30,30,30))
			lbl:SetPos(95+aowlgui.GUI.lsearch:GetWide(),-10+(10*i))
			lbl:SetSize(150,20)
			table.insert(last_labels_aliases,lbl)
			i = i + 1
		    end
		end
	end

	function aowlgui.GetClientCmds()
		for k,v in pairs(_G.aowl.commands) do
		    aowlgui.Commands[k] = {
			aliases = v.aliases,
			argtypes = v.argtypes,
		    }
		end
	end

	function aowlgui.GetAliases(cmd)
        	if not aowlgui.Commands[cmd] then return end
        	return aowlgui.Commands[cmd].aliases
    	end

	net.Receive(netstring,function()
		local ply = net.ReadEntity()
		local cmd = net.ReadString()
		local args = net.ReadTable()
		aowlgui.LogCommand(ply,cmd,args)
	end)

	net.Receive(netsendcmds,function()
		local tbl = net.ReadTable()
		aowlgui.Commands = tbl
		aowlgui.GetClientCmds()
		aowlgui.UpdateCmdList()
	end)

	hook.Add("AowlInitialized",tag,aowlgui.Init)

	concommand.Add("aowlgui",function()
		if aowlgui.IsOpened() then
		    aowlgui.Close()
		else
		    aowlgui.Open()
		end
	end)
end
