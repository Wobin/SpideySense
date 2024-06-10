local mod = get_mod("Spidey Sense")
local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")

local getFonts = function()
    local options = {}
    for i, v in pairs(FontDefinitions.fonts) do
        table.insert(options, {text = i, value = i})
    end
    local current_locale = Managers.localization and Managers.localization:language()
    if locale == "zh-cn" then
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
local color_options = {}
for i, color_name in ipairs(Color.list) do
    table.insert(
        color_options,
        {
            text = color_name,
            value = color_name
        }
    )
end
table.sort(color_options, function(a, b) return a.text < b.text end
)

local function get_color_options()
    return table.clone(color_options)
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
                type = "dropdown",
                default_value = defaultColour1,
                options = get_color_options()
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
                type = "dropdown",
                default_value = defaultColour1,
                options = get_color_options()
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
                type = "dropdown",
                default_value = defaultColour2,
                options = get_color_options()
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

mod.on_setting_changed = function(setting_id)
    if not setting_id:match("_copy_from") then
        return
    end    
    local typeName = string.sub(setting_id, 1, string.find(setting_id, "_copy_from") - 1)    
    local new_value = mod:get(setting_id)
    mod:set(typeName .. "_active", mod:get(new_value .. "_active"), false)
    mod:set(typeName .. "_radius", mod:get(new_value .. "_radius"), false)
    mod:set(typeName .. "_active_range", mod:get(new_value .. "_active_range"), false)
    mod:set(typeName .. "_nurgle_blessed", mod:get(new_value .. "_nurgle_blessed"), false)
    mod:set(typeName .. "_distance", mod:get(new_value .. "_distance"), false)
    mod:set(typeName .. "_arrow_distance", mod:get(new_value .. "_arrow_distance"), false)
    mod:set(typeName .. "_arrow_colour", mod:get(new_value .. "_arrow_colour"), false)
    mod:set(typeName .. "_only_behind", mod:get(new_value .. "_only_behind"), false)
    mod:set(typeName .. "_front_opacity", mod:get(new_value .. "_front_opacity"), false)
    mod:set(typeName .. "_front_colour", mod:get(new_value .. "_front_colour"), false)
    mod:set(typeName .. "_back_opacity", mod:get(new_value .. "_back_opacity"), false)
    mod:set(typeName .. "_back_colour", mod:get(new_value .. "_back_colour"), false)
    mod:set(setting_id, "none", false)
end

table.insert(options.options.widgets, create_option_set("burster", "burly_wood", "citadel_averland_sunset"))
table.insert(options.options.widgets, create_option_set("barrel", "cheeseburger", "citadel_balthasar_gold"))
table.insert(options.options.widgets, create_option_set("beast_of_nurgle", "citadel_dorn_yellow", "citadel_balthasar_gold"))
table.insert(options.options.widgets, create_option_set("crusher", "sienna", "ui_red_medium"))
table.insert(options.options.widgets, create_option_set("chaos_spawn", "cheeseburger", "ui_red_medium"))
table.insert(options.options.widgets, create_option_set("daemonhost", "teal", "blue_violet"))
table.insert(options.options.widgets, create_option_set("flamer", "online_green", "medium_violet_red"))
table.insert(options.options.widgets, create_option_set("grenadier", "sandy_brown", "ui_interaction_pickup"))
table.insert(options.options.widgets, create_option_set("hound", "chart_reuse", "cadet_blue"))
table.insert(options.options.widgets, create_option_set("mauler", "turquoise", "ui_blue_light"))
table.insert(options.options.widgets, create_option_set("mutant", "ui_green_light", "spring_green"))
table.insert(options.options.widgets, create_option_set("plague_ogryn", "powder_blue", "citadel_bieltan_green"))
table.insert(options.options.widgets, create_option_set("rager", "medium_spring_green", "midnight_blue"))
table.insert(options.options.widgets, create_option_set("sniper", "powder_blue", "ui_ability_purple"))
table.insert(options.options.widgets, create_option_set("trapper", "ui_hud_overcharge_medium", "ui_hud_overcharge_low"))
table.insert(options.options.widgets, create_option_set("toxbomber", "chart_reuse", "citadel_bieltan_green"))
table.insert(
    options.options.widgets,
    {
        setting_id = "backstab_colour",
        type = "group",
        sub_widgets = {
            {
                setting_id = "backstab_active",
                type = "checkbox",
                default_value = true
            },
            {
                setting_id = "backstab_radius",
                type = "numeric",
                default_value = 50,
                range = {0, 200},
                decimals_number = 0
            },
            {
                setting_id = "backstab_distance",
                type = "numeric",
                default_value = 40,
                range = {0, 40},
                decimals_number = 0
            },
            {
                setting_id = "backstab_front_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = "backstab_front_colour",
                type = "dropdown",
                default_value = "ui_terminal",
                options = get_color_options()
            },
            {
                setting_id = "backstab_back_opacity",
                type = "numeric",
                default_value = 255,
                range = {0, 255},
                decimals_number = 0
            },
            {
                setting_id = "backstab_back_colour",
                type = "dropdown",
                default_value = "ui_terminal",
                options = get_color_options()
            }
        }
    }
)
table.insert(
    options.options.widgets,
    {
        setting_id = "crusher_text_warnings",
        type = "group",
        sub_widgets = {
            {
                setting_id = "render_crusher_warning",
                type = "checkbox",
                tooltip = "render_crusher_warning_description",
                default_value = false
            },
            {
                setting_id = "crusher_range_max",
                type = "numeric",
                default_value = 10,
                range = {5, 20}
            },
            {
                setting_id = "font_size_cleave",
                type = "numeric",
                default_value = 28,
                range = {28, 125}
            },
            {
                setting_id = "font_name_cleave",
                type = "dropdown",
                default_value = "proxima_nova_light",
                options = getFonts()
            },
            {
                setting_id = "font_color_cleave",
                type = "dropdown",
                default_value = "ui_terminal",
                options = get_color_options()
            }
        }
    }
)
table.insert(
    options.options.widgets,
    {
        setting_id = "trapper_text_warnings",
        type = "group",
        sub_widgets = {
            {
                setting_id = "render_trapper_warning",
                type = "checkbox",
                tooltip = "render_trapper_warning_description",
                default_value = false
            },
--[[            {
                setting_id = "netboomer",
                tooltip = "netboomer_tooltip",
                type = "checkbox",                
                default_value = false
            },--]]
            {
                setting_id = "trapper_range_max",
                type = "numeric",
                default_value = 15,
                range = {15, 35}
            },
            {
                setting_id = "font_size_net",
                type = "numeric",
                default_value = 28,
                range = {28, 125}
            },
            {
                setting_id = "font_name_net",
                type = "dropdown",
                default_value = "proxima_nova_light",
                options = getFonts()
            },
            {
                setting_id = "font_color_net",
                type = "dropdown",
                default_value = "ui_terminal",
                options = get_color_options()
            }
        }
    }
)

return options
