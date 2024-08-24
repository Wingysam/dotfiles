AutoSpotify = {}

AutoSpotify.AUDIO_DEVICE = "dayflower"
AutoSpotify.APPS_THAT_DO_NOT_COUNT = {
	"Roblox",
	"RobloxStudio",
	"OBS",
}

function AutoSpotify.howManyAppsThatDoNotCountAreOpen()
	local count = 0
	for _, app in ipairs(AutoSpotify.APPS_THAT_DO_NOT_COUNT) do
		if hs.application.get(app) then
			count = count + 1
		end
	end
	return count
end

AutoSpotify.menubar = hs.menubar.new()

AutoSpotify.enabled = false
function AutoSpotify.toggle()
	AutoSpotify.enabled = not AutoSpotify.enabled
	AutoSpotify.menubar:setTitle("AutoSpotify " .. (AutoSpotify.enabled and "enabled" or "disabled"))
	if AutoSpotify.enabled then
		AutoSpotify.tap:start()
	else
		AutoSpotify.tap:stop()
	end
end

AutoSpotify.menubar:setClickCallback(AutoSpotify.toggle)

AutoSpotify.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function()
	AutoSpotify.tap:stop()
	if not AutoSpotify.enabled then
		return
	end
	hs.timer.doAfter(1, function()
		if not AutoSpotify.enabled then
			return
		end
		AutoSpotify.enabled = false
		AutoSpotify.toggle()
	end)
	if hs.audiodevice.current().name ~= AutoSpotify.AUDIO_DEVICE then
		return
	end
	hs.task
		.new("/usr/bin/pmset", function(exitCode, stdout)
			if exitCode ~= 0 then
				return
			end
			local lines = hs.fnutils.split(stdout, "\n")
			local sleepLine = hs.fnutils.find(lines, function(line)
				return line:match("^ sleep")
			end)
			local coreaudiodCount = select(2, sleepLine:gsub("coreaudiod", ""))
			local appsThatDoNotCountCount = AutoSpotify.howManyAppsThatDoNotCountAreOpen()
			if coreaudiodCount - appsThatDoNotCountCount <= 0 then
				hs.task
					.new("/usr/bin/osascript", function() end, { "-e", 'tell application "Spotify" to play' })
					:start()
			end
		end, { "-g" })
		:start()
end)

hs.timer.doEvery(1, function()
	AutoSpotify.tap:stop()
	if AutoSpotify.enabled then
		AutoSpotify.tap:start()
	end
end)

AutoSpotify.toggle()
