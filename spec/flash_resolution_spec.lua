local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- End-to-end regression for the bug that made the sniper warning dead in a live mission.
--
-- The flash reaches a client through FxSystem.rpc_trigger_wwise_event, which does
--   source_id = WwiseWorld.make_auto_source(wwise_world, POSITION)
--   WwiseWorld.trigger_resource_event(wwise_world, event_name, source_id)
-- so hook_monster is handed a plain source_id NUMBER and no unit. SourceRegistry used to map
-- unit-built sources only, so get(source_id) returned nil and hook_monster bailed at
-- `if unit_or_position == nil then return end` -- the warning never fired ONCE.
--
-- Verified in-game: 8 flashes, warning_expiry{} empty, play_special_sniper_flash hit=0 MISS=2.

local FLASH = "wwise/events/weapon/play_special_sniper_flash"

return function()
	t.suite("Flash source resolution (position-built sources)")

	local function fresh()
		local mod = engine.install({
			render_sniper_warning = true,
			sniper_active = true,
		})
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua")
		engine.attach_hud_element(mod)
		mod.on_all_mods_loaded()

		-- Drive the registry's WwiseWorld hooks the way the engine would.
		local hooks = {}
		for _, h in ipairs(mod.hooks) do
			hooks[h.name] = hooks[h.name] or h.fn
		end

		local next_id = 0
		local function make_auto(unit_or_position)
			local id
			hooks.make_auto_source(function() next_id = next_id + 1 id = next_id return id end,
				{}, unit_or_position)
			return id
		end

		return mod, make_auto
	end

	t.it("a flash from a position-built source fires the Sniper warning", function()
		local mod, make_auto = fresh()
		engine.set_time(10)

		-- the sniper's muzzle, 40m away -- a POSITION, not a unit
		local source_id = make_auto(engine.vec(0, 40, 0))

		-- hook_monster receives the bare source id and no check_unit, exactly as in game
		mod.hook_monster(FLASH, source_id, nil)

		t.truthy(mod.ui.is_warning_visible("Sniper"),
			"the flash must resolve through the registry and fire the warning")
	end)

	t.it("still fires for a sniper far beyond any range gate", function()
		local mod, make_auto = fresh()
		engine.set_time(10)

		local source_id = make_auto(engine.vec(0, 120, 0)) -- sniper max_distance is 150m
		mod.hook_monster(FLASH, source_id, nil)

		t.truthy(mod.ui.is_warning_visible("Sniper"), "sniper warning is range-unlimited")
	end)

	t.it("an unresolvable source id still fires nothing and does not crash", function()
		local mod = fresh()
		engine.set_time(10)

		mod.hook_monster(FLASH, 999999, nil)

		t.falsy(mod.ui.is_warning_visible("Sniper"), "unknown source resolves to nothing")
	end)

	-- A position-built source resolves to a Vector3, which has no extensions. Anything that
	-- assumed a Unit downstream (breed lookup, nurgle buffs, the multi-enemy tracker) would
	-- otherwise blow up on it.
	t.it("a position-sourced footstep cue does not crash the breed lookup", function()
		local mod, make_auto = fresh()
		engine.set_time(10)

		local source_id = make_auto(engine.vec(0, 5, 0))
		mod.hook_monster("wwise/events/minions/play_minion_footsteps_boots_heavy", source_id, nil)

		t.truthy(true, "survived a footstep cue with no unit behind it")
	end)

	t.it("a position-sourced indicator cue does not enter the multi-enemy tracker", function()
		local mod, make_auto = fresh()
		engine.set_time(10)

		local source_id = make_auto(engine.vec(0, 5, 0))
		mod.hook_monster("wwise/events/weapon/play_combat_weapon_las_sniper", source_id, nil)

		mod.multi_enemy_tracker:update()
		t.eq(mod.multi_enemy_tracker:get_count("sniper"), 0,
			"a Vector3 is userdata but is not a unit -- it must not be tracked")
	end)
end
