local State = hs.loadSpoon("State")

local windows = State("state/windows.json")

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

local hintId = 0

local sinkKeys = {}
local downKeys = {}
local binds = {}

downTap = hs.eventtap
	.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		if downKeys[keyCode] then
			return sinkKeys[keyCode]
		end
		downKeys[keyCode] = true
		print(keyCode, "down")
		local bind = binds[keyCode]
		if bind then
			local sink = bind(event)
			sinkKeys[keyCode] = sink
			return sink
		end
	end)
	:start()

upTap = hs.eventtap
	.new({ hs.eventtap.event.types.keyUp }, function(event)
		local keyCode = event:getKeyCode()
		downKeys[keyCode] = nil
		sinkKeys[keyCode] = nil
	end)
	:start()

local function capslockBind(key, fn)
	local keyCode = hs.keycodes.map[key]
	binds[keyCode] = function(event)
		if not downKeys[CAPS_LOCK] then
			return false
		end
		hintId = hintId + 1
		return fn(event)
	end
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
local function getWindow(windowInfo)
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
		capslockBind(key, function(event)
			local flags = event:getFlags()
			if flags.shift then
				activeProfile = key
				windows._activeProfile = key
				return true
			end
			if flags.alt then
				local window = hs.window.focusedWindow()
				if not window then
					return true
				end
				activeWindows[key] = dumpWindow(window)
				return true
			end

			local windowInfo = activeWindows[key]

			-- That bind isn't set
			if not windowInfo then
				return true
			end

			local window = getWindow(windowInfo)
			if window == false then
				return true
			end

			if not window then
				hs.application.launchOrFocusByBundleID(windowInfo.appId)
				return true
			end

			window:focus()
			activeWindows[key] = dumpWindow(window)

			return true
		end)
	end)(key)
end
