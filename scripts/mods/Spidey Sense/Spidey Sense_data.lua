local mod = get_mod("Spidey Sense")
local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")

local getFonts = function()
    local options = {}
    for i, v in pairs(FontDefinitions.fonts) do
        table.insert(options, {text = i, value = i})
    end
    local current_locale = Managers.localization and Managers.localization:language()
    if current_locale == "zh-cn" then
        table.insert(options, {text = "noto_sans_sc_black", value = "noto_sans_sc_black"})
        table.insert(options, {text = "noto_sans_sc_bold", value = "noto_sans_sc_bold"})
    end
    return options
end

local options = {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {}
    }
}
local function colour_default(name)
    if type(name) == "table" then
        return name
    end

    local swatch = rawget(Color, name)

    if swatch then
        return swatch(255, true)
    end

    return Color.white(255, true)
end

local function create_option_set(typeName, defaultColour1, defaultColour2)
    return {
        setting_id = typeName .. "_colour",
        type = "group",
        sub_widgets = {
            {
                setting_id = typeName .. "_active",
                type = "checkbox",
                default_value = true
            },
            {
                setting_id = typeName .. "_radius",
                type = "numeric",
                default_value = 50,
                range = {-125, 200},
                decimals_number = 0
            },
            {
                setting_id = typeName .. "_active_range",
                type = "checkbox",
                tooltip = "active_range_tooltip",
                default_value = false
            },
            {
                setting_id = typeName .. "_nurgle_blessed",
                type = "checkbox",
                tooltip = "active_range_tooltip",
                default_value = false
            },
            {
                setting_id = typeName .. "_distance",
                type = "numeric",
                default_value = 40,
                range = {0, 40},
                decimals_number = 0
            },
            {
                setting_id = typeName .. "_arrow_distance",
                type = "numeric",
                default_value = 0,
                range = {0, 40},
                decimals_number = 0
            },
            {
                setting_id = typeName .. "_arrow_colour",
                type = "color",
                default_value = colour_default(defaultColour1),
                has_alpha = false
            },
            {
                setting_id = typeName .. "_only_behind",
                type = "checkbox",
                default_value = false
            },
            {
                setting_id = typeName .. "_front_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = typeName .. "_front_colour",
                type = "color",
                default_value = colour_default(defaultColour1),
                has_alpha = false
            },
            {
                setting_id = typeName .. "_back_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = typeName .. "_back_colour",
                type = "color",
                default_value = colour_default(defaultColour2),
                has_alpha = false
            },
            {
                setting_id = typeName .. "_multi_enemy_show_numbers",
                type = "checkbox",
                tooltip = "multi_enemy_show_numbers_tooltip",
                default_value = false
            },
            {
                setting_id = typeName .. "_copy_from",
                title = "copy_from",
                type = "dropdown",
                options = table.clone(mod.typeList),
                default_value = "none"
            }
        }
    }
end

table.insert(options.options.widgets, {
    setting_id = "arc_side",
    type = "dropdown",
    tooltip = "arc_side_tooltip",
    default_value = "both",
    options = {
        {text = "arc_side_both",  value = "both"},
        {text = "arc_side_left",  value = "left"},
        {text = "arc_side_right", value = "right"},
    }
})

local enemy_blocks = {}
local warning_blocks = {}

table.insert(enemy_blocks, create_option_set("burster", "burly_wood", "citadel_averland_sunset"))
table.insert(enemy_blocks, create_option_set("barrel", "cheeseburger", "citadel_balthasar_gold"))
table.insert(enemy_blocks, create_option_set("beast_of_nurgle", "citadel_dorn_yellow", "citadel_balthasar_gold"))
table.insert(enemy_blocks, create_option_set("crusher", "sienna", "ui_red_medium"))
table.insert(enemy_blocks, create_option_set("chaos_spawn", "cheeseburger", "ui_red_medium"))
table.insert(enemy_blocks, create_option_set("daemonhost", "teal", "blue_violet"))
table.insert(enemy_blocks, create_option_set("flamer", "online_green", "medium_violet_red"))
table.insert(enemy_blocks, create_option_set("grenadier", "sandy_brown", "ui_interaction_pickup"))
table.insert(enemy_blocks, create_option_set("hound", "chart_reuse", "cadet_blue"))
table.insert(enemy_blocks, create_option_set("mauler", "turquoise", "ui_blue_light"))
table.insert(enemy_blocks, create_option_set("mutant", "ui_green_light", "spring_green"))
table.insert(enemy_blocks, create_option_set("plague_ogryn", "powder_blue", "citadel_bieltan_green"))
table.insert(enemy_blocks, create_option_set("plasma_gunner", "royal_blue", "tomato"))
table.insert(enemy_blocks, create_option_set("rager", "medium_spring_green", "midnight_blue"))
table.insert(enemy_blocks, create_option_set("sniper", "powder_blue", "ui_ability_purple"))
table.insert(enemy_blocks, create_option_set("trapper", "ui_hud_warp_charge_medium", "ui_hud_warp_charge_low"))
table.insert(enemy_blocks, create_option_set("toxbomber", "chart_reuse", "citadel_bieltan_green"))
table.insert(
    enemy_blocks,
    {
        setting_id = "melee_backstab_colour",
        type = "group",
        sub_widgets = {
            {
                setting_id = "melee_backstab_active",
                type = "checkbox",
                default_value = true
            },
            {
                setting_id = "melee_backstab_radius",
                type = "numeric",
                default_value = 50,
                range = {0, 200},
                decimals_number = 0
            },
            {
                setting_id = "melee_backstab_distance",
                type = "numeric",
                default_value = 40,
                range = {0, 40},
                decimals_number = 0
            },
            {
                setting_id = "melee_backstab_front_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = "melee_backstab_front_colour",
                type = "color",
                default_value = colour_default("ui_terminal"),
                has_alpha = false
            },
            {
                setting_id = "melee_backstab_back_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = "melee_backstab_back_colour",
                type = "color",
                default_value = colour_default("ui_terminal"),
                has_alpha = false
            }
        }
    }
)
table.insert(
    enemy_blocks,
    {
        setting_id = "ranged_backstab_colour",
        type = "group",
        sub_widgets = {
            {
                setting_id = "ranged_backstab_active",
                type = "checkbox",
                default_value = true
            },
            {
                setting_id = "ranged_backstab_radius",
                type = "numeric",
                default_value = 50,
                range = {0, 200},
                decimals_number = 0
            },
            {
                setting_id = "ranged_backstab_distance",
                type = "numeric",
                default_value = 40,
                range = {0, 40},
                decimals_number = 0
            },
            {
                setting_id = "ranged_backstab_front_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = "ranged_backstab_front_colour",
                type = "color",
                default_value = colour_default("ui_terminal"),
                has_alpha = false
            },
            {
                setting_id = "ranged_backstab_back_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = "ranged_backstab_back_colour",
                type = "color",
                default_value = colour_default("ui_terminal"),
                has_alpha = false
            }
        }
    }
)

local add_warning = function(typeName, attackName)
  table.insert(
    warning_blocks,
    {
        setting_id = typeName.."_text_warnings",
        type = "group",
        sub_widgets = {
            {
                setting_id = "render_".. typeName .."_warning",
                type = "checkbox",
                tooltip = "render_".. typeName .."_warning_description",
                default_value = false
            },
            {
                setting_id = typeName .."_range_max",
                type = "numeric",                
                default_value = 10,
                range = {5, 20}
            },
            {
                setting_id = "font_size_".. attackName,
                type = "numeric",
                default_value = 28,
                range = {28, 125}
            },
            {
                setting_id = "font_name_".. attackName,
                type = "dropdown",
                default_value = "proxima_nova_light",
                options = getFonts()
            },
            {
                setting_id = "font_colour_".. attackName,
                type = "color",
                default_value = colour_default("ui_terminal"),
                has_alpha = false
            }
        }
    }
  )
end

add_warning("crusher", "cleave")
add_warning("trapper", "net")
add_warning("pogryn", "charge")
add_warning("shotgun", "shot")
add_warning("hound", "pounce")
add_warning("sniper", "sniper")

local insert_pack_warning = {
                setting_id = "render_pack_hound_warning",
                type = "checkbox",                
                default_value = false
  }

local _, pogryn = table.find_by_key(warning_blocks, "setting_id", "pogryn_text_warnings")
local _, subwidget = table.find_by_key(pogryn.sub_widgets, "setting_id", "pogryn_range_max")
subwidget.tooltip = "render_pogryn_warning_description"

local _, hound = table.find_by_key(warning_blocks, "setting_id", "hound_text_warnings")
table.insert(hound.sub_widgets, 2, insert_pack_warning)
local _, houndsubwidget = table.find_by_key(hound.sub_widgets, "setting_id", "hound_range_max")
houndsubwidget.range = {5,50}
houndsubwidget.default_value = 20

local _, sniper = table.find_by_key(warning_blocks, "setting_id", "sniper_text_warnings")
local sniperkey, snipersubwidget = table.find_by_key(sniper.sub_widgets, "setting_id", "sniper_range_max")
table.remove(sniper.sub_widgets, sniperkey)

local function build_selector(blocks, label_of, section_id, selector_id, title_key, placeholder_key, pin_last)
    pin_last = pin_last or {}

    table.sort(blocks, function(a, b)
        local pinned_a = pin_last[a.setting_id] and 1 or 0
        local pinned_b = pin_last[b.setting_id] and 1 or 0

        if pinned_a ~= pinned_b then
            return pinned_a < pinned_b
        end

        return mod:localize(label_of(a)) < mod:localize(label_of(b))
    end)

    local selector_options = {
        {text = placeholder_key, value = "none", show_widgets = {}}
    }

    for i = 1, #blocks do
        selector_options[i + 1] = {
            text = label_of(blocks[i]),
            value = blocks[i].setting_id,
            show_widgets = {i}
        }
    end

    local stored = mod:get(selector_id)

    if stored ~= nil then
        local known = false

        for i = 1, #selector_options do
            if selector_options[i].value == stored then
                known = true
                break
            end
        end

        if not known then
            mod:set(selector_id, "none")
        end
    end

    return {
        setting_id = section_id,
        type = "group",
        title = section_id,
        sub_widgets = {
            {
                setting_id = selector_id,
                type = "dropdown",
                title = title_key,
                default_value = "none",
                options = selector_options,
                sub_widgets = blocks
            }
        }
    }
end

table.insert(options.options.widgets, build_selector(
    enemy_blocks,
    function(block) return (string.gsub(block.setting_id, "_colour$", "_name")) end,
    "enemy_type_settings",
    "enemy_type_selector",
    "enemy_type",
    "select_enemy_type",
    {melee_backstab_colour = true, ranged_backstab_colour = true}
))

table.insert(options.options.widgets, build_selector(
    warning_blocks,
    function(block) return block.setting_id end,
    "text_warning_settings",
    "text_warning_selector",
    "text_warning_type",
    "select_text_warning"
))

local colour_setting_defaults = {}

local enemy_colour_defaults = mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/core/Colours")

for type_name, slots in pairs(enemy_colour_defaults) do
    for slot, default_colour in pairs(slots) do
        colour_setting_defaults[type_name .. "_" .. slot .. "_colour"] = default_colour
    end
end

local warning_attacks = { "cleave", "net", "charge", "shot", "pounce", "sniper" }
for _, attack in ipairs(warning_attacks) do
    colour_setting_defaults["font_colour_" .. attack] = "ui_terminal"
end

for setting_id, default_colour in pairs(colour_setting_defaults) do
    local value = mod:get(setting_id)

    if type(value) == "string" then
        mod:set(setting_id, colour_default(value), false)
    elseif value ~= nil and type(value) ~= "table" then
        mod:set(setting_id, colour_default(default_colour), false)
    end
end

return options
