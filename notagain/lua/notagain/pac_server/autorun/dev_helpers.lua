function Say(string)
	string.Replace( string, '"', '\"' )
	if CLIENT then
		LocalPlayer():ConCommand("say \""..string.."\"")
	elseif SERVER then
		game.ConsoleCommand( "say "..string.."\n")	
	end
end