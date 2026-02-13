local mod = get_mod("Spidey Sense")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "open_imgui_settings",
                type = "checkbox",
                default_value = false,
            }
        }
    }
}
