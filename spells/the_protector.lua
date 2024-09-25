local my_utility = require("my_utility/my_utility")

local menu_elements_the_protector = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_the_protector_base")),
    min_max_targets       = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_max_number_of_targets_for_cast_the_protector_base"))
}

local function menu()
    
    if menu_elements_the_protector.tree_tab:push("The Protector") then
        menu_elements_the_protector.main_boolean:render("Enable Spell", "")

        if menu_elements_the_protector.main_boolean:get() then
            menu_elements_the_protector.min_max_targets:render("Min Enemies Around", "Amount of targets to cast the spell")
        end

        menu_elements_the_protector.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local spell_id_the_protector = 1663208;
local function logics()

    local menu_boolean = menu_elements_the_protector.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_the_protector);

    if not is_logic_allowed then
    return false;
    end;
    
    local player_pos = get_player_position()
    local area_data = target_selector.get_most_hits_target_circular_area_light(player_pos, 5.0, 5.0, false)
    local units = area_data.n_hits

    if units < menu_elements_the_protector.min_max_targets:get() then
        return false;
    end;

    if cast_spell.self(spell_id_the_protector, 0.0) then
        
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.1;
        return true;
    end;


    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}