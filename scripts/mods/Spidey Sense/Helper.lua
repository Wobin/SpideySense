local mod = get_mod("Spidey Sense")
mod.helper = {}
mod.helper.get_userdata_type = function (userdata)
	if type(userdata) ~= "userdata" then
		return nil
	end

	if Unit.alive(userdata) then
		return "Unit"
	elseif Vector3.is_valid(userdata) then
		return "Vector3"
	else
		return tostring(userdata)
	end
end

local get_userdata_type = mod.helper.get_userdata_type

mod.helper.findlocalvalue = function(targets)
	local level = 1

	while debug.getinfo(level) ~= nil do
		local v = 1

		while true do
			local name, value = debug.getlocal(level, v)

			if not name then
				break
			end

			for _, target in ipairs(targets) do
				local targetName = target[1]
				local targetUserdataType = target[2]
        
        if name == targetName and get_userdata_type(value) == targetUserdataType then		          
					return value
				end
			end
			v = v + 1
		end

		level = level + 1
	end
end