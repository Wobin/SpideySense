local mod = get_mod("Spidey Sense")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local colourCache = mod.colourCache


local Definitions = {
  scenegraph_definition = {
    screen = UIWorkspaceSettings.screen,
    alert = {
      parent = "screen",
      size = { 500, 180 },
      vertical_alignment = "center",
      horizontal_alignment = "center",
      position = { -350, 0, 1 }    
    }    
  },
  widget_definitions = {
    alert = UIWidget.create_definition({
      {
        value = mod:localize("cleave_text"),
        pass_type = "text",        
        value_id = "text",
        style_id = "text",
        style = {
          font_type = mod:get("font_name_cleave"),
          font_size = mod:get("font_size_cleave"),
          text_vertical_alignment = "center",
          text_horizontal_alignment = "center",
          text_color = colourCache(mod:get("font_colour_cleave"), "mauler")(255, true),
          offset = { 0, 0, 1 }
        },
        visibility_function = function() return mod.showCleave end
      }
    }, "alert")
  }
}



local Warning = class("SpideySenseUICleaveWarning", "HudElementBase")

function Warning:init(parent, draw_layer, start_scale)  
  Warning.super.init(self, parent, draw_layer, start_scale, Definitions)
end

return Warning