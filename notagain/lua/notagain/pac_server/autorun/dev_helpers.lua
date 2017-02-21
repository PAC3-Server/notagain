function Say(string)
	if CLIENT then
		RunConsoleCommand("say", string)
	elseif SERVER then
		game.ConsoleCommand("say "..string.."\n")	
	end
end