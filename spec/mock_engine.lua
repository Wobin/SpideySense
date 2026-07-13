-- Stub Stingray/DMF surface so Spidey Sense modules can be loaded by standalone LuaJIT.
-- Only what the mod actually touches is implemented; anything else is a deliberate nil
-- so an unnoticed new engine dependency fails loudly instead of silently passing.

local M = {}

M.MOD_ROOT = "."
M.MOD_NAME = "Spidey Sense"

----------------------------------------------------------------------
-- clock
----------------------------------------------------------------------

local now = 0

function M.set_time(t) now = t end
function M.advance(dt) now = now + dt end
function M.time() return now end

----------------------------------------------------------------------
-- vectors (a real implementation, so distance maths in tests is genuine)
----------------------------------------------------------------------

-- Vector3 is userdata in-engine, and Helper.get_userdata_type keys off type(x) == "userdata",
-- so these must be real userdata (newproxy) rather than tables or the type probe misfires.
local comps = setmetatable({}, { __mode = "k" })

local function vec(x, y, z)
	local v = newproxy(true)
	local mt = getmetatable(v)
	comps[v] = { x = x or 0, y = y or 0, z = z or 0 }
	mt.__index = function(u, k) return comps[u][k] end
	mt.__newindex = function(u, k, val) comps[u][k] = val end
	mt.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end
	mt.__add = function(a, b) return vec(a.x + b.x, a.y + b.y, a.z + b.z) end
	mt.__unm = function(a) return vec(-a.x, -a.y, -a.z) end
	return v
end
M.vec = vec

local Vector3 = setmetatable({}, { __call = function(_, x, y, z) return vec(x, y, z) end })

function Vector3.zero() return vec(0, 0, 0) end
function Vector3.up() return vec(0, 0, 1) end
function Vector3.forward() return vec(0, 1, 0) end
function Vector3.is_valid(v) return comps[v] ~= nil end
function Vector3.length(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
function Vector3.distance(a, b) return Vector3.length(a - b) end
function Vector3.dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end

function Vector3.normalize(v)
	local len = Vector3.length(v)
	if len == 0 then return vec(0, 0, 0) end
	return vec(v.x / len, v.y / len, v.z / len)
end

function Vector3.cross(a, b)
	return vec(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

-- Boxes a Vector3 so it survives past the current frame. Raw Vector3s are frame-local temps,
-- so anything the registry keeps across frames MUST be boxed.
local function Vector3Box(v)
	local x, y, z = v.x, v.y, v.z
	return {
		unbox = function(_self)
			return vec(x, y, z)
		end,
		store = function(_self, other)
			x, y, z = other.x, other.y, other.z
		end,
	}
end

local Quaternion = {}
function Quaternion.identity() return { __is_quat = true } end
function Quaternion.inverse(q) return q end
function Quaternion.rotate(_q, v) return v end
function Quaternion.forward(_q) return vec(0, 1, 0) end
function Quaternion.look(v) return { __is_quat = true, dir = v } end

local Matrix4x4 = {}
function Matrix4x4.translation(pose) return pose and pose.position or vec(0, 0, 0) end
function Matrix4x4.rotation(pose) return pose and pose.rotation or Quaternion.identity() end

local Camera = {}
function Camera.local_rotation(_c) return Quaternion.identity() end

----------------------------------------------------------------------
-- units
----------------------------------------------------------------------

local unit_registry = setmetatable({}, { __mode = "k" })

-- Units are userdata in-engine, and Helper.get_userdata_type probes type(x) == "userdata"
-- before anything else, so a table here would silently fail every unit path.
function M.make_unit(opts)
	opts = opts or {}
	local u = newproxy(false)
	unit_registry[u] = {
		alive = opts.alive ~= false,
		position = opts.position or vec(0, 0, 0),
		breed = opts.breed,
		health = opts.health or 100,
	}
	return u
end

function M.kill_unit(u)
	local rec = unit_registry[u]
	if rec then
		rec.alive = false
		rec.health = 0
	end
end

function M.set_unit_position(u, p)
	local rec = unit_registry[u]
	if rec then rec.position = p end
end

local Unit = {}
function Unit.alive(u)
	local rec = unit_registry[u]
	return rec ~= nil and rec.alive == true
end

function Unit.local_position(u, _index)
	local rec = unit_registry[u]
	return rec and rec.position or vec(0, 0, 0)
end

Unit.world_position = Unit.local_position

local ScriptUnit = {}
function ScriptUnit.extension(u, system)
	local rec = unit_registry[u]
	if not rec then return nil end
	if system == "unit_data_system" then
		return { breed = function() return rec.breed and { name = rec.breed } or nil end }
	elseif system == "health_system" then
		return { current_health = function() return rec.health end }
	elseif system == "buff_system" then
		return { buffs = function() return {} end }
	end
	return nil
end

----------------------------------------------------------------------
-- colours
----------------------------------------------------------------------

local COLOR_NAMES = {
	"white", "yellow", "lime", "teal", "turquoise", "tomato", "sienna",
	"burly_wood", "cheeseburger", "blue_violet", "online_green", "sandy_brown",
	"chart_reuse", "cadet_blue", "spring_green", "powder_blue", "royal_blue",
	"midnight_blue", "medium_violet_red", "medium_spring_green", "ui_terminal",
	"ui_red_medium", "ui_blue_light", "ui_green_light", "ui_ability_purple",
	"ui_interaction_pickup", "ui_hud_warp_charge_medium", "ui_hud_warp_charge_low",
	"citadel_averland_sunset", "citadel_balthasar_gold", "citadel_dorn_yellow",
	"citadel_bieltan_green",
}

local Color = {}
for i, name in ipairs(COLOR_NAMES) do
	local shade = (i * 7) % 255
	Color[name] = function(alpha, _as_rgb)
		return { alpha or 255, shade, shade, shade }
	end
end
Color.list = COLOR_NAMES

----------------------------------------------------------------------
-- managers / engine singletons
----------------------------------------------------------------------

local fake_pose = { position = vec(0, 0, 0), rotation = Quaternion.identity() }

function M.set_listener_position(p) fake_pose.position = p end

local player = { viewport_name = "player1", player_unit = nil }

local Managers = {
	time = { time = function(_self, _name) return now end },
	player = {
		local_player = function(_self, _i) return player end,
		local_player_safe = function(_self, _i) return player end,
	},
	state = {
		camera = {
			camera = function(_self, _vp) return {} end,
			listener_pose = function(_self, _vp) return fake_pose end,
		},
		mission = { mission = function(_self) return { zone_id = "test" } end },
	},
	ui = { get_time = function(_self) return now end },
	backend = {
		authenticated = function(_self) return true end,
		authenticate = function(_self) return M.Promise:new() end,
	},
	package = {
		has_loaded = function(_self, _p) return true end,
		load = function(_self, _p, _n) end,
	},
	localization = { language = function(_self) return "en" end },
	url_loader = { load_texture = function(_self, _u) return M.Promise:new() end },
}

local Promise = {}
Promise.__index = Promise
function Promise:new()
	return setmetatable({}, Promise)
end
function Promise:next(_fn) return self end
function Promise.all(...) return setmetatable({}, Promise) end
function Promise.delay(_t) return setmetatable({}, Promise) end
M.Promise = Promise

local WwiseWorld = {
	trigger_resource_event = function() end,
	trigger_resource_external_event = function() end,
	make_auto_source = function() return 1 end,
	make_manual_source = function() return 1 end,
	destroy_manual_source = function() end,
	set_source_position = function() end,
	set_source_parameter = function() end,
}

local Application = {
	flow_callback_context_unit = function() return nil end,
}

----------------------------------------------------------------------
-- stdlib extensions the engine adds
----------------------------------------------------------------------

local function install_stdlib()
	function math.clamp(v, lo, hi)
		if v < lo then return lo end
		if v > hi then return hi end
		return v
	end

	function math.ease_out_exp(p)
		return p
	end

	function table.find_by_key(tbl, key, value)
		for i, entry in ipairs(tbl) do
			if entry[key] == value then
				return i, entry
			end
		end
		return nil, nil
	end

	-- Stingray's deep clone. data.lua relies on it to give each dropdown its own copy
	-- of the shared colour options (DMF localizes option.text in place).
	function table.clone(t)
		if type(t) ~= "table" then return t end
		local out = {}
		for k, v in pairs(t) do
			out[k] = type(v) == "table" and table.clone(v) or v
		end
		return out
	end
end

----------------------------------------------------------------------
-- the mock mod (DMF surface)
----------------------------------------------------------------------

local function new_mock_mod(settings)
	local mod = {
		settings = settings or {},
		echoes = {},
		hooks = {},
		require_hooks = {},
		hud_elements = {},
		commands = {},
	}

	function mod:get(id) return self.settings[id] end
	function mod:set(id, value, _save) self.settings[id] = value end
	function mod:echo(msg) self.echoes[#self.echoes + 1] = tostring(msg) end
	function mod:info(_msg) end
	function mod:error(_msg) end
	function mod:warning(_msg) end
	function mod:notify(_msg) end
	function mod:is_enabled() return true end
	function mod:localize(key) return key end
	function mod:dump(_a, _b, _c) end

	function mod:io_dofile(path)
		-- "Spidey Sense/scripts/mods/Spidey Sense/core/Helper" -> "<root>/scripts/mods/Spidey Sense/core/Helper.lua"
		local rest = path:gsub("^" .. M.MOD_NAME .. "/", "")
		return dofile(M.MOD_ROOT .. "/" .. rest .. ".lua")
	end

	function mod:hook(obj, name, fn)
		self.hooks[#self.hooks + 1] = { obj = obj, name = name, fn = fn, safe = false }
	end

	function mod:hook_safe(obj, name, fn)
		self.hooks[#self.hooks + 1] = { obj = obj, name = name, fn = fn, safe = true }
	end

	function mod:hook_require(path, cb)
		self.require_hooks[path] = cb
	end

	function mod:register_hud_element(def)
		self.hud_elements[#self.hud_elements + 1] = def
	end

	function mod:command(name, desc, fn)
		self.commands[name] = { desc = desc, fn = fn }
	end

	function mod:persistent_table(_name, default)
		return default or {}
	end

	return mod
end

----------------------------------------------------------------------
-- install
----------------------------------------------------------------------

-- Modules under test do `local mod = get_mod("Spidey Sense")` at file scope, so the
-- mod object must exist before any dofile. install() returns it.
function M.install(settings)
	now = 0
	fake_pose.position = vec(0, 0, 0)
	player.player_unit = nil

	install_stdlib()

	local mod = new_mock_mod(settings)
	M.mod = mod

	_G.Vector3 = Vector3
	_G.Vector3Box = Vector3Box
	_G.Quaternion = Quaternion
	_G.Matrix4x4 = Matrix4x4
	_G.Camera = Camera
	_G.Unit = Unit
	_G.ScriptUnit = ScriptUnit
	_G.Color = Color
	_G.Managers = Managers
	_G.WwiseWorld = WwiseWorld
	_G.Application = Application
	_G.Promise = Promise
	_G.DEDICATED_SERVER = false

	_G.get_mod = function(name)
		if name == M.MOD_NAME then return mod end
		return nil -- e.g. DarktideLocalServer absent, so UI takes the url_loader path
	end

	_G.class = function(name, _super)
		local c = { __name = name }
		c.__index = c
		c.super = { init = function() end }
		return c
	end

	local stub_modules = {
		["scripts/ui/hud/elements/damage_indicator/hud_element_damage_indicator_settings"] = {
			center_distance = 100,
			pulse_distance = 10,
			pulse_speed_multiplier = 2,
			life_time = 3,
			size = { 64, 64 },
		},
		["scripts/settings/ui/ui_hud_settings"] = { color = {} },
		["scripts/managers/ui/ui_widget"] = {
			create_definition = function(passes, scenegraph_id)
				return { passes = passes, scenegraph_id = scenegraph_id }
			end,
			draw = function() end,
		},
		["scripts/settings/ui/ui_workspace_settings"] = { screen = {} },
		["scripts/managers/ui/ui_fonts_definitions"] = {
			fonts = { proxima_nova_light = true, proxima_nova_bold = true },
		},
		["scripts/utilities/minion_visual_loadout"] = {},
	}

	-- Intercept engine requires only; anything else (the spec modules themselves)
	-- must still reach the real loader.
	local real_require = M._real_require or require
	M._real_require = real_require

	_G.require = function(path)
		local m = stub_modules[path]
		if m ~= nil then
			return m
		end
		if path:match("^spec%.") then
			return real_require(path)
		end
		error("mock_engine: unstubbed require('" .. tostring(path) .. "')", 2)
	end

	return mod
end

-- Give the mod a HUD element + preloaded arrow textures so create_indicator reaches
-- spawn_indicator instead of bailing early or detouring into async texture loading.
function M.attach_hud_element(mod)
	local function pass_style()
		return {
			size = { 32, 32 },
			offset = { 0, 0, 0 },
			pivot = { 0, 0 },
			material_values = { texture_map = "stub_texture" },
		}
	end

	local widget = {
		offset = { 0, 0, 0 },
		content = {},
		style = {
			background = pass_style(),
			front = pass_style(),
			arrow = pass_style(),
			arrow2 = pass_style(),
		},
	}

	mod.hudElement = widget
	mod.arrow1_texture = "stub_texture"
	mod.arrow2_texture = "stub_texture"
	return widget
end

return M
