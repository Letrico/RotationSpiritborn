local my_utility = require("my_utility/my_utility")

local menu_elements_rushing_claw =
{
    tree_tab                = tree_node:new(1),
    main_boolean            = checkbox:new(true, get_hash(my_utility.plugin_label .. "_rushing_claw_main_boolean")),
}

local function menu()
    if menu_elements_rushing_claw.tree_tab:push("Rushing Claw")then
        menu_elements_rushing_claw.main_boolean:render("Enable Spell", "")
  
        menu_elements_rushing_claw.tree_tab:pop()
     end
end

local spell_id_rushing_claw = 1871761;
local next_time_allowed_cast = 0.0;
local rushing_claw_data = spell_data:new(
    0.5,                                -- radius
    4.0,                                -- range
    0.8,                                -- cast_delay
    1.5,                                -- projectile_speed
    false,                              -- has_collision
    spell_id_rushing_claw,              -- spell_id
    spell_geometry.rectangular,         -- geometry_type
    targeting_type.targeted             -- targeting_type
)

local function logics(target)
    local menu_boolean = menu_elements_rushing_claw.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_rushing_claw);

    if not is_logic_allowed then
        return false;
    end;

    if not target then
        return false;
    end

    local target_position = target:get_position();
    if not target_position then
        return false;
    end

    if cast_spell.target(target, rushing_claw_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 1.5;
        
        console.print("Casted Rushing Claw");
        return true;
    end

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}