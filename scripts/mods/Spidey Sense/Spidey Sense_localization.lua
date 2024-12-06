local mod = get_mod("Spidey Sense")
local InputUtils = require("scripts/managers/input/input_utils")

local localizations = {
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
    invalid_colour_setting = {
      en = " has an invalid color. Please update the arc or text settings"
    },
    none_name = {
        en = "None",
        ["zh-cn"] = "无",
        ru = "Нет",
    },
    mutant_colour = {
        en = "Colour for Mutant warning",
        ["zh-cn"] = "变种人警告颜色",
        ru = "Цвет предупреждения о Мутантах",
    },
    mutant_name = {
        en = "Mutant",
        ["zh-cn"] = "变种人",
        ru = "Мутант",
    },
    trapper_colour = {
        en = "Colour for Trapper warning",
        ["zh-cn"] = "陷阱手警告颜色",
        ru = "Цвет предупреждения о Ловушечниках",
    },
    trapper_name = {
        en = "Trapper",
        ["zh-cn"] = "陷阱手",
        ru = "Ловушечник",
    },
    hound_colour = {
        en = "Colour for Hound warning",
        ["zh-cn"] = "猎犬警告颜色",
        ru = "Цвет предупреждения о Гончих",
    },
    hound_name = {
        en = "Hound",
        ["zh-cn"] = "猎犬",
        ru = "Гончая",
    },
    burster_colour = {
        en = "Colour for Burster warning",
        ["zh-cn"] = "爆破手警告颜色",
        ru = "Цвет предупреждения о Взрывунах",
    },
    burster_name = {
        en = "Burster",
        ["zh-cn"] = "爆破手",
        ru = "Взрывун",
    },
    flamer_colour = {
        en = "Colour for Flamer warning",
        ["zh-cn"] = "火焰兵警告颜色",
        ru = "Цвет предупреждения об Огнемётчиках",
    },
    flamer_name = {
        en = "Flamer",
        ["zh-cn"] = "火焰兵",
        ru = "Огнемётчик",
    },
    grenadier_colour = {
        en = "Colour for Grenadier warning",
        ["zh-cn"] = "轰炸者警告颜色",
        ru = "Цвет предупреждения о Скабах гренадёрах",
    },
    grenadier_name = {
        en = "Grenadier",
        ["zh-cn"] = "轰炸者",
        ru = "Скаб гренадёр",
    },
    sniper_colour = {
        en = "Colour for Sniper warning",
        ["zh-cn"] = "狙击手警告颜色",
        ru = "Цвет предупреждения о Снайперах",
    },
    sniper_name = {
        en = "Sniper",
        ["zh-cn"] = "狙击手",
        ru = "Снайпер",
    },
    melee_backstab_colour = {
        en = "Colour for Melee Backstab warnings",
        ["zh-cn"] = "近战背刺警告颜色",
        ru = "Цвет предупреждения об ударах ближнего боя в спину",
    },
    ranged_backstab_colour = {
        en = "Colour for Ranged Backstab warnings",
        ["zh-cn"] = "远程背刺警告颜色",
        ru = "Цвет предупреждения об ударах дальнего боя в спину",
    },
    barrel_colour = {
        en = "Colour for Barrel warning",
        ["zh-cn"] = "爆炸桶警告颜色",
        ru = "Цвет предупреждения о взрывающихся бочках",
    },
    barrel_name = {
        en = "Barrel",
        ["zh-cn"] = "爆炸桶",
        ru = "Взрывающаяся бочка",
    },
    crusher_colour = {
        en = "Colour for Crusher warning",
        ["zh-cn"] = "粉碎者警告颜色",
        ru = "Цвет предупреждения о Дробителях",
    },
    crusher_name = {
        en = "Crusher",
        ["zh-cn"] = "粉碎者",
        ru = "Дробитель",
    },
    mauler_colour = {
        en = "Colour for Mauler warning",
        ["zh-cn"] = "重锤兵警告颜色",
        ru = "Цвет предупреждения о Палачах",
    },
    mauler_name = {
        en = "Mauler",
        ["zh-cn"] = "重锤兵",
        ru = "Палач",
    },
    daemonhost_colour = {
        en = "Colour for Daemonhost",
        ["zh-cn"] = "恶魔宿主颜色",
        ru = "Цвет для Демонхоста",
    },
    daemonhost_name = {
        en = "Daemonhost",
        ["zh-cn"] = "恶魔宿主",
        ru = "Демонхост",
    },
    rager_colour = {
        en = "Colour for Ragers",
        ["zh-cn"] = "狂暴者颜色",
        ru = "Цвет для Берсерков",
    },
    rager_name = {
        en = "Rager",
        ["zh-cn"] = "狂暴者",
        ru = "Берсерк",
    },
    toxbomber_colour = {
        en = "Colour for Tox Grenadiers",
        ["zh-cn"] = "剧毒轰炸者颜色",
        ru = "Цвет для Дрегов токс гренадёров",
    },
    toxbomber_name = {
        en = "Tox Grenadier",
        ["zh-cn"] = "剧毒轰炸者",
        ru = "Дрег токс гренадёр",
    },
    plague_ogryn_colour = {
        en = "Colour for Plague Ogryn",
        ["zh-cn"] = "瘟疫欧格林警告颜色",
        ru = "Цвет для Чумного Огрина",
    },
    plague_ogryn_name = {
        en = "Plague Ogryn",
        ["zh-cn"] = "瘟疫欧格林",
        ru = "Чумной Огрин",
    },
    chaos_spawn_colour = {
        en = "Colour for Chaos Spawn",
        ["zh-cn"] = "混沌魔物警告颜色",
        ru = "Цвет для Отродья Хаоса",
    },
    chaos_spawn_name = {
        en = "Chaos Spawn",
        ["zh-cn"] = "混沌魔物",
        ru = "Отродье Хаоса",
    },
    beast_of_nurgle_colour = {
        en = "Colour for Beast of Nurgle",
        ["zh-cn"] = "纳垢兽警告颜色",
        ru = "Цвет для Зверя Нургла",
    },
    beast_of_nurgle_name = {
        en = "Beast of Nurgle",
        ["zh-cn"] = "纳垢兽",
        ru = "Зверь Нургла",
    },
    shotgunner_name = {
      en = "Shotgunner"
    },
    core_options = {
        en = "Core Options",
        ["zh-cn"] = "核心选项",
        ru = "Основные опции",
    },
    active_range = {
        en = "Active Range Indicator",
        ["zh-cn"] = "动态距离指示器",
        ru = "Активный индикатор расстояния",
    },
    active_range_tooltip = {
        en = "This option will move the arc closer to the centre from the 'Distance from standard arc' range, as the target gets closer",
        ["zh-cn"] = "启用此选项后，当目标靠近时，圆弧会比“与原版圆弧之间的距离”更靠近中心",
        ru = "Эта опция переместит индикатор ближе к центру от «Расстояния от стандартной дуги» по мере приближения цели.",
    },
    crusher_text_warnings = {
        en = "Crusher/Mauler Text Warnings",
        ["zh-cn"] = "粉碎者/重锤兵文字警告",
        ru = "Текст предупреждения для Дробителей/Палачей",
    },
    trapper_text_warnings = {
        en = "Trapper Text Warnings",
        ["zh-cn"] = "陷阱手文字警告",
        ru = "Текст предупреждения для Ловушечников",
    },
    pogryn_text_warnings = {
        en = "Plague Ogryn Text Warnings",
        ["zh-cn"] = "瘟疫欧格林文字警告",
        ru = "Текст предупреждения для Чумного огрина",
     },    
    shotgun_text_warnings = {
      en = "Shotgunner Text Warnings",
      ["zh-cn"] = "霰弹枪手文字警告",
      ru = "Текст предупреждения для врагов с дробовиками",
    },
    hound_text_warnings ={
      en = "Hound Text Warnings",
      ["zh-cn"] = "猎犬文字警告",
      ru = "Текст предупреждения для Гончих",
    },
    sniper_text_warnings ={
      en = "Sniper Shot Text Warnings"
    },
    crusher_range_max = {
        en = "Maximum distance for Crusher warning",
        ["zh-cn"] = "粉碎者最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Дробителях",
    },
    trapper_range_max = {
        en = "Maximum distance for Trapper warning",
        ["zh-cn"] = "陷阱手最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Ловушечниках",
    },
    pogryn_range_max = {
        en = "Maximum distance for Plague Ogryn Warning",
        ["zh-cn"] = "瘟疫欧格林最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Чумных огринах",
    },
    pogryn_range_max_description ={
        en = "NB: triggers on initial yell",
        ["zh-cn"] = "注：在第一次吼声时触发",
        ru = "Примечание: срабатывает при первом крике",
    },
    shotgun_range_max = {
        en = "Maximum distance for Shotgunner warning",
        ["zh-cn"] = "霰弹枪手最大警告距离",
        ru = "Максимальная дистанция для предупреждения о врагах с дробовиками",
    },
    hound_range_max = {
        en = "Maximum distance for Hound warning",
        ["zh-cn"] = "猎犬最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Гончих",
    },
    copy_from = {
        en = "Copy From...",
        ["zh-cn"] = "复制自…",
        ru = "Копировать из...",
    },
    cleave_text = {
        en = "CLEAVE!!",
        ["zh-cn"] = "劈砍！！",
        ru = "УДАР СВЕРХУ!!",
    },
    net_text = {
        en = "NET!!",
        ["zh-cn"] = "网！！",
        ru = "СЕТЬ!!",
    },
    charge_text = {
        en = "CHARGE!!",
        ["zh-cn"] = "冲撞！！",
        ru = "БЕЖИТ!!",
    },
    shot_text = {
        en = "SHOT!!",
        ["zh-cn"] = "喷！！",
        ru = "ВЫСТРЕЛ!!",
    },
    pounce_text = {
      en = "POUNCE!!",
      ["zh-cn"] = "扑！！",
      ru = "ПРЫГАЕТ!!",
    },
    sniper_text = {
      en = "SNIPER SHOT!"      
      },
    render_trapper_warning = {
        en = "\"NET!!\" indicator",
        ["zh-cn"] = "“网！！”警告语",
        ru = "Индикатор «СЕТЬ!!»",
    },
    render_trapper_warning_description = {
        en = "Shows NET!! indicator when trapper winds up",
        ["zh-cn"] = "当陷阱手发动攻击时，显示“网！！”警告",
        ru = "Показывает индикатор «СЕТЬ!!» на экране, когда Ловушечник заряжает сетемёт",
    },
    render_crusher_warning = {
        en = "\"CLEAVE!!\" indicator",
        ["zh-cn"] = "“劈砍！！”警告语",
        ru = "Индикатор «УДАР СВЕРХУ!!»",
    },
    render_crusher_warning_description = {
        en = "Shows CLEAVE!! indicator when Crusher or Mauler winds up",
        ["zh-cn"] = "当粉碎者或重锤兵发动攻击时，显示“劈砍！！”警告",
        ru = "Показывает индикатор «УДАР СВЕРХУ!!» на экране, когда Дробитель или Палач собирается нанести неотражаемый удар сверху",
    },
    render_pogryn_warning = {
        en = "\"CHARGE!!\" indicator",
        ["zh-cn"] = "“冲撞！！”警告语",
        ru = "Индикатор «БЕЖИТ!!»",
    },
    render_pogryn_warning_description = {
        en = "Shows CHARGE!! indicator when Plague Ogryn begins to charge",
        ["zh-cn"] = "当瘟疫欧格林开始冲撞时，显示“冲撞！！”警告",
        ru = "Показывает индикатор «БЕЖИТ!!» на экране, когда Чумной огрин разбегается для удара головой",
    },
    render_shotgun_warning = {
      en = "\"SHOT!!\" indicator",
      ["zh-cn"] = "“喷！！”警告语",
      ru = "Индикатор «ВЫСТРЕЛ!!»",
    },
    render_shotgun_warning_description = {
      en = "Shows SHOT!! indicator when the Shotgunner pumps their gun",
      ["zh-cn"] = "当霰弹枪手上膛时，显示“喷！！”警告",
      ru = "Показывает индикатор «ВЫСТРЕЛ!!» на экране, когда враг заряжает дробовик",
    },
    render_hound_warning = {
      en = "\"POUNCE!!\" indicator",
      ["zh-cn"] = "“扑！！”警告语",
      ru = "Индикатор «ПРЫГАЕТ!!»",
    },
    render_hound_warning_description = {
      en = "Shows POUNCE!! indicator when the hound starts its leap",
      ["zh-cn"] = "当猎犬起跳时，显示“扑！！”警告",
      ru = "Показывает индикатор «ПРЫГАЕТ!!» на экране, когда Гончая начинает прыжок",
    },
    render_pack_hound_warning = {
      en = "Include hounds during the Hunting Ground modifier",
      ["zh-cn"] = "包含狩猎场状况下的猎犬",
      ru = "Включить гончих во время игры с модификатором «Охотничьи угодья»",
    },
    render_sniper_warning = {
      en = "Shows SNIPER SHOT! indicator when a sniper fires an aimed shot",
    },
    
    arial = {en = "Arial"},
    itc_novarese_medium = {en = "Novarese Medium"},
    itc_novarese_bold = {en = "Novarese Bold"},
    proxima_nova_light = {en = "Proxima Nova Light"},
    proxima_nova_medium = {en = "Proxima Nova Medium"},
    proxima_nova_bold = {en = "Proxima Nova Bold"},
    friz_quadrata = {en = "Fritz Quadrata"}, -- this is also default Russian font
    rexlia = {en = "Rexila"},
    machine_medium = {en = "Machine Medium"},
    noto_sans_sc_black = {["zh-cn"] = "Noto Sans SC Black"},
    noto_sans_sc_bold = {["zh-cn"] = "Noto Sans SC Bold"} ,    
}
mod.typeList = {{text = "none_name", value = "none"}}

local function addFont(localisations, attack)
  localisations["font_size_"..attack] = {
    en = "Font Size",
    ["zh-cn"] = "字体大小",
    ru = "Размер шрифта",
  }
  localisations["font_colour_"..attack] = {
    en = "Font Color",
    ["zh-cn"] = "字体颜色",
    ru = "Цвет шрифта",
  }
  localisations["font_name_"..attack] = {
    en = "Font Name",
    ["zh-cn"] = "字体名称",
    ru = "Название шрифта",
  }
end

addFont(localizations, "cleave")
addFont(localizations, "net")
addFont(localizations, "charge")
addFont(localizations, "shot")
addFont(localizations, "pounce")
addFont(localizations, "sniper")

local function addLocalisation(localisations, typeName)
    if typeName ~= "melee_backstab" and typeName ~= "ranged_backstab" then
        table.insert(mod.typeList, {text = typeName .. "_name", value = typeName})
    end

    localisations[typeName .. "_active"] = {
        en = "Show indicator",
        ["zh-cn"] = "显示指示器",
        ru = "Показывать индикатор",
    }
    localisations[typeName .. "_only_behind"] = {
        en = "Show indicator only if behind you",
        ["zh-cn"] = "仅当目标在背后时显示指示器",
        ru = "Показывать индикатор только, если кто-то сзади",
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
    localisations[typeName .. "_back_opacity"] = {
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
    localisations[typeName .. "_arrow_colour"] = {
        en = "Proximity Alert Colour",
        ["zh-cn"] = "接近警告颜色",
        ru = "Цвет оповещения о приближении",
    }
    localisations[typeName .. "_active_range"] = {
        en = "Active Range Indicator",
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

addLocalisation(localizations, "melee_backstab")
addLocalisation(localizations, "ranged_backstab")
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
