local pac999 = requirex("pac999")

local Part = pac999.Part

if not IsValid(LOL) then return end

local a = util.KeyValuesToTable(file.Read("settings/spawnlist_default/001-construction props.txt", "GAME")).contents

local mdl = "models/hunter/blocks/cube075x075x075.mdl"
local root = Part(nil, mdl)
root:SetEntity(LOL)
root:SetPosition(Vector(0,0,0))
root:SetAngles(Angle(0,0,0))


local node = root

for i = 1,10 do
    local a = Part(node, table.Random(a).model)
    a:SetLocalScale(Vector(1,1,1))
    --a:SetScale(Vector(i,i,1))
    a:SetPosition(Vector(100,0,0))
    --a:SetAngles(Angle(-45,-45,0))
    node = a
end


do return end


root:SetScale(Vector(1,1,1)*0.5)

local list = {}
local node = root
for i = 1, 1 do
    local part = Part(node)
    list[i] = part
    part:SetPosition(Vector(0,0,0))
    part:SetScale(Vector(1 + (1/500), 1, 1))
    node = part
end

hook.Add("Think", "", function()
    local t = CurTime()
    local a = Angle(t,t,-t)
    for i,v in ipairs(list) do
        a.p = t
        a.y = t
        a.r = -t
        v:SetAngles(a)
        t = t * 1.001
    end
end)


return pac999