if not system.IsLinux() or XTERM_LOADED or game.IsDedicated() then
	return
end

if not pcall(require, "xterm") then
	return
end

local white = Color and Color(255,255,255,255) or {r=255,g=255,b=255,a=255}

XTERM_LOADED = true
unused_print = unused_print or print
local _print = unused_print
-- overwriting print because it is supposed to be white, but Garry fucked up
local MsgC=MsgC
local select=select
local Msg=Msg
print = function(...)
	for n=1,select('#',...) do
			if n>1 then
				Msg"\t"
			end
			local e = select(n,...)
			MsgC(white,e)
	end
	Msg"\n"
	if false then _print(...) end -- upvalues
end