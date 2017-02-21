local Tag = "Say"

if SERVER then
	util.AddNetworkString(Tag)
	local META = FindMetaTable('Player');
	function META:Say(string)
		net.Start(Tag)
			net.WriteString(string)
		net.Send(self)
	end
end

if CLIENT then
	net.Receive(Tag, function(len, ply)
		Say(net.ReadString())
	end)
end

function Say(string)
	string.Replace( string, '"', '\"' )
	if CLIENT then
		LocalPlayer():ConCommand("say \""..string.."\"")
	elseif SERVER then
		game.ConsoleCommand( "say "..string.."\n")	
	end
end