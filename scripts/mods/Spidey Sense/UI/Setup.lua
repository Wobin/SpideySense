local mod = get_mod("Spidey Sense")

local ui_scale = 1.5
local WIDTH = 500
local HEIGHT = 600
local OFFSET = 100
local DEFAULT_COLOR_NAME = "white"
local DEFAULT_WARNING_FONT_COLOR = "ui_terminal"
local DEFAULT_WARNING_FONT_SIZE = 28
local DEFAULT_WARNING_RANGE = 10
local DEFAULT_ENEMY_RADIUS = 50
local DEFAULT_ENEMY_DISTANCE = 40
local DEFAULT_OPACITY = 255

local first_run = true
local window_width = math.min(WIDTH * ui_scale, RESOLUTION_LOOKUP.width - OFFSET)
local window_height = math.min(HEIGHT * ui_scale, RESOLUTION_LOOKUP.height - OFFSET)

local Managers = Managers
local Imgui_text
local Imgui_is_item_hovered
local Imgui_begin_tool_tip
local Imgui_end_tool_tip

local function localize_or_key(value)
    return mod:localize(value) or value
end

local function show_tooltip(tooltip_id)
    if tooltip_id and Imgui_is_item_hovered() then
        Imgui_begin_tool_tip()
        Imgui_text(mod:localize(tooltip_id))
        Imgui_end_tool_tip()
    end
end

local function color_name_to_rgb(color_name)
    if type(color_name) == "table" then
        return color_name
    end

    if type(color_name) == "string" and Color[color_name] then
        return Color[color_name](255, true)
    end

    return {255, 255, 255, 255}
end

local function get_color_setting(setting_id, default_color_name)
    local value = mod:get(setting_id)

    if not value then
        return color_name_to_rgb(default_color_name or DEFAULT_COLOR_NAME)
    end

    if type(value) == "string" then
        local rgb = color_name_to_rgb(value)
        mod:set(setting_id, rgb, false)
        return rgb
    end

    return value
end

-- Enemy types list
local enemy_types = {
    "burster",
    "barrel",
    "beast_of_nurgle",
    "crusher",
    "chaos_spawn",
    "daemonhost",
    "flamer",
    "grenadier",
    "hound",
    "mauler",
    "mutant",
    "plague_ogryn",
    "plasma_gunner",
    "rager",
    "sniper",
    "trapper",
    "toxbomber",
    "melee_backstab",
    "ranged_backstab",
}

-- Text warning types list
local text_warning_types = {
    {type = "crusher", attack = "cleave"},
    {type = "trapper", attack = "net"},
    {type = "pogryn", attack = "charge"},
    {type = "shotgun", attack = "shot"},
    {type = "hound", attack = "pounce"},
    {type = "sniper", attack = "sniper"},
}

-- Available fonts list (function to support locale-specific fonts)
local function get_available_fonts_impl()
    local fonts = {
        "arial",
        "itc_novarese_medium",
        "itc_novarese_bold",
        "proxima_nova_light",
        "proxima_nova_medium",
        "proxima_nova_bold",
        "friz_quadrata",
        "rexlia",
        "machine_medium",
    }
    
    -- Add Chinese fonts for Chinese locale
    local current_locale = Managers.localization and Managers.localization:language()
    if current_locale == "zh-cn" then
        table.insert(fonts, "noto_sans_sc_black")
        table.insert(fonts, "noto_sans_sc_bold")
    end
    
    return fonts
end

-- Cache the font list at initialization
local available_fonts = get_available_fonts_impl()

-- Default colors for enemy types (for migration)
mod.ui.default_colors = {
    burster = {front = "burly_wood", back = "citadel_averland_sunset", arrow = "burly_wood"},
    barrel = {front = "cheeseburger", back = "citadel_balthasar_gold", arrow = "cheeseburger"},
    beast_of_nurgle = {front = "citadel_dorn_yellow", back = "citadel_balthasar_gold", arrow = "citadel_dorn_yellow"},
    crusher = {front = "sienna", back = "ui_red_medium", arrow = "sienna"},
    chaos_spawn = {front = "cheeseburger", back = "ui_red_medium", arrow = "cheeseburger"},
    daemonhost = {front = "teal", back = "blue_violet", arrow = "teal"},
    flamer = {front = "online_green", back = "medium_violet_red", arrow = "online_green"},
    grenadier = {front = "sandy_brown", back = "ui_interaction_pickup", arrow = "sandy_brown"},
    hound = {front = "chart_reuse", back = "cadet_blue", arrow = "chart_reuse"},
    mauler = {front = "turquoise", back = "ui_blue_light", arrow = "turquoise"},
    mutant = {front = "ui_green_light", back = "spring_green", arrow = "ui_green_light"},
    plague_ogryn = {front = "powder_blue", back = "citadel_bieltan_green", arrow = "powder_blue"},
    plasma_gunner = {front = "royal_blue", back = "tomato", arrow = "royal_blue"},
    rager = {front = "medium_spring_green", back = "midnight_blue", arrow = "medium_spring_green"},
    sniper = {front = "powder_blue", back = "ui_ability_purple", arrow = "powder_blue"},
    trapper = {front = "ui_hud_warp_charge_medium", back = "ui_hud_warp_charge_low", arrow = "ui_hud_warp_charge_medium"},
    toxbomber = {front = "chart_reuse", back = "citadel_bieltan_green", arrow = "chart_reuse"},
    melee_backstab = {front = "ui_terminal", back = "ui_terminal"},
    ranged_backstab = {front = "ui_terminal", back = "ui_terminal"},
}
local default_colors = mod.ui.default_colors

-- Local Imgui refs for performance
local Imgui = Imgui
local Imgui_checkbox = Imgui.checkbox
local Imgui_slider_int = Imgui.slider_int
local Imgui_begin_combo = Imgui.begin_combo
local Imgui_selectable = Imgui.selectable
local Imgui_end_combo = Imgui.end_combo
Imgui_text = Imgui.text
local Imgui_separator = Imgui.separator
local Imgui_set_next_window_size = Imgui.set_next_window_size
local Imgui_set_next_window_pos = Imgui.set_next_window_pos
local Imgui_begin_window = Imgui.begin_window
local Imgui_set_window_font_scale = Imgui.set_window_font_scale
local Imgui_end_window = Imgui.end_window
local Imgui_open_imgui = Imgui.open_imgui
local Imgui_close_imgui = Imgui.close_imgui
local Imgui_spacing = Imgui.spacing
local Imgui_color_edit_3 = Imgui.color_edit_3
Imgui_is_item_hovered = Imgui.is_item_hovered
Imgui_begin_tool_tip = Imgui.begin_tool_tip
Imgui_end_tool_tip = Imgui.end_tool_tip

local SpideySenseImgui = class("SpideySenseImgui")

function SpideySenseImgui:init()
    self._is_open = false
    self._selected_enemy_index = nil
    self._selected_warning_index = nil
end

function SpideySenseImgui:open()
    local input_manager = Managers.input
    local name = self.__class_name
  
    if not input_manager:cursor_active() then
        input_manager:push_cursor(name)
        self.pushed_cursor = true
    end

    self._is_open = true
    Imgui_open_imgui()
end

function SpideySenseImgui:close()
    local input_manager = Managers.input
    local name = self.__class_name
  
    if self.pushed_cursor then    
        input_manager:pop_cursor(name)
        self.pushed_cursor = false
    end

    self._is_open = false
    Imgui_close_imgui()
end

function SpideySenseImgui:is_open()
    return self._is_open
end

function SpideySenseImgui:toggle()
    if self._is_open then
        self:close()
    else
        self:open()
    end
end

-- Helper function to update a checkbox setting
local function update_checkbox(setting_id, tooltip_id)
    local current_value = mod:get(setting_id)
    local new_value = Imgui_checkbox(localize_or_key(setting_id), current_value)
    show_tooltip(tooltip_id)

    if new_value ~= current_value then
        mod:set(setting_id, new_value)
    end

    return new_value
end

-- Helper function to update a numeric setting
local function update_slider_int(setting_id, min_value, max_value, tooltip_id, default_value)
    local current_value = mod:get(setting_id)
    if current_value == nil and default_value ~= nil then
        current_value = default_value
        mod:set(setting_id, current_value, false)
    end

    local new_value = Imgui_slider_int(localize_or_key(setting_id), current_value, min_value, max_value)
    show_tooltip(tooltip_id)

    if new_value ~= current_value then
        mod:set(setting_id, new_value)
    end

    return new_value
end

-- Helper function to render color picker
local function render_color_picker(setting_id, default_color_name)
    local color_argb = get_color_setting(setting_id, default_color_name)

    Imgui_text(localize_or_key(setting_id))
    local r, g, b = Imgui_color_edit_3("##" .. setting_id, color_argb[2] / 255, color_argb[3] / 255, color_argb[4] / 255)

    if r ~= color_argb[2] / 255 or g ~= color_argb[3] / 255 or b ~= color_argb[4] / 255 then
        local new_color = {255, math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)}
        mod:set(setting_id, new_color)
    end
end

-- Helper function to render copy_from dropdown
local function render_copy_from_dropdown(type_name)
    local setting_id = type_name .. "_copy_from"
    local current_value = mod:get(setting_id)
    local current_text = current_value and mod:localize(current_value .. "_name") or mod:localize("copy_none")
    
    if Imgui_begin_combo(mod:localize("copy_settings_from"), current_text) then
        if Imgui_selectable(mod:localize("copy_none"), current_value == "none" or not current_value) then
            mod:set(setting_id, "none")
        end
        
        for i, enemy_type in ipairs(enemy_types) do
            if enemy_type ~= type_name then
                local display_name = mod:localize(enemy_type .. "_name") or enemy_type
                if Imgui_selectable(display_name, current_value == enemy_type) then
                    local copy_from = enemy_type

                    mod:set(type_name .. "_active", mod:get(copy_from .. "_active"), false)
                    mod:set(type_name .. "_radius", mod:get(copy_from .. "_radius"), false)
                    mod:set(type_name .. "_active_range", mod:get(copy_from .. "_active_range"), false)
                    mod:set(type_name .. "_nurgle_blessed", mod:get(copy_from .. "_nurgle_blessed"), false)
                    mod:set(type_name .. "_distance", mod:get(copy_from .. "_distance"), false)
                    mod:set(type_name .. "_arrow_distance", mod:get(copy_from .. "_arrow_distance"), false)
                    mod:set(type_name .. "_only_behind", mod:get(copy_from .. "_only_behind"), false)
                    mod:set(type_name .. "_front_opacity", mod:get(copy_from .. "_front_opacity"), false)
                    mod:set(type_name .. "_back_opacity", mod:get(copy_from .. "_back_opacity"), false)

                    mod:set(type_name .. "_arrow_colour", get_color_setting(copy_from .. "_arrow_colour"), false)
                    mod:set(type_name .. "_front_colour", get_color_setting(copy_from .. "_front_colour"), false)
                    mod:set(type_name .. "_back_colour", get_color_setting(copy_from .. "_back_colour"), false)
                    mod:set(setting_id, "none", false)
                end
            end
        end
        Imgui_end_combo()
    end
end

-- Render settings for selected enemy type
local function render_enemy_settings(type_name, is_backstab)
    Imgui_spacing()
        
    Imgui_separator()
    Imgui_spacing()
    
    update_checkbox(type_name .. "_active")
    
    Imgui_spacing()
    
    if not is_backstab then
        update_checkbox(type_name .. "_active_range", "active_range_tooltip")
        update_checkbox(type_name .. "_nurgle_blessed")
    end
    
update_slider_int(type_name .. "_radius", is_backstab and 0 or -125, 200, nil, DEFAULT_ENEMY_RADIUS)

    update_slider_int(type_name .. "_distance", 0, 40, nil, DEFAULT_ENEMY_DISTANCE)
    
    if not is_backstab then
        update_slider_int(type_name .. "_arrow_distance", 0, 40, type_name .. "_arrow_description")
        -- Only show proximity alert color when proximity range is set
        if mod:get(type_name .. "_arrow_distance") > 0 then
            Imgui_spacing()
            local arrow_default = default_colors[type_name] and default_colors[type_name].arrow or "white"
            render_color_picker(type_name .. "_arrow_colour", arrow_default)
        end
        Imgui_spacing()
        update_checkbox(type_name .. "_only_behind")
    end
    
    Imgui_spacing()
    local front_default = default_colors[type_name] and default_colors[type_name].front or DEFAULT_COLOR_NAME
    render_color_picker(type_name .. "_front_colour", front_default)
    Imgui_spacing()
    update_slider_int(type_name .. "_front_opacity", 0, 255, nil, DEFAULT_OPACITY)

    Imgui_spacing()
    local back_default = default_colors[type_name] and default_colors[type_name].back or DEFAULT_COLOR_NAME
    render_color_picker(type_name .. "_back_colour", back_default)
    Imgui_spacing()
    update_slider_int(type_name .. "_back_opacity", 0, 255, nil, DEFAULT_OPACITY)
    
    if not is_backstab then
        Imgui_spacing()
        Imgui_separator()
        Imgui_spacing()
        render_copy_from_dropdown(type_name)
    end
end

-- Render settings for selected text warning
local function render_text_warning_settings(type_name, attack_name)
    Imgui_spacing()
    Imgui_separator()
    Imgui_spacing()
    Imgui_spacing()

    update_checkbox("render_" .. type_name .. "_warning", "render_" .. type_name .. "_warning_description")
    
    if mod:get("render_" .. type_name .. "_warning") then
        Imgui_spacing()
        local range_max = (type_name == "hound") and 50 or 20
        local range_tooltip = (type_name == "pogryn") and "pogryn_range_max_description" or nil
        update_slider_int(type_name .. "_range_max", 5, range_max, range_tooltip, DEFAULT_WARNING_RANGE)
        
        if type_name == "hound" then
            Imgui_spacing()
            update_checkbox("render_pack_hound_warning")
        end
        
        Imgui_spacing()
        update_slider_int("font_size_" .. attack_name, 28, 125, nil, DEFAULT_WARNING_FONT_SIZE)
        
        Imgui_spacing()
        -- Font dropdown
        local font_setting_id = "font_name_" .. attack_name
        local current_font = mod:get(font_setting_id) or mod.ui.default_warning_font
        local font_label = mod:localize(font_setting_id) or "Font Name"
        local current_font_display = mod:localize(current_font) or current_font
        
        if Imgui_begin_combo(font_label, current_font_display) then
            for i, font_name in ipairs(available_fonts) do
                local font_display = mod:localize(font_name) or font_name
                if Imgui_selectable(font_display, current_font == font_name) then
                    mod:set(font_setting_id, font_name)
                end
            end
            Imgui_end_combo()
        end
        
        Imgui_spacing()
        render_color_picker("font_colour_" .. attack_name, DEFAULT_WARNING_FONT_COLOR)
    end
end

function SpideySenseImgui:update()
    if not self._is_open then
        return
    end

    Imgui_set_next_window_size(window_width, window_height)
    if first_run then
        Imgui_set_next_window_pos(
            (RESOLUTION_LOOKUP.width / 2) - (window_width / 2), 
            (RESOLUTION_LOOKUP.height / 2) - (window_height / 2)
        )
        first_run = false
    end
    
    local _, closed = Imgui_begin_window("Spidey Sense Settings", "always_auto_resize", "no_move")

    if closed then
        self:close()
        Imgui_end_window()
        return
    end

    Imgui_set_window_font_scale(ui_scale)

    -- Enemy Type Selection Dropdown
    Imgui_text(mod:localize("enemy_type_settings"))
    Imgui_spacing()
    
    local selected_enemy_text = mod:localize("select_enemy_type")
    if self._selected_enemy_index then
        local enemy_value = enemy_types[self._selected_enemy_index]
        selected_enemy_text = mod:localize(enemy_value .. "_name") or enemy_value
    end
    
    if Imgui_begin_combo(mod:localize("enemy_type"), selected_enemy_text) then
        for i, enemy_type in ipairs(enemy_types) do
            local display_name = mod:localize(enemy_type .. "_name") or enemy_type
            if Imgui_selectable(display_name, self._selected_enemy_index == i) then
                self._selected_enemy_index = i
            end
        end
        Imgui_end_combo()
    end
    
    -- Render settings for selected enemy
    if self._selected_enemy_index then
        local selected_enemy = enemy_types[self._selected_enemy_index]
        local is_backstab = (selected_enemy == "melee_backstab" or selected_enemy == "ranged_backstab")
        render_enemy_settings(selected_enemy, is_backstab)
    end
    
    Imgui_spacing()
    Imgui_spacing()
    Imgui_separator()
    Imgui_separator()
    Imgui_spacing()
    
    -- Text Warning Selection Dropdown
    Imgui_text(mod:localize("text_warning_settings"))
    Imgui_spacing()

    local selected_warning_text = mod:localize("select_text_warning")
    if self._selected_warning_index then
        local warning_data = text_warning_types[self._selected_warning_index]
        selected_warning_text = mod:localize("text_warning_" .. warning_data.type .. "_" .. warning_data.attack)
    end
    
    if Imgui_begin_combo(mod:localize("text_warning_type"), selected_warning_text) then
        for i, warning_type in ipairs(text_warning_types) do
            local display_name = mod:localize("text_warning_" .. warning_type.type .. "_" .. warning_type.attack)
            if Imgui_selectable(display_name, self._selected_warning_index == i) then
                self._selected_warning_index = i
            end
        end
        Imgui_end_combo()
    end

    -- Render settings for selected text warning
    if self._selected_warning_index then
        local selected_warning = text_warning_types[self._selected_warning_index]
        render_text_warning_settings(selected_warning.type, selected_warning.attack)
    end

    Imgui_end_window()
end

return SpideySenseImgui
