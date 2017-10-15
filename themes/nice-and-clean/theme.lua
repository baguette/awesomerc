-- Nice and Clean awesome theme
-- By Blazeix, based off of ghost1227's openbox theme.
--local gfs          = require "gears.filesystem"
local theme_assets = require "beautiful.theme_assets"
local gears        = require "gears"

local theme = {}
theme.theme_dir     = "~/.config/awesome/themes/nice-and-clean"

--theme.font          = "Fixed SemiCondensed 9"
--theme.font          = "PragmataPro:size=8:antialias=false"
theme.font          = "sans 8"
theme.font_mono     = "Input Mono Compressed Light 8"

theme.bg_normal     = "#222222"
theme.bg_focus      = "#d8d8d8"
theme.bg_urgent     = "#d02e54"
theme.bg_minimize   = "#444444"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#cccccc"
theme.fg_focus      = "#000000"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = "#ffffff"

theme.useless_gap   = 0
theme.border_width  = 2
theme.border_normal = theme.bg_minimize
theme.border_focus  = theme.bg_urgent
theme.border_marked = "#91231c"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- prompt_[fg|bg|fg_cursor|bg_cursor|font]
-- hotkeys_[bg|fg|border_width|border_color|shape|opacity|modifiers_fg|label_bg|label_fg|group_margin|font|description_font]
-- Example:
--theme.taglist_bg_focus = "#ff0000"
theme.taglist_bg_urgent        = theme.bg_urgent
theme.taglist_fg_urgent        = theme.fg_urgent

theme.tasklist_bg_urgent       = theme.bg_urgent
theme.tasklist_fg_urgent       = theme.fg_urgent

theme.prompt_font              = theme.font_mono

theme.hotkeys_font             = theme.font_mono
theme.hotkeys_description_font = theme.font

theme.tooltip_bg_color         = "#d8d82e"
theme.tooltip_fg_color         = "#2e2e1c"
theme.tooltip_border_color     = theme.tooltip_fg_color
theme.tooltip_border_width     = theme.border_width

-- Generate taglist squares:
local taglist_square_size = 6
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size, theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size, theme.fg_normal
)

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]
theme.notification_font         = theme.font
theme.notification_bg           = theme.bg_focus
theme.notification_fg           = theme.border_normal
theme.notification_border_color = theme.border_normal
theme.notification_border_width = theme.border_width
theme.notification_shape        = function(cr, w, h)
    return gears.shape.partially_rounded_rect(
        cr, w, h,                     -- Cairo context, width, height,
        false, false, false, true,    -- topleft, topright, botright, botleft,
        nil                           -- radius
    )
end
function theme.override_notification_config(config)
    config.presets.low.timeout           = 12
    config.presets.low.bg                = theme.bg_normal
    config.presets.low.fg                = theme.fg_normal

    config.presets.critical.bg           = theme.bg_urgent
    config.presets.critical.fg           = theme.fg_urgent
    config.presets.critical.border_color = theme.fg_urgent

    config.defaults.timeout              = 0
    config.defaults.border_width         = theme.notification_border_width
end

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = theme.theme_dir .. "/submenu.png"
theme.menu_height = 15
theme.menu_width  = 100

-- Define the image to load
theme.wallpaper = theme.theme_dir .. "/background.jpg"

theme.tasklist_floating_icon = theme.theme_dir .. "/tasklist/floatingw.png"

theme.titlebar_close_button_normal = theme.theme_dir .. "/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = theme.theme_dir .. "/titlebar/close_focus.png"

theme.titlebar_ontop_button_normal_inactive = theme.theme_dir .. "/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = theme.theme_dir .. "/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = theme.theme_dir .. "/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = theme.theme_dir .. "/titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive = theme.theme_dir .. "/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = theme.theme_dir .. "/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = theme.theme_dir .. "/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = theme.theme_dir .. "/titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive = theme.theme_dir .. "/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = theme.theme_dir .. "/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = theme.theme_dir .. "/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = theme.theme_dir .. "/titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = theme.theme_dir .. "/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = theme.theme_dir .. "/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = theme.theme_dir .. "/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = theme.theme_dir .. "/titlebar/maximized_focus_active.png"


-- You can use your own layout icons like this:
theme.layout_fairh = theme.theme_dir .. "/layouts/fairhw.png"
theme.layout_fairv = theme.theme_dir .. "/layouts/fairvw.png"
theme.layout_floating  = theme.theme_dir .. "/layouts/floatingw.png"
theme.layout_magnifier = theme.theme_dir .. "/layouts/magnifierw.png"
theme.layout_max = theme.theme_dir .. "/layouts/maxw.png"
theme.layout_fullscreen = theme.theme_dir .. "/layouts/fullscreenw.png"
theme.layout_tilebottom = theme.theme_dir .. "/layouts/tilebottomw.png"
theme.layout_tileleft   = theme.theme_dir .. "/layouts/tileleftw.png"
theme.layout_tile = theme.theme_dir .. "/layouts/tilew.png"
theme.layout_tiletop = theme.theme_dir .. "/layouts/tiletopw.png"
theme.layout_spiral  = theme.theme_dir .. "/layouts/spiralw.png"
theme.layout_dwindle = theme.theme_dir .. "/layouts/dwindlew.png"

--theme.awesome_icon = theme.theme_dir .. "/awesome16.png"
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height, theme.bg_urgent, theme.bg_normal
)

theme.icon_theme = "/usr/share/icons/breeze"

return theme
-- vim:ts=8:sts=4:sw=4:et:
