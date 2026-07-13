local engine = require("spec.mock_engine")
local t = require("spec.runner")

-- The six warning HUD elements were six copies of one file; they now come from a shared
-- factory. This pins what actually differs between them (class name, localization key,
-- screen position, and which warning id gates visibility) so the factory can't quietly
-- mis-wire one -- e.g. give two warnings the same visibility key.
--
-- { file, class_name, key, position, indicate_via_target }
local ELEMENTS = {
	{ "ChargeWarning", "SpideySenseUIChargeWarning", "charge", { 0, -150, 1 }, "charge" },
	{ "CleaveWarning", "SpideySenseUICleaveWarning", "cleave", { -350, 0, 1 }, "cleave" },
	{ "NetWarning",    "SpideySenseUINetWarning",    "net",    { 350, 0, 1 },  "trap"   },
	{ "PounceWarning", "SpideySenseUIPounceWarning", "pounce", { 0, -150, 1 }, "pounce" },
	{ "ShotWarning",   "SpideySenseUIShotWarning",   "shot",   { 0, 150, 1 },  "shot"   },
	{ "SniperWarning", "SpideySenseUISniperWarning", "sniper", { 0, -150, 1 }, "sniper" },
}

return function()
	t.suite("Warning HUD elements")

	local function load_all()
		local mod = engine.install({
			crusher_range_max = 100,
			trapper_range_max = 100,
			pogryn_range_max = 100,
			shotgun_range_max = 100,
			hound_range_max = 100,
		})
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/core/Helper.lua")
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/ui/UI.lua")

		local built = {}
		for _, e in ipairs(ELEMENTS) do
			local Warning = dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/ui/warnings/" .. e[1] .. ".lua")

			-- Definitions are private to the element; capture them via super.init.
			local defs
			Warning.super.init = function(_self, _p, _d, _s, d) defs = d end
			Warning:init(nil, nil, nil)

			built[e[1]] = { class = Warning, defs = defs }
		end
		return mod, built
	end

	local mod, built = load_all()

	for _, e in ipairs(ELEMENTS) do
		local file, class_name, key, position = e[1], e[2], e[3], e[4]

		t.it(file .. " has the right class, key and position", function()
			local b = built[file]
			t.truthy(b.defs, "element must pass Definitions to HudElementBase")

			t.eq(b.class.__name, class_name, "class name")

			local pass = b.defs.widget_definitions.alert.passes[1]
			t.eq(pass.value, key .. "_text", "localization key")
			t.eq(pass.value_id, "text", "pass id normalised")

			local pos = b.defs.scenegraph_definition.alert.position
			t.eq(pos[1], position[1], "position x")
			t.eq(pos[2], position[2], "position y")
		end)
	end

	-- register_hud_element takes the element's path as a STRING. A wrong path does not error --
	-- the HUD element simply never appears. That makes it the quietest way to break this mod, and
	-- exactly what a file reorganisation risks.
	t.it("every registered hud element path points at a real file", function()
		local mod = engine.install({})
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/core/Helper.lua")
		dofile(engine.MOD_ROOT .. "/scripts/mods/Spidey Sense/ui/UI.lua")
		mod.ui.loadWarnings()

		t.eq(#mod.hud_elements, 6, "all six warnings must register")

		for _, def in ipairs(mod.hud_elements) do
			-- "Spidey Sense/scripts/…/X" -> "<root>/scripts/…/X.lua"
			local rest = def.filename:gsub("^Spidey Sense/", "")
			local path = engine.MOD_ROOT .. "/" .. rest .. ".lua"

			local f = io.open(path, "r")
			t.truthy(f, "missing hud element file: " .. def.filename)
			if f then f:close() end
		end
	end)

	t.it("each element's visibility is gated by its OWN warning only", function()
		for _, e in ipairs(ELEMENTS) do
			local target = e[5]

			-- clear any warning left over from the previous iteration
			for k in pairs(mod.ui.warning_expiry) do
				mod.ui.warning_expiry[k] = nil
			end

			engine.advance(10)
			local enemy = engine.make_unit({ position = engine.vec(0, 10, 0) })
			mod.ui.indicate_warning(enemy, target)

			for _, other in ipairs(ELEMENTS) do
				local vis = built[other[1]].defs.widget_definitions.alert.passes[1].visibility_function()
				if other[1] == e[1] then
					t.truthy(vis, e[1] .. " must be visible when its own warning fires")
				else
					t.falsy(vis, other[1] .. " must stay hidden when " .. e[1] .. " fires")
				end
			end
		end
	end)
end
