local textures = {}

textures.replaced = {}

function textures.ReplaceTexture(id, path, to)
	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then

		local typ = type(to)
		local tex

		if typ == "string" then
			tex = Material(to):GetTexture("$basetexture")
		elseif typ == "ITexture" then
			tex = to
		elseif typ == "Material" then
			tex = to:GetTexture("$basetexture")
		else
			return false
		end

		textures.replaced[path] = textures.replaced[path] or {}
		textures.replaced[path][id] = textures.replaced[path][id] or {}

		textures.replaced[path][id].old_tex = textures.replaced[path][id].old_tex or mat:GetTexture("$basetexture")
		textures.replaced[path][id].new_tex = tex

		mat:SetTexture("$basetexture", tex)

		return true
	end

	return false
end


function textures.SetColor(id, path, color)
	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then
		textures.replaced[path] = textures.replaced[path] or {}
		textures.replaced[path][id] = textures.replaced[path][id] or {}

		textures.replaced[path][id].old_color = textures.replaced[path][id].old_color or mat:GetVector("$color")
		textures.replaced[path][id].new_color = color

		mat:SetVector("$color", color)

		return true
	end

	return false
end

function textures.Restore(id)
	for id_, data in pairs(textures.replaced) do
		if not id or id == _id then
			for name, tbl in pairs(data) do
				if
					not pcall(function()
						if tbl.old_tex then
							textures.ReplaceTexture(name, tbl.old_tex)
						end

						if tbl.old_color then
							textures.SetColor(name, tbl.old_color)
						end
					end)
				then
					print("Failed to restore: " .. tostring(name))
				end
			end
		end
	end
end

hook.Add("ShutDown", "texture_restore", function() textures.Restore() end)

return textures