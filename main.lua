local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_spiritborn = character_id == 7;
if not is_spiritborn then
     return
end;

local menu = require("menu");

local spells =
{
    armored_hide = require("spells/armored_hide"),
    concussive_stomp = require("spells/concussive_stomp"),
    counterattack = require("spells/counterattack"),
    crushing_hand = require("spells/crushing_hand"),
    payback = require("spells/payback"),
    quill_volley = require("spells/quill_volley"),
    rake = require("spells/rake"),
    ravager = require("spells/ravager"),
    razor_wings = require("spells/razor_wings"),
    rock_splitter = require("spells/rock_splitter"),
    rushing_claw = require("spells/rushing_claw"),
    scourge = require("spells/scourge"),
    soar = require("spells/soar"),
    stinger = require("spells/stinger"),
    the_devourer = require("spells/the_devourer"),
    the_hunter = require("spells/the_hunter"),
    the_protector = require("spells/the_protector"),
    the_seeker = require("spells/the_seeker"),
    thrash = require("spells/thrash"),
    thunderspike = require("spells/thunderspike"),
    touch_of_death = require("spells/touch_of_death"),
    toxic_skin = require("spells/toxic_skin"),
    vortex = require("spells/vortex"),
    withering_fist = require("spells/withering_fist"),
}

local my_utility = require("my_utility/my_utility")
local normal_monster_threshold = slider_int:new(1, 10, 5, get_hash(my_utility.plugin_label .. "normal_monster_threshold"))

on_render_menu(function ()

    if not menu.main_tree:push("Spiritborn: Base") then
        return;
    end;

    menu.main_boolean:render("Enable Plugin", "");

    if menu.main_boolean:get() == false then
      -- plugin not enabled, stop rendering menu elements
      menu.main_tree:pop();
      return;
    end;
 
    normal_monster_threshold:render("Normal Monster Threshold", "Threshold for considering normal monsters in target selection")
    spells.armored_hide.menu()
    spells.concussive_stomp.menu()
    spells.counterattack.menu()
    spells.crushing_hand.menu()
    spells.payback.menu()
    spells.quill_volley.menu()
    spells.rake.menu()
    spells.ravager.menu()
    spells.razor_wings.menu()
    spells.rock_splitter.menu()
    spells.rushing_claw.menu()
    spells.scourge.menu()
    spells.soar.menu()
    spells.stinger.menu()
    spells.the_devourer.menu()
    spells.the_hunter.menu()
    spells.the_protector.menu()
    spells.the_seeker.menu()
    spells.thrash.menu()
    spells.thunderspike.menu()
    spells.touch_of_death.menu()
    spells.toxic_skin.menu()
    spells.vortex.menu()
    spells.withering_fist.menu()
    menu.main_tree:pop();

end)

local can_move = 0.0;
local cast_end_time = 0.0;

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local my_utility = require("my_utility/my_utility");
local my_target_selector = require("my_utility/my_target_selector");

local max_hits = 0
local best_target = nil

-- Define scores for different enemy types
local normal_monster_value = 1
local elite_value = 2
local champion_value = 3
local boss_value = 20

-- Cache for heavy function results
local last_check_time = 0.0 -- Time of last check for most hits
local check_interval = 1.0 -- 1 second cooldown between checks

local function check_and_update_best_target(unit, player_position, max_range)
    local unit_position = unit:get_position()
    local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)

    if distance_sqr < (max_range * max_range) then
        local area_data = target_selector.get_most_hits_target_circular_area_light(unit_position, 5, 4, false)
        
        if area_data then
            local total_score = 0
            local n_normals = area_data.n_hits
            local has_elite = unit:is_elite()
            local has_champion = unit:is_champion()
            local is_boss = unit:is_boss()

            -- Skip single normal monsters unless there are more than the threshold
            if n_normals < normal_monster_threshold:get() and not (has_elite or has_champion or is_boss) then
                return -- Don't target single normal monsters or groups below threshold
            end

            -- Calculate score for normal monsters
            total_score = n_normals * normal_monster_value

            -- Add extra points for elite, champion, or boss
            if is_boss then
                total_score = total_score + boss_value
            elseif has_champion then
                total_score = total_score + champion_value
            elseif has_elite then
                total_score = total_score + elite_value
            end

            -- Prioritize based on score
            if total_score > max_hits then
                max_hits = total_score
                best_target = unit
            end
        end
    end
end

-- Updated function to get the closest valid enemy target
local function closest_target(player_position, entity_list, max_range)
    if not entity_list then
        return nil
    end

    local closest = nil
    local closest_dist_sqr = max_range * max_range

    for _, unit in ipairs(entity_list) do
        if target_selector.is_valid_enemy(unit) and unit:is_enemy() then
            local unit_position = unit:get_position()
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)
            if distance_sqr < closest_dist_sqr then
                closest = unit
                closest_dist_sqr = distance_sqr
            end
        end
    end

    return closest
end

-- on_update callback
on_update(function ()

    local local_player = get_local_player();
    if not local_player then
        return;
    end
    
    if menu.main_boolean:get() == false then
        -- if plugin is disabled dont do any logic
        return;
    end;

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        return;
    end;

    if not my_utility.is_action_allowed() then
        return;
    end  

    local screen_range = 16.0;
    local player_position = get_player_position();

    local collision_table = { false, 2.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    if not target_selector_data.is_valid then
        return;
    end

    local is_auto_play_active = auto_play.is_active();
    local max_range = 10.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    -- Only update best_target if cooldown has expired
    if current_time >= last_check_time + check_interval then
        -- Use the already fetched entity_list here
        local target_selector_data = my_target_selector.get_target_selector_data(
            player_position, 
            entity_list);

        if target_selector_data and target_selector_data.is_valid then
            max_hits = 0
            best_target = nil

            -- Check normal units and apply the priority-based logic
            for _, unit in ipairs(target_selector_data.list) do
                check_and_update_best_target(unit, player_position, max_range)
            end

            -- Update last check time
            last_check_time = current_time
        end
    end

    -- If no target meets the threshold, skip further logic and keep searching in future updates
    if not best_target then
        return
    end

    -- If best_target exists, continue with the rest of the logic
    local best_target_position = best_target:get_position();
    local distance_sqr = best_target_position:squared_dist_to_ignore_z(player_position);

    if distance_sqr > (max_range * max_range) then            
        return
    end

    if spells.armored_hide.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.concussive_stomp.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.counterattack.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.crushing_hand.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.payback.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.quill_volley.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.rake.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.ravager.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.razor_wings.logics(entity_list, target_selector_data, best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.rock_splitter.logics(closest_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.rushing_claw.logics(entity_list, target_selector_data, best_target, closest_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.scourge.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.soar.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.stinger.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.the_devourer.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.the_hunter.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.the_protector.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.the_seeker.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.thrash.logics(closest_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    -- New logic for Thunderspike, adapted from Maul
    if entity_list then
        local closest_thunderspike_target = closest_target(player_position, entity_list, max_range)
        
        if closest_thunderspike_target and spells.thunderspike.logics(closest_thunderspike_target) then
            cast_end_time = current_time + 0.4;
            return;
        end;
    else
        console.print("Warning: entity_list is nil, skipping thunderspike")
    end

    if spells.touch_of_death.logics(best_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.toxic_skin.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.vortex.logics() then
        cast_end_time = current_time + 0.2;
        return;
    end;

    if spells.withering_fist.logics(closest_target) then
        cast_end_time = current_time + 0.2;
        return;
    end;


    -- auto play engage far away monsters
    local move_timer = get_time_since_inject()
    if move_timer < can_move then
        return;
    end;

    local is_auto_play = my_utility.is_auto_play_enabled();
    if is_auto_play then
        local player_position = local_player:get_position();
        local is_dangerous_evade_position = evade.is_dangerous_position(player_position);
        if not is_dangerous_evade_position then
            local closer_target = target_selector.get_target_closer(player_position, 15.0);
            if closer_target then
                local closer_target_position = closer_target:get_position();
                local move_pos = closer_target_position:get_extended(player_position, 4.0);
                if pathfinder.move_to_cpathfinder(move_pos) then
                    can_move = move_timer + 1.50;
                end
            end
        end
    end

end)

local draw_player_circle = false;
local draw_enemy_circles = false;

on_render(function ()

    if menu.main_boolean:get() == false then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    if draw_player_circle then
        graphics.circle_3d(player_position, 8, color_white(85), 3.5, 144)
        graphics.circle_3d(player_position, 6, color_white(85), 2.5, 144)
    end    

    if draw_enemy_circles then
        local enemies = actors_manager.get_enemy_npcs()

        for i,obj in ipairs(enemies) do
        local position = obj:get_position();
        local distance_sqr = position:squared_dist_to_ignore_z(player_position);
        local is_close = distance_sqr < (8.0 * 8.0);
            graphics.circle_3d(position, 1, color_white(100));

            local future_position = prediction.get_future_unit_position(obj, 0.4);
            graphics.circle_3d(future_position, 0.5, color_yellow(100));
        end;
    end

    local screen_range = 16.0;
    local player_position = get_player_position();

    local collision_table = { false, 2.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    if not target_selector_data.is_valid then
        return;
    end
 
    local is_auto_play_active = auto_play.is_active();
    local max_range = 10.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    local best_target = target_selector_data.closest_unit;

    if target_selector_data.has_elite then
        local unit = target_selector_data.closest_elite;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end        
    end

    if target_selector_data.has_boss then
        local unit = target_selector_data.closest_boss;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end

    if target_selector_data.has_champion then
        local unit = target_selector_data.closest_champion;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end   

    if not best_target then
        return;
    end

    if best_target and best_target:is_enemy()  then
        local glow_target_position = best_target:get_position();
        local glow_target_position_2d = graphics.w2s(glow_target_position);
        graphics.line(glow_target_position_2d, player_screen_position, color_red(180), 2.5)
        graphics.circle_3d(glow_target_position, 0.80, color_red(200), 2.0);
    end

    -- New visualization for Thunderspike target
    if entity_list then
        local closest_thunderspike_target = closest_target(player_position, entity_list, max_range)
        
        if closest_thunderspike_target then
            local thunderspike_target_position = closest_thunderspike_target:get_position();
            local thunderspike_target_position_2d = graphics.w2s(thunderspike_target_position);
            graphics.line(thunderspike_target_position_2d, player_screen_position, color_blue(180), 2.5)
            graphics.circle_3d(thunderspike_target_position, 0.80, color_blue(200), 2.0);
        end
    end

end);

console.print("Lua Plugin - Spiritborn Base - Version 1.0");