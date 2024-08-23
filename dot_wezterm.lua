local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font_size = 16
config.freetype_load_target = "Light"

config.color_scheme = "Windows 10 (base16)"

return config
