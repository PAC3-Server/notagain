local ascii = {
	
	{
	Ascii = "\n ____ _____ _______ _____ _    _    __  __  ____  _____  ______    \n"..
	"|  _ \\_   _|__   __/ ____| |  | |  |  \\/  |/ __ \\|  __ \\|  ____| \n"..
	"| |_| || |    | | | |    | |__| |  | \\  / | |  | | |  | | |__       \n"..
	"|  _ < | |    | | | |    |  __  |  | |\\/| | |  | | |  | |  __|      \n"..
	"| | | || |    | | | |    | |  | |  | |  | | |  | | |  | | |          \n"..
	"| |_| || |_   | | | |____| |  | |  | |  | | |__| | |__| | |____      \n"..
	"|____/_____|  |_| \\______|_|  |_|  |_|  |_|\\____/|_____/|______|   \n",
	Sentence = "got bitched",
	},

	{
	Ascii = "\n ____          _   _  \n"..
	"|  _ \\   /\\   | \\ | |\n"..
	"| |_) | /  \\  |  \\| | \n"..
	"|  _ < / /\\ \\ | . ` | \n"..
	"| |_) / ____ \\| |\\  | \n"..
	"|____/_/    \\_\\_| \\_|\n",
	Sentence = "got banni'd",
	},

	{
	Ascii = "\n      _ _    _  _____ _______ _____ _____ ______  \n"..
	"     | | |  | |/ ____|__   __|_   _/ ____|  ____|   \n"..
	"     | | |  | | (___    | |    | || |    | |__      \n"..
	" _   | | |  | |\\___ \\   | |    | || |    |  __|   \n"..
	"| |__| | |__| |____) |  | |   _| || |____| |____    \n"..
	" \\____/ \\____/|_____/   |_|  |_____\\_____|______|\n",
	Sentence = "got crucified",
	},

	{
	Ascii = "\n        __       \n"..
	"  	    /  \\      	\n"..
	"       |  |	  	\n"..
	"       |  |      	\n"..
	"     __|  |__    	\n"..
	"    /  |  |  \\__ 	\n"..
	"  __|  |  |  |  |	\n"..
	" /  /        |  |	\n"..
	" |              |	\n"..
	" \\              |	\n"..
	"  \\             /	\n"..
	"   \\___________/  \n",
	Sentence = "got told to fuck off",
	},

	{
	Ascii = "\n	       ___________    ____      	\n"..
	"    ______/   \\__//   \\__/____\\		\n"..
	"  _/   \\_/  :           //____\\\\	\n"..
	" /|      :  :  ..      /        \\		\n"..
	"| |     ::     ::      \\        /		\n"..
	"| |     :|     ||     \\ \\______/		\n"..
	"| |     ||     ||      |\\  /  |		\n"..
	" \\|     ||     ||      |   / | \\		\n"..
	"  |     ||     ||      |  / /_\\ \\  	\n"..
	"  | ___ || ___ ||      | /  /    \\ 	\n"..
	"   \\_-_/  \\_-_/ | ____ |/__/      \\	\n"..
	"                _\\_--_/    \\      /	\n"..
	"               /____             /		\n"..
	"              /     \\           /		\n"..
	"              \\______\\_________/		\n",
	Sentence = "joined the army and died as a trash",
	},

}

local GetRandBanAscii = function()
	return ascii[math.random(1,#ascii)]
end

aowl.AsciiOnBanAndKick = true

hook.Add("AowlTargetCommand","AsciiOnBanKick",function(ply,type,ent,reason)
	if aowl.AsciiOnBanAndKick then
		if type == "ban" or type == "kick" then
			local tbl = GetRandBanAscii()
			MsgC(Color(244,66,66),tbl.Ascii)
			MsgC(Color(244,66,66),ent:GetName(),Color(255,255,255)," "..tbl.Sentence.." ("..type.." by ",Color(173, 244, 66),ply:GetName(),Color(255,255,255),")\n")
			MsgC(Color(244,66,66),"Reason ",Color(175,175,175),"⮞⮞",Color(255,255,255)," "..(reason or "No reason was provided.").."\n")
		end
	end
end)
