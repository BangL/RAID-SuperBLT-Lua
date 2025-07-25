---@class BLTModManager : BLTModule
---@field new fun(self):BLTModManager
BLTModManager = blt_class(BLTModule)
BLTModManager.__type = "BLTModManager"

function BLTModManager:init()
	---@diagnostic disable-next-line: undefined-field
	BLTModManager.super.init(self)
end

---Returns all mods managed by BLT
---@return BLTMod[] @Table of mods
function BLTModManager:Mods()
	return self.mods
end

---Returns the mod with the given name
---@param name string @The name of the mod
---@return BLTMod? @The mod instance, or `nil` if not found
function BLTModManager:GetModByName(name)
	for _, mod in pairs(self:Mods()) do
		if mod:GetName() == name then
			return mod
		end
	end
end

---Returns the mod with the given ID
---@param id string @The ID of the mod
---@return BLTMod? @The mod instance, or `nil` if not found
function BLTModManager:GetMod(id)
	for _, mod in ipairs(self:Mods()) do
		if mod:GetId() == id then
			return mod
		end
	end
end

---Returns the mod of which the given file is a part of
---@param file string @The path (relative to payday2_win32_release.exe) of the file
---@return BLTMod? @The mod instance, or `nil` if not found
function BLTModManager:GetModOwnerOfFile(file)
	for _, mod in pairs(self:Mods()) do
		if string.find(file, mod:GetPath(), 1, true) == 1 then
			return mod
		end
	end
end

function BLTModManager:SetModsList(mods_list)
	-- Set mods
	self.mods = mods_list

	-- Check saved mod data
	local mods = BLT.save_data.mods
	if mods then
		for i, mod in ipairs(self.mods) do
			if mods[mod:GetId()] then
				local data = mods[mod:GetId()]

				mod:SetEnabled(data.enabled, true)
				mod:SetSafeModeEnabled(data.safe)

				local updates = data.updates
				if updates then
					for update_id, enabled in pairs(updates) do
						local update = mod:GetUpdate(update_id)
						if update then
							update:SetEnabled(enabled)
						end
					end
				end
			end
		end
	end

	-- Post init mods
	for _, mod in pairs(self.mods) do
		mod:PostInit()
	end

	-- Setup mods
	for i, mod in ipairs(self.mods) do
		mod:Setup()
	end
end

function BLTModManager:IsExcludedDirectory(directory)
	return BLTModManager.Constants.ExcludedModDirectories[directory]
end

--------------------------------------------------------------------------------
-- Autoupdates

function BLTModManager:RunAutoCheckForUpdates()
	-- Don't run the autocheck twice
	if self._has_checked_for_updates then
		return
	end
	self._has_checked_for_updates = true

	call_on_next_update(callback(self, self, "_RunAutoCheckForUpdates"))
end

function BLTModManager:_RunAutoCheckForUpdates()
	-- Place a notification that we're checking for autoupdates
	if BLT.Notifications then
		self._updates_notification = BLT.Notifications:add_notification({
			title = managers.localization:text("blt_checking_updates"),
			text = managers.localization:text("blt_checking_updates_help"),
			icon = "guis/blt/updates",
			color = Color.white,
			priority = 1000
		})
	end

	-- Start checking all enabled mods for updates
	local count = 0
	for _, mod in ipairs(self:Mods()) do
		for _, update in ipairs(mod:GetUpdates()) do
			if update:IsEnabled() then
				update:CheckForUpdates(callback(self, self, "clbk_got_update"))
				count = count + 1
			end
		end
	end

	-- -- Remove notification if not getting updates
	if count < 1 and self._updates_notification then
		BLT.Notifications:remove_notification(self._updates_notification)
		self._updates_notification = nil
	end
end

function BLTModManager:clbk_got_update(update, required, reason)
	-- Add the pending download if required
	if required then
		BLT.Downloads:add_pending_download(update)
	end

	-- Check if any mods are still updating
	local still_checking = false
	for _, mod in ipairs(self:Mods()) do
		if mod:IsCheckingForUpdates() then
			still_checking = true
			break
		end
	end

	if not still_checking then
		-- Remove the old notification
		if self._updates_notification then
			BLT.Notifications:remove_notification(self._updates_notification)
			self._updates_notification = nil
		end

		-- Add notification if we need updates
		if table.size(BLT.Downloads:pending_downloads()) > 0 then
			self._updates_notification = BLT.Notifications:add_notification({
				title = managers.localization:text("blt_checking_updates_required"),
				text = managers.localization:text("blt_checking_updates_required_help"),
				icon = "guis/blt/updates",
				color = Color.white,
				priority = 1000
			})
		else
			self._updates_notification = BLT.Notifications:add_notification({
				title = managers.localization:text("blt_checking_updates_none_required"),
				text = managers.localization:text("blt_checking_updates_none_required_help"),
				icon = "guis/blt/updates",
				color = Color.white,
				priority = 0
			})
		end
	end
end

Hooks:Add("BLTOnSaveData", "BLTOnSaveData.BLTModManager", function(save_data)
	save_data.mods = {}

	local path = BLTModManager.Constants:ModManagerWrenDisabledModsFile()

	-- Save a Wren-readable list of disabled mods - it doesn't have a JSON parser so it
	-- can't load our normal file, and it needs to know what's enabled before any Lua code runs.
	local wren_file = io.open(path, "wb")

	if not wren_file then
		BLT:Log(LogLevel.ERROR, "Can't read " .. path)
		return
	end

	for _, mod in pairs(BLT.Mods:Mods()) do
		-- Save mod updates enabled data
		local updates = {}
		for _, update in pairs(mod:GetUpdates()) do
			updates[update:GetId()] = update:IsEnabled()
		end

		save_data.mods[mod:GetId()] = {
			enabled = mod:IsEnabled(),
			safe = mod:IsSafeModeEnabled(),
			updates = updates
		}

		if not mod:IsEnabled() then
			wren_file:write(mod.path .. "supermod.xml" .. "\n")
		end
	end

	wren_file:close()
end)

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

BLTModManager.Constants = BLTModManager.Constants or {
	["mods_directory"] = "mods/",
	["lua_base_directory"] = "base/",
	["downloads_directory"] = "downloads/",
	["logs_directory"] = "logs/",
	["saves_directory"] = "saves/"
}
BLTModManager.Constants.ExcludedModDirectories = {
	["logs"] = true,
	["saves"] = true,
	["downloads"] = true
}
BLTModManager.Constants.required_script_global = "RequiredScript"
BLTModManager.Constants.mod_path_global = "ModPath"
BLTModManager.Constants.logs_path_global = "LogsPath"
BLTModManager.Constants.save_path_global = "SavePath"
BLTModManager.Constants.mod_instance_global = "ModInstance"

BLTModManager.Constants.lua_mods_menu_id = "blt_mods_new"
BLTModManager.Constants.lua_mod_options_menu_id = "blt_options"

function BLTModManager.Constants:ModsDirectory()
	return self["mods_directory"]
end

function BLTModManager.Constants:BaseDirectory()
	return self["mods_directory"] .. self["lua_base_directory"]
end

function BLTModManager.Constants:DownloadsDirectory()
	return self["mods_directory"] .. self["downloads_directory"]
end

function BLTModManager.Constants:LogsDirectory()
	return self["mods_directory"] .. self["logs_directory"]
end

function BLTModManager.Constants:SavesDirectory()
	return self["mods_directory"] .. self["saves_directory"]
end

function BLTModManager.Constants:ModManagerSaveFile()
	return self:SavesDirectory() .. "blt_data.txt"
end

function BLTModManager.Constants:ModManagerWrenDisabledModsFile()
	return self:SavesDirectory() .. "blt_wren_disabled_mods.txt"
end

function BLTModManager.Constants:LuaModsMenuID()
	return self["lua_mods_menu_id"]
end

function BLTModManager.Constants:LuaModOptionsMenuID()
	return self["lua_mod_options_menu_id"]
end

-- Backwards compatibility
BLTModManager.Constants._lua_mods_menu_id = BLTModManager.Constants.lua_mods_menu_id
BLTModManager.Constants._lua_mod_options_menu_id = BLTModManager.Constants.lua_mod_options_menu_id
