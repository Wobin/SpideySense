-- Entrypoint for the Spidey Sense test suite.
--
--   cd "<...>/mods/Spidey Sense"
--   luajit spec/run_all.lua
--
-- Requires only standalone LuaJIT; nothing is loaded from the game.

package.path = "./?.lua;" .. package.path

local engine = require("spec.mock_engine")
engine.MOD_ROOT = "."

local runner = require("spec.runner")

local SPECS = {
	"spec.parse_spec",
	"spec.multi_enemy_tracker_spec",
	"spec.source_registry_spec",
	"spec.warnings_spec",
	"spec.hud_warnings_spec",
	"spec.sound_matcher_spec",
	"spec.warning_cues_spec",
	"spec.flash_resolution_spec",
	"spec.settings_lint_spec",
}

for _, name in ipairs(SPECS) do
	local ok, spec = pcall(require, name)
	if not ok then
		print("\n!! could not load " .. name .. ": " .. tostring(spec))
		os.exit(1)
	end
	spec()
end

os.exit(runner.report() and 0 or 1)
