local mod = get_mod("Spidey Sense")
local get_userdata_type = mod.helper.get_userdata_type
local Unit_alive = Unit.alive
local Vector3Box = Vector3Box

mod.source_registry = {}
local registry = mod.source_registry

local manual_map = {}
local auto_map = {}
local manual_positions = {}
local auto_positions = {}
local ring = {}
local ring_pos = 1
local CAP = 512

registry.hits = 0
registry.misses = 0

local function put_auto(source_id, unit, position_box)
	if auto_map[source_id] == nil and auto_positions[source_id] == nil then
		local evict = ring[ring_pos]
		if evict ~= nil then
			auto_map[evict] = nil
			auto_positions[evict] = nil
		end
		ring[ring_pos] = source_id
		ring_pos = ring_pos + 1
		if ring_pos > CAP then
			ring_pos = 1
		end
	end
	auto_map[source_id] = unit
	auto_positions[source_id] = position_box
end

registry.get = function(source_id)
	local unit = manual_map[source_id]
	if unit ~= nil then
		if Unit_alive(unit) then
			return unit
		end
		manual_map[source_id] = nil
	end
	unit = auto_map[source_id]
	if unit ~= nil then
		if Unit_alive(unit) then
			return unit
		end
		auto_map[source_id] = nil
	end

	local box = manual_positions[source_id] or auto_positions[source_id]
	if box ~= nil then
		return box:unbox()
	end

	return nil
end

local last_sweep = 0

registry.update = function()
	local t = Managers.time:time("main")
	if t - last_sweep < 5 then
		return
	end
	last_sweep = t
	for source_id, unit in pairs(manual_map) do
		if not Unit_alive(unit) then
			manual_map[source_id] = nil
		end
	end
end

local installed = false

registry.install = function()
	if installed then
		return
	end
	installed = true

	mod:hook(WwiseWorld, "make_auto_source", function(func, wwise_world, unit_or_position, ...)
		local source_id = func(wwise_world, unit_or_position, ...)
		if source_id then
			local source_type = get_userdata_type(unit_or_position)
			if source_type == "Unit" then
				put_auto(source_id, unit_or_position, nil)
			elseif source_type == "Vector3" then
				put_auto(source_id, nil, Vector3Box(unit_or_position))
			end
		end
		return source_id
	end)

	mod:hook(WwiseWorld, "make_manual_source", function(func, wwise_world, unit_or_position, ...)
		local source_id = func(wwise_world, unit_or_position, ...)
		if source_id then
			local source_type = get_userdata_type(unit_or_position)
			if source_type == "Unit" then
				manual_map[source_id] = unit_or_position
			elseif source_type == "Vector3" then
				manual_positions[source_id] = Vector3Box(unit_or_position)
			end
		end
		return source_id
	end)

	mod:hook_safe(WwiseWorld, "destroy_manual_source", function(wwise_world, source_id)
		manual_map[source_id] = nil
		manual_positions[source_id] = nil
	end)
end

mod:command("spideyregistry", "Print Spidey source-registry stats", function()
	local m, a = 0, 0
	for _ in pairs(manual_map) do
		m = m + 1
	end
	for _ in pairs(auto_map) do
		a = a + 1
	end
	mod:echo(string.format("[Spidey registry] hits=%d misses=%d manual=%d auto=%d", registry.hits, registry.misses, m, a))
end)
