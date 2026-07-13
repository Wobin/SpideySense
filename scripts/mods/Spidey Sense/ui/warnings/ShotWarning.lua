local mod = get_mod("Spidey Sense")
local build = mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/WarningElement")

return build("SpideySenseUIShotWarning", "shot", "Shot", { 0, 150, 1 })
