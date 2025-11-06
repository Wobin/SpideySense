--[[
Title: Spidey Sense
Author: Wobin
Date: 06/11/2025
Repository: https://github.com/Wobin/SpideySense
Version: 5.3.1
--]]

local mod = get_mod("Spidey Sense")
local FontManager = require("scripts/managers/ui/ui_font_manager")

mod.version = "5.3.1"

mod.showCleave = false
mod.showNet = false
mod.showCharge = false
mod.showShot = false
mod.showPounce = false
mod.showSniper = false
mod.main = {}
mod._indicators = {}

mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/Helper")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/Debug")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/UI/UI")
mod:io_dofile("Spidey Sense/scripts/mods/Spidey Sense/Sound")

local create_indicator = mod.ui.create_indicator 
local findlocalvalue = mod.helper.findlocalvalue
local get_userdata_type = mod.helper.get_userdata_type
local indicate_warning = mod.ui.indicate_warning 


function mod:getTrapper()  
  local name,value = debug.getlocal(8, 1)  
  return value._unit
end

local throttle = {}
local tc = Managers.time

mod.hook_monster = function(sound_name, unit_or_position, check_unit)
  
	--ignore monster spawn
	if sound_name:match("_spawn") and not sound_name:match("chaos_spawn") then
    --mod:echo(sound_name)
		return
	end

	-- throttle half a second on each type
	local lastCall = throttle[sound_name] or 0
	local delta = tc:time("main") - lastCall
	if delta < 0.5 then
		return
	end
	throttle[sound_name] = tc:time("main")
  if check_unit == nil then
    local userDataType = get_userdata_type(unit_or_position)
    -- if the unit_or_position is nil or a number,
    -- try to pull the unit or position from higher in the callstack
    if userDataType ~= "Unit" and userDataType ~= "Vector3" then
      unit_or_position = findlocalvalue({
        { "attacking_unit", "Unit" },
        { "position", "Vector3" },      
        { "parent_unit", "Unit" },
        { "unit", "Unit" },
        { "dialogue_actor_unit", "Unit"},      
      })
    end
  else
    unit_or_position = check_unit  
  end
  
  -- Naturally netters aren't as straight forward as we hoped, we need to pull the unit from the event extension
  if sound_name:match("wwise/events/minions/play_weapon_netgunner_wind_up") then 
    unit_or_position = mod:getTrapper()    
  end
  
  if unit_or_position == nil then
    --mod:echo("Cannot match unit on ".. sound_name)
    --mod:dump(extract_locals(1))
    return
  end
  
	local breed_name = ""
	if sound_name:match("footstep") or sound_name:match("heavy_run") then
		local unit_data_extension = ScriptUnit.extension(unit_or_position, "unit_data_system")
		local breed = unit_data_extension and unit_data_extension:breed()
		breed_name = breed and breed.name or ""    
	end

	if mod:get("burster_active")
		and (sound_name:match("wwise/events/minions/play_minion_poxwalker_bomber")
			or sound_name:match("wwise/events/minions/play_enemy_combat_poxwalker_bomber"))
	then create_indicator(unit_or_position, "burster") end
  
	if mod:get("hound_active")
		and (sound_name:match("wwise/events/minions/play_enemy_chaos_hound"))
	then create_indicator(unit_or_position, "hound") end

	if mod:get("mutant_active") 
    and sound_name:match("wwise/events/minions/play_enemy_mutant_charger") 
  then create_indicator(unit_or_position, "mutant")	end
  
	if mod:get("trapper_active")
		and (sound_name:match("wwise/events/minions/play_netgunner_run_foley_special")
			or sound_name:match("wwise/events/minions/play_netgunner_reload"))
	then create_indicator(unit_or_position, "trapper") end
  
	if mod:get("sniper_active")
		and (sound_name:match("wwise/events/weapon/play_combat_weapon_las_sniper")
			or sound_name:match("wwise/events/weapon/play_special_sniper_flash")
			or (breed_name:match("sniper") and sound_name:match("wwise/events/minions/play_netgunner")))
	then create_indicator(unit_or_position, "sniper") end
    
	if mod:get("grenadier_active")
		and (breed_name:match("grenadier") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier"))
	then create_indicator(unit_or_position, "grenadier") end
  
	if mod:get("barrel_active") and sound_name:match("wwise/events/weapon/play_explosion_fuse") then
		create_indicator(unit_or_position, "barrel", 3)
	end
  
	if mod:get("flamer_active")
		and (sound_name:match("wwise/events/minions/play_enemy_cultist_flamer_foley_tank")
			or sound_name:match("wwise/events/weapon/play_aoe_liquid_fire_loop")
			or sound_name:match("wwise/events/minions/play_cultist_flamer_foley_gas_loop")
			or sound_name:match("wwise/events/weapon/play_minion_flamethrower_green_wind_up")
			or sound_name:match("wwise/events/weapon/play_minion_flamethrower_start")
			or (breed_name:match("flamer") and sound_name:match("wwise/events/minions/play_traitor_guard_grenadier")))
	then create_indicator(unit_or_position, "flamer")	end
  
  if mod:get("crusher_active")
    and breed_name:match("chaos_ogryn_executor")
    and (sound_name:match("play_minion_footsteps_chaos_ogryn") 
      or sound_name:match("play_enemy_chaos_ogryn_armoured_executor") 
      or sound_name:match("play_shared_foley_chaos_ogryn_elites"))
  then create_indicator(unit_or_position, "crusher") end
  
  if mod:get("mauler_active")
      and ((breed_name:match("renegade_executor") 
      and (sound_name:match("wwise/events/minions/play_shared_foley_traitor_guard_heavy_run") 
      or sound_name:match("wwise/events/minions/play_minion_footsteps_boots_heavy")))
      or sound_name:match("wwise/events/minions/play_shared_elite_executor_cleave_warning"))
  then create_indicator(unit_or_position, "mauler") end
  
  if mod:get("daemonhost_active")
    and (sound_name:match("wwise/events/minions/play_enemy_daemonhost") 
    or sound_name:match("wwise/events/vo/play_sfx_es_daemonhost_vo")
    or sound_name:match("wwise/externals/loc_enemy_daemonhost"))
  then create_indicator(unit_or_position, "daemonhost") end
  
  if mod:get("rager_active")
    and (breed_name:match("berzerker") 
    and (sound_name:match("wwise/events/minions/play_shared_foley_elite_run") 
    or sound_name:match("wwise/events/minions/play_minion_footsteps_boots_heavy") 
    or sound_name:match("wwise/events/minions/play_minion_footsteps_wrapped_feet_specials") 
    or sound_name:match("wwise/events/minions/play_enemy_traitor_berzerker")
    or sound_name:match("wwise/events/minions/play_enemy_cultist_berzerker")
    or sound_name:match("wwise/events/minions/play_shared_foley_chaos_cultist_light_run")))
  then create_indicator(unit_or_position, "rager") end
  
  if mod:get("toxbomber_active")
    and (sound_name:match("wwise/events/minions/play_cultist_grenadier"))
    then create_indicator(unit_or_position, "toxbomber") end
  
  if mod:get("plague_ogryn_active")
    and sound_name:match("plague_ogryn") 
    then create_indicator(unit_or_position, "plague_ogryn") end    
  
  if mod:get("chaos_spawn_active")
    and sound_name:match("chaos_spawn") 
    then create_indicator(unit_or_position, "chaos_spawn") end
  
  if mod:get("beast_of_nurgle_active")
    and sound_name:match("beast_of_nurgle") 
    then create_indicator(unit_or_position, "beast_of_nurgle") end

  if mod:get("plasma_gunner_active")
    and (( breed_name:match("renegade_plasma_gunner")
          and (sound_name:match("play_footstep_boots_medium_enemy") or sound_name:match("traitor_guard_heavy_run")))
    or sound_name:match("plasmapistol"))
    then create_indicator(unit_or_position, "plasma_gunner") end
  
  if mod:get("melee_backstab_active")
		and sound_name:match("wwise/events/player/play_backstab_indicator_melee")
			or sound_name:match("wwise/events/player/play_backstab_indicator_melee_elite")
	then create_indicator(unit_or_position, "melee_backstab") end

	if mod:get("ranged_backstab_active")
		and sound_name:match("wwise/events/player/play_backstab_indicator_ranged")
    then create_indicator(unit_or_position, "ranged_backstab") end
  

  if mod:get("render_crusher_warning") and sound_name:match("cleave") then       
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
      and (sound_name:match("play_enemy_chaos_hound_vce_leap")
      or (mod:get("render_pack_hound_warning") and sound_name:match("play_chaos_hound_mutator_vce_leap"))) then
        indicate_warning(unit_or_position, "pounce") 
  end
  if mod:get("render_sniper_warning")
    and sound_name:match("play_special_sniper_flasheer") or sound_name:match("play_weapon_longlas_minion") then
      indicate_warning(unit_or_position, "sniper")
  end
  
end  


mod.on_all_mods_loaded = function()

  if not Managers.backend:authenticated() then
   Promise.delay(5):next(mod.on_all_mods_loaded)
   return
  end

  mod:info(mod.version)
  mod.ui.loadWarnings()

  local hooked_external_sounds = mod.sound.hooked_external_sounds
  local hooked_sounds = mod.sound.hooked_sounds
  local hook_monster = mod.hook_monster

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
end