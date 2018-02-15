local jspeak = {}

local speaking_entities = {}

local function calc_queue(ent, play_next_now)
	if ent.speaker_sound_queue and #ent.speaker_sound_queue > 0 then
		ent.speaker_next_sound = ent.speaker_next_sound or 0

		if play_next_now or ent.speaker_next_sound < RealTime() then

			-- stop any previous sounds
			if ent.speaker_current_sound then
				ent.speaker_current_sound:Stop()
			end

			-- remove and get the first sound from the queue
			local data = table.remove(ent.speaker_sound_queue, 1)

			if data.snd and data.pitch then
				data.snd:SetSoundLevel(data.soundlevel)
				data.snd:PlayEx(data.volume, data.pitch)

				-- make it so we can hook onto when a sound is played for effects
				hook.Run("SpeakerSoundPlayed", ent, data.path, data.pitch, data.duration, data.snd)

				-- store the sound so we can stop it before we play the next sound
				ent.speaker_current_sound = data.snd
			end

			-- store when to play the next sound
			ent.speaker_next_sound = RealTime() + data.duration
		end
	else
		ent.speaker_sound_queue = nil
		ent.speaker_next_sound = nil
		if ent.speaker_current_sound then
			ent.speaker_current_sound:Stop()
		end
		ent.speaker_current_sound = nil

		speaking_entities[ent:EntIndex()] = nil
	end
end

local function think()
	for key, ent in pairs(speaking_entities) do
		if ent:IsValid() then
			calc_queue(ent)
		else
			speaking_entities[key] = nil
		end
	end

	if not next(speaking_entities) then
		jrpg.RemoveHook("Think", "jspeak")
	end
end

local pause_sounds =
{
	["."] = true,
	["!"] = true,
	["?"] = true,
}


local function queue_sound(ent, path, pitch, volume, soundlevel, cutoff)
	local queue = ent.speaker_sound_queue or {}

	if pause_sounds[path] then
		table.insert(
			queue,
			{
				duration = 0.5,
			}
		)
	else
		table.insert(
			queue,
			{
				snd = CreateSound(ent, path),
				pitch = pitch,
				path = path,
				soundlevel = soundlevel,
				volume = volume,

				-- get the sound length of the sound and scale it with the pitch above
				-- the sounds have a little empty space at the end so subtract 0.05 seconds from their time
				duration = (cutoff < 0 and -cutoff) or (SoundDuration(path) * (pitch / 100) - 0.05 - cutoff),
			}
		)
	end

	ent.speaker_sound_queue = queue
end

-- makes the fairy talk without using a real language
-- it's using sounds from a zelda game which does the same thing
function jspeak.PlayPhrase(ent, text, list, pitch, volume, soundlevel, cutoff)
	if type(list) == "string" then
		list = jspeak.voices[list]
	end

	list = list or jspeak.voices.metrocop
	pitch = pitch or 100
	volume = volume or 1
	soundlevel = soundlevel or 90

	text = text:lower()
	text = text .. " "

	-- split the sentence up in chunks
	for chunk in (" " .. text .. " ."):gsub("%p", " %1 "):gmatch("(.-)[%s]") do
		if chunk:Trim() ~= "" then
			if pause_sounds[chunk] then
				queue_sound(ent, chunk)
			else
				-- this will use each chunk as random seed to make sure it picks the same sound for each chunk every time
				local crc = util.CRC(chunk)
				local path = list[1 + crc%#list]

				-- randomize pitch a little, makes it sound less static

				local pitch = pitch

				if type(pitch) == "number" then
					pitch = pitch + math.Rand(-4, 4)
				elseif type(pitch) == "table" then
					pitch = math.Rand(pitch.min or pitch[1], pitch.max or pitch[2])
				else
					pitch = 100 + math.Rand(-4, 4)
				end

				pitch = pitch + (crc%1 == 0 and crc%10 or -crc%10)

				local cutoff = cutoff

				if not cutoff then
					cutoff = (-0.25 * (1 + (#chunk / 10))) / 1.25
				end



				queue_sound(ent, path, pitch, volume, soundlevel, cutoff)
			end
		end
	end

	if not next(speaking_entities) then
		jrpg.AddHook("Think", "jspeak", think)
	end

	speaking_entities[ent:EntIndex()] = ent
end

function jspeak.StopSpeaking(ent)
	if ent.speaker_current_sound then
		ent.speaker_current_sound:Stop()
	end
	ent.speaker_sound_queue = {}
	ent.speaker_next_sound = 0
end

do
	-- add some voices
	local voices = {}

	local function add_voices(path, name)
		local tbl = {}

		for _, v in pairs(file.Find("sound/" .. path .. "*.wav", "GAME")) do
			if
				not v:lower():find("pain") and
				not v:lower():find("hurt") and
				not v:lower():find("die") and
				not v:lower():find("death")
			then
				table.insert(tbl, path .. v)
			end
		end

		voices[name] = tbl
	end

	add_voices("npc/metropolice/vo/", "metrocop")
	add_voices("npc/overwatch/radiovoice/", "overwatch")
	add_voices("vo/npc/female01/", "female")
	add_voices("vo/npc/male01/", "male")
	add_voices("vo/npc/alyx/", "alyx")
	add_voices("vo/npc/barney/", "barney")
	add_voices("vo/npc/vortigaunt/", "vortigaunt")

	voices.radio_noise = {}
	for i = 1, 15 do
		voices.radio_noise[i] = "ambient/levels/prison/radio_random"..i..".wav"
	end

	voices.seagull =
	{
		"ambient/creatures/seagull_idle1.wav",
		"ambient/creatures/seagull_idle2.wav",
		"ambient/creatures/seagull_idle3.wav",
		"ambient/creatures/seagull_pain1.wav",
		"ambient/creatures/seagull_pain2.wav",
		"ambient/creatures/seagull_pain3.wav",
	}

	voices.rat =
	{
		"ambient/creatures/rats1.wav",
		"ambient/creatures/rats2.wav",
		"ambient/creatures/rats3.wav",
		"ambient/creatures/rats4.wav",

	}

	voices.pigeon =
	{
		"ambient/creatures/pigeon_idle1.wav",
		"ambient/creatures/pigeon_idle2.wav",
		"ambient/creatures/pigeon_idle3.wav",
		"ambient/creatures/pigeon_idle4.wav",

	}

	voices.flies =
	{
		"ambient/creatures/flies1.wav",
		"ambient/creatures/flies2.wav",
		"ambient/creatures/flies3.wav",
		"ambient/creatures/flies4.wav",
		"ambient/creatures/flies5.wav",
	}

	voices.fast_zombie =
	{
		"npc/fast_zombie/gurgle_loop1.wav",
		"npc/fast_zombie/idle1.wav",
		"npc/fast_zombie/idle2.wav",
		"npc/fast_zombie/idle3.wav",
		"npc/fast_zombie/leap1.wav",
		"npc/fast_zombie/wake1.wav",
	}

	voices.crow =
	{
		"npc/crow/alert2.wav",
		"npc/crow/alert3.wav",
		"npc/crow/pain1.wav",
		"npc/crow/pain2.wav",
	}

	voices.big_robot =
	{
		"npc/dog/dog_alarmed1.wav",
		"npc/dog/dog_alarmed3.wav",
		"npc/dog/dog_angry1.wav",
		"npc/dog/dog_angry2.wav",
		"npc/dog/dog_angry3.wav",
		"npc/dog/dog_playfull1.wav",
		"npc/dog/dog_playfull2.wav",
		"npc/dog/dog_playfull3.wav",
		"npc/dog/dog_playfull4.wav",
		"npc/dog/dog_playfull5.wav",
	}

	voices.skeleton = {
		--"chatsounds/autoadd/goldeneye007soundfont/marimbab3.ogg",
		--"chatsounds/autoadd/goldeneye007soundfont/marimbae1.ogg",
		"chatsounds/autoadd/cartoon_sfx/shiveringskeleton.ogg",
	}

	voices.bird = {}
	for i = 1, 7 do voices.bird[i] = "ambient/levels/coast/coastbird"..i..".wav" end

	voices.robot = {}
	for i = 1, 6 do voices.robot[i] = "ambient/levels/canals/headcrab_canister_ambient"..i..".wav" end

	voices.terminal = {}
	for i = 1, 4 do voices.terminal[i] = "ambient/machines/combine_terminal_idle"..i..".wav" end

	voices.bird_swamp = {}
	for i = 1, 6 do voices.bird_swamp[i] = "ambient/levels/canals/swamp_bird"..i..".wav" end


	voices.bird_coast = {}
	for i = 1, 7 do voices.bird_coast[i] = "ambient/levels/coast/coastbird"..i..".wav" end

	voices.servo = {}
	for i = 1, 12 do
		if
			i ~= 4 and
			i ~= 9 and
			i ~= 11
		then
			table.insert(voices.servo,  "npc/dog/dog_servo"..i..".wav" )
		end
	end

	voices.zombie = {}
	for i = 1, 14 do voices.zombie[i] = "npc/zombie/zombie_voice_idle"..i..".wav" end

	voices.cat = {}
	for i = 1, 3 do voices.cat[i] = "items/halloween/cat0"..i..".wav" end

	jspeak.voices = voices

	function jspeak.GetVoices()
		return jspeak.voices
	end
end

if me then
	_G.speaker.PlayPhrase(me, "asdaw idaj iwajdi ajwdi ajwdijawidj awd? akidkwaid iawd.wa md aiwmd a,d awdik aid. awdwd", "bird")
end