local m = {}
m.__index = m



m.new = function(mass, stiff, damp, speed)
	local spring = {}
	
	spring.mass		= mass
	spring.stiff	= stiff
	spring.damp		= damp
	spring.speed	= speed
	
	spring.vel		= 0
	spring.pos		= 0
	spring.tpos		= 0
	
	return setmetatable(spring, m)
end



m.update = function(spring, dT)
	if spring.vel <= 0.001 then return spring.pos end
	
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
