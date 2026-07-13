local HudElementDamageIndicatorSettings =	require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local mod = get_mod("Spidey Sense")
local widget_definitions = mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/ui/widget_definitions")
local SimpleAssets = get_mod("SimpleAssets")
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
mod.ui.default_colors = mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/core/Colours")
mod.ui._target_settings_cache = mod.ui._target_settings_cache or {}
mod.ui._warning_settings_cache = mod.ui._warning_settings_cache or {}
mod.ui._default_color_name_cache = mod.ui._default_color_name_cache or {}
mod.ui._default_color_rgb_cache = mod.ui._default_color_rgb_cache or {}
mod.ui.warning_expiry = mod.ui.warning_expiry or {}

local NUMERAL_RADIUS = HudElementDamageIndicatorSettings.center_distance + 10

local NUMERAL_PAIR_SPACING = 28

local COMPOSITE_COUNTS = {
  [6] = true, [7] = true, [8] = true, [9] = true,
  [11] = true, [12] = true, [13] = true, [14] = true, [15] = true,
}

local COMPOSITE_EXTRA_PADDING = {
  [7]  = 6,
  [8]  = 12,
  [12] = 6,
  [13] = 12,
  [14] = 12,
}

local NUMERAL_STYLE_NUDGE = {
  roman_numeral_10  = { 10, 2},
  roman_numeral_10b = { 10, 2 },
}

local NUMERAL_STYLE_IDS = {
  "roman_numeral", "roman_numeral_2", "roman_numeral_3",
  "roman_numeral_4", "roman_numeral_5", "roman_numeral_10",
  "roman_numeral_1b", "roman_numeral_2b", "roman_numeral_3b",
  "roman_numeral_4b", "roman_numeral_5b", "roman_numeral_10b",
}

local STYLES_BY_COUNT = {}
do
  local visibility_by_style_id = widget_definitions.VISIBILITY_BY_STYLE_ID
  for style_id, counts in pairs(visibility_by_style_id) do
    local is_b = string.sub(style_id, -1) == "b"
    for count in pairs(counts) do
      STYLES_BY_COUNT[count] = STYLES_BY_COUNT[count] or {}
      table.insert(STYLES_BY_COUNT[count], { style_id = style_id, is_b = is_b })
    end
  end
end

local COLOR_YELLOW = Color["yellow"](255, true)
local COLOR_LIME   = Color["lime"](255, true)

mod.ui.pass_rotation_centre = function(widget, style_id)
  local s = widget.style[style_id]
  if not s then return nil, nil end
  local parent = HudElementDamageIndicatorSettings.size
  local pass_w = (s.size and s.size[1]) or parent[1]
  local pass_h = (s.size and s.size[2]) or parent[2]
  local align_x = s.horizontal_alignment == "center" and (parent[1] - pass_w) * 0.5
               or s.horizontal_alignment == "right"  and (parent[1] - pass_w)
               or 0
  local align_y = s.vertical_alignment   == "center" and (parent[2] - pass_h) * 0.5
               or s.vertical_alignment   == "bottom" and (parent[2] - pass_h)
               or 0
  local off = s.offset or { 0, 0, 0 }
  local widget_y = (widget.offset and widget.offset[2]) or 0
  local pivot = s.pivot or { pass_w * 0.5, pass_h * 0.5 }
  return align_x + off[1]            + pivot[1],
         align_y + off[2] + widget_y + pivot[2]
end

mod.ui.center_pass_outside_arc = function(style, R, sx)
  sx = sx or 0
  style.horizontal_alignment = "center"
  style.pivot = { style.size[1] * 0.5 - sx, R + style.size[2] * 0.5 }
  style.offset = style.offset or { 0, 0, 0 }
  style.offset[1] = sx
  style._radius_outside_arc = R
end

mod.ui.tick_centred_pass = function(style, distance, angle, sx, nudge)
  style.angle = angle
  local nx = nudge and nudge[1] or 0
  local ny = nudge and nudge[2] or 0
  style.offset[2] = distance - style._radius_outside_arc - style.size[2] * 0.5 + ny
  style.pivot[2]  = style._radius_outside_arc + style.size[2] * 0.5 - ny
  if sx then
    style.offset[1] = sx + nx
    style.pivot[1]  = style.size[1] * 0.5 - sx - nx
  end
end

mod.ui.configure_numeral_passes = function(widget)
  for _, style_id in ipairs(NUMERAL_STYLE_IDS) do
    local s = widget.style[style_id]
    if s then
      local sx = (s.offset and s.offset[1]) or 0
      mod.ui.center_pass_outside_arc(s, NUMERAL_RADIUS, sx)
    end
  end
end

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

local UNLIMITED_RANGE_WARNINGS = { sniper = true }

local target_settings_cache = mod.ui._target_settings_cache
local warning_settings_cache = mod.ui._warning_settings_cache
local default_color_name_cache = mod.ui._default_color_name_cache
local default_color_rgb_cache = mod.ui._default_color_rgb_cache
local warning_expiry = mod.ui.warning_expiry
local colour_check = {}

local arc_side_cached
local function get_arc_side()
  if arc_side_cached == nil then
    local value = mod:get("arc_side")
    if value ~= "left" and value ~= "right" then
      value = "both"
    end
    arc_side_cached = value
  end
  return arc_side_cached
end

local function get_main_time()
  local time_manager = Managers and Managers.time
  return time_manager and time_manager:time("main") or 0
end

local function get_numeric_setting(setting_id, fallback_value)
  local value = mod:get(setting_id)
  if type(value) == "number" then
    return value
  end

  return fallback_value
end

local function clear_cache(cache)
  for key in pairs(cache) do
    cache[key] = nil
  end
end

mod.ui.is_warning_visible = function(indicate)
  return (warning_expiry[indicate] or 0) > get_main_time()
end

mod.ui.invalidate_setting_caches = function(setting_id)
  if type(setting_id) == "string" then
    default_color_name_cache[setting_id] = nil
    default_color_rgb_cache[setting_id] = nil
    if setting_id:match("_colour$") then
      clear_cache(colour_check)
    end
  else
    clear_cache(default_color_name_cache)
    clear_cache(default_color_rgb_cache)
    clear_cache(colour_check)
  end

  clear_cache(target_settings_cache)
  clear_cache(warning_settings_cache)
  arc_side_cached = nil
end

mod.ui.loadWarnings = function()
  mod:register_hud_element({
    class_name = "SpideySenseUINetWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/NetWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUICleaveWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/CleaveWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUIChargeWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/ChargeWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })

  mod:register_hud_element({
    class_name = "SpideySenseUIShotWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/ShotWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUIPounceWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/PounceWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
  mod:register_hud_element({
    class_name = "SpideySenseUISniperWarning",
    filename = "Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/SniperWarning",
    use_hud_scale = true,
    visibility_groups = {
      "alive"
    },
  })
end

local get_target_settings
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

mod:hook_require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_definitions", function(definitions)
	local indicator = widget_definitions.create_indicator_definition(get_target_settings)
	definitions.indicator_definition = indicator 
end)


local arrowpng  = "https://wobin.github.io/SpideySense/images/arrow.png"
local arrow2png = "https://wobin.github.io/SpideySense/images/arrow2.png"

local load_arrow = function(indicator)
  if mod.arrow1_texture then indicator.style.arrow.material_values.texture_map = mod.arrow1_texture end
  if mod.arrow2_texture then indicator.style.arrow2.material_values.texture_map = mod.arrow2_texture end

  if mod.arrow1_texture and mod.arrow2_texture then return Promise:new() end

  if SimpleAssets then
    local arrowpromise = SimpleAssets.load_texture("Spidey Sense/images/arrow.png"):next(function(data)
        if data and data.texture then
          mod.arrow1_texture = data.texture
          indicator.style.arrow.material_values.texture_map = data.texture
        end
      end):catch(function() end)

    local arrow2promise = SimpleAssets.load_texture("Spidey Sense/images/arrow2.png"):next(function(data)
        if data and data.texture then
          mod.arrow2_texture = data.texture
          indicator.style.arrow2.material_values.texture_map = data.texture
        end
      end):catch(function() end)

    return Promise.all(arrowpromise, arrow2promise)
  end

  if not (Managers.url_loader and Managers.backend) then return Promise:new() end

  return Managers.backend:authenticate():next(function()
    local arrowpromise = Managers.url_loader:load_texture(arrowpng, nil, "spidey_arrow"):next(function(data)
        if data and data.texture then
          mod.arrow1_texture = data.texture
          indicator.style.arrow.material_values.texture_map = data.texture
        end
      end):catch(function() end)

    local arrow2promise = Managers.url_loader:load_texture(arrow2png, nil, "spidey_arrow2"):next(function(data)
        if data and data.texture then
          mod.arrow2_texture = data.texture
          indicator.style.arrow2.material_values.texture_map = data.texture
        end
      end):catch(function() end)

    return Promise.all(arrowpromise, arrow2promise)
  end):catch(function() end)
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
    local range_max
    if UNLIMITED_RANGE_WARNINGS[attacker] then
      range_max = math.huge
    else
      local raw = mod:get(attacker .. "_range_max")
      range_max = type(raw) == "number" and raw or math.huge
    end
    settings = {
      range_max = range_max,
    }
    warning_settings_cache[attacker] = settings
  end

  if distance < settings.range_max then
    warning_expiry[indicate] = math.max(warning_expiry[indicate] or 0, get_main_time() + (delay or 0))
  end
end


mod:hook_safe("HudElementDamageIndicator", "init", function(self)
  mod.hudElement = self._indicator_widget
  mod.ui.configure_numeral_passes(self._indicator_widget)
end)

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

local function is_silent_missing_color(colour_value)
  return colour_value == nil or colour_value == ""
end

local function resolve_colour(colourValue, settingName)
  if type(colourValue) == "table" then
    return nil, colourValue
  end

  if type(colourValue) ~= "string" or colourValue == "" then
    local _, fallback_name = get_default_color_rgb(settingName)
    if settingName and not is_silent_missing_color(colourValue) then
      echo_color_fallback(settingName, colourValue, fallback_name)
    end
    return fallback_name
  end

  if not colour_check[colourValue] then
    if rawget(Color, colourValue) then
      colour_check[colourValue] = colourValue
    else
      local _, fallback_name = get_default_color_rgb(settingName)
      colour_check[colourValue] = fallback_name
      echo_color_fallback(settingName, colourValue, fallback_name)
    end
  end

  return colour_check[colourValue]
end

local function get_color_rgb(colourValue, settingName)
  local name, literal = resolve_colour(colourValue, settingName)
  if literal then
    return literal
  end
  return Color[name](255, true)
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
  local name, literal = resolve_colour(colourValue, settingName)
  if literal then
    return function(_alpha, as_rgb)
      if as_rgb then
        return literal
      end
      return { literal[1], literal[2], literal[3], literal[4] }
    end
  end
  return Color[name]
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

	for i = num_indicators, 1, -1 do
		local indicator = indicators[i]
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

      background_style.color = indicator.back_color
      front_style.color = indicator.front_color

      local roman_numeral_count = indicator.roman_numeral_count or 0

      if indicator.arrow_color then
        arrow_style.color = indicator.arrow_color
      end

      if indicator.is_nurgled and indicator.arrow_color then
        arrow2_style.color = indicator.nurgle_color or COLOR_LIME
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

      local extra        = COMPOSITE_EXTRA_PADDING[roman_numeral_count] or 0
      local half_spacing = (NUMERAL_PAIR_SPACING + extra) * 0.5
      local is_composite = COMPOSITE_COUNTS[roman_numeral_count]

      local styles_for_count = STYLES_BY_COUNT[roman_numeral_count]
      if styles_for_count then
        local numeral_color = indicator.back_color
        for j = 1, #styles_for_count do
          local entry = styles_for_count[j]
          local style = widget.style[entry.style_id]
          local sx
          if is_composite then
            sx = entry.is_b and half_spacing or -half_spacing
          else
            sx = 0
          end
          style.color = numeral_color
          mod.ui.tick_centred_pass(style, distance, angle, sx, NUMERAL_STYLE_NUDGE[entry.style_id])
        end
      end

      widget.content.distance = indicator.actual_distance or nil
      widget.content.target_type = indicator.target_type
      widget.content.is_nurgled = indicator.is_nurgled
      widget.content.roman_numeral_count = roman_numeral_count


			UIWidget.draw(widget, ui_renderer)
		else
			table.remove(indicators, i)
		end
	end
end)

mod.ui.spawn_indicator = function(angle, target_type, extra_duration, distance, actual_distance, is_nurgled, roman_numeral_count)
	local t = Managers.ui:get_time()
	local duration = HudElementDamageIndicatorSettings.life_time + (extra_duration or 0)
	local player_angle = get_player_direction_angle()
  local settings = get_target_settings(target_type)
	
  local back_colour = settings.back_colour
  local back_opacity = settings.back_opacity
  local front_colour = settings.front_colour
  local front_opacity = settings.front_opacity
  local arrow_colour = settings.arrow_colour
	
  local back_color = sanitize_color_with_alpha(get_color_rgb(back_colour, target_type .. "_back_colour"), back_opacity)
  local front_color = sanitize_color_with_alpha(get_color_rgb(front_colour, target_type .. "_front_colour"), front_opacity)
	
	local arrow_color = nil
	local nurgle_color = nil
	if arrow_colour then
    arrow_color = get_color_rgb(arrow_colour, target_type .. "_arrow_colour")
		if is_nurgled and arrow_color then
			if arrow_color[3] > arrow_color[2] and arrow_color[3] > arrow_color[4] then
				nurgle_color = COLOR_YELLOW
			else
				nurgle_color = COLOR_LIME
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
    roman_numeral_count = roman_numeral_count or 0,
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

mod.ui.create_indicator = function(unit_or_position, target_type, extra_duration, roman_numeral_count)

  if not mod.hudElement then return end
  
  local position = get_position(unit_or_position)
	local settings = get_target_settings(target_type)

  if settings.nurgle_blessed and get_userdata_type(unit_or_position) == "Unit" then
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
	local arc_side = get_arc_side()
	local side_ok = arc_side == "both"
		or (arc_side == "left"  and directionRotatedNormalized.x <= 0)
		or (arc_side == "right" and directionRotatedNormalized.x >= 0)
	if distance < settings.max_distance and side_ok then
		if not settings.only_behind or (angle > 1.5 or angle < -1.5) then
      local active_distance = settings.active_range and math.max(0, (distance / settings.max_distance) * 325 - 125) or settings.radius
      local needs_distance_arrow = settings.arrow_distance and not arrow1_map
      local needs_nurgle_arrow   = nurgled[unit_or_position] and not arrow2_map

      if mod.hudElement
        and (needs_distance_arrow or needs_nurgle_arrow)
        and not mod.loadingarrow
      then
        mod.loadingarrow = true
        load_arrow(mod.hudElement):next(function() mod.loadingarrow = false end)
      else
        spawn_indicator(angle, target_type, extra_duration, active_distance, distance, nurgled[unit_or_position], roman_numeral_count)
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
