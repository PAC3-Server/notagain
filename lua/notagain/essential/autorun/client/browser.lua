gui.oldOpenURL = gui.oldOpenURL or gui.OpenURL

local browser = {
    History = {},
    HistoryPos = 0,
    HistoryMove = false,
    Init = function(self)
        self:SetSize(ScrW()-100,ScrH()-100)
        self:SetPos(ScrW()/2 - self:GetWide()/2,ScrH()/2 - self:GetTall()/2)
        self:SetTitle("In-Game Browser")
        self:SetSizable(true)

        self.Page     = self:Add("DHTML")
        self.URL      = self:Add("DTextEntry")
        self.Previous = self:Add("DButton")
        self.Next     = self:Add("DButton")
        self.Refresh  = self:Add("DButton")
        self.SteamO   = self:Add("DButton")

        self.URL:Dock(TOP)
        self.URL:SetTall(20)
        self.URL:DockMargin(100,5,100,5)
        self.URL.OnEnter = function(self)
            self:GetParent().Page:OpenURL(self:GetText())
        end

        self.Page:Dock(FILL)
        self.Page.Paint = function(self,w,h)
            surface.SetDrawColor(255,255,255)
            surface.DrawRect(0,0,w,h)
        end

        self.Page.OnDocumentReady = function(self,url)
            local frame = self:GetParent()
            if not frame.HistoryMove then
                frame.URL:SetText(url)
                frame.HistoryPos = frame.HistoryPos + 1
                table.insert(frame.History,frame.HistoryPos,url)
                frame.HistoryMove = false
            end
        end

        self.Previous:SetSize(30,22)
        self.Previous:SetPos(15,33)
        self.Previous:SetText("◄◄")
        self.Previous.DoClick = function(self)
            self:GetParent():PreviousURL()
        end

        self.Next:SetSize(30,22)
        self.Next:SetPos(55,33)
        self.Next:SetText("►►")
        self.Next.DoClick = function(self)
            self:GetParent():NextURL()
        end

        self.Refresh:SetSize(30,22)
        self.Refresh:SetPos(self:GetWide()-90,33)
        self.Refresh:SetText("R")
        self.Refresh.DoClick = function(self)
            self:GetParent():RefreshURL()
        end

        self.Refresh.Think = function(self)
            self:SetPos(self:GetParent():GetWide()-90,33)
        end

        self.SteamO:SetSize(30,22)
        self.SteamO:SetPos(self:GetWide()-50,33)
        self.SteamO:SetText("S-O")
        self.SteamO.DoClick = function(self)
            gui.oldOpenURL(self:GetParent():GetURL())
        end

        self.SteamO.Think = function(self)
            self:SetPos(self:GetParent():GetWide()-50,33)
        end
    end,

    PreviousURL = function(self)
        self.HistoryPos = self.HistoryPos - 1
        if self.HistoryPos == 0 then
            self.HistoryPos = #self.History
        end
        self.HistoryMove = true
        self.Page:OpenURL(self.History[self.HistoryPos])
    end,

    NextURL = function(self)
        self.HistoryPos = self.HistoryPos + 1
        if self.HistoryPos == #self.History + 1 then
            self.HistoryPos = 1
        end
        self.HistoryMove = true
        self.Page:OpenURL(self.History[self.HistoryPos])
    end,

    RefreshURL = function(self)
        self.HistoryMove = true
        self.Page:OpenURL((self.History[self.HistoryPos] or self.URL:GetText()))
    end,

    OpenURL = function(self,url)
        self.URL:SetText(url)
        self.Page:OpenURL(url)
    end,

    GetURL = function(self)
        return self.URL:GetText()
    end,

}

vgui.Register("DBrowser", browser, "DFrame")

local cv = CreateConVar("custom_browser","1",FCVAR_ARCHIVE,"use the custom ingame browser or the steam browser")

gui.OpenURL = function(url)
    if cv:GetBool() then
        local b = vgui.Create("DBrowser")
        b:MakePopup()
        b:OpenURL(url or "www.google.com")
    else
        gui.oldOpenURL(url or "www.google.com")
    end
end

gui.ShowProfile = function(ply)
    if not IsValid(ply) and not ply:IsBot() then return end
    gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
end

local PLAYER = FindMetaTable("Player")
PLAYER.oldShowProfile = PLAYER.oldShowProfile or PLAYER.ShowProfile
PLAYER.ShowProfile = gui.ShowProfile
