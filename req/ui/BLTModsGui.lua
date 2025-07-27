BLT:Require("req/ui/BLTUIControls")
BLT:Require("req/raid/BLTGUIControlListItemMod")

---@class BLTModsGui
---@field new fun(self, ws, fullscreen_ws, node):BLTModsGui
---@field translate fun(self, string, upper_case)
---@field set_legend fun(self, legend)
---@field set_controller_bindings fun(self, bindings, clear_old)
---@field super table
---@field _node table
---@field _root_panel table
BLTModsGui = BLTModsGui or blt_class(RaidGuiBase)
BLTModsGui.BACKGROUND_PAPER_COLOR = Color("cccccc")
BLTModsGui.BACKGROUND_PAPER_ALPHA = 0.7
BLTModsGui.BACKGROUND_PAPER_ROTATION = 5
BLTModsGui.BACKGROUND_PAPER_SCALE = 0.9
BLTModsGui.FOREGROUND_PAPER_COLOR = Color("ffffff")
BLTModsGui.SECONDARY_PAPER_PADDING_LEFT = -4
BLTModsGui.COLUMN_MODS = 1
BLTModsGui.COLUMN_INFO = 2
BLTModsGui.TABS_REGULAR_MODS = "regular_mods"
BLTModsGui.TABS_CORE_MODS = "core_mods"

BLTModsGui.FALLBACK_GUI_ICON = "ico_flag_empty"

local padding = 10
local paper_image = "menu_paper"
local soe_emblem_image = "icon_paper_stamp"

function BLTModsGui:init(ws, fullscreen_ws, node)
	self._selected_column = BLTModsGui.COLUMN_MODS
	self._selected_tab = BLTModsGui.TABS_REGULAR_MODS

	BLTModsGui.super.init(self, ws, fullscreen_ws, node, "blt_mods")
	self._root_panel.ctrls = self._root_panel.ctrls or {}

	self._controller_list = {}
	for index = 1, managers.controller:get_wrapper_count() do
		local con = managers.controller:create_controller("boot_" .. index, index, false)
		con:enable()
		self._controller_list[index] = con
	end
	managers.controller:add_hotswap_callback("blt_mods_gui", callback(self, self, "on_controller_hotswap"))
end

function BLTModsGui:_set_initial_data()
	self._node.components.raid_menu_header:set_screen_name("blt_installed_mods")

	-- Count the number of libraries installed
	self._libs_count = 0
	for _, mod in ipairs(BLT.Mods:Mods()) do
		if mod:IsLibrary() then
			self._libs_count = self._libs_count + 1
		end
	end
end

function BLTModsGui:close()
	if self._selected_mod then
		for _, update in ipairs(self._selected_mod:GetUpdates()) do
			update:remove_event_handler("blt_mods_gui_on_update_change")
		end
	end

	MenuCallbackHandler:perform_blt_save()

	self._primary_paper:stop()
	self._secondary_paper:stop()
	self._soe_emblem:stop()

	if self._controller_list then
		for _, controller in ipairs(self._controller_list) do
			controller:destroy()
		end
	end

	self._root_panel:clear()
	self._root_panel.ctrls = {}
	-- BLTModsGui.super.close(self) -- Nein!
end

function BLTModsGui:_layout()
	self._safe_rect_workspace = Overlay:gui():create_screen_workspace()
	managers.gui_data:layout_workspace(self._safe_rect_workspace)
	self._safe_panel = self._safe_rect_workspace:panel()

	self:_layout_primary_paper()
	self:_layout_secondary_paper()

	-- local header_height = self._node.components.raid_menu_header._screen_subtitle_label:bottom()
	-- local footer_height = self._node.components.raid_menu_footer._panel_h

	-- _list_panel
	self._list_panel = self._root_panel:panel({
		h = 690,
		layer = 1,
		name = "list_panel",
		w = 448,
		y = 78,
	})

	-- _primary_lists_panel
	self._primary_lists_panel = self._list_panel:panel({
		name = "primary_lists_panel",
	})

	-- _actions_panel
	self._actions_panel = self._root_panel:panel({
		h = self._root_panel:h(),
		name = "mod_actions_panel",
		w = self._root_panel:w(),
	})

	-- _list_tabs
	local tabs_params = {
		{
			-- breadcrumb = {
			-- 	category = BreadcrumbManager.CATEGORY_CONSUMABLE_MISSION,
			-- },
			callback_param = BLTModsGui.TABS_REGULAR_MODS,
			name = BLTModsGui.TABS_REGULAR_MODS,
			text = self:translate("blt_regular_mods_tab", true),
		},
		{
			-- breadcrumb = {
			-- 	category = BreadcrumbManager.CATEGORY_OPERATIONS,
			-- },
			callback_param = BLTModsGui.TABS_CORE_MODS,
			name = BLTModsGui.TABS_CORE_MODS,
			text = self:translate("blt_core_mods_tab", true),
		},
	}
	self._list_tabs = self._primary_lists_panel:tabs({
		name = "blt_mods_list_tabs",
		on_click_callback = callback(self, self, "_on_mod_list_type_changed"),
		tab_align = "center",
		tabs_params = tabs_params,
		x = 3,
		tab_width = (self._primary_lists_panel:w() - 2 * 3) / #tabs_params
	})
	self._selected_tab = BLTModsGui.TABS_REGULAR_MODS

	self:_layout_info_buttons()

	-- _regular_mods_list_panel
	self._regular_mods_list_panel = self._primary_lists_panel:scrollable_area({
		h = self._primary_lists_panel:h() - self._list_tabs:h(),
		name = "blt_regular_mods_list_scrollable_area",
		scroll_step = 35,
		w = self._primary_lists_panel:w(),
		y = self._list_tabs:h(),
	})
	-- _regular_mods_list
	self._regular_mods_list = self._regular_mods_list_panel:get_panel():list({
		name = "blt_regular_mods_list",
		data_source_callback = callback(self, self, "_mods_list_data_source", BLTModsGui.TABS_REGULAR_MODS),
		scrollable_area_ref = self._regular_mods_list_panel,
		loop_items = false,
		selection_enabled = true,
		padding_top = 2,
		vertical_spacing = 2,
		item_class = BLTGUIControlListItemMod,
		item_params = {
			icon_color = Color.white,
		},
		on_mouse_click_sound_event = "menu_enter",
		on_mouse_over_sound_event = "highlight",
		w = self._regular_mods_list_panel:w(),
		on_item_clicked_callback = callback(self, self, "_on_mod_selected"),
		-- on_item_double_clicked_callback = callback(self, self, "_on_mods_list_double_clicked"),
		on_item_selected_callback = callback(self, self, "_on_mod_selected"),
		-- selected_callback = callback(self, self, "_on_regular_mods_list_selected"),
		-- unselected_callback = callback(self, self, "_on_regular_mods_list_unselected"),
		on_menu_move = {
			-- up = "blt_download_manager_btn",
			down = "blt_download_manager_btn",
		},
	})
	self._regular_mods_list_panel:setup_scroll_area()

	-- _core_mods_list_panel
	self._core_mods_list_panel = self._list_panel:scrollable_area({
		h = self._list_panel:h() - self._list_tabs:h(),
		name = "blt_core_mods_list_scrollable_area",
		scroll_step = 35,
		y = self._list_tabs:h(),
	})
	self._core_mods_list_panel:set_alpha(0)
	self._core_mods_list_panel:set_visible(false)

	-- _core_mods_list
	self._core_mods_list = self._core_mods_list_panel:get_panel():list({
		name = "blt_core_mods_list",
		data_source_callback = callback(self, self, "_mods_list_data_source", BLTModsGui.TABS_CORE_MODS),
		scrollable_area_ref = self._core_mods_list_panel,
		loop_items = false,
		selection_enabled = true,
		padding_top = 2,
		vertical_spacing = 2,
		item_class = BLTGUIControlListItemMod,
		item_params = {
			icon_color = Color.white,
		},
		on_mouse_click_sound_event = "menu_enter",
		on_mouse_over_sound_event = "highlight",
		on_item_clicked_callback = callback(self, self, "_on_mod_selected"),
		-- on_item_double_clicked_callback = callback(self, self, "_on_mods_list_double_clicked"),
		on_item_selected_callback = callback(self, self, "_on_mod_selected"),
		-- selected_callback = callback(self, self, "_on_core_mods_list_selected"),
		-- unselected_callback = callback(self, self, "_on_core_mods_list_unselected"),
		on_menu_move = {
			-- up = "blt_download_manager_btn",
			down = "blt_download_manager_btn",
		},
	})
	self._core_mods_list_panel:setup_scroll_area()

	-- download manager button
	self._download_manager_button = self._actions_panel:long_secondary_button({
		name = "blt_download_manager_btn",
		text = self:translate("blt_download_manager", true),
		on_click_callback = callback(self, self, "clbk_open_download_manager"),
		x = 6,
	})
	self._download_manager_button:set_center_y(840)
	-- downloads available
	local downloads_count = #BLT.Downloads:pending_downloads()
	if downloads_count > 0 then
		self._download_manager_button_desc = self._actions_panel:label({
			name = "blt_download_manager_desc",
			fit_text = true,
			color = tweak_data.gui.colors.raid_grey,
			text = managers.localization:text("blt_downloads_available" .. ((downloads_count == 1) and "_sin" or "_plu"),
				{ COUNT = downloads_count }),
			x = self._download_manager_button:right() + padding,
		})
		self._download_manager_button_desc:set_center_y(self._download_manager_button:center_y())
	end

	if self._regular_mods_list._list_items and (#self._regular_mods_list._list_items > 0) then
		self:_select_regular_mods_tab()
	else
		self:_select_core_mods_tab()
	end
end

function BLTModsGui:_layout_primary_paper()
	self._primary_paper_panel = self._root_panel:panel({
		h = 768,
		layer = RaidGuiBase.FOREGROUND_LAYER + 150,
		name = "primary_paper_panel",
		w = 524,
		x = 580,
		y = 118,
	})

	self._primary_paper = self._primary_paper_panel:bitmap({
		h = self._primary_paper_panel:h(),
		name = "primary_paper",
		texture = tweak_data.gui.images[paper_image].texture,
		texture_rect = tweak_data.gui.images[paper_image].texture_rect,
		w = self._primary_paper_panel:w(),
		x = 0,
		y = 0,
	})

	self._soe_emblem = self._primary_paper_panel:bitmap({
		layer = self._primary_paper:layer() + 1,
		name = "soe_emblem",
		texture = tweak_data.gui.icons[soe_emblem_image].texture,
		texture_rect = tweak_data.gui.icons[soe_emblem_image].texture_rect,
		x = 384,
		y = 22,
	})

	self:_recreate_paper_mission_icon()

	self._primary_paper_title = self._primary_paper_panel:label({
		color = tweak_data.gui.colors.raid_black,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		layer = self._primary_paper:layer() + 1,
		name = "primary_paper_title",
		text = "",
		y = 44,
	})

	self._mod_version = self._primary_paper_panel:label({
		color = tweak_data.gui.colors.raid_dark_grey,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.extra_small,
		layer = self._primary_paper:layer() + 1,
		name = "mod_version",
		text = "",
		y = 78,
	})

	self._mod_update_status = self._primary_paper_panel:label({
		color = tweak_data.gui.colors.raid_dark_grey,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.extra_small,
		name = "mod_update_status",
		text = "",
		y = 112,
	})

	self:_align_paper_titles()

	self._primary_paper_separator = self._primary_paper_panel:rect({
		color = tweak_data.gui.colors.raid_black,
		h = 2,
		layer = self._primary_paper:layer() + 1,
		name = "primary_paper_separator",
		w = 350,
		x = 34,
		y = 148,
	})

	self:_layout_mod_details()
end

function BLTModsGui:_layout_secondary_paper()
	self._secondary_paper_panel = self._root_panel:panel({
		h = 768,
		layer = RaidGuiBase.FOREGROUND_LAYER,
		name = "secondary_paper_panel",
		w = 524,
		x = 580,
		y = 118,
	})

	self._secondary_paper = self._secondary_paper_panel:bitmap({
		h = self._secondary_paper_panel:h(),
		name = "secondary_paper",
		texture = tweak_data.gui.images[paper_image].texture,
		texture_rect = tweak_data.gui.images[paper_image].texture_rect,
		w = self._secondary_paper_panel:w(),
		x = 0,
		y = 0,
	})

	self:_layout_dev_info()

	self._secondary_paper_panel:set_x(self._primary_paper_panel:x())
	self._secondary_paper_panel:set_rotation(BLTModsGui.BACKGROUND_PAPER_ROTATION)
	self._secondary_paper_panel:set_w(self._primary_paper_panel:w() * BLTModsGui.BACKGROUND_PAPER_SCALE)
	self._secondary_paper_panel:set_h(self._primary_paper_panel:h() * BLTModsGui.BACKGROUND_PAPER_SCALE)
	self._secondary_paper:set_color(BLTModsGui.BACKGROUND_PAPER_COLOR)
	self._secondary_paper_panel:set_alpha(BLTModsGui.BACKGROUND_PAPER_ALPHA)

	self._secondary_paper_shown = false
	self._paper_animation_t = 0
end

function BLTModsGui:_layout_dev_info()
	local x, y = 38, 44
	self._dev_info_panel = self._secondary_paper_panel:scrollable_area({
		layer = self._secondary_paper_panel:layer() + 1,
		name = "dev_info_panel",
		scroll_step = 35,
		x = x,
		y = y,
		w = self._secondary_paper_panel:w() - x * 2,
		h = self._secondary_paper_panel:h() - y * 2,
	})

	self._mod_dev_info = self._dev_info_panel:get_panel():label({
		color = tweak_data.gui.colors.raid_black,
		font = tweak_data.gui.fonts.lato,
		font_size = tweak_data.gui.font_sizes.size_12,
		name = "mod_dev_info",
		text = "",
		fit_text = true,
		w = self._dev_info_panel:w(),
	})

	self._dev_info_panel:setup_scroll_area()
end

function BLTModsGui:_layout_info_buttons()
	self._info_buttons_panel = self._primary_paper_panel:panel({
		h = 96,
		layer = self._primary_paper_panel:layer() + 1,
		name = "info_buttons_panel",
		w = self._primary_paper_panel:w(),
		x = self._primary_paper_title:x(),
		y = 0,
	})
	self._info_buttons_panel:set_center_x(math.floor(self._primary_paper_panel:w() / 2))
	self._info_buttons_panel:set_y(self._primary_paper_panel:h() - self._info_buttons_panel:h() - 16)

	self._info_buttons = {}

	local function make_button(icon, clbk_func, text)
		local i = #self._info_buttons + 1
		local btn = self._info_buttons_panel:info_button({
			name = "info_button_" .. tostring(i),
			icon = icon,
			on_click_callback = callback(self, self, clbk_func, i),
			text = text,
		})
		btn._icon:set_w(36)
		btn._icon:set_h(36)
		btn._icon_w = 36
		btn._icon_h = 36
		btn:_fit_size()
		btn:set_center_y(math.floor(self._info_buttons_panel:h() / 2))
		table.insert(self._info_buttons, i, btn)
		return btn
	end

	self._info_button_mod_toggle_enable = make_button("ico_locker", "_on_info_button_toggle_mod_enabled_clicked",
		"TOGGLE")
	self._info_button_mod_contact = make_button("ico_info", "_on_info_button_contact_clicked",
		"CONTACT")
	self._info_button_mod_toggle_updates = make_button("ico_dlc", "_on_info_button_toggle_auto_updates_clicked",
		"TOGGLE AUTO UPD.")
	self._info_button_mod_update_check = make_button("waypoint_special_where",
		"_on_info_button_check_for_updates_clicked",
		"CHECK NOW")

	self:_update_info_buttons(nil)
end

function BLTModsGui:_layout_mod_details()
	self._mod_details_panel = self._primary_paper_panel:panel({
		layer = self._primary_paper_panel:layer() + 1,
		h = 528,
		w = 432,
		x = 38,
		y = 161,
		visible = false,
	})
	self._mod_description = self._mod_details_panel:label({
		color = tweak_data.gui.colors.raid_black,
		font = tweak_data.gui.fonts.lato,
		font_size = tweak_data.gui.font_sizes.paragraph,
		name = "mod_description",
		text = "",
		wrap = true,
		fit_text = true,
		w = 432,
	})
	self._mod_author = self._mod_details_panel:label({
		color = tweak_data.gui.colors.raid_black,
		font = tweak_data.gui.fonts.lato,
		font_size = tweak_data.gui.font_sizes.paragraph,
		name = "mod_author",
		text = "",
		wrap = true,
		fit_text = true,
		w = 432,
	})
	self._mod_contact = self._mod_details_panel:label({
		color = tweak_data.gui.colors.raid_black,
		font = tweak_data.gui.fonts.lato,
		font_size = tweak_data.gui.font_sizes.paragraph,
		name = "mod_contact",
		text = "",
		wrap = true,
		fit_text = true,
		w = 432,
	})
	self._mod_errors = self._mod_details_panel:label({
		color = tweak_data.gui.colors.raid_red,
		font = tweak_data.gui.fonts.lato,
		font_size = tweak_data.gui.font_sizes.paragraph,
		name = "mod_errors",
		text = "",
		wrap = true,
		fit_text = true,
		w = 432,
	})
end

function BLTModsGui:_mods_list_data_source(mode)
	local mods = {}
	local index = 1
	-- collect mods for current list
	for _, mod in ipairs(BLT.Mods:Mods()) do
		if ((mode == BLTModsGui.TABS_CORE_MODS) and ((mod:GetId() == "base") or mod:IsLibrary())) or
			((mode == BLTModsGui.TABS_REGULAR_MODS) and ((mod:GetId() ~= "base") and not mod:IsLibrary())) then
			local missing_icon
			local missing_icon_text
			local icon
			if mod:HasModImage() then
				icon = { texture = mod:GetModImage() }
			else
				missing_icon = true
				missing_icon_text = self:translate("blt_no_image", true)
				icon = tweak_data.gui:get_full_gui_data(BLTModsGui.FALLBACK_GUI_ICON)
			end
			local mod_data = {
				index = index,
				mod = mod,
				value = mod:GetName(),
				icon = icon,
				missing_icon = missing_icon,
				missing_icon_text = missing_icon_text,
			}
			table.insert(mods, mod_data)
			index = index + 1
		end
	end

	-- Sort mods/libs
	table.sort(mods, function(mod1, mod2)
		if mod1.mod:GetId() == "base" then
			return true
		elseif mod2.mod:GetId() == "base" then
			return false
		elseif mod1.mod:GetName():lower() < mod2.mod:GetName():lower() then
			return true
		elseif mod1.mod:GetName():lower() > mod2.mod:GetName():lower() then
			return false
		end
		return mod1.mod:GetId():lower() < mod2.mod:GetId():lower()
	end)

	return mods
end

function BLTModsGui:_on_mod_list_type_changed(tab)
	self._selected_tab = tab

	if self._selected_tab == BLTModsGui.TABS_REGULAR_MODS then
		self:_select_regular_mods_tab()
	else
		self:_select_core_mods_tab()
	end
end

function BLTModsGui:_select_regular_mods_tab()
	self._download_manager_button:set_selected(false)
	self._core_mods_list:set_selected(false)
	self._regular_mods_list:set_selected(true)

	self._core_mods_list_panel:set_visible(false)
	self._core_mods_list_panel:set_alpha(0)
	self._regular_mods_list_panel:set_visible(true)
	self._regular_mods_list_panel:set_alpha(1)

	self._download_manager_button:set_menu_move_controls({
		up = "blt_regular_mods_list",
		-- down = "blt_regular_mods_list",
	})
end

function BLTModsGui:_select_core_mods_tab()
	self._download_manager_button:set_selected(false)
	self._regular_mods_list:set_selected(false)
	self._core_mods_list:set_selected(true)

	self._regular_mods_list_panel:set_visible(false)
	self._regular_mods_list_panel:set_alpha(0)
	self._core_mods_list_panel:set_visible(true)
	self._core_mods_list_panel:set_alpha(1)

	self._download_manager_button:set_menu_move_controls({
		up = "blt_core_mods_list",
		-- down = "blt_core_mods_list",
	})
end

function BLTModsGui:_on_list_tabs_left()
	if self._selected_tab == BLTModsGui.TABS_REGULAR_MODS or not self._list_tabs:enabled() then
		return
	end
	self:_unselect_middle_column()
	self._list_tabs:_move_left()
	self._selected_column = BLTModsGui.COLUMN_MODS
	self._selected_tab = BLTModsGui.TABS_REGULAR_MODS
	return true
end

function BLTModsGui:_on_list_tabs_right()
	if self._selected_tab == BLTModsGui.TABS_CORE_MODS or not self._list_tabs:enabled() then
		return
	end
	self:_unselect_middle_column()
	self._list_tabs:_move_right()
	self._selected_column = BLTModsGui.COLUMN_MODS
	self._selected_tab = BLTModsGui.TABS_CORE_MODS
	return true
end

function BLTModsGui:_on_column_left()
	if self._selected_column == BLTModsGui.COLUMN_MODS then
		return true
	end

	self._selected_column = self._selected_column - 1

	if self._selected_column == BLTModsGui.COLUMN_MODS then
		self:_unselect_middle_column()
		self._list_tabs:set_selected(true)
	end

	return true
end

function BLTModsGui:_on_column_right()
	if self._selected_column == BLTModsGui.COLUMN_INFO then
		return true
	end

	self._selected_column = self._selected_column + 1

	if (self._selected_column == BLTModsGui.COLUMN_INFO) then
		self:_unselect_left_column()
		self._info_buttons[1]:set_selected(true)
	end

	return true
end

function BLTModsGui:_unselect_left_column()
	self._regular_mods_list:set_selected(false)
	self._core_mods_list:set_selected(false)
	self._list_tabs:set_selected(false)
end

function BLTModsGui:_unselect_middle_column()
	for _, btn in ipairs(self._info_buttons) do
		btn:set_selected(false)
	end
end

function BLTModsGui:refresh_mods()
	local selected_tab = self._selected_tab
	local selected_mod = self._selected_mod

	self._primary_paper:stop()
	self._secondary_paper:stop()

	self._regular_mods_list:refresh_data()
	self._core_mods_list:refresh_data()

	if selected_mod then
		if selected_tab == BLTModsGui.TABS_REGULAR_MODS then
			self._regular_mods_list:select_item_by_value(selected_mod:GetName())
		elseif selected_tab == BLTModsGui.TABS_CORE_MODS then
			self._core_mods_list:select_item_by_value(selected_mod:GetName())
		end
	end
end

function BLTModsGui:_animate_change_primary_paper_control(control, mid_callback, new_active_control)
	local fade_out_duration = 0.2
	local t
	if self._active_primary_paper_control then
		if control then
			t = (1 - self._active_primary_paper_control:alpha()) * fade_out_duration
			while t < fade_out_duration do
				local dt = coroutine.yield()
				t = t + dt
				local alpha = Easing.cubic_in_out(t, 1, -1, fade_out_duration)
				self._active_primary_paper_control:set_alpha(alpha)
			end
		end
		self._active_primary_paper_control:set_alpha(0)
		self._active_primary_paper_control:set_visible(false)
	end
	if mid_callback then
		mid_callback()
	end
	self._active_primary_paper_control = new_active_control
	self._active_primary_paper_control:set_visible(true)
	local fade_in_duration = 0.25
	if control then
		t = self._active_primary_paper_control:alpha() * fade_in_duration
		while t < fade_in_duration do
			local dt = coroutine.yield()

			t = t + dt

			local alpha = Easing.cubic_in_out(t, 0, 1, fade_in_duration)

			self._active_primary_paper_control:set_alpha(alpha)
		end
	end
	self._active_primary_paper_control:set_alpha(1)
end

function BLTModsGui:_animate_show_secondary_paper(_, done_callback)
	local duration = 0.5
	local t = self._paper_animation_t * duration

	self._secondary_paper_shown = true

	while t < duration do
		local dt = coroutine.yield()

		t = t + dt

		local alpha = Easing.cubic_in_out(t, BLTModsGui.BACKGROUND_PAPER_ALPHA, 1 - BLTModsGui.BACKGROUND_PAPER_ALPHA,
			duration)
		local color_r = Easing.cubic_in_out(t, BLTModsGui.BACKGROUND_PAPER_COLOR.r,
			BLTModsGui.FOREGROUND_PAPER_COLOR.r - BLTModsGui.BACKGROUND_PAPER_COLOR.r, duration)
		local color_g = Easing.cubic_in_out(t, BLTModsGui.BACKGROUND_PAPER_COLOR.g,
			BLTModsGui.FOREGROUND_PAPER_COLOR.g - BLTModsGui.BACKGROUND_PAPER_COLOR.g, duration)
		local color_b = Easing.cubic_in_out(t, BLTModsGui.BACKGROUND_PAPER_COLOR.b,
			BLTModsGui.FOREGROUND_PAPER_COLOR.b - BLTModsGui.BACKGROUND_PAPER_COLOR.b, duration)

		self._secondary_paper:set_color(Color(color_r, color_g, color_b))
		self._secondary_paper_panel:set_alpha(alpha)

		local scale = Easing.cubic_in_out(t, BLTModsGui.BACKGROUND_PAPER_SCALE, 1 - BLTModsGui.BACKGROUND_PAPER_SCALE,
			duration)

		self._secondary_paper_panel:set_w(self._primary_paper_panel:w() * scale)
		self._secondary_paper_panel:set_h(self._primary_paper_panel:h() * scale)

		local rotation = Easing.cubic_in_out(t, BLTModsGui.BACKGROUND_PAPER_ROTATION,
			-BLTModsGui.BACKGROUND_PAPER_ROTATION, duration)

		self._secondary_paper_panel:set_rotation(rotation)

		local x = Easing.cubic_in_out(t, self._primary_paper_panel:x(),
			self._primary_paper_panel:w() + BLTModsGui.SECONDARY_PAPER_PADDING_LEFT, duration)

		self._secondary_paper_panel:set_x(x)

		self._paper_animation_t = t / duration
	end

	self._secondary_paper_panel:set_x(self._primary_paper_panel:x() + self._primary_paper_panel:w() +
		BLTModsGui.SECONDARY_PAPER_PADDING_LEFT)
	self._secondary_paper_panel:set_rotation(0)
	self._secondary_paper_panel:set_w(self._primary_paper_panel:w())
	self._secondary_paper_panel:set_h(self._primary_paper_panel:h())
	self._secondary_paper:set_color(BLTModsGui.FOREGROUND_PAPER_COLOR)
	self._secondary_paper_panel:set_alpha(1)

	self._paper_animation_t = 1

	self._dev_info_panel:show()

	if done_callback then
		done_callback()
	end
end

function BLTModsGui:_animate_hide_secondary_paper()
	local duration = 0.5
	local t = (1 - self._paper_animation_t) * duration

	self._secondary_paper_shown = false

	self._dev_info_panel:hide()

	while t < duration do
		local dt = coroutine.yield()

		t = t + dt

		local alpha = Easing.cubic_in_out(t, 1, BLTModsGui.BACKGROUND_PAPER_ALPHA - 1, duration)
		local color_r = Easing.cubic_in_out(t, BLTModsGui.FOREGROUND_PAPER_COLOR.r,
			BLTModsGui.BACKGROUND_PAPER_COLOR.r - BLTModsGui.FOREGROUND_PAPER_COLOR.r, duration)
		local color_g = Easing.cubic_in_out(t, BLTModsGui.FOREGROUND_PAPER_COLOR.g,
			BLTModsGui.BACKGROUND_PAPER_COLOR.g - BLTModsGui.FOREGROUND_PAPER_COLOR.g, duration)
		local color_b = Easing.cubic_in_out(t, BLTModsGui.FOREGROUND_PAPER_COLOR.b,
			BLTModsGui.BACKGROUND_PAPER_COLOR.b - BLTModsGui.FOREGROUND_PAPER_COLOR.b, duration)

		self._secondary_paper:set_color(Color(color_r, color_g, color_b))
		self._secondary_paper_panel:set_alpha(alpha)

		local scale = Easing.cubic_in_out(t, 1, BLTModsGui.BACKGROUND_PAPER_SCALE - 1, duration)

		self._secondary_paper_panel:set_w(self._primary_paper_panel:w() * scale)
		self._secondary_paper_panel:set_h(self._primary_paper_panel:h() * scale)

		local rotation = Easing.cubic_in_out(t, 0, BLTModsGui.BACKGROUND_PAPER_ROTATION, duration)

		self._secondary_paper_panel:set_rotation(rotation)

		local x = Easing.cubic_in_out(t,
			self._primary_paper_panel:x() + self._primary_paper_panel:w() + BLTModsGui.SECONDARY_PAPER_PADDING_LEFT,
			-self._primary_paper_panel:w() - BLTModsGui.SECONDARY_PAPER_PADDING_LEFT, duration)

		self._secondary_paper_panel:set_x(x)

		self._paper_animation_t = 1 - t / duration
	end

	self._secondary_paper_panel:set_x(self._primary_paper_panel:x())
	self._secondary_paper_panel:set_rotation(BLTModsGui.BACKGROUND_PAPER_ROTATION)
	self._secondary_paper_panel:set_w(self._primary_paper_panel:w() * BLTModsGui.BACKGROUND_PAPER_SCALE)
	self._secondary_paper_panel:set_h(self._primary_paper_panel:h() * BLTModsGui.BACKGROUND_PAPER_SCALE)
	self._secondary_paper:set_color(BLTModsGui.BACKGROUND_PAPER_COLOR)
	self._secondary_paper_panel:set_alpha(BLTModsGui.BACKGROUND_PAPER_ALPHA)

	self._paper_animation_t = 0
end

function BLTModsGui:_recreate_paper_mission_icon()
	if self._primary_paper_mission_icon then
		self._primary_paper_panel:remove(self._primary_paper_mission_icon)
	end
	self._primary_paper_mission_icon = self._primary_paper_panel:bitmap({
		-- color = tweak_data.gui.colors.raid_black,
		layer = self._primary_paper:layer() + 1,
		name = "mission_icon",
		texture = tweak_data.gui.icons[soe_emblem_image].texture,
		texture_rect = tweak_data.gui.icons[soe_emblem_image].texture_rect,
		x = 32,
		y = 44,
	})
	if self._missing_icon_text then
		self._primary_paper_panel:remove(self._missing_icon_text)
	end
	self._missing_icon_text = self._primary_paper_panel:label({
		name = "missing_icon_text",
		fit_size = true,
		font_size = tweak_data.gui.font_sizes.small,
		font = tweak_data.gui.fonts.din_compressed,
		layer = 11,
		text = self:translate("blt_no_image", true),
		align = "center",
		vertical = "center",
	})
	self._missing_icon_text:set_center_x(self._primary_paper_mission_icon:center_x())
	self._missing_icon_text:set_center_y(self._primary_paper_mission_icon:center_y())
end

function BLTModsGui:_align_paper_titles()
	self._primary_paper_title:set_x(self._primary_paper_mission_icon:right() + padding)
	self._mod_version:set_x(self._primary_paper_title:x())
	self._mod_update_status:set_x(self._primary_paper_title:x())
end

function BLTModsGui:_update_info_buttons(mod)
	local has_mod = not not mod

	local enabled_buttons = {
		[self._info_button_mod_toggle_enable] = has_mod and not mod:IsUndisablable(),
		[self._info_button_mod_contact] = has_mod and mod:GetContact() and mod:IsContactWebsite(),
		[self._info_button_mod_toggle_updates] = has_mod and mod:HasUpdates(),
		[self._info_button_mod_update_check] = has_mod and mod:HasUpdates(),
	}

	if has_mod then
		if not mod:IsUndisablable() then
			self._info_button_mod_toggle_enable._text:set_text(mod:IsEnabled() and "DISABLE" or "ENABLE")
			self._info_button_mod_toggle_enable:_fit_size()
		end

		if mod:HasUpdates() then
			self._info_button_mod_toggle_updates._text:set_text((mod:HasUpdates() and mod:AreUpdatesEnabled()) and
				"DIS. AUTO UPD." or
				"EN. AUTO UPD.")
			self._info_button_mod_toggle_updates:_fit_size()
		end
	end

	local enabled_btn_count = 0
	for _, v in pairs(enabled_buttons) do
		if v then
			enabled_btn_count = enabled_btn_count + 1
		end
	end

	local last_info_btn = nil
	local next_info_btn = nil
	local enabled_i = 0
	for i, btn in ipairs(self._info_buttons) do
		if enabled_buttons[btn] then
			enabled_i = enabled_i + 1
			btn:set_center_x(math.floor(self._info_buttons_panel:w() / (enabled_btn_count + 1) * enabled_i))
			btn._params.on_menu_move = btn._params.on_menu_move or {}
			if last_info_btn then
				btn._params.on_menu_move.left = "info_button_" .. tostring(last_info_btn)
			else
				btn._params.on_menu_move.left = nil
			end
			for j = i + 1, #self._info_buttons do -- get next enabled btn
				if enabled_buttons[self._info_buttons[j]] then
					next_info_btn = j
					break
				end
			end
			if next_info_btn then
				btn._params.on_menu_move.right = "info_button_" .. tostring(next_info_btn)
			else
				btn._params.on_menu_move.right = nil
			end
			btn:set_menu_move_controls(btn._params.on_menu_move)

			last_info_btn = i
			next_info_btn = nil

			btn:show()
		else
			btn:hide()
		end
	end
end

function BLTModsGui:_set_active_info_button(i, state)
	for _i, btn in ipairs(self._info_buttons) do
		btn:set_active(state and (i == _i))
	end
end

function BLTModsGui:_on_mod_selected(mod_data)
	if self._selected_mod then
		for _, update in ipairs(self._selected_mod:GetUpdates()) do
			update:remove_event_handler("blt_mods_gui_on_update_change")
		end
	end
	self._selected_mod = nil -- temp disable info buttons

	if self._secondary_paper_shown then
		self._secondary_paper:stop()
		self._secondary_paper:animate(
			callback(self, self, "_animate_hide_secondary_paper")
		)
	end

	self._primary_paper:stop()
	self._primary_paper:animate(
		callback(self, self, "_animate_change_primary_paper_control"),
		callback(self, self, "refresh_mod_details", mod_data),
		self._mod_details_panel
	)
	self:bind_controller_inputs()
end

function BLTModsGui:refresh_mod_details(mod_data)
	local mod = mod_data.mod

	-- mod icon
	self:_recreate_paper_mission_icon()
	self._primary_paper_mission_icon:set_image(mod_data.icon.texture)
	if mod_data.icon.texture_rect then
		self._primary_paper_mission_icon:set_texture_rect(unpack(mod_data.icon.texture_rect))
	end
	self._primary_paper_mission_icon:set_w(mod_data.icon.w)
	self._primary_paper_mission_icon:set_h(mod_data.icon.h)
	if mod_data.missing_icon then
		self._missing_icon_text:set_text(mod_data.missing_icon_text)
		self._missing_icon_text:set_center_x(self._primary_paper_mission_icon:center_x())
		self._missing_icon_text:set_center_y(self._primary_paper_mission_icon:center_y())
		self._missing_icon_text:set_visible(true)
	else
		self._missing_icon_text:set_visible(false)
	end

	-- mod name
	self._primary_paper_title:set_text(mod:GetName())

	-- mod version
	self._mod_version:set_text(mod:GetVersion())

	-- mod update status
	self:_refresh_mod_update_status()

	self:_align_paper_titles() -- align name / version / update status x

	----

	-- mod description

	self._mod_description:set_w(self._mod_details_panel:w())
	self._mod_description:set_text(mod:GetDescription())

	local next_y = self._mod_details_panel:h() / 2

	-- mod author

	local author = mod:GetAuthor()
	if author then
		self._mod_author:set_y(next_y)
		self._mod_author:set_w(self._mod_details_panel:w())
		self._mod_author:set_text(self:translate("blt_mod_info_author") ..
			":\n" .. author)
		next_y = self._mod_author:bottom() + padding
		self._mod_author:show()
	else
		self._mod_author:hide()
	end

	-- mod contact

	local contact = mod:GetContact()
	if contact and (contact ~= "N/A") then
		self._mod_contact:set_y(next_y)
		self._mod_contact:set_w(self._mod_details_panel:w())
		self._mod_contact:set_text(self:translate("blt_mod_info_contact") ..
			":\n" .. contact)
		next_y = self._mod_contact:bottom() + padding
		self._mod_contact:show()
	else
		self._mod_contact:hide()
	end

	-- mod errors
	if mod:Errors() then
		-- Build the errors string
		local error_str = ""
		for i, error in ipairs(mod:Errors()) do
			error_str = error_str .. (i > 1 and "\n" or "") .. self:translate(error)
		end
		error_str = error_str .. "\n"

		-- Append any missing dependencies and if they available
		for _, dependency in ipairs(mod:GetMissingDependencies()) do
			local loc_str = dependency:GetServerData() and "blt_mod_missing_dependency_download" or
				"blt_mod_missing_dependency"
			error_str = error_str ..
				managers.localization:text(loc_str, { dependency = dependency:GetServerName() }) .. "\n"
		end
		error_str = error_str .. (#mod:GetMissingDependencies() > 0 and "\n" or "")

		for _, dependency_mod in ipairs(mod:GetDisabledDependencies()) do
			error_str = error_str ..
				managers.localization:text("blt_mod_disabled_dependency", { dependency = dependency_mod:GetName() }) ..
				"\n"
		end
		error_str = error_str .. (#mod:GetDisabledDependencies() > 0 and "\n" or "")

		self._mod_errors:set_y(next_y)
		self._mod_errors:set_w(self._mod_details_panel:w())
		self._mod_errors:set_text(error_str)
		next_y = self._mod_errors:bottom() + padding

		self._mod_errors:show()
	else
		self._mod_errors:hide()
	end

	if not self._secondary_paper_shown then
		self._secondary_paper:stop()
		self._secondary_paper:animate(
			callback(self, self, "_animate_show_secondary_paper"),
			callback(self, self, "refresh_mod_details_secondary_paper", mod)
		)
	end

	self:_update_info_buttons(mod)
	self._selected_mod = mod -- re-enable info buttons

	for _, update in ipairs(self._selected_mod:GetUpdates()) do
		update:register_event_handler("blt_mods_gui_on_update_change",
			callback(self, self, "_on_update_change"))
	end
end

function BLTModsGui:refresh_mod_details_secondary_paper(mod)

	-- mod dev info
	self._mod_dev_info:set_text("Dev Info:\n" .. mod:GetDeveloperInfo())

	self._dev_info_panel:setup_scroll_area()
end

function BLTModsGui:clbk_open_download_manager()
	MenuHelper:OpenMenu("blt_download_manager")
end

function BLTModsGui:_on_info_button_toggle_mod_enabled_clicked(i)
	if not self._selected_mod then
		return
	end
	if self._selected_mod:IsUndisablable() then
		return
	end
	self._selected_mod:SetEnabled(not self._selected_mod:IsEnabled())
	self:refresh_mods()
end

function BLTModsGui:_on_info_button_contact_clicked(i)
	if not self._selected_mod then
		return
	end
	if not self._selected_mod:GetContact() or not self._selected_mod:IsContactWebsite() then
		return
	end
	Utils.OpenUrlSafe(self._selected_mod:GetContact())
end

function BLTModsGui:_on_info_button_toggle_auto_updates_clicked(i)
	if not self._selected_mod then
		return
	end
	self._selected_mod:SetUpdatesEnabled(not self._selected_mod:AreUpdatesEnabled())
	self:refresh_mods()
end

function BLTModsGui:_on_info_button_check_for_updates_clicked(i)
	if not self._selected_mod then
		return
	end
	if not self._selected_mod:IsCheckingForUpdates() then
		self._selected_mod:CheckForUpdates(callback(self, self, "clbk_check_for_updates_finished"))
	end
end

function BLTModsGui:clbk_check_for_updates_finished(cache)
	local name

	-- Does this mod need updating
	local requires_update = false
	local error_reason
	for _, data in pairs(cache) do
		name = data.mod:GetName()
		-- An update for this mod needs updating
		requires_update = data.requires_update or requires_update

		-- Add the update to the download manager
		if data.requires_update then
			BLT.Downloads:add_pending_download(data.update)
		end
	end

	-- Show updates dialog
	local message
	if error_reason then
		message = managers.localization:text("blt_update_mod_error", { reason = error_reason })
	elseif not requires_update then
		message = managers.localization:text("blt_update_mod_up_to_date", { name = name })
	else
		message = managers.localization:text("blt_update_mod_available", { name = name })
	end
	if message then
		QuickMenu:new(
			managers.localization:text("blt_update_mod_title", { name = name }),
			message,
			nil,
			true
		)
	end
end

function BLTModsGui:on_controller_hotswap()
	local press_any_key_prompt = self._safe_panel:child("press_any_key_prompt")
	if press_any_key_prompt then
		press_any_key_prompt:stop()
		press_any_key_prompt:animate(callback(self, self, "_animate_change_press_any_key_prompt"))
	end
end

function BLTModsGui:_animate_change_press_any_key_prompt(prompt)
	local fade_out_duration = 0.25
	local t = (1 - prompt:alpha()) * fade_out_duration
	while t < fade_out_duration do
		local dt = coroutine.yield()
		t = t + dt
		local current_alpha = Easing.quartic_in_out(t, 0.85, -0.85, fade_out_duration)
		prompt:set_alpha(current_alpha)
	end
	prompt:set_alpha(0)
	local press_any_key_text = managers.controller:is_using_controller() and "press_any_key_to_skip_controller" or
		"press_any_key_to_skip"
	prompt:set_text(self:translate(press_any_key_text, true))
	local _, _, w, h = prompt:text_rect()
	prompt:set_w(w)
	prompt:set_h(h)
	prompt:set_right(self._safe_panel:w() - 50)
	local fade_in_duration = 0.25
	t = 0
	while t < fade_in_duration do
		local dt = coroutine.yield()
		t = t + dt
		local current_alpha = Easing.quartic_in_out(t, 0, 0.85, fade_in_duration)
		prompt:set_alpha(current_alpha)
	end
	prompt:set_alpha(0.85)
end

function BLTModsGui:bind_controller_inputs()
	local bindings = {
		{
			callback = callback(self, self, "_on_list_tabs_left"),
			key = Idstring("menu_controller_shoulder_left"),
			label = "",
		},
		{
			callback = callback(self, self, "_on_list_tabs_right"),
			key = Idstring("menu_controller_shoulder_right"),
		},
		{
			callback = callback(self, self, "_on_column_left"),
			key = Idstring("menu_controller_trigger_left"),
		},
		{
			callback = callback(self, self, "_on_column_right"),
			key = Idstring("menu_controller_trigger_right"),
		},
	}
	-- if Network:is_server() then
	-- 	table.insert(bindings, {
	-- 		callback = callback(self, self, "_on_start_raid"),
	-- 		key = Idstring("menu_controller_face_top"),
	-- 	})
	-- end
	self:set_controller_bindings(bindings, true)
	local legend = {
		controller = {
			"menu_legend_back",
			{
				translated_text = managers.localization:get_default_macros().BTN_TOP_L .. " " ..
					self:translate("blt_regular_mods_tab", true),
			},
			{
				translated_text = managers.localization:get_default_macros().BTN_TOP_R .. " " ..
					self:translate("blt_core_mods_tab", true),
			},
			"menu_legend_mission_column",
		},
		keyboard = {
			{
				callback = callback(self, self, "_on_legend_pc_back", nil),
				key = "footer_back",
			},
		},
	}
	-- if Network:is_server() then
	-- 	table.insert(legend.controller, "menu_legend_mission_start_raid")
	-- end
	self:set_legend(legend)
end

function BLTModsGui:_additional_active_controls()
	local res = {
		self._regular_mods_list,
		self._core_mods_list
	}
	for _, btn in ipairs(self._info_buttons) do
		table.insert(res, btn)
	end
	return res
end

function BLTModsGui:_refresh_mod_update_status()
	if not (self._selected_mod and self._mod_update_status) then
		return
	end

	-- mod update status
	local show_mod_update_status
	if self._selected_mod:GetUpdateError() then
		self._mod_update_status:set_text(managers.localization:text("blt_update_mod_error", {
			reason = self._selected_mod:GetUpdateError()
		}))
		self._mod_update_status:set_color(tweak_data.gui.colors.raid_red)
		show_mod_update_status = true
	elseif self._selected_mod:IsCheckingForUpdates() then
		self._mod_update_status:set_text(self:translate("blt_checking_updates"))
		show_mod_update_status = true
	elseif BLT.Downloads:get_pending_downloads_for(self._selected_mod) then
		self._mod_update_status:set_text(managers.localization:text("blt_update_mod_available_short", {
			name = self._selected_mod:GetName()
		}))
	end
	if show_mod_update_status then
		self._mod_update_status:show()
	else
		self._mod_update_status:hide()
	end
end

function BLTModsGui:_on_update_change(update, requires_update, error_reason)
	local mod = update:GetParentMod()
	if mod ~= self._selected_mod then
		return
	end
	log("BLTModsGui:_on_update_change")
	self:_refresh_mod_update_status()
end
