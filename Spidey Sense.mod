return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Spidey Sense` encountered an error loading the Darktide Mod Framework.")

		new_mod("Spidey Sense", {
			mod_script       = "Spidey Sense/scripts/mods/Spidey Sense/Spidey Sense",
			mod_data         = "Spidey Sense/scripts/mods/Spidey Sense/Spidey Sense_data",
			mod_localization = "Spidey Sense/scripts/mods/Spidey Sense/Spidey Sense_localization",
		})
	end,
  load_after = {
    "DarktideLocalServer"
  },
  version = "5.3.0",
	packages = {},
}
