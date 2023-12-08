local mod = get_mod("crosshair_hud")
local InputUtils = require("scripts/managers/input/input_utils")

local localizations = 
{
	mod_description = {
		en = "Offers a coloured arc indicator for the direction of sound cues for certain special units",
	},
  mutant_colour = {
    en = "Colour for Mutant warning"
  },
  mutant_active = {
    en = "Show indicator"
    },
  mutant_front_opacity = {
    en = "Foreground Opacity"
  },
  mutant_front_colour = {
    en = "Foreground Colour"
    },
  mutant_back_opacity= {
    en = "Background Opacity"
  },
  mutant_back_colour = {
    en = "Background Colour"
  },
  trapper_colour = {
    en = "Colour for Trapper warning"
  },
  trapper_active = {
    en = "Show indicator"
    },
  trapper_front_opacity = {
    en = "Foreground Opacity"
  },
  trapper_front_colour = {
    en = "Foreground Colour"
    },
  trapper_back_opacity= {
    en = "Background Opacity"
  },
  trapper_back_colour = {
    en = "Background Colour"
  },
  hound_colour = {
    en = "Colour for Hound warning"
  },
  hound_active = {
    en = "Show indicator"
    },
  hound_front_opacity = {
    en = "Foreground Opacity"
  },
  hound_front_colour = {
    en = "Foreground Colour"
    },
  hound_back_opacity= {
    en = "Background Opacity"
  },
  hound_back_colour = {
    en = "Background Colour"
  },
    burster_colour = {
    en = "Colour for Burster warning"
  },
  burster_active = {
    en = "Show indicator"
    },
  burster_front_opacity = {
    en = "Foreground Opacity"
  },
  burster_front_colour = {
    en = "Foreground Colour"
    },
  burster_back_opacity= {
    en = "Background Opacity"
  },
  burster_back_colour = {
    en = "Background Colour"
  },
  backstab_colour = {
    en = "Colour for Backstab warning"
  },
  backstab_active = {
    en = "Show indicator"
    },
  backstab_front_opacity = {
    en = "Foreground Opacity"
  },
  backstab_front_colour = {
    en = "Foreground Colour"
    },
  backstab_back_opacity= {
    en = "Background Opacity"
  },
  backstab_back_colour = {
    en = "Background Colour"
  },
  radius = {
    en = "Distance from standard arc"
    }
}

local function readable(text)
  local readable_string = ""
  local tokens = string.split(text, "_")
  for i, token in ipairs(tokens) do
    local first_letter = string.sub(token, 1, 1)
    token = string.format("%s%s", string.upper(first_letter), string.sub(token, 2))
    readable_string = string.trim(string.format("%s %s", readable_string, token))
  end

  return readable_string
end

local color_names = Color.list
for i, color_name in ipairs(color_names) do
  local color_values = Color[color_name](255, true)
  local text = InputUtils.apply_color_to_input_text(readable(color_name), color_values)
  localizations[color_name] = {
    en = text
  }
end


return localizations