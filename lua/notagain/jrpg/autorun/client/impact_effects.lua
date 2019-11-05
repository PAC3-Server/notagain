local jfx = requirex("jfx")
local draw_line = requirex("draw_line")

do

    local glyph_disc = jfx.CreateMaterial({
        Shader = "UnlitGeneric",

        BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/disc.png",
        VertexColor = 1,
        VertexAlpha = 1,
    })

    local ring = jfx.CreateMaterial({
        Shader = "UnlitGeneric",

        BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/ring2.png",
        Additive = 0,
        VertexColor = 1,
        VertexAlpha = 1,
    })

    local hand = jfx.CreateMaterial({
        Shader = "UnlitGeneric",

        BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/clock_hand.png",
        Additive = 0,
        VertexColor = 1,
        VertexAlpha = 1,
        BaseTextureTransform = "center .5 .5 scale 1 5 rotate 0 translate 0 1.25",
    })

    local glow = jfx.CreateMaterial({
        Shader = "UnlitGeneric",

        BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/glow.png",
        Additive = 1,
        VertexColor = 1,
        VertexAlpha = 1,
    })

    local glow2 = jfx.CreateMaterial({
        Shader = "UnlitGeneric",

        BaseTexture = "sprites/light_glow02",
        Additive = 1,
        VertexColor = 1,
        VertexAlpha = 1,
        Translucent = 1,
    })

    local META = {}
    META.Name = "impact_effect"

    function META:Initialize()
        self.pixvis = util.GetPixelVisibleHandle()

        self.color = self.color or Color(255, 217, 104, 255)
        self.size = self.size or 0.6
        self.something = self.something or 1

        self.dlight = DynamicLight( 0 )
        self.dlight.DieTime = 99999

    end

    function META:DrawSprites(time, f, f2)
        local s = self.size*1.5
        local c = Color(self.color.r^1.15, self.color.g^1.15, self.color.b^1.15)
        c.a = 255

        local dark =  Color(0,0,0,c.a)

        cam.Start3D(EyePos(), EyeAngles())

            local pos = self.position

            render.SetMaterial(glow2)
            render.DrawQuadEasy(pos, Vector(0,0,1), 420*s, 420*s, c, 45)

            render.SetMaterial(glow)
            render.DrawQuadEasy(self.position, -EyeVector(), 10*s, 10*s, c, -45)

            render.SetMaterial(glow2)
            render.DrawQuadEasy(self.position, -EyeVector(), 220*s, 220*s, c, 45)

        cam.End3D()
    end

    function META:DrawGlow(time, f, f2)
        local s = self.size
        local c = Color(self.color.r, self.color.g, self.color.b)
        c.a = 20*f2*self.visible

        cam.Start3D(EyePos(), EyeAngles())
        cam.IgnoreZ(true)
            render.SetMaterial(glow)
            local size = 500*s
            render.DrawSprite(self.position, size, size, c)
        cam.IgnoreZ(false)
        cam.End3D()
    end

    function META:DrawRefraction(time, f, f2)
        local s = self.size
        local c = Color(self.color.r, self.color.g, self.color.b)
        c.a = 100*f2*self.something

        cam.Start3D(EyePos(), EyeAngles())
            render.SetMaterial(jfx.materials.refract)
            render.DrawQuadEasy(self.position, -EyeVector(), 128*s, 128*s, c, f*45)
        cam.End3D()
    end

    function META:DrawRefraction2(time, f, f2)
        local s = self.size
        local c = Color(self.color.r, self.color.g, self.color.b)
        c.a = (self.something*100)*f2

        cam.Start3D(EyePos(), EyeAngles())
            render.SetMaterial(jfx.materials.refract2)
            render.DrawQuadEasy(self.position, -EyeVector(), 130*s, 130*s, c, f*45)
        cam.End3D()
    end

    function META:DrawSunbeams(time, f, f2)
        local s = self.size
        local pos = self.position
        local screen_pos = pos:ToScreen()

        DrawSunbeams(0, (f2*self.visible*0.05)*self.something, 30 * (1/pos:Distance(EyePos()))*s, screen_pos.x / ScrW(), screen_pos.y / ScrH())
    end

    function META:DrawTranslucent(time, f, f2)
        self.position = self.pos

        self.visible = util.PixelVisible(self.position, 50, self.pixvis)
        self:DrawSprites(time, f, f2)

        self:DrawGlow(time, f, f2)
        self:DrawSunbeams(time, f, f2)
    end

    function META:DrawOpaque(time, f, f2)
        self.position = self.pos

        self:DrawRefraction2(time, f, f2)

        local dlight = self.dlight
        if dlight then
            dlight.pos = self.position
            dlight.r = self.color.r
            dlight.g = self.color.g
            dlight.b = self.color.b
            dlight.Brightness = 2
            dlight.Decay = 1
            dlight.Size = self.size*300
        end
    end

    function META:OnRemove()
        self.dlight.Decay = 0
        self.dlight.DieTime = 0
    end

    jfx.RegisterEffect(META)
end

local function think(p)
    local f = math.Clamp(-(p:GetLifeTime() / p:GetDieTime())+1, 0, 1)

    local vel = p:GetVelocity() + (Vector(jfx.GetRandomOffset(p:GetPos(), p:GetRoll(), 0.04)) * 10)
    p:SetVelocity(vel)

    local l = (vel:Length()/10) + 1

    p:SetStartLength(l)
    p:SetEndLength(-l)

    p:SetNextThink(CurTime())
end

local materials = {
    "particle/particle_glow_05",
    "particle/fire",
    "particle/Particle_Glow_04_Additive",
}

function jrpg.ImpactEffect(pos, normal, dir, f, color)
    if jfx.emitter:GetNumActiveParticles() > 500 then return end

    local h = color and (ColorToHSV(color) / 360) or 20/360

    jfx.CreateEffect("impact_effect", {
        color = Color(jfx.HSV2RGB(h+math.Rand(-0.03,0.03), math.Rand(0.25, 0.75)^2, 1)),
        size = 0.1*f,
        something = 0,
        length = 0.1*f,
        pos = pos,
    })

    local t = CurTime()
    local gravity = physenv.GetGravity()


    for i = 1, math.random(100*f,200*f) do
        local p = jfx.emitter:Add(materials[math.random(1, #materials)], pos)

        local r,g,b = jfx.HSV2RGB(h+math.Rand(-0.05,0.05), math.Rand(0.25, 0.75)^2, 1)
        p:SetColor(r, g, b)
        p:SetNextThink(t)
        p:SetThinkFunction(think)

        p:SetDieTime((math.Rand(0.5, 1)^10)*3*f)
        p:SetLifeTime(0)

        local size = math.max((math.Rand(5,7)^0.25)*f, 1)
        p:SetStartSize(size)
        p:SetEndSize(size)

        p:SetStartAlpha(255)
        p:SetEndAlpha(0)
        p:SetCollide(true)
        p:SetBounce(1)
        p:SetRoll(i)

        p:SetAirResistance(math.Rand(100,500))
        p:SetVelocity((VectorRand()*(math.Rand(0.5, 1)^5)*100 + normal*100 * math.Rand(1,4)) * f)
        p:SetGravity(gravity*math.Rand(0.2,0.3))
    end
end