-- Omackey: macOS-style per-window switcher for Omarchy.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + ESCAPE")
hl.unbind("SUPER + W")

local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- macOS-style window and in-app close shortcuts.
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Close in app", send_shortcut_once("CTRL", "W"))

local omackey = "omarchy-shell shell summon omackey.switcher"
local commit = "omarchy-shell -q shell call omackey.switcher commit ''"
local cancel = "omarchy-shell -q shell call omackey.switcher cancel ''"

local function show_switcher(action)
  return function()
    hl.exec_cmd(omackey .. " '{\"action\":\"" .. action .. "\"}'")
    hl.dispatch(hl.dsp.submap("omackey"))
  end
end

local function leave_switcher(command)
  return function()
    hl.exec_cmd(command)
    hl.dispatch(hl.dsp.submap("reset"))
  end
end

o.bind("SUPER + TAB", "Next window", show_switcher("forward"))
o.bind("SUPER + SHIFT + TAB", "Previous window", show_switcher("reverse"))

-- While the switcher is active, this submap suppresses Omarchy's global
-- SUPER+mouse move/resize bindings. Unbound pointer events reach the overlay.
hl.define_submap("omackey", function()
  o.bind("SUPER + TAB", "Next window", omackey .. " '{\"action\":\"forward\"}'")
  o.bind("SUPER + SHIFT + TAB", "Previous window", omackey .. " '{\"action\":\"reverse\"}'")
  o.bind("SUPER + SUPER_L", nil, leave_switcher(commit), { release = true })
  o.bind("SUPER + SUPER_R", nil, leave_switcher(commit), { release = true })
  o.bind("SUPER + ESCAPE", "Cancel window switcher", leave_switcher(cancel))
end)

-- Omarchy normally opens its System menu with SUPER+ESCAPE.
o.bind("SUPER + CTRL + ESCAPE", "System menu", "omarchy-menu toggle system")
