local mod = get_mod("Spidey Sense")
mod.debugging = {}

mod.debugging.extract_locals = function(level_base)
	local level = level_base
	local res = ""

	while debug.getinfo(level) ~= nil do
		res = string.format("%s\n[%i] ", res, level - level_base + 1)
		local v = 1

		while true do
			local name, value = debug.getlocal(level, v)
			if not name then
				break
			end

			local var = string.format("%s = %s; ", name, value)
			res = res .. var
			v = v + 1
		end

		level = level + 1
	end

	return res
end