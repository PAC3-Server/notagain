if not system.IsLinux() then return end

local Tag = "pirates"

local pirates={}
local pwlist={}

local kickhim=false
hook.Add("CheckPassword",Tag,function(_, ip, svpw, pw)
	if pirates[ip] then
		pirates[ip]=false
	end

    kickhim = false
    if svpw and svpw:len() > 0 then return end
    if pw and pw:len()>0 then
        pwlist[ip]=pw
    end
end)

local function GenPW(ip)
    local r1=util.CRC(ip..'1')%11
    local r2=util.CRC(ip..'_')%11
    return  tostring(
        r1   +   r2),           'password '..
        r1..'+'..r2..' = ?'
end

local pirates_allow_all=CreateConVar("pirates_allow_all","0")
local pirates_block_all=CreateConVar("pirates_block_all","0")
local pirates_nofreeload=CreateConVar("pirates_nofreeload","0")

local function canjoin()

	if pirates_allow_all:GetBool() then return true end

	if pirates_nofreeload:GetBool() then return end

	local players,pirates=0,0
	for _,v in next,player.GetHumans() do
		players = players + 1

		if v.IsPirate and v:IsPirate() then
			pirates = pirates +1
		end

	end
	return players<10 and pirates<3
end

local kickip = ""
hook.Add("ForceAccept", Tag, function(ip, sid32)
	pirates[ip]=sid32 or true

	local pw,answ=GenPW(ip)
	local plpw=pwlist[ip]
	kickhim = false

	if pirates_block_all:GetBool() then return end

	if pw==plpw then
		Msg"Pirate PASS "print(sid32,pw)
	elseif canjoin() then
		--Msg"\nPirate Pass "print(sid32,pw)
	else
		--Msg"[Pirate] Kick "
		--if plpw and #plpw>0 then
		--	print(sid32..' Answered "'..(plpw or "")..'" ~= "'..tostring(pw)..'"'..
		--	" Task: ",answ)
		--else
		--	print("NOANS")
		--end
		kickhim = answ or "GO AWAY"
		kickip = ip
	end

	return true
end)

hook.Add("PlayerConnect",Tag,function(_, ip)
    pwlist[ip]=nil
end)

local kicks = setmetatable({},{__index=function() return 0 end})

gameevent.Listen("player_connect")

hook.Add("player_connect",Tag,function(dat)
    if not kickhim then return end

    local kick = kickhim
    kickhim = false

    local userid=dat.userid
    local sid=dat.networkid

    if kick then
		local nkicks = kicks[sid] + 1
		if sid and nkicks>5 then
			nkicks = 0
			local ip = kickip:match("(.+):%d-") or kickip:match("%d+%.%d+%.%d+%.%d+")
			if ip and #ip>0 then
				game.ConsoleCommand("addip 1 "..ip..'\n')
			else
				ErrorNoHalt("Tried to kick, but ip not found!?\n")
			end
		end
		kicks[sid] = nkicks
        game.ConsoleCommand("kickid "..userid..' '..tostring(kick)..'\n')
    end

end)

hook.Add("CheckProtocol",Tag,function(addr,ver)
	if ver == 22 then
		Msg"[Arr] "print(addr,"using old proto")
		return true
	end
end)

FindMetaTable("Player").IsPirate = function(self)
	return pirates[self]
end


local player_clones = _G.player_clones or {}
_G.player_clones = player_clones
local function AddPlayer(ply)
	if not gameserver or not gameserver.CreateUnauthenticatedUserConnection then return end
	local name = ply:Name()
	local id = ply:UserID()

	if player_clones[id] then return end

	local sid64 = gameserver.CreateUnauthenticatedUserConnection()
	if not sid64 or sid64:len()<4 then return end

	player_clones[id] = sid64

	gameserver.UpdateUserData(sid64,name,0)

end

local function RemovePlayer(ply)
	local sid64 = player_clones[ply:UserID()]
	if sid64 then
		gameserver.SendUserDisconnect(sid64)
	end
	player_clones[ply:UserID()] = nil
end


hook.Add("PlayerInitialSpawn", Tag, function(ply)

	local pirate = pirates[ply:IPAddress()]

	if pirate then
		pirates[ply] = true
		pirates[ply:IPAddress()] = nil
	end

	if pirate then
		if ply.SetNetData then
			ply:SetNetData("pirate",true)
		end

		local function pirate_cloner()

			if ply:IsValid() and ply:IsPlayer() and ply:IsPirate() then
				AddPlayer(ply)
			end

		end

		timer.Simple(0.5,pirate_cloner)


		print( tostring( ply ) .. " is a pirate!" )
	end

	hook.Run("PostPirateCheck", ply, tobool(pirate))

end)

hook.Add("EntityRemoved",Tag,function(ply)
	if ply:IsPlayer() then
		RemovePlayer(ply)
	end
end)

hook.Add("OnValidateAuthTicketResponse", Tag, function(_, num)
	if num == 2 then
		return 0
	end
end)
