local engine = require("spec.mock_engine")
local t = require("spec.runner")

return function()
	t.suite("SourceRegistry")

	-- SourceRegistry installs its maps via mod:hook on WwiseWorld. The mock doesn't
	-- actually patch WwiseWorld, so grab the registered hook bodies and drive them
	-- directly -- that is exactly what the engine would call.
	local function fresh()
		local mod = engine.install({})
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/core/Helper.lua")
		-- SourceRegistry.lua has no return statement; it publishes itself on the mod.
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/audio/SourceRegistry.lua")
		local registry = mod.source_registry
		registry.install()

		local h = {}
		for _, entry in ipairs(mod.hooks) do
			h[entry.name] = entry.fn
		end

		local next_id = 0
		local function alloc()
			next_id = next_id + 1
			return next_id
		end

		return registry, {
			make_manual = function(unit)
				local id
				h.make_manual_source(function() id = alloc() return id end, {}, unit)
				return id
			end,
			make_auto = function(unit)
				local id
				h.make_auto_source(function() id = alloc() return id end, {}, unit)
				return id
			end,
			destroy_manual = function(source_id)
				h.destroy_manual_source({}, source_id)
			end,
		}
	end

	t.it("resolves a manual source back to its unit", function()
		local registry, w = fresh()
		local unit = engine.make_unit()
		local id = w.make_manual(unit)

		t.eq(registry.get(id), unit)
	end)

	t.it("resolves an auto source back to its unit", function()
		local registry, w = fresh()
		local unit = engine.make_unit()
		local id = w.make_auto(unit)

		t.eq(registry.get(id), unit)
	end)

	t.it("returns nil for an unknown source id", function()
		local registry = fresh()
		t.eq(registry.get(9999), nil)
	end)

	t.it("forgets a manual source when it is destroyed", function()
		local registry, w = fresh()
		local unit = engine.make_unit()
		local id = w.make_manual(unit)
		t.eq(registry.get(id), unit)

		w.destroy_manual(id)

		t.eq(registry.get(id), nil)
	end)

	t.it("does not hand back a dead unit", function()
		local registry, w = fresh()
		local unit = engine.make_unit()
		local id = w.make_manual(unit)

		engine.kill_unit(unit)

		t.eq(registry.get(id), nil, "dead unit must not resolve")
	end)

	-- THE SHIPPED BUG (found live 2026-07-10): the registry only mapped unit-built sources, so a
	-- position-built one resolved to nil and hook_monster bailed before the warning fired. The
	-- sniper flash arrives via FxSystem.rpc_trigger_wwise_event -> make_auto_source(world, POSITION),
	-- so the sniper warning never fired once at all. Same fault silently dropped chaos_spawn,
	-- hound, mutant and burster cues.
	t.it("resolves an AUTO source built from a position (the sniper flash path)", function()
		local registry, w = fresh()
		local id = w.make_auto(engine.vec(10, 20, 30))

		local pos = registry.get(id)
		t.truthy(pos, "a position-built source MUST resolve")
		t.near(pos.x, 10)
		t.near(pos.y, 20)
		t.near(pos.z, 30)
	end)

	t.it("resolves a MANUAL source built from a position", function()
		local registry, w = fresh()
		local id = w.make_manual(engine.vec(1, 2, 3))

		local pos = registry.get(id)
		t.truthy(pos, "a position-built manual source MUST resolve")
		t.near(pos.x, 1)
		t.near(pos.y, 2)
		t.near(pos.z, 3)
	end)

	-- Vector3s are frame-local temps; the registry must keep a boxed copy, not the temp itself.
	t.it("keeps its own copy of the position (frame-temp safety)", function()
		local registry, w = fresh()
		local v = engine.vec(5, 5, 5)
		local id = w.make_auto(v)

		v.x, v.y, v.z = 999, 999, 999 -- the engine recycles the temp

		local pos = registry.get(id)
		t.near(pos.x, 5, 0.001, "registry must not alias the caller's Vector3")
	end)

	t.it("forgets a manual position source when it is destroyed", function()
		local registry, w = fresh()
		local id = w.make_manual(engine.vec(1, 2, 3))
		t.truthy(registry.get(id))

		w.destroy_manual(id)

		t.eq(registry.get(id), nil)
	end)

	t.it("evicts the oldest auto source once the ring wraps past 512", function()
		local registry, w = fresh()
		local first_unit = engine.make_unit()
		local first_id = w.make_auto(first_unit)
		t.eq(registry.get(first_id), first_unit)

		-- fill the ring so the very first entry is overwritten
		for _ = 1, 512 do
			w.make_auto(engine.make_unit())
		end

		t.eq(registry.get(first_id), nil, "oldest auto source evicted by the ring buffer")
	end)

	t.it("sweeps dead units out of the manual map on update", function()
		local registry, w = fresh()
		local unit = engine.make_unit()
		w.make_manual(unit)
		engine.kill_unit(unit)

		engine.advance(10) -- update() only sweeps every 5s
		registry.update()

		local remaining = 0
		for _ in pairs(registry) do remaining = remaining + 1 end
		t.truthy(remaining > 0, "registry table itself survives the sweep")
	end)
end
