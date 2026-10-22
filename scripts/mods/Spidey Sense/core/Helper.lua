local mod = get_mod("Spidey Sense")
mod.helper = {}
mod.helper.get_userdata_type = function (userdata)
	if type(userdata) ~= "userdata" then
		return nil
	end

	local ok, is_unit = pcall(Unit.alive, userdata)
	if ok and is_unit then
		return "Unit"
	end

	local ok_vec, is_vec = pcall(Vector3.is_valid, userdata)
	if ok_vec and is_vec then
		return "Vector3"
	end

	return tostring(userdata)
end