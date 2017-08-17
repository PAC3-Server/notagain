if not system.IsLinux() or XTERM_LOADED ~= false or game.IsDedicated() then
	return
end

local ok, err = pcall(require, "xterm")
if not ok then return end

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
