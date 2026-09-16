-- mise bootstrap links shared.lua and the selected host as host.lua alongside this.
local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hyprDir = configHome .. "/hypr/"
dofile(hyprDir .. "shared.lua")
dofile(hyprDir .. "host.lua")

-- For Noctalia Color templates
require("noctalia").apply_theme()
