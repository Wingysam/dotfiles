local State = hs.loadSpoon("State")

local windows = State("state/windows.json")
local capslockBinds = {}

local function characters(string)
	local characters = {}
	for character in string:gmatch(".") do
		table.insert(characters, character)
	end
	return characters
end

local CAPS_LOCK = 102
local KEYS = characters("1234567890qwertyuiopasdfghjklzxcvbnm")

local activeProfile = windows._activeProfile or "1"
local activeWindows = {}
setmetatable(activeWindows, {
	__index = function(_, key)
		return windows[activeProfile .. "/" .. key]
	end,
	__newindex = function(_, key, value)
		windows[activeProfile .. "/" .. key] = value
	end,
})

local function haveMultipleOfApp(appName)
	local count = 0
	for key, window in pairs(windows) do
		if string.sub(key, 1, #activeProfile + 1) == activeProfile .. "/" then
			if window.appName == appName then
				count = count + 1
				if count > 1 then
					return true
				end
			end
		end
	end
	return false
end

local hintId = 0
local alertUuid
hs.hotkey.bind({}, CAPS_LOCK, function()
	local thisHintId = hintId + 1
	hintId = thisHintId
	hs.timer.doAfter(1, function()
		if hintId == thisHintId then
			local message = table.concat(
				hs.fnutils.map(
					hs.fnutils.filter(KEYS, function(key)
						return activeWindows[key]
					end),
					function(key)
						local line = key .. ": " .. activeWindows[key].appName
						if haveMultipleOfApp(activeWindows[key].appName) then
							line = line .. " - " .. activeWindows[key].title
						end
						return line
					end
				),
				"\n"
			)
			alertUuid = hs.alert.show(message, {
				radius = 0,
				strokeWidth = 8,
				fadeInDuration = 0,
				fadeOutDuration = 0,
			}, true)
		end
	end)
	for _, bind in ipairs(capslockBinds) do
		bind:enable()
	end
end, function()
	hintId = hintId + 1
	if alertUuid then
		hs.alert.closeSpecific(alertUuid)
		alertUuid = nil
	end
	for _, bind in ipairs(capslockBinds) do
		bind:disable()
	end
end)

local function capslockBind(modifiers, key, fn)
	local bind = hs.hotkey.new(modifiers, key, function()
		hintId = hintId + 1
		fn()
	end)
	table.insert(capslockBinds, bind)
end

local function dumpWindow(window)
	local title = window:title()
	if title == "" then
		title = nil
	end
	return {
		id = window:id(),
		title = title,
		appId = window:application():bundleID(),
		appName = window:application():title(),
	}
end

local STABLE_TITLES = {
	["dom.microsoft.VSCode"] = true,
}
-- Returns nil if we can't find the window to open
-- Returns false if we shouldn't do anything
function getWindow(windowInfo)
	-- I run several instances of some apps
	-- that have the same bundle ID, and the IDs swap around when I reboot.
	-- I configure them to have the same title, so I can use that to identify them.
	-- In those cases, if there's not a window with an identical title,
	-- I don't want to do anything.
	if STABLE_TITLES[windowInfo.appId] then
		return hs.window.get(windowInfo.title) or false
	end

	-- The IDs all shuffle around when I reboot.
	-- I can't use the title to identify them because the titles change as I use the apps.
	-- (for example, the title of Firefox's window changes as I switch tabs or switch pages)
	-- I can't use the app ID to identify them because I run several instances of some apps.
	-- So I use the ID if the app ID still matches.
	-- This is imperfect, so I use the STABLE_TITLES table for
	-- the apps where I have several instances with stable titles.
	do
		local window = hs.window.get(windowInfo.id)
		if window and window:application():bundleID() == windowInfo.appId then
			return window
		end
	end

	-- If we don't have one with the same ID (because we rebooted), we try to find it by title.
	-- It doesn't work perfectly for apps that have unstable titles.
	if windowInfo.title then
		local window = hs.window.get(windowInfo.title)
		if window then
			return window
		end
	end

	-- If there isn't a window with the same ID or title, we try to find one from the same app.
	-- If you have a few Firefox windows open or something it'll just get one of them.
	local application = hs.application.get(windowInfo.appId)
	if application then
		local window = application:mainWindow()
		if window then
			return window
		end
	end

	return
end

for _, key in ipairs(KEYS) do
	(function(key)
		capslockBind({ "shift" }, key, function()
			activeProfile = key
			windows._activeProfile = key
		end)
		capslockBind({ "option" }, key, function()
			local window = hs.window.focusedWindow()
			if not window then
				return
			end
			activeWindows[key] = dumpWindow(window)
		end)
		capslockBind({}, key, function()
			local windowInfo = activeWindows[key]

			-- That bind isn't set
			if not windowInfo then
				return
			end

			local window = getWindow(windowInfo)
			if window == false then
				return
			end

			if not window then
				hs.application.launchOrFocusByBundleID(windowInfo.appId)
				return
			end

			window:focus()
			activeWindows[key] = dumpWindow(window)
		end)
	end)(key)
end
