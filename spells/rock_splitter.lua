local my_utility = require("my_utility/my_utility")

local menu_elements_rock_splitter_base =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "rock_splitter_main_bool_base")),
    use_as_filler_only  = checkbox:new(true, get_hash(my_utility.plugin_label .. "rock_splitter_use_as_filler_only")),
}

local function menu()
    if menu_elements_rock_splitter_base.tree_tab:push("Rock Splitter")then
        menu_elements_rock_splitter_base.main_boolean:render("Enable Spell", "")

        if menu_elements_rock_splitter_base.main_boolean:get() then
            menu_elements_rock_splitter_base.use_as_filler_only:render("Filler Only", "Prevent casting with a lot of spirit")
        end

        menu_elements_rock_splitter_base.tree_tab:pop()
    end
end

local spell_id_rock_splitter = 1817045;

local spell_data_rock_splitter = spell_data:new(
    0.2,                        -- radius
    0.2,                        -- range
    0.4,                        -- cast_delay
    0.3,                        -- projectile_speed
    true,                           -- has_collision
    spell_id_rock_splitter,           -- spell_id
    spell_geometry.rectangular,          -- geometry_type
    targeting_type.targeted    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements_rock_splitter_base.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_rock_splitter);

    if not is_logic_allowed then
        return false;
    end;

    local player_local = get_local_player();
    
    local is_filler_enabled = menu_elements_rock_splitter_base.use_as_filler_only:get();  
    if is_filler_enabled then
        local current_resource_ws = player_local:get_primary_resource_current();
        local max_resource_ws = player_local:get_primary_resource_max();
        local spirit_perc = current_resource_ws / max_resource_ws 
        local low_in_spirit = spirit_perc < 0.4
    
        if not low_in_spirit then
            return false;
        end
    end;

    local player_position = get_player_position();
    if player_position then
        local target_position = target:get_position();
        
        if target_position then
            local distance = player_position:dist_to_ignore_z(target_position);
            
            if distance > 1.5 then
                pathfinder.request_move(target_position);
                return false;
            end

            if cast_spell.target(target, spell_data_rock_splitter, false) then
                local current_time = get_time_since_inject();
                next_time_allowed_cast = current_time + 0.2;

                console.print("Casted Rock Splitter");
                return true;
            end
        end
    end
            
    return false;
end


return 
{
    menu = menu,
    logics = logics,   
}