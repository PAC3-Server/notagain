aowl.AddCommand("votekick=player,string[bye]",function(ply,line,ent,reason)
    if cleanup and cleanup.CC_Cleanup then
      cleanup.CC_Cleanup(ent,"gmod_cleanup",{})
    end
    
    if votes then
      votes.Create(ply:Nick().." wants to kick "..ent:Nick(),30,{"yes","no"},function(votes)
        if votes[1] == "yes" then
          ent:Kick("kicked by "..ply:Nick())
        end
      end
    end
end)
    
aowl.AddCommand("vote=string[vote],number[60],string", function(ply, line, str,num,...)  
            if votes then
                votes.Create(str,num,{...})
                if votes.IsOnGoing() then
                    gamemode.Call("PlayerButtonUp",ply,num+1)
                end
            end
end)
            
