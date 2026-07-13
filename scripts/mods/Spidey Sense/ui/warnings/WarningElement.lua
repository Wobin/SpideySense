local mod = get_mod("Spidey Sense")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

return function(class_name, key, indicate, position)
	local colour_setting = "font_colour_" .. key

	local Definitions = {
		scenegraph_definition = {
			screen = UIWorkspaceSettings.screen,
			alert = {
				parent = "screen",
				size = { 500, 180 },
				vertical_alignment = "center",
				horizontal_alignment = "center",
				position = position,
			},
		},
		widget_definitions = {
			alert = UIWidget.create_definition({
				{
					value = mod:localize(key .. "_text"),
					pass_type = "text",
					value_id = "text",
					style_id = "text",
					style = {
						font_type = mod:get("font_name_" .. key) or mod.ui.default_warning_font,
						font_size = mod:get("font_size_" .. key) or 28,
						text_vertical_alignment = "center",
						text_horizontal_alignment = "center",
						text_color = mod.colourCache(mod:get(colour_setting), colour_setting)(255, true),
						offset = { 0, 0, 1 },
					},
					visibility_function = function()
						return mod.ui.is_warning_visible(indicate)
					end,
				},
			}, "alert"),
		},
	}

	local Warning = class(class_name, "HudElementBase")

	function Warning:init(parent, draw_layer, start_scale)
		Warning.super.init(self, parent, draw_layer, start_scale, Definitions)
	end

	return Warning
end
