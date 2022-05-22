local m = {}
m.__index = m



m.new = function(mass, stiff, damp, speed)
	local spring = {}
	
	spring.mass		= mass
	spring.stiff	= stiff
	spring.damp		= damp
	spring.speed	= speed
	
	spring.vel		= Vector3.new()
	spring.pos		= Vector3.new()
	spring.tpos		= Vector3.new()
	
	return setmetatable(spring, m)
end



m.update = function(spring, dT)
	--if spring.vel.Magnitude <= 0.001 then return spring.pos end
	dT 					= math.min(0.1, dT) * spring.speed
	
	local dx			= spring.tpos - spring.pos
	local force			= spring.stiff * dx
	local acceleration 	= force / spring.mass
	
	spring.vel			+= acceleration * dT - spring.vel * spring.damp
	spring.pos			+= spring.vel * dT
	
	return spring.pos
end



m.impulse = function(spring, impulseForce)
	spring.vel += impulseForce/spring.mass
end



return m