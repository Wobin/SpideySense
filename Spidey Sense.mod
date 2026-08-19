return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Spidey Sense` encountered an error loading the Darktide Mod Framework.")

		new_mod("Spidey Sense", {
			mod_script       = "Spidey Sense/scripts/mods/Spidey Sense/Spidey Sense",
			mod_data         = "Spidey Sense/scripts/mods/Spidey Sense/Spidey Sense_data",
			mod_localization = "Spidey Sense/scripts/mods/Spidey Sense/Spidey Sense_localization",
		})
	end,
	require = {
		"SimpleAssets"
	},
	load_after = {
		"SimpleAssets"
	},
	packages = {
		"packages/ui/views/inventory_background_view/inventory_background_view",
	},
}
