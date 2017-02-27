AddCSLuaFile()

if SERVER then
	API_TRANS_URL = "https://translation.googleapis.com/language/translate/v2"
	API_TRANS_KEY = file.Read("translation_key.txt")

	local LangCode = {
		["afrikaans"] = "af",
		["albanian"] = "sq",
		["amharic"] = "am",
		["arabic"] = "ar",
		["armenian"] = "hy",
		["azeerbaijani"] = "az",
		["basque"] = "eu",
		["belarusian"] = "be",
		["bengali"] = "bn",
		["bosnian"] = "bs",
		["bulgarian"] = "bg",
		["catalan"] = "ca",
		["cebuano"] = "ceb",
		["chichewa"] = "ny",
		["chinese simplified"] = "zh-CN",
		["chinese traditional"] = "zh-TW",
		["corsican"] = "co",
		["croatian"] = "hr",
		["czech"] = "cs",
		["danish"] = "da",
		["dutch"] = "nl",
		["english"] = "en",
		["esperanto"] = "eo",
		["estonian"] = "et",
		["filipino"] = "tl",
		["finnish"] = "fi",
		["french"] = "fr",
		["frisian"] = "fy",
		["galician"] = "gl",
		["georgian"] = "ka",
		["german"] = "de",
		["greek"] = "el",
		["gujarati"] = "gu",
		["haitian creole"] = "ht",
		["hausa"] = "ha",
		["hawaiian"] = "haw",
		["hebrew"] = "iw",
		["hindi"] = "hi",
		["hmong"] = "hmn",
		["hungarian"] = "hu",
		["icelandic"] = "is",
		["igbo"] = "ig",
		["indonesian"] = "id",
		["irish"] = "ga",
		["italian"] = "it",
		["japanese"] = "ja",
		["javanese"] = "jw",
		["kannada"] = "kn",
		["kazakh"] = "kk",
		["khmer"] = "km",
		["korean"] = "ko",
		["kurdish"] = "ku",
		["kyrgyz"] = "ky",
		["lao"] = "lo",
		["latin"] = "la",
		["latvian"] = "lv",
		["lithuanian"] = "lt",
		["luxembourgish"] = "lb",
		["macedonian"] = "mk",
		["malagasy"] = "mg",
		["malay"] = "ms",
		["malayalam"] = "ml",
		["maltese"] = "mt",
		["maori"] = "mi",
		["marathi"] = "mr",
		["mongolian"] = "mn",
		["burmese"] = "my",
		["nepali"] = "ne",
		["norwegian"] = "no",
		["pashto"] = "ps",
		["persian"] = "fa",
		["polish"] = "pl",
		["portuguese"] = "pt",
		["punjabi"] = "ma",
		["romanian"] = "ro",
		["russian"] = "ru",
		["samoan"] = "sm",
		["scots gaelic"] = "gd",
		["serbian"] = "sr",
		["sesotho"] = "st",
		["shona"] = "sn",
		["sindhi"] = "sd",
		["sinhala"] = "si",
		["slovak"] = "sk",
		["slovenian"] = "sl",
		["somali"] = "so",
		["spanish"] = "es",
		["sundanese"] = "su",
		["swahili"] = "sw",
		["swedish"] = "sv",
		["tajik"] = "tg",
		["tamil"] = "ta",
		["telugu"] = "te",
		["thai"] = "th",
		["turkish"] = "tr",
		["ukrainian"] = "uk",
		["urdu"] = "ur",
		["uzbek"] = "uz",
		["vietnamese"] = "vi",
		["welsh"] = "cy",
		["xhosa"] = "xh",
		["yiddish"] = "yi",
		["yoruba"] = "yo",
		["zulu"] = "zu",
	}
	
	function ConvertLang( str )
		str = string.lower( str )
		
		if str == "auto" then
			return ""
		end
	
		for k, v in pairs( LangCode ) do
			if v == str then
				return str
			end
		
			if string.StartWith( k, str ) then
				return v
			end
		end
	end

	function translate( sentence, from, to, callback )
		from = ConvertLang( from )
		to = ConvertLang( to )

		http.Post(API_TRANS_URL,
		{
			key = API_TRANS_KEY,
			source = from,
			target = to,
			q = sentence
		},
		
		function( res )
			local tab = util.JSONToTable(res)
			
			if tab.data then
				callback(tab.data.translations[1].translatedText)
				return
			end
			callback(false)
		end,
		function( err )
			callback(false)
		end
		)
	end

	util.AddNetworkString( "s2c_translate" )

	aowl.AddCommand( {"tr", "translate"}, function( player, line, from, to, sentence )
		translate( sentence, from, to, function( data )
			if data then
				net.Start( "s2c_translate" )
				net.WriteString( data ) 
				net.Broadcast()
			else
				aowl.Message( player, "Translation error", "error" )
			end
		end )
	end)
else
	net.Receive( "s2c_translate", function()
		local data = net.ReadString()
		
		chat.AddText(
		Color(1, 64, 202), "T",
		Color(221, 24, 18), "r",
		Color(252, 202, 3), "a",
		Color(1, 64, 202), "n",
		Color(22, 166, 30), "s",
		Color(221, 24, 18), "l",
		Color(1, 64, 202), "a",
		Color(221, 24, 18), "t",
		Color(252, 202, 3), "e",
		color_white, ": ",
		data)
	end )
end