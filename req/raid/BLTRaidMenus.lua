BLTOptionsMenu = BLTOptionsMenu or blt_class(RaidMenuLeftOptions)

function BLTOptionsMenu:init(ws, fullscreen_ws, node, component_name)
	BLTOptionsMenu.super.init(self, ws, fullscreen_ws, node, component_name)
	self.list_menu_options:show()
end

function BLTOptionsMenu:_set_initial_data()
	self._node.components.raid_menu_header:set_screen_name("menu_header_options_main_screen_name", "blt_options_menu_lua_mod_options")
end

function BLTOptionsMenu:_layout()
	BLTOptionsMenu.super._layout(self)
	self:_layout_list_menu()
	self:bind_controller_inputs()
end

function BLTOptionsMenu:close()
	BLTOptionsMenu.super.close(self)
	MenuCallbackHandler:perform_blt_save()
end

function BLTOptionsMenu:_layout_list_menu()
	-- fixed-height viewport above the back button, scrolls when there are too many mods
	-- full width, so the scrollbar sits at the right screen edge
	self._list_scrollable_area = self._root_panel:scrollable_area({
		name = "blt_options_menu_list_scrollable_area",
		h = 724,
		w = self._root_panel:w(),
		y = 144,
		x = 0,
		scroll_step = 33,
		scrollbar_width = 8,
	})
	local list_menu_options_params = {
		w = 480 - RaidGUIControlScrollableArea.SCROLLBAR_WIDTH,
		name = "blt_options_menu_list",
		selection_enabled = true,
		vertical_spacing = 2,
		loop_items = true,
		on_item_clicked_callback = callback(self, self, "_on_list_menu_options_item_selected"),
		data_source_callback = callback(self, self, "_list_menu_options_data_source"),
		item_class = RaidGUIControlListItemMenu,
		scrollable_area_ref = self._list_scrollable_area,
		blt_can_sort_list = true
	}
	self.list_menu_options = self._list_scrollable_area:get_panel():create_custom_control(RaidGUIControlSingleSelectList, list_menu_options_params)
	-- mod menus get injected after creation, so re-fit the scroll area whenever the items are rebuilt
	local area = self._list_scrollable_area
	local orig_create_items = self.list_menu_options._create_items
	self.list_menu_options._create_items = function(list, ...)
		orig_create_items(list, ...)
		area:setup_scroll_area()
	end
	area:setup_scroll_area()
	self.list_menu_options:set_selected(true)
end

-- the list lives inside a scroll area now, so the menu component manager does not find it for input
for _, func in ipairs({"move_up", "move_down", "confirm_pressed"}) do
	BLTOptionsMenu[func] = function(self, ...)
		return self.list_menu_options[func](self.list_menu_options, ...)
	end
end

function BLTOptionsMenu:_list_menu_options_data_source()
	return {} -- filled by RaidMenuHelper:CreateMenu injection
end

BLTKeybindsMenu = BLTKeybindsMenu or blt_class(BLTMenu)
function BLTKeybindsMenu:Init(root)
	self:Title({text = "menu_header_options_main_screen_name"})
	self:SubTitle({text = "blt_options_menu_keybinds"})
	self:EnableScrolling() -- header stays fixed, everything below scrolls
	local last_mod
	self:AutoBindNamedControlsBegin()
	for i, bind in ipairs(BLT.Keybinds:keybinds()) do
		if bind:IsActive() and bind:ShowInMenu() then
			-- Separate keybinds by mod
			if last_mod ~= bind:ParentMod() then
				self:Label({text = bind:ParentMod():GetName(), localize = false, y_offset = 16})
			end
			self:KeyBind({
				name = bind:Id(),
				text = bind:Name(),
				keybind_id = bind:Id(),
				x_offset = 10,
				localize = false,
				desc = bind:Description(),
				localize_desc = false,
				auto_select_on_hover = true,
			})

			last_mod = bind:ParentMod()
		end
	end
	self:AutoBindNamedControlsEnd()
end

function BLTKeybindsMenu:on_escape()
	MenuCallbackHandler:perform_blt_save()
end

Hooks:Add("MenuComponentManagerInitialize", "BLT.MenuComponentManagerInitialize", function()
	RaidMenuHelper:CreateMenu({
		name = "blt_mods",
		name_id = "blt_options_menu_blt_mods",
		class = BLTModsGui,
		inject_list = "raid_menu_left_options",
		inject_after = "network",
		icon = "menu_item_cards"
	})

	RaidMenuHelper:CreateMenu({
		name = "blt_keybinds",
		name_id = "blt_options_menu_keybinds",
		class = BLTKeybindsMenu,
		inject_list = "raid_menu_left_options",
		inject_after = "network",
		icon = "menu_item_controls"
	})

	RaidMenuHelper:CreateMenu({
		name = "blt_options",
		name_id = "blt_options_menu_lua_mod_options",
		class = BLTOptionsMenu,
		inject_list = "raid_menu_left_options",
		inject_after = "network",
		icon = "menu_item_options"
	})

	RaidMenuHelper:CreateMenu({
		name = "blt_download_manager",
		name_id = "blt_download_manager",
		class = BLTDownloadManagerGui,
	})
end)