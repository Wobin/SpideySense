--[[
Title: Spidey Sense
Author: Wobin
Date: 09/12/2023
Repository: https://github.com/Wobin/SpideySense
Version: 1.2.2
--]]

local mod = get_mod("Spidey Sense")
local HudElementDamageIndicatorSettings = require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local HEDI = CLASS.HudElementDamageIndicator

local Audio
local incomingIndicators = {}

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



local get_userdata_type = function(userdata)
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

local _get_player_direction_angle = function()

  local player =  Managers.player:local_player(1)  

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


local listener_position_rotation = function()
	local player = Managers.player and Managers.player:local_player_safe(1)

	if not player then
		return Vector3.zero(), Quaternion.identity()
	end

	local listener_pose = Managers.state.camera:listener_pose(player.viewport_name)
	local lister_position = listener_pose and Matrix4x4.translation(listener_pose) or Vector3.zero()
	local lister_rotation = listener_pose and Matrix4x4.rotation(listener_pose) or Quaternion.identity()

	return lister_position, lister_rotation
end


mod._indicators = incomingIndicators

mod:hook_safe(HEDI, "_draw_indicators", function (self, dt, t, ui_renderer)  
	local indicators = incomingIndicators
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
			local attack_result = indicator.attack_result
      background_style.color = Color[mod:get(indicator.target_type.."_back_colour")](mod:get(indicator.target_type.."_back_opacity"), true)
      front_style.color = Color[mod:get(indicator.target_type.."_front_colour")](mod:get(indicator.target_type.."_front_opacity"), true)      
			local distance = center_distance + mod:get(indicator.target_type.."_radius") - (pulse_distance - pulse_distance * hit_progress)
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

mod.create_indicator = function(self, unit_or_position, target_type)
    local input_type = get_userdata_type(unit_or_position)
    local position
    
    if input_type == "Unit" then
      position = Unit.local_position(unit_or_position, 1) or Vector3.zero()
    elseif input_type == "Vector3" then
      position = unit_or_position
    end
    local listener_position, listener_rotation = listener_position_rotation()    
    local direction = position - listener_position
    local directionRotated = Quaternion.rotate(Quaternion.inverse(listener_rotation), direction)
    local directionRotatedNormalized = Vector3.normalize(directionRotated)
    local angle = math.atan2(directionRotatedNormalized.x, directionRotatedNormalized.y)    
    
    local distance = Vector3.distance(position, listener_position)        
    if distance < mod:get(target_type .. "_distance") or 40 then      
      if not mod:get(target_type .. "_only_behind") or (angle > 1.5 or angle < -1.5) then
        mod:spawn_indicator(angle, target_type)
      end
    end
    
end

mod.spawn_indicator = function (self, angle, target_type)
	local t = Managers.ui:get_time()
	local duration = HudElementDamageIndicatorSettings.life_time
	local player_angle = _get_player_direction_angle()
	self._indicators[#self._indicators + 1] = {
		angle = player_angle + angle,
		time = t + duration,
		duration = duration,		
    target_type = target_type
	}
end

local getlocal = debug.getlocal

mod.hook_monster = function(sound_type, sound_name, delta, unit)
  if delta ~= nil and delta < 0.04 then return end
  if sound_type == "source_sound" or sound_type == "3d_sound"  then 
    local name, value = getlocal(4, 2)  
    if (sound_type == "source_sound" and name == "unit") or (sound_type == "3d_sound" and name == "event_name") then
      if get_userdata_type(value) or name == "event_name" then
        if mod:get("mutant_active") and sound_name:match("wwise/events/minions/play_enemy_mutant_charger") then
          mod:create_indicator(value, "mutant")
        end
        if mod:get("trapper_active") and sound_name:match("wwise/events/minions/play_netgunner") then
          mod:create_indicator(value, "trapper")
        end  
        if mod:get("hound_active") and (sound_name:match("wwise/events/minions/play_enemy_chaos_hound") or sound_name:match("wwise/events/minions/play_fly_swarm")) then
          mod:create_indicator(value, "hound")
        end  
        if mod:get("burster_active") and (sound_name:match("wwise/events/minions/play_minion_poxwalker_bomber") or sound_name:match("wwise/events/minions/play_enemy_combat_poxwalker_bomber")) then
          mod:create_indicator(value, "burster")
        end  
        if mod:get("backstab_active") and sound_name:match("wwise/events/player/play_backstab_indicator_melee") then
          mod:create_indicator(unit, "backstab")
        end
        if mod:get("sniper_active") and sound_name:match("wwise/events/weapon/play_special_sniper_flash") then
          mod:create_indicator(value, "sniper")
        end
        if mod:get("grenadier_active") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier") then                     
          mod:create_indicator(value, "grenadier")
        end
      end
    end
  end
end

mod.on_all_mods_loaded = function()
 Audio = get_mod("Audio")    
 
 Audio.hook_sound("wwise/events/minions/play_enemy_mutant_charger", mod.hook_monster)
 Audio.hook_sound("wwise/events/minions/play_netgunner", mod.hook_monster)
 Audio.hook_sound("wwise/events/minions/play_enemy_chaos_hound", mod.hook_monster)
 Audio.hook_sound("wwise/events/minions/play_fly_swarm", mod.hook_monster)
 Audio.hook_sound("wwise/events/minions/play_minion_poxwalker_bomber", mod.hook_monster) 
 Audio.hook_sound("wwise/events/minions/play_enemy_combat_poxwalker_bomber", mod.hook_monster)
 Audio.hook_sound("wwise/events/player/play_backstab_indicator_melee", mod.hook_monster)
 Audio.hook_sound("wwise/events/weapon/play_special_sniper_flash", mod.hook_monster)
 Audio.hook_sound("wwise/events/minions/play_traitor_guard_grenadier", mod.hook_monster)
 
 
end