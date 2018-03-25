local t = {
	mask = MASK_PLAYERSOLID,
}

local function IsStuck(ply)
	t.start = ply:GetPos()
	t.endpos = t.start
	t.filter = ply

	return util.TraceEntity(t, ply).StartSolid
end

local function LookAt(ply, pos)
	if isentity(pos) and IsValid(pos) then
		pos = pos:EyePos()
	end

	if pos == ply:EyePos() then return end
	ply:SetEyeAngles( (pos - ply:EyePos()):Angle() )
end

-- helper
local function SendPlayer( from, to )
	if from:IsPlayer() then
		if not from:Alive() then
			from:Spawn()
		end

		if not from:InVehicle() then
			from:ExitVehicle()
		end
	end

	local pos
	local ang
	local times=16

	if IsEntity(to) then

		if not to:IsInWorld() then
			return false
		end

		local anginc=360/times

		ang=to:GetVelocity():Length2DSqr()<1 and (to:IsPlayer() and to:GetAimVector() or to:GetForward()) or -to:GetVelocity()
		ang.z=0
		ang:Normalize()
		ang=ang:Angle()

		pos = to:GetPos()
	else
		pos = to
		ang = Angle(0,0,0)
	end

	local frompos = from:GetPos()

	local origy=ang.y

	for i=0,times do
		ang.y=origy+(-1)^i*(i/times)*180

		from:SetPos(pos+ang:Forward()*64+Vector(0,0,10))
		if not IsStuck(from) then return true end
	end

	return false
end

local function compare(a, b)
	if a == b then return true end
	if a:find(b, nil, true) then return true end
	if a:lower() == b:lower() then return true end
	if a:lower():find(b:lower(), nil, true) then return true end

	return false
end

aowl.AddCommand("goto|warp|go=location", function(ply, line, ent)
	ply.aowl_tpprevious = ply:GetPos()

	local oldpos = ply:GetPos() + Vector(0,0,32)

	if isstring(ent) then -- If a string was recieved check if the area was map defined first.
		if string.lower(ent) == "spawn" then
			ent = table.Random(ents.FindByClass("info_player_start")):GetPos()
		else
			local areas = MapDefine and MapDefine.Areas or {}

			if next(areas) and ent == "somewhere" then
				ent = table.Random(table.GetKeys(areas))
			end

			for area, data in next, areas do
				if compare(area, ent) then
					local refs = data.Refs
					local pos = Vector(0,0,0)

					if refs then
						pos.x = math.random(refs.XMin, refs.XMax)
						pos.y = math.random(refs.YMin, refs.YMax)

						-- Trying to find the floor.
						t.start = Vector(pos.x, pos.y, refs.ZMax)
						t.endpos = Vector(pos.x, pos.y, refs.ZMin)
						pos.z = ( util.TraceLine(t) ).HitPos.z
							
						ent = pos
						break
					end
				end
			end

			if not isvector(ent) then
				error('MapDefine: Location not found or is invalid.')
			end
		end
	end

	if IsEntity(ent) then
		local dir = ent:GetAngles()
		dir.p = 0
		dir.r = 0
		dir = dir:Forward() * -100

		if ent.NoGoto and not ply:IsSudo() then
			ply:ChatPrint('This entity has "goto" disabled please respect its privacy.')
			return
		end

		if ent:GetPos():DistToSqr(ply:GetPos()) < 256*256 and (not ply.IsStuck or not ply:IsStuck()) then
			LookAt(ply, ent)
			return
		end

		local ok = SendPlayer(ply, ent)

		if not ok then
			ply:SetPos(ent:GetPos() + dir)
			ply:DropToFloor()
		end
	else
		ply:SetPos(ent)
	end

	sound.Play("npc/dog/dog_footstep"..math.random(1,4)..".wav",oldpos)

	if ply.UnStuck then
		timer.Create(tostring(pl)..'unstuck',1,1,function()
			if IsValid(ply) then
				ply:UnStuck()
			end
		end)
	end

	LookAt(ply, ent)

	ply:EmitSound("buttons/button15.wav")
	ply:SetVelocity(-ply:GetVelocity())

	hook.Run("AowlTargetCommand", ply, "goto", ent)
end)

aowl.AddCommand("togglegoto|tgoto|tgo", function(ply, line)
	ply.NoGoto = ( not ply.NoGoto ) or nil
	ply:ChatPrint("Players may "..(ply.NoGoto and 'no longer "goto" you!' or 'now "goto" you!'))
end)

aowl.AddCommand("tp", function(pl)
	local start = pl:GetPos() + Vector(0,0,1)
	local pltrdat = util.GetPlayerTrace( pl )
	pltrdat.mask = bit.bor(CONTENTS_PLAYERCLIP,MASK_PLAYERSOLID_BRUSHONLY,MASK_SHOT_HULL)
	local pltr = util.TraceLine( pltrdat )

	local endpos = pltr.HitPos
	local wasinworld=util.IsInWorld(start)

	local diff=start-endpos
	local len=diff:Length()
	len=len>100 and 100 or len
	diff:Normalize()
	diff=diff*len
	--start=endpos+diff

	if not wasinworld and util.IsInWorld(endpos-pltr.HitNormal*120) then
		pltr.HitNormal=-pltr.HitNormal
	end
	start=endpos+pltr.HitNormal*120

	if math.abs(endpos.z-start.z)<2 then
		endpos.z=start.z
		--print"spooky match?"
	end

	local tracedata = {start=start,endpos=endpos}

	tracedata.filter = pl
	tracedata.mins = Vector( -16, -16, 0 )
	tracedata.maxs = Vector( 16, 16, 72 )
	tracedata.mask = bit.bor(CONTENTS_PLAYERCLIP,MASK_PLAYERSOLID_BRUSHONLY,MASK_SHOT_HULL)
	local tr = util.TraceHull( tracedata )

	if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
		tr = util.TraceHull( tracedata )
		tracedata.start=endpos+pltr.HitNormal*3

	end
	if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
		tr = util.TraceHull( tracedata )
		tracedata.start=pl:GetPos()+Vector(0,0,1)

	end
	if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
		tr = util.TraceHull( tracedata )
		tracedata.start=endpos+diff

	end
	if tr.StartSolid then return false,"unable to perform teleportation without getting stuck" end
	if not util.IsInWorld(tr.HitPos) and wasinworld then return false,"couldnt teleport there" end

	if math.abs(pl:GetVelocity().z) > 10 * 10 * math.sqrt(GetConVarNumber("sv_gravity")) then
		pl:EmitSound("physics/concrete/boulder_impact_hard".. math.random(1, 4) ..".wav")
		pl:SetVelocity(-pl:GetVelocity())
	end

	pl.aowl_tpprevious = pl:GetPos()

	pl:SetPos(tr.HitPos)
	pl:EmitSound"ui/freeze_cam.wav"
end)


aowl.AddCommand("send=players_alter,location", function(ply, line, players, where)
	for k, ent in pairs( players ) do
		ent.aowl_tpprevious = ent:GetPos()
		ent:SetPos( where )
	end
end)

aowl.AddCommand("gotoid=string_trim", function(ply, line, target)
	local function loading(s)
		ply:SendLua(string.format("local l=notification l.Kill'aowl_gotoid'l.AddProgress('aowl_gotoid',%q)",s))
	end

	local function kill(s,typ)
		if not IsValid(ply) then return false end
		ply:SendLua[[notification.Kill'aowl_gotoid']]
		if s then aowl.Message(ply,s,typ or 'error') end
	end

	local url
	local function gotoip(str)
		if not ply:IsValid() then return end
		local ip = str:match[[In%-Game.-Garry's Mod.-steam://connect/([0-9]+%.[0-9]+%.[0-9]+%.[0-9]+%:[0-9]+).-Join]]
		if ip then
			if co and co.serverinfo and serverquery then
				co(function()
					local info = co.serverinfo(ip)
					if not info or not info.name then return end
					aowl.Message(ply, ("server name: %q"):format(info.name), 'generic')
				end)
			end
			kill(string.format("found %q from %q", ip, target),"generic")
			aowl.Message(ply,'connecting in 5 seconds.. press jump to abort','generic')

			local uid = tostring(ply) .. "_aowl_gotoid"
			timer.Create(uid,5,1,function()
				hook.Remove('KeyPress',uid)
				if not IsValid(ply) then return end

				kill'connecting!'
				ply:Cexec("connect " .. ip)
			end)

			hook.Add("KeyPress", uid, function(_ply, key)
				if key == IN_JUMP and _ply == ply then
					timer.Remove(uid)
					kill'aborted gotoid!'

					hook.Remove('KeyPress',uid)
				end
			end)
		else
			kill(string.format('could not fetch the server ip from %q',target))
		end
	end
	local function gotoid()
		if not ply:IsValid() then return end

		loading'looking up steamid ...'

		http.Fetch(url, function(str)
			gotoip(str)
		end,function(err)
			kill(string.format('load error: %q',err or ''))
		end)
	end

	if tonumber(target) then
		url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(target)
		gotoid()
	elseif target:find("STEAM") then
		url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(util.SteamIDTo64(target))
		gotoid()
	else
		loading'looking up player ...'

		http.Post(string.format("http://steamcommunity.com/actions/Search?T=Account&K=%q", target:gsub("%p", function(char) return "%" .. ("%X"):format(char:byte()) end)), "", function(str)
			gotoip(str)
		end,function(err)
			kill(string.format('load error: %q',err or ''))
		end)
	end
end)

aowl.AddCommand("back=entity_alter|self", function(ply, line, ent)
	if not ent.aowl_tpprevious or not type( ent.aowl_tpprevious ) == "Vector" then
		return false, "Nowhere to send you"
	end

	local prev = ent.aowl_tpprevious

	ent.aowl_tpprevious = ent:GetPos()
	ent:SetPos( prev )

	hook.Run("AowlTargetCommand", ply, "back", ent)
end)

aowl.AddCommand("bring=player_alter", function(ply, line, ent)
	if ent:IsPlayer() then
		if not ent:Alive() then
			ent:Spawn()
		end

		if not ent:InVehicle() then
			ent:ExitVehicle()
		end
	end

	ent.aowl_tpprevious = ent:GetPos()

	local pos = ply:GetEyeTrace().HitPos + (ent:IsVehicle() and Vector(0, 0, ent:BoundingRadius()) or Vector(0, 0, 0))

	ent:SetPos(pos)

	local ang = (ply:EyePos() - ent:EyePos()):Angle()

	if ent:IsPlayer() then
		ang.r=0
		ent:SetEyeAngles(ang)
	elseif ent:IsNPC() then
		ang.r=0
		ang.p=0
		ent:SetAngles(ang)
	else
		ent:SetAngles(ang)
	end

	if ent.UnStuck then
		timer.Create(tostring(ent)..'unstuck!',1,1,function()
			if IsValid(ent) and IsStuck(ent) then
				ent:UnStuck()
			end
		end)
	end

	aowlMsg("bring", tostring(ply) .." <- ".. tostring(ent))
end)

aowl.AddCommand("spawn=players|player_alter|self", function(ply, line, ent)
	if type(ent) ~= "table" then ent = {ent} end

	for _, ent in ipairs(ent) do
		ent:Spawn()
		ent.aowl_tpprevious = ent:GetPos()
	end
end)

do
	hook.Add("PlayerDeath", "aowl_revive", function(ply)
		ply.aowl_predeathpos = ply:GetPos()
		ply.aowl_predeathangles = ply:GetAngles()
	end)

	hook.Add("PlayerSilentDeath", "aowl_revive", function(ply)
		ply.aowl_predeathpos = ply:GetPos()
		ply.aowl_predeathangles = ply:GetAngles()
	end)

	aowl.AddCommand("resurrect|respawn|revive=players_alter|self", function(ply, line, ent)
		if type(ent) ~= "table" and ent:Alive() then
			return false, "already alive"
		end

		ent = not istable(ent) and {ent}

		for _, ent in ipairs(ent) do
			ent:Spawn()

			if ent.aowl_predeathpos then
				ent:SetPos(ent.aowl_predeathpos)
			end

			if ent.aowl_predeathangles then
				ent:SetEyeAngles(ent.aowl_predeathangles)
			end
		end
	end)
end
