local engine = require("spec.mock_engine")
local t = require("spec.runner")

return function()
	t.suite("MultiEnemyTracker")

	local function fresh()
		engine.install({})
		return dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/tracking/MultiEnemyTracker.lua")
	end

	t.it("assigns sequential instance numbers per breed", function()
		local tracker = fresh()
		local a, b, c = engine.make_unit(), engine.make_unit(), engine.make_unit()

		tracker:register_unit(a, "sniper")
		tracker:register_unit(b, "sniper")
		tracker:register_unit(c, "sniper")

		t.eq(tracker:get_instance_number(a, "sniper"), 1)
		t.eq(tracker:get_instance_number(b, "sniper"), 2)
		t.eq(tracker:get_instance_number(c, "sniper"), 3)
	end)

	t.it("counts only after update() and keeps breeds separate", function()
		local tracker = fresh()
		tracker:register_unit(engine.make_unit(), "sniper")
		tracker:register_unit(engine.make_unit(), "sniper")
		tracker:register_unit(engine.make_unit(), "trapper")

		tracker:update()

		t.eq(tracker:get_count("sniper"), 2)
		t.eq(tracker:get_count("trapper"), 1)
		t.eq(tracker:get_count("hound"), 0, "unknown breed counts zero")
	end)

	t.it("does not double-register the same unit", function()
		local tracker = fresh()
		local a = engine.make_unit()

		tracker:register_unit(a, "sniper")
		tracker:register_unit(a, "sniper")
		tracker:update()

		t.eq(tracker:get_count("sniper"), 1)
	end)

	t.it("prunes dead units and recycles their instance number", function()
		local tracker = fresh()
		local a, b = engine.make_unit(), engine.make_unit()
		tracker:register_unit(a, "sniper")
		tracker:register_unit(b, "sniper")
		t.eq(tracker:get_instance_number(a, "sniper"), 1)

		engine.kill_unit(a)
		tracker:update()

		t.eq(tracker:get_count("sniper"), 1, "dead unit pruned")
		t.eq(tracker:get_instance_number(a, "sniper"), nil, "dead unit's number released")

		-- number 1 is free again, so the next sniper should claim it rather than take 3
		local c = engine.make_unit()
		tracker:register_unit(c, "sniper")
		t.eq(tracker:get_instance_number(c, "sniper"), 1, "freed number is reused")
	end)

	t.it("drops the breed bucket entirely once empty", function()
		local tracker = fresh()
		local a = engine.make_unit()
		tracker:register_unit(a, "sniper")
		tracker:update()
		t.eq(tracker:get_count("sniper"), 1)

		engine.kill_unit(a)
		tracker:update()

		t.eq(tracker:get_count("sniper"), 0)
		t.eq(tracker.active_instances["sniper"], nil, "empty bucket removed")
	end)

	t.it("caps concurrent tracked instances at 15", function()
		local tracker = fresh()
		local units = {}
		for i = 1, 20 do
			units[i] = engine.make_unit()
			tracker:register_unit(units[i], "sniper")
		end
		tracker:update()

		t.eq(tracker:get_count("sniper"), 15, "16th+ unit is refused a number and not tracked")
		t.eq(tracker:get_instance_number(units[16], "sniper"), nil)
	end)
end
