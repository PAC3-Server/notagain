local audio = {}

do
	local META = {}

	META.__valid = true

	function META:IsValid()
		return self.__valid == true
	end

	function META:QueueEvent(event, val)
		table.insert(self.event_queue, {event = event, val = val})
	end

	function META:ExecuteEventQueue()
		for i, data in ipairs(self.event_queue) do
			self:OnEvent(data.event, data.val)
		end
	end

	function META:SetSoundObject(obj)
		self.obj = obj
		self:ExecuteEventQueue()
	end

	local function DEFINE_FUNCTION(func, default)
		META[func] = default
		META["Set" .. func] = function(self, val) self[func] = val self:OnEvent("Set" .. func, val) end
		META["Get" .. func] = function(self) return self[func] end
	end

	DEFINE_FUNCTION("Pitch", 1)
	DEFINE_FUNCTION("Duration", -1)
	DEFINE_FUNCTION("Gain", 1)
	DEFINE_FUNCTION("Entity", NULL)
	DEFINE_FUNCTION("Looping", false)

	function META:SetPath(path, where)
		self.Path = path
		self.Where = where or "GAME"
		self:OnLoad(path, where)
	end

	function META:GetPath()
		return self.Path
	end

	function META:Stop()
		self:OnEvent("stop")
	end

	function META:Play()
		self:OnEvent("play")
	end

	function META:Pause()
		self:OnEvent("pause")
	end

	function META:GetDuration()
		return self:OnEvent("GetDuration") or -1
	end

	function META:IsReady()
		error("NYI", 2)
	end

	function META:Remove()
		self:OnEvent("remove")
		self.__valid = false
	end

	function META:Restart()
		self:Stop()
		self:Play()
	end

	function META:OnError(str)
		MsgC(Color(0, 255, 0), "[audio]["..self.ClassName.."] ")
        MsgC(Color(255, 100, 100), str)
        Msg("\n")
	end

	function META:OnRemove()
		self:Remove()
	end

	audio.base_meta = META
end

function audio.CreateTemplate(name)
	local META = table.Copy(audio.base_meta)
	META.__index = META
	META.ClassName = name
	return META
end

audio.registered = audio.registered or {}

function audio.RegisterTemplate(META)
	audio.registered[META.ClassName] = META
end

do
	local META = audio.CreateTemplate("bass")

	function META:Panic()
		RunConsoleCommand("stopsound")
	end

	function META:IsReady()
		return self.obj and self.obj:IsValid()
	end

	function META:OnEvent(event, val)
		if not self.obj then
			self:QueueEvent(event, val)
			return
		end

		if event == "play" then
			self.obj:Play()
		elseif event == "stop" then
			self.obj:Stop()
		elseif event == "pause" then
			self.obj:Pause()
		elseif event == "remove" then
			self.obj:Remove()
		end

		if event == "SetGain" then
			self.obj:SetVolume(val)
		elseif event == "SetPitch" then
			self.obj:SetPlaybackRate(val)
		elseif event == "GetDuration" then
			return self.obj:GetLength()
		end
	end

	function META:OnLoad(path, where)
		if where ==  "DATA" then
			path = "../data/" .. path
		end

		local function on_load(snd, err, no_3d)
			if not IsValid(snd) then
				self:OnError(err .. ": " .. path)
				return
			end

			self:SetSoundObject(snd)

			local id = "audio_bass_" .. tostring(self)
			local loaded = false

			hook.Add("RenderScene", id, function(eye_pos)

				if not snd:IsValid() then
					hook.Remove("RenderScene", id)
					return
				end

				local f = 1

				local ent = self:GetEntity()

				if ent:IsValid() then
					if no_3d then
						f = math.Clamp(1 - ent:EyePos():Distance(eye_pos) / 500, 0, 1) ^ 1.5
					else
						snd:SetPos(ent:EyePos(), ent:IsPlayer() and ent:GetAimVector() or ent:GetForward())
					end
				end

				if not system.HasFocus() and GetConVar("snd_mute_losefocus"):GetBool() then
					snd:SetVolume(0)
				else
					snd:SetVolume(self:GetGain() * f)
				end

				if not loaded then
					if self.OnReady then self:OnReady() end
					loaded = true
				end
			end)
		end

		sound.PlayFile(path, "noplay noblock 3d", function(snd, _, err)
			if not IsValid(snd) then
				if err == "BASS_ERROR_EMPTY" or err == "BASS_ERROR_UNKNOWN" then
					sound.PlayFile(path, "noplay noblock", function(snd, _, err)
						on_load(snd, err, true)
					end)
					return
				end
			end

			on_load(snd, err, false)
		end)
	end

	audio.RegisterTemplate(META)
end

do
	local webaudio = requirex("webaudio")

	local META = audio.CreateTemplate("webaudio")

	function META:Panic()
		webaudio.Panic()
	end

	function META:OnEvent(event, val)
		if not self.obj then
			self:QueueEvent(event, val)
			return
		end

		if not self.obj:IsValid() then
			return
		end

		if event == "play" then
			self.obj:Play()
		elseif event == "stop" then
			self.obj:Stop()
		elseif event == "pause" then
			self.obj:Pause()
		elseif event == "remove" then
			self.obj:Remove()
		end

		if event == "SetLooping" then
			self.obj:SetMaxLoopCount(val)
		elseif event == "SetEntity" then
			self.obj:Set3D(true)
			self.obj:SetSourceEntity(val)
		elseif event == "SetGain" then
			self.obj:SetVolume(val)
		elseif event == "SetPitch" then
			self.obj:SetPlaybackRate(val)
		elseif event == "GetDuration" then
			return self.obj:GetLength()
		end
	end

	function META:IsReady()
		return self.obj and self.obj:IsValid() and self.obj:IsReady()
	end

	function META:OnLoad(path, where)
		if where == "DATA" then
			path = "data/" .. path
		end

		local snd = webaudio.CreateStream(path)
		snd.OnError = function(_, str)
			self:OnError(str)
		end
		snd.OnLoad = function()
			self:SetSoundObject(snd)

			if self.OnReady then
				self:OnReady()
			end
		end
	end

	audio.RegisterTemplate(META)
end

do
	local META = audio.CreateTemplate("createsound")

	function META:Panic()
		RunConsoleCommand("stopsound")
	end

	function META:OnEvent(event, val)
		if not self.obj then
			self:QueueEvent(event, val)
			return
		end

		if event == "play" then
			self.obj:Play()
		elseif event == "stop" then
			self.obj:Stop()
		elseif event == "pause" then
			self.obj:Stop()
		elseif event == "remove" then
			--self.obj:Remove()
		end

		if event == "SetGain" then
			self.obj:ChangeVolume(val, 0)
		elseif event == "SetPitch" then
			self.obj:ChangePitch(val, 0)
		elseif event == "GetDuration" then
			return SoundDuration(self.path)
		end
	end

	function META:IsReady() return self.obj end

	function META:OnLoad(path, where)
		if where == "DATA" then
			self:OnError("CreateSound does not support reading from data folder: " .. path)
			return
		end

		if path:StartWith("sound/") then
			path = path:sub(7)
		else
			path = "../" .. path
		end

		self.path = path

		self:SetSoundObject(CreateSound(self:GetEntity(), path))

		timer.Simple(0, function() if self.OnReady then self:OnReady() end end)
	end

	audio.RegisterTemplate(META)
end

function audio.CreateSoundFromInterface(interface)
	interface = interface or "webaudio"

	local self = setmetatable({}, audio.registered[interface])
	self.__gcproxy = newproxy(true)
	getmetatable(self.__gcproxy).__gc = function() self:OnRemove() end
	self.event_queue = {}

	return self
end

function audio.Panic()
	for name, interface in pairs(audio.registered) do
		interface.Panic()
	end
end

if me then
	local snd = audio.CreateSoundFromInterface("webaudio")
	--snd:SetPath("data/goluwa/data/downloads/cache/6546273^ogg.dat")
	snd:SetEntity(LocalPlayer())
	snd:SetPath("sound/npc/dog/dog_servo1.wav")
	snd:Play()
	snd.OnReady = function() print("ready!") end
end

return audio
