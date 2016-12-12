minetest.register_privilege("secret", "Wouldn't you like to know?")
minetest.register_privilege("frozen", {description = "Unable to move.", give_to_singleplayer=false})
minetest.register_privilege("hobbled", {description = "Unable to jump.", give_to_singleplayer=false})
minetest.register_privilege("slowed", {description = "Slow moving.", give_to_singleplayer=false})
minetest.register_privilege("unglitched", {description = "Not very glitchy...", give_to_singleplayer=false})
minetest.register_privilege("caged", {description = "Not going anywhere...", give_to_singleplayer=false})
minetest.register_privilege("hidden_one", {description = "Can hide from players.", give_to_singleplayer=false})



-- Admin Curses

-- prevents player from jumping
local function hobble(name, param)
    -- return if player is admin
    local admin_name  = minetest.setting_get ("name")
    if name == admin_name then
        return
    end
    -- apply curse
    local player = minetest.get_player_by_name(param)
    local privs=minetest.get_player_privs(param)
    privs.hobbled=true
    minetest.set_player_privs(param,privs)
    player:set_physics_override({jump = 0})
end

minetest.register_chatcommand("hobble", {
    params = "<person>",
    privs = {secret=true},
    description = "Prevent player jumping.",
    func = function(name, param)
        local player = minetest.get_player_by_name(param)
        if player == nil then
            minetest.chat_send_player(name,"Player does not exist")
            return
        end
        hobble(name,param)
        minetest.chat_send_player(param, "Cursed by an admin! No more jumping!")
        minetest.chat_send_player(name, "Curse successful!")
    end
})

-- reduces player movement speed
local function slowmo(name, param)
    -- return if player is admin
    local admin_name  = minetest.setting_get ("name")
    if name == admin_name then
        return
    end
    -- apply curse
    local player = minetest.get_player_by_name(param)
    local privs = minetest.get_player_privs(param)
    privs.slowed = true
    minetest.set_player_privs(param,privs)
    player:set_physics_override({speed = 0.3})
end

minetest.register_chatcommand("slowmo", {
    params = "<person>",
    privs = {secret=true},
    description = "Reduce player movement speed.",
    func = function(name, param)
        local player = minetest.get_player_by_name(param)
        if player == nil then
            minetest.chat_send_player(name,"Player does not exist") 
            return
        end
        slowmo(name,param)
        minetest.chat_send_player(param, "Cursed by an admin! You feel sloooooow!")
        minetest.chat_send_player(name, "Curse successful!")
    end
})

-- disable sneak glitch for the player
local function noglitch(name, param)
    -- return if player is admin
    local admin_name  = minetest.setting_get ("name")
    if name == admin_name then
        return
    end
    -- apply curse
    local player = minetest.get_player_by_name(param)
    local privs=minetest.get_player_privs(param)
    privs.unglitched=true
    minetest.set_player_privs(param,privs)
    player:set_physics_override({sneak = false})
end

minetest.register_chatcommand("noglitch", {
    params = "<person>",
    privs = {secret=true},
    description = "Disable sneak glitch for a player.",
    func = function(name, param)
        local player = minetest.get_player_by_name(param)
        if player == nil then
            minetest.chat_send_player(name,"Player does not exist")
            return
        end
        noglitch(name, param)
        minetest.chat_send_player(param, "Cursed by an admin! You feel less glitchy...")
        minetest.chat_send_player(name, "Curse successful!")
    end
})

-- prevent player from changing speed/direction and jumping
local function freeze(name, param)
    -- return if player is admin
    local admin_name  = minetest.setting_get ("name")
    if name == admin_name then
        return
    end
    -- apply curse
    local player = minetest.get_player_by_name(param)
    local privs=minetest.get_player_privs(param)
    privs.frozen=true
    minetest.set_player_privs(param,privs)
    player:set_physics_override({jump = 0, speed = 0})
end

minetest.register_chatcommand("freeze", {
    params = "<person>",
    privs = {secret=true},
    description = "Prevent player movement.",
    func = function(name, param)
        local player = minetest.get_player_by_name(param)
        if player == nil then
            minetest.chat_send_player(name,"Player does not exist")
            return
        end
        freeze(name, param)
        minetest.chat_send_player(param, "Cursed by an admin! You are now frozen!")
        minetest.chat_send_player(name, "Curse successful!")
    end
})

-- trigger curse effects when player joins
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if minetest.get_player_privs(name).hobbled then
        hobble(name,name)
    end
    if minetest.get_player_privs(name).slowed then
        slowmo(name,name)
    end
    if minetest.get_player_privs(name).unglitched then
        noglitch(name,name)
    end
    if minetest.get_player_privs(name).frozen then
        freeze(name,name)
    end
end)

-- reset player physics
minetest.register_chatcommand("setfree",{
    params = "<person>",
    privs = {secret=true},
    description = "Reset player movement.",
    func = function(name, param)
        local player = minetest.get_player_by_name(param)
        if player == nil then 
            minetest.chat_send_player(name,"Player does not exist")
            return
        end
        local privs=minetest.get_player_privs(param)
        privs.frozen=nil
        privs.hobbled=nil
        privs.slowed=nil
        privs.unglitched=nil
        minetest.set_player_privs(param,privs)
        player:set_physics_override({jump = 1, speed = 1, sneak = true})
        minetest.chat_send_player(param, "The curse is lifted. You have been set free!")
        minetest.chat_send_player(name, "The curse is lifted.")
    end,
})



-- Cage Commands

local priv_table = {}

-- save table to file
local function table_save()
    local data = priv_table
    local f, err = io.open(minetest.get_worldpath() .. "/curse_priv_table.txt", "w")
    if err then
        return err
    end
    f:write(minetest.serialize(data))
    f:close()
end

-- read saved file
local function table_read()
    local f, err = io.open(minetest.get_worldpath() .. "/curse_priv_table.txt", "r")
    local data = minetest.deserialize(f:read("*a"))
    f:close()
    return data
end

minetest.after(3.0, function()
    local f, err = io.open(minetest.get_worldpath() .. "/curse_priv_table.txt", "r")
    if err then
        table_save()
    else
        priv_table = table_read()
    end
end)

minetest.register_on_shutdown(function()
    table_save()
end)


-- put a player in the cage
minetest.register_chatcommand("cage", {
    params = "<person>",
    privs = {secret=true},
    description = "Put a player in the cage.",
    func = function(warden_name, target_name)
        -- get target player or return
        local target = minetest.get_player_by_name(target_name)
        if not target then
            minetest.chat_send_player(warden_name,"Player does not exist")
            return
        end
        -- get target player's privs or return
        local privs = minetest.get_player_privs(target_name)
        if privs.caged == true then
            minetest.chat_send_player(warden_name,"This player is already caged")
            return
        end
        -- get cage position from config or return
        local cagepos = minetest.setting_get_pos("cage_coordinate")
        if not cagepos then
            minetest.chat_send_player(warden_name, "No cage set...")
            return
        end
        -- add current target privs to table and save to file
        priv_table[target_name] = privs
        table_save()
        -- remove all privs but shout and add caged and unglitched
        minetest.set_player_privs(target_name,{shout = true, caged = true})
        noglitch(warden_name, target_name)
        -- move target to cage location
        target:setpos(cagepos)
    end
})

-- free a player from the cage
minetest.register_chatcommand("uncage", {
    params = "<person>",
    privs = {secret=true},
    description = "Free a player from the cage.",
    func = function(warden_name, target_name)
        -- get target player or return
        local target = minetest.get_player_by_name(target_name)
        if not target then
            minetest.chat_send_player(warden_name,"Player does not exist")
            return
        end
        -- get target player's privs or return
        local privs = minetest.get_player_privs(target_name)
        if privs.caged ~= true then
            minetest.chat_send_player(warden_name,"This player is not caged")
            return
        end
        -- get release position from config or return
        local releasepos = minetest.setting_get_pos("release_coordinate")
        if not releasepos then
            minetest.chat_send_player(warden_name, "No release point set...")
            return
        end
        -- get target's original privs from table and restore them
        local original_privs = priv_table[target_name]
        minetest.set_player_privs(target_name,original_privs)
        -- remove entry for target from table and save to file
        priv_table[target_name] = nil
        table_save()
        -- restore sneak and move target to release point
        target:set_physics_override({sneak = true})
        target:setpos(releasepos)
    end
})

-- list caged players
minetest.register_chatcommand("list_caged", {
    params = "",
    description = "List all caged players.",
    privs = {server = true},
    func = function (_, _)
        local players = ""
        for player, _ in pairs(priv_table) do
            players = players .. player .. ", "
        end
        return true, "Currently caged players: " .. players
    end
})



-- Other Commands

-- hide player model and nametag (only works in 0.4.14 and above)
vanished_players = {}

minetest.register_chatcommand("vanish", {
    params = "",
    description = "Make user invisible",
    privs = {hidden_one = true},
    func = function(name, param)
        local prop
        local player = minetest.get_player_by_name(name)
        vanished_players[name] = not vanished_players[name]
        if vanished_players[name] then
            prop = {visual_size = {x = 0, y = 0},
            collisionbox = {0,0,0,0,0,0}}
            player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
        else
            -- default player size.
            prop = {visual_size = {x = 1, y = 1},
            collisionbox = {-0.35, -1, -0.35, 0.35, 1, 0.35}}
            player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})
        end
        player:set_properties(prop)
    end
})

-- announcements
minetest.register_chatcommand("proclaim", {
    params = "<text>",
    description = "Sends text to all players",
    privs = {server = true},
    func = function (name, param)
        if not param
        or param == "" then
            return
        end
        minetest.chat_send_all(param)
        if minetest.get_modpath("irc") then 
            if irc.connected and irc.config.send_join_part then
                irc:say(param)
            end
        end
    end
})



local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/bound.lua")