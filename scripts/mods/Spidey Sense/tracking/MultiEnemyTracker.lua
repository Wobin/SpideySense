local mod = get_mod("Spidey Sense")

mod.multi_enemy_tracker = {}
local tracker = mod.multi_enemy_tracker

tracker.active_instances = {}

tracker.breed_counts = {}

tracker.unit_numbers = {}

tracker.numbers_in_use = {}

function tracker:register_unit(unit, breed_name)
	if not unit or not breed_name then
		return
	end

	if not self.active_instances[breed_name] then
		self.active_instances[breed_name] = {}
		self.unit_numbers[breed_name] = {}
		self.numbers_in_use[breed_name] = {}
	end

	local instances = self.active_instances[breed_name]
	local unit_numbers = self.unit_numbers[breed_name]
	local numbers_in_use = self.numbers_in_use[breed_name]

	for _, tracked_unit in ipairs(instances) do
		if tracked_unit == unit then
			return
		end
	end

	local instance_number = nil
	for num = 1, 15 do
		if not numbers_in_use[num] then
			instance_number = num
			break
		end
	end

	if not instance_number then
		return
	end

	unit_numbers[unit] = instance_number
	numbers_in_use[instance_number] = true

	table.insert(instances, unit)
end

function tracker:update()
	for breed_name, instances in pairs(self.active_instances) do
		local unit_numbers = self.unit_numbers[breed_name]
		local numbers_in_use = self.numbers_in_use[breed_name]
		local i = 1
		while i <= #instances do
			local unit = instances[i]

			if self:is_unit_valid(unit) then
				i = i + 1
			else
				local freed_number = unit_numbers[unit]
				table.remove(instances, i)
				unit_numbers[unit] = nil
				
				if freed_number then
					numbers_in_use[freed_number] = nil
				end
			end
		end

		self.breed_counts[breed_name] = #instances

		if #instances == 0 then
			self.active_instances[breed_name] = nil
			self.breed_counts[breed_name] = nil
			self.unit_numbers[breed_name] = nil
			self.numbers_in_use[breed_name] = nil
		end
	end
end

function tracker:is_unit_valid(unit)
	if not unit or type(unit) ~= "userdata" then
		return false
	end

	if not Unit.alive(unit) then
		return false
	end

	local unit_data_ext = ScriptUnit.extension(unit, "unit_data_system")
	if not unit_data_ext then
		return false
	end

	local health_ext = ScriptUnit.extension(unit, "health_system")
	if health_ext and health_ext:current_health() <= 0 then
		return false
	end

	return true
end

function tracker:get_count(breed_name)
	return self.breed_counts[breed_name] or 0
end

function tracker:get_instance_number(unit, breed_name)
	if not breed_name or not self.unit_numbers[breed_name] then
		return nil
	end

	return self.unit_numbers[breed_name][unit]
end

return tracker
