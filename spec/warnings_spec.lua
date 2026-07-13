local engine = require("spec.mock_engine")
local t = require("spec.runner")

return function()
	t.suite("Warnings / range gate")

	local function fresh(settings)
		local mod = engine.install(settings or {})
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/core/Helper.lua")
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/ui/UI.lua")
		return mod
	end

	-- Put the listener at the origin and the enemy `distance` metres away on Y.
	local function enemy_at(distance)
		return engine.make_unit({ position = engine.vec(0, distance, 0) })
	end

	t.it("warns for a sniper that is far away", function()
		local mod = fresh()
		mod.ui.indicate_warning(enemy_at(60), "sniper")

		t.truthy(mod.ui.is_warning_visible("Sniper"), "a 60m sniper must warn")
	end)

	-- This is the regression that shipped: sniper_range_max=5 had been healed into
	-- user_settings.config, so the warning was gated at 5m and never fired.
	t.it("ignores a persisted sniper_range_max (the shipped bug)", function()
		local mod = fresh({ sniper_range_max = 5 })
		mod.ui.indicate_warning(enemy_at(60), "sniper")

		t.truthy(mod.ui.is_warning_visible("Sniper"),
			"sniper must be range-unlimited even with a stale saved range")
	end)

	t.it("still warns for a sniper that is close", function()
		local mod = fresh()
		mod.ui.indicate_warning(enemy_at(3), "sniper")

		t.truthy(mod.ui.is_warning_visible("Sniper"))
	end)

	t.it("clears the sniper warning once its duration lapses", function()
		local mod = fresh()
		mod.ui.indicate_warning(enemy_at(60), "sniper")
		t.truthy(mod.ui.is_warning_visible("Sniper"))

		engine.advance(1.01) -- sniper warning lasts 1s
		t.falsy(mod.ui.is_warning_visible("Sniper"), "warning must expire")
	end)

	t.it("re-triggering extends but never shortens the window", function()
		local mod = fresh()
		mod.ui.indicate_warning(enemy_at(60), "sniper")

		engine.advance(0.9)
		mod.ui.indicate_warning(enemy_at(60), "sniper") -- re-arm at t=0.9, expires 1.9

		engine.advance(0.5) -- t=1.4, past the first window but inside the second
		t.truthy(mod.ui.is_warning_visible("Sniper"), "re-arm must extend the window")
	end)

	-- Non-sniper warnings keep their configured range gate; the sniper carve-out
	-- must not have quietly made every warning unlimited.
	t.it("hound pounce warns inside its configured range", function()
		local mod = fresh({ hound_range_max = 20 })
		mod.ui.indicate_warning(enemy_at(10), "pounce")

		t.truthy(mod.ui.is_warning_visible("Pounce"))
	end)

	t.it("hound pounce does NOT warn beyond its configured range", function()
		local mod = fresh({ hound_range_max = 20 })
		mod.ui.indicate_warning(enemy_at(50), "pounce")

		t.falsy(mod.ui.is_warning_visible("Pounce"), "range gate must still apply to non-sniper warnings")
	end)

	t.it("warnings are independent of each other", function()
		local mod = fresh({ hound_range_max = 20 })
		mod.ui.indicate_warning(enemy_at(60), "sniper")

		t.truthy(mod.ui.is_warning_visible("Sniper"))
		t.falsy(mod.ui.is_warning_visible("Pounce"), "sniper must not light up the pounce warning")
	end)
end
