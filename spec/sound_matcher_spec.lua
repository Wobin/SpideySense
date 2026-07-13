local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- Golden table for hook_monster's sound -> indicator matching.
--
-- This exists so the matcher can be refactored (e.g. the if-chain -> a spec table)
-- without silently changing behaviour. It records the FULL set of indicators an event
-- produces, not just "did it fire", so a refactor that drops or duplicates a match fails.
--
-- { sound, breed (or nil), { expected target_types } }
local GOLDEN = {
	-- specials / elites by sound alone
	{ "wwise/events/minions/play_minion_poxwalker_bomber_foley", nil, { "burster" } },
	{ "wwise/events/minions/play_enemy_combat_poxwalker_bomber_a", nil, { "burster" } },
	{ "wwise/events/minions/play_enemy_chaos_hound_foley", nil, { "hound" } },
	{ "wwise/events/minions/play_enemy_mutant_charger", nil, { "mutant" } },
	{ "wwise/events/minions/play_netgunner_run_foley_special", nil, { "trapper" } },
	{ "wwise/events/minions/play_netgunner_reload", nil, { "trapper" } },
	{ "wwise/events/weapon/play_combat_weapon_las_sniper", nil, { "sniper" } },
	{ "wwise/events/weapon/play_explosion_fuse", nil, { "barrel" } },
	{ "wwise/events/minions/play_enemy_daemonhost_idle", nil, { "daemonhost" } },
	{ "wwise/events/minions/play_cultist_grenadier_foley", nil, { "toxbomber" } },

	-- flamer has several distinct cues
	{ "wwise/events/weapon/play_aoe_liquid_fire_loop", nil, { "flamer" } },
	{ "wwise/events/minions/play_enemy_cultist_flamer_foley_tank", nil, { "flamer" } },
	{ "wwise/events/weapon/play_minion_flamethrower_start", nil, { "flamer" } },

	-- substring-matched monsters
	{ "wwise/events/minions/play_enemy_plague_ogryn_foley", nil, { "plague_ogryn" } },
	{ "wwise/events/minions/play_chaos_spawn_foley", nil, { "chaos_spawn" } },
	{ "wwise/events/minions/play_beast_of_nurgle_idle", nil, { "beast_of_nurgle" } },

	-- backstab: "..._melee" is a prefix of "..._melee_elite", so one pattern catches both
	{ "wwise/events/player/play_backstab_indicator_melee", nil, { "melee_backstab" } },
	{ "wwise/events/player/play_backstab_indicator_melee_elite", nil, { "melee_backstab" } },
	{ "wwise/events/player/play_backstab_indicator_ranged", nil, { "ranged_backstab" } },

	-- breed-gated: the same footstep event means different things per breed
	{ "wwise/events/minions/play_minion_footsteps_chaos_ogryn", "chaos_ogryn_executor", { "crusher" } },
	{ "wwise/events/minions/play_minion_footsteps_boots_heavy", "renegade_executor", { "mauler" } },
	{ "wwise/events/minions/play_minion_footsteps_boots_heavy", "cultist_berzerker", { "rager" } },
	{ "wwise/events/minions/play_shared_elite_executor_cleave_warning", nil, { "mauler" } },

	-- breed gate must actually gate: wrong breed on a breed-only cue yields nothing
	{ "wwise/events/minions/play_minion_footsteps_boots_heavy", "renegade_rifleman", {} },
	{ "wwise/events/minions/play_minion_footsteps_chaos_ogryn", "renegade_rifleman", {} },

	-- spawn events are deliberately ignored (except chaos_spawn)
	{ "wwise/events/minions/play_minion_spawn", nil, {} },

	-- unrelated audio must produce nothing
	{ "wwise/events/player/play_footstep_player", nil, {} },
	{ "wwise/events/ui/play_ui_click", nil, {} },
}

return function()
	t.suite("hook_monster sound matcher (golden)")

	local ALL_ENEMIES = {
		"burster", "barrel", "beast_of_nurgle", "crusher", "chaos_spawn", "daemonhost",
		"flamer", "grenadier", "hound", "mauler", "mutant", "plague_ogryn", "plasma_gunner",
		"rager", "sniper", "trapper", "toxbomber", "melee_backstab", "ranged_backstab",
	}

	local function fresh()
		local settings = {}
		for _, name in ipairs(ALL_ENEMIES) do
			settings[name .. "_active"] = true
		end
		local mod = engine.install(settings)
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua")
		engine.attach_hud_element(mod)
		return mod
	end

	local clock = 0

	-- hook_monster throttles each sound name to once per 0.5s, so step the clock
	-- between probes or repeat entries in the table would be swallowed.
	local function fire(mod, sound, breed)
		clock = clock + 1
		engine.set_time(clock)

		for i = #mod._indicators, 1, -1 do
			mod._indicators[i] = nil
		end

		local unit = engine.make_unit({
			position = engine.vec(0, 10, 0), -- inside every enemy's default 40m range
			breed = breed,
		})
		mod.hook_monster(sound, unit, unit)

		local got = {}
		for _, ind in ipairs(mod._indicators) do
			got[#got + 1] = ind.target_type
		end
		table.sort(got)
		return got
	end

	local mod = fresh()

	for _, case in ipairs(GOLDEN) do
		local sound, breed, expected = case[1], case[2], case[3]
		local label = sound:gsub("^wwise/events/", "") .. (breed and (" [" .. breed .. "]") or "")

		t.it(label, function()
			local got = fire(mod, sound, breed)

			local want = {}
			for _, v in ipairs(expected) do want[#want + 1] = v end
			table.sort(want)

			t.eq(table.concat(got, ","), table.concat(want, ","),
				"indicator set for " .. sound)
		end)
	end

	t.it("respects the per-sound 0.5s throttle", function()
		local m = fresh()
		engine.set_time(100)
		local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })

		m.hook_monster("wwise/events/minions/play_enemy_mutant_charger", unit, unit)
		local after_first = #m._indicators

		engine.advance(0.1) -- inside the throttle window
		m.hook_monster("wwise/events/minions/play_enemy_mutant_charger", unit, unit)

		t.eq(#m._indicators, after_first, "second cue within 0.5s must be throttled away")
	end)

	t.it("does not fire for a disabled enemy", function()
		local settings = {}
		for _, name in ipairs(ALL_ENEMIES) do
			settings[name .. "_active"] = true
		end
		settings["mutant_active"] = false

		local m = engine.install(settings)
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua")
		engine.attach_hud_element(m)
		engine.set_time(500)

		local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })
		m.hook_monster("wwise/events/minions/play_enemy_mutant_charger", unit, unit)

		t.eq(#m._indicators, 0, "disabled enemy must produce no indicator")
	end)
end
