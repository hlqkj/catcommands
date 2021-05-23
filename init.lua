minetest.register_privilege("secret", "Wouldn't you like to know?")
minetest.register_privilege("hidden_one", {description = "Can hide from players.", give_to_singleplayer=false})

local default_sneak_mode = "old" -- change this to "new" if you want new movement.

-- Admin Curses

-- prevents player from jumping
local function hobble(user, target)
	local player = minetest.get_player_by_name(target)
	player:set_attribute("hobbled", "true")
	player:set_physics_override({jump = 0})
end

minetest.register_chatcommand("hobble", {
	params = "<person>",
	privs = {secret=true},
	description = "Prevent player jumping.",
	func = function(name, target)
		local player = minetest.get_player_by_name(target)
		if player == nil then
			return false, "Player does not exist."
		end
		hobble(name, target)
		minetest.chat_send_player(target, "Cursed by an admin! No more jumping!")
		minetest.chat_send_player(name, "Curse successful!")
	end
})

-- reduces player movement speed
local default_slow = 0.3

local function slowmo(name, target, speed)
	local player = minetest.get_player_by_name(target)
	player:set_attribute("slowed", speed)
	player:set_physics_override({speed = speed})
end

minetest.register_chatcommand("slowmo", {
	params = "<person> <speed>",
	privs = {secret = true},
	description = "Reduce player movement speed.",

	func = function(name, params)
		local target, speed = params:match("^(%S+)%s*([%d.]*)$")
		if target == nil or target == "" then
			return false, "You must enter a player name, optionally followed by speed."
		end

		local player = minetest.get_player_by_name(target)
		if player == nil then
			return false, "Player does not exist."
		end

		if speed == nil or speed == "" or
				tonumber(speed) > 1.0 or tonumber(speed) < 0.1 then
			speed = default_slow
		end

		slowmo(name, target, speed)
		minetest.chat_send_player(target, "Cursed by an admin! You feel sloooooow! " ..
			"(Speed set to ".. speed ..")")
		minetest.chat_send_player(name, "Curse successful! "..target.."'s speed set to "..speed)
	end
})

-- prevent player from changing speed/direction and jumping
local function freeze(name, target)
	local player = minetest.get_player_by_name(target)
	player:set_attribute("frozen", "true")
	player:set_physics_override({jump = 0, speed = 0})
end

minetest.register_chatcommand("freeze", {
	params = "<person>",
	privs = {secret=true},
	description = "Prevent player movement.",
	func = function(name, target)
		local player = minetest.get_player_by_name(target)
		if player == nil then
			return false, "Player does not exist."
		end
		freeze(name, target)
		minetest.chat_send_player(target, "Cursed by an admin! You are now frozen!")
		minetest.chat_send_player(name, "Curse successful!")
	end
})

-- disables minimap for player
local function getlost(name,target)
	local player = minetest.get_player_by_name(target)
	player:set_attribute("lost", "true")
	player:hud_set_flags({minimap = false})
end

minetest.register_chatcommand("getlost", {
	params = "<person>",
	privs = {secret=true},
	description = "Prevent player from using the minimap.",
	func = function(name, target)
		local player = minetest.get_player_by_name(target)
		if player == nil then
			return false, "Player does not exist."
		end
		getlost(name,target)
		minetest.chat_send_player(target, "Cursed by an admin! You will get lost now!")
		minetest.chat_send_player(name, "Curse successful!")
	end
})

-- lower light levels for player
local function blind(name,target)
	local player = minetest.get_player_by_name(target)
	player:set_attribute("blind", "true")
	player:override_day_night_ratio(0.05)
end

minetest.register_chatcommand("blind", {
	params = "<person>",
	privs = {secret=true},
	description = "Place player in eternal night time.",
	func = function(name, target)
		local player = minetest.get_player_by_name(target)
		if player == nil then
			return false, "Player does not exist."
		end
		blind(name,target)
		minetest.chat_send_player(target, "Cursed by an admin! Eternal night time!")
		minetest.chat_send_player(name, "Curse successful!")
	end
})


-- trigger curse effects when player joins
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if player:get_attribute("hobbled") == "true" then
		hobble(name,name)
	end
	local slowed = player:get_attribute("slowed")
	if slowed then
		slowmo(name,name, tonumber(slowed))
	end
	if player:get_attribute("frozen") == "true" then
		freeze(name,name)
	end
	if player:get_attribute("lost") == "true" then
		getlost(name,name)
	end
	if player:get_attribute("blind") == "true" then
		blind(name,name)
	end
	-- set sneak mode if unassigned
	if player:get_attribute("sneak_mode") == nil then
		player:set_attribute("sneak_mode", default_sneak_mode)
	end
	-- set movement physics based on sneak_mode
	if player:get_attribute("sneak_mode") == "old" then
		player:set_physics_override({new_move = false, sneak_glitch = true, sneak = true})
	elseif player:get_attribute("sneak_mode") == "new" then
		player:set_physics_override({new_move = true, sneak_glitch = false, sneak = true})
	elseif player:get_attribute("sneak_mode") == "none" then
		player:set_physics_override({sneak = false})
	end
end)

-- reset player physics
minetest.register_chatcommand("setfree",{
	params = "<person>",
	privs = {secret=true},
	description = "Reset player movement.",
	func = function(name, target)
		local player = minetest.get_player_by_name(target)
		if player == nil then
			return false, "Player does not exist."
		end
		player:set_attribute("hobbled", "")
		player:set_attribute("slowed", "")
		player:set_attribute("frozen", "")
		player:set_attribute("lost", "")
		player:set_attribute("blind", "")
		player:set_physics_override({jump = 1, speed = 1, sneak = true})
		player:hud_set_flags({minimap = true})
		player:override_day_night_ratio(nil)
		minetest.chat_send_player(target, "The curse is lifted. You have been set free!")
		minetest.chat_send_player(name, "The curse is lifted.")
	end
})

-- set sneak mode
local function sneak_mode(player, mode)
	player:set_attribute("sneak_mode", mode)
	if mode == "old" then
		player:set_physics_override({new_move = false, sneak_glitch = true, sneak = true})
	elseif mode == "new" then
		player:set_physics_override({new_move = true, sneak_glitch = false, sneak = true})
	elseif mode == "none" then
		player:set_physics_override({sneak = false})
	end
end

minetest.register_chatcommand("set_sneak",{
	params = "<player> <old | new | none>",
	privs = {secret = true},
	description = "Set sneak mode for player.",
	func = function(name, params)
		local target, mode = params:match("(%S+)%s+(.+)")
		if not target and not reason then
			return false, "Must include player name and sneak mode."
		end
		local player = minetest.get_player_by_name(target)
		if not player then
			return false, "Player does not exist."
		end
		if not mode or (mode ~= "old" and mode ~= "new" and mode ~= "none") then
			return false, "Set a mode: old, new or none."
		end
		sneak_mode(player, mode)
	end
})


-- check player status
minetest.register_chatcommand("curses",{
	params = "<person>",
	privs = {secret = true},
	description = "Check player status.",
	func = function(user_name, target_name)
		local player = minetest.get_player_by_name(target_name)
		if player == nil then
			return false, "Player does not exist or is not logged in."
		end
		local result = "Status for player "..target_name..": "
		local status_list = {"hobbled", "slowed", "frozen", "lost", "blind", "caged"}
		for i, status in ipairs(status_list) do
			if player:get_attribute(status_list[i]) == "true" then
				result = result..status_list[i].." "
			end
		end
		if player:get_attribute("slowed") and player:get_attribute("slowed") ~= "" then
			result = result.."slowed("..player:get_attribute("slowed")..")"
		end
		minetest.chat_send_player(user_name, result.." Sneak mode: "..player:get_attribute("sneak_mode"))
		return
	end
})


-- Cage Commands

-- put a player in the cage
minetest.register_chatcommand("cage", {
	params = "<person>",
	privs = {secret=true},
	description = "Put a player in the cage.",
	func = function(warden_name, target_name)
		-- prevent self-caging
		if warden_name == target_name then
			return false, "You can't cage yourself."
		end
		-- get target player or return
		local target = minetest.get_player_by_name(target_name)
		if not target then
			return false, "Player does not exist."
		end
		-- return if already caged
		if target:get_attribute("caged") == "true" then
			return false, "This player is already caged."
		end
		-- get cage position from config or return
		local cagepos = minetest.setting_get_pos("cage_coordinate")
		if not cagepos then
			return false, "No cage set..."
		end
		-- save then remove all privs other than shout
		local target_privs = minetest.privs_to_string(minetest.get_player_privs(target_name))
		target:set_attribute("caged_privs", target_privs)
		minetest.chat_send_player(warden_name, target:get_attribute("caged_privs"))
		minetest.set_player_privs(target_name,{shout = true})
		target:set_attribute("caged", "true")
		sneak_mode(target, "none")
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
			return false, "Player does not exist."
		end
		-- return if not caged
		if target:get_attribute("caged") ~= "true" then
			return false, "This player is not caged."
		end
		-- get release position from config or return
		local releasepos = minetest.setting_get_pos("release_coordinate")
		if not releasepos then
			return false, "No release point set..."
		end
		-- restore privs and release
		local original_privs = minetest.string_to_privs(target:get_attribute("caged_privs"))
		minetest.set_player_privs(target_name, original_privs)
		target:set_attribute("caged_privs", nil)
		sneak_mode(target, default_sneak_mode)
		target:set_attribute("caged", "")
		target:setpos(releasepos)
	end
})



-- Other Commands

-- hide player model and nametag (only works in 0.4.14 and above)
vanished_players = {}

-- 5.x update: backwards compat with 0.4.x
local selectionbox = 'selectionbox'
if not minetest.features.object_independent_selectionbox then
    selectionbox = 'collisionbox'
end

minetest.register_chatcommand("vanish", {
	params = "",
	description = "Make user invisible",
	privs = {hidden_one = true},
	func = function(user)
		local player = minetest.get_player_by_name(user)

		if vanished_players[user] then
			-- player is vanished, unvanish

			-- use defaults if for some reason data is not there
			local props = vanished_players[user][1] or {
				visual_size    = { x = 1, y = 1 },
				[selectionbox] = { -0.35, 0.00, -0.35, 0.35, 1.00, 0.35 }
			}

			local ntatts = vanished_players[user][2] or {
				text  = user,
				color = { r = 255, g = 255, b = 255, a = 255 }
			}

			vanished_players[user] = nil

			player:set_properties(props)
			player:set_nametag_attributes(ntatts)

		else
			-- player is unvanished, vanish

			-- preserve properties
			vanished_players[user] = {
				player:get_properties(),
				player:get_nametag_attributes()
			}

			-- vanish
			player:set_properties({
				visual_size    = { x = 0, y = 0, z = 0 },
				[selectionbox] = { 0, 0, 0, 0, 0, 0 }
			})

			player:set_nametag_attributes({
				text = " ",
				color = 0
			})
		end
	end
})

-- announcements
minetest.register_chatcommand("proclaim", {
	params = "<text>",
	description = "Sends text to all players",
	privs = {server = true},
	func = function (user, text)
		if not text
		or text == "" then
			return
		end
		minetest.chat_send_all(text)
		if minetest.get_modpath("irc") then
			if irc.connected and irc.config.send_join_part then
				irc:say(text)
			end
		end
	end
})

