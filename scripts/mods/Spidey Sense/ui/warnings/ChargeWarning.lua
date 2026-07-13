local mod = get_mod("Spidey Sense")
local build = mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/ui/warnings/WarningElement")

return build("SpideySenseUIChargeWarning", "charge", "Charge", { 0, -150, 1 })
