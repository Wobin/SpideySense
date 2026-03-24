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
mod.ui.default_warning_font = "proxima_nova_light"
mod.ui._healed_settings = mod.ui._healed_settings or {}
mod.ui._target_settings_cache = mod.ui._target_settings_cache or {}
mod.ui._warning_settings_cache = mod.ui._warning_settings_cache or {}
mod.ui._default_color_name_cache = mod.ui._default_color_name_cache or {}
mod.ui._default_color_rgb_cache = mod.ui._default_color_rgb_cache or {}
mod.ui.warning_expiry = mod.ui.warning_expiry or {}

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

local healed_settings = mod.ui._healed_settings
local target_settings_cache = mod.ui._target_settings_cache
local warning_settings_cache = mod.ui._warning_settings_cache
local default_color_name_cache = mod.ui._default_color_name_cache
local default_color_rgb_cache = mod.ui._default_color_rgb_cache
local warning_expiry = mod.ui.warning_expiry
local get_target_settings

-- Warning flag mapping for backwards compatibility
local warning_flag_by_indicate = {
  Cleave = "showCleave",
  Net = "showNet",
  Charge = "showCharge",
  Shot = "showShot",
  Pounce = "showPounce",
  Sniper = "showSniper",
}

local function get_main_time()
  local time_manager = Managers and Managers.time
  return time_manager and time_manager:time("main") or 0
end

local function heal_setting_once(setting_id, value)
  if type(setting_id) ~= "string" or healed_settings[setting_id] then
    return
  end

  mod:set(setting_id, value, false)
  healed_settings[setting_id] = true
end

local function get_numeric_setting(setting_id, fallback_value)
  local value = mod:get(setting_id)
  if type(value) == "number" then
    return value
  end

  heal_setting_once(setting_id, fallback_value)
  return fallback_value
end

local function clear_cache(cache)
  for key in pairs(cache) do
    cache[key] = nil
  end
end

local function set_warning_flag(indicate, active)
  local flag = warning_flag_by_indicate[indicate]
  if flag then
    mod[flag] = active == true
  end
end

mod.ui.is_warning_visible = function(indicate)
  return (warning_expiry[indicate] or 0) > get_main_time()
end

mod.ui.invalidate_setting_caches = function(setting_id)
  if type(setting_id) == "string" then
    healed_settings[setting_id] = nil
    default_color_name_cache[setting_id] = nil
    default_color_rgb_cache[setting_id] = nil
  else
    clear_cache(healed_settings)
    clear_cache(default_color_name_cache)
    clear_cache(default_color_rgb_cache)
  end

  clear_cache(target_settings_cache)
  clear_cache(warning_settings_cache)
end

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
        local target_settings = content.target_type and get_target_settings and get_target_settings(content.target_type) or nil
        local alert = target_settings and target_settings.arrow_distance or nil
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
    local target_settings = content.target_type and get_target_settings and get_target_settings(content.target_type) or nil
    return target_settings and target_settings.nurgle_blessed and content.is_nurgled
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
  local settings = warning_settings_cache[attacker]
  if not settings then
    settings = {
      range_max = get_numeric_setting(attacker .. "_range_max", 10),
    }
    warning_settings_cache[attacker] = settings
  end

  if distance < settings.range_max then
    warning_expiry[indicate] = math.max(warning_expiry[indicate] or 0, get_main_time() + (delay or 0))
    set_warning_flag(indicate, true)
  end
end


mod:hook_safe("HudElementDamageIndicator", "init", function(self)
  mod.hudElement = self._indicator_widget   
end)

local colour_check = {}

local function get_default_color_name(setting_id)
  if type(setting_id) ~= "string" then
    return "white"
  end

  local cached_name = default_color_name_cache[setting_id]
  if cached_name then
    return cached_name
  end

  if setting_id:match("^font_colour_") then
    default_color_name_cache[setting_id] = "ui_terminal"
    return "ui_terminal"
  end

  local enemy_type, color_slot = string.match(setting_id, "^(.-)_(front|back|arrow)_colour$")
  local defaults = mod.ui and mod.ui.default_colors
  local enemy_defaults = defaults and enemy_type and defaults[enemy_type]

  if enemy_defaults and enemy_defaults[color_slot] then
    default_color_name_cache[setting_id] = enemy_defaults[color_slot]
    return enemy_defaults[color_slot]
  end

  default_color_name_cache[setting_id] = "white"
  return "white"
end

local function get_default_color_rgb(setting_id)
  local cached_rgb = default_color_rgb_cache[setting_id]
  if cached_rgb then
    return cached_rgb, get_default_color_name(setting_id)
  end

  local fallback_name = get_default_color_name(setting_id)
  local fallback_color = Color[fallback_name] and Color[fallback_name](255, true) or Color.white(255, true)

  default_color_rgb_cache[setting_id] = fallback_color

  return fallback_color, fallback_name
end

local function persist_fallback_color(setting_id, color_rgb)
  if type(setting_id) == "string" and setting_id:match("_colour$") and type(color_rgb) == "table" then
    heal_setting_once(setting_id, color_rgb)
  end
end

local function echo_color_fallback(setting_id, colour_value, fallback_name)
  local setting_label = setting_id
  if type(setting_id) == "string" then
    setting_label = mod:localize(setting_id .. "_name") or setting_id
  end

  local reason
  if colour_value == nil then
    reason = " was missing"
  elseif colour_value == "" then
    reason = " was empty"
  elseif type(colour_value) ~= "string" then
    reason = " had unsupported type " .. type(colour_value)
  else
    reason = " used unknown color '" .. tostring(colour_value) .. "'"
  end

  mod:echo(setting_label .. reason .. "; falling back to default color '" .. tostring(fallback_name) .. "'.")
end

get_target_settings = function(target_type)
  local settings = target_settings_cache[target_type]
  if settings then
    return settings
  end

  settings = {
    max_distance = get_numeric_setting(target_type .. "_distance", 40),
    only_behind = mod:get(target_type .. "_only_behind"),
    active_range = mod:get(target_type .. "_active_range"),
    radius = get_numeric_setting(target_type .. "_radius", 50),
    arrow_distance = get_numeric_setting(target_type .. "_arrow_distance", 0),
    nurgle_blessed = mod:get(target_type .. "_nurgle_blessed"),
    back_colour = mod:get(target_type .. "_back_colour"),
    back_opacity = get_numeric_setting(target_type .. "_back_opacity", 255),
    front_colour = mod:get(target_type .. "_front_colour"),
    front_opacity = get_numeric_setting(target_type .. "_front_opacity", 255),
    arrow_colour = mod:get(target_type .. "_arrow_colour"),
  }

  target_settings_cache[target_type] = settings

  return settings
end

mod.ui.get_target_settings = get_target_settings

local function is_silent_missing_color(colour_value)
  return colour_value == nil or colour_value == ""
end

-- Helper to convert color value to RGB array format
local function get_color_rgb(colourValue, settingName)
  -- Handle new RGB array format {alpha, red, green, blue}
  if type(colourValue) == "table" then
    return colourValue
  end

  if type(colourValue) ~= "string" or colourValue == "" then
    local fallback_rgb, fallback_name = get_default_color_rgb(settingName)
    persist_fallback_color(settingName, fallback_rgb)
    if not is_silent_missing_color(colourValue) then
      echo_color_fallback(settingName, colourValue, fallback_name)
    end

    return fallback_rgb
  end
  
  -- Handle old color name format (string)
  if not colour_check[colourValue] then
    if rawget(Color, colourValue) then      
      colour_check[colourValue] = colourValue
    else
      local fallback_rgb, fallback_name = get_default_color_rgb(settingName)
      colour_check[colourValue] = fallback_name
      persist_fallback_color(settingName, fallback_rgb)
      echo_color_fallback(settingName, colourValue, fallback_name)
    end
  end
  return Color[colour_check[colourValue]](255, true)
end

local function sanitize_color_with_alpha(color_value, alpha_value)
  local color = type(color_value) == "table" and color_value or Color.white(255, true)
  local alpha = type(alpha_value) == "number" and alpha_value or 255
  local red = type(color[2]) == "number" and color[2] or 255
  local green = type(color[3]) == "number" and color[3] or 255
  local blue = type(color[4]) == "number" and color[4] or 255

  return {
    alpha,
    red,
    green,
    blue,
  }
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

  if type(colourValue) ~= "string" or colourValue == "" then
    local fallback_rgb, fallback_name = get_default_color_rgb(settingName)
    persist_fallback_color(settingName, fallback_rgb)
    if settingName and not is_silent_missing_color(colourValue) then
      echo_color_fallback(settingName, colourValue, fallback_name)
    end
    return function(alpha, as_rgb)
      if as_rgb then
        return fallback_rgb
      else
        return { fallback_rgb[1], fallback_rgb[2], fallback_rgb[3], fallback_rgb[4] }
      end
    end
  end
  
  if not colour_check[colourValue] then
    if rawget(Color, colourValue) then      
      colour_check[colourValue] = colourValue
    else
      local fallback_rgb, fallback_name = get_default_color_rgb(settingName)
      colour_check[colourValue] = fallback_name
      persist_fallback_color(settingName, fallback_rgb)
      echo_color_fallback(settingName, colourValue, fallback_name)
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
  local settings = get_target_settings(target_type)
	
	-- Cache all colors and settings for this indicator to avoid lookups every frame
  local back_colour = settings.back_colour
  local back_opacity = settings.back_opacity
  local front_colour = settings.front_colour
  local front_opacity = settings.front_opacity
  local arrow_colour = settings.arrow_colour
	
	-- Convert colors to RGB arrays once
  local back_color = sanitize_color_with_alpha(get_color_rgb(back_colour, target_type .. "_back_colour"), back_opacity)
  local front_color = sanitize_color_with_alpha(get_color_rgb(front_colour, target_type .. "_front_colour"), front_opacity)
	
	local arrow_color = nil
	local nurgle_color = nil
	if arrow_colour then
    arrow_color = get_color_rgb(arrow_colour, target_type .. "_arrow_colour")
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
    is_nurgled = settings.nurgle_blessed and is_nurgled,
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
	local settings = get_target_settings(target_type)
  
  -- Only check nurgle buffs if the setting is enabled
  if settings.nurgle_blessed then
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
	if distance < settings.max_distance then
		if not settings.only_behind or (angle > 1.5 or angle < -1.5) then
      local active_distance = settings.active_range and math.max(0, (distance / settings.max_distance) * 325 - 125) or settings.radius
      if mod.hudElement and 
        ( nurgled[unit_or_position] and not arrow1_map) or 
        ( settings.arrow_distance and not arrow2_map) and 
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
  local w = warnings[target_type]
  show_indicator(distance, w[1], w[2], w[3])
end
