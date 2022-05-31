local ser 			= {}
ser.pfs				= game:GetService("PathfindingService")
ser.plrs			= game:GetService("Players")
ser.repst			= game:GetService("ReplicatedStorage")
ser.runser			= game:GetService("RunService")

local mod			= {}
mod.essentials		= require(ser.repst.Modules.Shared.Essentials)



local m 			= {}
m.__index			= m

m.refreshSpeed		= .5
m.scanSpeed			= .1



local monsters		= {}



--// main function

m.new = function( object, paths, agent)
	
	local rcParams = RaycastParams.new()
	rcParams.FilterType = Enum.RaycastFilterType.Blacklist
	rcParams.FilterDescendantsInstances = {object}
	
	local activeBool 	= object.Configuration.Active
	
	
	
	local ai			= {}
	
	--// constants
	ai.pathsFolder		= paths
	ai.object			= object
	ai.agent			= agent
	ai.rcParams			= rcParams
	ai.index			= #monsters + 1
		
	--// variables - change via SCRIPT EXCEPT FOR ACTIVEBOOL.VALUE
	ai.range			= 200
	ai.chaserange		= 30
	
	ai.walkspeed		= 20
	ai.chasewalkspeed	= 24
	
	ai.rcOffset			= Vector3.new()
	
	
	
	--// Script Values
	ai.paths			= nil
	ai.path				= nil
	ai.idlepath			= nil
	ai.pindex			= nil
	ai.iindex			= nil -- idle index, when this number is reached the AI no longer is "walkingtoidle"
	ai.nopaths			= 0
	
	ai.target			= nil
	ai.lasttargetpos	= nil
	ai.lastobjectpos	= nil
	
	ai.chase			= false
	ai.active 			= activeBool.Value
	ai.idle				= false
	
	
	
	local meta = {
		__index = function(s, i)
			return rawget(ai, i) or rawget(m, i)
		end,
		
		__newindex = function(s, i, v)
			if i == 'active' then
				activeBool.Value = v
			end
			
			rawset(ai, i, v)
		end,
	}
	
	
	
	--local meta			= setmetatable(ai, m)
	local meta				= setmetatable({}, meta)
	
	
	
	object.Destroying:Connect(function()
		monsters[meta.index] = nil
	end)

	activeBool:GetPropertyChangedSignal("Value"):Connect(function()
		meta.active = activeBool.Value
	end)
	
	
	
	monsters[meta.index] = meta
	return meta
	
end





--// ai class functions

m.compilePaths = function(ai)
	
	local generated 	= {}
	local paths 		= ai.pathsFolder:GetChildren()
	
	for _, path in ipairs(paths) do
		local compiled = {}
		
		for i = 1, #path:GetChildren() do
			local wp = path[i]
			local prevwp = i > 1 and path:FindFirstChild(i-1)
			
			local s, e
			
			
			
			if prevwp then
				local p = ser.pfs:CreatePath(ai.agent)
				
				s, e = pcall(function()
					p:ComputeAsync(prevwp.Position, wp.Position)
				end)
				
				
				
				if s and p.Status == Enum.PathStatus.Success then
					local waypoints = p:GetWaypoints()
					
					for x = 1, #waypoints do
						--compiled[i + x - 2] = waypoints[x]
						table.insert(compiled, waypoints[x])
					end
					
					--compiled[i-1] = p
				end
			end
		end
		
		table.insert(generated, {name = path.Name, paths = compiled})
	end
	
	print(ai.object.Name..' paths: ', generated)
	ai.paths = generated
	return generated
	
end



m.getClosestVisibleCharacter = function(ai)
	
	local checkchase 	= true
	local v3 			= Vector3.new(1, 1, 1) * ai.range
	local r3			= Region3.new( ai.object.PrimaryPart.Position - v3, ai.object.PrimaryPart.Position + v3 )
	
	local pps			= {} -- character primaryparts
	local chars			= {}
	
	
	
	for _, p in ipairs(ser.plrs:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild('Humanoid') and p.Character.Humanoid.Health > 0 then
			pps[#pps+1] = p.Character.PrimaryPart
		end
	end
	
	
	
	if workspace:FindFirstChild('Fakes') then
		for _, p in ipairs(workspace.Fakes:GetChildren()) do
			pps[#pps+1] = p.PrimaryPart
		end
	end
	
	
	
	
	
	if #pps > 0 then
		for _, pp in ipairs( workspace:FindPartsInRegion3WithWhiteList(r3, pps, #pps) ) do
			chars[#chars+1] = pp.Parent
		end
	end
	
	
	
	table.sort(chars, function(a, b)
		return (a.PrimaryPart.Position - b.PrimaryPart.Position).Magnitude > (b.PrimaryPart.Position - a.PrimaryPart.Position).Magnitude
	end)
	
	
	
	for _, char in ipairs(chars) do
		local origin = ai.object.PrimaryPart.Position + ai.rcOffset
		
		local result = workspace:Raycast(
			origin,
			(char.PrimaryPart.Position - origin).Unit * ai.range,
			ai.rcParams
		)
		
		if result then
			if char:IsAncestorOf(result.Instance) then
				
				if mod.essentials.inrange( origin, char.PrimaryPart.Position, ai.chaserange, true ) then
					return char, true
				end
				
				return char, false
			end
		end
	end
	
	return nil, false
end



m.reachedTarget = function(ai)
	if ai.target then
		if mod.essentials.inrange(ai.object.PrimaryPart.Position, ai.target.PrimaryPart.Position, 4, true) then
			return true
		end
		
	end
	
	return false
end









-- Ai Loops

coroutine.wrap(function()
	-- This loop will take care
	-- of checking if the target has been
	-- reached.
	
	while true do
		for _, ai in pairs(monsters) do
			
			if ai.active then
				--print(ai.walkingtoidle, ai.path, ai.toidlepath)
				
				if ai.target then
					
					ai.object.Humanoid:MoveTo( ai.target.PrimaryPart.Position)
					if mod.essentials.inrange( ai.object.PrimaryPart.Position, ai.target.PrimaryPart.Position, 4, true ) then
						ai.target = nil
					end
					
				elseif ai.lasttargetpos then
					
					ai.object.Humanoid:MoveTo( ai.lasttargetpos )
					if mod.essentials.inrange( ai.object.PrimaryPart.Position, ai.lasttargetpos, 4, true) then
						ai.lasttargetpos = nil
					end
					
				elseif not ai.idlepath and ai.idle then
					
					local path = ser.pfs:CreatePath(ai.agent)
					local s, e = pcall(function()
						path:ComputeAsync( ai.object.PrimaryPart.Position, ai.path[ai.pindex].Position )
					end)
					
					if not s or path.Status ~= Enum.PathStatus.Success then
						warn(ai.path, ai.pindex, #ai.path)
					end

					print(s, e, path.Status)
					if s and path.Status == Enum.PathStatus.Success then
						ai.idlepath 	= {}
						ai.iindex 		= 1
						ai.nopaths 		= 0
						
						local wps = path:GetWaypoints()

						for _, wp in ipairs(path:GetWaypoints()) do
							table.insert(ai.idlepath, wp)
						end
					elseif path.Status == Enum.PathStatus.NoPath then
						ai.nopaths += 1
						if ai.nopaths >= 5 then
							if ai.path then
								if ai.pindex == #ai.path then
									ai.path = nil
								else
									ai.object:SetPrimaryPartCFrame( CFrame.new(ai.path[ai.pindex].Position) )
									ai.nopaths = 0
								end
							end
						end
					end
					
					
				elseif ai.idlepath and ai.iindex <= #ai.idlepath and ai.path then
					
					ai.object.Humanoid:MoveTo( ai.idlepath[ai.iindex].Position )
					if mod.essentials.inrange(ai.object.PrimaryPart.Position, ai.idlepath[ai.iindex].Position, 6, true) then
						
						ai.iindex += 1
						
					end
					
				elseif ai.idle and ai.path then
					
					ai.object.Humanoid:MoveTo( ai.path[ai.pindex].Position )
					if mod.essentials.inrange(ai.object.PrimaryPart.Position, ai.path[ai.pindex].Position, 6, true) then
						
						ai.path 			= ai.path[ai.pindex+1] ~= nil and ai.path or nil
						ai.pindex 			= ai.path ~= nil and ai.pindex + 1 or 1
						
						--[[ai.pindex 			= ai.path ~= nil and ai.pindex + 1 or function()
							ai.pindex = 1
							ai.path = ai.paths[ math.random(1, #ai.paths) ].paths
							ai.object:SetPrimaryPartCFrame( CFrame.new( ai.path[ai.pindex].Position ) )
						end]]
					end
					
				end
			end
			
		end
		
		task.wait(m.scanSpeed)
	end
	
end)()



coroutine.wrap(function()
	-- This loop will take care
	-- of handling the target.
	
	while true do
		
		for _, ai in pairs(monsters) do
			
			if ai.active then
				ai.target, ai.chase = ai:getClosestVisibleCharacter()
				ai.object.Humanoid.WalkSpeed = ai.chase and ai.chasewalkspeed or ai.walkspeed
				
				if ai.target then
					ai.lasttargetpos, ai.idle = ai.target.PrimaryPart.Position, false
				else
					if ai.lasttargetpos then
						if mod.essentials.inrange( ai.object.PrimaryPart.Position, ai.lasttargetpos, 5, true) then
							ai.target, ai.chase, ai.lasttargetpos = nil
						end
					end
				end
				
				
				if ai.lastobjectpos then
					if mod.essentials.inrange( ai.object.PrimaryPart.Position, ai.lastobjectpos, .5, true ) then
						ai.target, ai.idle, ai.chase, ai.lasttargetpos = nil, false, false, nil
					end
				end
				
				ai.lastobjectpos = ai.object.PrimaryPart.Position
				
				
				
				if not ai.target and not ai.chase and not ai.lasttargetpos and not ai.idle or not ai.path then
					ai.idle 			= true
					ai.pindex			= ai.path == nil and 1 or ai.pindex
					ai.path 			= ai.path ~= nil and ai.path or ai.paths[ math.random(1, #ai.paths) ].paths
					ai.idlepath			= nil
					ai.iindex			= nil
				end
			end
			
		end
		
		task.wait(m.refreshSpeed)
	end
	
end)()



return m