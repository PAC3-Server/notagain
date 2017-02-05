hook.Add("CreateClientsideRagdoll","RemoveRagdoll",function( entity, ragdoll )

	timer.Simple(10,function() if IsValid(ragdoll) then ragdoll:SetSaveValue( "m_bFadingOut", true ) ragdoll:Remove() end end)

end)

