--[[
Title: Spidey Sense
Author: Wobin
Date: 10/07/2026
Repository: https://github.com/Wobin/SpideySense
Version: 7.6
--]]

local mod = get_mod("Spidey Sense")

mod.version = "7.6"

mod.showCleave = false
mod.showNet = false
mod.showCharge = false
mod.showShot = false
mod.showPounce = false
mod.showSniper = false
mod._indicators = {}

mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/Helper")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/SourceRegistry")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/Debug")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/MultiEnemyTracker")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/UI/UI")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/Sound")

local get_userdata_type = mod.helper.get_userdata_type
local source_registry = mod.source_registry


local original_create_indicator = mod.ui.create_indicator
mod.ui.create_indicator = function(unit_or_position, target_type, extra_duration)
	if type(unit_or_position) == "userdata" then
		mod.multi_enemy_tracker:register_unit(unit_or_position, target_type)
		if mod:get(target_type .. "_multi_enemy_show_numbers") then
			local breed_count = mod.multi_enemy_tracker:get_count(target_type)
			if breed_count >= 2 then
				local instance_number = mod.multi_enemy_tracker:get_instance_number(unit_or_position, target_type)
				return original_create_indicator(unit_or_position, target_type, extra_duration, instance_number)
			end
		end
	end
	return original_create_indicator(unit_or_position, target_type, extra_duration)
end

local create_indicator = mod.ui.create_indicator
local indicate_warning = mod.ui.indicate_warning

local active_enemies = {}
local function update_active_enemies()
  active_enemies.burster = mod:get("burster_active")
  active_enemies.barrel = mod:get("barrel_active")
  active_enemies.beast_of_nurgle = mod:get("beast_of_nurgle_active")
  active_enemies.crusher = mod:get("crusher_active")
  active_enemies.chaos_spawn = mod:get("chaos_spawn_active")
  active_enemies.daemonhost = mod:get("daemonhost_active")
  active_enemies.flamer = mod:get("flamer_active")
  active_enemies.grenadier = mod:get("grenadier_active")
  active_enemies.hound = mod:get("hound_active")
  active_enemies.mauler = mod:get("mauler_active")
  active_enemies.mutant = mod:get("mutant_active")
  active_enemies.plague_ogryn = mod:get("plague_ogryn_active")
  active_enemies.plasma_gunner = mod:get("plasma_gunner_active")
  active_enemies.rager = mod:get("rager_active")
  active_enemies.sniper = mod:get("sniper_active")
  active_enemies.trapper = mod:get("trapper_active")
  active_enemies.toxbomber = mod:get("toxbomber_active")
  active_enemies.melee_backstab = mod:get("melee_backstab_active")
  active_enemies.ranged_backstab = mod:get("ranged_backstab_active")
end

mod.on_setting_changed = function(setting_id)
  if mod.ui and mod.ui.invalidate_setting_caches then
    mod.ui.invalidate_setting_caches(setting_id)
  end
  if setting_id:match("_copy_from") then
    local typeName = string.sub(setting_id, 1, string.find(setting_id, "_copy_from") - 1)
    local new_value = mod:get(setting_id)
    if new_value and new_value ~= "none" then
      mod:set(typeName .. "_active",         mod:get(new_value .. "_active"),         false)
      mod:set(typeName .. "_radius",         mod:get(new_value .. "_radius"),         false)
      mod:set(typeName .. "_active_range",   mod:get(new_value .. "_active_range"),   false)
      mod:set(typeName .. "_nurgle_blessed", mod:get(new_value .. "_nurgle_blessed"), false)
      mod:set(typeName .. "_distance",       mod:get(new_value .. "_distance"),       false)
      mod:set(typeName .. "_arrow_distance", mod:get(new_value .. "_arrow_distance"), false)
      mod:set(typeName .. "_arrow_colour",   mod:get(new_value .. "_arrow_colour"),   false)
      mod:set(typeName .. "_only_behind",    mod:get(new_value .. "_only_behind"),    false)
      mod:set(typeName .. "_front_opacity",  mod:get(new_value .. "_front_opacity"),  false)
      mod:set(typeName .. "_front_colour",   mod:get(new_value .. "_front_colour"),   false)
      mod:set(typeName .. "_back_opacity",   mod:get(new_value .. "_back_opacity"),   false)
      mod:set(typeName .. "_back_colour",    mod:get(new_value .. "_back_colour"),    false)
      mod:set(typeName .. "_multi_enemy_show_numbers", mod:get(new_value .. "_multi_enemy_show_numbers"), false)
    end
    mod:set(setting_id, "none", false)
    return
  end
  if setting_id:match("_active") then
    update_active_enemies()
  end
end

update_active_enemies()

local throttle = {}

mod.hook_monster = function(sound_name, unit_or_position, check_unit)

	if sound_name:match("_spawn") and not sound_name:match("chaos_spawn") then
		return
	end

	local now = Managers.time:time("main")
	local lastCall = throttle[sound_name] or 0
	if now - lastCall < 0.5 then
		return
	end
	throttle[sound_name] = now
  if check_unit == nil then
    local userDataType = get_userdata_type(unit_or_position)
    if userDataType ~= "Unit" and userDataType ~= "Vector3" then
      local resolved = type(unit_or_position) == "number" and source_registry.get(unit_or_position) or nil
      if resolved then
        unit_or_position = resolved
        source_registry.hits = source_registry.hits + 1
      else
        unit_or_position = nil
        source_registry.misses = source_registry.misses + 1
      end
    end
  else
    unit_or_position = check_unit
  end

  if unit_or_position == nil then
    return
  end
  
	local breed_name = ""
	if sound_name:match("footstep") or sound_name:match("heavy_run") then
		local unit_data_extension = ScriptUnit.extension(unit_or_position, "unit_data_system")
		local breed = unit_data_extension and unit_data_extension:breed()
		breed_name = breed and breed.name or ""    
	end

	if active_enemies.burster
		and (sound_name:match("wwise/events/minions/play_minion_poxwalker_bomber")
			or sound_name:match("wwise/events/minions/play_enemy_combat_poxwalker_bomber"))
	then create_indicator(unit_or_position, "burster") end
  
	if active_enemies.hound
		and (sound_name:match("wwise/events/minions/play_enemy_chaos_hound"))
	then create_indicator(unit_or_position, "hound") end

	if active_enemies.mutant 
    and sound_name:match("wwise/events/minions/play_enemy_mutant_charger") 
  then create_indicator(unit_or_position, "mutant")	end
  
	if active_enemies.trapper
		and (sound_name:match("wwise/events/minions/play_netgunner_run_foley_special")
			or sound_name:match("wwise/events/minions/play_netgunner_reload"))
	then create_indicator(unit_or_position, "trapper") end
  
	if active_enemies.sniper
		and (sound_name:match("wwise/events/weapon/play_combat_weapon_las_sniper")
			or sound_name:match("wwise/events/weapon/play_special_sniper_flash")
			or (breed_name:match("sniper") and sound_name:match("wwise/events/minions/play_netgunner")))
	then create_indicator(unit_or_position, "sniper") end
    
	if active_enemies.grenadier
		and (breed_name:match("grenadier") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier"))
	then create_indicator(unit_or_position, "grenadier") end
  
	if active_enemies.barrel and sound_name:match("wwise/events/weapon/play_explosion_fuse") then
		create_indicator(unit_or_position, "barrel", 3)
	end
  
	if active_enemies.flamer
		and (sound_name:match("wwise/events/minions/play_enemy_cultist_flamer_foley_tank")
			or sound_name:match("wwise/events/weapon/play_aoe_liquid_fire_loop")
			or sound_name:match("wwise/events/minions/play_cultist_flamer_foley_gas_loop")
			or sound_name:match("wwise/events/weapon/play_minion_flamethrower_green_wind_up")
			or sound_name:match("wwise/events/weapon/play_minion_flamethrower_start")
			or (breed_name:match("flamer") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier")))
	then create_indicator(unit_or_position, "flamer")	end
  
  if active_enemies.crusher
    and breed_name:match("chaos_ogryn_executor")
    and (sound_name:match("play_minion_footsteps_chaos_ogryn") 
      or sound_name:match("play_enemy_chaos_ogryn_armoured_executor") 
      or sound_name:match("play_shared_foley_chaos_ogryn_elites"))
  then create_indicator(unit_or_position, "crusher") end
  
  if active_enemies.mauler
      and ((breed_name:match("renegade_executor") 
      and (sound_name:match("wwise/events/minions/play_shared_foley_traitor_guard_heavy_run") 
      or sound_name:match("wwise/events/minions/play_minion_footsteps_boots_heavy")))
      or sound_name:match("wwise/events/minions/play_shared_elite_executor_cleave_warning"))
  then create_indicator(unit_or_position, "mauler") end
  
  if active_enemies.daemonhost
    and (sound_name:match("wwise/events/minions/play_enemy_daemonhost") 
    or sound_name:match("wwise/events/vo/play_sfx_es_daemonhost_vo")
    or sound_name:match("wwise/externals/loc_enemy_daemonhost"))
  then create_indicator(unit_or_position, "daemonhost") end
  
  if active_enemies.rager
    and (breed_name:match("berzerker") 
    and (sound_name:match("wwise/events/minions/play_shared_foley_elite_run") 
    or sound_name:match("wwise/events/minions/play_minion_footsteps_boots_heavy") 
    or sound_name:match("wwise/events/minions/play_minion_footsteps_wrapped_feet_specials") 
    or sound_name:match("wwise/events/minions/play_enemy_traitor_berzerker")
    or sound_name:match("wwise/events/minions/play_enemy_cultist_berzerker")
    or sound_name:match("wwise/events/minions/play_shared_foley_chaos_cultist_light_run")))
  then create_indicator(unit_or_position, "rager") end
  
  if active_enemies.toxbomber
    and (sound_name:match("wwise/events/minions/play_cultist_grenadier"))
    then create_indicator(unit_or_position, "toxbomber") end
  
  if active_enemies.plague_ogryn
    and sound_name:match("plague_ogryn") 
    then create_indicator(unit_or_position, "plague_ogryn") end    
  
  if active_enemies.chaos_spawn
    and sound_name:match("chaos_spawn") 
    then create_indicator(unit_or_position, "chaos_spawn") end
  
  if active_enemies.beast_of_nurgle
    and sound_name:match("beast_of_nurgle") 
    then create_indicator(unit_or_position, "beast_of_nurgle") end

  if active_enemies.plasma_gunner
    and (( breed_name:match("renegade_plasma_gunner")
          and (sound_name:match("play_footstep_boots_medium_enemy") or sound_name:match("traitor_guard_heavy_run")))
    or sound_name:match("plasmapistol"))
    then create_indicator(unit_or_position, "plasma_gunner") end
  
  if active_enemies.melee_backstab
		and sound_name:match("wwise/events/player/play_backstab_indicator_melee")
	then create_indicator(unit_or_position, "melee_backstab") end

	if active_enemies.ranged_backstab
		and sound_name:match("wwise/events/player/play_backstab_indicator_ranged")
    then create_indicator(unit_or_position, "ranged_backstab") end
  

  if mod:get("render_crusher_warning") and sound_name:match("cleave_warning") then
    indicate_warning(unit_or_position, "cleave")
  end
  
  if mod:get("render_trapper_warning") 
    and (sound_name:match("play_weapon_netgunner_wind_up")) then       
    indicate_warning(unit_or_position, "trap")     
  end
  
  if mod:get("render_pogryn_warning")
    and (sound_name:match("play_enemy_plague_ogryn_vce_charge")) then
        indicate_warning(unit_or_position, "charge")
  end
  
  if mod:get("render_shotgun_warning")
    and (sound_name:match("play_minion_shotgun_pump")) then
      indicate_warning(unit_or_position, "shot")
  end
  
  if mod:get("render_hound_warning")
      and ((sound_name:match("play_enemy_chaos_hound_vce_leap") or sound_name:match("wwise/events/minions/play_chaos_hound_armoured_vce_leap"))
      or (mod:get("render_pack_hound_warning") and sound_name:match("play_chaos_hound_mutator_vce_leap"))) then
        indicate_warning(unit_or_position, "pounce") 
  end
  if mod:get("render_sniper_warning")
    and (sound_name:match("play_special_sniper_flash") or sound_name:match("play_weapon_longlas_minion")) then
      indicate_warning(unit_or_position, "sniper")
  end
  
end  


mod.update = function(dt)
  mod.multi_enemy_tracker:update()
  source_registry.update()
end

mod.on_all_mods_loaded = function()

  if not Managers.backend:authenticated() then
   Promise.delay(5):next(mod.on_all_mods_loaded)
   return
  end

  local function load_package(package_name)
    if not Managers.package:has_loaded(package_name) then
      Managers.package:load(package_name, "Spidey Sense")
    end
  end

  load_package("packages/ui/views/inventory_background_view/inventory_background_view")

  mod:info(mod.version)
  mod.ui.loadWarnings()

  local hooked_external_sounds = mod.sound.hooked_external_sounds
  local hooked_sounds = mod.sound.hooked_sounds
  local hook_monster = mod.hook_monster

  source_registry.install()

  mod:hook_safe(WwiseWorld, "trigger_resource_event", function(_wwise_world, wwise_event_name, unit_or_position_or_id)
    for _, sound_name in ipairs(hooked_sounds) do    
      if wwise_event_name:match(sound_name) then            
        hook_monster(wwise_event_name, unit_or_position_or_id, Application.flow_callback_context_unit())
        return
      end
    end
  end)

  mod:hook_safe(WwiseWorld, "trigger_resource_external_event", function(_wwise_world, sound_event, sound_source, file_path, file_format, wwise_source_id)
      for _, speaker in ipairs(hooked_external_sounds) do
        if sound_source:match(speaker) then        
          hook_monster(file_path, wwise_source_id, Application.flow_callback_context_unit())
        end
      end
  end)

  local throttle = 0
  mod:hook_require("scripts/settings/fx/effect_templates/chaos_daemonhost_ambience", function(template)
    mod:hook_safe(template, "update", function(template_data, template_context, dt, t)
      if t - throttle < 1 then return end
      throttle = t
      if template_data.stage == 1 then
        if not mod:get("daemonhost_active") then return end
        create_indicator(template_data.unit, "daemonhost")
      end
    end)
  end)

  mod:hook_require("scripts/settings/fx/effect_templates/renegade_sniper_laser", function(template)
    mod:hook_safe(template, "start", function(template_data, template_context)
      if not mod:get("render_sniper_warning") then return end
      indicate_warning(template_data.unit, "sniper")
    end)
  end)

  local hooked_inventory_sounds = mod.sound.hooked_inventory_sounds
  mod:hook_require("scripts/extension_systems/fx/minion_fx_extension", function(MinionFxExtension)
    mod:hook_safe(MinionFxExtension, "_trigger_inventory_wwise_event", function(self, event_name)
      local unit = self._unit
      if not unit then return end
      for _, sound_name in ipairs(hooked_inventory_sounds) do
        if event_name:match(sound_name) then
          hook_monster(event_name, unit, unit)
          return
        end
      end
    end)
  end)
end