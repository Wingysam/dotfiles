-- When I connect my Bluetooth headset or AirPods, macOS tries to change my
-- audio input device to it. I never want to use these inputs because it
-- ruins output quality. I would rather use my dedicated mic or the
-- laptop's built-in mic than the headset mic.

local priorities = {
	"HyperX Quadcast",
	"HyperX SoloCast",
	"MacBook Pro Microphone",
}

local function getPreferredDevice()
	local devices = hs.audiodevice.allInputDevices()
	for _, priority in ipairs(priorities) do
		for _, device in ipairs(devices) do
			if device:name() == priority then
				return device
			end
		end
	end
	return nil
end

local function setInputMethod()
	local device = getPreferredDevice()
	if not device then
		warn("No device found to set input method")
		return
	end
	print("Setting default input device to " .. device:name())
	device:setDefaultInputDevice()
end

hs.audiodevice.watcher.setCallback(setInputMethod)
hs.audiodevice.watcher.start()
setInputMethod()
