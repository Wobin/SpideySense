local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- Warning cues routed through hook_monster (as opposed to warnings_spec, which drives
-- indicate_warning directly). These guard the render_*_warning settings cache: they must
-- gate correctly AND be refreshed by on_setting_changed, or a toggle in the options menu
-- silently does nothing until the next game launch.
--
-- { sound, indicate, extra_settings }
local CUES = {
	{ "wwise/events/minions/play_shared_elite_executor_cleave_warning", "Cleave" },
	{ "wwise/events/weapon/play_weapon_netgunner_wind_up",              "Net"    },
	{ "wwise/events/minions/play_enemy_plague_ogryn_vce_charge",        "Charge" },
	{ "wwise/events/weapon/play_minion_shotgun_pump",                   "Shot"   },
	{ "wwise/events/minions/play_enemy_chaos_hound_vce_leap",           "Pounce" },
	{ "wwise/events/weapon/play_special_sniper_flash",                  "Sniper" },
}

local ALL_WARNINGS = { "Cleave", "Net", "Charge", "Shot", "Pounce", "Sniper" }

local function base_settings()
	return {
		render_crusher_warning = true,
		render_trapper_warning = true,
		render_pogryn_warning = true,
		render_shotgun_warning = true,
		render_hound_warning = true,
		render_pack_hound_warning = false,
		render_sniper_warning = true,
		crusher_range_max = 100,
		trapper_range_max = 100,
		pogryn_range_max = 100,
		shotgun_range_max = 100,
		hound_range_max = 100,
	}
end

return function()
	t.suite("Warning cues via hook_monster")

	local clock = 0

	local function fresh(settings)
		local mod = engine.install(settings or base_settings())
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua")
		engine.attach_hud_element(mod)
		return mod
	end

	local function fire(mod, sound)
		clock = clock + 10
		engine.set_time(clock)
		for _, w in ipairs(ALL_WARNINGS) do
			mod.ui.warning_expiry[w] = nil
		end
		local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })
		mod.hook_monster(sound, unit, unit)
	end

	for _, cue in ipairs(CUES) do
		local sound, indicate = cue[1], cue[2]

		t.it(indicate .. " fires on " .. sound:gsub("^wwise/events/", ""), function()
			local mod = fresh()
			fire(mod, sound)

			t.truthy(mod.ui.is_warning_visible(indicate), indicate .. " must be visible")

			for _, other in ipairs(ALL_WARNINGS) do
				if other ~= indicate then
					t.falsy(mod.ui.is_warning_visible(other), other .. " must not fire")
				end
			end
		end)
	end

	t.it("a disabled warning does not fire", function()
		local s = base_settings()
		s.render_sniper_warning = false
		local mod = fresh(s)

		fire(mod, "wwise/events/weapon/play_special_sniper_flash")

		t.falsy(mod.ui.is_warning_visible("Sniper"), "disabled sniper warning must stay silent")
	end)

	t.it("pack-hound cue only fires when the pack-hound option is on", function()
		local mod = fresh()
		fire(mod, "wwise/events/minions/play_chaos_hound_mutator_vce_leap")
		t.falsy(mod.ui.is_warning_visible("Pounce"), "pack cue ignored while option is off")

		local s = base_settings()
		s.render_pack_hound_warning = true
		local mod2 = fresh(s)
		fire(mod2, "wwise/events/minions/play_chaos_hound_mutator_vce_leap")
		t.truthy(mod2.ui.is_warning_visible("Pounce"), "pack cue fires once option is on")
	end)

	-- The render_* flags are cached now, so toggling one in the options menu must invalidate
	-- that cache. Without the on_setting_changed hook this test fails.
	t.it("toggling a warning at runtime takes effect via on_setting_changed", function()
		local s = base_settings()
		s.render_sniper_warning = false
		local mod = fresh(s)

		fire(mod, "wwise/events/weapon/play_special_sniper_flash")
		t.falsy(mod.ui.is_warning_visible("Sniper"), "starts disabled")

		mod:set("render_sniper_warning", true)
		mod.on_setting_changed("render_sniper_warning")

		fire(mod, "wwise/events/weapon/play_special_sniper_flash")
		t.truthy(mod.ui.is_warning_visible("Sniper"), "cache must refresh when the setting changes")
	end)
end
