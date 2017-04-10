hook.Add("PlayerSpawnedSWEP", "undo_weapon", function(ply, ent)
	undo.Create("Weapon")
		undo.SetPlayer(ply)
		undo.AddEntity(ent)

		undo.AddFunction(function(self)
			if ent:IsValid() and ent:GetOwner():IsValid() then
				self.Entities = nil
			end
		end)

		if ent.PrintName then
			undo.SetCustomUndoText("Undone " .. ent.PrintName)
		end

	undo.Finish("Weapon (" .. tostring(ent:GetClass()) .. ")")
end)