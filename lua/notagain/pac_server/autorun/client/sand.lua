concommand.Add("sand", function()
	local textures = requirex("textures")

	-- Material Extensions / SkyBox modder
	local sky =
	{
		["up"]=true,
		["dn"]=true,
		["lf"]=true,
		["rt"]=true,
		["ft"]=true,
		["bk"]=true,
	}

	local sky_name = GetConVarString("sv_skyname")

	for side, path in pairs(sky) do
		path = "skybox/" .. sky_name .. side
		--textures.ReplaceTexture("sand.lua", path, "Decals/decal_paintsplatterpink001")
		--textures.SetColor("sand.lua", path, Vector(0.4,1,1))
	end

	for path, path in pairs(game.GetWorld():GetMaterials()) do
		if path:lower():find("grass") then
			textures.ReplaceTexture("sand.lua", path, "Nature/blendsandsand008a.vmt")
			textures.SetColor("sand.lua", path, Vector(1, 1, 1)*0.7)
		end
	end

	if CLIENT then

		hook.Add("RenderScreenspaceEffects", "hm", function()
			--DrawToyTown( 2, 200)

			local tbl = {}
				tbl[ "$pp_colour_addr" ] = 0.07
				tbl[ "$pp_colour_addg" ] = 0.02
				tbl[ "$pp_colour_addb" ] = 0.03
				tbl[ "$pp_colour_brightness" ] = 0.1
				tbl[ "$pp_colour_contrast" ] = 0.95
				tbl[ "$pp_colour_colour" ] = 1.3
				tbl[ "$pp_colour_mulr" ] = 0
				tbl[ "$pp_colour_mulg" ] = 0
				tbl[ "$pp_colour_mulb" ] = 0
			DrawColorModify( tbl )

		end)

		local function SetupFog()
			render.FogMode(1)
			render.FogStart(0)
			render.FogEnd(4096*4)
			render.FogColor(255, 100, 100)
			render.FogMaxDensity(0.05)

			return true
		end

		hook.Add("SetupWorldFog", "desert", SetupFog)
		hook.Add("SetupSkyboxFog", "desert", SetupFog)
	end

	if IsValid(g_SkyPaint) then
		g_SkyPaint:SetTopColor(Vector(37, 139, 162)/255)
		g_SkyPaint:SetBottomColor(Vector(168, 168, 168)/255)
		g_SkyPaint:SetDuskColor(Vector(1,0,0))
		g_SkyPaint:SetDuskScale(0)
		g_SkyPaint:SetFadeBias(0.1)
		g_SkyPaint:SetDuskIntensity(0.5)
	end
end)