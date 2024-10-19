local my_utility = require("my_utility/my_utility")

local menu_elements_crushing_hand_base =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "crushing_hand_base_main_bool")),
}

local function menu()
    
    if menu_elements_crushing_hand_base.tree_tab:push("Crushing Hand")then
        menu_elements_crushing_hand_base.main_boolean:render("Enable Spell", "")
 
        menu_elements_crushing_hand_base.tree_tab:pop()
    end
end

local spell_id_crushing_hand = 1519050;

local crushing_hand_spell_data = spell_data:new(
    3.0,                        -- radius
    0.1,                        -- range
    0.3,                        -- cast_delay
    0.3,                        -- projectile_speed
    true,                      -- has_collision
    spell_id_crushing_hand,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.targeted    --targeting_type
)
local next_time_allowed_cast = 0.0;

local function is_ravager_active()
    local local_player = get_local_player()
    local buffs = local_player:get_buffs()
   
    for i, buff in ipairs(buffs) do
        if buff.name_hash == 1862773 then
            return true
        end
    end

    return false
end

local function logics(target)
    
    local menu_boolean = menu_elements_crushing_hand_base.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_crushing_hand);

    if not is_logic_allowed then
        return false;
    end;

    local player_position = get_player_position();
    if player_position then
        local target_position = target:get_position();
        
        if target_position then
            local distance = player_position:dist_to_ignore_z(target_position);
            
            -- If ravager active, don't bother walking
            if distance > 5.0 and not is_ravager_active() then
                pathfinder.request_move(target_position);
                return false;
            end

            -- Check for wall collision using the target
            local is_wall_collision = prediction.is_wall_collision(player_position, target_position, 0.15)
            if is_wall_collision then
                return false
            end

            if cast_spell.target(target, crushing_hand_spell_data, false) then
                local current_time = get_time_since_inject();
                next_time_allowed_cast = current_time + 0.1;

                console.print("Casted Crushing Hand");
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