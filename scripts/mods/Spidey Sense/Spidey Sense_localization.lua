local mod = get_mod("Spidey Sense")
local InputUtils = require("scripts/managers/input/input_utils")

local localizations = {
    mod_name = {
        en = "Spidey Sense",
        ["zh-cn"] = "蜘蛛感应",
        ru = "Паучье чутьё",
        ["zh-tw"] = "蜘蛛感應",
    },
    mod_description = {
        en = "Offers a coloured arc indicator for the direction of sound cues for certain special units",
        ["zh-cn"] = "为某些特殊单位的音效提供彩色的方向圆弧指示器。",
        ["zh-tw"] = "為某些特殊單位的音效提供彩色的方向弧形指示器。",
        ru = "Spidey Sense - Добавляет цветной дуговой индикатор, показывающий направление звуковых сигналов для определённых врагов.",
    },
    invalid_colour_setting = {
        en = " has an invalid color. Please update the arc or text settings",
        ru = " имеет недопустимый цвет. Пожалуйста, обновите настройки дуги или текста",
        ["zh-tw"] = " 的顏色設定無效。請更新弧形或文字設定。",
    },
    none_name = {
        en = "None",
        ["zh-cn"] = "无",
        ["zh-tw"] = "無",
        ru = "Нет",
    },
    mutant_colour = {
        en = "Colour for Mutant warning",
        ["zh-cn"] = "变种人警告颜色",
        ru = "Цвет предупреждения о Мутантах",
        ["zh-tw"] = "變種人警告顏色",
    },
    mutant_name = {
        en = "Mutant",
        ["zh-cn"] = "变种人",
        ru = "Мутант",
        ["zh-tw"] = "變種人",
    },
    trapper_colour = {
        en = "Colour for Trapper warning",
        ["zh-cn"] = "陷阱手警告颜色",
        ru = "Цвет предупреждения о Ловушечниках",
        ["zh-tw"] = "陷阱兵警告顏色",
    },
    trapper_name = {
        en = "Trapper",
        ["zh-cn"] = "陷阱手",
        ru = "Ловушечник",
        ["zh-tw"] = "陷阱兵",
    },
    hound_colour = {
        en = "Colour for Hound warning",
        ["zh-cn"] = "猎犬警告颜色",
        ru = "Цвет предупреждения о Гончих",
        ["zh-tw"] = "瘟疫獵犬警告顏色",
    },
    hound_name = {
        en = "Hound",
        ["zh-cn"] = "猎犬",
        ru = "Гончая",
        ["zh-tw"] = "瘟疫獵犬",
    },
    burster_colour = {
        en = "Colour for Burster warning",
        ["zh-cn"] = "爆破手警告颜色",
        ru = "Цвет предупреждения о Взрывунах",
        ["zh-tw"] = "瘟疫爆者警告顏色",
    },
    burster_name = {
        en = "Burster",
        ["zh-cn"] = "爆破手",
        ru = "Взрывун",
        ["zh-tw"] = "瘟疫爆者",
    },
    flamer_colour = {
        en = "Colour for Flamer warning",
        ["zh-cn"] = "火焰兵警告颜色",
        ru = "Цвет предупреждения об Огнемётчиках",
        ["zh-tw"] = "火焰兵警告顏色",
    },
    flamer_name = {
        en = "Flamer",
        ["zh-cn"] = "火焰兵",
        ru = "Огнемётчик",
        ["zh-tw"] = "火焰兵",
    },
    grenadier_colour = {
        en = "Colour for Grenadier warning",
        ["zh-cn"] = "轰炸者警告颜色",
        ru = "Цвет предупреждения о Скабах гренадёрах",
        ["zh-tw"] = "轟炸者警告顏色",
    },
    grenadier_name = {
        en = "Grenadier",
        ["zh-cn"] = "轰炸者",
        ru = "Скаб гренадёр",
        ["zh-tw"] = "轟炸者",
    },
    sniper_colour = {
        en = "Colour for Sniper warning",
        ["zh-cn"] = "狙击手警告颜色",
        ru = "Цвет предупреждения о Снайперах",
        ["zh-tw"] = "狙擊手警告顏色",
    },
    sniper_name = {
        en = "Sniper",
        ["zh-cn"] = "狙击手",
        ru = "Снайпер",
        ["zh-tw"] = "狙擊手",
    },
    melee_backstab_colour = {
        en = "Colour for Melee Backstab warnings",
        ["zh-cn"] = "近战背刺警告颜色",
        ru = "Цвет предупреждения об ударах ближнего боя в спину",
        ["zh-tw"] = "近戰背刺警告顏色",
    },
    ranged_backstab_colour = {
        en = "Colour for Ranged Backstab warnings",
        ["zh-cn"] = "远程背刺警告颜色",
        ru = "Цвет предупреждения об ударах дальнего боя в спину",
        ["zh-tw"] = "遠程背刺警告顏色",
    },
    barrel_colour = {
        en = "Colour for Barrel warning",
        ["zh-cn"] = "爆炸桶警告颜色",
        ru = "Цвет предупреждения о взрывающихся бочках",
        ["zh-tw"] = "爆炸桶警告顏色",
    },
    barrel_name = {
        en = "Barrel",
        ["zh-cn"] = "爆炸桶",
        ru = "Взрывающаяся бочка",
        ["zh-tw"] = "爆炸桶",
    },
    crusher_colour = {
        en = "Colour for Crusher warning",
        ["zh-cn"] = "粉碎者警告颜色",
        ru = "Цвет предупреждения о Дробителях",
        ["zh-tw"] = "碾壓者警告顏色",
    },
    crusher_name = {
        en = "Crusher",
        ["zh-cn"] = "粉碎者",
        ru = "Дробитель",
        ["zh-tw"] = "碾壓者",
    },
    mauler_colour = {
        en = "Colour for Mauler warning",
        ["zh-cn"] = "重锤兵警告颜色",
        ru = "Цвет предупреждения о Палачах",
        ["zh-tw"] = "重錘兵警告顏色",
    },
    mauler_name = {
        en = "Mauler",
        ["zh-cn"] = "重锤兵",
        ru = "Палач",
        ["zh-tw"] = "重錘兵",
    },
    daemonhost_colour = {
        en = "Colour for Daemonhost",
        ["zh-cn"] = "恶魔宿主颜色",
        ru = "Цвет для Демонхоста",
        ["zh-tw"] = "惡魔宿主顏色",
    },
    daemonhost_name = {
        en = "Daemonhost",
        ["zh-cn"] = "恶魔宿主",
        ru = "Демонхост",
        ["zh-tw"] = "惡魔宿主",
    },
    rager_colour = {
        en = "Colour for Ragers",
        ["zh-cn"] = "狂暴者颜色",
        ru = "Цвет для Берсерков",
        ["zh-tw"] = "狂暴者顏色",
    },
    rager_name = {
        en = "Rager",
        ["zh-cn"] = "狂暴者",
        ru = "Берсерк",
        ["zh-tw"] = "狂暴者",
    },
    toxbomber_colour = {
        en = "Colour for Tox Grenadiers",
        ["zh-cn"] = "剧毒轰炸者颜色",
        ru = "Цвет для Дрегов токс гренадёров",
        ["zh-tw"] = "劇毒轟炸者顏色",
    },
    toxbomber_name = {
        en = "Tox Grenadier",
        ["zh-cn"] = "剧毒轰炸者",
        ru = "Дрег токс гренадёр",
        ["zh-tw"] = "劇毒轟炸者",
    },
    plague_ogryn_colour = {
        en = "Colour for Plague Ogryn",
        ["zh-cn"] = "瘟疫欧格林警告颜色",
        ru = "Цвет для Чумного Огрина",
        ["zh-tw"] = "瘟疫歐格林警告顏色",
    },
    plague_ogryn_name = {
        en = "Plague Ogryn",
        ["zh-cn"] = "瘟疫欧格林",
        ru = "Чумной Огрин",
        ["zh-tw"] = "瘟疫歐格林",
    },
    chaos_spawn_colour = {
        en = "Colour for Chaos Spawn",
        ["zh-cn"] = "混沌魔物警告颜色",
        ru = "Цвет для Отродья Хаоса",
        ["zh-tw"] = "混沌魔物警告顏色",
    },
    chaos_spawn_name = {
        en = "Chaos Spawn",
        ["zh-cn"] = "混沌魔物",
        ru = "Отродье Хаоса",
        ["zh-tw"] = "混沌魔物",
    },
    beast_of_nurgle_colour = {
        en = "Colour for Beast of Nurgle",
        ["zh-cn"] = "纳垢兽警告颜色",
        ru = "Цвет для Зверя Нургла",
        ["zh-tw"] = "納垢巨獸警告顏色",
    },
    beast_of_nurgle_name = {
        en = "Beast of Nurgle",
        ["zh-cn"] = "纳垢兽",
        ru = "Зверь Нургла",
        ["zh-tw"] = "納垢巨獸",
    },
    plasma_gunner_colour = {
       en = "Colour for Plasma Gunner",
       ["zh-tw"] = "電漿槍手警告顏色",
    },
    plasma_gunner_name = {
        en = "Plasma Gunner",
        ["zh-tw"] = "電漿槍手",
    },
    shotgunner_name = {
        en = "Shotgunner",
        ru = "Скаб с дробовиком",
      en = "Shotgunner",
      ["zh-tw"] = "霰彈槍手",
    },
    core_options = {
        en = "Core Options",
        ["zh-cn"] = "核心选项",
        ru = "Основные опции",
        ["zh-tw"] = "核心選項",
    },
    active_range = {
        en = "Active Range Indicator",
        ["zh-cn"] = "动态距离指示器",
        ru = "Активный индикатор расстояния",
        ["zh-tw"] = "動態距離指示器",
    },
    active_range_tooltip = {
        en = "This option will move the arc closer to the centre from the 'Distance from standard arc' range, as the target gets closer",
        ["zh-cn"] = "启用此选项后，当目标靠近时，圆弧会比“与原版圆弧之间的距离”更靠近中心",
        ru = "Эта опция переместит индикатор ближе к центру от «Расстояния от стандартной дуги» по мере приближения цели.",
        ["zh-tw"] = "啟用此選項後，當目標靠近時，弧形會比「與標準弧之間的距離」更接近中心",
    },
    crusher_text_warnings = {
        en = "Crusher/Mauler Text Warnings",
        ["zh-cn"] = "粉碎者/重锤兵文字警告",
        ru = "Текст предупреждения для Дробителей/Палачей",
        ["zh-tw"] = "碾壓者/重錘兵文字警告",
    },
    trapper_text_warnings = {
        en = "Trapper Text Warnings",
        ["zh-cn"] = "陷阱手文字警告",
        ru = "Текст предупреждения для Ловушечников",
        ["zh-tw"] = "陷阱手文字警告",
    },
    pogryn_text_warnings = {
        en = "Plague Ogryn Text Warnings",
        ["zh-cn"] = "瘟疫欧格林文字警告",
        ru = "Текст предупреждения для Чумного огрина",
        ["zh-tw"] = "瘟疫歐格林文字警告",
     },    
    shotgun_text_warnings = {
      en = "Shotgunner Text Warnings",
      ["zh-cn"] = "霰弹枪手文字警告",
      ru = "Текст предупреждения для врагов с дробовиками",
      ["zh-tw"] = "霰彈槍手文字警告",
    },
    hound_text_warnings ={
      en = "Hound Text Warnings",
      ["zh-cn"] = "猎犬文字警告",
      ru = "Текст предупреждения для Гончих",
      ["zh-tw"] = "瘟疫獵犬文字警告",
    },
    sniper_text_warnings ={
      en = "Sniper Shot Text Warnings",
      ru = "Текст предупреждения о снайперах",
      ["zh-tw"] = "狙擊手射擊文字警告",
    },
    crusher_range_max = {
        en = "Maximum distance for Crusher warning",
        ["zh-cn"] = "粉碎者最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Дробителях",
        ["zh-tw"] = "碾壓者最大警告距離",
    },
    trapper_range_max = {
        en = "Maximum distance for Trapper warning",
        ["zh-cn"] = "陷阱手最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Ловушечниках",
        ["zh-tw"] = "陷阱兵最大警告距離",
    },
    pogryn_range_max = {
        en = "Maximum distance for Plague Ogryn Warning",
        ["zh-cn"] = "瘟疫欧格林最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Чумных огринах",
        ["zh-tw"] = "瘟疫歐格林最大警告距離",
    },
    pogryn_range_max_description ={
        en = "NB: triggers on initial yell",
        ["zh-cn"] = "注：在第一次吼声时触发",
        ru = "Примечание: срабатывает при первом крике",
        ["zh-tw"] = "注意：在第一次吼叫時觸發",
    },
    shotgun_range_max = {
        en = "Maximum distance for Shotgunner warning",
        ["zh-cn"] = "霰弹枪手最大警告距离",
        ru = "Максимальная дистанция для предупреждения о врагах с дробовиками",
        ["zh-tw"] = "霰彈槍手最大警告距離",
    },
    hound_range_max = {
        en = "Maximum distance for Hound warning",
        ["zh-cn"] = "猎犬最大警告距离",
        ru = "Максимальная дистанция для предупреждения о Гончих",
        ["zh-tw"] = "瘟疫獵犬最大警告距離",
    },
    copy_from = {
        en = "Copy From...",
        ["zh-cn"] = "复制自…",
        ru = "Копировать из...",
        ["zh-tw"] = "複製自…",
    },
    cleave_text = {
        en = "CLEAVE!!",
        ["zh-cn"] = "劈砍！！",
        ru = "УДАР СВЕРХУ!!",
        ["zh-tw"] = "劈砍!!",
    },
    net_text = {
        en = "NET!!",
        ["zh-cn"] = "网！！",
        ru = "СЕТЬ!!",
        ["zh-tw"] = "網!!",
    },
    charge_text = {
        en = "CHARGE!!",
        ["zh-cn"] = "冲撞！！",
        ru = "БЕЖИТ!!",
        ["zh-tw"] = "衝撞!!",
    },
    shot_text = {
        en = "SHOT!!",
        ["zh-cn"] = "喷！！",
        ru = "ВЫСТРЕЛ!!",
        ["zh-tw"] = "噴!!",
    },
    pounce_text = {
      en = "POUNCE!!",
      ["zh-cn"] = "扑！！",
      ru = "ПРЫГАЕТ!!",
      ["zh-tw"] = "撲!!",
    },
    sniper_text = {
      en = "SNIPER SHOT!",
      ru = "ВЫСТРЕЛ СНАЙПЕРА!",
      ["zh-tw"] = "狙擊!!",
      },
    render_trapper_warning = {
        en = "\"NET!!\" indicator",
        ["zh-cn"] = "“网！！”警告语",
        ru = "Индикатор «СЕТЬ!!»",
        ["zh-tw"] = "「網!!」警告語",
    },
    render_trapper_warning_description = {
        en = "Shows NET!! indicator when trapper winds up",
        ["zh-cn"] = "当陷阱手发动攻击时，显示“网！！”警告",
        ru = "Показывает индикатор «СЕТЬ!!» на экране, когда Ловушечник заряжает сетемёт",
        ["zh-tw"] = "當陷阱手準備發動攻擊時，顯示「網!!」警告",
    },
    render_crusher_warning = {
        en = "\"CLEAVE!!\" indicator",
        ["zh-cn"] = "“劈砍！！”警告语",
        ru = "Индикатор «УДАР СВЕРХУ!!»",
        ["zh-tw"] = "「劈砍!!」警告語",
    },
    render_crusher_warning_description = {
        en = "Shows CLEAVE!! indicator when Crusher or Mauler winds up",
        ["zh-cn"] = "当粉碎者或重锤兵发动攻击时，显示“劈砍！！”警告",
        ru = "Показывает индикатор «УДАР СВЕРХУ!!» на экране, когда Дробитель или Палач собирается нанести неотражаемый удар сверху",
        ["zh-tw"] = "當碾壓者或重錘兵準備攻擊時，顯示「劈砍!!」警告",
    },
    render_pogryn_warning = {
        en = "\"CHARGE!!\" indicator",
        ["zh-cn"] = "“冲撞！！”警告语",
        ru = "Индикатор «БЕЖИТ!!»",
        ["zh-tw"] = "「衝撞!!」警告語",
    },
    render_pogryn_warning_description = {
        en = "Shows CHARGE!! indicator when Plague Ogryn begins to charge",
        ["zh-cn"] = "当瘟疫欧格林开始冲撞时，显示“冲撞！！”警告",
        ru = "Показывает индикатор «БЕЖИТ!!» на экране, когда Чумной огрин разбегается для удара головой",
        ["zh-tw"] = "當瘟疫歐格林開始衝撞時，顯示「衝撞!!」警告",
    },
    render_shotgun_warning = {
      en = "\"SHOT!!\" indicator",
      ["zh-cn"] = "“喷！！”警告语",
      ru = "Индикатор «ВЫСТРЕЛ!!»",
      ["zh-tw"] = "「噴!!」警告語",
    },
    render_shotgun_warning_description = {
      en = "Shows SHOT!! indicator when the Shotgunner pumps their gun",
      ["zh-cn"] = "当霰弹枪手上膛时，显示“喷！！”警告",
      ru = "Показывает индикатор «ВЫСТРЕЛ!!» на экране, когда враг заряжает дробовик",
      ["zh-tw"] = "當霰彈槍手上膛時，顯示「噴!!」警告",
    },
    render_hound_warning = {
      en = "\"POUNCE!!\" indicator",
      ["zh-cn"] = "“扑！！”警告语",
      ru = "Индикатор «ПРЫГАЕТ!!»",
      ["zh-tw"] = "「撲!!」警告語",
    },
    render_hound_warning_description = {
      en = "Shows POUNCE!! indicator when the hound starts its leap",
      ["zh-cn"] = "当猎犬起跳时，显示“扑！！”警告",
      ru = "Показывает индикатор «ПРЫГАЕТ!!» на экране, когда Гончая начинает прыжок",
      ["zh-tw"] = "當瘟疫獵犬起跳時，顯示「撲!!」警告",
    },
    render_pack_hound_warning = {
      en = "Include hounds during the Hunting Ground modifier",
      ["zh-cn"] = "包含狩猎场状况下的猎犬",
      ru = "Включая гончих в «Охотничьих угодьях»",
      ["zh-tw"] = "在狩獵場修正中包含獵犬",
    },
    render_sniper_warning = {
      en = "\"SNIPER SHOT!\" indicator",
      ru = "Индикатор «ВЫСТРЕЛ СНАЙПЕРА!»",
      ["zh-tw"] = "「狙擊!!」警告語",
    },
    render_sniper_warning_description = {
      en = "Shows SNIPER SHOT! indicator when a sniper fires an aimed shot",
      ru = "Показывает индикатор «ВЫСТРЕЛ СНАЙПЕРА!» на экране, когда снайпер готов выстрелить",
      ["zh-tw"] = "當狙擊手進行瞄準射擊時顯示「狙擊!！」警告",
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
    ["zh-tw"] = "字體大小",
  }
  localisations["font_colour_"..attack] = {
    en = "Font Color",
    ["zh-cn"] = "字体颜色",
    ru = "Цвет шрифта",
    ["zh-tw"] = "字體顏色",
  }
  localisations["font_name_"..attack] = {
    en = "Font Name",
    ["zh-cn"] = "字体名称",
    ru = "Название шрифта",
    ["zh-tw"] = "字體名稱",
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
        ["zh-tw"] = "顯示指示器",
    }
    localisations[typeName .. "_only_behind"] = {
        en = "Show indicator only if behind you",
        ["zh-cn"] = "仅当目标在背后时显示指示器",
        ru = "Показывать индикатор только, если кто-то сзади",
        ["zh-tw"] = "僅當目標在背後時顯示指示器",
    }
    localisations[typeName .. "_front_opacity"] = {
        en = "Foreground Opacity",
        ["zh-cn"] = "前景不透明度",
        ru = "Прозрачность переднего плана",
        ["zh-tw"] = "前景不透明度",
    }
    localisations[typeName .. "_front_colour"] = {
        en = "Foreground Colour",
        ["zh-cn"] = "前景颜色",
        ru = "Цвет переднего плана",
        ["zh-tw"] = "前景顏色",
    }
    localisations[typeName .. "_back_opacity"] = {
        en = "Background Opacity",
        ["zh-cn"] = "背景不透明度",
        ru = "Прозрачность заднего плана",
        ["zh-tw"] = "背景不透明度",
    }
    localisations[typeName .. "_back_colour"] = {
        en = "Background Colour",
        ["zh-cn"] = "背景颜色",
        ru = "Цвет заднего плана",
        ["zh-tw"] = "背景顏色",
    }
    localisations[typeName .. "_radius"] = {
        en = "Distance from standard arc",
        ["zh-cn"] = "与原版圆弧之间的距离",
        ru = "Расстояние от стандартной дуги",
        ["zh-tw"] = "與標準弧之間的距離",
    }
    localisations[typeName .. "_distance"] = {
        en = "Detection range (m)",
        ["zh-cn"] = "检测距离（米）",
        ru = "Дистанция обнаружения (м)",
        ["zh-tw"] = "偵測距離（米）",
    }
    localisations[typeName .. "_arrow_distance"] = {
        en = "Proximity Alert Range (m)",
        ["zh-cn"] = "接近警告距离（米）",
        ru = "Дистанция оповещения о приближении (м)",
        ["zh-tw"] = "接近警告距離（米）",
    }
    localisations[typeName .. "_arrow_colour"] = {
        en = "Proximity Alert Colour",
        ["zh-cn"] = "接近警告颜色",
        ru = "Цвет оповещения о приближении",
        ["zh-tw"] = "接近警告顏色",
    }
    localisations[typeName .. "_active_range"] = {
        en = "Active Range Indicator",
        ["zh-cn"] = "动态距离指示器",
        ru = "Активный индикатор расстояния",
        ["zh-tw"] = "動態距離指示器",
    }
    localisations[typeName .. "_nurgle_blessed"] = {
        en = "Indicate Nurgle Blessed",
        ["zh-cn"] = "指示纳垢赐福敌人",
        ru = "Показывать благословенных Нурглом",
        ["zh-tw"] = "指示納垢祝福敵人",
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
addLocalisation(localizations, "plasma_gunner")
addLocalisation(localizations, "rager")
addLocalisation(localizations, "sniper")
addLocalisation(localizations, "trapper")
addLocalisation(localizations, "toxbomber")

return localizations
