if engine.ActiveGamemode() ~= "sandbox" then return end

local added = {}

local real_hook_Add = hook.Add
local real_hook_Remove = hook.Add

local hook = {Add = function(event, id, func)
	table.insert(added, {event, id, func})
end}

local function ENABLE_HOOKS(b)
	if b then
		for i,v in ipairs(added) do
			real_hook_Add(unpack(v))
		end
	else
		for i,v in ipairs(added) do
			real_hook_Remove(v[1], v[2])
		end
	end
end

local HOOK_REF = 0

AddCSLuaFile()

for i = 1, 2 do
	util.PrecacheSound( "ambient/machines/slicer"..i..".wav" )
end
for i = 2, 4 do
	util.PrecacheSound( "physics/body/body_medium_break"..i..".wav" )
end
for i = 5, 7 do
	util.PrecacheSound( "physics/body/body_medium_impact_soft"..i..".wav" )
end
for i = 7, 9 do
	util.PrecacheSound( "vo/npc/male01/pain0"..i..".wav" )
end
for i = 2, 4 do
	util.PrecacheSound( "physics/wood/wood_strain"..i..".wav" )
end
for i = 2, 3 do
	util.PrecacheSound( "weapons/357/357_fire"..i..".wav" )
end
util.PrecacheSound( "npc/antlion_guard/shove1.wav" )

util.PrecacheModel( "models/dav0r/camera.mdl" )

local RagdollFight = _G.RagdollFight or {}
_G.RagdollFight = RagdollFight

if SERVER then
	resource.AddFile( "materials/pac_server/ragdollfight_arena.png" )

	RagdollFight.Ragdolls = {}
end

RAGDOLL_STANCE_IDLE = 0
RAGDOLL_STANCE_ATTACK = 1
RAGDOLL_STANCE_JUMP_ATTACK = 2
RAGDOLL_STANCE_GRAB = 3
RAGDOLL_STANCE_CROUCH_ATTACK = 4
RAGDOLL_STANCE_GRAB_IDLE = 5
RAGDOLL_STANCE_GRAB_JUMP = 6
RAGDOLL_STANCE_GRAB_ATTACK_SLAM = 7
RAGDOLL_STANCE_GRAB_ATTACK_THROW = 8
RAGDOLL_STANCE_GRAB_ATTACK_BACKTHROW = 9
RAGDOLL_STANCE_JUMP_ATTACK_SPRINT = 10
RAGDOLL_STANCE_BLOCK = 11
RAGDOLL_STANCE_SLIDE = 12
RAGDOLL_STANCE_TAUNT = 13

RAGDOLL_BLOCK_NORMAL = 1
RAGDOLL_BLOCK_CROUCH = 2

RAGDOLL_ATTACK_NORMAL = 1
RAGDOLL_ATTACK_CROUCH = 2
RAGDOLL_ATTACK_ANY = 3

RAGDOLL_DAMAGE_FISTS = 3
RAGDOLL_DAMAGE_LEG = 4
RAGDOLL_DAMAGE_LEG_HEAVY = 7
RAGDOLL_DAMAGE_LEG_SLIDE = 7
RAGDOLL_DAMAGE_GRAB_THROW = 6--13
RAGDOLL_DAMAGE_XRAY = 35

RAGDOLL_POWERUP_BREAKER = 1
RAGDOLL_POWERUP_HEAVYATTACK = 2
RAGDOLL_POWERUP_XRAY = 3

RAGDOLL_XRAY_ATTACKER = 1
RAGDOLL_XRAY_VICTIM = 2

local bones = {
	"ValveBiped.Bip01_Pelvis",
	"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_R_UpperArm",
	"ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_R_Calf",
	"ValveBiped.Bip01_R_Thigh",
}

local fingerbones = {
	{
		"ValveBiped.Bip01_L_Finger1",
		"ValveBiped.Bip01_L_Finger11",
		"ValveBiped.Bip01_L_Finger12",
		"ValveBiped.Bip01_L_Finger2",
		"ValveBiped.Bip01_L_Finger21",
		"ValveBiped.Bip01_L_Finger22",
		"ValveBiped.Bip01_L_Finger3",
		"ValveBiped.Bip01_L_Finger31",
		"ValveBiped.Bip01_L_Finger32",
		"ValveBiped.Bip01_L_Finger4",
		"ValveBiped.Bip01_L_Finger41",
		"ValveBiped.Bip01_L_Finger42",
	},
	{
		"ValveBiped.Bip01_R_Finger1",
		"ValveBiped.Bip01_R_Finger11",
		"ValveBiped.Bip01_R_Finger12",
		"ValveBiped.Bip01_R_Finger2",
		"ValveBiped.Bip01_R_Finger21",
		"ValveBiped.Bip01_R_Finger22",
		"ValveBiped.Bip01_R_Finger3",
		"ValveBiped.Bip01_R_Finger31",
		"ValveBiped.Bip01_R_Finger32",
		"ValveBiped.Bip01_R_Finger4",
		"ValveBiped.Bip01_R_Finger41",
		"ValveBiped.Bip01_R_Finger42",
	}
}

RagdollFight.Stances = {}


RagdollFight.Stances[ RAGDOLL_STANCE_IDLE ] = {
	{
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 0.18754577636719, 0.030773162841797, 11.548797607422 ), ang = Angle( -88.124938964844, -64.663650512695, -18.989500045776 ), ignore = true },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 2.4561614990234, -7.6287784576416, 20.275451660156 ), ang = Angle( 58.603122711182, -2.8904676437378, -150.09803771973 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 0.83984375, 7.5915203094482, 20.821434020996 ), ang = Angle( 41.015941619873, 5.7208156585693, -51.06702041626 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 10.015625, 8.7433738708496, 13.218711853027 ), ang = Angle( -61.010738372803, -91.254035949707, -19.907287597656 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 9.3375701904297, 2.7635383605957, 23.106872558594 ), ang = Angle( -67.280731201172, -67.310134887695, 11.927015304565 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 9.0903015136719, -8.2024211883545, 10.101448059082 ), ang = Angle( -24.576791763306, 69.557815551758, -118.65972137451 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 11.607330322266, 2.0846729278564, 14.996307373047 ), ang = Angle( -7.1184873580933, 118.26454162598, 152.80551147461 ), ignore = true },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_CROUCH_ATTACK ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -2.0823380947113, 94.932098388672, 38.407363891602 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -10.847434997559, -1.0817413330078, 3.8380661010742 ), ang = Angle( -79.331871032715, -147.27368164063, 59.355743408203 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -10.555992126465, -9.6311187744141, 12.216644287109 ), ang = Angle( 87.922706604004, -94.464576721191, -168.0945892334 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -11.23233795166, 5.7340240478516, 13.674011230469 ), ang = Angle( 85.297119140625, 130.66120910645, 6.2110276222229 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -11.874320983887, 6.4857635498047, 2.0012741088867 ), ang = Angle( 85.26456451416, 137.50611877441, 13.03152179718 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -12.563133239746, 7.1116943359375, -9.4351501464844 ), ang = Angle( 67.748649597168, 111.48500823975, 115.56149291992 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -10.589073181152, -10.053970336914, 0.51792907714844 ), ang = Angle( 87.967254638672, -109.6325302124, 176.74711608887 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -10.72590637207, -10.437545776367, -10.956550598145 ), ang = Angle( 68.082916259766, -68.080718994141, 67.034759521484 ), ignore = true },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.4212646484375, -3.9653778076172, -0.12437438964844 ), ang = Angle( -7.5593452453613, -3.2403535842896, -82.977203369141 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 18.0859375, -4.9632568359375, 2.2233734130859 ), ang = Angle( 8.5116767883301, -1.2706490755081, -82.960891723633 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -10.593086242676, -2.5244445800781, 19.162971496582 ), ang = Angle( -78.39037322998, 20.220310211182, 81.324630737305 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.33425140380859, 3.8734893798828, 0.141357421875 ), ang = Angle( 25.349443435669, -5.1454882621765, -109.2848739624 ) },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 15.764335632324, 2.4386138916016, -7.4619369506836 ), ang = Angle( 22.955503463745, -168.96748352051, 108.92875671387 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 0.82898712158203, -0.47332763671875, -13.907051086426 ), ang = Angle( 69.854019165039, -54.555698394775, -150.63359069824 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 34.425148010254, -5.32568359375, -0.22254943847656 ), ang = Angle( -65.194076538086, -9.4244718551636, -78.89665222168 ) },
	},
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 21.312721252441, 93.795608520508, 32.303421020508 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -11.365814208984, 0.18731689453125, 2.4119720458984 ), ang = Angle( -79.331871032715, -153.92572021484, 59.355743408203 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -12.066665649414, -8.3382263183594, 10.790550231934 ), ang = Angle( 88.380798339844, -99.008430480957, -165.97590637207 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -10.958595275879, 7.0018005371094, 12.247932434082 ), ang = Angle( 85.274444580078, 124.05014801025, 6.2592916488647 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -11.512878417969, 7.8272094726563, 0.57538604736328 ), ang = Angle( 85.243797302246, 130.8861541748, 13.070524215698 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -12.127334594727, 8.5309143066406, -10.86043548584 ), ang = Angle( 68.524566650391, 105.91648864746, 116.55618286133 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -12.11848449707, -8.6647491455078, -0.91115570068359 ), ang = Angle( 88.424942016602, -118.56897735596, 174.47100830078 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -12.269393920898, -8.9419097900391, -12.38850402832 ), ang = Angle( 68.539619445801, -74.171913146973, 67.660537719727 ), ignore = true },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.18191528320313, -3.6179809570313, 1.4062347412109 ), ang = Angle( 58.631866455078, -15.681463241577, -105.84451293945 ) },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 9.1273345947266, -6.128662109375, -13.83381652832 ), ang = Angle( -13.48159122467, 175.96435546875, 98.406707763672 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -11.280296325684, -1.275146484375, 17.736877441406 ), ang = Angle( -78.39037322998, 13.568285942078, 81.324630737305 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.057868957519531, 3.7989044189453, -1.4231262207031 ), ang = Angle( -8.9376544952393, 0.26353904604912, -101.79188537598 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 17.573554992676, 3.7635192871094, 1.3723983764648 ), ang = Angle( 7.2878403663635, -2.9060151576996, -101.8182220459 ) },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 33.944221496582, 2.9324951171875, -0.72390747070313 ), ang = Angle( -49.612426757813, -7.6542778015137, -92.64183807373 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -6.9027252197266, -4.9976959228516, -9.9812393188477 ), ang = Angle( 61.857425689697, -169.90614318848, 106.26025390625 ) },
	},

}

RagdollFight.Stances[ RAGDOLL_STANCE_ATTACK ] = {
	{
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -0.35674667358398, -0.30027770996094, 11.542762756348 ), ang = Angle( -77.759208679199, -92.435432434082, 64.597900390625 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 7.0512733459473, -4.5566558837891, 19.950942993164 ), ang = Angle( 11.66369342804, -11.272748947144, -120.72191619873 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -6.6283111572266, 2.5067977905273, 21.34748840332 ), ang = Angle( 86.335441589355, -169.74433898926, 7.6331763267517 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -7.3853874206543, 2.3724670410156, 9.6602478027344 ), ang = Angle( 86.262260437012, -160.98648071289, 16.348138809204 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -8.0804443359375, 2.129524230957, -1.7924270629883 ), ang = Angle( 68.793251037598, 169.06916809082, 114.91160583496 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 18.3571434021, -6.7669067382813, 17.606178283691 ), ang = Angle( -7.7706561088562, -0.17122422158718, -120.26902008057 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 29.733350753784, -6.8009185791016, 19.158599853516 ), ang = Angle( -30.273122787476, -8.0374441146851, 93.188232421875 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 0.74221420288086, -1.2228546142578, 26.87052154541 ), ang = Angle( -73.514823913574, 14.546360969543, 118.93698120117 ) },
	},
	{
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -0.60060119628906, -0.75241088867188, 11.475540161133 ), ang = Angle( -83.076644897461, 111.35478210449, 115.89022827148 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -5.2393569946289, -6.3141326904297, 21.009689331055 ), ang = Angle( 88.434944152832, -161.02827453613, 177.40937805176 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 5.2726001739502, 4.983024597168, 20.20629119873 ), ang = Angle( 9.7468852996826, 18.250547409058, -42.159526824951 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 16.258884429932, 8.5766677856445, 18.247779846191 ), ang = Angle( -10.714545249939, -3.8516888618469, -41.450523376465 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 27.514892578125, 7.8188323974609, 20.382392883301 ), ang = Angle( -25.504671096802, 3.513861656189, 84.265808105469 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -5.5415992736816, -6.4179458618164, 9.3076858520508 ), ang = Angle( 88.323143005371, -179.92445373535, 158.52061462402 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -5.8775787353516, -6.4183883666992, -2.1690902709961 ), ang = Angle( 68.415916442871, -120.0046005249, 67.13005065918 ), ignore = true },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 0.67391586303711, -0.83335113525391, 26.817245483398 ), ang = Angle( -75.007232666016, -25.250579833984, 91.943977355957 ) },
	},

}

RagdollFight.Stances[ RAGDOLL_STANCE_JUMP_ATTACK ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -10.170501708984, 104.86196136475, 88.552780151367 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -3.3772277832031, -2.8462829589844, 10.633491516113 ), ang = Angle( -83.782531738281, 149.20974731445, 131.35507202148 ), ignore = true },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -1.4787826538086, -9.6734619140625, 20.23030090332 ), ang = Angle( 86.035888671875, -109.43673706055, 163.07820129395 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -4.2615280151367, 5.4856414794922, 19.129272460938 ), ang = Angle( 83.740348815918, 128.61199951172, -1.2716072797775 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -5.0742645263672, 6.5026550292969, 7.4861450195313 ), ang = Angle( 83.690643310547, 133.69639587402, 3.8059966564178 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -5.9247665405273, 7.3895568847656, -3.9349899291992 ), ang = Angle( 65.033905029297, 115.14503479004, 113.91780853271 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -1.751823425293, -10.460800170898, 8.5347213745117 ), ang = Angle( 86.252090454102, -97.57585144043, 174.95848083496 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -1.848274230957, -11.190979003906, -2.9188995361328 ), ang = Angle( 68.411087036133, -69.101066589355, 63.962127685547 ), ignore = true },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.029426574707, -3.8264923095703, -0.69676208496094 ), ang = Angle( -2.0642032623291, -3.6098699569702, -89.215705871582 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 18.900543212891, -4.8941192626953, -0.037574768066406 ), ang = Angle( -12.736505508423, -3.978312253952, -89.156829833984 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -2.1922912597656, -1.5144958496094, 25.924392700195 ), ang = Angle( -83.534622192383, -14.747854232788, 94.539100646973 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -1.0103607177734, 3.81103515625, 0.70720672607422 ), ang = Angle( 63.222888946533, 13.396951675415, -84.354545593262 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 6.7624359130859, 5.60205078125, -15.056335449219 ), ang = Angle( 56.663536071777, -175.5365447998, 85.619354248047 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -2.2915420532227, 4.8952941894531, -28.86247253418 ), ang = Angle( 46.650650024414, 8.9643459320068, -88.979843139648 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 34.980331420898, -6.0124053955078, 3.605712890625 ), ang = Angle( -59.85523223877, 1.0935977697372, -92.100883483887 ) },
	},
}



RagdollFight.Stances[ RAGDOLL_STANCE_JUMP_ATTACK_SPRINT ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 36.900501251221, 95.565002441406, 0.82438868284225 ) },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -11.757125854492, -5.7090454101563, -3.6005783081055 ), ang = Angle( -31.858383178711, 167.48445129395, 153.24745178223 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -15.15217590332, -5.5579376220703, 8.0086669921875 ), ang = Angle( 0.26536759734154, -26.952791213989, 178.17802429199 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -21.095672607422, 1.5210723876953, -3.9901580810547 ), ang = Angle( 49.819431304932, 76.617576599121, -42.103954315186 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -18.981903076172, 7.8572387695313, -12.833602905273 ), ang = Angle( -28.221576690674, 7.8901710510254, -54.992115020752 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -8.9608764648438, 9.2459869384766, -7.4041290283203 ), ang = Angle( -25.554840087891, -0.06589862704277, 20.579225540161 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -5.7591094970703, -10.078811645508, 7.9530563354492 ), ang = Angle( 0.8031644821167, 73.805061340332, -176.35647583008 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -2.5570983886719, 0.94619750976563, 7.7921142578125 ), ang = Angle( 31.359300613403, 63.194274902344, 85.60913848877 ), ignore = true },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.38691711425781, -3.0761871337891, 2.3527297973633 ), ang = Angle( -24.296390533447, 7.0349612236023, -117.09292602539 ) },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 16.532745361328, -1.0830535888672, 9.6970748901367 ), ang = Angle( 20.797374725342, -14.838875770569, -116.32112121582 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -23.203491210938, -0.74337768554688, 5.4172668457031 ), ang = Angle( -50.829872131348, 176.69581604004, -48.76180267334 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.33183288574219, 3.3321685791016, -2.542724609375 ), ang = Angle( 14.265232086182, -25.969957351685, -144.39898681641 ) },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 14.733901977539, -4.6053771972656, -6.8397216796875 ), ang = Angle( 15.778965950012, -164.93296813965, 146.03416442871 ) },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -0.62193298339844, -8.7392120361328, -11.333381652832 ), ang = Angle( 50.52027130127, -90.897880554199, -177.74406433105 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 31.466049194336, -5.0394439697266, 3.8295516967773 ), ang = Angle( -36.820289611816, -20.572765350342, -95.497863769531 ) },
	},
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -38.79301071167, -64.362594604492, 137.1163482666 ) },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -7.6151123046875, 3.3760986328125, 7.8800582885742 ), ang = Angle( -45.802284240723, -176.18223571777, -9.694896697998 ), ignore = true },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -19.502090454102, 2.520263671875, 8.9107666015625 ), ang = Angle( 77.528289794922, -53.778656005859, -88.568992614746 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -8.4776382446289, 0.651611328125, 19.516075134277 ), ang = Angle( 26.869688034058, 18.079242706299, 33.129787445068 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 1.3169403076172, 3.9042816162109, 14.246994018555 ), ang = Angle( 26.901304244995, -92.480758666992, -27.670970916748 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 0.87373352050781, -6.3253479003906, 9.0520477294922 ), ang = Angle( 52.174137115479, -74.661018371582, 111.3628692627 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -18.045837402344, 0.43930053710938, -2.4325942993164 ), ang = Angle( -13.995216369629, -54.301307678223, -89.4921875 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -11.544898986816, -8.6081695556641, 0.34413909912109 ), ang = Angle( 43.202861785889, -92.322402954102, -125.95209503174 ), ignore = true },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -1.4340972900391, 3.1487121582031, -2.4475326538086 ), ang = Angle( 44.245876312256, -129.40512084961, -60.214748382568 ) },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -9.5503692626953, -6.7304077148438, -14.900894165039 ), ang = Angle( 55.328182220459, -4.5750842094421, 51.278926849365 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -18.308883666992, 0.04345703125, 18.441093444824 ), ang = Angle( -56.986289978027, -132.63081359863, 145.79428100586 ), ignore = true },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 1.3113784790039, -2.7637939453125, 2.4492034912109 ), ang = Angle( 1.057618021965, 5.1536226272583, 63.408435821533 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 19.098220825195, -1.2759857177734, 2.1911163330078 ), ang = Angle( -3.9474902153015, 6.0788989067078, 61.144714355469 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 35.491561889648, 0.46983337402344, 3.3287506103516 ), ang = Angle( 34.051837921143, -55.574363708496, 26.342502593994 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -0.17952728271484, -7.4802856445313, -28.491661071777 ), ang = Angle( 63.989463806152, -77.945693969727, -14.391007423401 ) },
	},
}


RagdollFight.Stances[ RAGDOLL_STANCE_GRAB ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 0.21284055709839, 84.410308837891, 110.26197052002 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 0.25850677490234, 0.023651123046875, 11.546607971191 ), ang = Angle( -67.226951599121, 12.313130378723, -111.23612213135 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 4.3222961425781, -7.0014953613281, 20.480438232422 ), ang = Angle( 13.764678955078, -17.51259803772, -176.6244354248 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 6.356861114502, 7.9930114746094, 18.36604309082 ), ang = Angle( 14.446464538574, 2.7088799476624, -42.994148254395 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 19.940963745117, 7.7208251953125, 15.780380249023 ), ang = Angle( -1.6211162805557, -12.002588272095, -45.928695678711 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 31.167121887207, 5.3341064453125, 16.105178833008 ), ang = Angle( -27.400009155273, 6.9503927230835, 64.565368652344 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 17.221252441406, -10.118041992188, 17.80492401123 ), ang = Angle( 12.424346923828, -4.1875414848328, -171.8331451416 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 28.404117584229, -10.936798095703, 15.33464050293 ), ang = Angle( -7.6372323036194, -24.343210220337, 131.3350982666 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 8.4241714477539, 0.82321166992188, 24.572792053223 ), ang = Angle( -65.265068054199, -7.4586758613586, 85.577445983887 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_GRAB_IDLE ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 1.1192216873169, 117.70123291016, 110.66622161865 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 0.18569183349609, 0.35574340820313, 11.613525390625 ), ang = Angle( -88.866683959961, 34.413600921631, -127.3729095459 ), ignore = true },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 1.3172149658203, -7.3280334472656, 20.659606933594 ), ang = Angle( 50.611907958984, -11.208387374878, -99.453117370605 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 2.1131286621094, 8.0982055664063, 20.479286193848 ), ang = Angle( 54.359279632568, 0.18117752671242, -78.300895690918 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 8.9461612701416, 8.1239624023438, 10.979827880859 ), ang = Angle( -47.990985870361, -16.968711853027, -79.806243896484 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 16.291957855225, 5.8771057128906, 19.511680603027 ), ang = Angle( -44.843975067139, -3.0877375602722, -25.227184295654 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 8.6130447387695, -8.7699279785156, 11.628936767578 ), ang = Angle( -45.649723052979, 2.250185251236, -98.572624206543 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 16.633045196533, -8.4547424316406, 19.839263916016 ), ang = Angle( -44.780868530273, -3.6907875537872, -155.13204956055 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 3.0805358886719, 0.38858032226563, 26.733612060547 ), ang = Angle( -65.265068054199, 0.73314666748047, 85.577445983887 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_GRAB_JUMP ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 7.6913280487061, 92.830307006836, 169.00939941406 ) },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 9.87939453125, 1.30419921875, 5.604248046875 ), ang = Angle( -3.1193754673004, -3.3453822135925, -96.138206481934 ), ignore = true },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 18.519958496094, -7.1473388671875, 5.676383972168 ), ang = Angle( 48.781753540039, -64.15389251709, 174.96235656738 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 19.593811035156, 8.2261962890625, 4.0361480712891 ), ang = Angle( 14.649593353271, 41.216461181641, 30.019317626953 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 28.687744140625, 15.748046875, 1.0077667236328 ), ang = Angle( 29.404369354248, -16.64214515686, 6.2948780059814 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 38.271301269531, 12.883422851563, -4.6294174194336 ), ang = Angle( -16.136522293091, 9.1229724884033, 59.749061584473 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 22.224304199219, -14.159240722656, -3.1176528930664 ), ang = Angle( 11.362012863159, 20.341939926147, -132.83883666992 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 32.778930664063, -10.24609375, -5.3796234130859 ), ang = Angle( -18.109029769897, -34.10071182251, 154.30601501465 ) },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.1982421875, -3.9117431640625, 0.52277374267578 ), ang = Angle( 19.671407699585, -173.68041992188, 96.73575592041 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -16.522583007813, -5.7236328125, -5.4373474121094 ), ang = Angle( -39.000522613525, 178.94274902344, 98.285850524902 ), ignore = true },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 25.122497558594, 0.12921142578125, 3.7976150512695 ), ang = Angle( -16.819101333618, -0.095346212387085, 88.508476257324 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.2144775390625, 3.92236328125, -0.52513122558594 ), ang = Angle( 16.884914398193, 178.81698608398, 98.986122131348 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -17.387573242188, 4.3014526367188, -5.6866989135742 ), ang = Angle( -15.543318748474, 173.54350280762, 98.810035705566 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -33.207458496094, 6.0917358398438, -1.2584838867188 ), ang = Angle( 12.30720615387, 169.67170715332, 91.375427246094 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -29.36279296875, -5.4866943359375, 4.9624557495117 ), ang = Angle( 35.913516998291, -164.89964294434, 103.08796691895 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_GRAB_ATTACK_SLAM ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 5.5480933189392, 89.194969177246, 127.29388427734 ) },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 3.6190185546875, 0.9970703125, 10.8330078125 ), ang = Angle( -23.278221130371, -7.7091150283813, -92.92700958252 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 11.26953125, -7.8763427734375, 13.369262695313 ), ang = Angle( 77.216743469238, -35.081733703613, -118.97180938721 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 13.56494140625, 7.3492431640625, 12.817291259766 ), ang = Angle( 36.237449645996, 34.656795501709, 5.2858047485352 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 21.2705078125, 12.671630859375, 6.1725463867188 ), ang = Angle( 9.9099969863892, -51.405475616455, -41.43123626709 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 28.326049804688, 3.831787109375, 4.196533203125 ), ang = Angle( -2.7708251476288, 12.576964378357, 11.193155288696 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 13.794799804688, -9.2413330078125, 1.2313842773438 ), ang = Angle( 4.7948279380798, -7.9027614593506, -98.408752441406 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 25.127563476563, -10.814453125, 0.27163696289063 ), ang = Angle( -3.2347118854523, 7.1769638061523, -163.44540405273 ) },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.0604248046875, -3.89208984375, 0.40966796875 ), ang = Angle( 67.056587219238, -0.43566387891769, -104.1704864502 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 6.8402099609375, -3.959716796875, -15.098419189453 ), ang = Angle( -17.528503417969, -168.81178283691, 96.335632324219 ), ignore = true },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 18.442138671875, -1.1461181640625, 14.394104003906 ), ang = Angle( -12.810371398926, 13.582862854004, 102.73969268799 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.03759765625, 3.9095458984375, -0.35543823242188 ), ang = Angle( 61.186038970947, 4.655469417572, -83.337699890137 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 8.41748046875, 4.6988525390625, -14.926849365234 ), ang = Angle( -7.0510230064392, 178.53610229492, 89.969482421875 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -7.923828125, 5.0941162109375, -13.467346191406 ), ang = Angle( 17.751224517822, 178.9388885498, 86.536636352539 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -8.53271484375, -7.03515625, -10.658233642578 ), ang = Angle( 37.424041748047, -147.39820861816, 109.53856658936 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_GRAB_ATTACK_THROW ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 4.6032466888428, 95.224456787109, -177.95481872559 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 11.479125976563, 1.08203125, 3.349853515625 ), ang = Angle( -20.667701721191, -9.4783229827881, -60.779113769531 ), ignore = true },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 20.49853515625, -6.4697265625, 2.0814208984375 ), ang = Angle( 11.979236602783, -43.387180328369, -175.30627441406 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 19.773803710938, 7.359130859375, 9.0825500488281 ), ang = Angle( 31.565532684326, 50.736919403076, -7.754741191864 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 26.894226074219, 15.1611328125, 3.2412109375 ), ang = Angle( 10.011145591736, -2.7079386711121, -29.433515548706 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 38.188415527344, 14.627197265625, 1.2452392578125 ), ang = Angle( -12.896565437317, 26.559307098389, 40.229663848877 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 31.128601074219, -14.39990234375, -0.0252685546875 ), ang = Angle( 1.5307737588882, 7.0842928886414, -168.45576477051 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 42.518493652344, -12.984375, -0.33200073242188 ), ang = Angle( -26.336944580078, 6.8015294075012, 85.838729858398 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 26.492797851563, -0.112548828125, 6.5375671386719 ), ang = Angle( -26.179580688477, 11.986010551453, 92.136543273926 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_GRAB_ATTACK_BACKTHROW ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -6.1562471389771, 97.330268859863, 3.1987392902374 ) },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -10.998718261719, -1.080810546875, -3.1019897460938 ), ang = Angle( 21.231872558594, 176.74011230469, 77.593536376953 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -19.830810546875, -8.40478515625, -6.6426391601563 ), ang = Angle( -47.051898956299, -136.42588806152, -6.3849873542786 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -20.125244140625, 6.72216796875, -3.5528869628906 ), ang = Angle( -26.943277359009, 133.26890563965, -174.44044494629 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -27.397247314453, 14.439208984375, 1.9226989746094 ), ang = Angle( -16.132312774658, -159.24479675293, 158.40405273438 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -37.711029052734, 10.530517578125, 5.1130065917969 ), ang = Angle( 15.786178588867, 167.85722351074, -138.91696166992 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -26.018371582031, -13.662841796875, 2.1410522460938 ), ang = Angle( -21.304746627808, 146.7043762207, 42.83996963501 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -34.95947265625, -7.79052734375, 6.3126831054688 ), ang = Angle( -16.105968475342, -170.41151428223, -9.2670269012451 ) },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.37405395507813, -3.941650390625, -0.38278198242188 ), ang = Angle( 6.4781875610352, -0.95062559843063, -100.26930236816 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 17.41796875, -4.80615234375, -2.2139282226563 ), ang = Angle( 44.290065765381, -170.11848449707, 103.94231414795 ), ignore = true },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -26.079742431641, -0.792236328125, -6.1805114746094 ), ang = Angle( 35.487789154053, -177.35563659668, -82.397346496582 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.49771118164063, 3.8359375, 0.42327880859375 ), ang = Angle( 21.199869155884, 4.9987635612488, -92.585609436035 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 16.085357666016, 5.28564453125, -6.0173034667969 ), ang = Angle( 28.286582946777, -172.76280212402, 92.728408813477 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 1.4382629394531, 3.419189453125, -12.474578857422 ), ang = Angle( 71.570747375488, 14.10311126709, -83.811790466309 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 5.764404296875, -6.83642578125, -13.753387451172 ), ang = Angle( 56.360885620117, -12.318192481995, -101.60134887695 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_BLOCK ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -1.1135094165802, 96.803153991699, 112.36982727051 ), ignore = true },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 0.73785400390625, -0.15061950683594, 11.473747253418 ), ang = Angle( -43.701950073242, -0.35901203751564, -94.186302185059 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 7.7651672363281, -7.9718475341797, 17.144020080566 ), ang = Angle( 40.446964263916, -24.236490249634, -144.5341796875 ) },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 8.636962890625, 7.4120025634766, 16.301536560059 ), ang = Angle( 58.280246734619, -21.647926330566, -76.537178039551 ) },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 14.369079589844, 5.13134765625, 6.366325378418 ), ang = Angle( -25.867942810059, -36.593105316162, -81.842079162598 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 22.663879394531, -1.0274200439453, 11.375755310059 ), ang = Angle( -38.781936645508, -7.1035232543945, 31.10933303833 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 15.934997558594, -11.53254699707, 9.6984710693359 ), ang = Angle( -35.819896697998, 52.74991607666, -139.67251586914 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 21.5703125, -4.1217498779297, 16.418022155762 ), ang = Angle( -42.676914215088, 15.516320228577, 179.21499633789 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 13.526351928711, -0.42427062988281, 20.039848327637 ), ang = Angle( -48.23363494873, 5.5867428779602, 80.99658203125 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_SLIDE ] = {
	{
		["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 4.7276110649109, 88.558616638184, 30.408382415771 ) },
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( -11.232727050781, 0.47021484375, 2.2522811889648 ), ang = Angle( -70.037162780762, -178.76670837402, 88.345420837402 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -13.068603515625, -7.3317260742188, 11.156410217285 ), ang = Angle( 77.908866882324, -162.89234924316, 103.69420623779 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -12.969787597656, 8.1145629882813, 11.308868408203 ), ang = Angle( 24.339021682739, 10.304812431335, -65.568138122559 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -2.5326538085938, 10.252197265625, 6.6049194335938 ), ang = Angle( -24.777225494385, -8.8417186737061, -64.600196838379 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 7.9375, 8.0197143554688, 11.167427062988 ), ang = Angle( -20.779066085815, -5.5889925956726, 58.291240692139 ) },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -15.419738769531, -8.0523071289063, -0.27095031738281 ), ang = Angle( 30.431104660034, 2.0354309082031, -93.29630279541 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -5.5260620117188, -7.70068359375, -6.0864410400391 ), ang = Angle( -0.61158341169357, -64.102439880371, 143.18569946289 ) },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.1533203125, -3.9544677734375, 0.32475280761719 ), ang = Angle( -6.214656829834, 0.044083271175623, -81.066604614258 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 17.59375, -3.8954467773438, 2.2526626586914 ), ang = Angle( 2.3747367858887, 1.3265055418015, -80.943115234375 ) },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( -13.917236328125, 0.33575439453125, 17.410575866699 ), ang = Angle( -86.091720581055, -10.293827056885, 95.400093078613 ) },
		["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.12347412109375, 3.8939819335938, -0.34530639648438 ), ang = Angle( -38.306503295898, 6.8702607154846, -113.18376922607 ), ignore = true },
		["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 13.968811035156, 5.6514282226563, 10.809593200684 ), ang = Angle( 69.271934509277, -69.706703186035, -153.34475708008 ), ignore = true },
		["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 15.997314453125, 0.16571044921875, -4.6459808349609 ), ang = Angle( 3.2155504226685, -12.40101146698, -109.92475891113 ) },
		["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 34.100341796875, -3.51318359375, 1.5679397583008 ), ang = Angle( -48.496849060059, -3.787914276123, -78.868705749512 ) },
	},
}

RagdollFight.Stances[ RAGDOLL_STANCE_TAUNT ] = {
	{
		["ValveBiped.Bip01_Spine2"] = { pos = Vector( 0.37554931640625, 0.33047485351563, 11.460105895996 ), ang = Angle( 84.986213684082, 77.15374755859, 92.506828308105 ) },
		["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 1.67529296875, -7.2708129882813, 20.61946105957 ), ang = Angle( 87.677597045898, -77.326889038086, 178.45658874512 ), ignore = true },
		["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 0.20928955078125, 8.0920104980469, 20.602806091309 ), ang = Angle( 5.9674077033997, -2.6927902698517, -46.637504577637 ), ignore = true },
		["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 11.734436035156, 7.4373168945313, 19.625793457031 ), ang = Angle( -43.99829864502, -124.62014770508, 18.647846221924 ), ignore = true },
		["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 6.9933471679688, 0.60842895507813, 27.55721282959 ), ang = Angle( -54.237754821777, -124.78739929199, 101.00861358643 ), ignore = true },
		["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 1.779541015625, -7.7340087890625, 8.9228820800781 ), ang = Angle( 87.601699829102, -90.31729888916, 165.47506713867 ), ignore = true },
		["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 1.7767944335938, -8.2138671875, -2.5488739013672 ), ang = Angle( 62.970867156982, -50.967834472656, 72.428237915039 ), ignore = true },
		["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.5333251953125, -3.5724487304688, 0.068084716796875 ), ang = Angle( 65.393745422363, 1.9163428544998, -113.62455749512 ), ignore = true },
		["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 8.9464721679688, -3.3202514648438, -16.06559753418 ), ang = Angle( 60.523677825928, -139.00199890137, 109.80471801758 ), ignore = true },
		["ValveBiped.Bip01_Head1"] = { pos = Vector( 1.6810913085938, 0.511474609375, 26.79833984375 ), ang = Angle( -71.619407653809, -7.0056886672974, 82.388328552246 ), ignore = true },
	},
}

RagdollFight.XRayStances = {}

--xray
RagdollFight.XRayStances[ 1 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Head1",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 1.7081564664841, 98.547706604004, 107.93807983398 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -0.2615966796875, 0.30518913269043, 11.500625610352 ), ang = Angle( -87.041877746582, -172.18975830078, 82.483688354492 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 0.7115478515625, -7.4727897644043, 20.560401916504 ), ang = Angle( 14.048253059387, 6.358006477356, -109.31003570557 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 0.614501953125, 7.9726982116699, 20.654899597168 ), ang = Angle( 87.271240234375, 109.40116119385, 2.1554017066956 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 0.427001953125, 8.5093078613281, 8.9628219604492 ), ang = Angle( 87.197776794434, 121.09079742432, 13.848948478699 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 0.139404296875, 8.9794635772705, -2.5067825317383 ), ang = Angle( 68.786193847656, 91.165939331055, 112.37200927734 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 12.072265625, -6.2008361816406, 17.755867004395 ), ang = Angle( -25.559289932251, 20.574148178101, -110.85311126709 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 21.769775390625, -2.5608062744141, 22.709579467773 ), ang = Angle( -23.594690322876, 13.96538066864, 109.28096008301 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.5777587890625, -3.8437194824219, 0.13658142089844 ), ang = Angle( 82.342079162598, 176.29386901855, 83.14852142334 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -1.7913818359375, -3.683952331543, -17.49787902832 ), ang = Angle( 70.34309387207, -179.40087890625, 87.34610748291 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 1.6104736328125, 0.21196746826172, 26.780899047852 ), ang = Angle( -69.920372009277, 22.95157623291, 87.02897644043 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.578125, 3.8472061157227, -0.12400054931641 ), ang = Angle( 87.726402282715, 48.355388641357, -44.830837249756 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -0.107666015625, 4.3789672851563, -17.946487426758 ), ang = Angle( 70.493591308594, 178.68228149414, 85.190017700195 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -5.624267578125, 4.5058574676514, -33.523246765137 ), ang = Angle( 33.429759979248, 1.6641144752502, -90.679931640625 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -7.349853515625, -3.742073059082, -33.060096740723 ), ang = Angle( 33.33784866333, -3.2419471740723, -91.349731445313 ) },
			},
			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 8.6112060546875, 1.2021961212158, -0.049362182617188 ), ang = Angle( -9.387978553772, -103.15073394775, 49.438079833984 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 18.4677734375, -0.12461471557617, 5.7049331665039 ), ang = Angle( -53.78885269165, 3.5470530986786, 108.32724761963 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 20.367370605469, 6.9040451049805, 15.215446472168 ), ang = Angle( 88.326110839844, 133.33470153809, -166.02282714844 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 25.186401367188, -7.4896965026855, 12.345314025879 ), ang = Angle( 88.692245483398, -49.0791015625, 28.902881622314 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 25.359924316406, -7.6909008026123, 0.64361572265625 ), ang = Angle( 88.319061279297, -31.064840316772, 46.908847808838 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 25.6484375, -7.8646640777588, -10.833122253418 ), ang = Angle( 69.330078125, -95.159896850586, 111.39852905273 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 20.13330078125, 7.1536350250244, 3.5177383422852 ), ang = Angle( 88.379051208496, 114.76061248779, 175.41014099121 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 19.997314453125, 7.4485549926758, -7.959358215332 ), ang = Angle( 68.585716247559, 157.50813293457, 67.607810974121 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 9.488525390625, 4.9400749206543, -0.66701507568359 ), ang = Angle( 73.41438293457, 150.19067382813, -114.91710662842 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 5.0703125, 7.4483947753906, -17.661315917969 ), ang = Angle( 68.828727722168, 12.529602050781, 109.71446990967 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 25.434509277344, -0.52794456481934, 19.427238464355 ), ang = Angle( -63.562664031982, -13.13562297821, -58.187549591064 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 7.738525390625, -2.5379028320313, 0.59082794189453 ), ang = Angle( 73.592269897461, 165.41879272461, -77.66675567627 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 2.8621826171875, -1.2536163330078, -16.482200622559 ), ang = Angle( 81.56559753418, -51.01628112793, 65.396072387695 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 4.3870849609375, -3.137752532959, -32.828712463379 ), ang = Angle( 34.400295257568, 137.53666687012, -96.359886169434 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 10.896484375, 8.7431621551514, -33.071189880371 ), ang = Angle( 32.324253082275, 160.2469329834, -102.08055877686 ) },
			},
		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Spine2",
		offset = -1 * vector_up * 9,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -2.033614397049, 86.498313903809, 91.521575927734 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -3.329833984375, -0.22985076904297, 10.945823669434 ), ang = Angle( -80.534957885742, 34.615623474121, -112.59762573242 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 0.8746337890625, -6.6376266479492, 20.155288696289 ), ang = Angle( 31.301115036011, -24.908130645752, -119.00032806396 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -2.4471435546875, 8.3972320556641, 19.307861328125 ), ang = Angle( 71.419166564941, -10.825827598572, -93.85285949707 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 1.697021484375, 9.6715240478516, 8.3072357177734 ), ang = Angle( -26.233419418335, -10.566771507263, -83.112571716309 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 11.459350585938, 6.1775894165039, 13.839363098145 ), ang = Angle( -19.392309188843, 3.46377825737, 40.058704376221 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 9.8775634765625, -10.960166931152, 14.320892333984 ), ang = Angle( -0.73435962200165, -8.3243131637573, -113.95798492432 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 21.285278320313, -12.514045715332, 14.255554199219 ), ang = Angle( 48.618144989014, 9.8249492645264, 121.26631164551 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.391845703125, -3.5921401977539, 0.29465484619141 ), ang = Angle( -3.0040907859802, 2.3803675174713, -85.27091217041 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 17.502807617188, -3.3612747192383, 0.864501953125 ), ang = Angle( 73.757049560547, 168.91078186035, 76.261367797852 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 1.2879638671875, 1.719841003418, 25.501708984375 ), ang = Angle( -54.144973754883, -17.482740402222, 113.49024200439 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.234619140625, 4.1602630615234, 0.10832977294922 ), ang = Angle( 83.384651184082, -45.64697265625, -128.12020874023 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 1.6636962890625, 2.536247253418, -17.614921569824 ), ang = Angle( 7.7056379318237, 173.02798461914, 93.755989074707 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -14.591064453125, 4.5240478515625, -19.830696105957 ), ang = Angle( 34.732791900635, 173.15357971191, 90.52840423584 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 12.966796875, -2.4722366333008, -15.001121520996 ), ang = Angle( 50.149852752686, -9.6987600326538, -93.057029724121 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 16.605346679688, 10.761260986328, 5.621223449707 ), ang = Angle( -30.084201812744, 163.470703125, 17.442880630493 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 13.173706054688, -0.42530059814453, 5.6341400146484 ), ang = Angle( 13.991800308228, -85.290977478027, 101.95673370361 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 21.349853515625, -9.3023071289063, 6.4421539306641 ), ang = Angle( 29.264129638672, 65.936935424805, -129.78959655762 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 6.2481689453125, -11.646179199219, 2.1830139160156 ), ang = Angle( 52.358943939209, 58.236145019531, -105.27613067627 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 8.9610595703125, -3.1212158203125, -5.8105392456055 ), ang = Angle( 52.33313369751, 60.518619537354, -101.32521820068 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 13.179565429688, 2.5966491699219, -15.037002563477 ), ang = Angle( 59.368572235107, 159.46893310547, 36.548595428467 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 25.322509765625, 0.018478393554688, 0.54557037353516 ), ang = Angle( 30.493782043457, 65.18822479248, -129.90661621094 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 29.474365234375, 8.9988098144531, -5.28076171875 ), ang = Angle( 67.55345916748, 37.209899902344, 61.657970428467 ), ignore = true },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 19.936401367188, 9.525032043457, 3.9818344116211 ), ang = Angle( 49.435810089111, 89.08805847168, -65.426864624023 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 20.025756835938, 21.170013427734, -9.5458526611328 ), ang = Angle( 41.207210540771, -124.34650421143, 68.969627380371 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 13.8857421875, -15.760513305664, 4.4840316772461 ), ang = Angle( 28.444795608521, -87.846580505371, -98.012496948242 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 13.236572265625, 11.519287109375, 7.89501953125 ), ang = Angle( 50.828392028809, 85.92317199707, -50.438835144043 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 14.133178710938, 22.720718383789, -5.9998092651367 ), ang = Angle( 61.717742919922, 178.74533081055, 31.995986938477 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 6.298095703125, 22.882118225098, -20.482040405273 ), ang = Angle( 45.686363220215, 91.72119140625, -49.432308197021 ), ignore = true },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 12.968139648438, 10.811019897461, -19.885360717773 ), ang = Angle( 53.976997375488, 99.288604736328, -56.928691864014 ), ignore = true },
			},
		},

	},

	--third move
	[ 3 ] = {

		bone = "ValveBiped.Bip01_Head1",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -6.4336609840393, 119.83840942383, 97.204116821289 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -1.41015625, -2.2552490234375, 11.137245178223 ), ang = Angle( -62.305000305176, 0.9806724190712, -57.828498840332 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 7.5733642578125, -7.904541015625, 16.688735961914 ), ang = Angle( 88.380798339844, -38.644390106201, -165.97880554199 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 0.06640625, 5.0479736328125, 20.51335144043 ), ang = Angle( 71.493385314941, 115.41031646729, 32.731311798096 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -1.5584716796875, 8.530029296875, 9.4130783081055 ), ang = Angle( 74.736785888672, 78.062812805176, -3.0701327323914 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -0.9149169921875, 11.408447265625, -1.6512985229492 ), ang = Angle( 66.331840515137, 82.909454345703, 120.52201080322 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 7.8314208984375, -8.1112060546875, 4.9870529174805 ), ang = Angle( 88.424934387207, -58.20272064209, 174.47030639648 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 7.9976806640625, -8.37939453125, -6.4902877807617 ), ang = Angle( 68.539710998535, -13.805144309998, 67.66039276123 ), ignore = true },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.96826171875, -3.425537109375, -0.44423675537109 ), ang = Angle( 38.965793609619, 13.703038215637, -95.721977233887 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 15.424438476563, -0.09619140625, -11.624076843262 ), ang = Angle( 65.15550994873, -152.82717895508, 100.93795013428 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 7.5992431640625, -0.689208984375, 23.521797180176 ), ang = Angle( -30.302211761475, -4.5202350616455, 126.28056335449 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -1.9677734375, 3.421875, 0.45612335205078 ), ang = Angle( 86.020866394043, -110.61162567139, 113.42418670654 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -2.3551025390625, 2.2294311523438, -17.166313171387 ), ang = Angle( 70.329689025879, -129.91729736328, 94.229560852051 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -5.9244384765625, -2.0368041992188, -32.727226257324 ), ang = Angle( 33.364013671875, 53.275867462158, -87.958099365234 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 9.2476806640625, -3.2669677734375, -26.619941711426 ), ang = Angle( 37.313282012939, 2.279744386673, -101.45917510986 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 37.447143554688, 5.8794555664063, -29.615715026855 ), ang = Angle( 63.283149719238, -81.915084838867, 176.90498352051 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 27.47216796875, 0.60302734375, -27.542442321777 ), ang = Angle( -1.0993025302887, -164.74711608887, -105.48718261719 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 16.690307617188, 5.721923828125, -26.756309509277 ), ang = Angle( 23.444131851196, 65.774345397949, 143.02842712402 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 20.514038085938, -8.6563720703125, -30.861778259277 ), ang = Angle( 19.251375198364, 6.5174808502197, 92.664825439453 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 31.528076171875, -7.611083984375, -34.271202087402 ), ang = Angle( 5.8084392547607, -174.48193359375, -93.097869873047 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 20.076782226563, -8.49072265625, -35.57982635498 ), ang = Angle( -4.4425621032715, 176.61058044434, -39.834991455078 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 21.080078125, 15.465087890625, -31.239387512207 ), ang = Angle( 22.111763000488, 65.341461181641, 143.40724182129 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 25.504516601563, 25.093811035156, -35.802940368652 ), ang = Angle( -29.156114578247, 68.369277954102, 88.268112182617 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 37.200927734375, 7.606689453125, -26.138282775879 ), ang = Angle( 25.842082977295, 89.606689453125, -177.1467590332 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 37.313232421875, 23.663909912109, -33.604347229004 ), ang = Angle( 3.1591320037842, -0.97439759969711, 154.80249023438 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 12.615600585938, -2.7313232421875, -29.909812927246 ), ang = Angle( 29.727928161621, -152.15473937988, 70.57137298584 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 37.687866210938, 4.1449584960938, -33.049690246582 ), ang = Angle( 2.9567058086395, 28.802797317505, 165.31942749023 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 53.30517578125, 12.726440429688, -33.776054382324 ), ang = Angle( 1.7440495491028, 23.064136505127, 165.70664978027 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 68.501586914063, 19.200347900391, -34.437110900879 ), ang = Angle( -0.74865061044693, 53.42179107666, 169.50991821289 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 53.81298828125, 23.387176513672, -34.66088104248 ), ang = Angle( -3.6535720825195, 57.654663085938, 174.55075073242 ) },
			},
		},
	},
}

RagdollFight.XRayStances[ 2 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Pelvis",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 8.3270883560181, 82.439300537109, 98.159446716309 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -1.8421325683594, 1.9812316894531, 11.190040588379 ), ang = Angle( -89.397499084473, -106.3443069458, 19.814359664917 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -0.021636962890625, -5.7349853515625, 20.175086975098 ), ang = Angle( 78.345596313477, -99.666038513184, 158.4633026123 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -0.95889282226563, 9.68212890625, 20.322784423828 ), ang = Angle( 64.768135070801, -171.48426818848, 103.24868774414 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -5.9164123535156, 9.0785217285156, 9.7681350708008 ), ang = Angle( 58.104507446289, -11.096985816956, -100.05466461182 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 0.0404052734375, 7.5950622558594, 0.014312744140625 ), ang = Angle( 62.590446472168, 37.510417938232, 12.495241165161 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -0.39947509765625, -8.1423950195313, 8.7915878295898 ), ang = Angle( 31.195585250854, 5.1154108047485, -103.34851074219 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 9.3468322753906, -7.09375, 2.765380859375 ), ang = Angle( 30.367321014404, -9.3854427337646, 160.32273864746 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.554931640625, -3.9927978515625, 0.68004608154297 ), ang = Angle( 6.9535903930664, 5.0115776062012, -81.503379821777 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 16.831634521484, -2.4673461914063, -1.7271347045898 ), ang = Angle( 5.0703883171082, 5.1514368057251, -82.88712310791 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 0.75906372070313, 1.9886779785156, 26.363456726074 ), ang = Angle( -68.597038269043, 10.329849243164, 92.619598388672 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.5042724609375, 3.8463745117188, -0.56141662597656 ), ang = Angle( 67.928695678711, -178.33410644531, 90.303451538086 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -6.1976013183594, 3.6495666503906, -17.095039367676 ), ang = Angle( 71.88646697998, -178.22778320313, 90.395164489746 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -11.313018798828, 3.5110168457031, -32.413795471191 ), ang = Angle( 33.413562774658, 7.3790822029114, -88.677673339844 ), ignore = true },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 33.416290283203, -1.0568237304688, -2.8473205566406 ), ang = Angle( -47.561126708984, 0.051558617502451, -79.712013244629 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 29.338256835938, -0.5255126953125, 6.2606353759766 ), ang = Angle( -0.85800576210022, -70.283203125, 107.67595672607 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 29.571044921875, -0.3193359375, 17.733085632324 ), ang = Angle( -74.549354553223, 161.83891296387, -65.194229125977 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 25.167114257813, 7.8942260742188, 25.25220489502 ), ang = Angle( 88.398933410645, 96.732711791992, -166.74308776855 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 26.731719970703, -7.3794555664063, 26.979614257813 ), ang = Angle( 78.102096557617, -96.463768005371, 5.3318376541138 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 26.442718505859, -9.8651123046875, 15.517990112305 ), ang = Angle( 78.279235839844, -96.207626342773, 5.5948047637939 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 26.201446533203, -12.128967285156, 4.2897567749023 ), ang = Angle( 66.797691345215, -101.7099609375, 124.81725311279 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 25.128845214844, 8.2188415527344, 13.550399780273 ), ang = Angle( 88.434768676758, 76.973701477051, 173.50531005859 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 25.199554443359, 8.5243835449219, 2.0729904174805 ), ang = Angle( 68.59204864502, 122.27513122559, 67.600105285645 ), ignore = true },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 28.032012939453, 3.413818359375, 6.251350402832 ), ang = Angle( 65.25479888916, 164.54981994629, -118.67807769775 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 20.801666259766, 5.1228637695313, -9.9516067504883 ), ang = Angle( 61.044063568115, 32.722461700439, 114.31610107422 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 23.181823730469, 0.60116577148438, 31.707939147949 ), ang = Angle( -46.907386779785, -154.95559692383, 64.294219970703 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 30.733276367188, -4.4892883300781, 6.415901184082 ), ang = Angle( 67.83708190918, -122.26062011719, -59.89351272583 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 27.06689453125, -9.9190368652344, -10.217811584473 ), ang = Angle( 77.753547668457, -35.543502807617, 24.685699462891 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 29.919097900391, -11.956756591797, -26.367012023926 ), ang = Angle( 67.169761657715, -138.96559143066, -74.794441223145 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 27.532440185547, 9.4476928710938, -24.411079406738 ), ang = Angle( 67.418312072754, 173.64329528809, -108.91386413574 ) },
			},


		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Head1",
		offset = vector_up * 30,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -5.8452172279358, 85.716949462891, -69.871215820313 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -0.14019775390625, 1.180908203125, -11.413291931152 ), ang = Angle( 47.050964355469, 177.90475463867, 81.720985412598 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -6.7783203125, -6.4236450195313, -17.87629699707 ), ang = Angle( 67.950271606445, -49.128601074219, -8.1673383712769 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -7.84521484375, 8.91064453125, -16.361679077148 ), ang = Angle( 58.598007202148, 60.60347366333, -145.73767089844 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -4.8556823730469, 14.2197265625, -26.356338500977 ), ang = Angle( 59.236209869385, 58.969081878662, -147.15586853027 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -1.8282165527344, 19.252105712891, -36.222320556641 ), ang = Angle( 70.585655212402, -111.33460235596, 94.05583190918 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -3.90625, -9.7426452636719, -28.72785949707 ), ang = Angle( 68.080947875977, -47.535194396973, -6.6984386444092 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -1.0125427246094, -12.904449462891, -39.379554748535 ), ang = Angle( 67.552589416504, 71.38801574707, 61.656890869141 ), ignore = true },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.29232788085938, -3.8945617675781, -0.40352630615234 ), ang = Angle( -55.796798706055, -157.9733581543, 70.886383056641 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -9.5578308105469, -7.6421203613281, 14.366493225098 ), ang = Angle( -23.284116744995, 1.373626947403, -79.096862792969 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -12.398651123047, 1.2473754882813, -20.725936889648 ), ang = Angle( 56.833171844482, 169.61801147461, -111.97556304932 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.34707641601563, 3.9111633300781, 0.28468322753906 ), ang = Angle( -64.434646606445, -176.29898071289, 85.586761474609 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -7.0111694335938, 3.6690673828125, 15.698448181152 ), ang = Angle( -41.006881713867, -1.7249596118927, -82.589630126953 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 5.435546875, 3.1470336914063, 26.579822540283 ), ang = Angle( -59.325164794922, -155.11614990234, 65.820602416992 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 5.6171875, -7.2782287597656, 20.898780822754 ), ang = Angle( -81.666275024414, -122.02927398682, 39.070430755615 ) },
			},
			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 20.310546875, -1.3104553222656, 39.004451751709 ), ang = Angle( -9.8046236038208, -74.106719970703, -177.31063842773 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 9.5505981445313, -3.7939147949219, 42.252807617188 ), ang = Angle( 53.668182373047, 166.58612060547, -87.493843078613 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 7.5903015136719, 5.0604248046875, 34.332035064697 ), ang = Angle( 52.242248535156, 65.245407104492, -6.4984230995178 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 3.3162231445313, -10.739715576172, 34.690238952637 ), ang = Angle( 51.2262840271, -93.50675201416, 146.27809143066 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 2.8955383300781, -17.691009521484, 25.260997772217 ), ang = Angle( 58.239009857178, -55.345008850098, 177.92999267578 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 6.3322143554688, -22.662475585938, 15.498710632324 ), ang = Angle( 66.797698974609, 179.29844665527, 124.81694030762 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 10.472686767578, 11.147430419922, 24.729774475098 ), ang = Angle( 51.921569824219, 66.2470703125, -4.960292339325 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 13.324920654297, 17.628814697266, 15.691764831543 ), ang = Angle( 67.553062438965, -153.73150634766, 61.656642913818 ), ignore = true },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 19.237335205078, 2.4472351074219, 38.367496490479 ), ang = Angle( 44.93794631958, 12.686354637146, 73.804214477539 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 31.599761962891, 5.193359375, 25.777038574219 ), ang = Angle( 9.0475997924805, 22.572076797485, 78.439514160156 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 2.6003723144531, -2.2352600097656, 27.924873352051 ), ang = Angle( 51.368419647217, 179.47125244141, 95.384033203125 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 21.388153076172, -5.0638732910156, 39.655239105225 ), ang = Angle( 51.122566223145, -17.273735046387, 58.584819793701 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 32.130706787109, -8.3507080078125, 25.742141723633 ), ang = Angle( 12.934346199036, 3.4607121944427, 70.456680297852 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 48.207336425781, -7.3785095214844, 22.04322052002 ), ang = Angle( 69.581733703613, -0.38980376720428, 75.990089416504 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 46.669281005859, 11.457550048828, 23.178363800049 ), ang = Angle( 79.708145141602, -40.70384979248, 25.942567825317 ) },
			},

		},
	},

	--third move
	[ 3 ] = {
		bone = "ValveBiped.Bip01_Head1",
		offset = -1 * vector_up * 12,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 5.5084762573242, 80.561157226563, 119.45967102051 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 3.55712890625, 0.39154052734375, 10.072731018066 ), ang = Angle( -9.1012172698975, -8.1112661361694, -91.346015930176 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 11.500427246094, -8.5738525390625, 10.31770324707 ), ang = Angle( 66.350318908691, -137.76335144043, 142.26681518555 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 13.705444335938, 6.7482299804688, 9.8697967529297 ), ang = Angle( 60.042644500732, 131.93179321289, 53.331027984619 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 9.8036804199219, 11.091888427734, -0.26059722900391 ), ang = Angle( 52.643287658691, 8.9157314300537, -60.56294631958 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 16.686309814453, 12.171600341797, -9.3870849609375 ), ang = Angle( 68.68775177002, 6.8931794166565, 64.409957885742 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 8.0159912109375, -11.729675292969, -0.39064788818359 ), ang = Angle( 64.361289978027, -51.88850402832, -137.2996673584 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 11.082305908203, -15.638610839844, -10.741851806641 ), ang = Angle( 71.674736022949, 33.90340423584, -144.68528747559 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -1.7505493164063, -3.8418884277344, 1.0751037597656 ), ang = Angle( 27.746934890747, -12.895370483398, -112.32168579102 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 13.646850585938, -7.3670654296875, -7.2344055175781 ), ang = Angle( 25.623106002808, -172.21774291992, 111.88807678223 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 18.787475585938, -1.842041015625, 9.8546371459961 ), ang = Angle( -23.332391738892, -8.6166820526123, 93.442489624023 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.70880126953125, 3.8871459960938, -0.17278289794922 ), ang = Angle( 28.400882720947, 8.3038597106934, -79.532409667969 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 16.740570068359, 6.4772644042969, -7.3470764160156 ), ang = Angle( 24.106502532959, 178.67280578613, 83.008514404297 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 1.6605529785156, 6.82666015625, -14.096542358398 ), ang = Angle( 76.651870727539, 13.226599693298, -80.738342285156 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -1.1251220703125, -9.3775634765625, -14.362884521484 ), ang = Angle( 66.646125793457, -31.286964416504, -122.05773925781 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( -25.129730224609, 1.4458312988281, 2.6432037353516 ), ang = Angle( 1.7330099344254, -91.39493560791, -116.48526000977 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -33.736511230469, 2.0916137695313, -4.4018249511719 ), ang = Angle( 65.742561340332, -26.635934829712, 65.316612243652 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -28.612274169922, 8.0129089355469, -13.455856323242 ), ang = Angle( 45.707557678223, 158.2024230957, 14.54492855072 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -29.652008056641, -7.1430358886719, -10.82649230957 ), ang = Angle( 41.747520446777, -145.04016113281, -165.50204467773 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -36.850830078125, -12.039764404297, -18.638107299805 ), ang = Angle( 2.412873506546, -78.252708435059, -136.93522644043 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -34.515289306641, -23.270965576172, -19.121459960938 ), ang = Angle( -42.121528625488, -79.148902893066, -85.818420410156 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -36.208221435547, 11.016052246094, -21.201934814453 ), ang = Angle( -2.7504506111145, 45.534996032715, -46.41410446167 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -28.175109863281, 19.199371337891, -21.200271606445 ), ang = Angle( 26.995555877686, 43.728664398193, -87.725250244141 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -25.036437988281, 5.3334350585938, 2.7531280517578 ), ang = Angle( -81.430015563965, 168.04704284668, -79.784606933594 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -27.638946533203, 5.8843688964844, 20.401672363281 ), ang = Angle( 46.661571502686, 179.75540161133, -87.794258117676 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -25.713287353516, -0.6907958984375, -16.822128295898 ), ang = Angle( 46.885536193848, -0.6551468372345, -113.14655303955 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -25.225677490234, -2.5508117675781, 2.5216827392578 ), ang = Angle( -74.051856994629, -105.49200439453, -153.16563415527 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -26.540588378906, -7.2122802734375, 19.665519714355 ), ang = Angle( 43.957042694092, 178.00869750977, -110.08602905273 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -38.429229736328, -6.7988891601563, 8.1950378417969 ), ang = Angle( 20.006824493408, -164.64091491699, -107.86089324951 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -38.980194091797, 5.9328002929688, 8.3826599121094 ), ang = Angle( 20.070413589478, 172.5411529541, -85.244682312012 ) },
			},
		},
	},

}

RagdollFight.XRayStances[ 3 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Spine2",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -5.9912271499634, 90.513458251953, 81.5654296875 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -5.2255859375, -1.1525421142578, 10.128059387207 ), ang = Angle( -53.065437316895, -0.027012255042791, -90.552398681641 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 1.68603515625, -8.8363800048828, 16.691581726074 ), ang = Angle( 11.118906974792, -29.140249252319, -159.29280090332 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 1.6986083984375, 6.8257904052734, 16.239295959473 ), ang = Angle( 14.836899757385, 42.617198944092, -24.748689651489 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 10.016296386719, 14.478790283203, 13.245223999023 ), ang = Angle( -14.22570514679, -14.127209663391, -25.089706420898 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 20.84912109375, 11.605224609375, 15.835433959961 ), ang = Angle( -21.510980606079, -7.2957816123962, 41.211833953857 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 14.282470703125, -14.270523071289, 15.173973083496 ), ang = Angle( -7.1642780303955, 13.300703048706, -150.32637023926 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 25.32470703125, -11.266525268555, 16.587211608887 ), ang = Angle( -8.8309841156006, 58.228073120117, 175.33274841309 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.03717041015625, -3.9075775146484, -0.37581634521484 ), ang = Angle( 87.384521484375, 136.13128662109, 34.819763183594 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -0.55084228515625, -3.3214416503906, -18.204666137695 ), ang = Angle( 81.726196289063, 176.6974029541, 75.300323486328 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 5.3870849609375, -1.1350402832031, 20.510139465332 ), ang = Angle( -28.905782699585, 1.7245198488235, 90.246459960938 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.0484619140625, 3.9142150878906, 0.38245391845703 ), ang = Angle( 71.795204162598, 46.498275756836, -58.836250305176 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 3.7898559570313, 7.9361724853516, -16.571220397949 ), ang = Angle( 77.528251647949, 148.62348937988, 41.270652770996 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 0.74298095703125, 9.7942810058594, -32.706504821777 ), ang = Angle( 36.538288116455, 16.847925186157, -83.307777404785 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -2.8494262695313, -3.2269134521484, -33.70858001709 ), ang = Angle( 32.974117279053, -13.765295028687, -97.300735473633 ) },
			},



			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 23.257751464844, -0.11167907714844, 7.9162979125977 ), ang = Angle( 1.7543541193008, -82.079612731934, 103.84712219238 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 24.315185546875, -0.31355285644531, 19.385238647461 ), ang = Angle( -67.351531982422, -177.20571899414, -94.728652954102 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 19.418884277344, 7.0769195556641, 27.499145507813 ), ang = Angle( 85.93529510498, 140.52824401855, -143.62800598145 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 19.330139160156, -8.0277404785156, 26.958953857422 ), ang = Angle( 89.347351074219, -84.41414642334, 21.622308731079 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 19.279235839844, -8.5591888427734, 15.165336608887 ), ang = Angle( 87.950714111328, -36.233375549316, 70.122840881348 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 19.657775878906, -8.6903381347656, 3.776252746582 ), ang = Angle( 69.378860473633, -114.56415557861, 111.6315612793 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 19.363464355469, 8.0017242431641, 15.795341491699 ), ang = Angle( 86.412475585938, 85.597587585449, 161.21076965332 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 19.418579101563, 8.7180328369141, 4.3361587524414 ), ang = Angle( 67.907028198242, 138.86090087891, 62.954296112061 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 22.724365234375, 3.7384185791016, 8.0578994750977 ), ang = Angle( 82.150375366211, 168.94790649414, -101.69077301025 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 20.34619140625, 4.2230987548828, -9.651008605957 ), ang = Angle( 63.87532043457, 4.0286407470703, 93.664482116699 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 16.03662109375, -0.49882507324219, 32.363265991211 ), ang = Angle( -43.571979522705, -178.34861755371, 87.717384338379 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 23.798767089844, -3.9767303466797, 7.7876892089844 ), ang = Angle( 81.344146728516, -47.075843811035, 25.93105506897 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 25.665344238281, -6.023193359375, -9.9019470214844 ), ang = Angle( 73.72550201416, -13.137495040894, 59.944664001465 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 30.175109863281, -7.0757904052734, -25.765022277832 ), ang = Angle( 71.86238861084, -122.5951461792, -52.263179779053 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 27.604675292969, 4.7342987060547, -24.487998962402 ), ang = Angle( 72.258445739746, 140.32360839844, -124.01677703857 ) },
			},
		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Spine2",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -6.8897595405579, 99.260620117188, 139.38592529297 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 5.9170532226563, -0.23785400390625, 9.8187484741211 ), ang = Angle( -13.813053131104, 5.0810079574585, -81.70484161377 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 15.937866210938, -6.8105926513672, 9.5666198730469 ), ang = Angle( 69.113426208496, -13.051495552063, -157.74856567383 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 14.017272949219, 8.3289337158203, 11.590972900391 ), ang = Angle( 59.927448272705, 53.602779388428, 0.45431473851204 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 17.493957519531, 13.045043945313, 1.4723510742188 ), ang = Angle( 32.163520812988, -15.569325447083, -53.706535339355 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 26.856872558594, 10.436248779297, -4.639778137207 ), ang = Angle( 21.985660552979, 34.317802429199, 21.224462509155 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 20.082397460938, -7.6825714111328, -1.369499206543 ), ang = Angle( 17.387557983398, 46.965496063232, -110.19738769531 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 27.559936523438, 0.326416015625, -4.8006210327148 ), ang = Angle( 22.206241607666, 11.76087474823, -175.37835693359 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.693115234375, -3.6066436767578, 1.0343322753906 ), ang = Angle( 41.42932510376, -6.0640358924866, -89.298980712891 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 14.002685546875, -4.785400390625, -10.818428039551 ), ang = Angle( 69.857124328613, 171.59799194336, 88.753051757813 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 21.175354003906, 1.5027923583984, 10.892082214355 ), ang = Angle( -23.649711608887, -5.6789031028748, 105.87480163574 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.73358154296875, 4.1591033935547, 0.58789825439453 ), ang = Angle( 44.825244903564, 34.788433074951, -68.946601867676 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 9.1207275390625, 11.119613647461, -10.89232635498 ), ang = Angle( 52.813613891602, -177.77328491211, 64.796478271484 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -0.8597412109375, 10.731536865234, -24.057548522949 ), ang = Angle( 43.396427154541, 37.430210113525, -71.737983703613 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 8.3200073242188, -3.9586029052734, -26.078086853027 ), ang = Angle( 33.660411834717, -21.196577072144, -95.139938354492 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 54.849609375, 3.3659057617188, -24.530601501465 ), ang = Angle( -11.929397583008, -92.679656982422, 9.1361036300659 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 66.071472167969, 2.4747467041016, -26.612037658691 ), ang = Angle( -3.2643823623657, -3.7963812351227, 90.505516052246 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 75.471740722656, 9.5970306396484, -24.580558776855 ), ang = Angle( 16.205446243286, 40.117076873779, -60.402877807617 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 74.559204101563, -5.8182220458984, -24.732353210449 ), ang = Angle( 16.312370300293, -153.03372192383, -102.49490356445 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 64.557495117188, -10.906967163086, -28.016502380371 ), ang = Angle( 1.0744324922562, -149.7001953125, -101.9864654541 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 54.645141601563, -16.700042724609, -28.278465270996 ), ang = Angle( 5.5106058120728, -121.40423583984, -1.1086935997009 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 84.05810546875, 16.831832885742, -27.843742370605 ), ang = Angle( 2.8062832355499, 32.622589111328, -61.650783538818 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 93.716857910156, 23.014221191406, -28.405876159668 ), ang = Angle( 17.613695144653, 27.263252258301, -96.707763671875 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 55.096374511719, 7.3756408691406, -25.667808532715 ), ang = Angle( -73.598785400391, 164.89109802246, -68.504547119141 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 50.232299804688, 8.6949157714844, -8.5293655395508 ), ang = Angle( -6.1523423194885, -175.04188537598, -84.039512634277 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 81.026245117188, 1.4589538574219, -23.10196685791 ), ang = Angle( 7.8665494918823, -10.787055015564, -90.39574432373 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 54.671997070313, -0.4366455078125, -23.727043151855 ), ang = Angle( -26.782358169556, 176.37213134766, -87.84447479248 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 38.7685546875, 0.56489562988281, -15.685340881348 ), ang = Angle( 42.227771759033, 179.07579040527, -87.473510742188 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 26.533569335938, 0.76225280761719, -26.791618347168 ), ang = Angle( -25.153064727783, 174.02621459961, -88.061370849609 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 33.863708496094, 7.2748870849609, -6.7583160400391 ), ang = Angle( -33.376106262207, -173.79089355469, -83.997657775879 ) },
			},


		},
	},

	--third move
	[ 3 ] = {
		bone = "ValveBiped.Bip01_Spine2",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 16.85856628418, 157.43649291992, 96.920707702637 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -3.9347534179688, -0.23440551757813, 10.258918762207 ), ang = Angle( -30.901126861572, 78.265357971191, -96.89234161377 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 5.35107421875, 6.0124816894531, 14.539222717285 ), ang = Angle( 39.798767089844, -48.638465881348, 145.86639404297 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -9.4786987304688, 10.048080444336, 12.907524108887 ), ang = Angle( 64.689392089844, -156.46745300293, 35.491268157959 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -14.061828613281, 8.0521850585938, 2.3374404907227 ), ang = Angle( 35.464847564697, 90.604766845703, -64.698303222656 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -14.159484863281, 17.404052734375, -4.3241424560547 ), ang = Angle( 26.317462921143, 106.92729949951, 53.07527923584 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 11.287414550781, -0.73001098632813, 7.0548782348633 ), ang = Angle( 32.763782501221, 55.97766494751, -139.13531494141 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 16.689514160156, 7.2722930908203, 0.84127044677734 ), ang = Angle( 9.6038036346436, 36.999450683594, 118.00065612793 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 3.426025390625, -1.3692474365234, 0.96572875976563 ), ang = Angle( 6.9697232246399, 67.678009033203, -105.74069213867 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 9.8546142578125, 15.139602661133, -1.213493347168 ), ang = Angle( 57.063320159912, -86.059730529785, 119.23272705078 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -0.70208740234375, 13.764495849609, 15.788711547852 ), ang = Angle( 1.420673251152, 89.700149536133, 61.512477874756 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -3.8074340820313, 1.2236175537109, -0.92020416259766 ), ang = Angle( 9.498984336853, 81.279403686523, -96.897811889648 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -0.83978271484375, 18.46484375, -3.7472991943359 ), ang = Angle( 41.076557159424, -90.492286682129, 99.48168182373 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -0.99627685546875, 6.2025451660156, -14.160186767578 ), ang = Angle( 61.429580688477, 82.123428344727, -96.652793884277 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 10.542663574219, 6.2229309082031, -14.590911865234 ), ang = Angle( 42.092990875244, 58.607368469238, -104.92440032959 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( -3.92919921875, 7.6999816894531, -26.655151367188 ), ang = Angle( 0.49201440811157, -89.536270141602, 7.8319110870361 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 7.3178100585938, 7.8090515136719, -29.168090820313 ), ang = Angle( 0.66208118200302, 6.9656782150269, 90.134422302246 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 15.374114990234, 16.577301025391, -27.869354248047 ), ang = Angle( -2.7903473377228, 153.68620300293, -92.040916442871 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 17.32470703125, 1.1914978027344, -27.865234375 ), ang = Angle( 10.910603523254, -143.3039855957, -65.775581359863 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 8.1188354492188, -5.6693115234375, -30.078384399414 ), ang = Angle( -2.6188876628876, -149.32536315918, -66.21435546875 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -1.7557373046875, -10.428131103516, -29.612899780273 ), ang = Angle( 0.15973775088787, -167.09698486328, -1.1481994390488 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 4.8497924804688, 21.779006958008, -27.241806030273 ), ang = Angle( -42.528259277344, 155.4510345459, -92.753112792969 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -2.8466796875, 25.294464111328, -19.480712890625 ), ang = Angle( -46.885028839111, 117.64729309082, 172.9930267334 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -4.1019287109375, 11.490570068359, -26.836517333984 ), ang = Angle( -32.743179321289, -176.41468811035, -99.075271606445 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -19.004150390625, 10.498397827148, -17.074127197266 ), ang = Angle( 45.073936462402, 170.60639953613, -101.76857757568 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 22.40087890625, 9.6455535888672, -26.692565917969 ), ang = Angle( 7.4597911834717, 0.64237350225449, -85.763122558594 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -3.8667602539063, 3.6626739501953, -26.710540771484 ), ang = Angle( -19.795141220093, -165.42175292969, -101.89726257324 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -20.119995117188, -0.53616333007813, -20.668075561523 ), ang = Angle( 26.063014984131, -174.99415588379, -102.4861907959 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -34.908203125, -1.8311920166016, -27.839721679688 ), ang = Angle( -3.004412651062, -176.03329467773, -100.08625030518 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -30.517761230469, 12.403137207031, -28.774307250977 ), ang = Angle( -19.678659439087, 156.94985961914, -87.166702270508 ) },
			},

		},
	},

}

RagdollFight.XRayStances[ 4 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Spine1",
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 1.3359001874924, 140.04496765137, 104.12547302246 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -0.71484375, -0.4012451171875, 11.115127563477 ), ang = Angle( -75.810020446777, 30.31223487854, -59.755676269531 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 8.5135498046875, -1.9913787841797, 18.584281921387 ), ang = Angle( 61.773216247559, -17.731424331665, -132.22456359863 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -4.758544921875, 5.7596435546875, 20.551826477051 ), ang = Angle( 66.293388366699, -175.01818847656, 67.454750061035 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -9.4359130859375, 5.3286743164063, 9.8071365356445 ), ang = Angle( 52.406826019287, 35.646900177002, -77.138702392578 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -3.6312866210938, 9.3323669433594, 0.72420501708984 ), ang = Angle( 53.860218048096, 45.177379608154, 27.188177108765 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 14.051391601563, -3.5098571777344, 7.9258728027344 ), ang = Angle( 11.263153076172, 13.08837890625, -95.657012939453 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 25.019409179688, -0.9598388671875, 5.6833267211914 ), ang = Angle( -18.34895324707, 25.845924377441, -121.86887359619 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 3.0421752929688, -2.6881408691406, 0.13668060302734 ), ang = Angle( 65.69921875, 15.553094863892, -112.0280456543 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 10.414001464844, -1.9277954101563, -15.594085693359 ), ang = Angle( 70.872314453125, -137.25357055664, 116.51742553711 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 3.7372436523438, 3.748291015625, 25.255859375 ), ang = Angle( -50.608043670654, 20.326391220093, 108.69096374512 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -3.089599609375, 2.5062255859375, 0.065544128417969 ), ang = Angle( 67.874214172363, 82.015701293945, -67.433052062988 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -2.3857421875, 9.0114593505859, -15.616180419922 ), ang = Angle( 64.77921295166, -135.38470458984, 67.168426513672 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -7.398193359375, 4.0658721923828, -30.566101074219 ), ang = Angle( 33.604278564453, 80.47932434082, -75.101280212402 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 6.4374389648438, -5.6032104492188, -31.206985473633 ), ang = Angle( 33.288669586182, 6.4183664321899, -98.42684173584 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 32.538146972656, 1.51611328125, 3.5342330932617 ), ang = Angle( 2.4385628700256, -83.95923614502, 87.567321777344 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 36.758178710938, 1.4993896484375, 14.15397644043 ), ang = Angle( -42.453330993652, -163.7767791748, -101.63558197021 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 28.826110839844, 7.8335113525391, 19.981018066406 ), ang = Angle( 29.261224746704, 39.617092132568, 99.239753723145 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 30.493713378906, -7.9131927490234, 18.119560241699 ), ang = Angle( 27.423152923584, 7.4450736045837, 86.008155822754 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 40.800231933594, -6.5733947753906, 12.777862548828 ), ang = Angle( 52.494590759277, -166.10864257813, -84.54557800293 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 34.014282226563, -8.2516479492188, 3.6695022583008 ), ang = Angle( 45.48962020874, -176.88342285156, -39.466354370117 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 36.683898925781, 14.337951660156, 14.26579284668 ), ang = Angle( 48.135955810547, -154.01271057129, -102.11626434326 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 29.796081542969, 10.980438232422, 5.7150192260742 ), ang = Angle( 47.524322509766, -176.3270111084, 165.90313720703 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 32.128845214844, 5.3836975097656, 3.6980972290039 ), ang = Angle( 83.765060424805, 102.21968841553, 174.71488952637 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 31.717407226563, 7.2781372070313, -14.040641784668 ), ang = Angle( 63.081371307373, 29.915868759155, 103.85163116455 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 24.182556152344, -1.6028900146484, 22.474319458008 ), ang = Angle( -20.094257354736, -178.77212524414, 85.419776916504 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 32.961120605469, -2.3768005371094, 3.3523941040039 ), ang = Angle( 76.497314453125, -2.0409305095673, 71.364280700684 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 37.228942871094, -2.7588043212891, -14.077606201172 ), ang = Angle( 71.025917053223, 4.7245116233826, 75.217140197754 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 42.583740234375, -2.3162536621094, -29.704956054688 ), ang = Angle( 46.19548034668, -162.10614013672, -89.145622253418 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 38.201904296875, 11.009307861328, -28.775375366211 ), ang = Angle( 38.92699432373, 174.33102416992, -108.40965270996 ) },
			},

		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Spine2",

		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -2.5741028785706, -167.76969909668, 100.33358001709 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 1.850341796875, -1.6113891601563, 11.102867126465 ), ang = Angle( -28.994325637817, 83.085830688477, -91.649436950684 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 10.56787109375, 5.9013061523438, 14.517562866211 ), ang = Angle( 47.253490447998, -80.686935424805, 119.38244628906 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -5.0847778320313, 8.7052001953125, 13.924743652344 ), ang = Angle( 73.274223327637, 74.083854675293, -83.165382385254 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -4.161865234375, 11.941223144531, 2.7268447875977 ), ang = Angle( -42.814315795898, 65.716468811035, -87.324043273926 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -0.69818115234375, 19.618408203125, 10.530075073242 ), ang = Angle( -36.900543212891, 83.235801696777, -27.689605712891 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 11.789306640625, -1.8247680664063, 6.2000579833984 ), ang = Angle( 61.124313354492, 37.405738830566, -132.72401428223 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 16.193664550781, 1.5432739257813, -3.8541107177734 ), ang = Angle( 52.910820007324, 15.648118019104, 126.48336791992 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 3.8362426757813, 0.80511474609375, 0.060081481933594 ), ang = Angle( 80.364051818848, -39.741947174072, 137.32778930664 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 6.1203002929688, -1.1085815429688, -17.53825378418 ), ang = Angle( 78.317329406738, -49.601253509521, 127.63459014893 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 3.6775512695313, 12.822326660156, 16.135864257813 ), ang = Angle( -26.982990264893, 70.167152404785, 79.650115966797 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -3.9759521484375, -1.3131103515625, -0.61068725585938 ), ang = Angle( 72.374076843262, 133.88206481934, -71.3095703125 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -7.6807250976563, 3.1622924804688, -17.509338378906 ), ang = Angle( 82.972671508789, -120.36141204834, 34.092811584473 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -8.70263671875, 1.4178466796875, -33.910438537598 ), ang = Angle( 34.179225921631, 109.18872833252, -89.208465576172 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 8.2904663085938, -3.66162109375, -33.688148498535 ), ang = Angle( 31.720684051514, 72.566268920898, -104.43852996826 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 9.4136962890625, 12.023681640625, -7.5022354125977 ), ang = Angle( -26.551231384277, -82.560623168945, 173.65589904785 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -1.1617431640625, 12.861694335938, -3.0903015136719 ), ang = Angle( -11.045728683472, 178.81044006348, -79.402633666992 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -10.426330566406, 20.3955078125, -4.0855331420898 ), ang = Angle( 77.239280700684, 101.24185180664, 178.46971130371 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -9.9988403320313, 6.9110107421875, -1.0449066162109 ), ang = Angle( 47.929916381836, 6.1355714797974, 122.47018432617 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -2.3672485351563, 5.4527587890625, -11.59268951416 ), ang = Angle( 35.837947845459, -0.73139208555222, 116.32228851318 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 7.0899658203125, 5.2896728515625, -17.426788330078 ), ang = Angle( 57.080974578857, -38.70043182373, -140.57339477539 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -10.929809570313, 22.928649902344, -15.489318847656 ), ang = Angle( 26.019441604614, -173.53395080566, -104.22343444824 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -21.182189941406, 21.7666015625, -20.526054382324 ), ang = Angle( 13.856313705444, 147.6130065918, 151.34939575195 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 8.9588623046875, 15.519165039063, -9.2638854980469 ), ang = Angle( 54.026203155518, -7.18528175354, 66.93773651123 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 19.403686523438, 14.188781738281, -23.698692321777 ), ang = Angle( 2.4736394882202, 11.252962112427, 76.798439025879 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -16.5517578125, 12.693542480469, -2.7422866821289 ), ang = Angle( 7.8604774475098, 164.84524536133, 94.988075256348 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 9.8800659179688, 8.5277099609375, -5.7520523071289 ), ang = Angle( 50.63423538208, -18.908782958984, 65.040184020996 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 20.638488769531, 4.8809814453125, -19.576316833496 ), ang = Angle( 13.721494674683, -3.075511932373, 74.011901855469 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 36.669006347656, 4.0196533203125, -23.496147155762 ), ang = Angle( 48.374614715576, 4.9443473815918, 85.502716064453 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 35.596130371094, 17.410522460938, -24.411918640137 ), ang = Angle( 42.397449493408, 31.133430480957, 102.49083709717 ) },
			},

		},

	},

	--third move
	[ 3 ] = {

		bone = "ValveBiped.Bip01_Spine2",
		offset = -1* vector_up * 16,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -4.4032669067383, -175.7038269043, 118.78771209717 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 1.314208984375, 2.1968383789063, 12.248588562012 ), ang = Angle( -9.483814239502, 92.663948059082, -51.603408813477 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 6.04443359375, 12.32958984375, 7.952278137207 ), ang = Angle( 73.47435760498, -113.18750762939, 25.80392074585 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -6.020263671875, 10.343017578125, 17.419784545898 ), ang = Angle( 61.399940490723, -168.74687194824, 37.869430541992 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -11.509887695313, 9.250732421875, 7.1539535522461 ), ang = Angle( 52.275489807129, 91.566612243652, -51.859214782715 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -11.701965332031, 16.273315429688, -1.927619934082 ), ang = Angle( 47.441581726074, 110.60167694092, 31.38597869873 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 4.729736328125, 9.2794799804688, -3.1798400878906 ), ang = Angle( 10.266934394836, 132.74353027344, -74.747261047363 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -2.9382934570313, 17.576538085938, -5.2262802124023 ), ang = Angle( 14.763154029846, 135.09590148926, 179.6037902832 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 3.8822631835938, 0.28338623046875, -0.17469787597656 ), ang = Angle( 71.579620361328, -75.819068908691, 83.545181274414 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 5.2731323242188, -5.1964111328125, -17.124580383301 ), ang = Angle( -6.8225932121277, -69.42862701416, 87.795524597168 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -1.0416259765625, 17.403625488281, 12.698043823242 ), ang = Angle( 3.7530794143677, 111.18883514404, 108.09107971191 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -3.8681030273438, -0.29058837890625, 0.29868316650391 ), ang = Angle( 82.658187866211, 113.02714538574, -58.072803497314 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -4.7709350585938, 1.79150390625, -16.970481872559 ), ang = Angle( -7.0937905311584, -98.087867736816, 84.644172668457 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -7.0909423828125, -14.419616699219, -15.163047790527 ), ang = Angle( 19.069158554077, -97.952758789063, 84.483367919922 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 11.038513183594, -20.558349609375, -15.161460876465 ), ang = Angle( 20.034492492676, -74.958839416504, 87.351585388184 ) },
			},



			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 1.3777465820313, 15.35400390625, -16.058052062988 ), ang = Angle( 7.8374447822571, -98.003036499023, 167.41589355469 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -8.4284057617188, 15.905395507813, -10.093193054199 ), ang = Angle( 1.0987341403961, -176.21894836426, -81.262138366699 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -17.913330078125, 22.7119140625, -12.805229187012 ), ang = Angle( -6.5233340263367, 37.196842193604, 43.400867462158 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -16.966003417969, 7.4696044921875, -10.42017364502 ), ang = Angle( 51.226726531982, -28.931873321533, 56.34009552002 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -10.737121582031, 3.9821166992188, -18.955101013184 ), ang = Angle( -1.4556992053986, 178.33897399902, -69.49186706543 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -22.22021484375, 4.3119506835938, -18.913383483887 ), ang = Angle( -25.820518493652, -159.36296081543, 55.281272888184 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -8.72314453125, 29.692260742188, -11.447486877441 ), ang = Angle( 25.127147674561, 1.1642175912857, 37.232082366943 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 1.669921875, 29.903472900391, -16.322929382324 ), ang = Angle( 63.55362701416, 10.401187896729, -86.07332611084 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.7980346679688, 19.348388671875, -15.318504333496 ), ang = Angle( 6.5570993423462, 2.1374027729034, 82.626762390137 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 19.503356933594, 19.958129882813, -17.753105163574 ), ang = Angle( -45.139415740967, 10.899076461792, 79.241584777832 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -23.480712890625, 14.507019042969, -13.003684997559 ), ang = Angle( 10.259149551392, 160.12889099121, 73.570205688477 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.81585693359375, 11.44091796875, -16.54174041748 ), ang = Angle( 2.3012011051178, -16.276180267334, 111.50674438477 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 17.923034667969, 6.50244140625, -17.378395080566 ), ang = Angle( -30.900314331055, -31.072519302368, 115.34476470947 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 30.068176269531, -0.8160400390625, -8.8919143676758 ), ang = Angle( 35.396099090576, -10.564794540405, 110.05784606934 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 30.94970703125, 22.162170410156, -6.0395889282227 ), ang = Angle( 30.678308486938, 8.506175994873, 87.896286010742 ) },
			},

		},
	},
}

RagdollFight.XRayStances[ 5 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Spine1",
		weapon = {
			{ mdl = Model( "models/props_canal/mattpipe.mdl" ), bone = "ValveBiped.Bip01_L_Hand", pos = Vector( 5.2192993164063, -2.340576171875, -7.691047668457 ), ang = Angle( 10.948788642883, -170.37492370605, 176.06504821777 ) },
		},
		extra_sound = function( self ) self:EmitSound( "ambient/machines/slicer"..math.random(1,2)..".wav", 120, math.random( 75, 85 ) ) end,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -1.5611518621445, 110.66674041748, 111.29476165771 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 0.53984069824219, -0.132568359375, 11.446701049805 ), ang = Angle( -84.328941345215, -6.1361198425293, -70.075439453125 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 4.5837554931641, -7.4133911132813, 20.094871520996 ), ang = Angle( 59.614070892334, 15.537550926208, -99.919784545898 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 0.93815612792969, 7.5956420898438, 20.58634185791 ), ang = Angle( 42.760581970215, 1.8549958467484, -58.459774017334 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 9.6526794433594, 7.998779296875, 12.635612487793 ), ang = Angle( -25.926572799683, -33.17414855957, -65.048194885254 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 18.200790405273, 2.2721557617188, 17.658561706543 ), ang = Angle( -27.233018875122, 3.9678778648376, -4.1630454063416 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 10.281951904297, -5.8291015625, 10.008422851563 ), ang = Angle( -37.156101226807, 27.917356491089, -96.276809692383 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 18.367828369141, -1.544677734375, 16.943237304688 ), ang = Angle( -32.02180480957, -18.189870834351, -164.08125305176 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.1660461425781, -3.444580078125, 0.35836791992188 ), ang = Angle( 59.613594055176, 3.4139215946198, -93.150466918945 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 10.119674682617, -2.6906127929688, -15.077499389648 ), ang = Angle( 57.307472229004, -171.00593566895, 93.801330566406 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 4.5922088623047, 0.3402099609375, 26.291007995605 ), ang = Angle( -60.747982025146, -7.9771389961243, 96.04810333252 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -1.4459838867188, 3.9569091796875, 0.062431335449219 ), ang = Angle( 58.645740509033, 47.546363830566, -74.133003234863 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 4.8903961181641, 10.478881835938, -15.083358764648 ), ang = Angle( 61.848106384277, -162.39042663574, 71.3203125 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -2.5410003662109, 8.1200561523438, -29.653656005859 ), ang = Angle( 39.341941833496, 44.528465270996, -78.11336517334 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 1.3036193847656, -4.0861206054688, -28.984832763672 ), ang = Angle( 44.845367431641, -6.7684798240662, -99.043884277344 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 26.585723876953, -0.00335693359375, -5.0865631103516 ), ang = Angle( -5.9897074699402, -71.837791442871, 84.529640197754 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 31.000381469727, 1.3487548828125, 5.1323394775391 ), ang = Angle( -59.064685821533, 5.5675230026245, 98.979637145996 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 32.281448364258, 10.185363769531, 13.853622436523 ), ang = Angle( 79.41478729248, 47.777835845947, 114.92468261719 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 36.257522583008, -6.0140380859375, 13.006057739258 ), ang = Angle( 84.854484558105, -63.271724700928, 17.997718811035 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 36.721008300781, -6.8876953125, 1.5160598754883 ), ang = Angle( 51.755229949951, -164.61685180664, -80.575187683105 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 29.868240356445, -8.7730712890625, -7.501335144043 ), ang = Angle( 2.662086725235, -128.4815826416, 71.782913208008 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 33.724868774414, 11.776000976563, 2.3600311279297 ), ang = Angle( 45.901695251465, -161.36917114258, -96.387100219727 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 26.153625488281, 9.223388671875, -5.8855056762695 ), ang = Angle( 41.807300567627, 167.77983093262, 148.67460632324 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 25.215270996094, 3.70654296875, -5.6298599243164 ), ang = Angle( 78.334892272949, 50.898109436035, 105.76133728027 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 27.625335693359, 6.1983642578125, -23.02473449707 ), ang = Angle( 7.8885145187378, 37.229423522949, 90.354675292969 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 36.56413269043, 1.4754028320313, 19.485992431641 ), ang = Angle( -65.762680053711, 69.656692504883, -161.8459777832 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 27.791778564453, -3.6798095703125, -4.6806182861328 ), ang = Angle( 71.990707397461, -122.1558380127, -46.950710296631 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 24.870651245117, -8.390869140625, -21.631454467773 ), ang = Angle( 11.555492401123, 13.854550361633, 77.50756072998 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 40.589874267578, -4.5140380859375, -24.941741943359 ), ang = Angle( 82.43106842041, 30.661375045776, 101.26485443115 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 40.658554077148, 16.101684570313, -25.292755126953 ), ang = Angle( 62.154685974121, 43.25186920166, 98.335380554199 ) },
			},


		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Head1",
		weapon = {
			{ mdl = Model( "models/props_canal/mattpipe.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 3.1847229003906, -1.790771484375, 0.2716064453125 ), ang = Angle( 9.1809034347534, -41.821220397949, 18.365940093994 ) },
		},
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 9.9483470916748, 109.20789337158, 101.65554046631 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -2.69677734375, 2.6558837890625, 11.616638183594 ), ang = Angle( -59.296424865723, 20.351770401001, -119.30284881592 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 2.2958984375, -4.1460571289063, 20.776481628418 ), ang = Angle( 75.108688354492, -127.4377822876, 160.5758972168 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 3.7611999511719, 10.842834472656, 17.153770446777 ), ang = Angle( 38.07494354248, 168.72871398926, 93.514381408691 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -5.2656860351563, 12.641906738281, 9.9430618286133 ), ang = Angle( 77.822326660156, -26.376739501953, -103.22393035889 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -3.0958557128906, 11.565856933594, -1.2802505493164 ), ang = Angle( 48.702152252197, 73.580757141113, 75.104568481445 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 0.46926879882813, -6.531982421875, 9.4766235351563 ), ang = Angle( 58.735725402832, -41.686721801758, -117.83876037598 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 4.9193115234375, -10.494995117188, -0.33772277832031 ), ang = Angle( 51.498985290527, -60.712867736816, 120.78597259521 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.3690490722656, -3.73974609375, 0.70825958251953 ), ang = Angle( 17.429052352905, 7.3086729049683, -104.75255584717 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 18.251342773438, -1.589599609375, -4.6260223388672 ), ang = Angle( 30.664176940918, 3.1350100040436, -106.71341705322 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 6.8778076171875, 4.8236083984375, 23.475280761719 ), ang = Angle( -35.820423126221, 14.918839454651, 76.584808349609 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -1.3478088378906, 3.6892700195313, -0.60305023193359 ), ang = Angle( 53.976188659668, 35.066570281982, -83.363845825195 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 6.9216613769531, 9.6072387695313, -14.679267883301 ), ang = Angle( 58.606746673584, -163.80206298828, 80.018005371094 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -1.3447875976563, 7.2060546875, -28.785415649414 ), ang = Angle( 42.47758102417, 35.88697052002, -80.604774475098 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 32.444610595703, -0.812255859375, -13.053985595703 ), ang = Angle( -26.320142745972, 1.3607293367386, -94.262969970703 ) },
			},



			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 67.181976318359, 2.6637573242188, -29.613708496094 ), ang = Angle( -1.5475475788116, -91.599159240723, 163.67105102539 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 57.956756591797, 3.1520385742188, -23.439727783203 ), ang = Angle( -44.373573303223, -178.087890625, -70.431945800781 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 48.591217041016, 9.6282348632813, -19.857467651367 ), ang = Angle( 33.213451385498, 25.585741043091, 128.9295501709 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 52.626586914063, -4.7697143554688, -16.17106628418 ), ang = Angle( 46.112884521484, -7.1291666030884, 33.613246917725 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 60.577545166016, -5.81982421875, -24.483840942383 ), ang = Angle( 45.171630859375, -4.9336113929749, 35.118846893311 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 68.63037109375, -6.5020751953125, -32.631301879883 ), ang = Angle( -20.156955718994, -8.2104349136353, 91.35595703125 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 57.414398193359, 13.852844238281, -26.262176513672 ), ang = Angle( 38.209064483643, 152.60919189453, -131.99375915527 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 49.428131103516, 17.988159179688, -33.51887512207 ), ang = Angle( -33.514938354492, 153.70771789551, 82.582473754883 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 67.261291503906, 6.554443359375, -29.78987121582 ), ang = Angle( 0.82356953620911, 10.378224372864, 74.235649108887 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 84.815765380859, 9.76904296875, -30.584106445313 ), ang = Angle( -58.660007476807, 38.104831695557, 58.656097412109 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 46.062042236328, 1.8187255859375, -15.017349243164 ), ang = Angle( -54.369159698486, -155.93699645996, 90.329460144043 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 67.044891357422, -1.225341796875, -29.760848999023 ), ang = Angle( 0.81021356582642, -2.7420587539673, 100.18914031982 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 84.870697021484, -2.079345703125, -30.242446899414 ), ang = Angle( -25.540790557861, -7.8484559059143, 101.39427947998 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 99.641418457031, -4.1153564453125, -23.117523193359 ), ang = Angle( 4.8933854103088, -14.024995803833, 92.713600158691 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 91.579071044922, 15.073120117188, -16.469955444336 ), ang = Angle( -27.806093215942, 34.199207305908, 72.302894592285 ) },
			},


		},

	},

	--third move
	[ 3 ] = {

		bone = "ValveBiped.Bip01_Head1",
		offset = -1* vector_up * 16,
		weapon = {
			{ mdl = Model( "models/props_canal/mattpipe.mdl" ), bone = "ValveBiped.Bip01_L_Hand", pos = Vector( 2.1417846679688, -3.4600219726563, -1.8284454345703 ), ang = Angle( -19.320419311523, -41.820449829102, 146.86383056641 ) },
		},
		extra_sound = function( self ) self:EmitSound( "ambient/machines/slicer"..math.random(1,2)..".wav", 120, math.random( 75, 85 ) ) end,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -2.1825263500214, 81.988822937012, 124.17092895508 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 2.4513854980469, -0.34710693359375, 10.886497497559 ), ang = Angle( -31.791677474976, 4.0625553131104, -88.753219604492 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 11.494262695313, -7.4110107421875, 14.331275939941 ), ang = Angle( 68.122352600098, 20.489377975464, -124.776512146 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 10.217864990234, 7.9757080078125, 14.620620727539 ), ang = Angle( 77.931304931641, -0.96542632579803, -67.950042724609 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 12.675231933594, 7.9310913085938, 3.1758651733398 ), ang = Angle( 27.852613449097, -20.189977645874, -84.900199890137 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 22.20295715332, 4.4273681640625, -2.1883544921875 ), ang = Angle( -4.8796963691711, 35.557231903076, 39.752700805664 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 15.620086669922, -5.84814453125, 3.4508361816406 ), ang = Angle( 10.079642295837, 51.054275512695, -102.52249908447 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 22.725860595703, 2.9439697265625, 1.4413452148438 ), ang = Angle( -8.5163593292236, -2.9850828647614, 158.27058410645 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.62738037109375, -3.8522338867188, -0.089599609375 ), ang = Angle( 55.018054962158, -8.1138973236084, -103.03257751465 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 9.6822509765625, -4.7149047851563, -14.955764770508 ), ang = Angle( -7.3789987564087, 178.12950134277, 102.22351074219 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 16.697265625, 0.7225341796875, 16.623123168945 ), ang = Angle( -27.77836227417, 13.293678283691, 97.139556884766 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.54180908203125, 3.8496704101563, 0.14816284179688 ), ang = Angle( 56.597072601318, 19.583242416382, -64.532958984375 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 9.7992553710938, 7.1431274414063, -14.751831054688 ), ang = Angle( -8.3270664215088, 179.94418334961, 76.158142089844 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -6.5135498046875, 7.1585693359375, -12.732757568359 ), ang = Angle( 16.569404602051, 152.68798828125, 60.059833526611 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -6.6973876953125, -4.179931640625, -12.833389282227 ), ang = Angle( 18.08588218689, -174.82148742676, 103.51271820068 ) },
			},




			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 53.598388671875, 3.486328125, -13.155349731445 ), ang = Angle( 2.4096717834473, -80.572189331055, -176.50791931152 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 42.50358581543, 1.35986328125, -10.050704956055 ), ang = Angle( -6.0019073486328, 167.76322937012, -91.307678222656 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 35.209625244141, 11.060485839844, -10.116317749023 ), ang = Angle( 27.486015319824, 9.0899324417114, 131.70916748047 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 31.896606445313, -4.3225708007813, -10.487045288086 ), ang = Angle( -15.616541862488, -55.110149383545, 52.556716918945 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 38.337860107422, -13.559387207031, -7.3394317626953 ), ang = Angle( 53.166374206543, -172.10523986816, -12.389351844788 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 31.519943237305, -14.504821777344, -16.529144287109 ), ang = Angle( -10.688323974609, -167.58944702148, 90.521606445313 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 45.452133178711, 12.699157714844, -15.512802124023 ), ang = Angle( 11.915379524231, 157.85456848145, -127.10265350342 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 35.07177734375, 16.922058105469, -18.270874023438 ), ang = Angle( -29.054327011108, 152.75680541992, 88.194633483887 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 52.963836669922, 7.3298950195313, -12.9853515625 ), ang = Angle( 2.7083668708801, 16.214847564697, 77.759750366211 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 70.366851806641, 12.375244140625, -13.773712158203 ), ang = Angle( -11.987778663635, 19.834953308105, 76.184616088867 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 27.506530761719, 4.67431640625, -11.100769042969 ), ang = Angle( 24.440391540527, -176.4432220459, 72.772079467773 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 54.226318359375, -0.38848876953125, -13.235168457031 ), ang = Angle( 4.7945351600647, 5.0358490943909, 101.29786682129 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 71.889343261719, 1.1815185546875, -14.802947998047 ), ang = Angle( -19.82172203064, -0.23693853616714, 102.06754302979 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 87.426208496094, 1.1171875, -9.2601623535156 ), ang = Angle( 48.362503051758, -3.358692407608, 90.485992431641 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 85.57275390625, 17.860168457031, -10.341369628906 ), ang = Angle( 43.110618591309, 32.914226531982, 96.189102172852 ) },
			},


		},
	},
}

RagdollFight.XRayStances[ 6 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Head1",
		weapon = {
			{ mdl = Model( "models/weapons/w_357.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 1.6109313964844, -0.579833984375, -1.9194793701172 ), ang = Angle( -10.313669204712, -22.588777542114, -173.70783996582 ) },
			{ mdl = Model( "models/weapons/w_bullet.mdl" ), victim = true, bone = "ValveBiped.Bip01_Head1", pos = Vector( 2.8647766113281, -3.3138427734375, 0.58245849609375 ), ang = Angle( 1.3241603374481, 58.13977432251, 78.139793395996 ) },
		},
		extra_sound = function( self ) self:EmitSound( "weapons/357/357_fire"..math.random(2,3)..".wav", 120, math.random( 75, 85 ) ) end,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -0.25689870119095, 134.69396972656, 93.032745361328 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -1.9705810546875, -2.5062866210938, 10.841537475586 ), ang = Angle( -79.74870300293, 33.220596313477, -78.225273132324 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 5.78369140625, -6.1341552734375, 19.229454040527 ), ang = Angle( 19.834932327271, -0.90763050317764, -123.02912902832 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -5.1018676757813, 4.8162231445313, 19.795066833496 ), ang = Angle( 57.822162628174, 177.75042724609, 59.047740936279 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -11.323974609375, 5.0606689453125, 9.8984603881836 ), ang = Angle( 70.728851318359, 79.206825256348, -33.910621643066 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -10.614318847656, 8.7828979492188, -0.93985748291016 ), ang = Angle( 67.678977966309, 93.911361694336, 105.75572967529 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 16.828491210938, -6.2990112304688, 15.291229248047 ), ang = Angle( -9.5828914642334, 17.294923782349, -121.27071380615 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 27.638122558594, -2.9332275390625, 17.202629089355 ), ang = Angle( -9.2223920822144, -17.861227035522, -175.07955932617 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 2.7472534179688, -2.7593383789063, -0.073509216308594 ), ang = Angle( 77.642532348633, -12.597390174866, -137.98365783691 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 6.1998291015625, -3.8408813476563, -17.001312255859 ), ang = Angle( 67.441040039063, -124.55270385742, 112.99300384521 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 2.1271362304688, 0.823974609375, 25.30241394043 ), ang = Angle( -60.435688018799, -5.4073853492737, 116.50189208984 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -2.743408203125, 2.7547607421875, 0.077743530273438 ), ang = Angle( 76.219093322754, 72.812683105469, -73.067115783691 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -1.5259399414063, 6.79345703125, -16.875129699707 ), ang = Angle( 69.156593322754, -133.45252990723, 78.560333251953 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -5.56982421875, 2.5249633789063, -32.318893432617 ), ang = Angle( 32.974170684814, 65.512153625488, -82.991271972656 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 2.6043090820313, -9.0621948242188, -32.262130737305 ), ang = Angle( 32.678527832031, 28.885776519775, -97.935447692871 ) },
			},



			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 65.147521972656, 1.3681640625, -6.3857727050781 ), ang = Angle( -4.2876348495483, -102.66569519043, 90.572128295898 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 68.861145019531, 1.3681640625, 4.4923324584961 ), ang = Angle( -63.921424865723, 0.72479891777039, 93.942375183105 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 71.027557373047, 9.0079956054688, 13.464492797852 ), ang = Angle( 2.053019285202, 130.13520812988, -159.81782531738 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 72.176910400391, -6.390869140625, 12.995193481445 ), ang = Angle( 42.508430480957, -82.948394775391, -22.909866333008 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 73.224334716797, -14.951171875, 5.1055679321289 ), ang = Angle( -20.897853851318, -161.67729187012, -41.900276184082 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 63.041748046875, -18.3232421875, 9.2010879516602 ), ang = Angle( -81.979347229004, -135.56784057617, 68.969169616699 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 63.483764648438, 17.944946289063, 13.076774597168 ), ang = Angle( -20.189754486084, -132.1630859375, 178.31187438965 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 56.250366210938, 9.957275390625, 17.039443969727 ), ang = Angle( -35.174716949463, -110.71322631836, 16.83123588562 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 66.022125244141, 5.168212890625, -6.6598434448242 ), ang = Angle( 39.573722839355, 149.17616271973, -96.981575012207 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 54.220336914063, 12.21728515625, -18.000915527344 ), ang = Angle( 69.976608276367, 138.53396606445, -106.06318664551 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 73.154174804688, 1.2401733398438, 19.275856018066 ), ang = Angle( -54.676212310791, -10.670526504517, -69.989128112793 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 64.299255371094, -2.5799560546875, -6.0880737304688 ), ang = Angle( 33.707420349121, -179.65643310547, -77.340187072754 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 49.453430175781, -2.5726928710938, -15.935432434082 ), ang = Angle( 79.475341796875, -92.151947021484, 4.2044987678528 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 49.340087890625, -5.5889892578125, -32.182662963867 ), ang = Angle( 31.799510955811, -171.95365905762, -75.733428955078 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 49.960754394531, 16.020141601563, -32.437286376953 ), ang = Angle( 33.498085021973, 156.15756225586, -89.702369689941 ), ignore = true },
			},



		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Pelvis",
		weapon = {
			{ mdl = Model( "models/weapons/w_357.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 1.6109313964844, -0.579833984375, -1.9194793701172 ), ang = Angle( -10.313669204712, -22.588777542114, -173.70783996582 ) },
			{ mdl = Model( "models/weapons/w_bullet.mdl" ), victim = true, bone = "ValveBiped.Bip01_Pelvis", pos = Vector( 1.4468383789063, -0.1302490234375, 1.0774230957031 ), ang = Angle( 72.754280090332, 167.88439941406, 72.396812438965 ) },
		},
		extra_sound = function( self ) self:EmitSound( "weapons/357/357_fire"..math.random(2,3)..".wav", 120, math.random( 75, 85 ) ) end,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 2.3859586715698, 135.45820617676, 91.209754943848 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -3.25390625, -1.9070434570313, 11.305023193359 ), ang = Angle( -75.550788879395, 12.966431617737, -55.961669921875 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 5.3903198242188, -5.6940307617188, 18.699996948242 ), ang = Angle( 28.947875976563, 3.8270525932312, -117.23097991943 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -5.69775390625, 4.8981323242188, 20.836364746094 ), ang = Angle( 42.030750274658, -174.82601928711, 71.036323547363 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -14.347473144531, 4.1149291992188, 13.007843017578 ), ang = Angle( 76.015899658203, 105.33555603027, -2.7119302749634 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -15.081237792969, 6.790771484375, 1.8664474487305 ), ang = Angle( 69.749794006348, 113.39028167725, 92.494171142578 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 15.715148925781, -4.995361328125, 13.024368286133 ), ang = Angle( 21.450305938721, 7.9484329223633, -115.3865814209 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 26.298889160156, -3.5177001953125, 8.8255844116211 ), ang = Angle( 19.838571548462, -8.5579452514648, 170.40505981445 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 2.7937622070313, -2.7178955078125, 0.066085815429688 ), ang = Angle( 77.642532348633, -12.59673500061, -137.98365783691 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 6.2463989257813, -3.7994384765625, -16.861717224121 ), ang = Angle( 67.441040039063, -124.55204772949, 112.99300384521 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 2.1737060546875, 0.8653564453125, 25.442008972168 ), ang = Angle( -48.781341552734, -0.15841414034367, 113.71028900146 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -2.9163208007813, 2.8233642578125, -0.043930053710938 ), ang = Angle( 75.553932189941, 71.096778869629, -74.956367492676 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -1.4313354492188, 6.912353515625, -16.769874572754 ), ang = Angle( 68.824493408203, -133.27560424805, 78.563079833984 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -5.5233764648438, 2.5662841796875, -32.179298400879 ), ang = Angle( 32.974170684814, 65.512802124023, -82.991271972656 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 2.65087890625, -9.0208129882813, -32.122535705566 ), ang = Angle( 32.678527832031, 28.886434555054, -97.935447692871 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 65.02734375, 1.447021484375, -6.097785949707 ), ang = Angle( -10.780628204346, -106.08945465088, 51.851257324219 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 73.857727050781, -3.8494873046875, 0.33969879150391 ), ang = Angle( -24.531511306763, 6.3979263305664, 86.371208190918 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 80.788299560547, 4.7833862304688, 4.8904113769531 ), ang = Angle( 45.297775268555, 152.7412109375, -73.662818908691 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 82.125823974609, -10.580383300781, 5.7776870727539 ), ang = Angle( 44.722217559814, -70.890563964844, -64.706275939941 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 84.845825195313, -18.431884765625, -2.45263671875 ), ang = Angle( 27.313125610352, -79.829696655273, -69.916076660156 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 86.647186279297, -28.473205566406, -7.7210540771484 ), ang = Angle( 59.476860046387, -108.20094299316, 36.639301300049 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 73.359100341797, 8.6025390625, -3.4933319091797 ), ang = Angle( 43.079582214355, 151.74450683594, -74.295539855957 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 65.972015380859, 12.572570800781, -11.335479736328 ), ang = Angle( 21.305912017822, 107.43963623047, 130.05656433105 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 66.091064453125, 5.1941528320313, -6.5064239501953 ), ang = Angle( 39.495067596436, 149.18089294434, -96.940757751465 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 54.262939453125, 12.226989746094, -17.843544006348 ), ang = Angle( 54.57022857666, 146.34060668945, -99.285453796387 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 86.457458496094, -2.267822265625, 9.0428466796875 ), ang = Angle( -10.370626449585, 9.5850067138672, -114.6195526123 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 63.96826171875, -2.2250366210938, -5.3701019287109 ), ang = Angle( 35.737953186035, -178.77156066895, -77.05933380127 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 49.532775878906, -2.5275268554688, -15.75341796875 ), ang = Angle( 75.264114379883, -139.54365539551, -42.837707519531 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 46.334411621094, -5.2550048828125, -31.735130310059 ), ang = Angle( 5.8004579544067, -164.8247833252, -77.827674865723 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 46.289184570313, 17.53662109375, -31.308753967285 ), ang = Angle( -16.088329315186, 159.04307556152, -94.864273071289 ) },
			},


		},

	},

	--third move
	[ 3 ] = {

		bone = "ValveBiped.Bip01_Spine1",
		--offset = -1* vector_up * 16,
		weapon = {
			{ mdl = Model( "models/weapons/w_357.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 1.6109313964844, -0.579833984375, -1.9194793701172 ), ang = Angle( -10.313669204712, -22.588777542114, -173.70783996582 ) },
			{ mdl = Model( "models/weapons/w_bullet.mdl" ), victim = true, bone = "ValveBiped.Bip01_Spine2", pos = Vector( 7.4416198730469, 6.8953552246094, 0.62646484375 ), ang = Angle( -0.4270167350769, -89.975784301758, -104.42044830322 ) },
		},
		extra_sound = function( self ) self:EmitSound( "weapons/357/357_fire"..math.random(2,3)..".wav", 120, math.random( 75, 85 ) ) end,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 3.9387202262878, 136.68203735352, 92.65926361084 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -3.5333862304688, -1.373291015625, 11.444999694824 ), ang = Angle( -76.035415649414, 31.195833206177, -112.73417663574 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 0.89111328125, -7.6519165039063, 20.634574890137 ), ang = Angle( 55.349960327148, -3.4806232452393, -106.34671783447 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -1.5311889648438, 7.5320434570313, 19.214698791504 ), ang = Angle( 48.368324279785, 145.64041137695, 54.889053344727 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -7.942626953125, 11.915283203125, 10.469413757324 ), ang = Angle( 58.425945281982, 35.565929412842, -43.194541931152 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -3.0523681640625, 15.411987304688, 0.68742370605469 ), ang = Angle( 59.491752624512, 37.066955566406, 37.017780303955 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 7.5860595703125, -8.0519409179688, 10.982269287109 ), ang = Angle( 25.890480041504, 5.5670247077942, -100.25746917725 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 17.866638183594, -7.0498046875, 5.9687652587891 ), ang = Angle( 23.813302993774, -18.014757156372, 164.0428314209 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 2.886962890625, -2.675537109375, 0.18499755859375 ), ang = Angle( 77.642532348633, -11.260925292969, -137.98365783691 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 6.3638916015625, -3.67626953125, -16.742805480957 ), ang = Angle( 67.441040039063, -123.21622467041, 112.99300384521 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 2.1834716796875, 0.89227294921875, 25.560920715332 ), ang = Angle( -48.781341552734, 1.1773960590363, 113.71028900146 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -2.966064453125, 2.7431640625, -0.12180328369141 ), ang = Angle( 75.37328338623, 70.520553588867, -76.592147827148 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -1.487060546875, 6.881591796875, -16.678535461426 ), ang = Angle( 68.561302185059, -132.28720092773, 78.69792175293 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -5.5510864257813, 2.413330078125, -32.060386657715 ), ang = Angle( 32.974170684814, 66.848617553711, -82.991271972656 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 2.8910522460938, -8.9800415039063, -32.003623962402 ), ang = Angle( 32.678527832031, 30.222244262695, -97.935447692871 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 84.966522216797, -5.83056640625, -30.404510498047 ), ang = Angle( 18.624303817749, -90.243614196777, 7.3657641410828 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 96.20751953125, -5.1515502929688, -32.720458984375 ), ang = Angle( -40.578632354736, -2.7667229175568, 88.937103271484 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 102.64865112305, 2.2905883789063, -25.885467529297 ), ang = Angle( 43.867782592773, 121.11059570313, -143.44869995117 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 101.71401977539, -13.123229980469, -25.672439575195 ), ang = Angle( 46.486061096191, -149.7237701416, -55.791408538818 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 94.756103515625, -17.189575195313, -33.811264038086 ), ang = Angle( 6.3045606613159, -173.12065124512, -65.778945922852 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 83.433685302734, -18.547241210938, -35.525405883789 ), ang = Angle( -32.210350036621, -120.40957641602, 33.023090362549 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 98.305206298828, 9.4998168945313, -33.591873168945 ), ang = Angle( 4.6814956665039, 161.03901672363, -125.83016204834 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 87.480102539063, 13.218505859375, -34.864898681641 ), ang = Angle( -23.776767730713, 155.38349914551, 88.215866088867 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 84.982177734375, -2.1428833007813, -29.162719726563 ), ang = Angle( -14.398545265198, 179.41371154785, -96.863189697266 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 67.763397216797, -1.967529296875, -24.677230834961 ), ang = Angle( 32.254444122314, 173.44848632813, -97.895973205566 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 105.99221801758, -5.5751342773438, -20.842803955078 ), ang = Angle( -26.755283355713, 3.3015356063843, -75.549613952637 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 84.939331054688, -9.6394653320313, -31.689147949219 ), ang = Angle( -5.5758638381958, -166.96701049805, -118.91945648193 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 67.650817871094, -13.575988769531, -29.934295654297 ), ang = Angle( 5.8216052055359, -173.08134460449, -118.94451141357 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 51.348205566406, -15.5537109375, -31.613510131836 ), ang = Angle( -19.453727722168, -131.99873352051, -139.27830505371 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 53.879547119141, -0.37298583984375, -33.496429443359 ), ang = Angle( -41.307754516602, 166.06616210938, -85.842353820801 ) },
			},
		},
	},
}

RagdollFight.XRayStances[ 7 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Spine1",
		weapon = {
			{ mdl = Model( "models/props_junk/bicycle01a.mdl" ), bone = "ValveBiped.Bip01_Pelvis", pos = Vector( -1.0755310058594, -2.7937164306641, 27.463989257813 ), ang = Angle( -27.338216781616, 88.129379272461, 179.10369873047 ) },
		},
		offset = vector_up * 13,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -1.059741973877, 92.52946472168, 102.53428649902 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -1.2841796875, -0.27142333984375, 11.387924194336 ), ang = Angle( -64.677154541016, -7.0955438613892, -76.661079406738 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 4.4881591796875, -8.2477111816406, 18.194007873535 ), ang = Angle( 58.086059570313, -39.417751312256, -139.31809997559 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 3.1357421875, 7.0745544433594, 19.758750915527 ), ang = Angle( 59.521953582764, 25.265924453735, -78.259368896484 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 8.5202026367188, 9.6133422851563, 9.6982345581055 ), ang = Angle( -18.204959869385, 13.184315681458, -83.793212890625 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 19.139587402344, 12.101013183594, 13.285301208496 ), ang = Angle( -8.1428604125977, -22.079469680786, 15.274682998657 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 9.2916870117188, -12.155029296875, 8.0196914672852 ), ang = Angle( -20.248064041138, 14.273057937622, -115.93813323975 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 19.731323242188, -9.4992370605469, 11.993339538574 ), ang = Angle( -21.997417449951, 13.238372802734, -176.44342041016 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 2.2144165039063, -5.3281860351563, -0.59182739257813 ), ang = Angle( 13.859710693359, -1.5507259368896, -86.276481628418 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 19.500183105469, -5.0193481445313, -4.8824844360352 ), ang = Angle( 36.21675491333, -0.47352558374405, -86.024284362793 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 7.5416259765625, -0.75369262695313, 23.992301940918 ), ang = Angle( -34.544425964355, 19.361663818359, 63.771186828613 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 1.246337890625, 4.467041015625, -0.29917907714844 ), ang = Angle( 14.742886543274, 10.096043586731, -83.890205383301 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 18.239562988281, 7.4927978515625, -4.8412170410156 ), ang = Angle( 57.656814575195, 17.940906524658, -78.90731048584 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 26.650573730469, 10.216094970703, -18.802703857422 ), ang = Angle( 15.954976081848, 11.798129081726, -85.662696838379 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 32.83203125, -5.1295166015625, -14.646293640137 ), ang = Angle( 10.019442558289, -5.5060610771179, -83.098091125488 ), ignore = true },
			},




			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 52.904663085938, 2.0403747558594, -15.586898803711 ), ang = Angle( 2.9510798454285, -86.79313659668, 32.666648864746 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 64.038330078125, 2.5242919921875, -12.88712310791 ), ang = Angle( -6.9037837982178, -2.304459810257, 91.982330322266 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 73.145080566406, 9.8378601074219, -10.1708984375 ), ang = Angle( 45.930332183838, 140.7165222168, -135.12344360352 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 72.5732421875, -5.5924377441406, -10.694068908691 ), ang = Angle( 41.46826171875, -148.05470275879, -67.683670043945 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 65.12890625, -10.227142333984, -18.42170715332 ), ang = Angle( 11.160213470459, -159.85780334473, -73.177680969238 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 54.55322265625, -14.106140136719, -20.644035339355 ), ang = Angle( 13.660859107971, -156.31053161621, 30.607118606567 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 66.921264648438, 14.963073730469, -18.618293762207 ), ang = Angle( 11.939015388489, 169.18669128418, -120.57004547119 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 55.887329101563, 17.070526123047, -20.993522644043 ), ang = Angle( -52.84591293335, 128.34649658203, 126.04130554199 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 52.785705566406, 5.8675231933594, -15.235877990723 ), ang = Angle( 64.994407653809, 163.25115966797, -119.83502960205 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 45.53857421875, 8.0068969726563, -31.460052490234 ), ang = Angle( 68.299514770508, 43.735370635986, 125.0865020752 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 78.759155273438, 1.8401184082031, -8.4341278076172 ), ang = Angle( 4.120231628418, -11.707621574402, -75.626983642578 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 53.134216308594, -2.003662109375, -15.783599853516 ), ang = Angle( 58.612731933594, -169.30514526367, -85.570869445801 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 44.00634765625, -3.631103515625, -30.999229431152 ), ang = Angle( 72.267639160156, -0.66422045230865, 81.876159667969 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 49.039123535156, -3.6894226074219, -46.739356994629 ), ang = Angle( 31.023502349854, -163.55793762207, -83.828514099121 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 49.953491210938, 12.231079101563, -46.814140319824 ), ang = Angle( 28.826385498047, 169.39233398438, -110.13304901123 ) },
			},
		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Pelvis",
		weapon = {
			{ mdl = Model( "models/props_junk/bicycle01a.mdl" ), bone = "ValveBiped.Bip01_Pelvis", pos = Vector( -0.854736328125, 59.989486694336, -10.166809082031 ), ang = Angle( 31.387176513672, -89.709892272949, 1.0495709180832 ) },
		},
		offset = vector_up * 73,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -0.25538447499275, 88.816093444824, -114.21971130371 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 7.8084716796875, -0.12188720703125, -8.3167991638184 ), ang = Angle( 44.565860748291, 0.37465885281563, -89.477493286133 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 13.319641113281, -7.7873229980469, -15.705070495605 ), ang = Angle( 50.797645568848, -102.69515228271, 101.76948547363 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 13.307373046875, 7.564208984375, -15.565010070801 ), ang = Angle( 54.893299102783, 114.74034118652, 90.233680725098 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 10.4287109375, 13.044891357422, -24.950443267822 ), ang = Angle( 46.718524932861, -63.104915618896, -69.130653381348 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 13.989440917969, 6.0246276855469, -33.30904006958 ), ang = Angle( 20.097053527832, -40.084197998047, 74.98420715332 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 11.695373535156, -14.9970703125, -24.765865325928 ), ang = Angle( 46.869007110596, 60.155864715576, -100.8696975708 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 15.601684570313, -8.1884155273438, -33.145114898682 ), ang = Angle( 51.236694335938, 52.822002410889, 112.42923736572 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.09808349609375, -3.9829711914063, -0.020412445068359 ), ang = Angle( -68.585494995117, -157.37379455566, 66.19075012207 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -6.0868530273438, -6.4585876464844, 16.614316940308 ), ang = Angle( -62.211544036865, -16.311754226685, -71.536636352539 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 16.752075195313, -0.039215087890625, -20.846946716309 ), ang = Angle( 65.359992980957, -7.7066426277161, 88.678619384766 ), ignore = true },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.0972900390625, 3.9838256835938, 0.023933410644531 ), ang = Angle( -53.088207244873, 169.83042907715, 100.16345977783 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -10.45654296875, 5.83447265625, 14.346347808838 ), ang = Angle( -79.659355163574, 34.120941162109, -126.71401977539 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -8.0009155273438, 7.4983520507813, 30.603185653687 ), ang = Angle( -45.997207641602, 170.42799377441, 97.863143920898 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 1.3071899414063, -8.6224060058594, 31.233787536621 ), ang = Angle( -86.52286529541, -104.82705688477, 15.902756690979 ) },
			},



			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 35.070556640625, 0.69711303710938, -99.545059204102 ), ang = Angle( 73.053253173828, 25.814445495605, 170.28234863281 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 44.191833496094, -5.9913330078125, -97.796997070313 ), ang = Angle( 6.5564646720886, -35.207386016846, -139.0517578125 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 48.344848632813, -16.626129150391, -93.918563842773 ), ang = Angle( 11.568158149719, 167.54048156738, 121.21551513672 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 53.214416503906, -7.4678344726563, -105.50628662109 ), ang = Angle( -0.6579230427742, 119.55910491943, 166.54022216797 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 47.790405273438, 2.7487487792969, -105.22880554199 ), ang = Angle( 10.485006332397, -164.02178955078, -178.04933166504 ) },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 36.95361328125, -0.3499755859375, -106.97032165527 ), ang = Angle( 6.9281721115112, -166.5336151123, -89.85765838623 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 37.159606933594, -14.154724121094, -96.263305664063 ), ang = Angle( 59.089931488037, -119.54368591309, 171.26286315918 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 34.28515625, -19.246856689453, -106.13902282715 ), ang = Angle( -14.57559967041, -109.8049697876, 81.904296875 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 33.986328125, 0.20037841796875, -95.682861328125 ), ang = Angle( 15.341432571411, -175.09448242188, -172.25340270996 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 16.837341308594, -1.2712097167969, -100.40744018555 ), ang = Angle( 14.98192024231, 127.76416778564, 171.5516204834 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 55.165954589844, -16.219360351563, -101.23983764648 ), ang = Angle( 18.158000946045, -17.839189529419, 46.206497192383 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 36.091369628906, 1.19091796875, -103.26657104492 ), ang = Angle( 5.8039655685425, -149.18566894531, 177.24520874023 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 20.753173828125, -7.8701171875, -105.10781860352 ), ang = Angle( 1.490562081337, 160.35157775879, 172.97807312012 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 5.1954345703125, -2.3153686523438, -105.5376739502 ), ang = Angle( -0.94667017459869, -162.11599731445, 175.32188415527 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 7.0616455078125, 11.348999023438, -104.66796875 ), ang = Angle( 6.3361959457397, -155.16259765625, -165.92700195313 ) },
			},



		},

	},

	--third move
	[ 3 ] = {

		bone = "ValveBiped.Bip01_Head1",
		offset = vector_up * 40,
		weapon = {
			{ mdl = Model( "models/props_junk/bicycle01a.mdl" ), bone = "ValveBiped.Bip01_Pelvis", pos = Vector( -8.0391540527344, -11.806945800781, 25.63077545166 ), ang = Angle( -44.319313049316, 115.41928863525, 151.92012023926 ) },
		},
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -18.498212814331, 97.494606018066, 173.03746032715 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 10.222045898438, -0.23336791992188, 4.6796188354492 ), ang = Angle( 45.11897277832, -8.9770240783691, -85.853912353516 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 14.015380859375, -8.5420227050781, -3.0976181030273 ), ang = Angle( 48.645248413086, -130.90534973145, 93.450233459473 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 17.187377929688, 6.5425720214844, -2.2930679321289 ), ang = Angle( 34.031719207764, 141.5198059082, 99.171920776367 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 9.6324462890625, 12.422058105469, -8.6832504272461 ), ang = Angle( 57.069446563721, -55.202709197998, -98.200653076172 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 13.194458007813, 7.2965087890625, -18.320159912109 ), ang = Angle( 61.649955749512, -45.225387573242, 38.003421783447 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 8.9253540039063, -14.349365234375, -11.821670532227 ), ang = Angle( 34.385311126709, 44.331848144531, -93.47159576416 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 15.703186035156, -7.7278747558594, -18.306015014648 ), ang = Angle( 74.601615905762, 103.93044281006, 169.306640625 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 0.55029296875, -3.7091369628906, -1.203125 ), ang = Angle( 82.846717834473, -11.608129501343, -112.41719818115 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 3.9439697265625, -2.7457580566406, -18.836959838867 ), ang = Angle( -3.9385166168213, -168.86036682129, 87.327987670898 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 18.971130371094, -1.4214477539063, -7.9314727783203 ), ang = Angle( 66.213233947754, -17.959457397461, 74.888862609863 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.48309326171875, 3.7079162597656, 1.2278137207031 ), ang = Angle( 68.197006225586, 160.59350585938, 68.168594360352 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -6.7809448242188, 5.906982421875, -15.398941040039 ), ang = Angle( 52.57405090332, 170.50132751465, 76.997413635254 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -16.686279296875, 7.5643310546875, -28.522285461426 ), ang = Angle( 81.419090270996, -99.407409667969, 172.77984619141 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -12.231567382813, -5.930908203125, -17.701919555664 ), ang = Angle( 73.102172851563, -158.08023071289, 97.195526123047 ) },
			},


			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( -32.989440917969, 0.28622436523438, -63.358512878418 ), ang = Angle( -20.352428436279, -105.78289794922, 14.966423988342 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -22.182250976563, -3.1015625, -64.047187805176 ), ang = Angle( 20.239040374756, 2.0070559978485, 58.58211517334 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -14.933776855469, 4.4742431640625, -69.762062072754 ), ang = Angle( 4.3232951164246, 151.01597595215, -80.895278930664 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( -11.687255859375, -8.6111755371094, -62.298957824707 ), ang = Angle( 40.419376373291, -158.42572021484, -47.516990661621 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( -19.962646484375, -11.886383056641, -69.815208435059 ), ang = Angle( 10.113897323608, 177.32192993164, -58.17208480835 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( -31.24560546875, -11.364044189453, -71.902702331543 ), ang = Angle( -34.36901473999, -160.84381103516, 69.054611206055 ), ignore = true },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -25.130432128906, 10.196594238281, -70.691673278809 ), ang = Angle( -9.3404769897461, 149.02198791504, -81.016227722168 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -34.838317871094, 16.023773193359, -68.92569732666 ), ang = Angle( 8.0778961181641, 155.36451721191, 129.39430236816 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -32.010009765625, 3.9025573730469, -64.732765197754 ), ang = Angle( 14.887699127197, 170.05157470703, -68.361328125 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -48.982543945313, 6.8179016113281, -69.292533874512 ), ang = Angle( 4.6543369293213, 165.85311889648, -69.026840209961 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -7.228759765625, -1.19482421875, -67.17066192627 ), ang = Angle( 25.212940216064, 10.544741630554, -100.89248657227 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -33.833312988281, -3.3111572265625, -62.00284576416 ), ang = Angle( -7.9025206565857, 172.3258972168, -79.261085510254 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -51.330932617188, -0.89846801757813, -59.574882507324 ), ang = Angle( 35.048809051514, -178.48341369629, -76.988761901855 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -64.86328125, -1.259765625, -68.375038146973 ), ang = Angle( 9.0448637008667, 170.03483581543, -81.200996398926 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -64.953674316406, 10.843475341797, -70.633460998535 ), ang = Angle( -57.490135192871, 111.15419006348, -33.055728912354 ) },
			},

		},
	},
}

RagdollFight.XRayStances[ 8 ] = {

	--first move
	[ 1 ] = {
		bone = "ValveBiped.Bip01_Spine2",
		weapon = {
			{ mdl = Model( "models/items/hevsuit.mdl" ), bone = "ValveBiped.Bip01_Pelvis", pos = Vector( 24.853408813477, -37.51904296875, 10.058227539063 ), ang = Angle( -48.892700195313, -85.109870910645, 36.114677429199 ) },
			{ mdl = Model( "models/weapons/w_crowbar.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 3.376220703125, -1.3202514648438, -2.6929321289063 ), ang = Angle( -76.326843261719, 166.91761779785, -58.862873077393 ) },
		},
		offset = vector_up * 33,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 6.7337050437927, 131.00047302246, 132.72105407715 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 2.4378051757813, 3.8453979492188, 10.277290344238 ), ang = Angle( -59.602020263672, 11.252226829529, -81.358116149902 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 10.519409179688, -2.1255493164063, 16.804351806641 ), ang = Angle( 30.965888977051, -79.353363037109, 157.46551513672 ) },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 5.7846069335938, 12.729614257813, 18.055068969727 ), ang = Angle( 30.194272994995, 118.19641113281, 59.003395080566 ) },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 1.039306640625, 21.643371582031, 12.132247924805 ), ang = Angle( 63.343608856201, 36.784595489502, -7.40287733078 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 5.164794921875, 24.727844238281, 1.8709182739258 ), ang = Angle( 38.258720397949, 52.77991104126, 74.730560302734 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 12.5, -12.020202636719, 10.741386413574 ), ang = Angle( 20.607719421387, 18.739347457886, -148.6974029541 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 22.677307128906, -8.567626953125, 6.7001953125 ), ang = Angle( 3.0082411766052, -13.603630065918, 150.75430297852 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 2.5908203125, -2.8846435546875, 0.60877227783203 ), ang = Angle( 36.718002319336, 27.939380645752, -99.592155456543 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 15.214111328125, 3.837890625, -10.071426391602 ), ang = Angle( 68.013542175293, -126.69192504883, 111.05013275146 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 12.103210449219, 6.174560546875, 22.031257629395 ), ang = Angle( -65.272964477539, -18.027519226074, 105.42077636719 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -2.5687866210938, 2.9530029296875, -0.46588897705078 ), ang = Angle( 57.031837463379, 61.261543273926, -73.24341583252 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 2.1238403320313, 11.457214355469, -15.394622802734 ), ang = Angle( 32.992992401123, -139.00563049316, 78.834915161133 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -8.3375854492188, 2.3650512695313, -24.393226623535 ), ang = Angle( 59.643226623535, 107.71122741699, -31.617177963257 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 11.517395019531, -1.1231689453125, -25.394836425781 ), ang = Angle( 33.082229614258, 22.529472351074, -101.14337158203 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 37.919189453125, 6.3238525390625, -35.489822387695 ), ang = Angle( -13.739336967468, -102.81751251221, 84.498870849609 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 43.753051757813, 7.76611328125, -25.575241088867 ), ang = Angle( -46.250148773193, -169.81146240234, -99.135955810547 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 36.105895996094, 14.36279296875, -19.130241394043 ), ang = Angle( 67.293304443359, 25.478809356689, 107.98503112793 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 37.060791015625, -0.9635009765625, -20.826179504395 ), ang = Angle( 59.695072174072, -60.5221824646, 17.935272216797 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 39.966796875, -6.1041870117188, -30.907012939453 ), ang = Angle( 25.636262893677, -155.6872253418, -57.762191772461 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 30.533447265625, -10.366027832031, -35.874641418457 ), ang = Angle( 17.14136505127, -144.24536132813, 61.460479736328 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 40.191772460938, 16.321228027344, -29.904029846191 ), ang = Angle( 52.922668457031, 179.7198638916, -101.33940124512 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 33.272705078125, 16.345153808594, -39.060424804688 ), ang = Angle( 52.962032318115, 166.8984375, 145.4754486084 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 39.219543457031, 10.07568359375, -36.625289916992 ), ang = Angle( 43.499198913574, 167.6810760498, -81.946357727051 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 26.57080078125, 12.837951660156, -48.910995483398 ), ang = Angle( 67.197372436523, 176.18104553223, -74.797966003418 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 31.496459960938, 5.990966796875, -16.430610656738 ), ang = Angle( -34.575622558594, -157.86024475098, 78.773880004883 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 37.080810546875, 2.6388549804688, -34.56583404541 ), ang = Angle( 66.123245239258, -150.09539794922, -50.574287414551 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 30.817321777344, -0.96405029296875, -50.877304077148 ), ang = Angle( 38.179557800293, -19.135438919067, 70.896041870117 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 43.241577148438, -5.25732421875, -60.218963623047 ), ang = Angle( 54.392295837402, -152.00430297852, -56.195617675781 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 20.153137207031, 13.259948730469, -63.851760864258 ), ang = Angle( 33.485019683838, 161.30583190918, -82.371826171875 ), ignore = true },
			},

		},
	},

	--second move
	[ 2 ] = {
		bone = "ValveBiped.Bip01_Head1",
		weapon = {
			{ mdl = Model( "models/items/hevsuit.mdl" ), bone = "ValveBiped.Bip01_Pelvis", pos = Vector( 2.6450805664063, -29.859649658203, -25.849426269531 ), ang = Angle( -2.8065319061279, -96.56812286377, 16.097356796265 ) },
			{ mdl = Model( "models/weapons/w_crowbar.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 4.3708801269531, -1.7904968261719, -3.7486572265625 ), ang = Angle( -66.360641479492, 151.7289276123, 155.08316040039 ) },
		},
		offset = vector_up * 73,
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( 14.606897354126, 76.899795532227, -67.873573303223 ) },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( -1.2691040039063, -2.8453369140625, -11.109683990479 ), ang = Angle( 86.013534545898, -51.114109039307, -122.71384429932 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( -4.602783203125, -10.2666015625, -19.917098999023 ), ang = Angle( 37.665802001953, -123.84979248047, 54.693908691406 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 0.2645263671875, 4.4171142578125, -20.521697998047 ), ang = Angle( -40.143444061279, 27.886520385742, -119.91289520264 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 8.1795654296875, 8.5806274414063, -13.014575958252 ), ang = Angle( -64.987678527832, 125.49225616455, 154.0989074707 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 5.3610229492188, 12.533264160156, -2.6096801757813 ), ang = Angle( -63.216217041016, 126.00227355957, -153.06059265137 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( -9.7584228515625, -17.953369140625, -27.06188583374 ), ang = Angle( 54.752559661865, 126.27472686768, -37.558162689209 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( -13.678955078125, -12.611450195313, -36.438613891602 ), ang = Angle( 74.201232910156, -113.34785461426, 51.146102905273 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( -0.85693359375, -3.6663818359375, 0.98817825317383 ), ang = Angle( -68.909225463867, 172.37097167969, 93.075012207031 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -7.0158081054688, -2.839599609375, 17.326707839966 ), ang = Angle( 5.0628180503845, -5.0140500068665, -91.216430664063 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( -3.1193237304688, -2.8334350585938, -26.392860412598 ), ang = Angle( 68.303840637207, -169.6993560791, -71.449584960938 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 0.88201904296875, 3.8555297851563, -0.99467468261719 ), ang = Angle( -34.01774597168, 170.01023864746, 82.770858764648 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -13.695434570313, 6.2992553710938, 9.0500812530518 ), ang = Angle( -73.88306427002, -35.600212097168, -67.98681640625 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -9.9654541015625, 3.6288452148438, 24.925838470459 ), ang = Angle( -38.145721435547, 173.40374755859, 79.314895629883 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 9.3819580078125, -4.2783813476563, 15.868389129639 ), ang = Angle( -72.066513061523, -9.5450859069824, -84.362579345703 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 18.319458007813, -7.423583984375, -68.035339355469 ), ang = Angle( -1.8695670366287, -90.606719970703, 110.50525665283 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 18.020568847656, -7.0486450195313, -56.505905151367 ), ang = Angle( -46.933979034424, 163.43927001953, -72.252220153809 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 11.50390625, 2.1281127929688, -52.403266906738 ), ang = Angle( 59.267669677734, 45.390808105469, 136.55383300781 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 10.605590820313, -12.957336425781, -49.184158325195 ), ang = Angle( 64.479690551758, -40.984485626221, 31.091907501221 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 14.415771484375, -16.256103515625, -59.732856750488 ), ang = Angle( 46.866928100586, -139.56932067871, -56.721813201904 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 8.4404907226563, -21.347045898438, -68.111824035645 ), ang = Angle( -13.332043647766, -122.42327880859, 83.49536895752 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 15.723999023438, 6.4027709960938, -62.466300964355 ), ang = Angle( 55.745372772217, 147.31143188477, -131.24580383301 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 10.284790039063, 9.8931884765625, -71.956428527832 ), ang = Angle( 61.554424285889, 141.90107727051, 109.22104644775 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 18.367431640625, -3.4657592773438, -68.145324707031 ), ang = Angle( 82.068061828613, 39.688365936279, 124.49558258057 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 20.274047851563, -1.9218139648438, -85.86555480957 ), ang = Angle( 66.817802429199, 16.186605453491, 101.74435424805 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 6.0966796875, -4.3458251953125, -47.151016235352 ), ang = Angle( -52.345649719238, -164.99546813965, 90.028678894043 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 18.273742675781, -11.377868652344, -67.926330566406 ), ang = Angle( 77.826370239258, -81.705909729004, 0.68117165565491 ), ignore = true },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 18.82763671875, -15.074157714844, -85.386642456055 ), ang = Angle( 64.789657592773, -19.833824157715, 60.026351928711 ), ignore = true },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 25.448913574219, -17.46240234375, -100.33786010742 ), ang = Angle( 70.478179931641, -158.53375244141, -72.998809814453 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 26.521423339844, -0.1083984375, -101.0565032959 ), ang = Angle( 71.285339355469, -174.7494354248, -90.239654541016 ) },
			},
		},

	},

	--third move
	[ 3 ] = {

		bone = "ValveBiped.Bip01_Pelvis",
		offset = vector_up * 45,
		weapon = {
			{ mdl = Model( "models/items/hevsuit.mdl" ), bone = "ValveBiped.Bip01_Pelvis", pos = Vector( -0.45733642578125, -21.908203125, 35.356670379639 ), ang = Angle( -76.401802062988, -119.955909729, 40.164108276367 ) },
			{ mdl = Model( "models/weapons/w_crowbar.mdl" ), bone = "ValveBiped.Bip01_R_Hand", pos = Vector( 4.7169799804688, -1.6441040039063, -1.136474609375 ), ang = Angle( -57.189758300781, -163.95687866211, 154.76525878906 ) },
		},
		data = {

			--player
			[ 1 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 0, 0, 0 ), ang = Angle( -11.93069934845, 98.825988769531, -177.11015319824 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 11.839538574219, 0.74725341796875, 3.3273124694824 ), ang = Angle( 54.595474243164, -13.420310020447, -83.948806762695 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 13.485473632813, -7.3786010742188, -5.4040374755859 ), ang = Angle( 50.322326660156, -160.99035644531, 48.182548522949 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 18.307800292969, 7.2446899414063, -4.3899230957031 ), ang = Angle( 36.633945465088, 151.50695800781, 137.94744873047 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 10.017883300781, 11.6943359375, -11.420585632324 ), ang = Angle( 49.918952941895, -123.57356262207, -157.74920654297 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 5.9296875, 5.5348510742188, -20.205596923828 ), ang = Angle( 75.307876586914, -144.01846313477, -123.86631774902 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 6.4273071289063, -9.8101806640625, -14.403182983398 ), ang = Angle( 39.066669464111, 76.009902954102, -56.74976348877 ) },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 8.5824584960938, -1.1600952148438, -21.639228820801 ), ang = Angle( 64.098533630371, 46.511810302734, -136.41688537598 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 1.1251220703125, -3.89697265625, -0.65930557250977 ), ang = Angle( 29.2701587677, -178.96752929688, 90.576263427734 ), ignore = true },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( -14.477905273438, -4.1832275390625, -9.372184753418 ), ang = Angle( -18.58953666687, -179.5059967041, 91.492111206055 ), ignore = true },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 18.360168457031, -0.5213623046875, -10.560501098633 ), ang = Angle( 48.952541351318, -13.772699356079, 90.523567199707 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( -0.583984375, 3.7613525390625, 0.80427169799805 ), ang = Angle( 55.288650512695, 157.02792358398, 60.707588195801 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( -9.9328002929688, 7.7437744140625, -13.865646362305 ), ang = Angle( -16.444301605225, -173.42942810059, 73.286109924316 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( -25.677978515625, 5.9300537109375, -9.1876220703125 ), ang = Angle( 40.603717803955, 171.63061523438, 70.163558959961 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( -30.140380859375, -4.3182373046875, -4.1041603088379 ), ang = Angle( 20.657760620117, -151.64181518555, 110.67022705078 ) },
			},

			--victim
			[ 2 ] = {
				["ValveBiped.Bip01_Pelvis"] = { pos = Vector( 43.20703125, 2.5538330078125, -47.902435302734 ), ang = Angle( -1.168963432312, -85.346527099609, 115.70082092285 ), ignore = true },
				["ValveBiped.Bip01_Spine2"] = { pos = Vector( 41.833679199219, 2.6805419921875, -36.500289916992 ), ang = Angle( -46.933975219727, 168.2437286377, -72.252220153809 ) },
				["ValveBiped.Bip01_R_UpperArm"] = { pos = Vector( 34.571228027344, 11.279357910156, -32.397644042969 ), ang = Angle( 59.267517089844, 50.196041107178, 136.55426025391 ), ignore = true },
				["ValveBiped.Bip01_L_UpperArm"] = { pos = Vector( 34.939636230469, -3.8284301757813, -29.17854309082 ), ang = Angle( 64.479675292969, -36.179779052734, 31.092027664185 ), ignore = true },
				["ValveBiped.Bip01_L_Forearm"] = { pos = Vector( 39.012756347656, -6.7964477539063, -39.727241516113 ), ang = Angle( 46.866958618164, -134.76477050781, -56.721736907959 ), ignore = true },
				["ValveBiped.Bip01_L_Hand"] = { pos = Vector( 33.48486328125, -12.369934082031, -48.10620880127 ), ang = Angle( -13.332043647766, -117.61882019043, 83.49536895752 ) },
				["ValveBiped.Bip01_R_Forearm"] = { pos = Vector( 38.418518066406, 15.892456054688, -42.46070098877 ), ang = Angle( 55.745227813721, 152.11584472656, -131.24627685547 ), ignore = true },
				["ValveBiped.Bip01_R_Hand"] = { pos = Vector( 32.706115722656, 18.914916992188, -51.950813293457 ), ang = Angle( 61.554424285889, 146.70553588867, 109.22104644775 ) },
				["ValveBiped.Bip01_R_Thigh"] = { pos = Vector( 42.888122558594, 6.487060546875, -47.997093200684 ), ang = Angle( 47.054290771484, 162.22163391113, -106.62844848633 ) },
				["ValveBiped.Bip01_R_Calf"] = { pos = Vector( 31.309875488281, 10.189270019531, -61.03889465332 ), ang = Angle( 77.210746765137, 55.007724761963, 151.12928771973 ) },
				["ValveBiped.Bip01_Head1"] = { pos = Vector( 29.725219726563, 4.3751220703125, -27.145401000977 ), ang = Angle( -52.345649719238, -160.19100952148, 90.028678894043 ) },
				["ValveBiped.Bip01_L_Thigh"] = { pos = Vector( 43.522644042969, -1.3230590820313, -47.82307434082 ), ang = Angle( 51.455219268799, -154.97381591797, -77.965507507324 ) },
				["ValveBiped.Bip01_L_Calf"] = { pos = Vector( 33.437194824219, -5.9695434570313, -61.800598144531 ), ang = Angle( 45.309108734131, -156.59764099121, -79.177513122559 ) },
				["ValveBiped.Bip01_L_Foot"] = { pos = Vector( 22.771362304688, -10.585571289063, -73.548568725586 ), ang = Angle( 17.764297485352, -157.62562561035, -84.554512023926 ) },
				["ValveBiped.Bip01_R_Foot"] = { pos = Vector( 33.407653808594, 13.186218261719, -77.154159545898 ), ang = Angle( 66.934226989746, 158.42671203613, -107.82692718506 ) },
			},


		},
	},
}


if SERVER then

local function RandomStanceNum( stance )
	if not RagdollFight.Stances[ stance ] then return 1 end
	local cnt = #RagdollFight.Stances[ stance ]

	return math.random( 1, cnt )
end

local bone_to_hitbox = {
	["ValveBiped.Bip01_L_Hand"] = "left_hand",
	["ValveBiped.Bip01_R_Hand"] = "right_hand",
	["ValveBiped.Bip01_L_Foot"] = "left_leg",
	["ValveBiped.Bip01_R_Foot"] = "right_leg",
}

local function ActivateHitbox( ent, lh, rh, ll, rl, attack_type, force, force_ragdoll, dmg, world_damage )
	if ent and ent:IsValid() then
		ent.HitDetection.left_hand = false
		ent.HitDetection.right_hand = false
		ent.HitDetection.left_leg = false
		ent.HitDetection.right_leg = false

		ent.AttackForce = nil
		ent.AttackType = RAGDOLL_ATTACK_ANY
		ent.AttackForceRagdoll = nil
		ent.AttackForceRagdollDamage = nil
		ent.AttackDamage = 0

		if lh then
			ent.HitDetection.left_hand = true
		end
		if rh then
			ent.HitDetection.right_hand = true
		end
		if ll then
			ent.HitDetection.left_leg = true
		end
		if rl then
			ent.HitDetection.right_leg = true
		end

		if attack_type then
			ent.AttackType = attack_type
		end

		if force and ent:GetOwner() and ent:GetOwner():IsValid() then
			ent.AttackForce = ent:GetOwner():GetForward() * force
		end

		if force_ragdoll then
			ent.AttackForceRagdoll = CurTime() + 1.5
		end

		if world_damage then
			ent.AttackForceRagdollDamage = world_damage
		end

		if dmg then
			ent.AttackDamage = dmg
		end



	end
end

local hitsound = Sound( "npc/vort/foot_hit.wav" )
local hitsound2 = Sound( "ambient/voices/citizen_punches2.wav" )

util.AddNetworkString( "RagdollFightUpdateRagdoll" )

function RagdollFight.SpawnRagdoll( pl, cmd, args )

	local mdl = pl:GetModel()
	local skin = pl:GetSkin()
	local ang = pl:GetAngles()
	local pos = pl:GetPos()

	local ent = ents.Create( "prop_ragdoll" )
	if ( !IsValid( ent ) ) then return end
	if IsValid( pl.Ragdoll ) then return end

	ent:SetModel( mdl )
	ent:SetSkin( skin )
	ent:SetAngles( ang )
	ent:SetPos( pos )
	ent:Spawn()
	ent:Activate()
	ent:SetOwner( pl )
	pl.Ragdoll = ent
	ent.IsRagdollFighter = true
	pl.pac_owner_override = ent
	do
		local id = pl:EntIndex()
		BroadcastLua([[Entity(]]..id..[[):SetNoDraw(true)]])
	end
	if pl:HasGodMode() then
		pl.rfwasgoded = true
	end
	pl:GodEnable()
	ent:SetCollisionGroup( COLLISION_GROUP_WEAPON  )
	ent:CollisionRulesChanged()
	pl.OldJumpPower = pl:GetJumpPower()
	pl:SetJumpPower( 230 )
	pl:StripWeapons()
	ent.Stance = RAGDOLL_STANCE_IDLE
	ent.StanceNum = 1
	ent.LastStance = ent.Stance
	ent.LastStanceNum = ent.StanceNum
	ent.StanceDuration = -1
	ent.Grab = false
	ent.GrabbedObject = nil
	ent._Constraints = nil
	ent.RagdollMode = false
	ent.OriginalMass = {}
	ent.OriginalDamping = {}
	ent.HitDetection = { left_hand = false, right_hand = false, left_leg = false, right_leg = false }
	ent.HitPhysBones = {}
	ent.AttackType = nil
	ent.AttackForce = nil
	ent:SetCustomCollisionCheck( true )
	pl:SetCustomCollisionCheck( true )

	timer.Simple( 0.1, function()
		net.Start( "RagdollFightUpdateRagdoll" )
			net.WriteInt( ent:EntIndex(), 32 )
		net.Send( pl )
	end)

	ent.ChangeFace = function( self )
		local FlexNum = self:GetFlexNum() - 1
		if ( FlexNum <= 0 ) then return end

		for i=0, FlexNum-1 do
			if math.random(3) == 3 then
				self:SetFlexWeight( i, math.Rand(0,1.1) )
			end
		end

		self:SetFlexScale(math.random(-10,10))
	end

	ent.RagdollTakeDamage = function( self, am )
		local owner = self:GetOwner()
		if owner and owner:IsValid() and owner.RagdollFightArena and owner.RagdollFightArena:IsValid() then
			local arena = owner.RagdollFightArena
			local my_slot = owner.RagdollFightArenaSlot

			arena:PlayerTakeDamage( my_slot, am )

		end
	end

	ent.RagdollTakeXRayDamage = function( self, num, b_name )
		local owner = self:GetOwner()
		if owner and owner:IsValid() and owner.RagdollFightArena and owner.RagdollFightArena:IsValid() then

			local arena = owner.RagdollFightArena
			local my_slot = owner.RagdollFightArenaSlot

			local hp = math.min( arena:GetPlayerHealth( my_slot ), RAGDOLL_DAMAGE_XRAY )

			local dmg = math.ceil( hp / num )

			if not self.XRayDamage then
				self.XRayDamage = dmg
			end

			arena:PlayerTakeDamage( my_slot, self.XRayDamage )

			if arena:GetPlayerHealth( my_slot ) <= 0 then
				self.DontForceRagdoll = true
				self.ForceResetDamping = true
			end

			local b = self:LookupBone( b_name )

			if b then
				local m = self:GetBoneMatrix( b )
				if m then
					local bone_pos = m:GetTranslation()
					local bone_ang = m:GetAngles()
					if bone_pos and bone_ang then
						local e = EffectData()
							e:SetOrigin( bone_pos )
							e:SetNormal( VectorRand() )
							e:SetScale( 0.2 )
							e:SetMagnitude( 1 )
						util.Effect( "HunterDamage", e, nil, true )
						local e = EffectData()
							e:SetOrigin( bone_pos )
							e:SetNormal( VectorRand() )
							e:SetScale( 6 )
							e:SetFlags( 3 )
							e:SetColor( 0 )
						util.Effect( "bloodspray", e, nil, true )
					end
				end
			end

		end
	end

	ent.HasPowerup = function( self, power )
		local owner = self:GetOwner()
		if owner and owner:IsValid() and owner.RagdollFightArena and owner.RagdollFightArena:IsValid() then
			local arena = owner.RagdollFightArena
			local my_slot = owner.RagdollFightArenaSlot

			return arena:IsChargeReady( my_slot, power )

		end
		return false
	end

	ent.ConsumeCharge = function( self, power )
		local owner = self:GetOwner()
		if owner and owner:IsValid() and owner.RagdollFightArena and owner.RagdollFightArena:IsValid() then
			local arena = owner.RagdollFightArena
			local my_slot = owner.RagdollFightArenaSlot

			arena:SetCharge( my_slot, arena:GetCharge( my_slot ) - power * 33 )--- 99 - power * 33

		end
	end

	for i=0, ent:GetPhysicsObjectCount() - 1 do
		local phys_bone = ent:GetPhysicsObjectNum( i )

		local rag_bone = ent:TranslatePhysBoneToBone( i )
		local bone_name = ent:GetBoneName( rag_bone )

		if phys_bone and phys_bone:IsValid() then

			phys_bone:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )

			local mass = phys_bone:GetMass() or 1
			ent.OriginalMass[ i ] = mass

			local lin_d, ang_d = phys_bone:GetDamping()

			ent.OriginalDamping[ i ] = { lin_d, ang_d }

		end
	end


	for k, v in pairs( bone_to_hitbox ) do
		local bone = ent:LookupBone( k )
		if bone then
			local physbone_id = ent:TranslateBoneToPhysBone( bone )
			local phys_bone = ent:GetPhysicsObjectNum( physbone_id )
			if phys_bone and phys_bone:IsValid() then
				ent.HitPhysBones[ v ] = phys_bone
			end
		end
	end

	local function RagdollCallback( self, data )

		local head_bonename = "ValveBiped.Bip01_Head1"
		local head_bone = self:LookupBone( head_bonename )

		local head_physbone_id = self:TranslateBoneToPhysBone( head_bone )
		local head_physbone = self:GetPhysicsObjectNum( head_physbone_id )

		if not self.HeadPhysBone then
			self.HeadPhysBone = head_physbone
		end

		if self.RagdollMode or ( self.RagdollModeTime and self.RagdollModeTime >= CurTime() ) then
			if ( self.NextBreakSound or 0 ) <= CurTime() and data.HitEntity and ( data.HitEntity:IsWorld() or data.HitEntity.IsArena ) and data.Speed > 100 then--
				if not self.FixBones then
					self:EmitSound( "physics/body/body_medium_break"..math.random(2,4)..".wav", 75, math.random( 95, 115 ) )
					util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal )
					local e = EffectData()
						e:SetOrigin( data.HitPos )
						e:SetNormal( data.HitNormal )
					util.Effect( "BloodImpact", e, nil, true )
					self.NextBreakSound = CurTime() + 0.4
				end
				if self.WasThrown then
					self:RagdollTakeDamage( RAGDOLL_DAMAGE_GRAB_THROW * self.WasThrown )
					self.NextGrab = CurTime() + 2
					self.WasThrown = nil

					if data.PhysObject == self.HeadPhysBone then
						self:ChangeFace()
					end

				end
			end
		end

		if self.Attack and self.Attack >= CurTime() and !self.Grab and !IsValid( self.GrabbedObject ) then
			if data.PhysObject and data.HitEntity:IsValid() and data.HitObject:IsValid() and data.HitEntity ~= self and data.HitEntity.IsRagdollFighter then
				for k, v in pairs( self.HitDetection ) do
					if v and self.HitPhysBones[ k ] then
						if data.HitEntity.Blocking and data.HitEntity.Blocking == self.AttackType then
							self:EmitSound( "physics/body/body_medium_impact_soft"..math.random(5,7)..".wav", 75, math.random( 95, 115 ) )
						else
							local e = EffectData()
								e:SetOrigin( data.HitPos )
								e:SetNormal( data.HitNormal )
							util.Effect( "BloodImpact", e, nil, true )

							util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal )
							self:EmitSound( hitsound, 75, math.random( 95, 115 ) )

							if self.AttackDamage then
								data.HitEntity:RagdollTakeDamage( self.AttackDamage )
								if data.HitObject == data.HitEntity.HeadPhysBone and data.HitEntity.ChangeFace then
									data.HitEntity:ChangeFace()
								end
							end

							if self.AttackForce and data.HitEntity:GetOwner() and data.HitEntity:GetOwner():IsValid() then

								data.HitEntity:GetOwner():SetGroundEntity( NULL )
								data.HitEntity:GetOwner():SetLocalVelocity( self.AttackForce )

								if self.AttackForceRagdoll and self:GetOwner() and self:GetOwner():IsValid() then

									data.HitEntity.RagdollModeTime = self.AttackForceRagdoll
									RagdollFight.ApplyForce( data.HitEntity, self.AttackForce , self.AttackForce:Length() * 2 )

									if self.AttackForceRagdollDamage then
										data.HitEntity.WasThrown = self.AttackForceRagdollDamage
									end
								end
							end

						end
						self.Attack = nil
						ActivateHitbox( self )
						break
					end
				end
			end
		end

		if self.Grab and ( self.GrabTime or 0 ) >= CurTime() and !IsValid(self.GrabbedObject) then

			local lh_bonename = "ValveBiped.Bip01_L_Hand"
			local lh_bone = self:LookupBone( lh_bonename )

			local lh_physbone_id = self:TranslateBoneToPhysBone( lh_bone )
			local lh_physbone = self:GetPhysicsObjectNum( lh_physbone_id )

			local rh_bonename = "ValveBiped.Bip01_R_Hand"
			local rh_bone = self:LookupBone( rh_bonename )

			local rh_physbone_id = self:TranslateBoneToPhysBone( rh_bone )
			local rh_physbone = self:GetPhysicsObjectNum( rh_physbone_id )



			if data.PhysObject and ( data.PhysObject == lh_physbone or data.PhysObject == rh_physbone ) and data.HitEntity:IsValid() and data.HitObject:IsValid() and data.HitEntity ~= self then

				if not ( self.RagdollMode or self.RagdollModeTime or data.HitEntity.NextGrab and data.HitEntity.NextGrab > CurTime() ) then
					if data.HitEntity.IsRagdollFighter and ( self:GetOwner():Crouching() and data.HitEntity.Blocking == RAGDOLL_BLOCK_CROUCH or !self:GetOwner():Crouching() and data.HitEntity.Blocking == RAGDOLL_BLOCK_NORMAL ) then return end
					local self_phys_num = data.PhysObject == lh_physbone and lh_physbone_id or rh_physbone_id
					local hitent_phys_num = 0

					for i=0, data.HitEntity:GetPhysicsObjectCount() - 1 do
						local cur = data.HitEntity:GetPhysicsObjectNum( i )
						if cur and cur == data.HitObject then
							hitent_phys_num = i
							break
						end
					end

					if data.HitEntity.IsRagdollFighter then
						data.HitEntity.RagdollMode = true
						RagdollFight.RemoveMass( data.HitEntity )
						self.GrabDuration = CurTime() + 3
						data.HitEntity.GrabbedBy = self
					end

					self.ToWeld = { ent1 = self, ent2 = data.HitEntity, bone1 = self_phys_num, bone2 = hitent_phys_num, bone_alt = ( data.PhysObject == lh_physbone and rh_physbone_id or lh_physbone_id ) }--
					self.GrabbedObject = data.HitEntity
					data.HitEntity.WasThrown = nil
				end
			end

		end

	end

	ent:AddCallback( "PhysicsCollide", RagdollCallback )

	for i=1, 2 do
		for k, v in pairs( fingerbones[ i ] ) do
			local bone = ent:LookupBone( v )
			if bone then
				ent:ManipulateBoneAngles( bone, Angle( 0, -60, 0 ) )
			end
		end
	end


	RagdollFight.Ragdolls[tostring(ent)] = ent

	ent:ChangeFace()


end
--concommand.Add( "rag_create", RagdollFightSpawnRagdoll )

function RagdollFight.ApplyForce( ent, dir, power, noang )

	if ent then
		local pow = power / ent:GetPhysicsObjectCount()
		for i=0, ent:GetPhysicsObjectCount() - 1 do
			local phys_bone = ent:GetPhysicsObjectNum( i )
			if phys_bone and phys_bone:IsValid() then
				phys_bone:ApplyForceCenter( dir * power )
				if not noang then
					phys_bone:AddAngleVelocity( VectorRand() * power )
				end
			end
		end
	end
end

function RagdollFight.RemoveMass( ent )
	if ent and ent.OriginalMass then
		for i=0, ent:GetPhysicsObjectCount() - 1 do
			local phys_bone = ent:GetPhysicsObjectNum( i )
			if phys_bone and phys_bone:IsValid() then
				local mass = 1
				phys_bone:SetMass( mass )
			end
		end
	end
end

function RagdollFight.ResetMass( ent )
	if ent and ent.OriginalMass then
		for i=0, ent:GetPhysicsObjectCount() - 1 do
			local phys_bone = ent:GetPhysicsObjectNum( i )
			if phys_bone and phys_bone:IsValid() then
				local mass = ent.OriginalMass[ i ] or 1
				phys_bone:SetMass( mass )
			end
		end
	end
end

function RagdollFight.ChangeDamping( ent, lin, ang )
	if ent and ent.OriginalMass then
		for i=0, ent:GetPhysicsObjectCount() - 1 do
			local phys_bone = ent:GetPhysicsObjectNum( i )
			if phys_bone and phys_bone:IsValid() then
				phys_bone:SetDamping( lin or 1, ang or 1 )
			end
		end
	end
end

function RagdollFight.ResetDamping( ent )
	if ent and ent.OriginalDamping then
		for i=0, ent:GetPhysicsObjectCount() - 1 do
			local phys_bone = ent:GetPhysicsObjectNum( i )
			if phys_bone and phys_bone:IsValid() then
				local lin = ent.OriginalDamping[ i ][ 1 ] or 1
				local ang = ent.OriginalDamping[ i ][ 2 ] or 1
				phys_bone:SetDamping( lin, ang )
			end
		end
	end
end

function RagdollFight.RemoveRagdoll( pl )

	if pl.Ragdoll and pl.Ragdoll:IsValid() then
		RagdollFight.Ragdolls[tostring(pl.Ragdoll)] = nil
		pl.Ragdoll:Remove()
		pl.pac_owner_override = nil
		do
			local id = pl:EntIndex()
			BroadcastLua([[Entity(]]..id..[[):SetNoDraw(false)]])
		end
		if not pl.rfwasgoded then
			pl:GodDisable()
		end
		pl:SetJumpPower( pl.OldJumpPower or 200 )
		--pl:SetCollisionGroup( COLLISION_GROUP_PLAYER )
		gamemode.Call("PlayerLoadout",pl)
		pl.Ragdoll = nil
	end

end

function RagdollFight.Think( )
	if RagdollFight.Ragdolls then
		for k, v in pairs( RagdollFight.Ragdolls ) do
			if v and v:IsValid() and !IsValid(v:GetOwner()) then
				RagdollFight.Ragdolls[tostring(v)] = nil
				v:Remove()
				continue
			end
			if IsValid(v) and IsValid(v:GetOwner()) and v:GetOwner():Alive() then
				local pl = v:GetOwner()

				if #pl:GetWeapons() > 0 then pl:StripWeapons() end

				if v.ToWeld then
					v._Constraints = true
					constraint.Weld( v.ToWeld.ent1, v.ToWeld.ent2, v.ToWeld.bone1, v.ToWeld.bone2, 0, false, false )
					constraint.Weld( v.ToWeld.ent1, v.ToWeld.ent2, v.ToWeld.bone_alt, v.ToWeld.bone2, 0, false, false )
					v.ToWeld = nil
				end

				if v.Blocking and v:GetOwner():KeyDown( IN_RELOAD ) then
					if v:GetOwner():Crouching() and v.Blocking ~= RAGDOLL_BLOCK_CROUCH then
						v.Blocking = RAGDOLL_BLOCK_CROUCH
					end
					if !v:GetOwner():Crouching() and v.Blocking ~= RAGDOLL_BLOCK_NORMAL then
						v.Blocking = RAGDOLL_BLOCK_NORMAL
					end
				end

				local reference_bonename = "ValveBiped.Bip01_Pelvis"
				local reference_bone = pl:LookupBone( reference_bonename ) or 1

				local reference_physbone_id = v:TranslateBoneToPhysBone( reference_bone )
				local reference_physbone = v:GetPhysicsObjectNum( reference_physbone_id )

				local bone_stance = v.Stance and RagdollFight.Stances[ v.Stance ][ v.StanceNum ]
				local last_stance = v.LastStance and RagdollFight.Stances[ v.LastStance ][ v.LastStanceNum ]

				local idle_stance = IsValid( v.GrabbedObject ) and RAGDOLL_STANCE_GRAB_IDLE or RAGDOLL_STANCE_IDLE


				if v:GetOwner():KeyDown( IN_RELOAD ) and !v.RagdollMode and !IsValid( v.GrabbedObject ) and !v.Grab then
					v.Blocking = v:GetOwner():Crouching() and RAGDOLL_BLOCK_CROUCH or RAGDOLL_BLOCK_NORMAL
				end

				if v.Blocking then idle_stance = RAGDOLL_STANCE_BLOCK end

				if v.StanceDuration and v.StanceDuration < CurTime() and v.Stance ~= idle_stance then
					v.Stance = idle_stance
					v.StanceNum = RandomStanceNum( idle_stance )
					v.StanceDuration = -1
				end

				local lerp_dur = 0.15

				if ( v.Stance ~= v.LastStance or v.StanceNum ~= v.LastStanceNum ) and not v.Lerping then
					v.Lerping = CurTime() + lerp_dur
					if v.LastBonePos then
						table.Empty( v.LastBonePos )
					else
						v.LastBonePos = {}
					end
				end

				if v.RagdollModeTime and v.RagdollModeTime < CurTime() then
					if v.FixBones then
						v.FixBones = nil
					else
						if v:GetOwner().RagdollFightArena and v:GetOwner().RagdollFightArena:IsValid() then
							local safe_pos = v:GetOwner().RagdollFightArena:ConvertIntoSafePos( v:GetPos() )
							v:GetOwner():SetPos( safe_pos )
							RagdollFight.ResetMass( v )
							v:GetOwner().RagdollFightArena:ClearPos( v:GetOwner(), v:GetOwner():GetPos() )--v:GetOwner():GetPos()
						else
							v:GetOwner():SetPos( v:GetPos() )
						end
					end
					v.RagdollModeTime = nil
				end

				if v.GrabDuration and v.GrabDuration < CurTime() or v.ForceDrop then
					v.GrabDuration = nil
					v.ForceDrop = nil
					if v.GrabbedObject and v.GrabbedObject:IsValid() then
						if v.GrabbedObject.IsRagdollFighter then
							v.GrabbedObject.NextGrab = CurTime() + 4
							RagdollFight.ResetMass( v.GrabbedObject )
						end
						v.GrabbedObject.GrabbedBy = nil
						v.GrabbedObject = nil
						v.Grab = false
					end
					if v._Constraints then
						constraint.RemoveConstraints( v, "Weld" )
					end
				end

				if v.ThrowTime and v.ThrowTime < CurTime() then
					v.ThrowTime = nil
				end


				local arena = IsValid( v:GetOwner().RagdollFightArena ) and v:GetOwner().RagdollFightArena


				if v.RagdollMode or v.RagdollModeTime and v.RagdollModeTime >= CurTime() or arena and v:GetOwner().RagdollFightArenaSlot and arena:GetPlayerHealth( v:GetOwner().RagdollFightArenaSlot ) <= 0 and !( v.XRay and v.XRayTime and v.XRayTime > CurTime() ) then

					v.Blocking = nil

					if v.ForceResetDamping then
						RagdollFight.ResetDamping( v )
						v.ForceResetDamping = nil
					end

					if not v.FixBones then
						if v:GetOwner():GetCollisionGroup() ~= COLLISION_GROUP_IN_VEHICLE then
							v:GetOwner():SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
							--v:GetOwner():CollisionRulesChanged()
						end
					end

					if not v.FixBones then
						if v:GetCollisionGroup() ~= COLLISION_GROUP_PLAYER then
							v:SetCollisionGroup( COLLISION_GROUP_PLAYER )
							v:CollisionRulesChanged()
						end
					end

					if !IsValid(v.GrabbedBy) then
						if v.RagdollMode then
							v.RagdollMode = false
							v.RagdollModeTime = CurTime() + 1.5
						end
					end

				else

					if v:GetOwner():GetCollisionGroup() == COLLISION_GROUP_IN_VEHICLE then
						v:GetOwner():SetCollisionGroup( COLLISION_GROUP_PLAYER )
					end

					if v:GetCollisionGroup() ~= COLLISION_GROUP_WEAPON then
						v:SetCollisionGroup( COLLISION_GROUP_WEAPON )
						v:CollisionRulesChanged()
					end


					if v.XRay and v.XRayTime and v.XRayTime > CurTime() and arena and arena:IsValid() then

						local xray_num = #RagdollFight.XRayStances[ v.XRayIndex or 1 ]

						local mini_dur = v.XRayDuration / xray_num
						local xray_lerp_dur = math.min( mini_dur / 3, 0.2 )--math.min( mini_dur / 3, 0.15 )

						if not v.XRayCurMove then
							v.XRayDamage = nil
							v.XRayCurMove = 1
							if v.XRay == RAGDOLL_XRAY_VICTIM then
								v:EmitSound( "physics/body/body_medium_break"..math.random(2,4)..".wav", 75, math.random( 55, 65 ) )
								v:EmitSound( "vo/npc/male01/pain0"..math.random(7,9)..".wav", 120, math.random( 45, 55 ) )
								v:EmitSound( "physics/wood/wood_strain"..math.random(2,4)..".wav", 130, math.random( 65, 75 ) )

								if RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].extra_sound and IsValid( v.XRayAttacker ) then
									RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].extra_sound( v.XRayAttacker )
								end

								v:RagdollTakeXRayDamage( xray_num, RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].bone )

							end

							if not v.XRayLerping then
								v.XRayLerping = CurTime() + xray_lerp_dur
								if v.XRayLastBonePos then
									table.Empty( v.XRayLastBonePos )
								else
									v.XRayLastBonePos = {}
								end
							end

						end

						if ( v.XRayTime - v.XRayDuration + v.XRayCurMove * mini_dur ) < CurTime() and v.XRayCurMove < xray_num then
							v.XRayCurMove = math.Clamp( v.XRayCurMove + 1, 1, xray_num )
							if v.XRay == RAGDOLL_XRAY_VICTIM then
								v:EmitSound( "physics/body/body_medium_break"..math.random(2,4)..".wav", 75, math.random( 55, 65 ) )
								v:EmitSound( "vo/npc/male01/pain0"..math.random(7,9)..".wav", 120, math.random( 45, 55 ) )
								v:EmitSound( "physics/wood/wood_strain"..math.random(2,4)..".wav", 130, math.random( 65, 75 ) )

								if RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].extra_sound and IsValid( v.XRayAttacker ) then
									RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].extra_sound( v.XRayAttacker )
								end

								v:RagdollTakeXRayDamage( xray_num, RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].bone )
							end

							--if not v.XRayLerping then
								v.XRayLerping = CurTime() + xray_lerp_dur
								if v.XRayLastBonePos then
									table.Empty( v.XRayLastBonePos )
								else
									v.XRayLastBonePos = {}
								end
							--end

						end

						local xray_stance = RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].data

						local attacker = v.XRayAttacker
						local victim = v.XRayVictim

						if v.XRay == RAGDOLL_XRAY_VICTIM and !IsValid( attacker ) then
							v.XRay = nil
							v.XRayTime = nil
							return
						end

						if v.XRay == RAGDOLL_XRAY_ATTACKER and !IsValid( victim ) then
							v.XRay = nil
							v.XRayTime = nil
							return
						end

						local reference_bonename = "ValveBiped.Bip01_Pelvis"
						local reference_bone = pl:LookupBone( reference_bonename ) or 1

						if v.XRay == RAGDOLL_XRAY_VICTIM and attacker then
							reference_bone = attacker:LookupBone( reference_bonename )
						end

						local reference_physbone_id = v:TranslateBoneToPhysBone( reference_bone )
						local reference_physbone = v:GetPhysicsObjectNum( reference_physbone_id )

						if v.XRay == RAGDOLL_XRAY_VICTIM and attacker then
							reference_physbone_id = attacker:TranslateBoneToPhysBone( reference_bone )
							reference_physbone = attacker:GetPhysicsObjectNum( reference_physbone_id )
						end

						for i=0, v:GetPhysicsObjectCount() - 1 do

							local phys_bone = v:GetPhysicsObjectNum( i )
							local rag_bone = pl:TranslatePhysBoneToBone( i )
							local bone_name = v:GetBoneName( rag_bone )
							local bone = pl:LookupBone( bone_name )

							if xray_stance and xray_stance[ v.XRay ] and xray_stance[ v.XRay ][ bone_name ] and reference_physbone then
								if bone and phys_bone and phys_bone:IsValid() and not xray_stance[ v.XRay ][ bone_name ].ignore then

									local m = pl:GetBoneMatrix( reference_bone )

									if v.XRay == RAGDOLL_XRAY_VICTIM and attacker then
										m = attacker:GetBoneMatrix( reference_bone )
									end

									if m then

										local angles = v.XRayAngles or arena:GetAngles()--pl:GetAngles()

										--hacky way to adjust offset for some moves
										if v.XRay == RAGDOLL_XRAY_ATTACKER then

											if v.XRay == RAGDOLL_XRAY_ATTACKER and v.XRayFixHeight then
												m:SetTranslation( Vector( m:GetTranslation().x, m:GetTranslation().y, v.XRayFixHeight ) )-- m:GetTranslation() + v.XRayFixHeight
											end

											if v.XRay == RAGDOLL_XRAY_ATTACKER and RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].offset then
												m:SetTranslation( m:GetTranslation() + RagdollFight.XRayStances[ v.XRayIndex or 1 ][ v.XRayCurMove ].offset )
											end

										end

										local pos, ang = LocalToWorld( xray_stance[ v.XRay ][ bone_name ].pos, xray_stance[ v.XRay ][ bone_name ].ang, m:GetTranslation(), angles )

										if v.XRayLerping then
											if not v.XRayLastBonePos[ bone_name ] then
												local temp_ang = angles
												temp_ang.p = 0
												local temp_pos2, temp_ang2 = WorldToLocal( phys_bone:GetPos(), phys_bone:GetAngles(), reference_physbone:GetPos(), temp_ang )
												v.XRayLastBonePos[ bone_name ] = { pos = temp_pos2, ang = temp_ang2  }
											end
											if v.XRayLerping >= CurTime() then
												local delta = math.Clamp( 1 - ( v.XRayLerping - CurTime() )/xray_lerp_dur, 0, 1 )

												local lerp_pos = LerpVector( delta, v.XRayLastBonePos[ bone_name ].pos, xray_stance[ v.XRay ][ bone_name ].pos )
												local lerp_ang = LerpAngle( delta, v.XRayLastBonePos[ bone_name ].ang, xray_stance[ v.XRay ][ bone_name ].ang )
												pos, ang = LocalToWorld( lerp_pos, lerp_ang, m:GetTranslation(), angles )

											else
												v.XRayLerping = nil
											end
										end

										if pos and ang then

											phys_bone:Wake()
											--phys_bone:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
											--phys_bone:AddGameFlag( FVPHYSICS_NO_SELF_COLLISIONS )
											phys_bone:SetMaterial( "zombieflesh" )
											phys_bone:SetPos( pos )
											phys_bone:SetAngles( ang )
										end

									end
								end
							end

						end


					else

						if v:GetOwner():GetMoveType() == MOVETYPE_NONE then
							v:GetOwner():SetMoveType( MOVETYPE_WALK )
							RagdollFight.ResetDamping( v )
							--v.RagdollModeTime = CurTime() + 1.5
						end

						if v.XRay and v.XRayTime and v.XRayTime < CurTime() then

							if v.XRay == RAGDOLL_XRAY_VICTIM then
								if v.DontForceRagdoll then
									v.DontForceRagdoll = nil
								else
									v.RagdollModeTime = CurTime() + 1.5
								end
							end

							v.XRay = nil
							v.XRayTime = nil
							RagdollFight.ResetDamping( v )

						end

						if v.XRayCurMove then
							v.XRayCurMove = nil
						end


						for i=0, v:GetPhysicsObjectCount() - 1 do
							local phys_bone = v:GetPhysicsObjectNum( i )
							local rag_bone = pl:TranslatePhysBoneToBone( i )
							local bone_name = v:GetBoneName( rag_bone )
							local bone = pl:LookupBone( bone_name )

							if bone_stance and bone_stance[ bone_name ] and reference_physbone then
								if bone and phys_bone and phys_bone:IsValid() and not bone_stance[ bone_name ].ignore then

									local m = pl:GetBoneMatrix( reference_bone )
									if m then

										if v.Stance == RAGDOLL_STANCE_SLIDE then
											m:SetTranslation( m:GetTranslation() - vector_up * 20 )
										end

										local pos, ang = LocalToWorld( bone_stance[ bone_name ].pos, bone_stance[ bone_name ].ang, m:GetTranslation(), pl:GetAngles() )


										if v.Lerping then
											if not v.LastBonePos[ bone_name ] then
												local temp_ang = pl:GetAngles()
												temp_ang.p = 0
												local temp_pos2, temp_ang2 = WorldToLocal( phys_bone:GetPos(), phys_bone:GetAngles(), reference_physbone:GetPos(), temp_ang )
												v.LastBonePos[ bone_name ] = { pos = temp_pos2, ang = temp_ang2  }
											end
											if v.Lerping >= CurTime() and last_stance then
												local delta = math.Clamp( 1 - ( v.Lerping - CurTime() )/lerp_dur, 0, 1 )

												if last_stance[ bone_name ] then
													local lerp_pos = LerpVector( delta, last_stance[ bone_name ].pos, bone_stance[ bone_name ].pos )
													local lerp_ang = LerpAngle( delta, last_stance[ bone_name ].ang, bone_stance[ bone_name ].ang )
													pos, ang = LocalToWorld( lerp_pos, lerp_ang, m:GetTranslation(), pl:GetAngles() )
												else
													local lerp_pos = LerpVector( delta, v.LastBonePos[ bone_name ].pos, bone_stance[ bone_name ].pos )
													local lerp_ang = LerpAngle( delta, v.LastBonePos[ bone_name ].ang, bone_stance[ bone_name ].ang )
													pos, ang = LocalToWorld( lerp_pos, lerp_ang, m:GetTranslation(), pl:GetAngles() )
												end
											else
												v.LastStance = v.Stance
												v.LastStanceNum = v.StanceNum
												v.Lerping = nil
											end
										end

										if pos and ang then

											phys_bone:Wake()
											--phys_bone:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
											--phys_bone:AddGameFlag( FVPHYSICS_NO_SELF_COLLISIONS )
											phys_bone:SetMaterial( "zombieflesh" )
											phys_bone:SetPos( pos )
											phys_bone:SetAngles( ang )
											phys_bone:SetVelocity( pl:GetVelocity() )

										end
									end

								end
							else
								if bone and phys_bone and phys_bone:IsValid() then

									local m = pl:GetBoneMatrix( bone )
									if m then

										if v.Stance == RAGDOLL_STANCE_SLIDE then
											m:SetTranslation( m:GetTranslation() - vector_up * 20 )
										end

										local pos, ang = m:GetTranslation(), m:GetAngles()
										if pos and ang then

											phys_bone:Wake()
											--phys_bone:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
											--phys_bone:AddGameFlag( FVPHYSICS_NO_SELF_COLLISIONS )
											phys_bone:SetMaterial( "zombieflesh" )
											phys_bone:SetPos( pos )
											phys_bone:SetAngles( ang )
											phys_bone:SetVelocity( pl:GetVelocity() )

										end
									end
								end
							end
						end
					end

				end
			end
		end
	end
end
hook.Add( "Think", "RagdollFightThink", RagdollFight.Think )

local IdleActivity = ACT_HL2MP_IDLE_FIST
local IdleActivityTranslate = {}
IdleActivityTranslate[ ACT_MP_STAND_IDLE ]					= IdleActivity
IdleActivityTranslate[ ACT_MP_WALK ]						= IdleActivity + 1
IdleActivityTranslate[ ACT_MP_RUN ]							= IdleActivity + 2
IdleActivityTranslate[ ACT_MP_CROUCH_IDLE ]					= IdleActivity + 3
IdleActivityTranslate[ ACT_MP_CROUCHWALK ]					= IdleActivity + 4
IdleActivityTranslate[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ]	= IdleActivity + 5
IdleActivityTranslate[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ]	= IdleActivity + 5
IdleActivityTranslate[ ACT_MP_RELOAD_STAND ]				= IdleActivity + 6
IdleActivityTranslate[ ACT_MP_RELOAD_CROUCH ]				= IdleActivity + 6
IdleActivityTranslate[ ACT_MP_JUMP ]						= ACT_HL2MP_JUMP_SLAM
IdleActivityTranslate[ ACT_MP_SWIM ]						= IdleActivity + 9
IdleActivityTranslate[ ACT_LAND ]							= ACT_LAND

function RagdollFight.TranslateActivity( ply, act )
	if ply.Ragdoll and ply.Ragdoll:IsValid() then
		return IdleActivityTranslate[ act ]
	end
end
hook.Add( "TranslateActivity", "RagdollFightTranslateActivity", RagdollFight.TranslateActivity )

util.AddNetworkString( "RagdollFightSendXRay" )

function RagdollFight.KeyPress( pl, key )

	if pl.Ragdoll and pl.Ragdoll:IsValid() then

		pl.Ragdoll.NextAttack = pl.Ragdoll.NextAttack or 0

		if pl.Ragdoll.StanceDuration and pl.Ragdoll.StanceDuration > CurTime() then return end
		if pl.Ragdoll.NextAttack and pl.Ragdoll.NextAttack > CurTime() then return end
		if pl.Ragdoll.XRay and pl.Ragdoll.XRayTime and pl.Ragdoll.XRayTime > CurTime() then return end

		--escape grab powerup
		if key == IN_USE and IsValid( pl.Ragdoll.GrabbedBy ) and pl.Ragdoll:HasPowerup( RAGDOLL_POWERUP_BREAKER ) then
			local enemy = pl.Ragdoll.GrabbedBy
			pl.Ragdoll.WasThrown = nil
			enemy.RagdollModeTime = CurTime() + 1.5
			RagdollFight.ApplyForce( enemy, pl:GetForward() + vector_up, 3000 )
			RagdollFight.ApplyForce( pl.Ragdoll, pl:GetForward() * -1 + vector_up, 3000 )
			enemy.WasThrown = 1.2
			enemy:EmitSound( "npc/antlion_guard/shove1.wav", 100, math.random( 100, 115 ) )
			pl.Ragdoll:ConsumeCharge( RAGDOLL_POWERUP_BREAKER )
			RagdollFight.ResetMass( pl.Ragdoll )
			enemy.GrabbedObject.GrabbedBy = nil
			enemy.GrabbedObject = nil
			if enemy._Constraints then
				constraint.RemoveConstraints( enemy, "Weld" )
			end
			enemy.Grab = false
			pl.Ragdoll.GrabbedBy = nil
			pl.Ragdoll.NextAttack = CurTime() + 1
			return
		end

		if pl.Ragdoll.RagdollMode then return end
		if pl.Ragdoll.RagdollModeTime then return end


		if key == IN_RELOAD and !pl.Ragdoll.RagdollMode and !IsValid( pl.Ragdoll.GrabbedObject ) and !pl.Ragdoll.Grab then
			pl.Ragdoll.Blocking = pl:Crouching() and RAGDOLL_BLOCK_CROUCH or RAGDOLL_BLOCK_NORMAL
		end

		pl.Ragdoll.NextTaunt = pl.Ragdoll.NextTaunt or 0

		if key == IN_WALK and !pl.Ragdoll.RagdollMode and !pl.RagdollModeTime and !pl.Ragdoll.Blocking and !IsValid( pl.Ragdoll.GrabbedObject ) and pl.Ragdoll.NextTaunt < CurTime() then
			pl.Ragdoll.Stance = RAGDOLL_STANCE_TAUNT
			pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
			pl.Ragdoll.StanceDuration = CurTime() + 0.2
			pl.Ragdoll.RagdollModeTime = CurTime() + 0.2
			pl.Ragdoll.NextTaunt = CurTime() + 5
			RagdollFight.ApplyForce( pl.Ragdoll, 1 * pl:GetForward() * 0 - vector_up, 2800 )
			pl.Ragdoll:EmitSound( "physics/body/body_medium_break"..math.random(2,4)..".wav", 100, math.random( 100, 115 ) )
			return
		end

		--xray shit
		if key == IN_ATTACK and !pl.Ragdoll.Blocking and IsValid( pl.Ragdoll.GrabbedObject ) and pl.Ragdoll.GrabbedObject.IsRagdollFighter and pl.Ragdoll:HasPowerup( RAGDOLL_POWERUP_XRAY ) then

			local victim = pl.Ragdoll.GrabbedObject
			local me = pl.Ragdoll

			local xray_ind = math.random( 1, #RagdollFight.XRayStances )

			me.XRay = RAGDOLL_XRAY_ATTACKER
			victim.XRay = RAGDOLL_XRAY_VICTIM

			local xray_dir = pl.RagdollFightArena:GetDirVector( 1 )

			if xray_dir:Dot( pl:GetForward() ) < 0 then
				xray_dir = pl.RagdollFightArena:GetDirVector( 2 )
			end

			if xray_ind == 4 then
				xray_dir = pl.RagdollFightArena:GetDirVector( 2 )
			end

			local xray_ang = xray_dir:Angle()

			me.XRayIndex = xray_ind
			victim.XRayIndex = xray_ind

			me.XRayFixHeight = nil
			victim.XRayFixHeight = nil

			local fix_pos = pl.RagdollFightArena:GetPos() + vector_up * 36

			me.XRayFixHeight = fix_pos.z

			me.XRayVictim = victim
			victim.XRayAttacker = me

			me.XRayAngles = xray_ang
			victim.XRayAngles = xray_ang

			me.XRayOrigin = nil
			victim.XRayOrigin = nil

			me.XRayDamage = nil
			victim.XRayDamage = nil

			me.XRayDuration = 6
			victim.XRayDuration = me.XRayDuration

			me.XRayLerping = nil
			victim.XRayLerping = nil

			me.XRayTime = CurTime() + me.XRayDuration
			victim.XRayTime = CurTime() + victim.XRayDuration

			pl:SetLocalVelocity( vector_origin )
			victim:SetLocalVelocity( vector_origin )

			pl:SetMoveType( MOVETYPE_NONE )
			victim:GetOwner():SetMoveType( MOVETYPE_NONE )

			--we dont want to make slowmotion, so we are going make it look like one
			RagdollFight.ChangeDamping( me, 70, 70 * 1.5 )
			RagdollFight.ChangeDamping( victim, 70, 70 * 1.5 )

			--RagdollFightResetMass( victim )

			victim.WasThrown = nil
			me.GrabbedObject = nil
			victim.RagdollMode = false
			victim.RagdollModeTime = nil
			if me._Constraints then
				constraint.RemoveConstraints( me, "Weld" )
			end
			me.Grab = false
			victim.GrabbedBy = nil
			me.NextAttack = CurTime() + 1
			victim.NextAttack = CurTime() + 1

			local xray_tbl = RagdollFight.XRayStances[ xray_ind ]

			local send = {}

			for i=1, #xray_tbl do
				send[ i ] = xray_tbl[ i ].bone
			end

			net.Start( "RagdollFightSendXRay" )
				net.WriteEntity( victim )
				net.WriteEntity( pl.Ragdoll )
				net.WriteInt( victim.XRayDuration, 32 )
				net.WriteInt( #xray_tbl, 32 )
				net.WriteInt( xray_ind, 32 )
				net.WriteTable( send )
			net.Send( pl )

			net.Start( "RagdollFightSendXRay" )
				net.WriteEntity( victim )
				net.WriteEntity( pl.Ragdoll )
				net.WriteInt( victim.XRayDuration, 32 )
				net.WriteInt( #xray_tbl, 32 )
				net.WriteInt( xray_ind, 32 )
				net.WriteTable( send )
			net.Send( victim:GetOwner() )

			pl.Ragdoll:ConsumeCharge( RAGDOLL_POWERUP_XRAY )

			return
		end

		local dur = 0.3

		if key == IN_ATTACK and !pl.Ragdoll.RagdollMode and !pl.Ragdoll.Blocking and !IsValid( pl.Ragdoll.GrabbedObject ) then

				if pl:OnGround() then
					if pl:Crouching() then
						if pl:GetVelocity():Length2DSqr() >= 22100 then
							dur = 0.6
							pl:SetGroundEntity( NULL )
							pl:SetLocalVelocity( pl:GetForward() * 1000 )
							pl.Ragdoll.Stance = RAGDOLL_STANCE_SLIDE
							pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
							pl.Ragdoll.StanceDuration = CurTime() + dur
							pl.Ragdoll.NextAttack = CurTime() + 1
							local use_charge = pl.Ragdoll:HasPowerup( RAGDOLL_POWERUP_HEAVYATTACK )-- and pl:KeyDown( IN_SPEED )
							ActivateHitbox( pl.Ragdoll, false, false, true, true, RAGDOLL_ATTACK_CROUCH, 500, use_charge, RAGDOLL_DAMAGE_LEG_SLIDE, use_charge and 1.8 or nil )
							if use_charge then
								pl.Ragdoll:ConsumeCharge( RAGDOLL_POWERUP_HEAVYATTACK )
							end
						else
							pl.Ragdoll.Stance = RAGDOLL_STANCE_CROUCH_ATTACK
							pl.Ragdoll.StanceNum = pl.Ragdoll.LastStanceNum == 1 and 2 or 1 --RandomStanceNum( pl.Ragdoll.Stance )
							pl.Ragdoll.StanceDuration = CurTime() + dur
							pl.Ragdoll.NextAttack = CurTime() + dur
							ActivateHitbox( pl.Ragdoll, false, false, true, true, RAGDOLL_ATTACK_CROUCH, 100, nil, RAGDOLL_DAMAGE_FISTS )
						end
					else
						pl.Ragdoll.Stance = RAGDOLL_STANCE_ATTACK
						pl.Ragdoll.StanceNum = pl.Ragdoll.LastStanceNum == 1 and 2 or 1--RandomStanceNum( pl.Ragdoll.Stance )
						pl.Ragdoll.StanceDuration = CurTime() + dur
						pl.Ragdoll.NextAttack = CurTime() + dur
						ActivateHitbox( pl.Ragdoll, true, true, false, false, RAGDOLL_ATTACK_NORMAL, 100, nil, RAGDOLL_DAMAGE_FISTS )
					end
				else
					if pl:KeyDown( IN_FORWARD ) then--pl:GetVelocity():Length2DSqr() >= 36100
						dur = 0.5
						pl:SetGroundEntity( NULL )
						pl:SetLocalVelocity( pl:GetForward() * 400 )
						pl.Ragdoll.Stance = RAGDOLL_STANCE_JUMP_ATTACK_SPRINT
						pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
						pl.Ragdoll.StanceDuration = CurTime() + dur
						pl.Ragdoll.NextAttack = CurTime() + 1.1
						local use_charge = pl.Ragdoll:HasPowerup( RAGDOLL_POWERUP_HEAVYATTACK )-- and pl:KeyDown( IN_SPEED )
						ActivateHitbox( pl.Ragdoll, false, false, true, true, RAGDOLL_ATTACK_NORMAL, 1000, use_charge, RAGDOLL_DAMAGE_LEG_HEAVY, use_charge and 1.8 or nil )
						if use_charge then
							pl.Ragdoll:ConsumeCharge( RAGDOLL_POWERUP_HEAVYATTACK )
						end
					else
						dur = 0.4
						pl.Ragdoll.Stance = RAGDOLL_STANCE_JUMP_ATTACK
						pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
						pl.Ragdoll.StanceDuration = CurTime() + dur
						pl.Ragdoll.NextAttack = CurTime() + dur
						ActivateHitbox( pl.Ragdoll, false, false, false, true, RAGDOLL_ATTACK_NORMAL, 500, nil, RAGDOLL_DAMAGE_FISTS )
					end
				end

				pl.Ragdoll.Attack = CurTime() + dur

		end

		if key == IN_ATTACK2 and !IsValid( pl.Ragdoll.GrabbedObject ) and !pl.Ragdoll.Blocking then
			pl.Ragdoll.Grab = true
			pl.Ragdoll.GrabTime = CurTime() + 1
			if pl:OnGround() then
				pl.Ragdoll.Stance = RAGDOLL_STANCE_GRAB
				pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
				pl.Ragdoll.StanceDuration = CurTime() + 0.2
				pl.Ragdoll.NextAttack = CurTime() + 0.4
			else
				pl.Ragdoll.Stance = RAGDOLL_STANCE_GRAB_JUMP
				pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
				pl.Ragdoll.StanceDuration = CurTime() + 0.3
				pl.Ragdoll.NextAttack = CurTime() + dur
			end
		end

	end

end
hook.Add( "KeyPress", "RagdollFightKeyPress", RagdollFight.KeyPress )

function RagdollFight.KeyRelease( pl, key )

	if pl.Ragdoll and pl.Ragdoll:IsValid() then

		if key == IN_RELOAD and pl.Ragdoll.Blocking and !pl.Ragdoll.RagdollMode and !IsValid( pl.Ragdoll.GrabbedObject ) and !pl.Ragdoll.Grab then
			pl.Ragdoll.Blocking = nil
		end

		if key == IN_ATTACK2 then

			if IsValid( pl.Ragdoll.GrabbedObject ) and !pl.Ragdoll.RagdollMode and !pl.Ragdoll.RagdollModeTime then
				if pl.Ragdoll.GrabbedObject.IsRagdollFighter then

					local dur = 0.3

					if pl:OnGround() then
						if pl:Crouching() then
							pl.Ragdoll.Stance = RAGDOLL_STANCE_GRAB_ATTACK_BACKTHROW
							pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
							RagdollFight.ApplyForce( pl.Ragdoll.GrabbedObject, -1 * pl:GetForward() - vector_up , 7000, true )
							pl.Ragdoll.StanceDuration = CurTime() + dur
							pl.Ragdoll.GrabbedObject.WasThrown = 1.6
							pl.Ragdoll.NextAttack = CurTime() + 1
						else
							pl.Ragdoll.Stance = RAGDOLL_STANCE_GRAB_ATTACK_THROW
							pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
							RagdollFight.ApplyForce( pl.Ragdoll.GrabbedObject, pl:GetForward() + vector_up * 0.05 , 1000 )
							pl.Ragdoll.GrabbedObject.WasThrown = 0.2
							pl.Ragdoll.StanceDuration = CurTime() + dur
							pl.Ragdoll.NextAttack = CurTime() + 0
						end
					else
						pl:SetGroundEntity( NULL )
						pl:SetLocalVelocity( vector_up * -250 )
						pl.Ragdoll.Stance = RAGDOLL_STANCE_GRAB_ATTACK_SLAM
						pl.Ragdoll.StanceNum = RandomStanceNum( pl.Ragdoll.Stance )
						RagdollFight.ApplyForce( pl.Ragdoll.GrabbedObject, pl:GetForward() * 0.1 - vector_up , 18000, true )
						pl.Ragdoll.GrabbedObject.WasThrown = 1.3
						pl.Ragdoll.StanceDuration = CurTime() + dur
						pl.Ragdoll.NextAttack = CurTime() + 1
					end
					pl.Ragdoll.ThrowTime = CurTime() + 4
					pl.Ragdoll.GrabbedObject.NextGrab = CurTime() + 4
					RagdollFight.ResetMass( pl.Ragdoll.GrabbedObject )

				end
				pl.Ragdoll.GrabbedObject.GrabbedBy = nil
				pl.Ragdoll.GrabbedObject = nil
			end
			if pl.Ragdoll._Constraints then
				constraint.RemoveConstraints( pl.Ragdoll, "Weld" )
			end
			pl.Ragdoll.Grab = false
		end

	end

end
hook.Add( "KeyRelease", "RagdollFightKeyRelease", RagdollFight.KeyRelease )

hook.Add( "AllowPlayerPickup", "RagdollFightAllowPlayerPickup", function( pl, ent )
	if pl.Ragdoll and pl.Ragdoll:IsValid() then
		return false
	end
 end)

hook.Add( "PlayerSwitchFlashlight", "RagdollFightPlayerSwitchFlashlight", function( pl, enabled )
	if pl.Ragdoll and pl.Ragdoll:IsValid() then
		return false
	end
end)

hook.Add( "PlayerSpawnProp", "RagdollFightPlayerSpawnProp", function( pl, model )
	if pl and pl.RagdollFightArena and pl.RagdollFightArena:IsValid() then return false end
end)

--command for making stances. gonna lock it behind IsAdmin, just to be sure
function RagdollFight.SaveStance( pl, cmd, args )

	if not pl then return end
	if !pl:IsAdmin() then return end

	local ent = pl:GetEyeTrace().Entity

	local id = args and args[1] and tonumber(args[1]) or nil

	local remember = id and id == 1
	local override = id and id == 2 and IsValid( pl.RememberRag ) and pl.RememberRag

	if !IsValid( ent ) then return end
	if ent:GetClass() ~= "prop_ragdoll" then return end

	print"----------"
	print( pl.RememberRag )
	print( pl.RememberAng )

	print( "remember ", remember )
	print( "override ", override )

	local reference_bonename = "ValveBiped.Bip01_Pelvis"
	local reference_bone = ent:LookupBone( reference_bonename ) or 1

	if override then
		reference_bone = override:LookupBone( reference_bonename )
	end

	if not reference_bone then return end


	local reference_physbone_id = ent:TranslateBoneToPhysBone( reference_bone )
	local reference_physbone = ent:GetPhysicsObjectNum( reference_physbone_id )

	if override then
		reference_physbone_id = override:TranslateBoneToPhysBone( reference_bone )
		reference_physbone = override:GetPhysicsObjectNum( reference_physbone_id )
	end

	local tbl = "{\n"

	if reference_physbone then

		local ref_pos = reference_physbone:GetPos()
		local ref_angle = reference_physbone:GetAngles()

		for i=0, ent:GetPhysicsObjectCount() - 1 do

			--if i == reference_physbone_id then continue end

			local phys_bone = ent:GetPhysicsObjectNum( i )
			local rag_bone = ent:TranslatePhysBoneToBone( i )
			local bone_name = ent:GetBoneName( rag_bone )

			if phys_bone and phys_bone:IsValid() then

				local ignore = ""

				if phys_bone:IsMoveable() then
					ignore = ", ignore = true"
				end

				local pos = reference_physbone:GetPos()
				local ang = pl:GetAngles()

				if pl.RememberAng then
					ang = pl.RememberAng
				end

				ang.p = 0

				local offset_pos, offset_ang = WorldToLocal( phys_bone:GetPos(), phys_bone:GetAngles(), pos, ang )

				tbl = tbl.."	[\""..bone_name.."\"] = { pos = Vector( "..offset_pos.x..", "..offset_pos.y..", "..offset_pos.z.." ), ang = Angle( "..offset_ang.p..", "..offset_ang.y..", "..offset_ang.r.." )"..ignore.." },\n"

				--print( bone_name )
				--print( offset_pos )
				--print( offset_ang )

			end

		end

	end

	if pl.RememberRag then
		pl.RememberRag = nil
		pl.RememberAng = nil
	end

	if remember then
		pl.RememberRag = ent
		local ang = pl:GetAngles()
		ang.p = 0
		pl.RememberAng = ang
	end

	tbl = tbl.."},"

	print(tbl)


end
concommand.Add( "rag_remember", RagdollFight.SaveStance )

--small command for making xray weapons. gonna lock it behind IsAdmin, just to be sure
function RagdollFight.SaveWeapon( pl, cmd, args )

	if not pl then return end
	if !pl:IsAdmin() then return end
	local tr = pl:GetEyeTrace()
	local ent = tr.Entity

	local id = args and args[1] and tonumber(args[1]) or nil

	local ragdoll = id and id == 1
	local weapon = id and id == 2

	if !IsValid( ent ) then return end

	if ragdoll then

		if tr.PhysicsBone then

			local bone = ent:TranslatePhysBoneToBone( tr.PhysicsBone )
			if bone then
				local bone_name = ent:GetBoneName( bone )
				local m = ent:GetBoneMatrix( bone )
				if m then
					local pos, ang = m:GetTranslation(), m:GetAngles()
					print( bone_name, pos, ang )
					if pl.RememberRagWep then
						table.Empty( pl.RememberRagWep )
					else
						pl.RememberRagWep = {}
					end
					pl.RememberRagWep.bone_name = bone_name
					pl.RememberRagWep.pos = pos
					pl.RememberRagWep.ang = ang
				end
			end

		end
	end

	if weapon then
		if pl.RememberRagWep then

			if ent:GetClass() == "prop_effect" then
				ent = ent.AttachedEntity
			end

			local pos, ang = ent:GetPos(), ent:GetAngles()

			local new_pos, new_ang = WorldToLocal( pos, ang, pl.RememberRagWep.pos, pl.RememberRagWep.ang )
			local text = "{ mdl = Model( \""..ent:GetModel().."\" ), bone = \""..pl.RememberRagWep.bone_name.."\", pos = Vector( "..new_pos.x..", "..new_pos.y..", "..new_pos.z.." ), ang = Angle( "..new_ang.p..", "..new_ang.y..", "..new_ang.r.." ) },"

			print("\n\n", text)

		end
	end


end
concommand.Add( "rag_remember_wep", RagdollFight.SaveWeapon )

end

if CLIENT then

surface.CreateFont( "RagdollFightDefault", {
	font	= "Dejavu Sans",
	size	= 22,
	weight	= 800
} )

surface.CreateFont( "RagdollFightDefaultTitle", {
	font	= "Dejavu Sans",
	size	= 32,
	weight	= 800
} )

surface.CreateFont( "RagdollFightRoundNumber", {
	font	= "Dejavu Sans",
	size	= 52,
	weight	= 800
} )

surface.CreateFont( "RagdollFightBigMessage", {
	font	= "Dejavu Sans",
	size	= 150,
	weight	= 800
} )

surface.CreateFont( "RagdollFightMedMessage", {
	font	= "Dejavu Sans",
	size	= 65,
	weight	= 800
} )

surface.CreateFont( "RagdollFightSmallMessage", {
	font	= "Dejavu Sans",
	size	= 50,
	weight	= 800
} )

surface.CreateFont( "RagdollFightChargeDesc", {
	font	= "Dejavu Sans",
	size	= 18,
	weight	= 800
} )


net.Receive( "RagdollFightUpdateRagdoll", function( len )

	if !IsValid( LocalPlayer() ) then return end

	local rag_id = net.ReadInt( 32 )
	local rag = Entity( rag_id )
	if rag and rag:IsValid() then
		LocalPlayer().Ragdoll = rag
	end


end)

function RagdollFight.CreateMove( cmd )

	local pl = LocalPlayer()
	local arena = IsValid( pl.RagdollFightArena ) and pl.RagdollFightArena

	if arena and pl:Alive() then
		local pl1 = arena:GetPlayer( 1 )
		local pl2 = arena:GetPlayer( 2 )

		local rag1 = arena:GetRagdollFighter( 1 )
		local rag2 = arena:GetRagdollFighter( 2 )

		local enemy = pl == pl1 and pl2 or pl1

		local my_rag = pl == pl1 and rag1 or rag2
		local enemy_rag = pl == pl1 and rag2 or rag1

		local ang = arena:GetAngles()
		ang.p = 0

		if pl == pl1 then

		end

		if pl == pl2 then
			ang:RotateAroundAxis( arena:GetUp(), 180 )
		end

		if enemy and enemy:IsValid() and enemy ~= pl and rag1 and rag1:IsValid() and rag2 and rag2:IsValid() and enemy_rag and enemy_rag:IsValid() and pl:GetCollisionGroup() == COLLISION_GROUP_PLAYER then-- and pl:GetMoveType() ~= MOVETYPE_NONE then
			ang = ( enemy_rag:GetPos() - pl:GetPos() ):GetNormal():Angle()
		end

		ang.p = 0

		cmd:SetViewAngles( ang )
	end

end
hook.Add( "CreateMove", "RagdollFightCreateMove", RagdollFight.CreateMove )

hook.Add( "OnSpawnMenuOpen", "RagdollFightOnSpawnMenuOpen", function()
	local pl = LocalPlayer()
	if pl and pl.RagdollFightArena and pl.RagdollFightArena:IsValid() then return false end
end )

hook.Add( "DrawDeathNotice", "RagdollFightDrawDeathNotice", function()
	local pl = LocalPlayer()
	if pl and pl.RagdollFightArena and pl.RagdollFightArena:IsValid() then return false end
end )

net.Receive( "RagdollFightSendXRay", function( len )

	local pl = LocalPlayer()

	if !IsValid( pl ) then return end

	if pl.XRayTable then
		table.Empty( pl.XRayTable )
	else
		pl.XRayTable = {}
	end

	local enemy_rag = net.ReadEntity()
	local attacker_rag = net.ReadEntity()
	local xray_dur = net.ReadInt( 32 )
	local xray_num = net.ReadInt( 32 )
	local xray_ind = net.ReadInt( 32 )
	local xray_bones = net.ReadTable()


	pl.XRayTable.enemy_rag = enemy_rag
	pl.XRayTable.attacker_rag = attacker_rag
	pl.XRayTable.xray_dur = xray_dur
	pl.XRayTable.xray_time = CurTime() + xray_dur
	pl.XRayTable.xray_num = xray_num
	pl.XRayTable.xray_ind = xray_ind
	pl.XRayTable.xray_bones = xray_bones
	pl.XRayTable.xray_zoom = 0
	pl.XRayTable.xray_zoom_goal = 0
	pl.XRayTable.xray_zoom_dist = 60

end )

local bloody = Material( "models/skeleton/skeleton_bloody" )
local skeleton = Model( "models/player/skeleton.mdl" )
local zombie = Model( "models/player/zombie_fast.mdl" )
local skull = Model( "models/Gibs/HGIBS.mdl" )
local flesh = Material("models/flesh")

local bone_gibs = {
	[ "ValveBiped.Bip01_Head1" ] = { mdl = Model( "models/gibs/hgibs_scapula.mdl" ), scale = function() return math.Rand( 0.2, 0.7 ) end, spacing = function() return math.Rand( 2, 5 ) end, am = 6 },
	[ "ValveBiped.Bip01_Spine2" ] = { mdl = Model( "models/gibs/hgibs_rib.mdl" ), scale = function() return math.Rand( 0.6, 0.8 ) end, spacing = function() return math.Rand( 2, 6 ) end, am = 5 },
	[ "ValveBiped.Bip01_Spine1" ] = { mdl = Model( "models/gibs/hgibs_rib.mdl" ), scale = function() return math.Rand( 0.4, 0.9 ) end, spacing = function() return math.Rand( 2, 6 ) end, am = 5 },
	[ "ValveBiped.Bip01_Pelvis" ] = { mdl = Model( "models/gibs/hgibs_scapula.mdl" ), scale = function() return math.Rand( 0.7, 1 ) end, spacing = function() return math.Rand( 3, 8 ) end, am = 5 },
}

local function CreateDummy( self )

	if self.Dummy then return end

	if not self.CreateDummyNextFrame then
		self.CreateDummyNextFrame = true
		return
	end

	local pl = LocalPlayer()

	self.Dummy = ClientsideModel( self.OriginalModel, RENDERGROUP_BOTH )--RENDER_GROUP_OPAQUE_ENTITY
	if self.Dummy then
		self.Dummy:SetPos( self:GetPos() )
		self.Dummy:SetAngles( self:GetAngles() )
		self.Dummy:SetParent( self )
		self.Dummy:SetNoDraw( true )

		pl.RagdollFightDummies = pl.RagdollFightDummies or {}

		table.insert( pl.RagdollFightDummies, self.Dummy )
	end

end

local function DrawMask( self, pos, ang )

	if self.Dummy and self.Dummy:IsValid() then

		self.Dummy:SetModel( skull )

		self.Dummy:SetParent()

		self.Dummy:SetPos( pos )
		self.Dummy:SetAngles( ang )

		self.Dummy:SetModelScale( 2.7, 0 )
		self.Dummy:SetupBones()

		self.Dummy:DrawModel()

	end

end

local function DrawWeapons( self, attacker, cur_xray, cur_move )

	if self.Dummy and self.Dummy:IsValid() and attacker and RagdollFight.XRayStances[ cur_xray ] and RagdollFight.XRayStances[ cur_xray ][ cur_move ] and RagdollFight.XRayStances[ cur_xray ][ cur_move ].weapon then

		local weps = RagdollFight.XRayStances[ cur_xray ][ cur_move ].weapon

		for i = 1, #weps do

			local tbl = weps[i]
			if tbl then

				local ent = attacker

				if tbl.victim then
					ent = self
				end

				local bone = ent:LookupBone( tbl.bone )
				if bone then

					local m = ent:GetBoneMatrix( bone )
					if m then

						local bone_pos, bone_ang = m:GetTranslation(), m:GetAngles()
						local new_pos, new_ang = LocalToWorld( tbl.pos, tbl.ang, bone_pos, bone_ang )

						if new_pos and new_ang then
							self.Dummy:SetModel( tbl.mdl )

							self.Dummy:SetParent()

							self.Dummy:SetPos( new_pos )
							self.Dummy:SetAngles( new_ang )

							self.Dummy:SetModelScale( 1, 0 )
							self.Dummy:SetupBones()
							self.Dummy:DrawModel()
						end
					end
				end
			end

		end

	end

end

local function CollideCallback( particle, hitpos, hitnormal )
	if not particle.HitAlready then
		particle.HitAlready = true
		util.Decal( math.random( 3 ) == 3 and "Blood" or "Impact.Flesh", hitpos + hitnormal, hitpos - hitnormal )
	end
end

local function DrawChunks( self, bone_name, m, cur_move )
	if self.Dummy and self.Dummy:IsValid() then
		if bone_gibs[ bone_name ] then

			--reset chunk data

			local pos = m:GetTranslation()
			local ang = m:GetAngles()

			if self.PrevMove ~= cur_move then
				self.ChunkTime = CurTime() + 0.32
				self.PrevMove = cur_move
			end

			if self.ChunkTime and self.ChunkTime < CurTime() then

				self.ChunkTime = nil

				if self.ChunkTableStatic then
					table.Empty( self.ChunkTableStatic )
				else
					self.ChunkTableStatic = {}
				end

				for i = 1, bone_gibs[ bone_name ].am do
					self.ChunkTableStatic[ i ] = { offset = VectorRand() * bone_gibs[ bone_name ].spacing(), ang = VectorRand():Angle(), scale = bone_gibs[ bone_name ].scale() }
				end


				if self.ChunkTable then
					table.Empty( self.ChunkTable )
				else
					self.ChunkTable = {}
				end

				if self.Emitter then
					self.Emitter:Finish()
				end

				self.Emitter = ParticleEmitter( pos, true )

				local dir = vector_origin
				local pl = LocalPlayer()

				if pl.XRayTable.attacker_rag and pl.XRayTable.attacker_rag:IsValid() then
					dir = ( pos - pl.XRayTable.attacker_rag:LocalToWorld( pl.XRayTable.attacker_rag:OBBCenter() ) ):GetNormal() * 35
				end

				for i = 1, bone_gibs[ bone_name ].am do

					self.ChunkTable[ i ] = self.Emitter:Add( "Decals/flesh/Blood"..math.random(1,5),pos + VectorRand() * bone_gibs[ bone_name ].spacing() )
					local pos2 = pos + VectorRand() * bone_gibs[ bone_name ].spacing() / 3
					self.ChunkTable[ i ]:SetPos( pos2 )
					self.ChunkTable[ i ]:SetAngles( ( pos - pos2 ):GetNormal():Angle() )
					self.ChunkTable[ i ]:SetVelocity(VectorRand() * 93 + dir)
					self.ChunkTable[ i ]:SetAngleVelocity( VectorRand():Angle() * math.Rand( -1, 1 ) )
					self.ChunkTable[ i ]:SetDieTime( 2 )
					self.ChunkTable[ i ]:SetGravity( vector_up * - 100 )
					self.ChunkTable[ i ]:SetStartSize( 0 )
					self.ChunkTable[ i ]:SetCollideCallback( CollideCallback )
					self.ChunkTable[ i ]:SetEndSize( 0 )
					self.ChunkTable[ i ].ModelSize = bone_gibs[ bone_name ].scale()
					self.ChunkTable[ i ].AngRand = VectorRand():Angle()
					self.ChunkTable[ i ]:SetStartAlpha( 1 )
					self.ChunkTable[ i ]:SetEndAlpha( 1 )
					self.ChunkTable[ i ]:SetCollide( true )
					self.ChunkTable[ i ]:SetBounce( 40 )
					self.ChunkTable[ i ]:SetAirResistance( 222 )

				end

			end

			--dynamic ones
			for i = 1, bone_gibs[ bone_name ].am do

				if self.ChunkTable and self.ChunkTable[ i ] then

					self.Dummy:SetModel( bone_gibs[ bone_name ].mdl )
					self.Dummy:SetParent()
					self.Dummy:SetPos( self.ChunkTable[ i ]:GetPos() )

					self.Dummy:SetAngles( self.ChunkTable[ i ]:GetAngles() + self.ChunkTable[ i ].AngRand )

					self.Dummy:SetModelScale( self.ChunkTable[ i ].ModelSize, 0 )--self.ChunkTable[ i ]:GetStartSize()
					self.Dummy:SetupBones()

					render.ModelMaterialOverride( bloody )
					self.Dummy:DrawModel()
					render.ModelMaterialOverride( )

				end
			end

			--static
			for i = 1, bone_gibs[ bone_name ].am do

				if self.ChunkTableStatic and self.ChunkTableStatic[ i ] then

					self.Dummy:SetModel( bone_gibs[ bone_name ].mdl )
					self.Dummy:SetParent()
					self.Dummy:SetPos( pos + self.ChunkTableStatic[ i ].offset + ang:Forward() * 3 )
					self.Dummy:SetAngles( ang + self.ChunkTableStatic[ i ].ang )

					self.Dummy:SetModelScale( self.ChunkTableStatic[ i ].scale * 1.1, 0 )
					self.Dummy:SetupBones()

					render.ModelMaterialOverride( bloody )
					self.Dummy:DrawModel()
					render.ModelMaterialOverride( )

				end
			end

		end
	end
end

local function DrawSkeleton( self, delta )

	if self.Dummy and self.Dummy:IsValid() then

		/*self.Dummy:SetupBones()
		self.Dummy:SetModel( zombie )

		self.Dummy:SetParent( self )
		self.Dummy:AddEffects( EF_BONEMERGE )

		self.Dummy:SetModelScale( 1, 0 )
		--render.ModelMaterialOverride( bloody )
		render.SetBlend( math.Clamp( delta ^ 0.9, 0.9, 1 ) )
		--render.CullMode( MATERIAL_CULLMODE_CW )
		self.Dummy:DrawModel()
		--render.CullMode( MATERIAL_CULLMODE_CCW )
		render.SetBlend( 1 )
		--render.ModelMaterialOverride( )*/


		self.Dummy:SetupBones()
		self.Dummy:SetModel( skeleton )

		self.Dummy:SetParent( self )
		self.Dummy:AddEffects( EF_BONEMERGE )

		self.Dummy:SetModelScale( 1, 0 )
		render.ModelMaterialOverride( bloody )
		self.Dummy:DrawModel()
		render.ModelMaterialOverride( )

	end

end


local function DrawInsides( self )

	if self.Dummy and self.Dummy:IsValid() then

		self.Dummy:SetModel( self.OriginalModel )

		self.Dummy:SetParent( self )
		self.Dummy:AddEffects( EF_BONEMERGE )

		self.Dummy:SetModelScale( 1, 0 )
		render.ModelMaterialOverride( flesh )

		render.CullMode( MATERIAL_CULLMODE_CW )
		self.Dummy:SetupBones()
		self.Dummy:DrawModel()
		render.CullMode( MATERIAL_CULLMODE_CCW )

		render.ModelMaterialOverride( )

	end

end




function RagdollFight.RagdollDraw( self )

	if not self.OriginalModel then
		self.OriginalModel = self:GetModel()
	end

	CreateDummy( self )

	local pl = LocalPlayer()

	--xray draw
	if pl.XRayTable and pl.XRayTable.xray_time and pl.XRayTable.enemy_rag and pl.XRayTable.enemy_rag == self then

		local bones = pl.XRayTable.xray_bones

		local bone_name = bones[ pl.XRayTable.cur_move ]
		local bone = self:LookupBone( bone_name )

		if bone then
			local m = self:GetBoneMatrix( bone )
				if m then
				local bone_pos = m:GetTranslation()
				local bone_ang = m:GetAngles()
					if bone_pos and bone_ang then

						local delta = 1

						if pl.XRayTable.xray_zoom_time and pl.XRayTable.xray_zoom_time > CurTime() then
							delta = math.Clamp( ( pl.XRayTable.xray_zoom_time - CurTime() ) / ( pl.XRayTable.xray_zoom_time_dur ), 0, 1 )
						end

						local normal = EyeAngles():Forward()
						local distance = normal:Dot( bone_pos )

						local ang = EyeAngles()
						ang:RotateAroundAxis( ang:Right(), 90 )

						--insides
						render.ClearStencil()
						render.SetStencilEnable( true )

						render.SetStencilWriteMask( 1 )
						render.SetStencilTestMask( 1 )

						render.SetStencilFailOperation( STENCIL_REPLACE )
						render.SetStencilPassOperation( STENCIL_ZERO )
						render.SetStencilZFailOperation( STENCIL_ZERO )
						render.SetStencilCompareFunction( STENCIL_NEVER )
						render.SetStencilReferenceValue( 1 )

						DrawMask( self, bone_pos, bone_ang )

						render.SetStencilFailOperation( STENCIL_ZERO )
						render.SetStencilPassOperation( STENCIL_REPLACE )
						render.SetStencilZFailOperation( STENCIL_ZERO )
						render.SetStencilCompareFunction( STENCIL_EQUAL )

						render.SetStencilEnable( false )

						render.SetStencilEnable( true )
						render.SetStencilReferenceValue( 1 )

						render.OverrideDepthEnable( true, false )
						DrawInsides( self )
						render.OverrideDepthEnable( false, false )

						DrawSkeleton( self, delta )

						render.SetStencilEnable( false )


						--normal ragdoll outside of mask area
						render.ClearStencil()
						render.SetStencilEnable( true )

						render.SetStencilWriteMask( 1 )
						render.SetStencilTestMask( 1 )

						render.SetStencilFailOperation( STENCIL_REPLACE )
						render.SetStencilPassOperation( STENCIL_ZERO )
						render.SetStencilZFailOperation( STENCIL_ZERO )
						render.SetStencilCompareFunction( STENCIL_NEVER )
						render.SetStencilReferenceValue( 1 )

						render.OverrideDepthEnable( true, true )
						self:SetupBones()
						self:DrawModel()
						render.OverrideDepthEnable( false, false )

						render.SetStencilReferenceValue( 2 )

						DrawMask( self, bone_pos, bone_ang )

						render.SetStencilFailOperation( STENCIL_KEEP )
						render.SetStencilPassOperation( STENCIL_REPLACE )
						render.SetStencilZFailOperation( STENCIL_KEEP )
						render.SetStencilCompareFunction( STENCIL_EQUAL )

						render.SetStencilEnable( false )

						render.SetStencilEnable( true )
						render.SetStencilReferenceValue( 1 )

						self:SetupBones()
						self:DrawModel()

						--and dissapearing part of ragdoll inside mask area
						render.SetStencilReferenceValue( 2 )

						DrawChunks( self, bone_name, m, pl.XRayTable.cur_move or 1, bone_pos, bone_ang )

						render.SetBlend( delta ^ 3.5 )-- delta ^ 2
						self:SetupBones()
						self:DrawModel()
						render.SetBlend( 1 )

						render.SetStencilEnable( false )

						if pl.XRayTable.attacker_rag then
							DrawWeapons( self, pl.XRayTable.attacker_rag, pl.XRayTable.xray_ind, pl.XRayTable.cur_move )
						end

					end
				end
		end
	else
		self:DrawModel()
	end

end

local cam_offset = Vector( -200, 0, 75 )
local zero_ang = Angle( 0, 0, 0 )
local cur_viewpos
local last_arena

function RagdollFight.CalcView( pl, origin, angles, fov, znear, zfar )

	local arena = IsValid( pl.RagdollFightArena ) and pl.RagdollFightArena

	if arena and pl:Alive() then

		local pl1 = arena:GetPlayer( 1 )
		local pl2 = arena:GetPlayer( 2 )
		local enemy = pl == pl1 and pl2 or pl1

		local rag1 = arena:GetRagdollFighter( 1 )
		local rag2 = arena:GetRagdollFighter( 2 )

		if rag1 and rag1:IsValid() and not rag1.SetRenderOverride then
			rag1.RenderOverride = RagdollFight.RagdollDraw
			rag1.SetRenderOverride = true
		end

		if rag2 and rag2:IsValid() and not rag2.SetRenderOverride then
			rag2.RenderOverride = RagdollFight.RagdollDraw
			rag2.SetRenderOverride = true
		end

		local my_rag = pl == pl1 and rag1 or rag2
		local enemy_rag = pl == pl1 and rag2 or rag1

		local my_pos = my_rag and my_rag:IsValid() and my_rag:GetPos() or pl:GetShootPos()
		local enemy_pos = arena:GetPos() + arena:GetUp() * 75

		if enemy and enemy:IsValid() and enemy ~= pl and enemy_rag and enemy_rag:IsValid() then
			enemy_pos = enemy_rag:GetPos()
		end

		local max_dist = 390
		local dist = my_pos:Distance( enemy_pos )

		local my_pos_loc = arena:WorldToLocal( my_pos )
		local enemy_pos_loc = arena:WorldToLocal( enemy_pos )

		local dir = my_pos + enemy_pos

		local vec_center = ( my_pos_loc + enemy_pos_loc ) / 2

		vec_center.y = -1* math.min( 200, math.max( dist, 100 ) ) --zoom
		vec_center.z = math.max( 45, vec_center.z ) --height

		local add_z = 0

		if pl.XRayTable and pl.XRayTable.xray_time then
			if pl.XRayTable.xray_time > CurTime() then

				local mini_dur = pl.XRayTable.xray_dur / pl.XRayTable.xray_num
				local xray_lerp_dur = math.min( mini_dur / 3, 0.15 )

				if not pl.XRayTable.cur_move then

					pl.XRayTable.cur_move = 1
					pl.XRayTable.xray_zoom_goal = pl.XRayTable.xray_zoom_dist
					pl.XRayTable.xray_zoom = 0

					if not pl.XRayTable.xray_zoom_time then
						pl.XRayTable.xray_zoom_time = CurTime() + mini_dur * 0.65
						pl.XRayTable.xray_zoom_time_dur = mini_dur * 0.65
					end

				end

				if ( pl.XRayTable.xray_time - pl.XRayTable.xray_dur + pl.XRayTable.cur_move * mini_dur ) < CurTime() and pl.XRayTable.cur_move < pl.XRayTable.xray_num then
					pl.XRayTable.cur_move = math.Clamp( pl.XRayTable.cur_move + 1, 1, pl.XRayTable.xray_num )
					pl.XRayTable.xray_zoom_goal = pl.XRayTable.xray_zoom_dist

					if not pl.XRayTable.xray_zoom_time then
						pl.XRayTable.xray_zoom_time = CurTime() + mini_dur * 0.65
						pl.XRayTable.xray_zoom_time_dur = mini_dur * 0.65
					end

				end


				local rag = pl.XRayTable.enemy_rag
				local bones = pl.XRayTable.xray_bones

				if rag and rag:IsValid() and bones and bones[ pl.XRayTable.cur_move ] then

					local bone_name = bones[ pl.XRayTable.cur_move ]
					local bone = rag:LookupBone( bone_name )

					if bone then
						local m = rag:GetBoneMatrix( bone )
						if m then
							local bone_pos = m:GetTranslation()
							if bone_pos then
								local bone_pos_loc = arena:WorldToLocal( bone_pos )
								local delta = 1 - ( pl.XRayTable.xray_zoom_goal - pl.XRayTable.xray_zoom ) / pl.XRayTable.xray_zoom_dist

								vec_center = LerpVector( delta, vec_center, bone_pos_loc )
								vec_center.y = -1* math.min( 200, math.max( dist, 100 ) ) --zoom
								vec_center.z = math.max( 5, vec_center.z ) --height
							end
						end
					end

				end

				local rate = FrameTime() * 100

				if pl.XRayTable.xray_zoom_time then
					if pl.XRayTable.xray_zoom_time >= CurTime() then
						rate = FrameTime() * 250
					else
						pl.XRayTable.xray_zoom_goal = 0
						pl.XRayTable.xray_zoom_time = nil
					end

				end

				pl.XRayTable.xray_zoom = math.Approach( pl.XRayTable.xray_zoom, pl.XRayTable.xray_zoom_goal, rate )

				vec_center.y = vec_center.y + pl.XRayTable.xray_zoom
			else
				pl.XRayTable = nil
			end
		end


		local pos, ang = arena:GetPos(), arena:GetAngles()

		local newpos, newang = LocalToWorld( vec_center, zero_ang, pos, ang )
		newang:RotateAroundAxis( arena:GetUp(), 90 )

		if not cur_viewpos or last_arena ~= arena then
			last_arena = arena
			cur_viewpos = newpos
		end

		cur_viewpos = LerpVector( FrameTime()*3, cur_viewpos, newpos )

		return { origin = newpos, angles = newang }

	end
end
hook.Add( "CalcView", "RagdollFightCalcView", RagdollFight.CalcView )

local hide_stuff = {
	CHudHealth = true,
	CHudBattery = true,
	CHudCrosshair = true,
}

hook.Add( "HUDShouldDraw", "RagdollFightHUDShouldDraw", function( name )
	local pl = LocalPlayer()
	if pl and pl.RagdollFightArena and pl.RagdollFightArena:IsValid() then
		if hide_stuff[ name ] then
			return false
		end
	end
end )

hook.Add( "HUDDrawTargetID", "RagdollFightHUDDrawTargetID", function( )
	local pl = LocalPlayer()
	if pl and pl.RagdollFightArena and pl.RagdollFightArena:IsValid() then return false end
end )


end

--todo: do something about making player go faster over time, so slide/jumpkick triggering will stop being so shit!
function RagdollFight.Move( pl, cmd )

	if pl.RagdollFightArena and pl.RagdollFightArena:IsValid() and pl:Alive() then
		local ang = pl.RagdollFightArena:GetAngles()
		ang:RotateAroundAxis( pl.RagdollFightArena:GetUp(), 90 )
		cmd:SetMoveAngles( ang )
		cmd:SetForwardSpeed( 0 )
		cmd:SetMaxSpeed( 200 )
		cmd:SetMaxClientSpeed( 200 )
	end

end
hook.Add( "Move", "RagdollFightMove", RagdollFight.Move )

hook.Add( "PlayerNoClip", "RagdollFightPlayerNoClip", function( pl )
	if pl and pl.RagdollFightArena and pl.RagdollFightArena:IsValid() then return false end
end )

--thats a scary hook, without CollisionRulesChanged
function RagdollFight.ShouldCollide( ent1, ent2 )
	if ent1:IsPlayer() and ent1.RagdollFightArena and ent1.RagdollFightArena:IsValid() and ent1:Alive() then
		local rag1 = ent1.RagdollFightArena:GetRagdollFighter( 1 )
		local rag2 = ent1.RagdollFightArena:GetRagdollFighter( 2 )
		if ent2 and ent2:IsValid() and ( ent2 == rag1 or ent2 == rag2 ) then
			return false
		end
	end
	if ent2:IsPlayer() and ent2.RagdollFightArena and ent2.RagdollFightArena:IsValid() and ent2:Alive() then
		local rag1 = ent2.RagdollFightArena:GetRagdollFighter( 1 )
		local rag2 = ent2.RagdollFightArena:GetRagdollFighter( 2 )
		if ent1 and ent1:IsValid() and ( ent1 == rag1 or ent1 == rag2 ) then
			return false
		end
	end
end
hook.Add( "ShouldCollide", "RagdollFightShouldCollide", RagdollFight.ShouldCollide )


--arena entity itself
--dont ask me why the hell I put it in there, instead of a separate file. I wont be able to come up with a reasonable answer

local ENT = {}

ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.PrintName = "Ragdoll Fight Arena"
ENT.Author = "Necrossin"
ENT.Information = "Lets you punch other players anywhere."
--ENT.Purpose = "Controls:\n\nAttack - Left mouse button + jumping/crouching/etc\nGrab - Hold right mouse button. Release +crouch/jump/etc to throw\n\nTo remove an arena - just undo it"
ENT.Category = "Fun + Games"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.MaxRounds = 3
ENT.StartingCharge = 33--0 --should probably make convars for these
ENT.ChargeMultiplier = 1.6--1.2

ENT.MessageBig = 1
ENT.MessageMed = 2
ENT.MessageSmall = 3

local arena_length = 48
local arena_width = 400
local arena_height = 200

--bottom
local box1_min = Vector( -arena_width/2, -arena_length/2, -7 )
local box1_max = Vector( arena_width/2, arena_length/2, -0.2 )

--top
local box2_min = Vector( -arena_width/2, -arena_length/2, 0 )
local box2_max = Vector( arena_width/2, arena_length/2, 2 )

local box2_offset = Vector( 0, 0, arena_height )

--wall
local box3_min = Vector( -arena_width/2, -1, 0 )
local box3_max = Vector( arena_width/2, 0, arena_height )

local box3_offset = Vector( 0, -arena_length/2, 0 )


--small walls
local box4_min = Vector( -3, -arena_length/2, 0 )
local box4_max = Vector( 0, arena_length/2, arena_height )

local box4_offset = Vector( -arena_width/2, 0, 0 )

local cam_offset = Vector( 0, -200, 75 )

local cam_points = {
	Vector( -arena_width/2, -arena_length/2, 0 ),
	Vector( arena_width/2, -arena_length/2, 0 ),
	Vector( -arena_width/2, -arena_length/2, arena_height ),
	Vector( arena_width/2, -arena_length/2, arena_height ),
}

local spawnpoints = {
	[1] = Vector( -arena_width/3, 0, 15 ),
	[2] = Vector( arena_width/3, 0, 15 ),
}

local player_styles = {
	"six fingers", "fart of dragon", "mingejitsu", "backup plan", "hi youtube", "molten core", "old and spicy", "that guy", "angry frenchman", "local man",
	"college ball", "butt breaker", "your mom", "deadly fedora", "nothing personnel", "i studied fist", "minecon punch", "facepunch", "timeroller",
	"i eat steroids", "drop 2k or die", "windows 10"
}

if CLIENT then
	function ENT:Initialize()
		HOOK_REF = HOOK_REF + 1
		ENABLE_HOOKS(true)
	end

	function ENT:OnRemove()

		HOOK_REF = HOOK_REF - 1
		if HOOK_REF == 0 then
			ENABLE_HOOKS(false)
		end
	end
end

if SERVER then

util.AddNetworkString( "RagdollFightArenaUpdatePlayer" )
util.AddNetworkString( "RagdollFightArenaRemovePlayer" )
util.AddNetworkString( "RagdollFightArenaSendMessage" )

	function ENT:SpawnFunction( pl, tr, classname )

		if ( !tr.Hit ) then return end

		local SpawnPos = tr.HitPos
		local SpawnAng = pl:EyeAngles()
		SpawnAng.p = 0

		SpawnAng = SpawnAng:Forward():Angle()

		local ent = ents.Create( classname )
		ent:SetPos( tr.HitPos )
		ent:SetAngles( SpawnAng )
		ent:Spawn()
		ent:Activate()

		return ent

	end

	function ENT:Initialize()
		self:SetModel( "models/dav0r/camera.mdl" )
		self:DrawShadow( false )

		self:PhysicsInitMultiConvex(
		{
			{
				Vector( box1_min.x, box1_min.y, box1_min.z ),
				Vector( box1_min.x, box1_min.y, box1_max.z ),
				Vector( box1_min.x, box1_max.y, box1_min.z ),
				Vector( box1_min.x, box1_max.y, box1_max.z ),
				Vector( box1_max.x, box1_min.y, box1_min.z ),
				Vector( box1_max.x, box1_min.y, box1_max.z ),
				Vector( box1_max.x, box1_max.y, box1_min.z ),
				Vector( box1_max.x, box1_max.y, box1_max.z ),
			},
			{
				Vector( box2_min.x, box2_min.y, box2_min.z ) + box2_offset,
				Vector( box2_min.x, box2_min.y, box2_max.z ) + box2_offset,
				Vector( box2_min.x, box2_max.y, box2_min.z ) + box2_offset,
				Vector( box2_min.x, box2_max.y, box2_max.z ) + box2_offset,
				Vector( box2_max.x, box2_min.y, box2_min.z ) + box2_offset,
				Vector( box2_max.x, box2_min.y, box2_max.z ) + box2_offset,
				Vector( box2_max.x, box2_max.y, box2_min.z ) + box2_offset,
				Vector( box2_max.x, box2_max.y, box2_max.z ) + box2_offset,
			},
			{
				Vector( box3_min.x, box3_min.y, box3_min.z ) + box3_offset,
				Vector( box3_min.x, box3_min.y, box3_max.z ) + box3_offset,
				Vector( box3_min.x, box3_max.y, box3_min.z ) + box3_offset,
				Vector( box3_min.x, box3_max.y, box3_max.z ) + box3_offset,
				Vector( box3_max.x, box3_min.y, box3_min.z ) + box3_offset,
				Vector( box3_max.x, box3_min.y, box3_max.z ) + box3_offset,
				Vector( box3_max.x, box3_max.y, box3_min.z ) + box3_offset,
				Vector( box3_max.x, box3_max.y, box3_max.z ) + box3_offset,
			},
			{
				Vector( box3_min.x, box3_min.y, box3_min.z ) - box3_offset,
				Vector( box3_min.x, box3_min.y, box3_max.z ) - box3_offset,
				Vector( box3_min.x, box3_max.y, box3_min.z ) - box3_offset,
				Vector( box3_min.x, box3_max.y, box3_max.z ) - box3_offset,
				Vector( box3_max.x, box3_min.y, box3_min.z ) - box3_offset,
				Vector( box3_max.x, box3_min.y, box3_max.z ) - box3_offset,
				Vector( box3_max.x, box3_max.y, box3_min.z ) - box3_offset,
				Vector( box3_max.x, box3_max.y, box3_max.z ) - box3_offset,
			},
			{
				Vector( box4_min.x, box4_min.y, box4_min.z ) + box4_offset,
				Vector( box4_min.x, box4_min.y, box4_max.z ) + box4_offset,
				Vector( box4_min.x, box4_max.y, box4_min.z ) + box4_offset,
				Vector( box4_min.x, box4_max.y, box4_max.z ) + box4_offset,
				Vector( box4_max.x, box4_min.y, box4_min.z ) + box4_offset,
				Vector( box4_max.x, box4_min.y, box4_max.z ) + box4_offset,
				Vector( box4_max.x, box3_max.y, box4_min.z ) + box4_offset,
				Vector( box4_max.x, box4_max.y, box4_max.z ) + box4_offset,
			},
			{
				Vector( box4_min.x, box4_min.y, box4_min.z ) - box4_offset,
				Vector( box4_min.x, box4_min.y, box4_max.z ) - box4_offset,
				Vector( box4_min.x, box4_max.y, box4_min.z ) - box4_offset,
				Vector( box4_min.x, box4_max.y, box4_max.z ) - box4_offset,
				Vector( box4_max.x, box4_min.y, box4_min.z ) - box4_offset,
				Vector( box4_max.x, box4_min.y, box4_max.z ) - box4_offset,
				Vector( box4_max.x, box3_max.y, box4_min.z ) - box4_offset,
				Vector( box4_max.x, box4_max.y, box4_max.z ) - box4_offset,
			},


		} )
		self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
		self:SetSolid( SOLID_VPHYSICS  )
		self:SetMoveType( MOVETYPE_VPHYSICS  )

		self:EnableCustomCollisions( true )

		self:PhysWake()

		self:SetUseType( SIMPLE_USE )

		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:EnableMotion( false )
		end

		self:SetRound( 1 )

		local ang = self:GetAngles()
		ang.p = 0

		self:SetDirVector( 1, ang:Forward() )

		ang:RotateAroundAxis( self:GetUp(), 180 )
		self:SetDirVector( 2, ang:Forward() )

		self.IsArena = true

		--just to be sure
		constraint.Weld( self, game.GetWorld(), 0, 0, 0, false, false )

		HOOK_REF = HOOK_REF + 1
		ENABLE_HOOKS(true)
	end

	function ENT:Use( activator, caller, useType, value )

		if activator and activator:IsPlayer() and activator:Alive() and self:GetPlayerNum() < 2 and !IsValid( activator.RagdollFightArena ) then

			local bot = player.GetBots()[1]

			local free_slot = 1

			for i=1, 2 do
				if !IsValid( self:GetPlayer( i ) ) then
					free_slot = i
					break
				end
			end

			--debug stuff
			/*if bot and self:GetPlayerNum() < 1 then
				self:AddPlayer( free_slot, bot )
				return
			end*/

			self:AddPlayer( free_slot, activator )
		end

	end

	function ENT:OnRemove()

		self.Removing = true

		if IsValid( self:GetPlayer( 1 ) ) then
			self:RemovePlayer( 1 )
		end
		if IsValid( self:GetPlayer( 2 ) ) then
			self:RemovePlayer( 2 )
		end

		HOOK_REF = HOOK_REF - 1
		if HOOK_REF == 0 then
			ENABLE_HOOKS(false)
		end
	end

	function ENT:SendMessage( txt, dur, t )

		for i=1, 2 do
			local pl = self:GetPlayer( i )

			if pl and pl:IsValid() then

				net.Start( "RagdollFightArenaSendMessage" )
					net.WriteInt( t, 32 )
					net.WriteFloat( dur )
					net.WriteString( txt )
				net.Send( pl )

			end
		end

	end

	function ENT:AddPlayer( slot, ent )

		--remove noclip
		ent:SetMoveType( MOVETYPE_WALK )

		if ent:FlashlightIsOn() then
			ent:Flashlight( false )
		end

		slot = math.Clamp( slot, 1, 2 )
		self:SetDTEntity( slot, ent )

		ent.RagdollFightArena = self
		ent.RagdollFightArenaSlot = slot
		net.Start( "RagdollFightArenaUpdatePlayer" )
			net.WriteEntity( self )
			net.WriteInt( slot, 32 )
		net.Send( ent )

		self:SetSpawnPos( slot, ent )
		RagdollFight.RemoveRagdoll( ent )
		RagdollFight.SpawnRagdoll( ent )

		self:AddRagdollFighter( slot, ent )
		self:ClearPos( ent )

		self:SetPlayerHealth( slot, 100 )
		self:SetCharge( slot, self.StartingCharge )
		self:SetPlayerText( slot, player_styles[ math.random( 1, #player_styles ) ] )

		for i=1, 2 do
			if IsValid( self:GetPlayer( i ) ) and i ~= slot then
				self:SetSpawnPos( i, self:GetPlayer( i ) )
			end
		end

		if self:GetPlayerNum() >= 2 then
			self:SendMessage( "ROUND "..self:GetRound(), 1.5, self.MessageBig )
			self:SendMessage( "FIGHT", 1.5, self.MessageBig )
		end

	end

	function ENT:RemovePlayer( slot )
		slot = math.Clamp( slot, 1, 2 )

		local pl = self:GetPlayer( slot )

		if pl and pl:IsValid() then
			RagdollFight.RemoveRagdoll( pl )
			pl:SetMoveType( MOVETYPE_WALK )
			pl:SetCollisionGroup( COLLISION_GROUP_PLAYER )
			if pl.OldJumpPower then
				pl:SetJumpPower( pl.OldJumpPower )
			end
			pl.RagdollFightArena = nil
			pl.RagdollFightArenaSlot = nil
			net.Start( "RagdollFightArenaRemovePlayer" )
			net.Send( pl )
			if pl:Alive() and not self.Removing then
				pl:SetPos( self:GetPos() + self:GetRight() * 200 )
			end
		end

		if not self.Removing then
			self:SetCharge( slot, self.StartingCharge )
			self:SetPlayerHealth( slot, 100 )
			self:SetDTEntity( slot, NULL )
		end

	end

	function ENT:SetSpawnPos( slot, pl )
		local pos = spawnpoints[ slot ]

		if pos then
			local new_pos = LocalToWorld( pos, Angle( 0, 0, 0 ) , self:GetPos(), self:GetAngles() )
			pl:SetPos( new_pos )
		end

	end

	--lets make sure players wont get stuck in each other
	function ENT:ClearPos( ent1, pos )

		local pl1 = self:GetPlayer( 1 )
		local pl2 = self:GetPlayer( 2 )

		local ent2 = ent1 == pl1 and pl2 or pl1
		local slot1 = ent1 == pl1 and 1 or 2
		local slot2 = slot1 == 1 and 2 or 1

		if ent1:IsValid() and ent2:IsValid() then

			pos = pos or ent1:GetPos()
			local pos2 = ent2:GetPos()

			local c_pos = Vector( pos.x, pos.y, 0 )
			local c_pos2 = Vector( pos2.x, pos2.y, 0 )

			local dist = c_pos:Distance( c_pos2 )

			if dist < 60 then

				local new_pos = pos + self:GetDirVector( slot1 ) * 65

				new_pos = self:ConvertIntoSafePos( new_pos )

				c_pos2 = Vector( new_pos.x, new_pos.y, 0 )

				local dist2 = c_pos:Distance( c_pos2 )


				if dist2 < 60 then

					new_pos = pos + self:GetDirVector( slot2 ) * 65

					new_pos = self:ConvertIntoSafePos( new_pos )

				end

				ent2:SetPos( new_pos )

			end


		end

	end

	--prevents player from getting stuck inside the arena itself (or outside)
	function ENT:ConvertIntoSafePos( pos )

		local pos_loc = self:WorldToLocal( pos )

		pos_loc.x = math.Clamp( pos_loc.x, -176, 176 )
		pos_loc.y = 0
		pos_loc.z = 15

		local fixed_pos = self:LocalToWorld( pos_loc )

		return fixed_pos, pos_loc

	end

	function ENT:AddRagdollFighter( slot, pl )

		slot = math.Clamp( slot + 2, 3, 4 )
		self:SetDTEntity( slot, pl.Ragdoll )

	end

	function ENT:SetPlayerHealth( slot, am )

		local rag = self:GetRagdollFighter( slot )

		slot = math.Clamp( slot, 1, 2 )
		if rag and rag:IsValid() then
			self:SetDTInt( slot, math.Clamp( am or 100, 0, 100 ) )

			if self.ResettingRound then return end

			if self:GetPlayerHealth( slot ) <= 0 then

				self.ResettingRound = true

				local enemy_slot = slot == 1 and 2 or 1

				self:SetPlayerScore( enemy_slot, self:GetPlayerScore( enemy_slot ) + 1 )

				if self:GetRound() == 2 and ( self:GetPlayerScore( 1 ) >= 2 or self:GetPlayerScore( 2 ) >= 2 ) or self:GetRound() == 3 then
					local winner = self:GetPlayerScore( enemy_slot ) >= 2 and enemy_slot == 1 and 1 or 2

					local winner_pl = self:GetPlayer( winner )

					if winner_pl and winner_pl:IsValid() then
						self:SendMessage( string.upper( winner_pl:Nick() ).." WON THE MATCH!", 3, self.MessageSmall )
					end

					timer.Simple( 5, function() if IsValid( self.Entity ) then self:ResetRound( true ) end end )
				else

					local winner_pl = self:GetPlayer( enemy_slot )

					if winner_pl and winner_pl:IsValid() then
						self:SendMessage( string.upper( winner_pl:Nick() ).." WINS!", 3, self.MessageMed )
					end

					timer.Simple( 5, function() if IsValid( self.Entity ) then self:ResetRound() end end )
				end


			end

		end

	end

	function ENT:Think()

		local reset = false

		local pl1 = self:GetPlayer( 1 )
		local pl2 = self:GetPlayer( 2 )

		if pl1 and pl1:IsValid() and !pl1:Alive() then
			self:RemovePlayer( 1 )
			reset = true
		end

		if pl2 and pl2:IsValid() and !pl2:Alive() then
			self:RemovePlayer( 2 )
			reset = true
		end

		if reset then
			self:ResetRound( true )
		end

	end


	function ENT:SetPlayerScore( slot, am )
		slot = math.Clamp( slot + 2, 3, 4 )
		self:SetDTInt( slot, math.Clamp( am or 0, 0, self.MaxRounds ) )
	end

	function ENT:SetCharge( slot, am )
		slot = math.Clamp( slot + 4, 5, 6 )
		self:SetDTInt( slot, math.Clamp( am or 0, 0, 99 ) )
	end

	function ENT:SetPlayerText( slot, txt )
		txt = string.upper( txt )
		slot = math.Clamp( slot, 1, 2 )
		self:SetDTString( slot, txt )
	end

	function ENT:PlayerTakeDamage( slot, am )
		self:SetPlayerHealth( slot, self:GetPlayerHealth( slot ) - am )
		self:SetCharge( slot, self:GetCharge( slot ) + math.floor( am * self.ChargeMultiplier ) )
	end

	function ENT:SetDirVector( slot, vec )
		vec = vec:GetNormal()
		slot = math.Clamp( slot, 1, 2 )
		self:SetDTVector( slot, vec )
	end

	function ENT:SetRound( am )
		self:SetDTInt( 7, am or 1 )
	end

	function ENT:ResetRound( full )

		self.ResettingRound = false

		for i=1, 2 do
			local pl = self:GetPlayer( i )

			if pl and pl:IsValid() then
				self:SetSpawnPos( i, pl )
				self:ClearPos( pl )
				self:SetPlayerHealth( i, 100 )
				if full then
					self:SetPlayerScore( i, 0 )
					self:SetPlayerText( i, player_styles[ math.random( 1, #player_styles ) ] )
					self:SetCharge( i, self.StartingCharge )
				end
			end

		end

		if full then
			self:SetRound( 1 )
			if self:GetPlayerNum() >= 2 then
				self:SendMessage( "ROUND "..self:GetRound(), 1.5, self.MessageBig )
				self:SendMessage( "FIGHT", 1.5, self.MessageBig )
			end
		else
			self:SetRound( self:GetRound() + 1 )
			if self:GetPlayerNum() >= 2 then
				self:SendMessage( "ROUND "..self:GetRound(), 1.5, self.MessageBig )
				self:SendMessage( "FIGHT", 1.5, self.MessageBig )
			end
		end
	end



else

	function ENT:DrawBlur()

		local pl = LocalPlayer()
		local ang = self:GetAngles()

		self.Alpha = self.Alpha or 0
		self.GoalAlpha = self.GoalAlpha or 0

		if pl.XRayTable and pl.XRayTable.xray_time and pl.XRayTable.xray_time > CurTime() and pl.RagdollFightArena and pl.RagdollFightArena == self then
			self.GoalAlpha = 230
		else
			self.GoalAlpha = 0
		end

		self.Alpha = math.Approach( self.Alpha, self.GoalAlpha, FrameTime() * 300 )

		if self.Alpha > 0 then

			cam.Start3D2D( self:GetPos() + vector_up - self:GetRight() * 20,ang, 1)
				surface.SetDrawColor( 10, 10, 10, self.Alpha )
				surface.DrawRect( - ScrW(), 0, ScrW()*2, ScrH() )
			cam.End3D2D()

			ang:RotateAroundAxis( self:GetForward(), 90 )

			cam.Start3D2D( self:LocalToWorld( self:OBBCenter() ) - self:GetRight() * 22,ang, 1)
				surface.SetDrawColor( 10, 10, 10, self.Alpha )
				surface.DrawRect( - ScrW(), - ScrH() / 2, ScrW()*2, ScrH() )
			cam.End3D2D()
		end


	end

	local wireframe = Material( "models/wireframe" )
	local wire_col = Color( 200, 200, 255, 255 )

	function ENT:Draw()

		self:SetRenderBounds( Vector( -400, -400, 0 ), Vector( 400, 400, 200 ) )

		local pos, ang = self:GetPos(), self:GetAngles()

		local rag1 = self:GetRagdollFighter( 1 )
		local rag2 = self:GetRagdollFighter( 2 )

		if rag1 and rag1:IsValid() and not rag1.GetPlayerColor then
			rag1.GetPlayerColor = function( s )
				local owner = s:GetOwner()
				if owner and owner:IsValid() then
					local col = owner:GetPlayerColor()
					return Vector( col.x, col.y, col. z )
				end
				return Vector( 1, 1, 1 )
			end
		end

		if rag2 and rag2:IsValid() and not rag2.GetPlayerColor then
			rag2.GetPlayerColor = function( s )
				local owner = s:GetOwner()
				if owner and owner:IsValid() then
					local col = owner:GetPlayerColor()
					return Vector( col.x, col.y, col. z )
				end
				return Vector( 1, 1, 1 )
			end
		end

		if IsValid( LocalPlayer().RagdollFightArena ) then
			self:DrawBlur()
		end

		if self:GetPlayerNum() < 2 and !IsValid( LocalPlayer().RagdollFightArena ) then

			render.DrawWireframeBox( pos, ang, box1_min, box1_max, wire_col )
			render.DrawWireframeBox( pos, ang, box2_min + box2_offset, box2_max + box2_offset, wire_col )
			render.DrawWireframeBox( pos, ang, box3_min + box3_offset, box3_max + box3_offset, wire_col )
			render.DrawWireframeBox( pos, ang, box3_min - box3_offset, box3_max - box3_offset, wire_col )
			render.DrawWireframeBox( pos, ang, box4_min + box4_offset, box4_max + box4_offset, wire_col )
			render.DrawWireframeBox( pos, ang, box4_min - box4_offset, box4_max - box4_offset, wire_col )

			local pos = self:GetPos()
			local ang = self:GetAngles()

			local cam_pos, cam_ang = LocalToWorld( cam_offset, Angle( 0, 90, 0 ), pos, ang )

			self:SetRenderOrigin( cam_pos )
			self:SetRenderAngles( cam_ang )

			render.SetColorModulation( wire_col.r / 255, wire_col.g / 255, wire_col.b / 255 )
				render.ModelMaterialOverride( wireframe )
				self:DrawModel()
				render.ModelMaterialOverride( )
			render.SetColorModulation( 1, 1, 1 )

			self:SetRenderOrigin( )
			self:SetRenderAngles( )

			for i = 1, 4 do
				local vec = cam_points[ i ]
				if vec then
					local vec_pos, vec_ang = LocalToWorld( vec, Angle( 0, 0, 0 ), pos, ang )
					render.DrawLine( cam_pos, vec_pos, wire_col, false )
				end
			end

			local eyeang = EyeAngles()
			eyeang:RotateAroundAxis( eyeang:Right(), 90 )
			eyeang:RotateAroundAxis( eyeang:Up(), -90 )

			cam.Start3D2D( self:GetPos() + vector_up * 72, eyeang, 0.3)
				draw.DrawText( "Press "..string.upper( input.LookupBinding( "+use", true ) ).." to join", "RagdollFightDefault", 0, 0, wire_col, TEXT_ALIGN_CENTER )
				draw.DrawText( "To exit arena, just undo it or suicide", "RagdollFightDefault", 0, 25, wire_col, TEXT_ALIGN_CENTER )
			cam.End3D2D()

		end

	end

	local grad = surface.GetTextureID( "gui/gradient" )
	local white_bar = Color( 255, 255, 255, 220 )

	local RF_DRAW_HUD = util.tobool( CreateClientConVar("cl_rf_drawhud", 1, true, false, "Enable or disable UI in Ragdoll Fight."):GetInt() )
	cvars.AddChangeCallback("cl_rf_drawhud", function(cvar, oldvalue, newvalue)
		RF_DRAW_HUD = util.tobool( newvalue )
	end)

	--I'm gonna play it safe and have all HUD inside this panel, without worrrying about 400+ other HUD addons that players might have installed
function RagdollFight.HUD()

		local pl = LocalPlayer()

		local base = vgui.Create( "DPanel" )
		base:SetPos( 0, 0 )
		base:SetSize( ScrW(), ScrH() )
		base:SetMouseInputEnabled( false )
		base:SetKeyboardInputEnabled( false )
		base.Arena = pl.RagdollFightArena
		base.ShowHints = true

		base.Messages = {}

		pl.RagdollFightArenaHUD = base

		local bind_to_button = function( bind )
			local txt = input.LookupBinding( bind, true )
			if txt then
				return string.upper( txt )
			end
			return ""
		end

		base.HintText = {}

		base.HintText[ 1 ] = { txt = bind_to_button( "+attack" ).." - attack (also try jumping/crouching)", keys = { IN_ATTACK } }
		base.HintText[ 2 ] = { txt = bind_to_button( "+attack2" ).." - hold to grab. Release to throw", keys = { IN_ATTACK2 } }
		base.HintText[ 3 ] = { txt = bind_to_button( "+reload" ).." - hold to block", keys = { IN_RELOAD } }
		base.HintText[ 4 ] = { txt = "" }
		base.HintText[ 5 ] = { txt = bind_to_button( "+attack" ).." + "..bind_to_button( "+jump" ).." - jump kick", keys = { IN_ATTACK, IN_JUMP } }
		base.HintText[ 6 ] = { txt = bind_to_button( "+attack" ).." + "..bind_to_button( "+duck" ).." when moving - slide attack", keys = { IN_ATTACK, IN_DUCK } }
		base.HintText[ 7 ] = { txt = bind_to_button( "+forward" ).." + "..bind_to_button( "+attack" ).." + "..bind_to_button( "+jump" ).." when moving - heavy jump kick", keys = { IN_ATTACK, IN_FORWARD, IN_JUMP } }
		base.HintText[ 8 ] = { txt = "" }
		base.HintText[ 9 ] = { txt = bind_to_button( "+walk" ).." - fix your spine or playermodel", keys = { IN_WALK } }
		base.HintText[ 10 ] = { txt = bind_to_button( "+showscores" ).." - toggle hints" }
		base.HintText[ 11 ] = { txt = "" }
		base.HintText[ 12 ] = { txt = "To disable/enable UI - type cl_rf_drawhud 0 or 1 in console" }
		base.HintText[ 13 ] = { txt = "" }
		base.HintText[ 14 ] = { txt = "Now try to explain this to the second player" }

		base.AddMessage = function( self, txt, dur, t )

			if not RF_DRAW_HUD then return end

			local msg = {}

			msg.text = txt
			--msg.time = CurTime()
			msg.dur = dur
			msg.t = t

			table.insert( self.Messages, msg )

		end

		base.PaintTriangle = function( self, x, y, size, id )

			if not self.Triangles then
				self.Triangles = {}
			end

			if not self.Triangles[ id ] then
				self.Triangles[ id ] = {
					{ x = x - size/2, y = y },
					{ x = x + size/2, y = y },
					{ x = x, y = y + size }
				}
			end

			surface.DrawPoly( self.Triangles[ id ] )--

		end

		base.PaintCircle = function( self, x, y, radius, seg, id )

			if not self.Circles then
				self.Circles = {}
			end

			if not self.Circles[ id ] then
				self.Circles[ id ] = {}

				table.insert( self.Circles[ id ], { x = x, y = y, u = 0.5, v = 0.5 } )
				for i = 0, seg do
					local a = math.rad( ( i / seg ) * -360 )
					table.insert( self.Circles[ id ], { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
				end

				local a = math.rad( 0 )
				table.insert( self.Circles[ id ], { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

			end


			surface.DrawPoly( self.Circles[ id ] )
		end

		base.PaintChargeBar = function( self, x, y, w, h, shift, scale )

			shift = shift or 5

			local poly = {
				{ x = x + shift, y = y - h * ( scale - 1 ) / 2 }, { x = x + shift + w, y = y - h * ( scale - 1 ) / 2 },
				{ x = x + w, y = y + h + h * ( scale - 1 ) / 2 },{ x = x, y = y + h + h * ( scale - 1 ) / 2 }
			}
			draw.NoTexture()
			surface.DrawPoly( poly )

		end

		base.Paint = function( self, pw, ph )

			local pl = LocalPlayer()
			local arena = pl.RagdollFightArena
			local my_slot = pl.RagdollFightArenaSlot

			if not RF_DRAW_HUD then return end

			if pl and arena and arena:IsValid() and my_slot then

				local slot1 = my_slot
				local slot2 = my_slot == 1 and 2 or 1

				self.Arena = arena

				--top

				local w, h = pw/2.3, 15
				local x, y = pw/4 - w/2, 30

				--all this, because I was too lazy to make a texture instead

				render.ClearStencil()
				render.SetStencilEnable( true )

				render.SetStencilWriteMask( 1 )
				render.SetStencilTestMask( 1 )

				render.SetStencilFailOperation( STENCIL_REPLACE )
				render.SetStencilPassOperation( STENCIL_ZERO )
				render.SetStencilZFailOperation( STENCIL_ZERO )
				render.SetStencilCompareFunction( STENCIL_NEVER )
				render.SetStencilReferenceValue( 1 )


				surface.SetDrawColor( Color( 0, 0, 0, 255 ) )

				local rad1 = ( pw/2 - w + 22 ) / 2
				local rad2 = pw/22.2--72--( pw/2 - w + 22 ) / 2

				self:PaintCircle( pw/2, y + h + 15, rad1, 35, 1 )

				draw.RoundedBox( 0, x, y + h, w - rad2 * 0.7, 20, Color( 0, 0, 0, 255 ) )
				draw.RoundedBox( 0, 3*pw/4 - w/2 + rad2 * 0.7, y + h, w - rad2 * 0.7, 20, Color( 0, 0, 0, 255 ) )

				surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
				self:PaintCircle( x + w - rad2 * 0.7, y + h + rad2, rad2, 40, 2 )
				self:PaintCircle( 3*pw/4 - w/2 + rad2 * 0.7, y + h + rad2, rad2, 40, 3 )

				render.SetStencilFailOperation( STENCIL_ZERO )
				render.SetStencilPassOperation( STENCIL_REPLACE )
				render.SetStencilZFailOperation( STENCIL_ZERO )
				render.SetStencilCompareFunction( STENCIL_EQUAL )

				--render.SetStencilReferenceValue( 2 )

				render.SetStencilEnable( false )

				local pl1 = arena:GetPlayer( slot1 )

				if pl1 and pl1:IsValid() then

					local hp = arena:GetPlayerHealth( slot1 )
					self.LastHP1 = self.LastHP1 or hp
					self.LastChangedHP1 = self.LastChangedHP1 or hp
					self.LastHP1Fade = self.LastHP1Fade or 0
					self.FlashTime1 = self.FlashTime1 or 0

					if self.LastHP1 ~= hp and ( not self.LastHP1Changed or self.LastChangedHP1 ~= hp ) then
						self.LastHP1Changed = true
						self.LastChangedHP1 = hp
						self.LastHP1Fade = CurTime() + 1
						self.FlashTime1 = CurTime() + 0.07
					end

					render.SetStencilEnable( true )
					render.SetStencilReferenceValue( 2 )

					if ( self.LastHP1Fade + 1 ) > CurTime() and hp  ~= 100 then
						local delta2 = math.Clamp( ( ( self.LastHP1Fade + 1 ) - CurTime() ) / 1.3 , 0, 1 )
						surface.SetDrawColor( Color( 215 - 120 * ( 1 - delta2 ), 15, 15, 220 * delta2 ) )
						render.SetScissorRect( x + w * ( 1 - self.LastHP1/100 ), y, x + w * ( 1 - hp/100 ), y + h + 20, true )
						surface.DrawRect( x, y, w, h + 20 )
							surface.SetDrawColor( Color( 0, 0, 0, 200 * delta2  ) )
							draw.NoTexture()
							self:PaintTriangle( x + w/2, y, 6, 1 )
							self:PaintTriangle( x + 3*w/4, y, 6, 2 )
							self:PaintTriangle( x + w * 0.9, y, 6, 3 )
							self:PaintTriangle( x + w * 0.92, y, 6, 4 )
							self:PaintTriangle( x + w * 0.94, y, 6, 5 )
							self:PaintTriangle( x + w * 0.96, y, 6, 6 )
							self:PaintTriangle( x + w * 0.98, y, 6, 7 )
						render.SetScissorRect( 0, 0, 0, 0, false )
					else
						if self.LastHP1Changed then
							self.LastHP1Changed = false
							self.LastChangedHP1 = hp
							self.LastHP1 = hp
						end
					end

					local delta = math.Clamp( hp/100, 0, 1 )

					white_bar.r = 255
					white_bar.g = 255
					white_bar.b = 255

					if self.FlashTime1 > CurTime() then

						local new_col = 170--math.sin( RealTime() * 15 ) * 35 + 220

						white_bar.r = new_col
						white_bar.g = new_col
						white_bar.b = new_col

					end


					surface.SetDrawColor( white_bar )
					render.SetScissorRect( x + w * ( 1 - delta ), y, x + w, y + h + 20, true )
					surface.DrawRect( x, y, w, h + 20 )

					surface.SetTexture( grad )
					surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
					surface.DrawTexturedRectRotated( x + w/4, y + h/2, w / 2 + 2, h + 2, 0 )
					surface.SetDrawColor( Color( 0, 0, 0, 250 ) )
					draw.NoTexture()
					self:PaintTriangle( x + w/2, y, 6, 8 )
					self:PaintTriangle( x + 3*w/4, y, 6, 9 )
					self:PaintTriangle( x + w * 0.9, y, 6, 10 )
					self:PaintTriangle( x + w * 0.92, y, 6, 11 )
					self:PaintTriangle( x + w * 0.94, y, 6, 12 )
					self:PaintTriangle( x + w * 0.96, y, 6, 13 )
					self:PaintTriangle( x + w * 0.98, y, 6, 14 )
					render.SetScissorRect( 0, 0, 0, 0, false )

					render.SetStencilEnable( false )

					--render.SetStencilReferenceValue( 2 )

					if hp < 100 and hp ~= 0 then
						local extra = hp <= 6 and hp > 2 and ( 1 - hp/6 ) * 15 or 0
						surface.SetDrawColor( Color( 255, 255, 255, 230 ) )
						surface.DrawRect( x + w * ( 1 - delta ), y, 1, h + extra )
						surface.SetDrawColor( Color( 255, 255, 255, 100 ) )
						surface.DrawRect( x + w * ( 1 - delta )- 1, y - 3, 1, h+5+extra )
					end

					local style = arena:GetPlayerText( slot1 )
					draw.SimpleText( style or "", "RagdollFightDefault", x, y + h + 15, Color( 255, 255, 255, 220 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
					draw.SimpleText( string.upper( pl1:Nick() or "" ), "RagdollFightDefaultTitle", x, y + h + 40, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

				end

				x, y = 3*pw/4 - w/2, y

				--render.SetStencilReferenceValue( 1 )

				local pl2 = arena:GetPlayer( slot2 )

				if pl2 and pl2:IsValid() then

					local hp = arena:GetPlayerHealth( slot2 )
					self.LastHP2 = self.LastHP2 or hp
					self.LastChangedHP2 = self.LastChangedHP2 or hp
					self.LastHP2Fade = self.LastHP2Fade or 0
					self.FlashTime2 = self.FlashTime2 or 0

					if self.LastHP2 ~= hp and ( not self.LastHP2Changed or self.LastChangedHP2 ~= hp ) then
						self.LastHP2Changed = true
						self.LastChangedHP2 = hp
						self.LastHP2Fade = CurTime() + 1
						self.FlashTime2 = CurTime() + 0.07
					end

					render.SetStencilEnable( true )
					render.SetStencilReferenceValue( 2 )

					if ( self.LastHP2Fade + 1 ) > CurTime() and hp~= 100 then
						local delta2 = math.Clamp( ( ( self.LastHP2Fade + 1 ) - CurTime() ) / 1.3 , 0, 1 )
						surface.SetDrawColor( Color( 215 - 120 * ( 1 - delta2 ), 15, 15, 220 * delta2 ) )
						render.SetScissorRect( x + w * hp/100, y, x + w * self.LastHP2/100, y + h + 20, true )
						surface.DrawRect( x, y, w, h + 20 )
							surface.SetDrawColor( Color( 0, 0, 0, 200 * delta2 ) )
							draw.NoTexture()
							self:PaintTriangle( x + w/2, y, 6, 15 )
							self:PaintTriangle( x + w/4, y, 6, 16 )
							self:PaintTriangle( x + w * 0.1, y, 6, 17 )
							self:PaintTriangle( x + w * 0.08, y, 6, 18 )
							self:PaintTriangle( x + w * 0.06, y, 6, 19 )
							self:PaintTriangle( x + w * 0.04, y, 6, 20 )
							self:PaintTriangle( x + w * 0.02, y, 6, 21 )
						render.SetScissorRect( 0, 0, 0, 0, false )
					else
						if self.LastHP2Changed then
							self.LastHP2Changed = false
							self.LastChangedHP2 = hp
							self.LastHP2 = hp
						end
					end

					local delta = math.Clamp( hp/100, 0, 1 )

					white_bar.r = 255
					white_bar.g = 255
					white_bar.b = 255

					if self.FlashTime2 > CurTime() then

						local new_col = 170

						white_bar.r = new_col
						white_bar.g = new_col
						white_bar.b = new_col

					end

					surface.SetDrawColor( white_bar )
					render.SetScissorRect( x, y, x + w * delta, y + h + 20, true )
					surface.DrawRect( x, y, w, h + 20 )
					surface.SetTexture( grad )
					surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
					surface.DrawTexturedRectRotated( x + 3*w/4, y + h/2, w/2 + 2, h + 2, 180 )
					surface.SetDrawColor( Color( 0, 0, 0, 250 ) )
					draw.NoTexture()
					self:PaintTriangle( x + w/2, y, 6, 22 )
					self:PaintTriangle( x + w/4, y, 6, 23 )
					self:PaintTriangle( x + w * 0.1, y, 6, 24 )
					self:PaintTriangle( x + w * 0.08, y, 6, 25 )
					self:PaintTriangle( x + w * 0.06, y, 6, 26 )
					self:PaintTriangle( x + w * 0.04, y, 6, 27 )
					self:PaintTriangle( x + w * 0.02, y, 6, 28 )
					render.SetScissorRect( 0, 0, 0, 0, false )

					render.SetStencilEnable( false )


					if hp < 100 and hp ~= 0 then
						surface.SetDrawColor( Color( 255, 255, 255, 230 ) )
						surface.DrawRect( x + w * delta - 1, y, 1, h )
						surface.SetDrawColor( Color( 255, 255, 255, 100 ) )
						surface.DrawRect( x + w * delta, y - 3, 1, h+5 )
					end



					local style = arena:GetPlayerText( slot2 )
					draw.SimpleText( style or "", "RagdollFightDefault", x + w, y + h + 15, Color( 255, 255, 255, 220 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
					draw.SimpleText( string.upper( pl2:Nick() or "" ), "RagdollFightDefaultTitle", x + w, y + h + 40, Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

				end

				x, y = pw/2, y + h/2

				draw.SimpleText( arena:GetRound(), "RagdollFightRoundNumber", x, y + 10, Color( 255, 255, 255, 220 ),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )


				--bottom

				local gap = 20
				local gap2 = pw/4 - w/2

				local name1, hint1 = "ESCAPE GRAB", "PRESS ["..string.upper( input.LookupBinding( "+use", true ) ).."]"
				local name2, hint2 = "HORSE LEGS", "JUMPKICK / SLIDE"
				local name3, hint3 = "X-RAY", "GRAB + ATTACK"

				w, h = pw/4 / 3, 7
				x, y = gap2 + 5, ph - 30 - h

				if pl1 and pl1:IsValid() then

					white_bar.r = 255
					white_bar.g = 255
					white_bar.b = 255

					surface.SetDrawColor( Color( 0, 0, 0, 120 ) )
					draw.NoTexture()
					if !arena:IsChargeReady( slot1, 1 ) then
						self:PaintChargeBar( x, y, w, h, -5, 1 )
					end
					if !arena:IsChargeReady( slot1, 2 ) then
						self:PaintChargeBar( x + w + gap, y, w, h, -5, 1 )
					end
					if !arena:IsChargeReady( slot1, 3 ) then
						self:PaintChargeBar( x + w * 2 + gap * 2, y, w, h, -5, 1 )
					end

					local rate = RealTime() * 0.8
					local sin = math.sin( rate )
					local cos = math.cos( rate )

					if arena:IsChargeReady( slot1, 1 ) then
						draw.SimpleText( sin > 0 and name1 or hint1, "RagdollFightChargeDesc", x + w/2 - 5, y - h - 10, Color( 255, 255, 255, math.abs( sin * 220 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					if arena:IsChargeReady( slot1, 2 ) then
						draw.SimpleText( sin > 0 and name2 or hint2, "RagdollFightChargeDesc", x + w + gap + w/2 - 5, y - h - 10, Color( 255, 255, 255, math.abs( sin * 220 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					if arena:IsChargeReady( slot1, 3 ) then
						draw.SimpleText( sin > 0 and name3 or hint3, "RagdollFightChargeDesc", x + w * 2 + gap * 2 + w/2 - 5, y - h - 10, Color( 255, 255, 255, math.abs( sin * 220 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					local col_flash = Color( 255, 255, 255, 220 + math.abs( cos * 35 ) )

					surface.SetDrawColor( arena:IsChargeReady( slot1, 1 ) and col_flash or white_bar )
					self:PaintChargeBar( x, y, w * arena:GetChargeStatus( slot1, 1 ), h, -5, arena:IsChargeReady( slot1, 1 ) and 2 or 1 )
					surface.SetDrawColor( arena:IsChargeReady( slot1, 2 ) and col_flash or white_bar )
					self:PaintChargeBar( x + w + gap, y, w * arena:GetChargeStatus( slot1, 2 ), h, -5, arena:IsChargeReady( slot1, 2 ) and 2 or 1 )
					surface.SetDrawColor( arena:IsChargeReady( slot1, 3 ) and col_flash or white_bar )
					self:PaintChargeBar( x + w * 2 + gap * 2, y, w * arena:GetChargeStatus( slot1, 3 ), h, -5, arena:IsChargeReady( slot1, 3 ) and 2 or 1 )

				end

				local gap3 = gap2 + 5 + w * 3 + gap * 2

				x, y = pw - gap3, ph - 30 - h

				if pl2 and pl2:IsValid() then

					white_bar.r = 255
					white_bar.g = 255
					white_bar.b = 255

					white_bar.a = 220

					surface.SetDrawColor( Color( 0, 0, 0, 120 ) )
					draw.NoTexture()
					if !arena:IsChargeReady( slot2, 3 ) then
						self:PaintChargeBar( x, y, w, h, 5, 1 )
					end
					if !arena:IsChargeReady( slot2, 2 ) then
						self:PaintChargeBar( x + w + gap, y, w, h, 5, 1 )
					end
					if !arena:IsChargeReady( slot2, 1 ) then
						self:PaintChargeBar( x + w * 2 + gap * 2, y, w, h, 5, 1 )
					end

					local rate = RealTime() * 1
					local sin = math.sin( rate )
					local cos = math.cos( rate )

					if arena:IsChargeReady( slot2, 1 ) then
						draw.SimpleText( sin > 0 and name1 or hint1, "RagdollFightChargeDesc", x + w * 2 + gap * 2 + w/2, y - h - 10, Color( 255, 255, 255, math.abs( sin * 220 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					if arena:IsChargeReady( slot2, 2 ) then
						draw.SimpleText( sin > 0 and name2 or hint2, "RagdollFightChargeDesc", x + w + gap + w/2, y - h - 10, Color( 255, 255, 255, math.abs( sin * 220 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					if arena:IsChargeReady( slot2, 3 ) then
						draw.SimpleText( sin > 0 and name3 or hint3, "RagdollFightChargeDesc", x + w/2, y - h - 10, Color( 255, 255, 255, math.abs( sin * 220 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					local col_flash = Color( 255, 255, 255, 220 + math.abs( cos * 35 ) )

					surface.SetDrawColor( arena:IsChargeReady( slot2, 1 ) and col_flash or white_bar )
					self:PaintChargeBar( x + w * 2 + gap * 2 + w * ( 1 - arena:GetChargeStatus( slot2, 1 ) ), y, w * arena:GetChargeStatus( slot2, 1 ), h, 5, arena:IsChargeReady( slot2, 1 ) and 2 or 1 )
					surface.SetDrawColor( arena:IsChargeReady( slot2, 2 ) and col_flash or white_bar )
					self:PaintChargeBar( x + w + gap + w * ( 1 - arena:GetChargeStatus( slot2, 2 ) ), y, w * arena:GetChargeStatus( slot2, 2 ), h, 5, arena:IsChargeReady( slot2, 2 ) and 2 or 1 )
					surface.SetDrawColor( arena:IsChargeReady( slot2, 3 ) and col_flash or white_bar )
					self:PaintChargeBar( x + w * ( 1 - arena:GetChargeStatus( slot2, 3 ) ), y, w * arena:GetChargeStatus( slot2, 3 ), h, 5, arena:IsChargeReady( slot2, 3 ) and 2 or 1 )
				end

				self.ShowHintsDelay = self.ShowHintsDelay or 0

				if pl:KeyDown( IN_SCORE ) and self.ShowHintsDelay < CurTime( )then
					self.ShowHints = !self.ShowHints
					self.ShowHintsDelay = CurTime() + 0.5
				end

				if arena:GetPlayerNum() < 2 and self.ShowHints then

					for i=1, #self.HintText do

						local pressed = true

						if self.HintText[ i ].keys then
							for _, v in pairs( self.HintText[ i ].keys ) do
								if not pl:KeyDown( v ) then
									pressed = false
									break
								end
							end
						else
							pressed = false
						end

						local text_col = pressed and Color( 225, 50, 50, 250 ) or white_bar

						local txt = self.HintText[ i ].txt
						draw.SimpleText( txt, "RagdollFightDefault", pw/2, ph/2 + 25 * i, text_col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
					end

				end



				for _, msg in pairs( self.Messages or {} ) do

					if not msg.time then
						msg.time = CurTime()
					end

					local fadeout = ( msg.time + msg.dur ) - CurTime()

					if ( msg.time + msg.dur ) > CurTime() then

						local font = msg.t == 1 and "RagdollFightBigMessage" or msg.t == 2 and "RagdollFightMedMessage" or "RagdollFightSmallMessage"

						surface.SetFont( font)
						local t_w, t_h = surface.GetTextSize( msg.text )
						local r_h = t_h * 1.2

						surface.SetDrawColor( Color( 0, 0, 0, 120 * math.Clamp( fadeout, 0, 1 ) ) )
						surface.DrawRect( 0, ph/2.5 - r_h/2, pw, r_h )

						draw.SimpleText( msg.text, font, pw/2, ph/2.5, Color( 255, 255, 255, fadeout * 220 ),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

						return
					end

				end

				if #self.Messages > 0 then
					table.Empty( self.Messages )
				end

			end


		end
		base.Think = function( self )
			--self:MoveToFront()
			if !IsValid( self.Arena ) then
				self:Remove()
				return
			end
		end

	end


	net.Receive( "RagdollFightArenaRemovePlayer", function( len )

		local pl = LocalPlayer()

		if !IsValid( pl ) then return end

		pl.RagdollFightArena = nil
		pl.RagdollFightArenaSlot = nil

	end )

	net.Receive( "RagdollFightArenaSendMessage", function( len )

		local pl = LocalPlayer()

		if !IsValid( pl ) then return end

		local t = net.ReadInt( 32 )
		local dur = net.ReadFloat( )
		local text = net.ReadString()

		if pl.RagdollFightArenaHUD then
			pl.RagdollFightArenaHUD:AddMessage( text, dur, t )
		end

	end )

	net.Receive( "RagdollFightArenaUpdatePlayer", function( len )

		local pl = LocalPlayer()

		if !IsValid( pl ) then return end

		local arena = net.ReadEntity()
		local slot = net.ReadInt( 32 )

		--clean up previous clientside dummies
		if pl.RagdollFightDummies then
			for k, v in pairs( pl.RagdollFightDummies ) do
				if v and v:IsValid() then
					v:Remove()
				end
			end
			table.Empty( pl.RagdollFightDummies )
		end

		if arena and arena:IsValid() and slot then
			pl.RagdollFightArena = arena
			pl.RagdollFightArenaSlot = slot

			RagdollFight.HUD()
		end


	end )

end

function ENT:GetPlayer( slot )
	slot = math.Clamp( slot, 1, 2 )
	return self:GetDTEntity( slot )
end

function ENT:GetPlayerText( slot )
	slot = math.Clamp( slot, 1, 2 )
	return self:GetDTString( slot )
end

function ENT:GetPlayerHealth( slot )
	slot = math.Clamp( slot, 1, 2 )
	return self:GetDTInt( slot ) or 0
end

function ENT:GetCharge( slot )
	slot = math.Clamp( slot + 4, 5, 6 )
	return self:GetDTInt( slot )
end

function ENT:IsChargeReady( slot, num )
	local charge = self:GetChargeStatus( slot, num )
	return charge >= 1
end

function ENT:GetChargeStatus( slot, num )
	local charge = self:GetCharge( slot )
	local delta = ( charge - ( num - 1 ) * 33 ) / 33
	return math.Clamp( delta, 0, 1 )
end

function ENT:GetPlayerScore( slot )
	slot = math.Clamp( slot + 2, 3, 4 )
	return self:GetDTInt( slot ) or 0
end

function ENT:GetDirVector( slot )
	slot = math.Clamp( slot, 1, 2 )
	return self:GetDTVector( slot )
end

function ENT:GetRound()
	return self:GetDTInt( 7 )
end


function ENT:GetPlayerNum()
	local cnt = 0

	if IsValid( self:GetPlayer( 1 ) ) then
		cnt = cnt + 1
	end

	if IsValid( self:GetPlayer( 2 ) ) then
		cnt = cnt + 1
	end

	return cnt
end

function ENT:GetRagdollFighter( slot )
	slot = math.Clamp( slot + 2, 3, 4 )
	return self:GetDTEntity( slot )
end

scripted_ents.Register( ENT, "ragdollfight_arena" )
