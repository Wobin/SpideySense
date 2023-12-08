local mod = get_mod("Spidey Sense")



local color_options = {}
for i, color_name in ipairs(Color.list) do
  table.insert(color_options, {
    text = color_name,
    value = color_name
  })
end
table.sort(color_options, function(a, b)
  return a.text < b.text
end)

local function get_color_options()
  return table.clone(color_options)
end



return {
	name = "Spidey Sense",
	description = mod:localize("mod_description"),
	is_togglable = true,
  options = {
    widgets = {
      {
        setting_id = "radius",
        type = "numeric",
					default_value = 50,
					range = {0, 200},
					decimals_number = 0
				},        
      	{
				setting_id = "mutant_colour",
				type = "group",
				sub_widgets = {
          {
            setting_id = "mutant_active",
            type = "checkbox",
            default_value = true,
          },
          {
            setting_id = "mutant_front_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "mutant_front_colour",
            type = "dropdown",
            default_value = "ui_green_light",
            options = get_color_options()
          },
          {
            setting_id = "mutant_back_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "mutant_back_colour",
            type = "dropdown",
            default_value = "spring_green",
            options = get_color_options()
          },
        }
      },
      {
				setting_id = "trapper_colour",
				type = "group",
				sub_widgets = {
          {
            setting_id = "trapper_active",
            type = "checkbox",
            default_value = true,
          },
          {
            setting_id = "trapper_front_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "trapper_front_colour",
            type = "dropdown",
            default_value = "ui_hud_overcharge_medium",
            options = get_color_options()
          },
          {
            setting_id = "trapper_back_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "trapper_back_colour",
            type = "dropdown",
            default_value = "ui_hud_overcharge_low",
            options = get_color_options()
          },
        }
      },
        {
				setting_id = "hound_colour",
				type = "group",
				sub_widgets = {
          {
            setting_id = "hound_active",
            type = "checkbox",
            default_value = true,
          },
          {
            setting_id = "hound_front_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "hound_front_colour",
            type = "dropdown",
            default_value = "turquoise",
            options = get_color_options()
          },
          {
            setting_id = "hound_back_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "hound_back_colour",
            type = "dropdown",
            default_value = "ui_blue_light",
            options = get_color_options()
          },
        }
      },
      {
				setting_id = "burster_colour",
				type = "group",
				sub_widgets = {
          {
            setting_id = "burster_active",
            type = "checkbox",
            default_value = true,
          },
          {
            setting_id = "burster_front_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "burster_front_colour",
            type = "dropdown",
            default_value = "sienna",
            options = get_color_options()
          },
          {
            setting_id = "burster_back_opacity",
            type = "numeric",
            default_value = 255,
            range = {0, 255},
            decimals_number = 0
          },
          {
            setting_id = "burster_back_colour",
            type = "dropdown",
            default_value = "ui_red_medium",
            options = get_color_options()
          },
        }
      },
      	{
				setting_id = "backstab_colour",
				type = "group",
				sub_widgets = {
          {
            setting_id = "backstab_active",
            type = "checkbox",
            default_value = true,
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
          },
        }
      },
    }
  }
}
