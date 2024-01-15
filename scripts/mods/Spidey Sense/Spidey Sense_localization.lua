local mod = get_mod("crosshair_hud")
local InputUtils = require("scripts/managers/input/input_utils")

local localizations = 
{
	mod_name = {
		en = "Spidey Sense",
		["zh-cn"] = "蜘蛛感应",
		ru = "Паучье Чутьё",
	},
	mod_description = {
		en = "Offers a coloured arc indicator for the direction of sound cues for certain special units",
		["zh-cn"] = "为某些特殊单位的音效提供彩色的方向圆弧指示器。",
		ru = "Spidey Sense - Добавляет цветной дуговой индикатор, показывающий направление звуковых сигналов для определённых врагов.",
	},
  mutant_colour = {
    en = "Colour for Mutant warning",
    ["zh-cn"] = "变种人警告颜色",
    ru = "Цвет предупреждения о мутантах",
  },  
  trapper_colour = {
    en = "Colour for Trapper warning",
    ["zh-cn"] = "陷阱手警告颜色",
    ru = "Цвет предупреждения о ловушечниках",
  },
  hound_colour = {
    en = "Colour for Hound warning",
    ["zh-cn"] = "猎犬警告颜色",
    ru = "Цвет предупреждения о гончих",
  },
  burster_colour = {
    en = "Colour for Burster warning",
    ["zh-cn"] = "爆破手警告颜色",
    ru = "Цвет предупреждения о взрывунах",
  },
  flamer_colour = {
    en = "Colour for Flamer warning",
    ["zh-cn"] = "火焰兵警告颜色",
    ru = "Цвет предупреждения о огнемётчиках",
  },
  grenadier_colour = {
    en = "Colour for Grenadier warning",
    ["zh-cn"] = "轰炸者警告颜色",
    ru = "Цвет предупреждения о гренадёрах",
  },
  sniper_colour = {
    en = "Colour for Sniper warning",
    ["zh-cn"] = "狙击手警告颜色",
    ru = "Цвет предупреждения о снайперах",
  },
  backstab_colour = {
    en = "Colour for Backstab warning",
    ["zh-cn"] = "背刺警告颜色",
    ru = "Цвет предупреждения об ударах в спину",
  },
  barrel_colour = {
    en = "Colour for Barrel warning",
    ["zh-cn"] = "爆炸桶警告颜色",
    ru = "Цвет предупреждения о взрывающихся бочках",
  },
  crusher_colour = {
    en = "Colour for Crusher warning",
    ["zh-cn"] = "粉碎者警告颜色",
    ru = "Цвет предупреждения о дробителях",
  },
  mauler_colour = {
    en = "Colour for Mauler warning",
    ["zh-cn"] = "重锤兵警告颜色",
    ru = "Цвет предупреждения о палачах",
  },
  daemonhost_colour = {
    en  = "Colour for Daemonhost",
    ["zh-cn"] = "恶魔宿主颜色",
  },
  rager_colour = {
   en = "Colour for Ragers",
    ["zh-cn"] = "狂暴者颜色",
  },
  core_options = {
    en = "Core Options",
    ["zh-cn"] = "核心选项",
  },
  active_range = {
    en ="Active Range Indicator",
    ["zh-cn"] = "动态距离指示器",
  },
  active_range_tooltip = {
    en = "This option will move the arc closer to the centre from the 'Distance from standard arc' range, as the target gets closer",
    ["zh-cn"] = "启用此选项后，当目标靠近时，圆弧会比“与原版圆弧之间的距离”更靠近中心",
  },
}

local function addLocalisation(localisations, typeName)
  localisations[typeName .. "_active"] = {
    en = "Show indicator",
    ["zh-cn"] = "显示指示器",
    ru = "Показывать индикатор",
  }
  localisations[typeName .. "_only_behind"] = {
    en = "Show indicator only if behind you",    
    ["zh-cn"] = "仅当目标在背后时显示指示器",
    ru = "Показывать только индикатор ударов ссзади",
    }
  localisations[typeName .. "_front_opacity"] = {
    en = "Foreground Opacity",
    ["zh-cn"] = "前景不透明度",
    ru = "Прозрачность переднего плана",
  }
  localisations[typeName .. "_front_colour"] = {
    en = "Foreground Colour",
    ["zh-cn"] = "前景颜色",
    ru = "Цвет переднего плана",
    }
  localisations[typeName .. "_back_opacity"]= {
    en = "Background Opacity",
    ["zh-cn"] = "背景不透明度",
    ru = "Прозрачность заднего плана",
  }
  localisations[typeName .. "_back_colour"] = {
    en = "Background Colour",
    ["zh-cn"] = "背景颜色",
    ru = "Цвет заднего плана",
  }
  localisations[typeName .. "_radius"] = {
    en = "Distance from standard arc",
    ["zh-cn"] = "与原版圆弧之间的距离",
    ru = "Расстояние от стандартной дуги",
  }
  localisations[typeName .. "_distance"] = {
    en = "Detection range (m)",
    ["zh-cn"] = "检测距离（米）",
    ru = "Дистанция обнаружения (м)",
    }
end


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

addLocalisation(localizations, "backstab")
addLocalisation(localizations, "barrel")
addLocalisation(localizations, "burster")
addLocalisation(localizations, "crusher")
addLocalisation(localizations, "daemonhost")
addLocalisation(localizations, "flamer")
addLocalisation(localizations, "grenadier")
addLocalisation(localizations, "hound")
addLocalisation(localizations, "mauler")
addLocalisation(localizations, "mutant")
addLocalisation(localizations, "rager")
addLocalisation(localizations, "sniper")
addLocalisation(localizations, "trapper")



return localizations
