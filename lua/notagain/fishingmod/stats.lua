local netdata = requirex("netdata")

local META = {}function META:__index(key)	self = self.player	if not self:IsValid() then return end	if SERVER and not self.fishing_initialized then		local data = self:GetPData("fishingmod")
		if data then
			data = util.JSONToTable(data)
		else
			data = {}
		end
		for key, val in pairs(data) do			netdata.SetData(self, "fishingmod_" .. key, val)		end		self.fishing_vars = data		self.fishing_initialized = true	end	return netdata.GetData(self, "fishingmod_" .. key)endfunction META:__newindex(key, val)	self = self.player	if CLIENT or not self:IsValid() then return end	self.fishing_vars = self.fishing_vars or {}	self.fishing_vars[key] = val	self:SetPData("fishingmod", util.TableToJSON(self.fishing_vars))	netdata.SetData(self, "fishingmod_" .. key, val)endfunction fishing.GetStats(ent)	return setmetatable({player = ent or NULL}, META)end