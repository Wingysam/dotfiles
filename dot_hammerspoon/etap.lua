local downKeys = {}

eventTap = hs.eventtap
	.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		if downKeys[keyCode] then
			return
		end
		downKeys[keyCode] = true
		print(keyCode .. " down")
	end)
	:start()

et2 = hs.eventtap
	.new({ hs.eventtap.event.types.keyUp }, function(event)
		local keyCode = event:getKeyCode()
		downKeys[keyCode] = nil
		print(keyCode .. " up")
	end)
	:start()
