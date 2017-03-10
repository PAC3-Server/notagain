timer.Simple(0.5, function()
	if not FindMetaTable("Player").CanAlter or not _G.FPP then return end
	FPP._OLD_plyCanTouchEnt = FPP._OLD_plyCanTouchEnt or FPP.plyCanTouchEnt
	function FPP.plyCanTouchEnt(ply, ent, ...)
		if ply:CanAlter(ent) then
			return 31 -- all the touch flags
		end
		return FPP._OLD_plyCanTouchEnt(ply, ent, ...)
	end
end)