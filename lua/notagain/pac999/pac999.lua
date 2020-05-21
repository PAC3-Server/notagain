
AddCSLuaFile()

local camera = requirex("camera")
local input = requirex("input")

pac999 = pac999 or {}

local pac999 = pac999

local META = {}
META.__index = META

function META:__tostring()
    return "part " .. self.index
end

local ref = 0

function META:Initialize()
    self.Transform = Matrix()
    self.ScaleTransform = Matrix()
    self.LocalScaleTransform = Matrix()
    self.Matrix = Matrix()

    self.Children = {}
    self.Rays = {}

    self.index = ref
    ref = ref +  1
end

local function GetChildrenRecursive(self, out)
    for _, child in ipairs(self.Children) do
        table.insert(out, child)
        GetChildrenRecursive(child, out)
    end
end

function META:GetAllChildren()
    if not self.ChildrenList then
        self.ChildrenList = {}
        GetChildrenRecursive(self, self.ChildrenList)
    end

    return self.ChildrenList
end

function META:GetParentList()
    local out = {}

    local node = self.Parent

    if not node then return out end

    repeat
        table.insert(out, node)
        node = node.Parent

    until not node

    return out
end

function META:InvalidateMatrix()
    if self.InvalidMatrix then return end

    self.InvalidMatrix = true

    for _, child in ipairs(self:GetAllChildren()) do
        child.InvalidMatrix = true
    end
end

function META:GetMatrix()
    if self.InvalidMatrix then
        self.Matrix = self:BuildMatrix()
        self.InvalidMatrix = false
    end

    return self.Matrix
end

function META:BuildMatrix()
    local tr = self.ScaleTransform * self.Transform


    if self.Entity then
        tr = self.Entity:GetWorldTransformMatrix() * tr
    end

    if self.Parent then
        tr = self.Parent:GetMatrix() * tr
    end
    ---tr:Translate(LerpVector(0.5, self:OBBMins(), self:OBBMaxs()))

    tr:SetScale(self.LocalScaleTransform:GetScale())

    return tr
end

function META:AddChild(part)
    part.Parent = self
    table.insert(self.Children, part)

    self.ChildrenList = nil

    for i, v in ipairs(self:GetParentList()) do
        v.ChildrenList = nil
    end
end

function META:SetEntity(ent)
    --ent:SetRenderBounds(Vector(1,1,1)*-30000, Vector(1,1,1)*30000)
    self.Entity = ent

    ent.CalcAbsolutePosition = function(_)
        self:InvalidateMatrix()
        local m = self:GetMatrix()

        return m:GetTranslation(), m:GetAngles()
    end

    local pixvis-- = util.GetPixelVisibleHandle()

    ent.RenderOverride = function(_)
        local min, max = self:GetWorldSpaceBoundingBox()
        local center = LerpVector(0.5, min, max)
        local radius = min:Distance(max) / 2

        local visible = 1

        if pixvis then
            if EyePos():Distance(center) < radius then
                visible = 1
            else
                visible = util.PixelVisible(center, radius/2, pixvis)
            end
        end

        if visible > 0 then
            self.LastRender = FrameNumber()
            self:Render()
        end
        ent:DrawModel()
    end

    hook.Add("RenderScene", "pac_999", function()
        if not self:WasVisibleLastFrame() then return end

        self:UpdateRenderBounds()
        self:Update()
        self:DrawBounds()

        local m = self:GetMatrix()

        ent:SetPos(m:GetTranslation())
        ent:SetAngles(m:GetAngles())

        --self:AddEFlags(EFL_DIRTY_ABSTRANSFORM)
    end)

    hook.Add("PostDrawTranslucentRenderables", "pac_999", function()
        if not self:IsVisible() then return end
        self:Render2D()
    end)

    self:InvalidateMatrix()
end

function META:WasVisibleLastFrame()
    return self.LastRender == FrameNumber() -1
end

function META:IsVisible()
    return self.LastRender == FrameNumber()
end

function META:SetWorldMatrix(m)
    local lm = m:GetInverse() * self:GetMatrix()
    self.Transform = self.Transform * lm:GetInverse()
    self:InvalidateMatrix()
end

function META:SetPosition(v)
    self.Transform:SetTranslation(v)
    self:InvalidateMatrix()
end

function META:SetAngles(a)
    self.Transform:SetAngles(a)
    self:InvalidateMatrix()
end

function META:SetScale(v)
    self.ScaleTransform:Scale(v)
    self:InvalidateMatrix()
end

function META:SetLocalScale(v)
    self.LocalScaleTransform:Scale(v)
    self:InvalidateMatrix()
end


function META:GetRenderList()
    if not self.RenderList then
        self.RenderList = {self}
        for i,v in ipairs(self:GetAllChildren()) do
            self.RenderList[i+1] = v
        end
    end
    return self.RenderList
end

local function sort(a, b)
    return a:GetMatrix():GetTranslation():Distance(EyePos()) < b:GetMatrix():GetTranslation():Distance(EyePos())
end

function META:GetUpdateList()
    local out = {self}
    for i,v in ipairs(self:GetAllChildren()) do
        out[i+1] = v
    end

    table.sort(out, sort)

    return out
end

local ourMat = Material( "vgui/white" ) -- Calling Material() every frame is quite expensive
function META:Render()
    --mdl:EnableMatrix("RenderMultiply", self:GetMatrix())
    for _, child in ipairs(self:GetRenderList()) do
        local mdl = child.Model

        --mdl:SetBoneMatrix(0, v:GetMatrix())
        local world = child:GetMatrix()

        local m = world * Matrix()
        mdl:SetRenderOrigin(m:GetTranslation())
        m:SetTranslation(vector_origin)
        mdl:EnableMatrix("RenderMultiply", m)
        mdl:SetupBones()
        mdl:DrawModel()
    end
end

local function View(ray)
    local m = Matrix()
    m:SetAngles(ray:Angle())
    m:SetTranslation(EyePos())
    return m
end

local cache = {}
local function mesh_info(mdl)
    if not cache[mdl] then
        local data = util.GetModelMeshes(mdl, 0, 0)

        local angle_offset = Angle()
        local temp = ClientsideModel(mdl)
        temp:DrawModel()
        local m = temp:GetBoneMatrix(0)
        if m then
            angle_offset = m:GetAngles()
        end
        temp:Remove()

        local minx,miny,minz = 0,0,0
        local maxx,maxy,maxz = 0,0,0

        for _, data in ipairs(data) do
            for _, vertex in ipairs(data.triangles) do
                if vertex.pos.x < minx then minx = vertex.pos.x end
                if vertex.pos.y < miny then miny = vertex.pos.y end
                if vertex.pos.z < minz then minz = vertex.pos.z end

                if vertex.pos.x > maxx then maxx = vertex.pos.x end
                if vertex.pos.y > maxy then maxy = vertex.pos.y end
                if vertex.pos.z > maxz then maxz = vertex.pos.z end
            end
        end

        cache[mdl] = {
            data = data,
            min = Vector(minx, miny, minz),
            max = Vector(maxx, maxy, maxz),
            angle = angle_offset,
        }
    end

    return cache[mdl]
end


local box_mesh = Mesh()
mesh.Begin(box_mesh, MATERIAL_QUADS, 6)
    mesh.Quad(
        Vector(-1, -1, -1),
        Vector(-1, 1, -1),
        Vector(-1, 1, 1),
        Vector(-1, -1, 1)
    )
    mesh.Quad(
        Vector(1, -1, -1),
        Vector(-1, -1, -1),
        Vector(-1, -1, 1),
        Vector(1, -1, 1)
    )
    mesh.Quad(
        Vector(1, 1, -1),
        Vector(1, -1, -1),
        Vector(1, -1, 1),
        Vector(1, 1, 1)
    )
    mesh.Quad(
        Vector(-1, 1, -1),
        Vector(1, 1, -1),
        Vector(1, 1, 1),
        Vector(-1, 1, 1)
    )
    mesh.Quad(
        Vector(1, -1, 1),
        Vector(-1, -1, 1),
        Vector(-1, 1, 1),
        Vector(1, 1, 1)
    )
    mesh.Quad(
        Vector(1, 1, -1),
        Vector(-1, 1, -1),
        Vector(-1, -1, -1),
        Vector(1, -1, -1)
    )
mesh.End()

local white_mat = CreateMaterial("pac999_white_" .. math.random(), "VertexLitGeneric", {
    ["$basetexture"] = "color/white",
    ["$model"] = "1",
    ["$nocull"] = "0",
    ["$translucent"] = "0",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1",
})

local active_part = nil

pac999_temp_model = pac999_temp_model or ClientsideModel("error.mdl")
pac999_temp_model:SetNoDraw(true)
local temp_model = pac999_temp_model

function META:RenderGrabbableBox(id, pos, ang, mins, maxs, color, mdl, mdloffset, mdlscale)
    if active_part and self ~= active_part then return end
    local ray = self.Rays[id]
    if not ray then return end

    local m = self:GetMatrix() * Matrix()
    local ratio = mins - maxs
    m:Translate(LerpVector(0.5, mins, maxs))
    m:Translate(pos)
    m:Rotate(ang)
    local scale = -ratio/2

    local pressed =
       (not self.GrabData and input.IsGrabbing() and ray.HitPos) or
        (self.GrabData and self.GrabData.id == id)


    do
        render.SetMaterial(white_mat)
        white_mat:SetVector("$color", Vector(color.r/255, color.g/255, color.b/255))
        white_mat:SetFloat("$alpha", pressed and 0.25 or ray.HitPos and 0.125 or 1)
        cam.IgnoreZ(true)

        if mdl then
            m:Translate(mdloffset)
            m:Scale(mdlscale)

            --render.SetBlend(pressed and 0.25 or hit_pos and 0.125 or 1)
            render.SetColorModulation(color.r/10, color.g/10, color.b/10)
            temp_model:SetModel(mdl)
            render.MaterialOverride(white_mat)

            temp_model:EnableMatrix("RenderMultiply", m)
            temp_model:SetupBones()
            temp_model:DrawModel()

            render.MaterialOverride()
        else
            local m = m * Matrix()
            m:Scale(-ratio/2)
            cam.PushModelMatrix(m)
                render.SuppressEngineLighting(true)
                box_mesh:Draw()
                render.SuppressEngineLighting(false)
            cam.PopModelMatrix()
        end

        cam.IgnoreZ(false)
    end
end


function META:UpdateGrabbableBox(id, pos, ang, mins, maxs)
    if active_part and self ~= active_part then return end

    local m = self:GetMatrix() * Matrix()
    local ratio = mins - maxs
    m:Translate(LerpVector(0.5, mins, maxs))
    m:Translate(pos)
    m:Rotate(ang)

    -- don't scale the matrix here, since it messes up GetAngles()
    local scale = -ratio/2
    local hit_pos, normal, fraction = util.IntersectRayWithOBB(
        EyePos(),
        camera.GetViewRay() * 32000,
        m:GetTranslation(),
        m:GetAngles(),
        -m:GetScale()*scale,
        m:GetScale()*scale
    )

    debugoverlay.BoxAngles(
        m:GetTranslation(),
        -m:GetScale()*scale,
        m:GetScale()*scale,
        m:GetAngles(),
        0,
        Color(255,0,255,0)
    )

    self.Rays[id] = self.Rays[id] or {}
    self.Rays[id].HitPos = hit_pos
    self.Rays[id].Normal = normal
    self.Rays[id].Fraction = fraction

    local pressed =
       (not self.GrabData and input.IsGrabbing() and hit_pos) or
        (self.GrabData and self.GrabData.id == id)

    if input.IsGrabbing() then
        if hit_pos and not self.GrabData then
            active_part = self
            self.GrabData = {
                id = id,
                hit_pos = hit_pos,
                normal = normal,
                fraction = fraction,
                eye_pos = EyePos(),
                eye_ang = EyeAngles(),
                ray = camera.GetViewRay(),
                world = self:GetMatrix() * Matrix(),
                view = camera.GetViewMatrix(),
            }
        end
    else
        active_part = nil
        self.GrabData = nil
    end

    return pressed and self.GrabData
end

function META:OBBMins()
    return mesh_info(self.Model:GetModel()).min
end

function META:OBBMaxs()
    return mesh_info(self.Model:GetModel()).max
end


local beam = ClientsideModel("models/mechanics/robotics/a1.mdl")
beam:SetNoDraw(true)
function META:RenderBeam(from, to, color)
    local m = self:GetMatrix() * Matrix()
    local dir = (from-to)

    render.SetColorModulation(color.r/255, color.g/255, color.b/255)
    render.MaterialOverride(white_mat)

    m:Translate(-dir/2)
    m:Rotate(dir:Angle())
    m:Scale(Vector(1,0.05,0.05)*(from-to):Length()/15/2)
    beam:EnableMatrix("RenderMultiply", m)
    beam:SetupBones()
    beam:DrawModel()

    render.MaterialOverride()
end

function META:Axis(axis)
    local dir
    if axis == "x" then
        dir = Vector(1,0,0)
    elseif axis == "y" then
        dir = Vector(0,1,0)
    elseif axis == "z" then
        dir = Vector(0,0,1)
    end
    local color = axis == "x" and Color(255,0,0,255) or
    axis == "y" and Color(0,255,0,255) or
    axis == "z" and Color(0,0,255,255)

    local data = self:RenderGrabbableBox(
        dir * -100,

        axis == "x" and Angle(-90,0,0) or
        axis == "y" and Angle(0,0,90) or
        axis == "z" and Angle(0,0,180),

        Vector(1,1,1)*-10, Vector(1,1,1)*10,

        color,
        axis .. " axis",
        "models/hunter/misc/cone1x1.mdl",
        Vector(0,0,-10),
        Vector(1,1,1)*0.45
    )

    self:RenderBeam(Vector(), dir *-100, Color(0,0,0))

    if not data then return end

    local dir1
    local dir2

    if axis == "x" then
        dir1 = data.world:GetForward()
        dir2 = data.world:GetUp()
    elseif axis == "y" then
        dir1 = data.world:GetRight()
        dir2 = data.world:GetForward()
    elseif axis == "z" then
        dir1 = data.world:GetUp()
        dir2 = data.world:GetForward()
    end

    local m = data.world * Matrix()

    local plane_pos = util.IntersectRayWithPlane(
        EyePos(),
        camera.GetViewRay(),
        data.world:GetTranslation(),
        dir2
    )

    if not plane_pos then return end

    local plane_pos2 = util.IntersectRayWithPlane(
        data.eye_pos,
        data.ray,
        data.world:GetTranslation(),
        dir2
    )

    if not plane_pos2 then return end


    local diff = plane_pos - plane_pos2

    m:SetTranslation(
        m:GetTranslation() +
        dir1 * diff:Dot(dir1)
    )

    self:SetWorldMatrix(m)
end


function META:Scale(axis)
    local dir
    if axis == "x" then
        dir = Vector(1,0,0)
    elseif axis == "y" then
        dir = Vector(0,1,0)
    elseif axis == "z" then
        dir = Vector(0,0,1)
    end
    local color = axis == "x" and Color(255,0,0,255) or
    axis == "y" and Color(0,255,0,255) or
    axis == "z" and Color(0,0,255,255)

    local data = self:RenderGrabbableBox(
        dir * -50,

        axis == "x" and Angle(-90,0,0) or
        axis == "y" and Angle(0,0,90) or
        axis == "z" and Angle(0,0,180),

        Vector(1,1,1)*-10, Vector(1,1,1)*10,

        color,
        axis .. " scale axis"
    )

    self:RenderBeam(Vector(), dir *-100, Color(0,0,0))


    if not data then return end


    local dir1
    local dir2

    if axis == "x" then
        dir1 = data.world:GetForward()
        dir2 = data.world:GetUp()
    elseif axis == "y" then
        dir1 = data.world:GetRight()
        dir2 = data.world:GetForward()
    elseif axis == "z" then
        dir1 = data.world:GetUp()
        dir2 = data.world:GetForward()
    end

    local m = data.world * Matrix()

    local plane_pos = util.IntersectRayWithPlane(
        EyePos(),
        camera.GetViewRay(),
        data.world:GetTranslation(),
        dir2
    )

    if not plane_pos then return end

    local plane_pos2 = util.IntersectRayWithPlane(
        data.eye_pos,
        data.ray,
        data.world:GetTranslation(),
        dir2
    )

    if not plane_pos2 then return end


    local diff = plane_pos - plane_pos2

    self:SetLocalScale(Vector(-diff:Dot(dir1)+1,1,1))

    self:SetWorldMatrix(m)
end

function META:CenterGrab()
    local min = self:OBBMins()
    local max = self:OBBMaxs()

    self:RenderGrabbableBox(
        "center",
        Vector(0,0,0),
        mesh_info(self.Model:GetModel()).angle:Forward():Angle(),
        Vector(1,1,1)*-10, Vector(1,1,1)*10,
        Color(255,255,0,100),
        "models/hunter/misc/sphere025x025.mdl",
        Vector(0,0,0),
        Vector(1,1,1)*2
    )
end


function META:UpdateCenterGrab()
    local min = self:OBBMins()
    local max = self:OBBMaxs()

    local data = self:UpdateGrabbableBox(
        "center",
        Vector(0,0,0),
        mesh_info(self.Model:GetModel()).angle:Forward():Angle(),
        Vector(1,1,1)*-10, Vector(1,1,1)*10
    )

    if not data then return end

    local m = data.view:GetInverse() * data.world
    m = camera.GetViewMatrix() * m
    self:SetWorldMatrix(m)


end

function META:UpdateBoundingBox()
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    self:UpdateGrabbableBox(
        "self",
        Vector(0,0,0),
        mesh_info(self.Model:GetModel()).angle:Forward():Angle(),
        mins, maxs
    )
end

function META:RenderBoundingBox()
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    self:RenderGrabbableBox(
        "self",
        Vector(0,0,0),
        mesh_info(self.Model:GetModel()).angle:Forward():Angle(),
        mins, maxs,
        Color(255,0,0,255)
    )
end

function META:RenderCenterGrab()
    self:RenderGrabbableBox(
        "center",
        Vector(0,0,0),
        mesh_info(self.Model:GetModel()).angle:Forward():Angle(),
        Vector(1,1,1)*-10, Vector(1,1,1)*10,
        Color(255,255,0,100),
        "models/hunter/misc/sphere025x025.mdl",
        Vector(0,0,0),
        Vector(1,1,1)*2
    )
end

function META:RenderBoundingBox2()
    local mins, maxs = self.Model:WorldSpaceAABB()

    debugoverlay.BoxAngles(
        Vector(0,0,0),
        mins,
        maxs,
        self:GetMatrix():GetAngles(),
        0,
        Color(255,0,255,0)
    )
end

function META:RenderBoundingBox3()
    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()

    local m = self:GetMatrix() * Matrix()
    local ratio = mins - maxs
    m:Translate(LerpVector(0.5, mins, maxs))
    m:Rotate(mesh_info(self.Model:GetModel()).angle:Forward():Angle())

    local scale = -ratio/2

    debugoverlay.BoxAngles(
        m:GetTranslation(),
        -m:GetScale()*scale,
        m:GetScale()*scale,
        m:GetAngles(),
        0,
        Color(255,0,255,0)
    )
end

function META:GetBoundingBox()
    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()

    local m = self:GetMatrix() * Matrix()
    local ratio = mins - maxs

    m:Translate(LerpVector(0.5, mins, maxs))
    m:Rotate(mesh_info(self.Model:GetModel()).angle:Forward():Angle())

    local scale = -ratio

    local s1 = m:GetScale()*-scale
    local s2 = m:GetScale()*scale

    return
        m:GetTranslation() + s1,
        m:GetTranslation() + s2
end

function META:GetWorldSpaceBoundingBox()
    local root = self:GetRenderList()[1]

    local min = root:GetMatrix():GetTranslation()
    local max = min*1

    for _, child in ipairs(self:GetRenderList()) do
        child:UpdateCenterGrab()

        local min2, max2 = child:GetBoundingBox()

        min.x = math.min(min.x, min2.x)
        min.y = math.min(min.y, min2.y)
        min.z = math.min(min.z, min2.z)


        max.x = math.max(max.x, max2.x)
        max.y = math.max(max.y, max2.y)
        max.z = math.max(max.z, max2.z)
    end

    return min, max
end

function META:GetWorldSpaceCenter()
    return LerpVector(0.5, self:GetWorldSpaceBoundingBox())
end

function META:GetBoundingRadius()
    local min, max = self:GetWorldSpaceBoundingBox()
    return min:Distance(max)/2
end

function META:UpdateRenderBounds()
    local min, max = self:GetWorldSpaceBoundingBox()
    self.Entity:SetRenderBoundsWS(min, max)
end

function META:DrawBounds()
    local min, max = self:GetWorldSpaceBoundingBox()

    debugoverlay.Box(Vector(0,0,0), min, max, 0, Color(255,0,0, 0))
    debugoverlay.Sphere(
        self:GetWorldSpaceCenter(),
        self:GetBoundingRadius(),
        0,
        Color(255,0,0, 0)
    )
end

function META:Update()
    for _, child in ipairs(self:GetUpdateList()) do
        child:UpdateCenterGrab()
        --child:Axis("x")
        --child:Axis("y")
        --child:Axis("z")

        child:UpdateBoundingBox()
    end
end

function META:Render2D()
    for _, child in ipairs(self:GetRenderList()) do
        child:RenderCenterGrab()
        --child:Axis("x")
        --child:Axis("y")
        --child:Axis("z")

        child:RenderBoundingBox()

        ---child:Scale("x")

        --child:RenderGrabbablePlane(cameraRay, grabbing, Angle(0,0,0), Color(255,255,0), "left right")
        --child:RenderGrabbablePlane(cameraRay, grabbing, Angle(-90,0,0), Color(0,255,255), "up right")
        --child:RenderGrabbablePlane(cameraRay, grabbing, Angle(0,0,90), Color(255,0,255), "up forward")

        --child:RenderGrabbableAxis(cameraRay, grabbing, Vector(-1,0,0), Angle(0,0,0), Color(255,0,0), "right")
        --child:RenderGrabbableAxis(cameraRay, grabbing, Vector(0,-1,0), Angle(-90,0,0), Color(0,255,0), "forward")
        --child:RenderGrabbableAxis(cameraRay, grabbing, Vector(0,0,-1), Angle(0,0,90), Color(0,0,255), "up")

    end
end

function pac999.Part(parent, mdl)
    local part = setmetatable({}, META)
    part:Initialize()
    part.Model = ClientsideModel(mdl or "models/props_junk/TrashDumpster01a.mdl")
    part.Model:SetNoDraw(true)

    if parent then
        parent:AddChild(part)
    end
    return part
end

return pac999