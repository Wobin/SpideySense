local HudElementDamageIndicatorSettings =	require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local mod = get_mod("Spidey Sense")
local DLS = get_mod("DarktideLocalServer")
local Color = Color
mod.ui = {}

local warnings = {}
warnings["cleave"] = { "crusher", "Cleave", 2 }
warnings["trap"] = { "trapper", "Net", 2 }
warnings["charge"] = { "pogryn", "Charge", 3 }
warnings["shot"] = {"shotgun", "Shot", 1}
warnings["pounce"] = {"hound", "Pounce", 1}
warnings["sniper"] = {"sniper", "Sniper", 1}

mod.ui.loadWarnings = function()
  mod:register_hud_element({
    class_name = "SpideySenseUINetWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/UI/Warnings/NetWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUICleaveWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/UI/Warnings/CleaveWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUIChargeWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/UI/Warnings/ChargeWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })

  mod:register_hud_element({
    class_name = "SpideySenseUIShotWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/UI/Warnings/ShotWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUIPounceWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/UI/Warnings/PounceWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUISniperWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/UI/Warnings/SniperWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
end
mod:hook_require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_definitions", function(definitions)
    
    local center_distance = HudElementDamageIndicatorSettings.center_distance
    local size = HudElementDamageIndicatorSettings.size
    local indicator_definition = {
	{
		value = "content/ui/materials/hud/damage_indicators/hit_indicator_bg",
		style_id = "background",
		pass_type = "rotated_texture",
		style = {
			angle = 0,
			pivot = {
				size[1] * 0.5,
				center_distance
			},
			color = UIHudSettings.color_tint_alert_3
		}
	},
	{
		value = "content/ui/materials/hud/damage_indicators/hit_indicator_fg",
		style_id = "front",
		pass_type = "rotated_texture",
		style = {
			angle = 0,
			pivot = {
				size[1] * 0.5,
				center_distance
			},
			color = UIHudSettings.color_tint_alert_1,
			offset = {
				0,
				0,
				1
			}
		}
	},
  {		
    texture = nil,
    size = size,
		style_id = "arrow",
		pass_type = "rotated_texture",
    vertical_alignment = "center",
				horizontal_alignment = "center",
		style = {
			angle = 0,
			pivot = {
				size[1] * 0.5,
				center_distance
			},
			color = Color["black"](255,true),
      material_values = {
            texture_map = nil
          },
			offset = {
					0,
					0,
					6
				},
		},
    visibility_function = function (content) 
        if not content.target_type then return false end
        local alert = content.target_type and mod:get(content.target_type .."_arrow_distance") or nil
                return (content.distance and alert) and
                (alert > 0 and
                content.distance < alert or false) 
                or false
                end,
	},
  {		
    texture = nil,
    size = size,
		style_id = "arrow2",
		pass_type = "rotated_texture",
    vertical_alignment = "center",
				horizontal_alignment = "center",
		style = {
      size = size,
			angle = 0,
			pivot = {
				size[1] * 0.5,
				center_distance
			},
			color = UIHudSettings.ui_hud_green_super_light,
       material_values = {
            texture_map = nil
          },  
			offset = {
					0,
					0,
					5
				},
		},
    visibility_function = function (content) 
        if not content.target_type then return false end
        return mod:get(content.target_type .."_nurgle_blessed") and content.is_nurgled
    end,
	}
}
    
	
  local indicator = UIWidget.create_definition(indicator_definition, "indicator")

  definitions.indicator_definition = indicator 
end)


local arrowpng =  "https://wobin.github.io/SpideySense/images/arrow.png"
local arrow2png = "https://wobin.github.io/SpideySense/images/arrow2.png"

local load_arrow = function(indicator)
  if DLS then
    local texture_dir = DLS.absolute_path("images")
    local arrowpromise =  DLS.get_image(texture_dir .."/arrow.png"):next(function(data) indicator.style.arrow.material_values.texture_map = data.texture end)
    local arrow2promise = DLS.get_image(texture_dir .."/arrow2.png"):next(function(data) indicator.style.arrow2.material_values.texture_map = data.texture end)
    return Promise.all(arrowpromise, arrow2promise)
  else  
   return Managers.backend:authenticate():next(function()
      Managers.url_loader:load_texture(arrowpng):next(function(data)                  
        indicator.style.arrow.material_values.texture_map = data.texture
      end)
      Managers.url_loader:load_texture(arrow2png):next(function(data)          
        indicator.style.arrow2.material_values.texture_map = data.texture              
      end)
    end)
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

mod.ui.listener_position_rotation = function()
	local player = Managers.player and Managers.player:local_player_safe(1)

	if not player then
		return Vector3.zero(), Quaternion.identity()
	end

	local listener_pose = Managers.state.camera:listener_pose(player.viewport_name)
	local listener_position = listener_pose and Matrix4x4.translation(listener_pose) or Vector3.zero()
	local listener_rotation = listener_pose and Matrix4x4.rotation(listener_pose) or Quaternion.identity()

	return listener_position, listener_rotation
end

local get_userdata_type = mod.helper.get_userdata_type

mod.ui.get_position = function(unit_or_position)
   local input_type = get_userdata_type(unit_or_position)
	local position

	if input_type == "Unit" then
		position = Unit.local_position(unit_or_position, 1) or Vector3.zero()
	elseif input_type == "Vector3" then
		position = unit_or_position
	else
		return
	end
  return position
end

mod.ui.show_indicator = function(distance, attacker, indicate, delay)        
  local maxRange = mod:get(attacker .."_range_max") or 1000000 
    if distance < maxRange then 
      mod["show"..indicate] = true    
      Promise.delay(delay):next(function() 
          mod["show"..indicate] = false 
      end)
    end
end


mod:hook_safe("HudElementDamageIndicator", "init", function(self)
  mod.hudElement = self._indicator_widget 
end)

local colour_check = {}

mod.colourCache = function(colourName, settingName)
  if not colour_check[colourName] then
    if rawget(Color, colourName) then      
      colour_check[colourName] = colourName
    else
      colour_check[colourName] = "white"
      mod:echo(mod:localize(settingName .. "_name") .. mod:localize("invalid_colour_setting"))
    end
  end
  return Color[colour_check[colourName]]
end

local colourCache = mod.colourCache

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
  local arrow_style = widget.style.arrow
  local arrow2_style = widget.style.arrow2
  local arrow_pivot = arrow_style.pivot
  local arrow2_pivot = arrow2_style.pivot
  
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
			local angle = player_angle - indicator.angle      
			background_style.angle = angle
			front_style.angle = angle
      arrow_style.angle = angle
      arrow2_style.angle = angle
      widget.alpha_multiplier = progress

			background_style.color = colourCache(mod:get(indicator.target_type .. "_back_colour"), indicator.target_type)(
				mod:get(indicator.target_type .. "_back_opacity"),
				true
			)
			front_style.color = colourCache(mod:get(indicator.target_type .. "_front_colour"), indicator.target_type)(
				mod:get(indicator.target_type .. "_front_opacity"),
				true
			)
      if mod:get(indicator.target_type .. "_arrow_colour") then
        arrow_style.color = colourCache(mod:get(indicator.target_type .. "_arrow_colour"), indicator.target_type)(255,true)
      end
      
      if indicator.is_nurgled and arrow_style.color then
        if arrow_style.color[3] > arrow_style.color[2] and arrow_style.color[3] > arrow_style.color[4] then
          arrow2_style.color = Color["yellow"](255, true)
        else
          arrow2_style.color = Color["lime"](255, true)
        end
      end
      
      
			local distance = center_distance
				+ (indicator.distance and indicator.distance or 0)
				- (pulse_distance - pulse_distance * hit_progress)
        
			widget_offset[2] = -distance + size[2] * 0.5
			widget_offset[3] = math.min(i, 50)
			background_pivot[2] = distance
			front_pivot[2] = distance
      arrow_pivot[2] = distance
      arrow2_pivot[2] = distance
    
      widget.content.distance = indicator.actual_distance or nil
      widget.content.target_type = indicator.target_type
      widget.content.is_nurgled = indicator.is_nurgled
			UIWidget.draw(widget, ui_renderer) 
		else
			table.remove(indicators, i)
		end
	end
end)

mod.ui.spawn_indicator = function(angle, target_type, extra_duration, distance, actual_distance, is_nurgled)
	local t = Managers.ui:get_time()
	local duration = HudElementDamageIndicatorSettings.life_time + (extra_duration or 0)
	local player_angle = get_player_direction_angle()
	mod._indicators[#mod._indicators + 1] = {
		angle = player_angle + angle,
		time = t + duration,
		duration = duration,
		target_type = target_type,
    distance = distance,
    actual_distance = actual_distance,
    is_nurgled = mod:get(target_type .."_nurgle_blessed") and is_nurgled
	}
end

local nurgled = {}
local get_position = mod.ui.get_position
local listener_position_rotation = mod.ui.listener_position_rotation
local show_indicator = mod.ui.show_indicator
local spawn_indicator = mod.ui.spawn_indicator

mod.ui.create_indicator = function(unit_or_position, target_type, extra_duration)	
	local position = get_position(unit_or_position)
  
  if mod:get(target_type .."_nurgle_blessed") then
    local buff_ext = ScriptUnit.extension(unit_or_position, "buff_system")    
    local buffs = buff_ext and buff_ext:buffs()    
    nurgled[unit_or_position] = false
    if buffs then
      for _, buff in ipairs(buffs) do        
        if buff:template_name() == "mutator_minion_nurgle_blessing_tougher" then
          nurgled[unit_or_position] = true
        end
      end    
    end
  else
    nurgled[unit_or_position] = false
  end
  
  local listener_position, listener_rotation = listener_position_rotation()
	local direction = position - listener_position
	local directionRotated = Quaternion.rotate(Quaternion.inverse(listener_rotation), direction)
	local directionRotatedNormalized = Vector3.normalize(directionRotated)
	local angle = math.atan2(directionRotatedNormalized.x, directionRotatedNormalized.y)

	local distance = Vector3.distance(position, listener_position)
	if distance < (mod:get(target_type .. "_distance") or 40) then
		if not mod:get(target_type .. "_only_behind") or (angle > 1.5 or angle < -1.5) then
      local active_distance = mod:get(target_type .. "_active_range") and ((distance / mod:get(target_type .. "_distance")) * 325) - 125
          or mod:get(target_type .."_radius")            
      if mod.hudElement and (not mod.hudElement.style.arrow.material_values.texture_map or not mod.hudElement.style.arrow2.material_values.texture_map) then
        load_arrow(mod.hudElement):next(
          function() spawn_indicator(angle, target_type, extra_duration, active_distance, distance, nurgled[unit_or_position]) end)
      else
        spawn_indicator(angle, target_type, extra_duration, active_distance, distance, nurgled[unit_or_position])
      end			
		end
	end
end

mod.ui.indicate_warning = function(unit_or_position, target_type)
  local position = get_position(unit_or_position)  
	local listener_position, listener_rotation = listener_position_rotation()
 	local distance = Vector3.distance(position, listener_position)  
  show_indicator(distance, unpack(warnings[target_type]))
end
