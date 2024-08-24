local State = { __gc = true }
setmetatable(State, State)

function State:__call(path)
	local swp = path .. ".swp"
	local this = {}
	local _state = hs.json.read(path) or {}
	setmetatable(this, {
		__index = function(_, key)
			return _state[key]
		end,
		__newindex = function(_, key, value)
			_state[key] = value
			hs.json.write(_state, swp, true, true)
			os.rename(swp, path)
		end,
		__pairs = function()
			return next, _state, nil
		end,
	})
	return this
end

return State
