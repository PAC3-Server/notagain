hook.Add("CreateClientsideRagdoll","RemoveRagdoll",function( entity, ragdoll )

	timer.Simple(10,function() ragdoll:SetSaveValue( "m_bFadingOut", true ) ragdoll:Remove() end)

end)

