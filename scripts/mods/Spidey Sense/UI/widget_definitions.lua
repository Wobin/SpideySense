local HudElementDamageIndicatorSettings = require("scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local mod = get_mod("Spidey Sense")

local widget_definitions = {}

-- Canonical roman-numeral visibility lookup. Single source of truth — UI.lua
-- reads this via the returned widget_definitions table to drive the draw loop.
widget_definitions.VISIBILITY_BY_STYLE_ID = {
	roman_numeral    = {[1] = true, [9] = true},
	roman_numeral_2  = {[2] = true},
	roman_numeral_3  = {[3] = true},
	roman_numeral_4  = {[4] = true},
	roman_numeral_5  = {[5] = true, [6] = true, [7] = true, [8] = true},
	roman_numeral_10 = {[10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true},
	roman_numeral_1b = {[6] = true, [11] = true},
	roman_numeral_2b = {[7] = true, [12] = true},
	roman_numeral_3b = {[8] = true, [13] = true},
	roman_numeral_4b = {[14] = true},
	roman_numeral_5b = {[15] = true},
	roman_numeral_10b = {[9] = true},
}

function widget_definitions.create_indicator_definition(get_target_settings)
	local center_distance = HudElementDamageIndicatorSettings.center_distance
	local size = HudElementDamageIndicatorSettings.size

	local visibility_by_style_id = widget_definitions.VISIBILITY_BY_STYLE_ID

	local function is_count_visible(style_id, count)
		local visible = visibility_by_style_id[style_id]
		return visible and visible[count] or false
	end
	
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
				color = Color["black"](255, true),
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
		},
		-- Roman numeral passes. Geometry (pivot, alignment, offset[1..2]) is
		-- configured at runtime by mod.ui.center_pass_outside_arc in UI.lua so
		-- they share the arc's screen-centre rotation point. offset[3] (z) and
		-- offset[1] (slot X) are preserved by the helper.
		{
			value = "content/ui/materials/icons/presets/preset_21",
			style_id = "roman_numeral",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 0, 0, 6 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_22",
			style_id = "roman_numeral_2",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 0, 0, 5 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_2", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_23",
			style_id = "roman_numeral_3",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 0, 0, 4 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_3", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_24",
			style_id = "roman_numeral_4",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 0, 0, 3 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_4", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_25",
			style_id = "roman_numeral_5",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 0, 0, 2 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_5", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/backgrounds/scanner/scanner_map_greek_22",
			style_id = "roman_numeral_10",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 0, 0, 1 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_10", content.roman_numeral_count)
			end
		},
		-- Slot 2 roman numerals. offset[1] = 20 picks the right slot at angle 0;
		-- the helper compensates pivot.x so rotation centre stays on screen centre.
		{
			value = "content/ui/materials/icons/presets/preset_21",
			style_id = "roman_numeral_1b",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 20, 0, 6 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_1b", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_22",
			style_id = "roman_numeral_2b",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 20, 0, 5 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_2b", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_23",
			style_id = "roman_numeral_3b",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 20, 0, 4 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_3b", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_24",
			style_id = "roman_numeral_4b",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 20, 0, 3 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_4b", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/icons/presets/preset_25",
			style_id = "roman_numeral_5b",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 20, 0, 2 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_5b", content.roman_numeral_count)
			end
		},
		{
			value = "content/ui/materials/backgrounds/scanner/scanner_map_greek_22",
			style_id = "roman_numeral_10b",
			pass_type = "rotated_texture",
			style = {
				size = { size[1] * 0.28, size[2] * 0.28 },
				angle = 0,
				color = UIHudSettings.color_tint_alert_1,
				offset = { 20, 0, 1 }
			},
			visibility_function = function(content, style)
				return is_count_visible("roman_numeral_10b", content.roman_numeral_count)
			end
		}
	}

	return UIWidget.create_definition(indicator_definition, "indicator")
end

return widget_definitions
