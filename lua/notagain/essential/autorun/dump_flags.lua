local function get_flags(what)
	local tbl = {}
	for k,v in pairs(_G) do
		if type(k) == "string" and type(v) == "number" and k:StartWith(what) then
			table.insert(tbl, {k = k, v = v})
		end
	end

	table.sort(tbl, function(a, b) return a.k > b.k end)

	return tbl
end

local found = {}

local function print_flags(ent, func, friendly, flags)
	local tbl = found[flags]

	if not tbl then
		tbl = get_flags(flags)
		found[flags] = tbl
	end

	print(friendly .. " flags:")
	for k,v in pairs(tbl) do
		if func(ent, v.v) then
			print("\t" .. v.k)
		end
	end
end

local function print_enum(ent, func, friendly, flags)
	local tbl = found[flags]

	if not tbl then
		tbl = get_flags(flags)
		found[flags] = tbl
	end

	for k,v in pairs(tbl) do
		if func(ent) == v then
			print(friendly .. ": " .. v.k)
		end
	end
end

function DumpFlags(ent)
	print_flags(ent, ent.IsEFlagSet, "entity", "EFL_")
	print_flags(ent, ent.IsEffectActive, "effect", "EF_")
	print_flags(ent, ent.IsFlagSet, "misc", "FL_")
	print_flags(ent, ent.HasSpawnFlags, "spawn", "SF_")
	print_flags(ent, function(e, v) return bit.band(e:GetSolidFlags(), v) == v end, "solid", "FSOLID_")
	print_enum(ent, ent.GetRenderMode, "rendermode", "RENDERMODE_")
	print_enum(ent, ent.GetCollisionGroup, "collision group", "COLLISION_GROUP_")
	print_enum(ent, ent.GetSolid, "solid", "SOLID_")

	print("parent: ", ent:GetParent())
	print("nodraw: ", ent:GetNoDraw())
	print("owner: ", ent:GetOwner())
	if CLIENT then
		print("predictable: ", ent:GetPredictable())
	end
	local seq = ent:GetSequence() or -1
	print("sequence: ", (ent:GetSequenceName(seq) or "INVALID") .. "(" .. seq .. ")")
	print("transmit with parent: ", ent:GetTransmitWithParent())

	if SERVER then
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			print_flags(phys, phys.HasGameFlag, "vphysics", "FVPHYSICS_")
		end
	end
end