local chat = _G.chat or {}

local META = FindMetaTable("Player")

function META:IsTyping()
	return self:GetNW2Bool("chat_istyping")
end

if CLIENT then

	local suppress = false

	hook.Add("PlayerBindPress", "chat", function(ply, bind, status)
		if bind == "messagemode" or bind == "messagemode2" then
			local team_only = bind == "messagemode2"
			suppress = true
			if hook.Run("StartChat", team_only) ~= true then
				chat.Open(team_only and 0 or 1)
			end
			suppress = false
			return true
		end
	end)

	hook.Add("StartChat", "chat", function()
		if suppress then return end
		return true
	end)

	-- this can only be used by one chatbox
	-- then the chatbox has to call ie hook.Run("ChatHUDAddText", args)
	-- for others to use
	chat._AddText = chat._AddText or chat.AddText
	function chat.AddText(...)
		if hook.Run("ChatAddText", ...) ~= false then
			return chat._AddText(...)
		end
	end

	chat._GetChatBoxSize = chat._GetChatBoxSize or chat.GetChatBoxSize
	function chat.GetChatBoxSize(...)
		if hook.Run("ChatGetChatBoxPos", ...) ~= false then
			return chat._GetChatBoxPos(...)
		end
	end

	chat._GetChatBoxSize = chat._GetChatBoxSize or chat.GetChatBoxSize
	function chat.GetChatBoxSize(...)
		if hook.Run("ChatGetChatBoxSize", ...) ~= false then
			return chat._GetChatBoxSize(...)
		end
	end

	chat._ChatOpen = chat._ChatOpen or chat.Open
	function chat.Open(team_chat)
		net.Start("chat_istyping", true)
			net.WriteBool(true)
		net.SendToServer()

		if hook.Run("ChatOpenChatBox", team_chat == 1) == false then
			return true
		end

		return chat._ChatOpen(team_chat)
	end

	chat._ChatClose = chat._ChatClose or chat.Close
	function chat.Close(...)
		net.Start("chat_istyping", true)
			net.WriteBool(false)
		net.SendToServer()

		if hook.Run("ChatCloseChatBox", ...) ~= false then
			hook.Run("FinishChat")
			chat.TextChanged("")
			return chat._ChatClose(...)
		end
	end

	function chat.TextChanged(str)
		hook.Run("ChatTextChanged", str)
	end

	function chat.Autocomplete(str)
		local res = hook.Run("OnChatTab", str)

		return res
	end

	net.Receive("chat_say", function()
		local ply = net.ReadEntity()
		local str = net.ReadString()
		local team_only = net.ReadBool()

		chat.Say(ply, str, team_only)
	end)

	function chat.SayServer(str, team_only)
		net.Start("chat_say", true)
			net.WriteString(str)
			net.WriteBool(team_only)
		net.SendToServer()
	end

	concommand.Add("say2", function(_,_,_,str)
		chat.SayServer(str)
	end)

	function chat.Say(ply, str, team_only)
		if hook.Run("OnPlayerChat", ply, str, team_only, not ply:Alive()) ~= true then
			chat.AddText(ply, color_white, ": ", str)
		end
	end

	--[[
	local function test(event)
		hook.Add(event, "test", function(...) print(debug.traceback()) print(event, ...) end)
	end
	test"StartChat"
	test"FinishChat"
	test"ChatTextChanged"
	test"ChatText"
	test"OnPlayerChat"
	]]
end

if SERVER then
	util.AddNetworkString("chat_say")
	util.AddNetworkString("chat_istyping")

	net.Receive("chat_say", function(len, ply)
		local str = net.ReadString()
		local team_only = net.ReadBool()
		if str ~= "" then
			chat.Say(ply, str, team_only)
		end
	end)

	net.Receive("chat_istyping", function(len, ply)
		local b = net.ReadBool()
		ply:SetNW2Bool("chat_istyping", b)
	end)

	function chat.Say(ply, str, team_only)
		ply = ply or NULL

		local res = hook.Run("PlayerSay", ply, str, false)

		if res == "" then return end

		net.Start("chat_say", true)
			net.WriteEntity(ply)
			net.WriteString(res or str)
			net.WriteBool(team_only)
		net.Broadcast()
	end

	function META:Say(str, b)
		chat.Say(self, str)
	end
end