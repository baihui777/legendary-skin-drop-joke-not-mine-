


function IngameLobbyMenuState:update(t, dt)
	if self._is_generating_skirmish_lootdrop and managers.skirmish:has_finished_generating_additional_rewards() then
		self._is_generating_skirmish_lootdrop = nil
		local lootdrops = managers.skirmish:get_generated_lootdrops()
		local lootdrop_data = {
			peer = managers.network:session() and managers.network:session():local_peer(),
			items = lootdrops.items or {},
			coins = lootdrops.coins or 0
		}

		if self._inventory_reward then
			table.insert(lootdrop_data.items, 1, self._inventory_reward)

			self._inventory_reward = nil
		end

		managers.hud:make_lootdrop_hud(lootdrop_data)

		if not Global.game_settings.single_player and managers.network:session() then
			
			local legendary_skin_list = {}
			for k, v in pairs(tweak_data.blackmarket.weapon_skins or {}) do
				if v.rarity and v.rarity == "legendary" then
					table.insert(legendary_skin_list, tostring(k))
				end
			end

			local fake_lootdrop_string = ""
			local fake_lootdrop_string = fake_lootdrop_string .. tostring(lootdrops.coins or 0)
			local global_index = nil
			local global_values = tweak_data.lootdrop.global_value_list_map
			
			for i = 1, #lootdrops.items do
				local rnd = math.random(#legendary_skin_list)
				local fake_item_id = legendary_skin_list[rnd]
				local fake_item_category = "weapon_skins"
				local fake_global_value = managers.blackmarket:get_global_value(fake_item_category, fake_item_id)
				local fake_global_index = global_values[fake_global_value] or 1
				fake_lootdrop_string = fake_lootdrop_string .. " " .. tostring(fake_global_index) .. "-" .. tostring(fake_item_category) .. "-" .. tostring(fake_item_id)
			end
			
			managers.network:session():send_to_peers("feed_lootdrop_skirmish", fake_lootdrop_string)
		end
	end
end


function IngameLobbyMenuState:set_lootdrop(drop_category, drop_item_id, ...)
	if managers.skirmish:is_skirmish() then
		self:set_lootdrop_skirmish(drop_category, drop_item_id)

		return
	end
	
	local global_value, item_category, item_id, max_pc, item_pc = nil
	local allow_loot_drop = true
	allow_loot_drop = not managers.crime_spree:is_active()
	
	if drop_item_id and drop_category then
		global_value = managers.blackmarket:get_global_value(drop_category, drop_item_id)
		item_category = drop_category
		item_id = drop_item_id
		max_pc = math.max(math.ceil(managers.experience:current_level() / 10), 1)
		item_pc = math.ceil(4)
	elseif allow_loot_drop then
		self._lootdrop_data = {}

		managers.lootdrop:new_make_drop(self._lootdrop_data)

		global_value = self._lootdrop_data.global_value or "normal"
		item_category = self._lootdrop_data.type_items
		item_id = self._lootdrop_data.item_entry
		max_pc = self._lootdrop_data.total_stars
		item_pc = self._lootdrop_data.joker and 0 or math.ceil(self._lootdrop_data.item_payclass / 10)
	end

	local peer = managers.network:session() and managers.network:session():local_peer() or false
	local disable_weapon_mods = not managers.lootdrop:can_drop_weapon_mods() and true or nil
	local card_left_pc = managers.lootdrop:new_fake_loot_pc(nil, {
		weapon_mods = disable_weapon_mods
	})
	local card_right_pc = managers.lootdrop:new_fake_loot_pc(nil, {
		weapon_mods = disable_weapon_mods
	})
	local lootdrop_data = {
		peer,
		global_value,
		item_category,
		item_id,
		max_pc,
		item_pc,
		card_left_pc,
		card_right_pc
	}

	managers.hud:make_lootdrop_hud(lootdrop_data)

	if not Global.game_settings.single_player and managers.network:session() then
		
		local global_values = tweak_data.lootdrop.global_value_list_map
		
		local legendary_skin_list = {}
		for k, v in pairs(tweak_data.blackmarket.weapon_skins or {}) do
			if v.rarity and v.rarity == "legendary" then
				table.insert(legendary_skin_list, tostring(k))
			end
		end
		
		local rnd = math.random(#legendary_skin_list)
		local fake_item_id = legendary_skin_list[rnd]
		local fake_item_category = "weapon_skins"
		
		local fake_global_value = managers.blackmarket:get_global_value(fake_item_category, fake_item_id)
		
		local fake_global_index = global_values[fake_global_value] or 1

		managers.network:session():send_to_peers("feed_lootdrop", fake_global_index, fake_item_category, fake_item_id, max_pc, item_pc, card_left_pc, card_right_pc)
	end
end