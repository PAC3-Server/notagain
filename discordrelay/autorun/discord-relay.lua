if SERVER then
	include( "discordrelay/relay.lua" )
	AddCSLuaFile("discordrelay/cl_relay.lua")
end

if CLIENT then
	include("discordrelay/cl_relay.lua")
end