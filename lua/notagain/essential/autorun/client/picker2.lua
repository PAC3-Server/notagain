-----------------------------------------------------------------
-- Usage:                                                      --
--   bind key picker2                                          --
--     Enable/Disable picker.                                  --
--                                                             --
--   bind key +picker2_copy                                    --
--     Copies the highlighted entry to the clipboard.          --
--     Hold down, move mouse over label, release.              --
--                                                             --
-----------------------------------------------------------------
-- Console Variables:                                          --
--   picker2_centerdist:                                       --
--     How far from the center should labels be drawn?         --
--     Default = 16 pixels                                     --
--                                                             --
--   picker2_decimals:                                         --
--     Number of decimals to round to.                         --
--     Default = 2                                             --
--                                                             --
--   picker2_box:                                              --
--     Draw boxes around the currently highlighted label?      --
--     0 = never                                               --
--     1 = while holding the copy button (Default)             --
--     2 = always                                              --
--                                                             --
-----------------------------------------------------------------
-- Version history:                                            --
--   1.3.0 - Made picker2_decimals fault-tolerant              --
--         - Updated for gmod 13 beta                          --
--   1.2.1 - Version 1.2 accidentaly required wiremod to work  --
--   1.2.0 - Made label positions a lot more consistent,       --
--           if there is a lot of them.                        --
--         - You can now display PhysObjs/bones of ragdolls.   --
--           "picker2" cycles between disabled/ents/bones.     --
--   1.1.0 - Added cvars for decimals and centerdist           --
--           Added box around labels. picker2_box 0 to disable --
--   1.0.0 - First public release, based on ReaperSWE's ver    --
-----------------------------------------------------------------

if not CLIENT then return end -- to avoid stupidity

--local validEntity = _R.Entity.IsValid
local validEntity = FindMetaTable("Entity").IsValid

-- configuration is now done via cvars:
picker2_centerdist = CreateClientConVar("picker2_centerdist", 16, true, false)
picker2_decimals   = CreateClientConVar("picker2_decimals"  ,  2, true, false)
picker2_box        = CreateClientConVar("picker2_box"       ,  1, true, false)

-- cache some library functions
local Round = math.Round
local abs = math.abs
local table_insert = table.insert
local sprintf = string.format

local vecformat = "%.2f, %.2f, %.2f"
local function FormatVector(value)
	return sprintf(vecformat, value.x, value.y, value.z)
end

local function FormatAngle(value)
	return sprintf(vecformat, value.p, value.y, value.r)
end

local function pairs_sortvalues(tbl, criterion)
	local crit = criterion and
		function(a,b)
			return criterion(tbl[a],tbl[b])
		end
	or
		function(a,b)
			return tbl[a] < tbl[b]
		end

	tmp = {}
	for k,v in pairs(tbl) do table.insert(tmp,k) end
	table.sort(tmp, crit)

	local iter, state, index, k = ipairs(tmp)
	return function()
		index,k = iter(state, index)
		if index == nil then return nil end
		return k,tbl[k]
	end
end


local mode = 0
-- text to be copied to the clipboard
local selected_text = nil
local freeze_labels = false

-- entities for which labels should be shown
local textents = {}
local entstable = {}

hook.Add("EntityRemoved", "picker2", function(ent)
	textents[ent] = nil
end)

--local LocalToWorld = FindMetaTable("Entity").LocalToWorld
local ToScreen = FindMetaTable("Vector").ToScreen
local SetDrawColor = surface.SetDrawColor
local DrawLine = surface.DrawLine

local vec_forward, vec_left, vec_up

local function drawents()
	local centerdist, decimals = picker2_centerdist:GetFloat(), math.Clamp(math.floor(picker2_decimals:GetFloat()),0,16)
	vecformat = string.format("%%.%df, %%.%df, %%.%df", decimals, decimals, decimals)

	selected_text = nil

	local entstable = ents.GetAll()

	local centerx = ScrW()/2
	local centery = ScrH()/2

	-- reset the list of labeled entities
	if not freeze_labels then textents = {} end

	local playerpos = LocalPlayer():GetPos()
	local playershootpos = LocalPlayer():GetShootPos()
	local trace = LocalPlayer():GetEyeTrace()

	local function drawent(entphys, realent, boneindex)
		-- skip entities at players' feet, like the player entity itself and some other things servers tend to place.
		if entphys:GetPos() == playerpos then return end

		local pos = entphys:GetPos()
		-- skip entities that are too close to the player, including weapons
		if playershootpos:Distance(pos) < 32 then return end

		local pos_ToScreen = ToScreen(pos)
		-- Don't draw things we can't see.
		if not pos_ToScreen.visible then return end
		local scrposx,scrposy = pos_ToScreen.x,pos_ToScreen.y
		if scrposx < 0 then return end
		if scrposy < 0 then return end
		if scrposx >= ScrW() then return end
		if scrposy >= ScrH() then return end

		--pos_center = entphys:LocalToWorld( Vector( 0, 0, 0)):ToScreen() scrposx,scrposy = pos_center.x, pos_center.y
		local LocalToWorld = entphys.LocalToWorld
		pos_axis = ToScreen(LocalToWorld(entphys, vec_forward))
		SetDrawColor( 255, 0, 0, 255 ) DrawLine( pos_axis.x, pos_axis.y, scrposx, scrposy )

		pos_axis = ToScreen(LocalToWorld(entphys, vec_left))
		SetDrawColor( 0, 255, 0, 255 ) DrawLine( pos_axis.x, pos_axis.y, scrposx, scrposy )

		pos_axis = ToScreen(LocalToWorld(entphys, vec_up))
		SetDrawColor( 0, 0, 255, 255 ) DrawLine( pos_axis.x, pos_axis.y, scrposx, scrposy )

		-- Don't draw labels for things off-center
		if abs(scrposx-centerx) > centerdist then return end
		if abs(scrposy-centery) > centerdist then return end
		if freeze_labels then return end

		-- draw labels for this entity
		textents[entphys] = { pos, scrposx, scrposy, nil, realent, boneindex or 0 }
	end -- function drawent

	-- draw axes
	for _, ent in ipairs(entstable) do
		if mode == 1 then
			drawent(ent)
		else--if mode == 2 then
			i = 0
			local phys
			while true do
				phys = ent:GetPhysicsObjectNum(i)
				if not phys or not phys:IsValid() then
					if i == 0 then drawent(ent) end
					break
				end
				drawent(phys, ent, i)
				if trace.Entity == ent and trace.PhysicsBone == i then textents[phys] = nil end
				i = i + 1
			end
		end
	end -- for entstable

	-- Always draw labels for the entity the player is looking at.
	local traceent = trace.Entity
	if validEntity(traceent) and not freeze_labels then
		local hasphys = false
		if mode == 2 then
			local tracephys = traceent:GetPhysicsObjectNum(trace.PhysicsBone)
			if tracephys then
				hasphys = true
				traceent = tracephys
			end
		end
		local pos = traceent:GetPos()
		local pos_ToScreen = ToScreen(pos)
		local scrposx,scrposy = math.floor(pos_ToScreen.x),math.floor(pos_ToScreen.y)

		local localvec = nil
		if not freeze_labels then
			local localpos = traceent:WorldToLocal(trace.HitPos)
			localvec = "Local Position: " .. FormatVector(localpos)
		end

		if hasphys then
			textents[traceent] = { pos, scrposx, scrposy, localvec, trace.Entity, trace.PhysicsBone }
		else
			textents[traceent] = { pos, scrposx, scrposy, localvec, nil, 0 }
		end
	end

	local pos, scrposx, scrposy, localvec

	-- keep track of the element closest to the crosshair.
	local mindist, mintext, minx, miny, minent,minenttext = math.huge,nil,0,0,NULL,""
	local function table_insert_logclosest(texts, ent, curtext)
		local x,y = scrposx-centerx, scrposy+(#texts+0.5)*16-centery
		local curdist = x*x+y*y*16

		if curdist < mindist then
			mindist = curdist
			mintext = curtext
			minx = scrposx
			miny = scrposy+(#texts)*16
			minent = ent
		end
		table_insert(texts,curtext)
	end

	local nextscrposy = -math.huge
	-- draw labels
	local function drawlabel(ent,v)
		pos, scrposx, scrposy, localvec, realent, boneindex = unpack(v)
		local isEntity = not realent
		if freeze_labels then
			local pos_ToScreen = ToScreen(pos)
			scrposx,scrposy = math.floor(pos_ToScreen.x),math.floor(pos_ToScreen.y)
		end

		if nextscrposy>scrposy then scrposy = nextscrposy end

		v[2] = scrposx
		v[3] = scrposy

		local texts = {}
		local name = ""
		if isEntity then
			if ent:IsPlayer() then name = ent:GetName() end
			table_insert_logclosest( texts, ent, "Entity: ("..ent:EntIndex() ..") ".. ent:GetClass() .." " .. name )
		else
			if not validEntity(realent) then return end
			table_insert_logclosest( texts, ent, "Bone: #"..boneindex.." of Entity #"..realent:EntIndex())
		end

		if pos.x ~= 0 or pos.y ~= 0 or pos.z ~= 0 then
			table_insert_logclosest( texts, ent, "Position: " .. FormatVector(pos) )
		end

		if localvec then
			table_insert_logclosest( texts, ent, localvec )
		end

		local angle = ent:GetAngles()
		if angle.p ~= 0 or angle.y ~= 0 or angle.r ~= 0 then
			table_insert_logclosest( texts, ent, "Angles: ".. FormatAngle(angle) )
		end

		if isEntity then
			local model = ent:GetModel()
			if model and model ~= "" then
				table_insert_logclosest( texts, ent, "Model: ".. model )
			end

			local material = ent:GetMaterial()
			if material and material ~= "" then
				table_insert_logclosest( texts, ent, "Material: ".. material )
			end

			local colr, colg, colb, cola = ent:GetColor()
			if VERSION >= 150 then colr, colg, colb, cola = colr.r, colr.g, colr.b, colr.a end
			if colr ~= 255 or colg ~= 255 or colb ~= 255 or cola ~= 255 then
				table_insert_logclosest( texts, ent, "Color: ".. colr ..", ".. colg ..", ".. colb ..", ".. cola )
			end

			if ent:IsPlayer() then
				table_insert_logclosest(texts, "Health: ".. ent:Health() .." Armor: ".. ent:Armor())
			end
		end

		local text = table.concat(texts, "\n")
		if ent == minent then minenttext = text end

		draw.DrawText(text, "BudgetLabel", scrposx, scrposy, Color(255,255,255,255), TEXT_ALIGN_LEFT)
		nextscrposy = scrposy + (#texts)*16+8
	end

	local function less_bone(a,b)
		if a then
			if b then return (a[3])<(b[3]) end
			return true
		end
		return false
	end
	for ent,v in pairs_sortvalues(textents,less_bone) do
		if v then drawlabel(ent,v) end
	end

	-- overdraw the closest label in green
	if mintext then
		local drawbox = picker2_box:GetInt()
		if drawbox == 2 or (freeze_labels and drawbox ~= 0) then
			local _,x,y = unpack(textents[minent])
			surface.SetFont("BudgetLabel")
			local w,h = surface.GetTextSize(minenttext)
			draw.RoundedBox(1, x-11, y-7, w+22, h+14, Color(0,0,0,192) )
			draw.RoundedBox(1, x-9, y-5, w+18, h+10, Color(128,128,128,255) )
			draw.DrawText(minenttext, "BudgetLabel", x, y, Color(255,255,255,255), TEXT_ALIGN_LEFT)
			draw.RoundedBox(1, minx-5, miny-1, w+10, 18, Color(32,32,32,255) )
			selected_text = mintext
		end

		draw.DrawText(mintext, "BudgetLabel", minx, miny, Color(128,255,128,255), TEXT_ALIGN_LEFT)
	end
end -- function drawents

concommand.Add("picker2", function(ply, command, args)
	mode = (mode+1)%3
	if mode == 0 then
		hook.Remove("HUDPaint", "picker2")
		GAMEMODE:AddNotify("Picker disabled.", NOTIFY_CLEANUP, 3)

		selected_text = nil
	elseif mode == 1 then
		hook.Add("HUDPaint", "picker2", drawents)
		GAMEMODE:AddNotify("Showing entities.", NOTIFY_GENERIC, 3)

		vec_forward = Vector(20,  0,  0)
		vec_left    = Vector( 0, 20,  0)
		vec_up      = Vector( 0,  0, 20)
	elseif mode == 2 then
		hook.Add("HUDPaint", "picker2", drawents)
		GAMEMODE:AddNotify("Showing physics objects/bones.", NOTIFY_GENERIC, 3)

		vec_forward = Vector(8, 0, 0)
		vec_left    = Vector(0, 8, 0)
		vec_up      = Vector(0, 0, 8)
	end
end)

concommand.Add("+picker2_copy", function(ply, command, args)
	freeze_labels = true
end)

concommand.Add("-picker2_copy", function(ply, command, args)
	freeze_labels = false
	if not selected_text then return end
	local piece, text = string.match(selected_text, "^([^:]+): (.*)$")
	if piece == "Entity" then
		text = string.match(text,"^%(?.[0-9]+%) (.*) .*$")
	elseif piece == "Bone" then
		local boneindex, entindex = string.match(text,"^#([0-9]+) of Entity #([0-9]+)$")
		text = string.format("entity(%s):bone(%s)", entindex, boneindex)
		--text = string.format("Entity(%s):GetPhysicsObjectNum(%s)", entindex, boneindex)
	end
	SetClipboardText(text)
	LocalPlayer():ChatPrint("Copied '"..text.."' to the clipboard.")
end)
