Screenshot = {}

hs.hotkey.bind({ "cmd", "shift" }, "s", function()
	if Screenshot.canvas then
		Screenshot.canvas:delete()
		Screenshot.canvas = nil
		return
	end
	if Screenshot.screencapture then
		hs.alert.show("Already taking a screenshot")
		return
	end
	Screenshot.canvas = hs.canvas.new(hs.screen.primaryScreen():fullFrame().table):show()
	Screenshot.canvas[1] = {
		type = "image",
		image = hs.screen.primaryScreen():snapshot(),
	}
	Screenshot.screencapture = hs.task
		.new("/usr/sbin/screencapture", function()
			if Screenshot.canvas then
				Screenshot.canvas:delete()
				Screenshot.canvas = nil
			end
			Screenshot.screencapture = nil
		end, { "-ci" })
		:start()
end)
