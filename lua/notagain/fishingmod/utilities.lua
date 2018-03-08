function fishing.GetOutfit(name)	return CompileFile("notagain/fishingmod/client/pac_outfits/".. name ..".lua")()end

if CLIENT then
	local jfx = requirex("jfx")	function fishing.GetMaterialFromURL(url, size)		return jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = url,
			VertexAlpha = 1,
			VertexColor = 1,
		})	end
endfunction fishing.Panic()	for key, ent in pairs(ents.GetAll()) do		if ent.IsFishingEntity then			ent:Remove()		end	endendfunction fishing.GetRandomSize(rareness)	rareness = rareness or 20	return 1 + ((math.random() ^ rareness) * 3) - (math.random() ^ rareness)endfunction fishing.IsSomeoneFishing()	for key, ply in pairs(player.GetAll()) do		if ply:GetActiveWeapon().ClassName == "weapon_fishing" then			return true		end	end	return falseendfunction fishing.IsPosVisible(pos)	for key, ply in pairs(player.GetAll()) do		if ply:VisibleVec(pos) then			return true		end		local wep = ply:GetActiveWeapon()		if wep.ClassName == "weapon_fishing" then			if wep.dt.hook:GetPos():Distance(pos) < 500 then				return true			end		end	end	return falseendfunction fishing.IsFishing(ply)	return (ply or LocalPlayer()):GetActiveWeapon().ClassName == "weapon_fishing"endif SERVER then	util.AddNetworkString("fishing_event")endif CLIENT then	net.Receive("fishing_event", function()		local event = net.ReadString()		local args = net.ReadTable()		fishing.CallEvent(event, unpack(args))	end)endfunction fishing.CallEvent(event, ...)	if CLIENT then		return hook.Run("Fishing" ..event, ...)	end	if SERVER then		net.Start("fishing_event")			net.WriteString(event)			net.WriteTable({...})		net.Broadcast()	endend