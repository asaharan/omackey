-- Omackey: macOS-style per-window switcher for Omarchy.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + grave")
hl.unbind("SUPER + SHIFT + grave")
hl.unbind("SUPER + ESCAPE")
hl.unbind("SUPER + W")
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
hl.unbind("SUPER + mouse:272")
hl.unbind("SUPER + mouse:273")

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

local switcher_namespace = "macos-application-switcher"
local switcher_layers = 0
local active_binds = {}

local function clear_active_binds()
  for _, keybind in ipairs(active_binds) do
    keybind:unbind()
  end
  active_binds = {}
end

local function install_default_binds()
  clear_active_binds()
  active_binds = {
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd(omackey .. " '{\"action\":\"forward\"}'"), { description = "Next window" }),
    hl.bind("SUPER + SHIFT + TAB", hl.dsp.exec_cmd(omackey .. " '{\"action\":\"reverse\"}'"), { description = "Previous window" }),
    hl.bind("SUPER + grave", hl.dsp.exec_cmd(omackey .. " '{\"action\":\"forward\",\"scope\":\"application\"}'"), { description = "Next window in application" }),
    hl.bind("SUPER + SHIFT + grave", hl.dsp.exec_cmd(omackey .. " '{\"action\":\"reverse\",\"scope\":\"application\"}'"), { description = "Previous window in application" }),
    hl.bind("SUPER + LEFT", hl.dsp.focus({ direction = "l" }), { description = "Focus on left window" }),
    hl.bind("SUPER + RIGHT", hl.dsp.focus({ direction = "r" }), { description = "Focus on right window" }),
    hl.bind("SUPER + UP", hl.dsp.focus({ direction = "u" }), { description = "Focus on above window" }),
    hl.bind("SUPER + DOWN", hl.dsp.focus({ direction = "d" }), { description = "Focus on below window" }),
    hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("omarchy-launch-terminal"), { description = "Terminal" }),
    hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd("omarchy-launch-browser"), { description = "Browser" }),
    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { description = "Move window", mouse = true }),
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { description = "Resize window", mouse = true }),
  }
end

local function install_switcher_binds()
  clear_active_binds()
  active_binds = {
    hl.bind("SUPER + TAB", hl.dsp.no_op(), { description = "Next window", non_consuming = true }),
    hl.bind("SUPER + SHIFT + TAB", hl.dsp.no_op(), { description = "Previous window", non_consuming = true }),
    hl.bind("SUPER + grave", hl.dsp.no_op(), { description = "Next window in application", non_consuming = true }),
    hl.bind("SUPER + SHIFT + grave", hl.dsp.no_op(), { description = "Previous window in application", non_consuming = true }),
    hl.bind("SUPER + LEFT", hl.dsp.no_op(), { description = "Select window on left", non_consuming = true }),
    hl.bind("SUPER + RIGHT", hl.dsp.no_op(), { description = "Select window on right", non_consuming = true }),
    hl.bind("SUPER + UP", hl.dsp.no_op(), { description = "Select window above", non_consuming = true }),
    hl.bind("SUPER + DOWN", hl.dsp.no_op(), { description = "Select window below", non_consuming = true }),
    hl.bind("SUPER + RETURN", hl.dsp.no_op(), { description = "Open selected window", non_consuming = true }),
    hl.bind("SUPER + SHIFT + RETURN", hl.dsp.no_op(), { description = "Open selected window", non_consuming = true }),
    hl.bind("SUPER + mouse:272", hl.dsp.no_op(), { mouse = true }),
    hl.bind("SUPER + mouse:273", hl.dsp.no_op(), { mouse = true }),
  }
end

hl.on("layer.opened", function(layer)
  if layer.namespace == switcher_namespace then
    switcher_layers = switcher_layers + 1
    if switcher_layers == 1 then
      install_switcher_binds()
    end
  end
end)

hl.on("layer.closed", function(layer)
  if layer.namespace == switcher_namespace and switcher_layers > 0 then
    switcher_layers = switcher_layers - 1
    if switcher_layers == 0 then
      install_default_binds()
    end
  end
end)

install_default_binds()

-- Omarchy normally opens its System menu with SUPER+ESCAPE.
o.bind("SUPER + CTRL + ESCAPE", "System menu", "omarchy-menu toggle system")
