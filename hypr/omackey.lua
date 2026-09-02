-- Omackey: macOS-style per-window switcher for Omarchy.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + ESCAPE")

local omackey = "omarchy-shell shell summon omackey.switcher"
local commit = "omarchy-shell -q shell call omackey.switcher commit ''"
local cancel = "omarchy-shell -q shell call omackey.switcher cancel ''"

o.bind("SUPER + TAB", "Next window", omackey .. " '{\"action\":\"forward\"}'")
o.bind("SUPER + SHIFT + TAB", "Previous window", omackey .. " '{\"action\":\"reverse\"}'")
o.bind("SUPER + SUPER_L", nil, commit, { release = true })
o.bind("SUPER + SUPER_R", nil, commit, { release = true })
o.bind("SUPER + ESCAPE", "Cancel window switcher", cancel)

-- Omarchy normally opens its System menu with SUPER+ESCAPE.
o.bind("SUPER + CTRL + ESCAPE", "System menu", "omarchy-menu toggle system")
