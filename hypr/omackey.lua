-- Omackey: macOS-style per-window switcher for Omarchy.
hl.config({
  binds = {
    -- Keep directional focus useful when a maximized/fullscreen window hides
    -- the other windows on its workspace.
    movefocus_cycles_fullscreen = true,
  },
})

hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + grave")
hl.unbind("SUPER + SHIFT + grave")
hl.unbind("SUPER + ESCAPE")
hl.unbind("SUPER + Q")
hl.unbind("SUPER + W")
hl.unbind("SUPER + T")
hl.unbind("SUPER + F")
hl.unbind("SUPER + S")
hl.unbind("SUPER + O")
hl.unbind("SUPER + P")
hl.unbind("SUPER + L")
hl.unbind("SUPER + G")
hl.unbind("SUPER + BACKSPACE")
hl.unbind("SUPER + SHIFT + N")
hl.unbind("SUPER + SHIFT + G")
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

local function send_shortcut_sequence(shortcuts)
  return function()
    local function send_next(index)
      local shortcut = shortcuts[index]
      if not shortcut then
        return
      end

      hl.dispatch(hl.dsp.send_key_state({ mods = shortcut.mods, key = shortcut.key, state = "down" }))
      hl.timer(function()
        hl.dispatch(hl.dsp.send_key_state({ mods = shortcut.mods, key = shortcut.key, state = "up" }))
        hl.timer(function()
          send_next(index + 1)
        end, { timeout = 25, type = "oneshot" })
      end, { timeout = 50, type = "oneshot" })
    end

    send_next(1)
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function delete_to_start_of_line()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL", "U")()
  else
    send_shortcut_sequence({
      { mods = "SHIFT", key = "HOME" },
      { mods = "", key = "BACKSPACE" },
    })()
  end
end

-- macOS-style window navigation and in-app shortcuts.
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Close in app", send_shortcut_once("CTRL", "W"))
o.bind("CTRL + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("CTRL + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + T", "New tab", send_shortcut_once("CTRL", "T"))
o.bind("SUPER + SHIFT + T", "Reopen closed tab", send_shortcut_once("CTRL + SHIFT", "T"))
o.bind("SUPER + A", "Select all", send_shortcut_once("CTRL", "A"))
o.bind("SUPER + Z", "Undo", send_shortcut_once("CTRL", "Z"))
o.bind("SUPER + SHIFT + Z", "Redo", send_shortcut_once("CTRL + SHIFT", "Z"))
o.bind("SUPER + F", "Find", send_shortcut_once("CTRL", "F"))
o.bind("SUPER + S", "Save", send_shortcut_once("CTRL", "S"))
o.bind("SUPER + O", "Open", send_shortcut_once("CTRL", "O"))
o.bind("SUPER + P", "Print", send_shortcut_once("CTRL", "P"))
o.bind("SUPER + N", "New window", send_shortcut_once("CTRL", "N"))
o.bind("SUPER + SHIFT + N", "New private window", send_shortcut_once("CTRL + SHIFT", "N"))
o.bind("SUPER + R", "Reload", send_shortcut_once("CTRL", "R"))
o.bind("SUPER + L", "Focus location", send_shortcut_once("CTRL", "L"))
o.bind("SUPER + BRACKETLEFT", "Back", send_shortcut_once("ALT", "LEFT"))
o.bind("SUPER + BRACKETRIGHT", "Forward", send_shortcut_once("ALT", "RIGHT"))
o.bind("SUPER + G", "Next match", send_shortcut_once("CTRL", "G"))
o.bind("SUPER + SHIFT + G", "Previous match", send_shortcut_once("CTRL + SHIFT", "G"))
o.bind("SUPER + BACKSPACE", "Delete to start of line", delete_to_start_of_line)

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
    hl.bind("SUPER + LEFT", send_shortcut_once("", "HOME"), { description = "Start of line" }),
    hl.bind("SUPER + RIGHT", send_shortcut_once("", "END"), { description = "End of line" }),
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
