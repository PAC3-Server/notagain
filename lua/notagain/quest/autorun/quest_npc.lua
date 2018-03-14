local ENT = {
	Base 				  = "base_ai",
	Type 				  = "ai",
	PrintName 			  = "QuestGiver",
	Author 				  = "Earu",
	Contact 			  = "",
	Purpose 			  = "Daily quests for everyone!",
	Instructions 		  = "",
	ms_notouch 		 	  = true,
	IsMSNPC 			  = true,
	RenderGroup			  = RENDERGROUP_BOTH,
	AutomaticFrameAdvance = true,
	Spawnable 			  = false,
}

ENT.Initialize = function(self)
	self:SetModel("models/odessa.mdl")

	if SERVER then
		self:SetHealth(1000)
		self:SetHullType(HULL_HUMAN)
		self:SetHullSizeNormal()
		self:SetSolid(SOLID_BBOX)
		self:SetMoveType(MOVETYPE_STEP)
		self:CapabilitiesAdd(bit.bor(CAP_USE,CAP_ANIMATEDFACE,CAP_TURN_HEAD))
		self:AddEFlags(EFL_NO_DISSOLVE)
		self:SetUseType(SIMPLE_USE)
	end
end

ENT.GetGender = function(self)
	self.Gender = self.Gender or (self:GetModel():lower():find("female",1,true)
		or self:GetModel():lower():find("alyx",1,true)
		and "female" or "male")

	return self.Gender
end

if SERVER then
	util.AddNetworkString("QuestOpenMenu")

	ENT.AcceptInput = function(self,event,activator,caller)
		if Quest then
			local quest = Quest.ActiveQuest
			if event == "Use" then
				local isblacklisted = quest.Blacklist[caller:SteamID()] ~= nil
				local isongoing = quest.Players[caller] ~= nil
				local tasks = {}
				if not isblacklisted then
					for k,v in ipairs(quest.Tasks) do
						table.insert(tasks, {
							Name = v.Description,
							IsFinished = quest.Players[caller] and k < quest.Players[caller] or false,
							OnGoing = quest.Players[caller] and k == quest.Players[caller] or false
						})
					end
				end
				net.Start("QuestOpenMenu")
				net.WriteBool(isblacklisted)
				net.WriteBool(isongoing)
				net.WriteEntity(self)
				net.WriteString(quest.PrintName)
				net.WriteString(quest.Description)
				net.WriteTable(tasks)
				net.Send(caller)
			end
		end

	end

	ENT.PlaySound = function(self,s,a,b,c)
		local now = RealTime()
		if (self.NextTalk or 0) > now then return false end

		self:EmitSound(s,100,math.random(96,104))

		local dur = SoundDuration(s)
		dur = dur and dur > 0 and dur or 0.3

		self.NextTalk = now + dur + 0.3
		return true
	end

	ENT.StopThat = function(self)
		local gender = self:GetGender()
		self:PlaySound("vo/trainyard/" .. gender .. "01/cit_hit0"..math.random(1, 3)..".wav")
	end

	ENT.OverHere = function(self)
		local gender = self:GetGender()
		self:PlaySound("vo/npc/" .. gender .. "01/overhere01.wav")
	end

	ENT.Pssst = function(self)
		self:PlaySound("vo/trainyard/cit_hall_psst.wav")
	end

	ENT.Think = function(self)
		self.CanBeckon = self.CanBeckon == nil and true or self.CanBeckon
		if not self.CanBeckon then return end
		for k,v in pairs(ents.FindInSphere(self:GetPos(),200)) do
			if v:IsPlayer() then
				if math.random(0,1) == 1 then
					self:Pssst()
				else
					self:OverHere()
				end
				self.CanBeckon = false
				timer.Simple(30,function()
					if self:IsValid() then
						self.CanBeckon = true
					end
				end)
			end
		end
	end

	ENT.OnTakeDamage = function(self,dmg)
		local v = dmg:GetAttacker()
		local mdl = self:GetModel()

		self:StopThat()
		if self:IsOnFire() then
			self:Extinguish()
		end

		if not IsValid(v) then return end
		if not v:IsPlayer() then
			v = v.CPPIGetOwneer and v:CPPIGetOwner() or nil
			if not IsValid(v) or not v:IsPlayer() then
				return
			end
		end

		local id = v:UserID()..'pl_lua_npc_kill'
		if timer.Exists(id) then
			return
		end

		timer.Create(id,1,1, function()
			timer.Remove(id)
			if IsValid(v) and v:IsPlayer() then
				if v:Alive() then
					v:EmitSound("ambient/explosions/explode_2.wav")
					v:Kill()

					local ent = v:GetRagdollEntity()

					if not IsValid(ent) then return end
					ent:SetName("dissolvemenao"..tostring(ent:EntIndex()))

					local e=ents.Create'env_entity_dissolver'
					e:SetKeyValue("target","dissolvemenao"..tostring(ent:EntIndex()))
					e:SetKeyValue("dissolvetype","1")
					e:Spawn()
					e:Activate()
					e:Fire("Dissolve",ent:GetName(),0)
					SafeRemoveEntityDelayed(e,0.1)
					if self:IsValid() then
						if MetAchievements and MetaWorks.FireEvent then
							MetaWorks.FireEvent("ms_npcdissolve", v, self, weapon)
						end
					end
				end
			end
		end)

	end

	ENT.RunBehaviour = function(self)
	end
end

if CLIENT then

	ENT.Draw = function(self)
		self:DrawModel()
	end

	ENT.DisplayMenu = function(self,name,desc,tasks,ongoing)
		self.Menu = vgui.Create("QuestMainPanel")
		self.Menu:Setup(self,name,desc,tasks,ongoing)
	end

	net.Receive("QuestOpenMenu",function()
		local blacklisted = net.ReadBool()
		local ongoing = net.ReadBool()
		local ent = net.ReadEntity()
		local questname = net.ReadString()
		local questdesc = net.ReadString()
		local tasks = net.ReadTable()
		if Quest then
			if blacklisted then
				Quest.ShowDialog({"Sorry folk. I have no other quests for you today!",
				"Come back later!"},"Mysterious man")
			else
				if not IsValid(ent.Menu) then
					ent:DisplayMenu(questname,questdesc,tasks,ongoing)
				end
			end
		end
	end)

end

scripted_ents.Register(ENT,"lua_npc_quest")