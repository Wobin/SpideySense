local HudElementDamageIndicatorSettings =	require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
--local mt = get_mod("modding_tools")
local mod = get_mod("Spidey Sense")
local DLS = get_mod("DarktideLocalServer")
local Color = Color
local Vector3 = Vector3
local Quaternion = Quaternion
local Unit = Unit
local ScriptUnit = ScriptUnit
local Camera = Camera
local Matrix4x4 = Matrix4x4
local Managers = Managers
local Promise = Promise
mod.ui = {}

mod.loadingarrow = false
mod.arrow1_texture = false
mod.arrow2_texture = false

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
            texture_map = mod.arrow1_texture or nil
          },
			offset = {
					0,
					0,
					6
				},
		},
    visibility_function = function (content, style) 
        if not content.target_type then return false end
        if not style.material_values.texture_map then return false end
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
            texture_map = mod.arrow1_texture or nil
          },  
			offset = {
					0,
					0,
					5
				},
		},
    visibility_function = function (content, style) 
        if not content.target_type then return false end
        if not style.material_values.texture_map then return false end
        return mod:get(content.target_type .."_nurgle_blessed") and content.is_nurgled
    end,
	}
}
    
	
  local indicator = UIWidget.create_definition(indicator_definition, "indicator")

  definitions.indicator_definition = indicator 
end)


local arrowpng =  "https://wobin.github.io/SpideySense/images/arrow.png"
local arrow2png = "https://wobin.github.io/SpideySense/images/arrow2.png"

local texture_dir
local load_arrow = function(indicator)  
  if mod.arrow1_texture then indicator.style.arrow.material_values.texture_map = mod.arrow1_texture end
  if mod.arrow2_texture then indicator.style.arrow2.material_values.texture_map = mod.arrow2_texture end

  if mod.arrow1_texture and mod.arrow2_texture then return Promise:new() end
  
  if DLS then    
    texture_dir = texture_dir or DLS.absolute_path("images")
    local arrowpromise =  DLS.get_image(texture_dir .."/arrow.png"):next(function(data) 
        mod.arrow1_texture = data.texture
        indicator.style.arrow.material_values.texture_map = data.texture 
      end) 
    
    local arrow2promise = DLS.get_image(texture_dir .."/arrow2.png"):next(function(data) 
        mod.arrow2_texture = data.texture
        indicator.style.arrow2.material_values.texture_map = data.texture 
      end)
    return Promise.all(arrowpromise, arrow2promise)
  else      
   return Managers.backend:authenticate():next(function()
      Managers.url_loader:load_texture(arrowpng):next(function(data)                  
        mod.arrow1_texture = data.texture
        indicator.style.arrow.material_values.texture_map = data.texture
      end)
      Managers.url_loader:load_texture(arrow2png):next(function(data)          
        mod.arrow2_texture = data.texture
        indicator.style.arrow2.material_values.texture_map = data.texture              
      end)
    end)
  end  
end

local function get_player_direction_angle()
	local player = Managers.player:local_player(1)

	local world_viewport_name = player.viewport_name
    if not world_viewport_name then
        return
    end

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

-- Helper to convert color value to RGB array format
local function get_color_rgb(colourValue, settingName)
  -- Handle new RGB array format {alpha, red, green, blue}
  if type(colourValue) == "table" then
    return colourValue
  end
  
  -- Handle old color name format (string)
  if not colour_check[colourValue] then
    if rawget(Color, colourValue) then      
      colour_check[colourValue] = colourValue
    else
      colour_check[colourValue] = "white"
      mod:echo(mod:localize(settingName .. "_name") .. mod:localize("invalid_colour_setting"))
    end
  end
  return Color[colour_check[colourValue]](255, true)
end

mod.colourCache = function(colourValue, settingName)
  -- Kept for backwards compatibility
  if type(colourValue) == "table" then
    return function(alpha, as_rgb)
      if as_rgb then
        return colourValue
      else
        return {colourValue[1], colourValue[2], colourValue[3], colourValue[4]}
      end
    end
  end
  
  if not colour_check[colourValue] then
    if rawget(Color, colourValue) then      
      colour_check[colourValue] = colourValue
    else
      colour_check[colourValue] = "white"
      mod:echo(mod:localize(settingName .. "_name") .. mod:localize("invalid_colour_setting"))
    end
  end
  return Color[colour_check[colourValue]]
end

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
	
	-- Cache color constants
	local color_yellow = Color["yellow"](255, true)
	local color_lime = Color["lime"](255, true)
  
  
  
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

			-- Use cached colors from indicator
			background_style.color = indicator.back_color
			front_style.color = indicator.front_color
      if indicator.arrow_color then
        arrow_style.color = indicator.arrow_color
      end
      
      if indicator.is_nurgled and indicator.arrow_color then
        arrow2_style.color = indicator.nurgle_color or color_lime
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
	
	-- Cache all colors and settings for this indicator to avoid lookups every frame
	local back_colour = mod:get(target_type .. "_back_colour")
	local back_opacity = mod:get(target_type .. "_back_opacity")
	local front_colour = mod:get(target_type .. "_front_colour")
	local front_opacity = mod:get(target_type .. "_front_opacity")
	local arrow_colour = mod:get(target_type .. "_arrow_colour")
	
	-- Convert colors to RGB arrays once
	local back_color = get_color_rgb(back_colour, target_type)
	back_color[1] = back_opacity
	local front_color = get_color_rgb(front_colour, target_type)
	front_color[1] = front_opacity
	
	local arrow_color = nil
	local nurgle_color = nil
	if arrow_colour then
		arrow_color = get_color_rgb(arrow_colour, target_type)
		-- Calculate nurgle indicator color based on arrow color
		if is_nurgled and arrow_color then
			if arrow_color[3] > arrow_color[2] and arrow_color[3] > arrow_color[4] then
				nurgle_color = Color["yellow"](255, true)
			else
				nurgle_color = Color["lime"](255, true)
			end
		end
	end
	
	mod._indicators[#mod._indicators + 1] = {
		angle = player_angle + angle,
		time = t + duration,
		duration = duration,
		target_type = target_type,
    distance = distance,
    actual_distance = actual_distance,
    is_nurgled = mod:get(target_type .."_nurgle_blessed") and is_nurgled,
    -- Cached colors
    back_color = back_color,
    front_color = front_color,
    arrow_color = arrow_color,
    nurgle_color = nurgle_color
	}
end

local nurgled = setmetatable({}, { __mode = "kv" })
local get_position = mod.ui.get_position
local listener_position_rotation = mod.ui.listener_position_rotation
local show_indicator = mod.ui.show_indicator
local spawn_indicator = mod.ui.spawn_indicator

mod.ui.create_indicator = function(unit_or_position, target_type, extra_duration)	
	
  if not mod.hudElement then return end
  
  local position = get_position(unit_or_position)
  
  -- Cache settings to avoid multiple mod:get() calls
  local max_distance = mod:get(target_type .. "_distance") or 40
  local only_behind = mod:get(target_type .. "_only_behind")
  local active_range = mod:get(target_type .. "_active_range")
  local radius = mod:get(target_type .. "_radius")
  local arrow_distance = mod:get(target_type .. "_arrow_distance")
  local nurgle_blessed = mod:get(target_type .. "_nurgle_blessed")
  
  -- Only check nurgle buffs if the setting is enabled
  if nurgle_blessed then
    local buff_ext = ScriptUnit.extension(unit_or_position, "buff_system")    
    local buffs = buff_ext and buff_ext:buffs()    
    nurgled[unit_or_position] = false
    if buffs then
      for _, buff in ipairs(buffs) do        
        if buff:template_name() == "mutator_minion_nurgle_blessing_tougher" then
          nurgled[unit_or_position] = true
          break
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
  local arrow1_map = mod.hudElement.style.arrow.material_values.texture_map
  local arrow2_map = mod.hudElement.style.arrow2.material_values.texture_map

	local distance = Vector3.distance(position, listener_position)
	if distance < max_distance then
		if not only_behind or (angle > 1.5 or angle < -1.5) then
      local active_distance = active_range and ((distance / max_distance) * 325) - 125 or radius
      if mod.hudElement and 
        ( nurgled[unit_or_position] and not arrow1_map) or 
        ( arrow_distance and not arrow2_map) and 
        not mod.loadingarrow 
      then     
        mod.loadingarrow = true        
        load_arrow(mod.hudElement):next(function() mod.loadingarrow = false end)
      else
        spawn_indicator(angle, target_type, extra_duration, active_distance, distance, nurgled[unit_or_position])
      end			
		end
	end
end

mod.ui.indicate_warning = function(unit_or_position, target_type)
  local position = get_position(unit_or_position)  
  local listener_position = listener_position_rotation()
  local distance = Vector3.distance(position, listener_position)  
  show_indicator(distance, table.unpack(warnings[target_type]))
end
