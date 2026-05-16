local HudElementDamageIndicatorSettings =	require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

--local mt = get_mod("modding_tools")
local mod = get_mod("Spidey Sense")
local widget_definitions = mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/UI/widget_definitions")
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
mod.ui.default_colors = {
    burster = {front = "burly_wood", back = "citadel_averland_sunset", arrow = "burly_wood"},
    barrel = {front = "cheeseburger", back = "citadel_balthasar_gold", arrow = "cheeseburger"},
    beast_of_nurgle = {front = "citadel_dorn_yellow", back = "citadel_balthasar_gold", arrow = "citadel_dorn_yellow"},
    crusher = {front = "sienna", back = "ui_red_medium", arrow = "sienna"},
    chaos_spawn = {front = "cheeseburger", back = "ui_red_medium", arrow = "cheeseburger"},
    daemonhost = {front = "teal", back = "blue_violet", arrow = "teal"},
    flamer = {front = "online_green", back = "medium_violet_red", arrow = "online_green"},
    grenadier = {front = "sandy_brown", back = "ui_interaction_pickup", arrow = "sandy_brown"},
    hound = {front = "chart_reuse", back = "cadet_blue", arrow = "chart_reuse"},
    mauler = {front = "turquoise", back = "ui_blue_light", arrow = "turquoise"},
    mutant = {front = "ui_green_light", back = "spring_green", arrow = "ui_green_light"},
    plague_ogryn = {front = "powder_blue", back = "citadel_bieltan_green", arrow = "powder_blue"},
    plasma_gunner = {front = "royal_blue", back = "tomato", arrow = "royal_blue"},
    rager = {front = "medium_spring_green", back = "midnight_blue", arrow = "medium_spring_green"},
    sniper = {front = "powder_blue", back = "ui_ability_purple", arrow = "powder_blue"},
    trapper = {front = "ui_hud_warp_charge_medium", back = "ui_hud_warp_charge_low", arrow = "ui_hud_warp_charge_medium"},
    toxbomber = {front = "chart_reuse", back = "citadel_bieltan_green", arrow = "chart_reuse"},
    melee_backstab = {front = "ui_terminal", back = "ui_terminal"},
    ranged_backstab = {front = "ui_terminal", back = "ui_terminal"},
}
mod.ui._healed_settings = mod.ui._healed_settings or {}
mod.ui._target_settings_cache = mod.ui._target_settings_cache or {}
mod.ui._warning_settings_cache = mod.ui._warning_settings_cache or {}
mod.ui._default_color_name_cache = mod.ui._default_color_name_cache or {}
mod.ui._default_color_rgb_cache = mod.ui._default_color_rgb_cache or {}
mod.ui.warning_expiry = mod.ui.warning_expiry or {}

-- Radius (in widget pixels) from screen centre to the centre of a Roman-numeral
-- texture. center_distance (= 247) is where the arc texture's top edge sits, so
-- +10 puts the numeral just outside the arc's outer edge. Tune to taste.
local NUMERAL_RADIUS = HudElementDamageIndicatorSettings.center_distance + 10

-- Centre-to-centre spacing (widget pixels) between the two glyphs of a
-- composite roman numeral (e.g. VI = V + I). The pair is centred on the arc,
-- so each glyph sits at ±NUMERAL_PAIR_SPACING * 0.5 from screen-centre along
-- the indicator's local-X axis.
local NUMERAL_PAIR_SPACING = 28

-- Counts whose visible numeral is composed of TWO textures. For every other
-- count <= 15, only one (primary) numeral renders and it sits at screen-centre.
local COMPOSITE_COUNTS = {
  [6] = true, [7] = true, [8] = true, [9] = true,
  [11] = true, [12] = true, [13] = true, [14] = true, [15] = true,
}

-- Extra centre-to-centre spacing (widget pixels) added to NUMERAL_PAIR_SPACING
-- for composites whose "b" (right) glyph is visibly wider than I. II/III are
-- centred in a 56 px canvas, so their left edge sits closer to the primary --
-- bumping spacing here pushes BOTH glyphs outward equally (pair stays centred).
local COMPOSITE_EXTRA_PADDING = {
  [7]  = 6,   -- V + II
  [8]  = 12,  -- V + III
  [12] = 6,   -- X + II
  [13] = 12,  -- X + III
  [14] = 12,  -- X + IV
}

-- Per-style positional calibration (widget pixels) for textures whose visible
-- glyph doesn't sit at its canvas centre. Applied on top of slot positioning,
-- with matching pivot compensation so rotation still pivots on screen-centre.
-- Format: { dx, dy } in widget-local pixels — +dx is right, +dy is "down"
-- (toward screen-centre when the indicator is at angle 0).
local NUMERAL_STYLE_NUDGE = {
  -- X texture (scanner_map_greek_22) is a repurposed scanner asset, not a
  -- preset_2X glyph — its X is painted up-and-left of canvas centre relative
  -- to the other numerals, so shift it down-and-right to align with them.
  roman_numeral_10  = { 10, 2},
  roman_numeral_10b = { 10, 2 },
}

local NUMERAL_STYLE_IDS = {
  "roman_numeral", "roman_numeral_2", "roman_numeral_3",
  "roman_numeral_4", "roman_numeral_5", "roman_numeral_10",
  "roman_numeral_1b", "roman_numeral_2b", "roman_numeral_3b",
  "roman_numeral_4b", "roman_numeral_5b", "roman_numeral_10b",
}

-- Inverse of widget_definitions.VISIBILITY_BY_STYLE_ID: for a given roman-numeral
-- count, the list of styles that should render. At most 2 entries per count (one
-- per slot). Built once at file load; iterated in the indicator draw hot path.
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

-- Color constants used by the indicator draw loop. Hoisted out of the hot path
-- so we don't allocate two color tables per frame.
local COLOR_YELLOW = Color["yellow"](255, true)
local COLOR_LIME   = Color["lime"](255, true)

-- Given a rotated_texture pass on the damage-indicator widget, return where it
-- currently rotates around in widget-local pixels (screen pixels relative to the
-- indicator scenegraph origin). Diagnostic helper for verifying that an overlay
-- shares the arc's rotation centre. See the brainstorm plan for the derivation.
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

-- Configure a rotated_texture pass so it rotates around screen centre (the arc's
-- rotation point), sits at radius R from there along local-up at angle 0, and
-- keeps its base facing screen centre as it rotates. sx is a screen-X slot offset
-- at angle 0 (e.g. 20 for the "b" slot); pivot.x compensates so rotation centre
-- stays on screen centre regardless of sx. Per frame, call tick_centred_pass to
-- absorb the arc's pulse (widget.offset[2]) into style.offset[2].
mod.ui.center_pass_outside_arc = function(style, R, sx)
  sx = sx or 0
  style.horizontal_alignment = "center"
  style.pivot = { style.size[1] * 0.5 - sx, R + style.size[2] * 0.5 }
  style.offset = style.offset or { 0, 0, 0 }
  style.offset[1] = sx
  style._radius_outside_arc = R
end

-- Per-frame counterpart to center_pass_outside_arc: write the current angle and
-- cancel the arc's pulse so the numeral stays pinned at radius R from screen
-- centre regardless of the arc's bounce. Cheap; safe to call once per visible
-- numeral per indicator draw. Optional sx re-slots the glyph along local-X
-- (with matching pivot.x compensation) so the screen-centre rotation pivot is
-- preserved as the slot moves between frames. Optional nudge = { dx, dy } adds
-- a per-style calibration shift (with matching pivot compensation on both axes)
-- for textures whose visible glyph doesn't sit at the canvas centre.
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

-- Apply center_pass_outside_arc to every numeral style on the indicator widget.
-- Reads existing offset[1] from each style so the widget definition keeps owning
-- per-slot positioning (0 for primary, 20 for "b").
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

local healed_settings = mod.ui._healed_settings
local target_settings_cache = mod.ui._target_settings_cache
local warning_settings_cache = mod.ui._warning_settings_cache
local default_color_name_cache = mod.ui._default_color_name_cache
local default_color_rgb_cache = mod.ui._default_color_rgb_cache
local warning_expiry = mod.ui.warning_expiry
local colour_check = {}
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
    if setting_id:match("_colour$") then
      clear_cache(colour_check)
    end
  else
    clear_cache(healed_settings)
    clear_cache(default_color_name_cache)
    clear_cache(default_color_rgb_cache)
    clear_cache(colour_check)
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

      -- Numerals: tick the visible ones so their angle tracks the arc and their
      -- screen position is unaffected by the arc's pulse (absorbed into offset[2]).
      -- For composite counts (VI, VII, VIII, IX, XI-XV), straddle the centre by
      -- ±half_spacing so the pair sits centred on the arc rather than drifting.
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

      widget.content.roman_numeral_count = roman_numeral_count
      
      -- TEST: Simplified - II always shown via hard-coded texture in widget definition
      
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

mod.ui.create_indicator = function(unit_or_position, target_type, extra_duration, roman_numeral_count)	
	
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
      -- arrow_distance arrow renders via style.arrow → fed by arrow1_texture;
      -- nurgle indicator renders via style.arrow2 → fed by arrow2_texture.
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
