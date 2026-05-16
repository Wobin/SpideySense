--[[
MultiEnemyTracker
Tracks multiple instances of the same enemy breed within detection range
Assigns sequential numbers (1-15) to each instance based on detection order
Numbers are rendered as roman numerals (I-XV) via texture overlay system
--]]

local mod = get_mod("Spidey Sense")

mod.multi_enemy_tracker = {}
local tracker = mod.multi_enemy_tracker

-- Store active instances per breed
-- tracker.active_instances[breed_name] = { unit1, unit2, ... }
tracker.active_instances = {}

-- Store the count of active instances per breed
-- tracker.breed_counts[breed_name] = count
tracker.breed_counts = {}

-- Store persistent instance numbers per unit per breed
-- tracker.unit_numbers[breed_name][unit] = instance_number (1-15)
tracker.unit_numbers = {}

-- Track which numbers are currently in use per breed
-- tracker.numbers_in_use[breed_name][number] = true/false (1-15)
tracker.numbers_in_use = {}

-- Store spawn time for each unit to maintain ordering info (for reference)
-- tracker.unit_spawn_times[unit] = spawn_time
local unit_spawn_times = setmetatable({}, { __mode = "kv" })

--[[
Register a unit as detected for a given breed
Called from create_indicator() when an enemy is detected
Assigns a persistent instance number (1-15) that stays with the unit
Uses the lowest available number that isn't currently assigned
Supports full roman numeral range I-XV for texture rendering
--]]
function tracker:register_unit(unit, breed_name)
	if not unit or not breed_name then
		return
	end

	-- Initialize breed list if needed
	if not self.active_instances[breed_name] then
		self.active_instances[breed_name] = {}
		self.unit_numbers[breed_name] = {}
		self.numbers_in_use[breed_name] = {}
	end

	local instances = self.active_instances[breed_name]
	local unit_numbers = self.unit_numbers[breed_name]
	local numbers_in_use = self.numbers_in_use[breed_name]

	-- Check if unit already tracked for this breed
	for _, tracked_unit in ipairs(instances) do
		if tracked_unit == unit then
			return  -- Already registered
		end
	end

	-- Find the lowest available number (1-15) that isn't currently in use
	-- Supports display up to XV (15) in dual-slot roman numeral rendering
	local instance_number = nil
	for num = 1, 15 do
		if not numbers_in_use[num] then
			instance_number = num
			break
		end
	end

	-- If all numbers 1-15 are in use, don't register (cap at 15 per breed)
	if not instance_number then
		return
	end

	-- Assign the number to this unit
	unit_numbers[unit] = instance_number
	numbers_in_use[instance_number] = true
	unit_spawn_times[unit] = Managers.time:time("main")

	-- Register new unit
	table.insert(instances, unit)
end

--[[
Update the tracker - validate units are still alive, remove dead units
Called once per frame from main mod update loop
--]]
function tracker:update()
	local main_time = Managers.time and Managers.time:time("main") or 0

	-- Check each breed's unit list
	for breed_name, instances in pairs(self.active_instances) do
		local unit_numbers = self.unit_numbers[breed_name]
		local numbers_in_use = self.numbers_in_use[breed_name]
		local i = 1
		while i <= #instances do
			local unit = instances[i]

			-- Validate unit is still alive and valid
			if self:is_unit_valid(unit) then
				i = i + 1
			else
				-- Unit died - remove it and free up its number
				local freed_number = unit_numbers[unit]
				table.remove(instances, i)
				unit_numbers[unit] = nil
				
				-- Mark this number as available again
				if freed_number then
					numbers_in_use[freed_number] = nil
				end
			end
		end

		-- Update count for this breed
		self.breed_counts[breed_name] = #instances

		-- Clean up empty breed lists
		if #instances == 0 then
			self.active_instances[breed_name] = nil
			self.breed_counts[breed_name] = nil
			self.unit_numbers[breed_name] = nil
			self.numbers_in_use[breed_name] = nil
		end
	end
end

--[[
Check if a unit is valid (still alive, not destroyed)
--]]
function tracker:is_unit_valid(unit)
	if not unit then
		return false
	end

	-- Check if unit is a valid userdata type
	if type(unit) ~= "userdata" then
		return false
	end

	-- Check if unit exists in world
	local unit_data_ext = ScriptUnit.extension(unit, "unit_data_system")
	if not unit_data_ext then
		return false
	end

	-- Check if unit is alive (has health)
	local health_ext = ScriptUnit.extension(unit, "health_system")
	if health_ext and health_ext:current_health() <= 0 then
		return false
	end

	return true
end

--[[
Get count of active instances for a breed
Returns the number of tracked units for the given breed (0 if none)
--]]
function tracker:get_count(breed_name)
	return self.breed_counts[breed_name] or 0
end

--[[
Get the instance number (1-15) for a specific unit within its breed
Returns the persistent number assigned to this unit on first registration
Rendered as roman numerals I-XV in indicator textures
Returns nil if unit not tracked for this breed
--]]
function tracker:get_instance_number(unit, breed_name)
	if not breed_name or not self.unit_numbers[breed_name] then
		return nil
	end

	return self.unit_numbers[breed_name][unit]
end

--[[
Get total count for a unit's breed
Combines with get_instance_number for complete tracking info
--]]
function tracker:get_breed_info(unit, breed_name)
	local instance_num = self:get_instance_number(unit, breed_name)
	local total_count = self:get_count(breed_name)

	if instance_num then
		return {
			instance_number = instance_num,
			total_in_breed = total_count
		}
	end

	return nil
end

--[[
Clear all tracking data (called on mod unload or reset)
--]]
function tracker:clear()
	self.active_instances = {}
	self.breed_counts = {}
	self.unit_numbers = {}
	self.numbers_in_use = {}
	-- Clear weak table by iteration (safe approach)
	for unit in pairs(unit_spawn_times) do
		unit_spawn_times[unit] = nil
	end
end

return tracker
