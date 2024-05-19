-- Taran's WezTerm config!

local wezterm = require 'wezterm'
local muz = wezterm.mux
local act = wezterm.action

local config = {}

-- if a new version, then use the new method
-- else then default to the above config = {}
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- assigning the different configurations
config.default_prog = { 'pwsh' }
config.color_scheme = "ChallengerDeep"
config.use_fancy_tab_bar = true
-- ctrl+shift+t for a new tab
config.hide_tab_bar_if_only_one_tab = true
-- change the window opacity here, 1 is nice, but .9 is also nice
config.window_background_opacity = 0.95
config.text_background_opacity = 0.8
config.adjust_window_size_when_changing_font_size = false


-- terminal splitting
config.leader = {
    key = 'a',
    mods = "CTRL",
    timeout_milliseconds = 1000
}

config.keys = {
    -- This will create a new split and run your default program inside it
    {
        -- CTRL+SHIFT+ALT+" will split the window VERTICALLY
        key = '"',
        mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
        key = "=",
        mods = "CTRL",
        action = wezterm.action.IncreaseFontSize
    },
    {
        key = "-",
        mods = "CTRL",
        action = wezterm.action.DecreaseFontSize
    },
}

return config
