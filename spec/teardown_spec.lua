local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- Regression for a mission-end crash (2026-07-18):
-- During StateGameplay on_exit cleanup the viewport/camera is destroyed, but sound cues still
-- fire (a despawning plasma gunner's charge-up template calls stop_minion_plasmapistol_charge).
-- The mod caught the cue, ran create_indicator -> listener_position_rotation ->
-- camera_manager:listener_pose, and the engine crashed on the nil viewport
-- ("bad argument #1 to 'camera' (userdata expected, got nil)"), taking the whole game down on exit.
--
-- The mod must never let a cue crash the game just because the camera is mid-teardown.

return function()
	t.suite("Mission teardown (no camera)")

	local function fresh()
		local settings = {
			plasma_gunner_active = true,
			plasma_gunner_range_max = 100,
			render_sniper_warning = true,
			hound_range_max = 100,
			render_hound_warning = true,
		}
		local mod = engine.install(settings)
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua")
		engine.attach_hud_element(mod)
		return mod
	end

	t.it("an indicator cue during teardown does not crash and spawns nothing", function()
		local mod = fresh()
		engine.set_camera_available(false) -- viewport gone

		local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })
		local ok = pcall(function()
			engine.set_time(1)
			mod.hook_monster("wwise/events/weapon/stop_minion_plasmapistol_charge_02", unit, unit)
		end)

		t.truthy(ok, "cue during teardown must not crash")
		t.eq(#mod._indicators, 0, "no indicator without a listener")
	end)

	t.it("a warning cue during teardown does not crash and fires nothing", function()
		local mod = fresh()
		engine.set_camera_available(false)

		local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })
		local ok = pcall(function()
			engine.set_time(1)
			mod.ui.indicate_warning(unit, "sniper")
		end)

		t.truthy(ok, "indicate_warning during teardown must not crash")
		t.falsy(mod.ui.is_warning_visible("Sniper"), "no warning without a listener")
	end)

	t.it("listener_position_rotation returns nil when the camera is gone", function()
		local mod = fresh()
		engine.set_camera_available(false)

		local pos = mod.ui.listener_position_rotation()
		t.eq(pos, nil, "no position when there is no camera")
	end)

	t.it("recovers to normal once the camera is back", function()
		local mod = fresh()
		engine.set_camera_available(false)
		mod.ui.listener_position_rotation()

		engine.set_camera_available(true)
		engine.set_time(5)
		local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })
		mod.hook_monster("wwise/events/weapon/play_minion_plasmapistol", unit, unit)

		t.truthy(#mod._indicators > 0, "indicators resume when the camera returns")
	end)
end
