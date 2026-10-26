require("lib/managers/menu/raid_menu/controls/raidguicontrollistitemmenu")

-- Main-menu style list entry (icon, label, red selection marker) as a standalone BLTMenu item,
-- without the RaidGUIControlList around it. Selection is driven by BLTMenu (hover / keyboard).
---@class BLTGUIControlNewMenuButton
---@field new fun(self, parent, params):BLTGUIControlNewMenuButton
BLTGUIControlNewMenuButton = BLTGUIControlNewMenuButton or blt_class(RaidGUIControlListItemMenu)

function BLTGUIControlNewMenuButton:init(parent, params)
	BLTGUIControlNewMenuButton.super.init(self, parent, params, {
		text = params.text,
		icon = params.icon,
		selectable = true,
	})
	self._on_menu_move = params.on_menu_move
	self._enabled = true
end

function BLTGUIControlNewMenuButton:set_selected(value)
	if value then
		if self._enabled then
			self:select(true)
		end
	else
		self:unselect()
	end
end

function BLTGUIControlNewMenuButton:on_mouse_over(x, y)
	self._mouse_inside = true
	if self._enabled then
		self:select(true)
	end
	if self._on_mouse_enter_callback then
		self._on_mouse_enter_callback(self, self._data)
	end
end

function BLTGUIControlNewMenuButton:on_mouse_out(x, y)
	self._mouse_inside = false
	self:unselect()
	if self._on_mouse_exit_callback then
		self._on_mouse_exit_callback(self, self._data)
	end
end

function BLTGUIControlNewMenuButton:on_mouse_released(button)
	if self._enabled then
		BLTGUIControlNewMenuButton.super.on_mouse_released(self, button)
	end
end

function BLTGUIControlNewMenuButton:confirm_pressed(button)
	if self._selected and self._enabled and self._on_click_callback then
		self._on_click_callback(button, self, self._data, true)
		return true
	end
end

function BLTGUIControlNewMenuButton:enabled()
	return self._enabled
end

function BLTGUIControlNewMenuButton:set_enabled(enabled)
	self._enabled = enabled and true or false
	self._item_label:set_color(self._enabled and self.UNSELECTED_COLOR or tweak_data.gui.colors.raid_dark_grey)
end

function BLTGUIControlNewMenuButton:enable()
	self:set_enabled(true)
end

function BLTGUIControlNewMenuButton:disable()
	self:set_enabled(false)
end

function BLTGUIControlNewMenuButton:set_text(text)
	self._item_label:set_text(text)
end
