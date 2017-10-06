AddCSLuaFile()

local tag = "trans"
trans = trans or {}

trans.error = {}
trans.error.LangConvert = 1
trans.error.InvaildJson = 2
trans.error.HttpRequest = 3

trans.error._Message = {
	[trans.error.LangConvert] = "Language Convert Error",
	[trans.error.InvaildJson] = "Invailed Json",
	[trans.error.HttpRequest] = "Bad request"
}

if SERVER then
	trans.transUrl = "https://translation.googleapis.com/language/translate/v2"
	trans.detectUrl = "https://translation.googleapis.com/language/translate/v2/detect"
	trans.Key = file.Read("translate_key.txt")

	util.AddNetworkString( "s2c_" .. tag )
	
	trans.langs = {
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
	
	function string.lang( str )
		for k, v in pairs( trans.langs ) do
			if v == str then
				return v
			end
		end
		
		for k, v in pairs( trans.langs ) do
			if k:StartWith( str ) then
				return v
			end
		end
	
		return false
	end
	
	function trans.Error( code )
		MsgC( Color( 255, 0, 0 ), ("[Translate Error] %s\n"):format( trans.error._Message[code] ) )
	end
	
	function trans.detect( str, success, failed )
		local data = {
			key = trans.Key,
			q = str
		}
		
		local function _success( body )
			local tab = util.JSONToTable( body )
			
			if ( tab ) then
				success( tab.data.detections[1][1].language )
			else
				trans.Error( trans.error.InvaildJson )
				if failed then failed( trans.error.InvaildJson ) end
			end
		end
		
		local function _failed( err )
			trans.Error( trans.error.HttpRequest )
			if failed then failed( trans.error.HttpRequest ) end
		end
	
		http.Post(trans.detectUrl, data, _success, _failed)
	end
	
	function trans.to( str, target, success, failed )
		target = target:lang()

		local function _success( body )
			local tab = util.JSONToTable( body )
			
			if ( tab ) then
				success( tab.data.translations[1].translatedText )
			else
				trans.Error( trans.error.InvaildJson )
				if failed then failed( trans.error.InvaildJson ) end
			end
		end
		
		local function _failed( err )
			trans.Error( trans.error.HttpRequest )
			if failed then failed( trans.error.HttpRequest ) end
		end
		
		if ( target ) then
			local data = {
				key = trans.Key,
				target = target,
				q  = str
			}
		
			http.Post( trans.transUrl, data, _success, _failed )
		else
			if failed then failed( trans.error.LangConvert ) end
			trans.Error( trans.error.LangConvert )
		end
	end
	
	aowl.AddCommand("tr|translate=string,string_rest", function( player, line, to, sentence )
		trans.to( sentence, to, function( text )
			net.Start( "s2c_" .. tag )
			net.WriteString( text )
			net.Broadcast()
		end, function( code )
			aowl.Message( player, "Translation error: " .. trans.error._Message[code], "error" )
		end )
	end)
else
	net.Receive( "s2c_" .. tag, function()
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
