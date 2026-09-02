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

local function show_switcher(action)
  return function()
    hl.exec_cmd(omackey .. " '{\"action\":\"" .. action .. "\"}'")
  end
end

o.bind("SUPER + TAB", "Next window", show_switcher("forward"))
o.bind("SUPER + SHIFT + TAB", "Previous window", show_switcher("reverse"))

-- Omarchy normally opens its System menu with SUPER+ESCAPE.
o.bind("SUPER + CTRL + ESCAPE", "System menu", "omarchy-menu toggle system")
