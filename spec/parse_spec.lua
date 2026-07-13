local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- loadfile() compiles without executing, so this is a pure syntax gate over every
-- shipped source file -- the cheapest possible guard against a broken release.
local SOURCES = {
	"scripts/mods/Spidey Sense/Spidey Sense.lua",
	"scripts/mods/Spidey Sense/Spidey Sense_data.lua",
	"scripts/mods/Spidey Sense/Spidey Sense_localization.lua",
	"scripts/mods/Spidey Sense/core/Helper.lua",
	"scripts/mods/Spidey Sense/core/Colours.lua",
	"scripts/mods/Spidey Sense/audio/SourceRegistry.lua",
	"scripts/mods/Spidey Sense/tracking/MultiEnemyTracker.lua",
	"scripts/mods/Spidey Sense/audio/Sound.lua",
	"scripts/mods/Spidey Sense/ui/UI.lua",
	"scripts/mods/Spidey Sense/ui/widget_definitions.lua",
	"scripts/mods/Spidey Sense/ui/warnings/WarningElement.lua",
	"scripts/mods/Spidey Sense/ui/warnings/ChargeWarning.lua",
	"scripts/mods/Spidey Sense/ui/warnings/CleaveWarning.lua",
	"scripts/mods/Spidey Sense/ui/warnings/NetWarning.lua",
	"scripts/mods/Spidey Sense/ui/warnings/PounceWarning.lua",
	"scripts/mods/Spidey Sense/ui/warnings/ShotWarning.lua",
	"scripts/mods/Spidey Sense/ui/warnings/SniperWarning.lua",
}

return function()
	t.suite("Parse gate")

	for _, rel in ipairs(SOURCES) do
		t.it(rel, function()
			local path = engine.MOD_ROOT .. "/" .. rel
			local chunk, err = loadfile(path)
			t.truthy(chunk, "syntax error: " .. tostring(err))
		end)
	end

	t.it("the .mod manifest parses and its version matches mod.version", function()
		local chunk, err = loadfile(engine.MOD_ROOT .. "/Spidey Sense.mod")
		t.truthy(chunk, "syntax error: " .. tostring(err))

		-- .mod is a bare `return { ... }` table, safe to run with new_mod stubbed out
		_G.new_mod = function() end
		_G.fassert = function() end
		local manifest = chunk()

		local src = io.open(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua"):read("*a")
		local script_version = src:match('mod%.version%s*=%s*"([^"]+)"')

		t.eq(manifest.version, script_version,
			".mod version must match mod.version in the script")
	end)
end
