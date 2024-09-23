--[[
    Taran's Wezterm Configuration File.
    Re-written on 23/09/24 for more clarity and added fun.
--]]

local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}

-- Try to default to the config builder if possible
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- Changing the main options
-- I like ChallengerDeep personally, but can be changed here too.
-- Change default_prog to your executable:
-- - pwsh || cmd || fish || bash || zsh

config.default_prog = { 'pwsh' }
config.color_scheme = "ChallengerDeep"
config.font_size = 14.0

-- Tabbing & custom tab bar
-- I personally prefer no tab bar as I have a top bar with the info I would need
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Window properties
config.window_background_opacity = 0.95
config.text_background_opacity = 0.8
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.scrollback_lines = 5000
config.enable_scroll_bar = false

config.max_fps = 165

-- Setting panes to dim if inactive 
config.inactive_pane_hsb = {
    saturation = 0.6,
    brightness = 0.4
}

-- Configuring the leader key to C-a
-- Leader is pressing C-a then another key for something to happen (within the timeout in ms)
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 5000}

config.keys = {
    -- LEADER+c :: Copy mode enabled 
    { key = "c", mods = "LEADER", action = act.ActivateCopyMode },

    -- Pane bindings
    { key = "/", mods = "LEADER", action = act.SplitHorizontal { domain = "CurrentPaneDomain"} },
    { key = "\\", mods = "LEADER", action = act.SplitVertical { domain = "CurrentPaneDomain"} },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane { confirm = true } },
    -- For navigating the panes, this is what I am used to and I'm pretty sure it's the default anyways
    { key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action{ActivatePaneDirection="Left"} },
    { key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action{ActivatePaneDirection="Right"} },
    { key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action{ActivatePaneDirection="Down"} },
    { key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action{ActivatePaneDirection="Up"} },

    -- Maximise the current pane, keeping the others in the background,
    -- same key to minimise and return back to normal, hence the 'toggle'
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    -- Rotate the panes (Counter/Clock)wise
    { key = "n", mods = "LEADER", action = act.RotatePanes 'Clockwise' },
    { key = "m", mods = "LEADER", action = act.RotatePanes 'CounterClockwise' }
}

-- Uncomment this for a pretty cool Wezterm bar at the bottom
-- -- using a terminal bar at the bottom for info
-- local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
-- bar.apply_to_config(
--     config,
--     {
--         position = "top",
--         max_width = 20,
        
--         enabled_modules = {
--             username = true,
--             clock = true,
--             workspace = false,
--             pane = false,
--             hostname = false,
--             cwd = false -- cwd->current working directory
--         }
--     }
-- )

return config
