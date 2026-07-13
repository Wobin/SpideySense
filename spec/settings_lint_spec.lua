local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- Cross-checks the settings the code ACTUALLY reads against the widgets data.lua declares.
--
-- A grep for mod:get("literal") would not have caught the sniper bug: the offending read
-- was mod:get(attacker .. "_range_max"), built at runtime. So instead of scanning source,
-- this exercises the mod with a recording mod:get and diffs the ids it really requested
-- against the declared set. That surfaces exactly the sniper_range_max class of failure:
-- a setting the code still reads but whose widget was deleted.

local ENEMIES = {
	"burster", "barrel", "beast_of_nurgle", "crusher", "chaos_spawn", "daemonhost",
	"flamer", "grenadier", "hound", "mauler", "mutant", "plague_ogryn", "plasma_gunner",
	"rager", "sniper", "trapper", "toxbomber", "melee_backstab", "ranged_backstab",
}

local WARNINGS = { "cleave", "trap", "charge", "shot", "pounce", "sniper" }

-- Reads the code makes deliberately without a backing widget. Each needs a reason:
-- these must be intentional, not accidental like sniper_range_max was.
--
-- get_target_settings is generic and asks every target type for the full option set.
-- The two backstab indicators are direction-only pips with no arrow, no behind-gate and
-- no nurgle variant, so data.lua never declares these and they correctly resolve to nil.
local INTENTIONALLY_UNDECLARED = {}
for _, backstab in ipairs({ "melee_backstab", "ranged_backstab" }) do
	for _, opt in ipairs({ "active_range", "arrow_colour", "arrow_distance", "nurgle_blessed", "only_behind" }) do
		INTENTIONALLY_UNDECLARED[backstab .. "_" .. opt] = true
	end
end

local function collect_declared(widgets, out)
	for _, w in ipairs(widgets or {}) do
		if w.setting_id then
			out[w.setting_id] = true
		end
		if w.sub_widgets then
			collect_declared(w.sub_widgets, out)
		end
	end
	return out
end

return function()
	t.suite("Settings declaration lint")

	-- 1. what data.lua declares
	local mod = engine.install({})
	local options = dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense_data.lua")

	local declared = collect_declared(options and options.options and options.options.widgets, {})

	t.it("data.lua declares a non-trivial set of widgets", function()
		local n = 0
		for _ in pairs(declared) do n = n + 1 end
		t.truthy(n > 50, "expected many declared settings, got " .. n)
	end)

	-- 2. record every setting id the code actually asks for
	local requested = {}

	local settings = {}
	for _, e in ipairs(ENEMIES) do settings[e .. "_active"] = true end

	mod = engine.install(settings)
	local raw_get = mod.get
	mod.get = function(self, id)
		requested[id] = true
		return raw_get(self, id)
	end

	dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/Spidey Sense.lua")
	engine.attach_hud_element(mod)

	-- exercise the paths that build setting ids dynamically
	for _, e in ipairs(ENEMIES) do
		mod.ui.get_target_settings(e)
	end

	engine.set_time(1)
	local unit = engine.make_unit({ position = engine.vec(0, 10, 0) })
	for i, w in ipairs(WARNINGS) do
		engine.set_time(i * 10)
		mod.ui.indicate_warning(unit, w)
	end

	-- 3. diff
	t.it("every setting the code reads is declared in data.lua", function()
		local missing = {}
		for id in pairs(requested) do
			if not declared[id] and not INTENTIONALLY_UNDECLARED[id] then
				missing[#missing + 1] = id
			end
		end
		table.sort(missing)

		t.eq(#missing, 0,
			"undeclared settings read by code: " .. table.concat(missing, ", "))
	end)
end
