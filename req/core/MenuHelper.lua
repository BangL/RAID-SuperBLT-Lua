
_G.MenuHelper = _G.MenuHelper or {}

function MenuHelper:SetupMenu( menu, id )
	if menu[id] == nil then
		BLT:Log(LogLevel.ERROR, "Could not find '" .. id .. "' in menu!")
		return
	end
	self.menu_to_clone = menu[id]
end

function MenuHelper:SetupMenuButton( menu, id, button_name )
	if menu[id] == nil then
		BLT:Log(LogLevel.ERROR, "Could not find '" .. id .. "' in menu!")
		return
	end

	local button_id
	if button_name then
		for id, item in pairs(menu[id]:items()) do
			if type(item) == "table" and item._parameters and item._parameters.name == button_name then
				button_id = id
			end
		end
	else
		button_id = 1
	end
	self.menubutton_to_clone = menu[id]:items()[button_id]
end

function MenuHelper:NewMenu( menu_id )

	self.menus = self.menus or {}

	local new_menu = deep_clone( self.menu_to_clone )
	new_menu._items = {}
	self.menus[menu_id] = new_menu

	return new_menu

end

function MenuHelper:GetMenu( menu_id )
	local menu = (self.menus or {})[menu_id]
	if menu == nil then
		BLT:Log(LogLevel.ERROR, "Could not find menu with id '" .. tostring(menu_id) .. "'!")
		BLT:Log(LogLevel.ERROR, debug.traceback())
	end
	return menu
end

function MenuHelper:AddBackButton( menu_id )
	local menu = self:GetMenu( menu_id )
	MenuManager:add_back_button( menu )
end

function MenuHelper:AddButton( button_data )

	local data = {
		type = "CoreMenuItem.Item",
	}

	local params = {
		name = button_data.id,
		text_id = button_data.title,
		help_id = button_data.desc,
		callback = button_data.callback,
		back_callback = button_data.back_callback,
		disabled_color = button_data.disabled_color or Color(0.25, 1, 1, 1),
		next_node = button_data.next_node,
		localize = button_data.localized,
		localize_help = button_data.localized,
	}

	local menu = self:GetMenu( button_data.menu_id )
	local item = menu:create_item(data, params)
	item._priority = button_data.priority

	if button_data.disabled then
		item:set_enabled( not button_data.disabled )
	end

	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end

function MenuHelper:AddDivider( divider_data )

	local data = {
		type = "MenuItemDivider",
		size = divider_data.size or 8,
		no_text = divider_data.no_text or true,
	}

	local params = {
		name = divider_data.id,
	}

	local menu = self:GetMenu( divider_data.menu_id )
	local item = menu:create_item( data, params )
	item._priority = divider_data.priority or 0
	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end

function MenuHelper:AddToggle( toggle_data )

	local data = {
		type = "CoreMenuItemToggle.ItemToggle",
		{
			_meta = "option",
			icon = "guis/textures/menu_tickbox",
			value = "on",
			x = 24,
			y = 0,
			w = 24,
			h = 24,
			s_icon = "guis/textures/menu_tickbox",
			s_x = 24,
			s_y = 24,
			s_w = 24,
			s_h = 24
		},
		{
			_meta = "option",
			icon = "guis/textures/menu_tickbox",
			value = "off",
			x = 0,
			y = 0,
			w = 24,
			h = 24,
			s_icon = "guis/textures/menu_tickbox",
			s_x = 0,
			s_y = 24,
			s_w = 24,
			s_h = 24
		}
	}

	local params = {
		name = toggle_data.id,
		text_id = toggle_data.title,
		help_id = toggle_data.desc,
		callback = toggle_data.callback,
		disabled_color = toggle_data.disabled_color or Color( 0.25, 1, 1, 1 ),
		icon_by_text = toggle_data.icon_by_text or false,
		localize = toggle_data.localized,
		localize_help = toggle_data.localized,
	}

	local menu = self:GetMenu( toggle_data.menu_id )
	local item = menu:create_item( data, params )
	item:set_value( toggle_data.value and "on" or "off" )
	item._priority = toggle_data.priority

	if toggle_data.disabled then
		item:set_enabled( not toggle_data.disabled )
	end

	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end

function MenuHelper:AddSlider( slider_data )

	local data = {
		type = "CoreMenuItemSlider.ItemSlider",
		min = slider_data.min or 0,
		max = slider_data.max or 10,
		step = slider_data.step or 1,
		show_value = slider_data.show_value or false
	}

	local params = {
		name = slider_data.id,
		text_id = slider_data.title,
		help_id = slider_data.desc,
		callback = slider_data.callback,
		disabled_color = slider_data.disabled_color or Color( 0.25, 1, 1, 1 ),
		localize = slider_data.localized,
	}

	local menu = self:GetMenu( slider_data.menu_id )
	local item = menu:create_item(data, params)
	item:set_value( math.clamp(slider_data.value, data.min, data.max) or data.min )
	item._priority = slider_data.priority

	if slider_data.disabled then
		item:set_enabled( not slider_data.disabled )
	end

	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end

function MenuHelper:AddMultipleChoice( multi_data )

	local data = {
		type = "MenuItemMultiChoice"
	}
	for k, v in ipairs( multi_data.items or {} ) do
		table.insert( data, { _meta = "option", text_id = v, value = k } )
	end
	
	local params = {
		name = multi_data.id,
		text_id = multi_data.title,
		help_id = multi_data.desc,
		callback = multi_data.callback,
		filter = true,
		localize = multi_data.localized,
		localize_help = multi_data.localized,
	}
	
	local menu = self:GetMenu( multi_data.menu_id )
	local item = menu:create_item(data, params)
	item._priority = multi_data.priority
	item:set_value( multi_data.value or 1 )

	if multi_data.disabled then
		item:set_enabled( not multi_data.disabled )
	end

	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end

function MenuHelper:AddKeybinding( bind_data )

	local data = {
		type = "MenuItemCustomizeController",
	}

	local params = {
		name = bind_data.id,
		text_id = bind_data.title,
		help_id = bind_data.desc,
		connection_name = bind_data.connection_name,
		binding = bind_data.binding,
		button = bind_data.button,
		callback = bind_data.callback,
		localize = bind_data.localized,
		localize_help = bind_data.localized,
		is_custom_keybind = true,
	}

	local menu = self:GetMenu( bind_data.menu_id )
	local item = menu:create_item(data, params)
	item._priority = bind_data.priority

	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end

function MenuHelper:AddInput( input_data )
	local data = {
		type = "MenuItemInput",
	}

	local params = {
		name = input_data.id,
		text_id = input_data.title,
		help_id = input_data.desc,
		callback = input_data.callback,
		disabled_color = input_data.disabled_color or Color( 0.25, 1, 1, 1 ),
		localize = input_data.localized,
		localize_help = input_data.localized,
	}

	local menu = self:GetMenu( input_data.menu_id )
	local item = menu:create_item( data, params )
	item._priority = input_data.priority
	item:set_value( input_data.value or "" )

	menu._items_list = menu._items_list or {}
	table.insert( menu._items_list, item )

	return item

end


function MenuHelper:BuildMenu( menu_id, data )

	-- Check menu exists
	local menu = self.menus[menu_id]
	if menu == nil then
		BLT:Log(LogLevel.ERROR, "Attempting to build menu '" .. menu_id .."' which doesn't exist!")
		return
	end

	-- Check items exist for this menu
	if menu._items_list ~= nil then

		local priority_items = {}
		local nonpriority_items = {}
		for k, v in pairs( menu._items_list ) do
			if v._priority ~= nil then
				table.insert( priority_items, v )
			else
				table.insert( nonpriority_items, v )
			end
		end

		-- Sort table by priority, higher priority first
		table.sort( priority_items, function(a, b)
			return a._priority > b._priority
		end)

		-- Sort non-priority items alphabetically
		table.sort( nonpriority_items, function(a, b)
			return managers.localization:text(a._parameters.text_id or "") < managers.localization:text(b._parameters.text_id or "")
		end)

		-- Add items to menu
		for k, item in pairs( priority_items ) do
			menu:add_item( item )
		end
		for k, item in pairs( nonpriority_items ) do
			menu:add_item( item )
		end

		-- Slider dirty callback fix
		for k, item in pairs( menu._items ) do
			if item._type == "slider" or item._parameters.type == "CoreMenuItemSlider.ItemSlider" then
				item.dirty_callback = nil
			end
		end

		-- Back callback
		if data then

			if data.focus_changed_callback then
				menu._parameters.focus_changed_callback = {
					MenuCallbackHandler[data.focus_changed_callback]
				}
			end
			
			if data.back_callback then

				if not menu._parameters.back_callback then
					menu._parameters.back_callback = {}
				end

				if type(data.back_callback) == "table" then
					for k, v in pairs( data.back_callback ) do

						if type(v) == "string" then
							data.back_callback = MenuCallbackHandler[v]
						end

						table.insert( menu._parameters.back_callback, v )

					end
				else
					
					if type(data.back_callback) == "string" then
						data.back_callback = MenuCallbackHandler[data.back_callback]
					end

					table.insert( menu._parameters.back_callback, data.back_callback )

				end

			end

			if data.area_bg then
				menu._parameters.area_bg = data.area_bg
			end

		end

	end

	-- Add back button to menu
	self:AddBackButton( menu_id )

	-- Build menu data
	menu._parameters.menu_id = menu_id
	self.menus[menu_id] = menu

	return self.menus[menu_id]

end

function MenuHelper:AddMenuItem( parent_menu, child_menu, name, desc, menu_position, subposition )

	if parent_menu == nil then
		BLT:Log(LogLevel.WARN, string.gsub("[Menus][Warning] Parent menu for child '{1}' is null, ignoring...", "{1}", child_menu))
		return
	end

	-- Get menu position from string
	if type( menu_position ) == "string" then
		for k, v in pairs( parent_menu._items ) do
			if menu_position == v["_parameters"]["name"] then

				if subposition == nil then
					subposition = "after"
				end

				if subposition == "after" then
					menu_position = k + 1
				else
					menu_position = k
				end

				break

			end
		end
	end

	-- Put at end of menu, but before the back button
	if menu_position == nil or type(menu_position) == "string" then
		menu_position = #parent_menu._items
	end

	-- Insert in menu
	local button = deep_clone( self.menubutton_to_clone )
	button._parameters.name = child_menu
	button._parameters.text_id = name
	button._parameters.help_id = desc
	button._parameters.next_node = child_menu
	table.insert( parent_menu._items, menu_position, button )

	return button

end

function MenuHelper:LoadFromJsonFile( file_path, parent_class, data_table )

	local file = io.open( file_path, "r" )
	if file then

		local file_content = file:read("*all")
		file:close()

		local content = json.decode( file_content )
		local menu_id = content.menu_id
		local parent_menu = content.parent_menu_id
		local menu_name = content.title
		local menu_desc = content.description
		local items = content.items
		local focus_changed_callback = content.focus_changed_callback
		local back_callback = content.back_callback
		local menu_priority = content.priority or nil
		local area_bg = content.area_bg

		Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupCustomMenus_Json_" .. menu_id, function( menu_manager, nodes )
			MenuHelper:NewMenu( menu_id )
		end)

		Hooks:Add("MenuManagerBuildCustomMenus", "Base_BuildCustomMenus_Json_" .. menu_id, function( menu_manager, nodes )

			local data = {
				focus_changed_callback = focus_changed_callback,
				back_callback = back_callback,
				area_bg = area_bg,
			}
			nodes[menu_id] = MenuHelper:BuildMenu( menu_id, data )

			if menu_priority ~= nil then
				for k, v in pairs( nodes[parent_menu]._items ) do
					if menu_priority > (v._priority or 0) then
						menu_priority = k
						break
					end
				end
			end

			MenuHelper:AddMenuItem( nodes[parent_menu], menu_id, menu_name, menu_desc, menu_priority )

		end)

		Hooks:Add("MenuManagerPopulateCustomMenus", "Base_PopulateCustomMenus_Json_" .. menu_id, function( menu_manager, nodes )

			for k, item in pairs( items ) do

				local type = item.type
				local id = item.id
				local title = item.title
				local desc = item.description
				local callback = item.callback
				local priority = item.priority or #items - k
				local value = item.default_value
				local localized = item.localized
				if data_table and data_table[item.value] ~= nil then
					value = data_table[item.value]
				end

				if type == "button" then
					MenuHelper:AddButton({
						id = id,
						title = title,
						desc = desc,
						callback = callback,
						next_node = item.next_menu or nil,
						menu_id = menu_id,
						priority = priority,
						localized = localized,
					})
				end

				if type == "toggle" then
					MenuHelper:AddToggle({
						id = id,
						title = title,
						desc = desc,
						callback = callback,
						value = value,
						menu_id = menu_id,
						priority = priority,
						localized = localized,
					})
				end

				if type == "slider" then
					MenuHelper:AddSlider({
						id = id,
						title = title,
						desc = desc,
						callback = callback,
						value = value,
						min = item.min or 0,
						max = item.max or 1,
						step = item.step or 0.1,
						show_value = true,
						menu_id = menu_id,
						priority = priority,
						localized = localized,
					})
				end

				if type == "divider" then
					MenuHelper:AddDivider({
						id = "divider_" .. menu_id .. "_" .. tostring(priority),
						size = item.size,
						menu_id = menu_id,
						priority = priority,
					})
				end

				if type == "keybind" then

					local key = ""
					if item.keybind_id then
						local mod = BLT.Mods:GetModOwnerOfFile( file_path )
						if mod then
							local params = {
								id = item.keybind_id,
								allow_menu = item.run_in_menu,
								allow_game = item.run_in_game,
								show_in_menu = item.show_in_menu,
								name = title,
								desc = desc,
								localize = true,
								callback = item.func and MenuCallbackHandler[item.func],
							}
							BLT.Keybinds:register_keybind( mod, params )
						end

						local bind = BLT.Keybinds:get_keybind( item.keybind_id )
						key = bind and bind:Key() or ""
					end

					MenuHelper:AddKeybinding({
						id = id,
						title = title,
						desc = desc,
						connection_name = item.keybind_id,
						button = key,
						binding = key,
						menu_id = menu_id,
						priority = priority,
						localized = localized,
					})

				end

				if type == "multiple_choice" then
					MenuHelper:AddMultipleChoice({
						id = id,
						title = title,
						desc = desc,
						callback = callback,
						items = item.items,
						value = value,
						menu_id = menu_id,
						priority = priority,
						localized = localized,
					})
				end

				if type == "input" then
					MenuHelper:AddInput({
						id = id,
						title = title,
						desc = desc,
						callback = callback,
						value = value,
						menu_id = menu_id,
						priority = priority,
						localized = localized,
					})
				end
 
			end

		end)

	else
		BLT:Log(LogLevel.ERROR, "Could not load file: " .. file_path)
	end

end

function MenuHelper:ResetItemsToDefaultValue( item, items_table, value )

	if type(items_table) ~= "table" then
		local s = tostring(items_table)
		items_table = {}
		items_table[s] = true
	end

	local node_items = item._parameters.gui_node.row_items
	for k, v in pairs( node_items ) do

		if items_table[v.item._parameters.name] and v.item.set_value then

			local item_type = v.item._type

			if item_type == "toggle" then
				v.item:set_value( value and "on" or "off" )
			else
				v.item:set_value( value )
			end

			for x, y in pairs( v.item._parameters.callback ) do
				y(v.item)
			end

		end

	end

	managers.viewport:resolution_changed()

end

--[[
	Registers a new BLTCustomComponent

	Please note you still need to set up your component in BLTMenuNodes

	This does the following:
	- adds a method named name_gui to MenuComponentManager
	- adds a method named create_name_gui to MenuComponentManager
	- adds a method named close_name_gui to MenuComponentManager
	- Sets up managers.component._active_components to refer to the create and close functions

	In other words, calling AddComponent("mycmp", MyCmp) will result in:

	function MenuComponentManager:mycmp_gui()
		return self._mycmp
	end

	function MenuComponentManager:create_mycmp_gui(node)
		if not node then
			return
		end
		self._mycmp = self._mycmp or MyCmp:new(self._ws, self._fullscreen_ws, node)
		self:register_component("mycmp_gui", self._mycmp)
	end

	function MenuComponentManager:close_mycmp_gui()
		if self._mycmp then
			self._mycmp:close()
			self._mycmp = nil
			self:unregister_component("mycmp_gui")
		end
	end
]]
function MenuHelper:AddComponent(name, clss)
	local function add(component)
		local c_name = name.."_gui"
		local u_name = "_"..name
		local create = "create_"..c_name
		local close = "close_"..c_name

		-- function MenuComponentManager:name_gui()
		MenuComponentManager[c_name] = function(self)
			return self[u_name]
		end

		-- function MenuComponentManager:create_name_gui()
		MenuComponentManager[create] = function(self, node)
			if not node then
				return
			end
			self[u_name] = self[u_name] or clss:new(self._ws, self._fullscreen_ws, node)
			self:register_component(c_name, self[u_name])
		end

		-- function MenuComponentManager:close_name_gui()
		MenuComponentManager[close] = function(self)
			if self[u_name] then
				self[u_name]:close()
				self[u_name] = nil
				self:unregister_component(c_name)
			end
		end

		-- Make the component available
		component._active_components[name] = {
			create = callback(component, component, create),
			close = callback(component, component, close)
		}
	end

	-- If the component manager is already loaded then set everything up now,
	-- otherwise set it up as it's loaded
	if managers.component then
		add(managers.component)
	else
		Hooks:Add("MenuComponentManagerInitialize", name..".MenuComponentManagerInitialize", add)
	end
end