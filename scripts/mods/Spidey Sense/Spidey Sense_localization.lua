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
    ru = "Цвет предупреждения о Мутантах",
  },  
  trapper_colour = {
    en = "Colour for Trapper warning",
    ["zh-cn"] = "陷阱手警告颜色",
    ru = "Цвет предупреждения о Ловушечниках",
  },
  hound_colour = {
    en = "Colour for Hound warning",
    ["zh-cn"] = "猎犬警告颜色",
    ru = "Цвет предупреждения о Гончих",
  },
  burster_colour = {
    en = "Colour for Burster warning",
    ["zh-cn"] = "爆破手警告颜色",
    ru = "Цвет предупреждения о Взрывунах",
  },
  flamer_colour = {
    en = "Colour for Flamer warning",
    ["zh-cn"] = "火焰兵警告颜色",
    ru = "Цвет предупреждения об Огнемётчиках",
  },
  grenadier_colour = {
    en = "Colour for Grenadier warning",
    ["zh-cn"] = "轰炸者警告颜色",
    ru = "Цвет предупреждения о Скаб гренадёрах",
  },
  sniper_colour = {
    en = "Colour for Sniper warning",
    ["zh-cn"] = "狙击手警告颜色",
    ru = "Цвет предупреждения о Снайперах",
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
    ru = "Цвет предупреждения о Дробителях",
  },
  mauler_colour = {
    en = "Colour for Mauler warning",
    ["zh-cn"] = "重锤兵警告颜色",
    ru = "Цвет предупреждения о Палачах",
  },
  daemonhost_colour = {
    en  = "Colour for Daemonhost",
    ["zh-cn"] = "恶魔宿主颜色",
    ru = "Цвет для Демонхоста",
  },
  rager_colour = {
   en = "Colour for Ragers",
    ["zh-cn"] = "狂暴者颜色",
    ru = "Цвет для Берсерков",
  },
  toxbomber_colour = {
   en = "Colour for Tox Grenadiers",
    ["zh-cn"] = "剧毒轰炸者颜色",
    ru = "Цвет для Токс гренадёров",
  },
  plague_ogryn_colour = {
   en = "Colour for Plague Ogryn",
    ["zh-cn"] = "瘟疫欧格林警告颜色",
    ru = "Цвет для Чумного Огрина",
  },
  chaos_spawn_colour = {
   en = "Colour for Chaos Spawn",
    ["zh-cn"] = "混沌魔物警告颜色",
    ru = "Цвет для Отродья Хаоса",
  },
  beast_of_nurgle_colour = {
   en = "Colour for Beast of Nurgle",
    ["zh-cn"] = "纳垢兽警告颜色",
    ru = "Цвет для Зверя Нургла",
  },
  core_options = {
    en = "Core Options",
    ["zh-cn"] = "核心选项",
    ru = "Основные опции",
  },
  active_range = {
    en ="Active Range Indicator",
    ["zh-cn"] = "动态距离指示器",
    ru = "Активный индикатор расстояния",
  },
  active_range_tooltip = {
    en = "This option will move the arc closer to the centre from the 'Distance from standard arc' range, as the target gets closer",
    ["zh-cn"] = "启用此选项后，当目标靠近时，圆弧会比“与原版圆弧之间的距离”更靠近中心",
    ru = "Эта опция переместит индикатор ближе к центру от «Расстояния от стандартной дуги» по мере приближения цели.",
  },
  crusher_text_warnings = {
    en = "Crusher/Mauler Text Warnings"
  },
  trapper_text_warnings = {
    en = "Trapper Text Warnings"
    },
  cleave_text = {
    en = "CLEAVE!!"
  },
  net_text = {
    en = "NET!!"
    },
  render_trapper_warning = {
    en = "Show NET!! indicator when trapper winds up"
  },
  render_crusher_warning = {
    en = "Show CLEAVE!! indicator when Crusher or Mauler winds up"
  },
  font_size_cleave = {
    en = "Font Size"
  },
  font_size_net = {
    en = "Font Size"
  },
  font_name_cleave = {
    en = "Font Name"
  },
  font_name_net = {
    en = "Font Name"
  },
  
  font_color_cleave = {
    en = "Font Color"
  },
  font_color_net = {
    en = "Font Color"
  },
    arial = { en = "Arial"},
		itc_novarese_medium = { en = "Novarese Medium"},
		itc_novarese_bold = { en = "Novarese Bold"},
		proxima_nova_light = { en = "Proxima Nova Light"},
		proxima_nova_medium = { en = "Proxima Nova Medium"},
		proxima_nova_bold = { en = "Proxima Nova Bold"},
		friz_quadrata = { en = "Fritz Quadrata"}, -- this is also default Russian font
		rexlia = { en = "Rexila"},
		machine_medium  = { en = "Machine Medium"},
    noto_sans_sc_black = { ["zh-cn"] = "" },
    noto_sans_sc_bold  = { ["zh-cn"] = "" },
    noto_sans_sc_black = { ["zh-cn"] = "" },  
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
    localisations[typeName .. "_arrow_distance"] = {
    en = "Proximity Alert Range (m)",
    ["zh-cn"] = "接近警告距离（米）",
    ru = "Дистанция оповещения о приближении (м)",
  }
  localisations[typeName .. "_arrow_colour"] ={
    en = "Proximity Alert Colour",
    }
  localisations[typeName .. "_active_range"] = {
    en ="Active Range Indicator",
    ["zh-cn"] = "动态距离指示器",
    ru = "Активный индикатор расстояния",
  }
  localisations[typeName .. "_nurgle_blessed"] = {
    en = "Indicate Nurgle Blessed",
    ["zh-cn"] = "指示纳垢赐福敌人",
    ru = "Показывать благословенных Нурглом",
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
addLocalisation(localizations, "beast_of_nurgle")
addLocalisation(localizations, "burster")
addLocalisation(localizations, "crusher")
addLocalisation(localizations, "chaos_spawn")
addLocalisation(localizations, "daemonhost")
addLocalisation(localizations, "flamer")
addLocalisation(localizations, "grenadier")
addLocalisation(localizations, "hound")
addLocalisation(localizations, "mauler")
addLocalisation(localizations, "mutant")
addLocalisation(localizations, "plague_ogryn")
addLocalisation(localizations, "rager")
addLocalisation(localizations, "sniper")
addLocalisation(localizations, "trapper")
addLocalisation(localizations, "toxbomber")



return localizations
