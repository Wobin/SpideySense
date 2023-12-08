local mod = get_mod("crosshair_hud")
local InputUtils = require("scripts/managers/input/input_utils")

local localizations = 
{
	mod_description = {
		en = "Offers a coloured arc indicator for the direction of sound cues for certain special units",
		["zh-cn"] = "为某些特殊单位的音效提供彩色的方向圆弧指示器。",
	},
  mutant_colour = {
    en = "Colour for Mutant warning",
    ["zh-cn"] = "变种人警告颜色",
  },
  mutant_active = {
    en = "Show indicator",
    ["zh-cn"] = "显示指示器",
    },
  mutant_front_opacity = {
    en = "Foreground Opacity",
    ["zh-cn"] = "前景不透明度",
  },
  mutant_front_colour = {
    en = "Foreground Colour",
    ["zh-cn"] = "前景颜色",
    },
  mutant_back_opacity= {
    en = "Background Opacity",
    ["zh-cn"] = "背景不透明度",
  },
  mutant_back_colour = {
    en = "Background Colour",
    ["zh-cn"] = "背景颜色",
  },
  trapper_colour = {
    en = "Colour for Trapper warning",
    ["zh-cn"] = "陷阱手警告颜色",
  },
  trapper_active = {
    en = "Show indicator",
    ["zh-cn"] = "显示指示器",
    },
  trapper_front_opacity = {
    en = "Foreground Opacity",
    ["zh-cn"] = "前景不透明度",
  },
  trapper_front_colour = {
    en = "Foreground Colour",
    ["zh-cn"] = "前景颜色",
    },
  trapper_back_opacity= {
    en = "Background Opacity",
    ["zh-cn"] = "背景不透明度",
  },
  trapper_back_colour = {
    en = "Background Colour",
    ["zh-cn"] = "背景颜色",
  },
  hound_colour = {
    en = "Colour for Hound warning",
    ["zh-cn"] = "猎犬警告颜色",
  },
  hound_active = {
    en = "Show indicator",
    ["zh-cn"] = "显示指示器",
    },
  hound_front_opacity = {
    en = "Foreground Opacity",
    ["zh-cn"] = "前景不透明度",
  },
  hound_front_colour = {
    en = "Foreground Colour",
    ["zh-cn"] = "前景颜色",
    },
  hound_back_opacity= {
    en = "Background Opacity",
    ["zh-cn"] = "背景不透明度",
  },
  hound_back_colour = {
    en = "Background Colour",
    ["zh-cn"] = "背景颜色",
  },
    burster_colour = {
    en = "Colour for Burster warning",
    ["zh-cn"] = "爆破手警告颜色",
  },
  burster_active = {
    en = "Show indicator",
    ["zh-cn"] = "显示指示器",
    },
  burster_front_opacity = {
    en = "Foreground Opacity",
    ["zh-cn"] = "前景不透明度",
  },
  burster_front_colour = {
    en = "Foreground Colour",
    ["zh-cn"] = "前景颜色",
    },
  burster_back_opacity= {
    en = "Background Opacity",
    ["zh-cn"] = "背景不透明度",
  },
  burster_back_colour = {
    en = "Background Colour",
    ["zh-cn"] = "背景颜色",
  },
  backstab_colour = {
    en = "Colour for Backstab warning",
    ["zh-cn"] = "背刺警告颜色",
  },
  backstab_active = {
    en = "Show indicator",
    ["zh-cn"] = "显示指示器",
    },
  backstab_front_opacity = {
    en = "Foreground Opacity",
    ["zh-cn"] = "前景不透明度",
  },
  backstab_front_colour = {
    en = "Foreground Colour",
    ["zh-cn"] = "前景颜色",
    },
  backstab_back_opacity= {
    en = "Background Opacity",
    ["zh-cn"] = "背景不透明度",
  },
  backstab_back_colour = {
    en = "Background Colour",
    ["zh-cn"] = "背景颜色",
  },
  radius = {
    en = "Distance from standard arc",
    ["zh-cn"] = "与原版圆弧之间的距离",
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
