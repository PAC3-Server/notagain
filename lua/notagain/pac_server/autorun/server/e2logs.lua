local timer = timer

local function wait(callback)
    timer.Simple(FrameTime(), function()
        callback()
    end)
end

local function killExpression(ent, no_remove)
    for _,v in next, ents.FindByClass("gmod_wire_expression2") do
        if IsValid(v) and v:GetPlayer() == ent then
            v:PCallHook('destruct')
            for x,_ in next, v.context.data.spawnedProps do
                SafeRemoveEntity(x)
            end
            if not no_remove then SafeRemoveEntity(v) end
        end
    end
end

aowl.AddCommand("dele2=player,boolean[0]", function(ply, line, ent, no_remove)
    killExpression(ent, no_remove)
end, "developers")

hook.Add("OnEntityCreated", "e2log", function(ent)
    wait(function()
        if IsValid(ent) and ent:GetClass() == "gmod_wire_expression2" then

            local Context = ent.ResetContext

            function ent:ResetContext()
                wait(function()
                    if not IsValid(self) then return end

                    local owner = self:GetPlayer()

                    local name = self.directives.name
                    local context = self.context

                    local weight = type(self.script) == "table" and self.script[2] or 0
                    local cpu = math.floor( weight + ( context.timebench*1000000 ) )

                    local data = context.data
                    local holos = #data.holos
                    local props = data.spawnedProps and #data.spawnedProps or 0
                    local sounds = #data.sound_data.sounds

                    Msg("[E2] ")
                    print( string.format("%s(%s) compiled E2(%s) [CPU:%sus|h%sp%ss%s]",
                        owner:Nick(), owner:SteamID(), name, cpu, holos, props, sounds) )
                end)

                return Context(self)
            end

        end
    end)
end)
