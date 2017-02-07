local Tag="AFKMon"
local Cmd='\5'..Tag
local MAX_AFK = CreateConVar("mp_afktime","35",{ FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_GAMEDLL },"Seconds until flagged as afk")
local LocalPlayer=LocalPlayer

local afktable = {}
local ignoreinput=false

function inp()
	ignoreinput=false
end

local function ModeChanged(pl,newmode)
	ignoreinput = true
	hook.Call('AFK',nil,pl,newmode)
	timer.Simple(0,inp)
end



-- Set AFK modes, trigger the hook, ensure mode cant be changed to same mode.
local function SetAFKMode(pl,afkmode)
	if afktable[pl] != afkmode then
		afktable[pl] = afkmode
		ModeChanged(pl,afkmode)
	--else -- how did this manage to happen? I don't care enough.
	--	ErrorNoHalt("AFK not changed: "..tostring(pl)..' N:'..tostring(afkmode))
	end
end



FindMetaTable("Player").IsAFK = function(s) return afktable[s] and afktable[s]!=0 or false end

if SERVER then
	-- TODO: Spamstop!!!
	local function SetAFK(pl,_,newmode)
		newmode=tonumber(newmode[1])
		if !newmode then return end

		SetAFKMode(pl,newmode)

	end
	concommand.Add(Cmd,SetAFK)

	-- Annoounce users afk info
	hook.Add('AFK',Tag,function(pl,newmode) 
		umsg.Start(Tag)
			umsg.Entity( pl )
			umsg.Char( newmode )
		umsg.End()
		if pl.SetNetData then
			pl:SetNetData(Tag,newmode)
		end
	end)

	concommand.Add("__refreshafk",function(pl) 
		for who,mode in pairs(afktable) do
			if IsValid(who) then
				umsg.Start(Tag,pl)
					umsg.Entity( who )
					umsg.Char( mode )
				umsg.End()
			end
		end
	end)
	
end 

if CLIENT then


	hook.Add('AFK','Console',function(pl,newmode) 

		if not IsValid( pl ) then return end

		Msg"[AFK] "
		if newmode==0 then 
			chat.AddText(Color(20,155,20),"●",Color(255,255,255)," [AFK]: "..pl:Name().." is no longer away.")
		else
			chat.AddText(Color(200,20,20),"●",Color(255,255,255)," [AFK]: "..pl:Name().." is away.")

		end

	end)

	-- Tell server we became AFK.
	hook.Add('AFK',Tag,function(pl,newmode) 
		if pl==LocalPlayer() then
			RunConsoleCommand('cmd',Cmd,tostring(newmode))
		end
	end)

----- Input tracking ----
	local Now=SysTime
	local last_input=Now()+5 -- mouse coords
	local last_focus = Now() + 5
	local function InputReceived()
		if ignoreinput then return end
		last_input=Now()
		--Msg"."
	end


	local last_mouse=Now()+5


	local oldmouse=1
	local mx,my= gui.MouseX,gui.MouseY
	local function Think()

		-- Check for mouse movement
		local newmouse=mx()+my()
		if newmouse != oldmouse then
			oldmouse = newmouse
			last_mouse=Now()
			--Msg"!"
		end
		if system.HasFocus() then
			last_focus = Now()
		end
	
		local max=MAX_AFK:GetFloat()
		local var=Now()-max
		if (last_mouse < var and last_input < var) or last_focus < var then
			if afktable[LocalPlayer()]!=1 then
				SetAFKMode(LocalPlayer(), 1 )
			end
			
		elseif afktable[LocalPlayer()]==1 then
			SetAFKMode(LocalPlayer(), 0 )
		end

	end 
	timer.Simple(10,function() -- waiting a bit
		timer.Create(Tag,0.2,0,Think)
	end)

	-- The following is for view input
	hook.Add( "KeyPress", Tag, InputReceived )
	hook.Add( "KeyRelease", Tag, InputReceived )
	hook.Add( "PlayerBindPress", Tag, InputReceived )

	do -- some hacky key checking
		local oldkeys =nil
		local old_y   =nil
		local last_32 = false
		local last_33 = false
		local last_27 = false
		local last_29 = false
		local last_31 = false
		local last_19 = false
		local last_11 = false
		local last_14 = false
		local last_15 = false
		local last_25 = false
		local last_79 = false
		local last_65 = false
		--local keyarray,newarray,lastarray ={},{},{}
		--for _,x in pairs{"KEY_A","KEY_E","KEY_I","KEY_O","KEY_U","KEY_Q","KEY_W","KEY_S","KEY_D"} do keyarray[x]=true lastarray[x]=false end
		local isdown=input.IsKeyDown
		local function CheckStuff(UCMD)

			if oldkeys!=UCMD:GetButtons() then
				InputReceived()
				oldkeys = UCMD:GetButtons() 
			end

			if old_y!=UCMD:GetMouseX( ) then
				InputReceived()
				old_y = UCMD:GetMouseX( )
			end

			-- Unrolled loop for maximum efficiency
			-- Checking only some keys so we don't bloat the game with these.
			if isdown(33)!=last_33 then 
				last_33 = isdown(33)
				InputReceived()
				return
			end
			if isdown(27)!=last_27 then 
				last_27 = isdown(27)
				InputReceived()
				return
			end
			if isdown(29)!=last_29 then 
				last_29 = isdown(29)
				InputReceived()
				return
			end
			if isdown(31)!=last_31 then 
				last_31 = isdown(31)
				InputReceived()
				return
			end
			if isdown(19)!=last_19 then 
				last_19 = isdown(19)
				InputReceived()
				return
			end
			if isdown(11)!=last_11 then 
				last_11 = isdown(11)
				InputReceived()
				return
			end
			if isdown(14)!=last_14 then 
				last_14 = isdown(14)
				InputReceived()
				return
			end
			if isdown(15)!=last_15 then 
				last_ = isdown(15)
				InputReceived()
				return
			end
			if isdown(25)!=last_25 then 
				last_25 = isdown(25)
				InputReceived()
				return
			end
			if isdown(32)!=last_32 then 
				last_32 = isdown(32)
				InputReceived()
				return
			end
			if isdown(79)!=last_79 then 
				last_79 = isdown(79)
				InputReceived()
				return
			end
			if isdown(65)!=last_65 then 
				last_65 = isdown(65)
				InputReceived()
				return
			end
		end
		hook.Add("CreateMove", Tag, CheckStuff)
	end

	-- Receive others afks
	usermessage.Hook(Tag,function(umsg)
		local pl = umsg:ReadEntity()
		if pl==LocalPlayer() then return end -- Oh shit, I'm wasting usermessages.
		local afkmode = umsg:ReadChar()
		SetAFKMode( pl, afkmode )
	end)
	timer.Simple(0,function() 		
		timer.Simple(2,function() 
			RunConsoleCommand("cmd","__refreshafk") 
		end) 
		timer.Simple(20,function() 
			RunConsoleCommand("cmd","__refreshafk") 
		end) 
	end)
	
end
