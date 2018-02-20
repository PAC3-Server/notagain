AddCSLuaFile()

local LUA_GETTABLE = false
local LUA_BONE_CACHE = false

do -- override type functions
	gtype = type

	local getmetatable = getmetatable
	local rawequal = rawequal

	getmetatable("").MetaName = "string"

	if not getmetatable(0) then
		debug.setmetatable(0, {MetaName = "number"})
	else
		getmetatable(0).MetaName = "number"
	end

	if not getmetatable(function() end) then
		debug.setmetatable(function() end, {MetaName = "function"})
	else
		getmetatable(function() end).MetaName = "function"
	end

	if not getmetatable(coroutine.create(getmetatable)) then
		debug.setmetatable(coroutine.create(getmetatable), {MetaName = "thread"})
	else
		getmetatable(coroutine.create(getmetatable)).MetaName = "thread"
	end

	function type(val)
		if rawequal(val, nil) then
			return "nil"
		end

		if rawequal(val, true) or rawequal(val, false) then
			return "boolean"
		end

		local m = getmetatable(val)

		return m and m.MetaName or "table"
	end

	local type = type

	local function override(name)
		local old = _G["is" .. name:lower()]
		_G["is" .. name:lower()] = function(val)
			local m = getmetatable(val)
			return m and m.MetaName == name or false
		end
	end

	override("string")
	override("number")
	override("bool")
	override("function")

	override("Angle")
	override("Vector")
	override("Panel")
	override("Matrix")

	function istable(val)
		return type(val) == "table"
	end

	function isentity(val)
		local m = getmetatable(val)
		return m and (m.MetaName == "Entity" or m.MetaBaseClass and m.MetaBaseClass.MetaName == "Entity")
	end

	IsEntity = isentity
end

function LUAIFY_POST()
	do return end

	local events = {}
	local hook_call = hook.Call
	hook.Call = function(event, gm, ...)
		if events[event] then
			local a,b,c,d,e,f,g = events[event](...)
			if a ~= nil then
				return a,b,c,d,e,f,g
			end
		end

		return hook_call(event, gm, ...)
	end

	local init_entity
	local remove_entity

	do
		local list = {}
		local hash_list = {}

		function ents.GetAll()
			local copy = {}

			for i, v in ipairs(list) do
				copy[i] = v
			end

			return copy
		end

		function player.GetAll()
			local copy = {}

			local i = 1

			for _, v in ipairs(list) do
				if v:GetClass() == "player" then
					copy[i] = v
					i = i + 1
				end
			end

			return copy
		end

		function ents.FindByClass(class)
			class = class:lower()

			local copy = {}
			local i = 1

			if class:find("*", nil, true) then
				class = class:gsub("%*", ".-")

				for _, v in ipairs(list) do
					if v:GetClass():find(class) then
						copy[i] = v
						i = i + 1
					end
				end
			else
				for _, v in ipairs(list) do
					if v:GetClass() == class then
						copy[i] = v
						i = i + 1
					end
				end
			end

			return copy
		end

		local local_player = _G.LocalPlayer
		local LOCAL_PLAYER

		if CLIENT then
			function _G.LocalPlayer()
				return LOCAL_PLAYER or NULL
			end
		end

		events.OnEntityCreated = function(ent)
			if local_player and not LOCAL_PLAYER and ent == local_player() then
				LOCAL_PLAYER = ent
			end

			if LUA_GETTABLE then
				init_entity(ent)
			end

			if not hash_list[ent] then
				table.insert(list, ent)
				hash_list[ent] = true
			end
		end

		events.NetworkEntityCreated = events.OnEntityCreated

		events.EntityRemoved = function(ent)
			if local_player and LOCAL_PLAYER and ent == local_player() then
				LOCAL_PLAYER = nil
			end

			if hash_list[ent] then
				for i, v in ipairs(list) do
					if v == ent then
						remove_entity(ent)
						table.remove(list, i)
						break
					end
				end
				hash_list[ent] = nil
			end
		end

		events.PlayerDisconnected = events.EntityRemoved

		ENTITY_LIST = list
	end

	do -- entity meta
		local ENTITY = FindMetaTable("Entity")
		local VEHICLE = FindMetaTable("Vehicle")
		local PLAYER = FindMetaTable("Player")
		local WEAPON = FindMetaTable("Weapon")

		local env = {}

		luaify_env = env

		local set_table = ENTITY.SetTable
		local get_table = ENTITY.GetTable
		local is_valid = ENTITY.IsValid

		local set_model = ENTITY.SetModel
		local get_model = ENTITY.GetModel

		local get_bone_count = ENTITY.GetBoneCount
		local get_bone_name = ENTITY.GetBoneName
		local lookup_bone = ENTITY.LookupBone

		local get_class = ENTITY.GetClass

		--local get_scripted_table = scripted_ents.Get
		--function scripted_ents.Get() return nil end

		init_entity = function(self)
			if LUA_GETTABLE then
				self:GetTable()
			else
				env[self] = {}
				env[self].class = get_class(self)
			end
			--print("CREATE", self, get_class(self))
		end

		remove_entity = function(self)
			env[self] = nil
			--print("REMOVE", self, get_class(self))
		end

		local function reset_bones(self)
			env[self].model = get_model(self)
			env[self].bone_count = get_bone_count(self)
			env[self].bones = {}

			if CLIENT then
				self:SetupBones()
			end

			for i = 0, env[self].bone_count do
				local name = get_bone_name(self, i)

				if name then
					env[self].bones[name:lower()] = i
				end
			end
		end

		if LUA_BONE_CACHE then
			timer.Create("__check_bones_luaify", 0.1, 0, function()
				for _, v in ipairs(ENTITY_LIST) do
					local mdl = get_model(v)
					if env[v] and env[v].model ~= mdl then
						env[v].model = mdl
						reset_bones(v)
					end
				end
			end)
		end

		local function check_table(self)
			if env[self] then
				if env[self].changed_table == false then
					local t = get_table(self)
					if t ~= env[self].tbl then
						--print("TABLE CHANGED!?", self, get_class(self), env[self].tbl, ">>", get_table(self))
						env[self].tbl = t
						env[self].changed_table = true
					end
				end
			elseif is_valid(self) then
				local class = get_class(self)

				env[self] = {}
				env[self].class = class
				env[self].tbl = get_table(self)
				env[self].changed_table = not self:IsScripted()

				reset_bones(self)

				--print("TABLE SETUP", self, get_class(self))
			end
		end

		function ENTITY:__index(key)
			local val = ENTITY[key]
			if val ~= nil then return val end

			local tbl = ENTITY.GetTable( self )
			if tbl then
				local val = tbl[key]
				if val ~= nil then return val end
			end

			if key == "Owner" then
				return ENTITY.GetOwner( self )
			end

			return nil
		end

		function WEAPON:__index(key)
			local val = WEAPON[key]
			if val ~= nil then return val end

			local val = ENTITY[key]
			if val ~= nil then return val end

			local tbl = ENTITY.GetTable( self )
			if tbl then
				local val = tbl[key]
				if val ~= nil then return val end
			end

			if key == "Owner" then
				return ENTITY.GetOwner( self )
			end

			return nil
		end

		function VEHICLE:__index(key)
			local val = VEHICLE[key]
			if val ~= nil then return val end

			local val = ENTITY[key]
			if val ~= nil then return val end

			local tbl = ENTITY.GetTable( self )
			if tbl then
				local val = tbl[key]
				if val ~= nil then return val end
			end

			return nil
		end

		function PLAYER:__index( key )
			local val = PLAYER[key]
			if val ~= nil then return val end

			local val = ENTITY[key]
			if val ~= nil then return val end

			local tbl = ENTITY.GetTable( self )
			if tbl then
				local val = tbl[key]
				if val ~= nil then return val end
			end

			return nil
		end

		if LUA_GETTABLE then
			function ENTITY:__newindex(key, val)
				check_table(self)
				if env[self] then
					env[self].tbl[key] = val
				end
			end

			PLAYER.__newindex = ENTITY.__newindex
			VEHICLE.__newindex = ENTITY.__newindex
			WEAPON.__newindex = ENTITY.__newindex

			function ENTITY:GetTable()
				check_table(self)
				return env[self] and env[self].tbl
			end

			function ENTITY:SetTable(tbl)
				check_table(self)
				env[self].tbl = tbl
			end
		end
		-- this does not work well
		-- function ENTITY:IsValid() return env[self] ~= nil end

		function ENTITY:IsPlayer()
			return env[self] and env[self].class == "player"
		end

		function ENTITY.__eq(a, b)
			return rawequal(a, b)
		end

		VEHICLE.__eq = ENTITY.__eq
		PLAYER.__eq = ENTITY.__eq
		WEAPON.__eq = ENTITY.__eq

		function ENTITY:GetClass()
			return env[self] and env[self].class or get_class(self)
		end

		if LUA_BONE_CACHE then
			function ENTITY:SetModel(mdl)
				set_model(self, mdl)
				reset_bones(self)
			end

			function ENTITY:GetModel()
				return env[self].model
			end

			function ENTITY:GetBoneCount()
				return env[self].bone_count
			end

			function ENTITY:LookupBone(str)
				return env[self].bones[tostring(str):lower()]
			end
		end

		ENTITY_TABLES = env
	end

	-- not working yet
	if CLIENT and false then
		do -- panels
			local PANEL = FindMetaTable("Panel")

			local env = {}

			local set_table = PANEL.SetTable
			local get_table = PANEL.GetTable
			local is_valid = PANEL.IsValid

			local function check_table(self)
				if not env[self] and is_valid(self) then
					env[self] = {}
					env[self].tbl = get_table(self)
				end
			end

			function PANEL:__index(key)
				local tbl = env[self] and env[self].tbl
				if tbl then
					local val = tbl[key]
					if val ~= nil then return val end
				end

				local val = PANEL[key]
				if val ~= nil then return val end

				if key == "x" or key == "X" then
					local x = PANEL.GetPos(self)
					return x
				elseif key == "y" or key == "Y" then
					local _, y = PANEL.GetPos(self)
					return y
				elseif key == "w" or key == "W" then
					return PANEL.GetWide(self)
				elseif key == "h" or key == "H" then
					return PANEL.GetTall(self)
				elseif key == "Hovered" then
					return PANEL.IsHovered(self)
				end
			end

			function PANEL:__newindex(key, val)
				check_table(self)
				if env[self] then
					env[self].tbl[key] = val
				end
			end

			function PANEL:GetTable()
				check_table(self)
				return env[self] and env[self].tbl
			end

			function PANEL:SetTable(tbl)
				check_table(self)
				env[self].tbl = tbl
			end

			local remove = PANEL.Remove

			function PANEL:Remove()
				env[self] = nil
				remove(self)
			end
--[[
			local vgui_create = vgui.Create

			function vgui.Create(class, parent, name)
				local self = vgui_create(class, parent, name)
				check_table(self)
				return self
			end
]]
		end
	end
end