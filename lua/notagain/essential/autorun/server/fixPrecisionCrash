local function precisionToolFix()
	local stool = weapons.Get('gmod_tool')
	local swep = stool.Tool['precision']

	if not swep then return end -- If the swep doesn't exist never run.

	swep.OldLeftClick = swep.OldLeftClick or swep.LeftClick
	swep.OldDoConstraint = swep.OldDoConstraint or swep.DoConstraint
	swep.OldDoMove = swep.OldDoMove or swep.DoMove

	function swep:LeftClick(trace)
		local cantool = 0
		local owner = self:GetOwner()
		local mode = self:GetClientNumber( "mode" )

		if mode == 4 then
			cantool = hook.Run("CanTool", owner, owner:GetEyeTrace(), "weld")
		elseif mode == 5 then
			cantool = hook.Run("CanTool", owner, owner:GetEyeTrace(), "axis")
		elseif mode == 6 then
			cantool = hook.Run("CanTool", owner, owner:GetEyeTrace(), "ballsocket")
		elseif mode == 7 then
			cantool = hook.Run("CanTool", owner, owner:GetEyeTrace(), "ballsocket")
		elseif mode == 8 then
			cantool = hook.Run("CanTool", owner, owner:GetEyeTrace(), "slider")
		end

		if cantool == false then
			self:Holster()
		else
			self:OldLeftClick(trace)
		end
	end

	function swep:DoConstraint(mode)
		local hitEnt = self:GetEnt(1)
		constraint.RemoveAll(hitEnt)
		self:OldDoConstraint(mode)
	end

	function swep:DoMove()
		local PhysA, PhysB = self:GetPhys(1), self:GetPhys(2)

		self:OldDoMove()

		PhysA:Sleep()
		PhysB:Sleep()
	end

	weapons.Register(stool,'gmod_tool')

	for _,v in next, ents.FindByClass('gmod_tool') do
	    v:Initialize()
	    v:Activate()
	end
end

hook.Add("PostGamemodeLoaded", "precision_fix", precisionToolFix)
