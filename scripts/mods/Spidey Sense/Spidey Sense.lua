--[[
Title: Spidey Sense
Author: Wobin
Date: 13/12/2023
Repository: https://github.com/Wobin/SpideySense
Version: 2.2
--]]

local mod = get_mod("Spidey Sense")
local HudElementDamageIndicatorSettings =
	require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

--[[
local function extract_locals(level_base)
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

--]]


local function get_userdata_type(userdata)
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

local function findlocalvalue(targets)
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
					-- mod:echo("Found " .. targetName .. " at level " .. level .. " : " .. tostring(value))
					return value
				end
			end
			v = v + 1
		end

		level = level + 1
	end
end

local function get_player_direction_angle()
	local player = Managers.player:local_player(1)

	local world_viewport_name = player.viewport_name

	local camera_manager = Managers.state.camera
	local camera = camera_manager:camera(world_viewport_name)

	if not camera then
		return
	end

	local camera_rotation = Camera.local_rotation(camera)
	local camera_forward = Quaternion.forward(camera_rotation)
	camera_forward.z = 0
	camera_forward = Vector3.normalize(camera_forward)
	local camera_right = Vector3.cross(camera_forward, Vector3.up())
	local direction = Vector3.forward()
	local forward_dot_dir = Vector3.dot(camera_forward, direction)
	local right_dot_dir = Vector3.dot(camera_right, -direction)
	local angle = math.atan2(right_dot_dir, forward_dot_dir)

	return angle + math.pi
end

local function listener_position_rotation()
	local player = Managers.player and Managers.player:local_player_safe(1)

	if not player then
		return Vector3.zero(), Quaternion.identity()
	end

	local listener_pose = Managers.state.camera:listener_pose(player.viewport_name)
	local listener_position = listener_pose and Matrix4x4.translation(listener_pose) or Vector3.zero()
	local listener_rotation = listener_pose and Matrix4x4.rotation(listener_pose) or Quaternion.identity()

	return listener_position, listener_rotation
end

mod._indicators = {}

mod:hook_safe("HudElementDamageIndicator", "_draw_indicators", function(self, _dt, t, ui_renderer)
	local indicators = mod._indicators
	local num_indicators = #indicators

	if num_indicators < 1 then
		return
	end

	local widget = self._indicator_widget
	local widget_offset = widget.offset
	local background_style = widget.style.background
	local background_pivot = background_style.pivot
	local front_style = widget.style.front
	local front_pivot = front_style.pivot
	local center_distance = HudElementDamageIndicatorSettings.center_distance
	local pulse_distance = HudElementDamageIndicatorSettings.pulse_distance
	local pulse_speed_multiplier = HudElementDamageIndicatorSettings.pulse_speed_multiplier
	local size = HudElementDamageIndicatorSettings.size
	local player_angle = self:_get_player_direction_angle()

	for i = num_indicators, 1, -1 do
		local indicator = indicators[i]

		if not indicator then
			return
		end

		local time = indicator.time

		if t <= time then
			local duration = indicator.duration
			local progress = (time - t) / duration
			local anim_progress = math.ease_out_exp(1 - progress)
			local hit_progress = math.clamp(anim_progress * pulse_speed_multiplier, 0, 1)
			widget.alpha_multiplier = progress
			local angle = player_angle - indicator.angle
			background_style.angle = angle
			front_style.angle = angle
			background_style.color = Color[mod:get(indicator.target_type .. "_back_colour")](
				mod:get(indicator.target_type .. "_back_opacity"),
				true
			)
			front_style.color = Color[mod:get(indicator.target_type .. "_front_colour")](
				mod:get(indicator.target_type .. "_front_opacity"),
				true
			)
			local distance = center_distance
				+ mod:get(indicator.target_type .. "_radius")
				- (pulse_distance - pulse_distance * hit_progress)
			widget_offset[2] = -distance + size[2] * 0.5
			widget_offset[3] = math.min(i, 50)
			background_pivot[2] = distance
			front_pivot[2] = distance

			UIWidget.draw(widget, ui_renderer)
		else
			table.remove(indicators, i)
		end
	end
end)

function mod:create_indicator(unit_or_position, target_type, extra_duration)
	local input_type = get_userdata_type(unit_or_position)
	local position

	if input_type == "Unit" then
		position = Unit.local_position(unit_or_position, 1) or Vector3.zero()
	elseif input_type == "Vector3" then
		position = unit_or_position
	else
		--mod:echo("Input Type = " .. (input_type and input_type or "nil"))
		--mod:echo("Target Type = " .. (target_type and target_type or "nil"))
		--mod:echo(unit_or_position)
		return
	end

	local listener_position, listener_rotation = listener_position_rotation()
	local direction = position - listener_position
	local directionRotated = Quaternion.rotate(Quaternion.inverse(listener_rotation), direction)
	local directionRotatedNormalized = Vector3.normalize(directionRotated)
	local angle = math.atan2(directionRotatedNormalized.x, directionRotatedNormalized.y)

	local distance = Vector3.distance(position, listener_position)
	if distance < (mod:get(target_type .. "_distance") or 40) then
		if not mod:get(target_type .. "_only_behind") or (angle > 1.5 or angle < -1.5) then
			mod:spawn_indicator(angle, target_type, extra_duration)
		end
	end
end

function mod:spawn_indicator(angle, target_type, extra_duration)
	local t = Managers.ui:get_time()
	local duration = HudElementDamageIndicatorSettings.life_time + (extra_duration or 0)
	local player_angle = get_player_direction_angle()
	self._indicators[#self._indicators + 1] = {
		angle = player_angle + angle,
		time = t + duration,
		duration = duration,
		target_type = target_type,
	}
end

local throttle = {}

function mod:hook_monster(sound_name, unit_or_position)
	--ignore monster spawn
	if sound_name:match("_spawn") then
		return
	end

	-- throttle half a second on each type
	local lastCall = throttle[sound_name] or 0
	local delta = Managers.time:time("main") - lastCall
	if delta < 0.5 then
		return
	end
	throttle[sound_name] = Managers.time:time("main")

	local userDataType = get_userdata_type(unit_or_position)

	-- if the unit_or_position is nil or a number,
	-- try to pull the unit or position from higher in the callstack
	if userDataType ~= "Unit" and userDataType ~= "Vector3" then
		unit_or_position = findlocalvalue({
			{ "attacking_unit", "Unit" },
			{ "position", "Vector3" },
			{ "parent_unit", "Unit" },
			{ "unit", "Unit" },
		})
	end

	if unit_or_position == nil then
		return
	end

	local breed_name = ""
	if sound_name:match("footsteps") then
		local unit_data_extension = ScriptUnit.extension(unit_or_position, "unit_data_system")
		local breed = unit_data_extension and unit_data_extension:breed()
		breed_name = breed and breed.name or ""
	end

	if mod:get("backstab_active") and sound_name:match("wwise/events/player/play_backstab_indicator") then
		mod:create_indicator(unit_or_position, "backstab")		
	end

	if mod:get("burster_active")
		and (
			sound_name:match("wwise/events/minions/play_minion_poxwalker_bomber")
			or sound_name:match("wwise/events/minions/play_enemy_combat_poxwalker_bomber")
		)
	then mod:create_indicator(unit_or_position, "burster") end
	if mod:get("hound_active")
		and (
			sound_name:match("wwise/events/minions/play_enemy_chaos_hound")
			or sound_name:match("wwise/events/minions/play_fly_swarm")
		)
	then mod:create_indicator(unit_or_position, "hound") end

	if mod:get("mutant_active") and sound_name:match("wwise/events/minions/play_enemy_mutant_charger") then
		mod:create_indicator(unit_or_position, "mutant")
	end
  
	if mod:get("trapper_active")
		and (
			sound_name:match("wwise/events/minions/play_netgunner_run_foley_special")
			or sound_name:match("wwise/events/minions/play_netgunner_reload")
		)
	then mod:create_indicator(unit_or_position, "trapper") end
  
	if mod:get("sniper_active")
		and (
			sound_name:match("wwise/events/weapon/play_combat_weapon_las_sniper")
			or sound_name:match("wwise/events/weapon/play_special_sniper_flash")
			or (breed_name:match("sniper") and sound_name:match("wwise/events/minions/play_netgunner"))
		)
	then
		mod:create_indicator(unit_or_position, "sniper") end
    
	if mod:get("grenadier_active")
		and (breed_name:match("grenadier") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier"))
	then mod:create_indicator(unit_or_position, "grenadier") end
  
	if mod:get("barrel_active") and sound_name:match("wwise/events/weapon/play_explosion_fuse") then
		mod:create_indicator(unit_or_position, "barrel", 3)
	end
  
	if mod:get("flamer_active")
		and (
			sound_name:match("wwise/events/minions/play_enemy_cultist_flamer_foley_tank")
			or sound_name:match("wwise/events/weapon/play_aoe_liquid_fire_loop")
			or sound_name:match("wwise/events/minions/play_cultist_flamer_foley_gas_loop")
			or sound_name:match("wwise/events/weapon/play_minion_flamethrower_green_wind_up")
			or sound_name:match("wwise/events/weapon/play_minion_flamethrower_start")
			or (breed_name:match("flamer") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier"))
		)
	then mod:create_indicator(unit_or_position, "flamer")	end
  
  if mod:get("crusher_active")
    and (
       sound_name:match("wwise/events/minions/play_enemy_chaos_ogryn_armoured_executor_a__special_attack_vce")      
     or sound_name:match("wwise/events/minions/play_enemy_chaos_ogryn_armoured_executor_a__running_breath_vce")      
    )
  then mod:create_indicator(unit_or_position, "crusher") end
  if mod:get("mauler_active")
    and (
      (breed_name:match("renegade_executor") and sound_name:match("wwise/events/minions/play_shared_foley_traitor_guard_heavy_run"))
      or sound_name:match("wwise/events/minions/play_shared_elite_executor_cleave_warning")
      )
  then mod:create_indicator(unit_or_position, "mauler") end
end

local hooked_sounds = {
	"wwise/events/minions/play_enemy_mutant_charger",
	"wwise/events/minions/play_netgunner_footsteps",
	"wwise/events/minions/play_netgunner_run_foley_special",
	"wwise/events/minions/play_netgunner_reload",
	"wwise/events/minions/play_enemy_chaos_hound",
	"wwise/events/minions/play_fly_swarm",
	"wwise/events/minions/play_minion_poxwalker_bomber",
	"wwise/events/minions/play_enemy_combat_poxwalker_bomber",
	"wwise/events/player/play_backstab_indicator",
	"wwise/events/weapon/play_special_sniper_flash",
	"wwise/events/weapon/play_combat_weapon_las_sniper",
	"wwise/events/minions/play_traitor_guard_grenadier",
	"wwise/events/weapon/play_explosion_fuse",
	"wwise/events/minions/play_enemy_cultist_flamer_foley_tank",
	"wwise/events/weapon/play_aoe_liquid_fire_loop",
	"wwise/events/weapon/play_minion_flamethrower_green_wind_up",
	"wwise/events/minions/play_cultist_flamer_foley_gas_loop",
	"wwise/events/weapon/play_minion_flamethrower_start",
  "wwise/events/minions/play_enemy_chaos_ogryn_armoured_executor_a__running_breath_vce",
  "wwise/events/minions/play_enemy_chaos_ogryn_armoured_executor_a__special_attack_vce",
  "wwise/events/minions/play_shared_foley_traitor_guard_heavy_run",
  "wwise/events/minions/play_shared_elite_executor_cleave_warning"
}

mod:hook_safe(WwiseWorld, "trigger_resource_event", function(_wwise_world, wwise_event_name, unit_or_position_or_id)
	for _, sound_name in ipairs(hooked_sounds) do
		if wwise_event_name:match(sound_name) then
			mod:hook_monster(wwise_event_name, unit_or_position_or_id)
			return
		end
	end
end)
