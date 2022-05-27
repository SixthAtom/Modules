local m				= {}
m.__index			= m
m.retryInterval			= 5



local ser 		 	= {}
ser.tps			 	= game:GetService("TeleportService")
ser.plrs		 	= game:GetService("Players")



m.create = function( placeID, serverData )

	local server		= {}
	server.placeID		= placeID
	server.data		= serverData

	local code, id		= ser.tps:ReserveServer(placeID)
	server.joinCode		= code
	server.joinID		= id

	return setmetatable(server, m)

end



m.join = function(server, plrs)
	if type(plrs) ~= 'table' then
		plrs = {plrs}
	end



	for _, plr in ipairs(plrs) do
		coroutine.wrap(function()
			local s

			repeat
				s = pcall(function()
					local data = server.data

					ser.tps:TeleportToPrivateServer(
						server.placeID,
						server.joinCode,
						{plr},
						nil,
						data
					)
				end)

				task.wait(m.retryInterval)
			until not ser.plrs:IsAncestorOf(plr) and not s

		end)()
	end
end



return m
