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
						return windows[key]
					end),
					function(key)
						local hasMultiple = false
						for otherKey, otherWindow in pairs(windows) do
							if key ~= otherKey and windows[key].appName == otherWindow.appName then
								hasMultiple = true
								break
							end
						end
						local line = key .. ": " .. windows[key].appName
						if hasMultiple then
							line = line .. " - " .. windows[key].title
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

for _, key in ipairs(KEYS) do
	(function(key)
		capslockBind({ "option" }, key, function()
			local window = hs.window.focusedWindow()
			if not window then
				return
			end
			windows[key] = dumpWindow(window)
		end)
		capslockBind({}, key, function()
			local windowInfo = windows[key]
			if not windowInfo then
				return
			end
			local window
			if windowInfo.appId == "com.microsoft.VSCode" then
				window = hs.window.get(windowInfo.title)
				if not window then
					return
				end
			end
			if not window then
				window = hs.window.get(windowInfo.id)
			end
			if window and window:application():bundleID() == windowInfo.appId then
				window:focus()
				return
			end
			if not window and windowInfo.title then
				window = hs.window.get(windowInfo.title)
			end
			if not window then
				local application = hs.application.get(windowInfo.appId)
				if application then
					window = application:mainWindow()
				end
			end
			if not window then
				hs.application.launchOrFocusByBundleID(windowInfo.appId)
				return
			end
			window:focus()
			windows[key] = dumpWindow(window)
		end)
	end)(key)
end
