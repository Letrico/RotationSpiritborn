local my_utility = require("my_utility/my_utility")

local menu_elements_withering_fist_base =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "withering_fist_main_bool_base")),
}

local function menu()
    
    if menu_elements_withering_fist_base.tree_tab:push("Withering Fist")then
        menu_elements_withering_fist_base.main_boolean:render("Enable Spell", "")
 
        menu_elements_withering_fist_base.tree_tab:pop()
    end
end

local spell_id_withering_fist = 1834476;

local spell_data_withering_fist = spell_data:new(
    0.2,                        -- radius
    0.2,                        -- range
    0.4,                        -- cast_delay
    0.3,                        -- projectile_speed
    true,                           -- has_collision
    spell_id_withering_fist,           -- spell_id
    spell_geometry.rectangular,          -- geometry_type
    targeting_type.targeted    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements_withering_fist_base.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_withering_fist);

    if not is_logic_allowed then
        return false;
    end;

    local player_local = get_local_player();
    
    local player_position = get_player_position();
    local target_position = target:get_position();

    if cast_spell.target(target, spell_data_withering_fist, false) then

        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.2;

        console.print("Casted Withering Fist");
        return true;
    end;
            
    return false;
end


return 
{
    menu = menu,
    logics = logics,   
}