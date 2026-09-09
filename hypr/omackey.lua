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
hl.unbind("ALT + LEFT")
hl.unbind("ALT + RIGHT")
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

-- Terminals honor readline/zle's Emacs-style word motions (Alt+B/Alt+F) via
-- shell config regardless of terminal emulator, whereas GTK/Qt/Electron/web
-- text fields use Ctrl+Left/Right for word motion.
local function word_left()
  if active_window_is_terminal() then
    send_shortcut_once("ALT", "B")()
  else
    send_shortcut_once("CTRL", "LEFT")()
  end
end

local function word_right()
  if active_window_is_terminal() then
    send_shortcut_once("ALT", "F")()
  else
    send_shortcut_once("CTRL", "RIGHT")()
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
o.bind("ALT + LEFT", "Word left", word_left)
o.bind("ALT + RIGHT", "Word right", word_right)

local omackey = "omarchy-shell shell summon omackey"

local switcher_namespace = "macos-application-switcher"
local switcher_layers = 0
local switcher_active = false
local pending_exit = nil

local function reset_switcher_submap()
  if hl.get_current_submap() == "omackey" then
    hl.dispatch(hl.dsp.submap("reset"))
  end
end

local function send_switcher_action(action)
  hl.exec_cmd(omackey .. " '{\"action\":\"" .. action .. "\"}'")
end

local function open_switcher(action, scope)
  return function()
    switcher_active = true
    pending_exit = nil

    -- Install the compositor-side release handlers before starting the
    -- asynchronous shell command, so even a very quick Super tap is observed.
    hl.dispatch(hl.dsp.submap("omackey"))

    local scope_json = scope and ',\"scope\":\"' .. scope .. '\"' or ""
    hl.exec_cmd(omackey .. " '{\"action\":\"" .. action .. "\"" .. scope_json .. "}'")
  end
end

local function exit_switcher(action)
  return function()
    -- Restore normal shortcuts synchronously. The shell IPC may take longer,
    -- but the user must never remain trapped in the temporary submap.
    reset_switcher_submap()

    if not switcher_active then
      return
    end

    if switcher_layers > 0 then
      pending_exit = nil
      send_switcher_action(action)
    else
      -- The release beat the asynchronous summon. Wait for the layer before
      -- committing so the exit command cannot overtake the open command.
      pending_exit = action
    end
  end
end

local commit_switcher = exit_switcher("commit")

-- Hyprland emits this raw event before keybind matching. Modifier-only release
-- binds are unreliable in Hyprland 0.55.3+, so observe the physical key state
-- directly. The event uses XKB keycodes (evdev keycode + 8): left/right Super
-- are 133/134, and wl_keyboard reports release as state 0.
hl.on("input.keyboard.key", function(keycode, _, state)
  if switcher_active and state == 0 and (keycode == 133 or keycode == 134) then
    commit_switcher()
  end
end)

hl.on("layer.opened", function(layer)
  if layer.namespace == switcher_namespace then
    switcher_layers = switcher_layers + 1

    if pending_exit then
      local action = pending_exit
      pending_exit = nil
      send_switcher_action(action)
    end
  end
end)

hl.on("layer.closed", function(layer)
  if layer.namespace == switcher_namespace and switcher_layers > 0 then
    switcher_layers = switcher_layers - 1
    if switcher_layers == 0 then
      switcher_active = false
      pending_exit = nil
      reset_switcher_submap()
    end
  end
end)

o.bind("SUPER + TAB", "Next window", open_switcher("forward"))
o.bind("SUPER + SHIFT + TAB", "Previous window", open_switcher("reverse"))
o.bind("SUPER + grave", "Next window in application", open_switcher("forward", "application"))
o.bind("SUPER + SHIFT + grave", "Previous window in application", open_switcher("reverse", "application"))
o.bind("SUPER + LEFT", "Start of line", send_shortcut_once("", "HOME"))
o.bind("SUPER + RIGHT", "End of line", send_shortcut_once("", "END"))
o.bind("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + RETURN", "Terminal", "omarchy-launch-terminal")
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

hl.define_submap("omackey", function()
  -- Navigation stays in-process: these binds only keep Hyprland from running
  -- the normal global actions while allowing the focused QML item to see keys.
  o.bind("SUPER + TAB", "Next window", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + SHIFT + TAB", "Previous window", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + grave", "Next window in application", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + SHIFT + grave", "Previous window in application", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + LEFT", "Select window on left", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + RIGHT", "Select window on right", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + UP", "Select window above", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + DOWN", "Select window below", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + RETURN", "Open selected window", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + SHIFT + RETURN", "Open selected window", hl.dsp.no_op(), { non_consuming = true })
  o.bind("SUPER + ESCAPE", "Cancel window switcher", exit_switcher("cancel"))

  -- Retain compositor release binds as fallbacks. The raw keyboard listener
  -- above is the primary path on Hyprland versions affected by the submap bug.
  o.bind("SUPER + SUPER_L", nil, commit_switcher, { release = true })
  o.bind("SUPER + SUPER_R", nil, commit_switcher, { release = true })

  -- QML cannot cancel Hyprland's compositor-level mouse move/resize actions.
  -- Mark these non-consuming so the button press/release still reaches the
  -- focused QML surface (otherwise Hyprland's bind match swallows clicks on
  -- switcher tiles entirely while Super is held).
  o.bind("SUPER + mouse:272", nil, hl.dsp.no_op(), { mouse = true, non_consuming = true })
  o.bind("SUPER + mouse:273", nil, hl.dsp.no_op(), { mouse = true, non_consuming = true })
end)

-- A configuration reload can recreate this module while the old switcher
-- submap is active. Recover it before accepting any new input.
reset_switcher_submap()

-- Omarchy normally opens its System menu with SUPER+ESCAPE.
o.bind("SUPER + CTRL + ESCAPE", "System menu", "omarchy-menu toggle system")
