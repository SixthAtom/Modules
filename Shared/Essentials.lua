local m = {}

m.weld = function(model, p0)
	if not p0 then p0 = model.PrimaryPart or nil end
	assert(p0 ~= nil, 'No P0')
	
	local welds = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA('BasePart') or p:IsA('Wedge') and not p == p0 then
			
			local w 	= Instance.new('Weld')
			w.Part0 	= p0
			w.Part1 	= p

			w.Name 		= p0.Name..'-'..p.Name
			w.Parent	= p0
			
			w.C0		= p0.CFrame:ToObjectSpace(p.CFrame)
			p.Anchored 	= false
			
			table.insert(welds, w)
		end
	end
	
	p0.Anchored = false
	return welds
end



m.deepClone = function(tab)
	local rt = {}
	
	for i, v in pairs(tab) do
		if type(v) == 'table' then
			rt[i] = m.deepClone(v)
		else
			rt[i] = v
		end
	end
	
	return rt
end



m.inrange = function(p0, p1, distance, incly)
	local xd = math.abs(p0.X - p1.X)
	local zd = math.abs(p0.Z - p1.Z)
	
	if incly then
		local yd = math.abs(p0.Y - p1.Y)
		return xd <= distance and yd <= distance and zd <= distance
	end
	
	return xd <= distance and zd <= distance
end







return m
