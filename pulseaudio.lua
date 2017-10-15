local pulseaudio = {}

local awful   = require "awful"
local gears   = require "gears"
local mouse   = require "mouse"
local wibox   = require "wibox"
local naughty = require "naughty"
local beautiful = require "beautiful"
local shell   = require "shell"


-------------------------------------------------------------------------------
---  CONFIGURATION
-------------------------------------------------------------------------------

-- PulseAudio "sinks" (see `pamixer --list-sinks` or `pactl list [short] sinks`
--
pulseaudio.sinks = {
    {name="alsa_output.pci-0000_00_1b.0.analog-stereo"
    , label="pci"},
    {name="alsa_output.usb-Logitech_Inc_Logitech_USB_Headset_H540_00000000-00.analog-stereo"
    , label="usb"},
}
pulseaudio.default_sink = 1      -- used when shell returns failure
pulseaudio.volume_boost = true   -- allow volumes >100% ?
pulseaudio.volume_step  = 2      -- adjust volume in increments/decrements of 2
pulseaudio.big_volume_step = 5   -- bigger steps when shift is held



-------------------------------------------------------------------------------
---  IMPLEMENTATION
-------------------------------------------------------------------------------

-----------------------------------------------------------------------
---  Initialization.
-----------------------------------------------------------------------

local initialized = false

-- XXX:  Allow the CONFIGURATION settings above to be passed in `t` when
--       `init(t)` is called, so that this file need not be editted when
--       the configuration is changed.
--
-- This function needs to be called *after* `modkey` is set in `rc.lua`
-- and *before* any of the other `pulseaudio` functions are called.
--
function pulseaudio.init(t)
    --- XXX  no workie :(
    local sinkmt = {
        __index = function(t, k)
            if k == "with_id" then
                return function(k)
                    return pulseaudio.call_with_sink(t.name, k)
                end
            end
            return nil
        end
    }
    
    for i, v in ipairs(pulseaudio.sinks) do
        v.index = i
        v._prototype = sinkmt
        setmetatable(v, sinkmt)
    end

    pulseaudio.default_sink = t.default_sink or pulseaudio.sinks[pulseaudio.default_sink]
    pulseaudio.current_sink = pulseaudio.current_sink or pulseaudio.default_sink

    initialized = true
end


-----------------------------------------------------------------------
---  The core functions.
-----------------------------------------------------------------------

--  run pavucontrol and update the volume widget when it exits
--
function pulseaudio.pavucontrol()
    ---  The set_volume() message to awesomewm is now handled in a pavucontrol
    ---  wrapper script in /usr/local/bin/pavucontrol that launches
    ---  /usr/bin/pavucontrol and then pipes the message to awesome-client.
    ---  For this to work properly, /usr/local/bin must be prioritized in
    ---  $PATH over /usr/bin.
    ---
    ---return sh("{ pavucontrol; echo 'set_volume()' |awesome-client; }")

    --return shell.exec "pavucontrol"
    return awful.spawn("pavucontrol", {
        floating  = true,
        tag       = mouse.screen.selected_tag,
        --placement = function(c, ) return awful.placement.align(c, {position="top_right", honor_workarea=true}) end
    }, function(c)
        local w = mouse.screen.workarea
        local n = { x = w.x + w.width - c.width - 2*beautiful.border_width,
                    y = w.y + beautiful.border_width,
                    width = c.width,
                    height = c.height
                  }
        c:geometry(n)

        c:connect_signal("list",    pulseaudio.volume_changed)
        c:connect_signal("focus",   pulseaudio.volume_changed)
        c:connect_signal("unfocus", pulseaudio.volume_changed)
    end)
end

-- Locate a sink object in `pulseaudio.sinks` whose `name` field matches
-- `sink_name` and return that object, else `nil`.
--
function pulseaudio.find_sink_by_name(sink_name)
    for _, v in ipairs(pulseaudio.sinks) do
        if v.name == sink_name then
            return v
        end
    end
    return nil
end

-- Some filters for the output of `pamixer --list-sinks` which are used to
-- collect specific information by `get_sink_info` (below).
--
local _pamixer_list_sinks_1 = " |awk {'print $1'}"
local _pamixer_list_sinks_2 = " |grep -E -m1 -o '\"[^\"]+\"' |head -1"

-- Find a sink whose listing in `pamixer --list-sinks` matches (exact string
-- matching, as with `fgrep(1)`) the string given by `match_me`.  If
-- `match_me` is falsy, then the first sink listed by pamixer will be used.
-- Returns two values:  the numeric ID associated with the sink followed by
-- the sink object from `pulseaudio.sinks` whose `name` matches the listing
-- given by `pamixer`.
--
function pulseaudio.call_with_sink(match_me, k)
    if not match_me then
        match_me = pulseaudio.current_sink and pulseaudio.current_sink.name
    end

    local c
    if match_me then
        c = "pamixer --list-sinks |grep -F -m1 '"..match_me.."'"
    else
        c = "pamixer --list-sinks |grep -E -m1 '^[[:space:]]*[[:digit:]]'"
    end
    return shell.read(c .. _pamixer_list_sinks_1, function(s)
        return shell.read(c .. _pamixer_list_sinks_2, function(n)
            if s:len() < 1 then
                return k(nil)
            end
            s = s:match("%S+")       -- snatch *only* the first "word", if there is one
            n = n:match('"([^"]+)"') -- strip quotation marks

            ---naughty.notify{title=match_me, text=s}
            return k(s, pulseaudio.find_sink_by_name(n))
        end)
    end)
end

--  abbreviation for `pamixer` [1.3.1] <https://github.com/cdemoulins/pamixer>
--
local function _augment(cmd, k)
    local i = cmd:find("-i%s")
    local j = cmd:find("--increase%s")
    local d = cmd:find("-d%s")
    local e = cmd:find("--decrease%s")

    local x = (i or j or d or e) and
                "--allow-boost " or
                ""
    x = pulseaudio.volume_boost and x or ""

    --local s = pulseaudio.get_sink_info()
    return pulseaudio.current_sink.with_id(function(s)
        s = s and ("--sink "..s.." ") or ""
        ---naughty.notify{title='pamixer', text=s}
        return k("pamixer "..s..x..cmd)
    end)
end

pulseaudio.pamixer = shell.wrap(
    function(cmd)
        return _augment(cmd, function(c)
            shell.exec(c)
            -- only call set_volume() when the volume has been set,
            -- or else suffer the infinite loop!!
            local _ = c:find("--get") or pulseaudio.volume_changed()
        end)
    end
)
local pa = pulseaudio.pamixer

pulseaudio.call_pa = function(cmd, k)
    _augment(cmd, function(c)
        shell.read(c, function(out)
            k(out)
            local _ = c:find("--get") or pulseaudio.volume_changed()
        end)
    end)
end


-----------------------------------------------------------------------
---  Utility functions to be used as callbacks.
-----------------------------------------------------------------------

function pulseaudio.inc_sink(n)
    n = n or 1
    return function()
        if pulseaudio.current_sink then
            local i = (pulseaudio.current_sink.index - 1 + n) % #pulseaudio.sinks
            pulseaudio.current_sink = pulseaudio.sinks[i + 1]
            pulseaudio.current_sink.with_id(function(id)
                return id or pulseaudio.next_sink(n)
            end)
        else
            pulseaudio.current_sink = pulseaudio.default_sink
        end
        pulseaudio.volume_changed()
    end
end

pulseaudio.next_sink = pulseaudio.inc_sink(1)
pulseaudio.prev_sink = pulseaudio.inc_sink(-1)

function pulseaudio.inc_volume_by(x)
    return function()
        local p = x or pulseaudio.volume_step or 1
        return pa("-u -i "..(p < 0 and -p or p))
    end
end

function pulseaudio.dec_volume_by(x)
    return function()
        local p = x or pulseaudio.volume_step or 1
        return pa("-u -d "..(p < 0 and -p or p))
    end
end

pulseaudio.inc_volume = pulseaudio.inc_volume_by()
pulseaudio.dec_volume = pulseaudio.dec_volume_by()

function pulseaudio.toggle_mute()
    return pa("-t")
end

function pulseaudio.get_volume(k)
    --return get_mute() and "--" or pa("--get-volume"):match("(%d+)")
    return pulseaudio.get_mute(function(mute)
        if mute then
            return k(" 0")
        else
            return pulseaudio.call_pa("--get-volume", function(vol)
                return k(vol:match("(%d+)"))
            end)
        end
    end)
end

function pulseaudio.get_mute(k)
    return pulseaudio.call_pa("--get-mute", function(mute)
        return k(mute:find("true") == 1)
    end)
end

function pulseaudio.get_emblem(mutep)
    local sink = pulseaudio.current_sink
    ---local label = sink and (sink.label.."("..tostring(sink.index).."/"..tostring(#pulseaudio.sinks)..")" or tostring(sink.index)) or "???"
    local label = sink and (sink.label or tostring(sink.index)) or "???"

    return label..":"..(mutep and "◁×" or "◀»")
end


-- A function that creates naughty notifications based on any changes to the
-- pulseaudio settings caused by calling the function `f`.
--
function pulseaudio.notify(f)
    return function()
        return pulseaudio.get_volume(function(v1)
            return pulseaudio.get_mute(function(m1)
                local s1 = pulseaudio.current_sink
                f()
                return pulseaudio.get_volume(function(v2)
                    return pulseaudio.get_mute(function(m2)
                        local s2 = pulseaudio.current_sink

                        if s2 ~= s1 then
                            naughty.notify {
                                title = "Audio sink",
                                text  = s2.label or tostring(s2.index)
                            }
                        else
                            local emblem = pulseaudio.get_emblem(false)
                            local t, x
                            v1, v2 = tonumber(v1), tonumber(v2)
                            if v2 > v1 then
                                t = emblem.."++";  x = "+"
                            elseif v2 < v1 then
                                t = emblem.."--";  x = "-"
                            end
                            if m2 and m1 ~= m2 then
                                t = pulseaudio.get_emblem(m2).."≠";  x = "="
                            end

                            naughty.notify {
                                title = t,
                                text  = x..v2.."%"
                            }
                        end
                    end)
                end)
            end)
        end)
    end
end


-----------------------------------------------------------------------
---  The volume widget.
-----------------------------------------------------------------------

if not pulseaudio.__volume then
    pulseaudio.__volume = wibox.widget.textbox()
end

function pulseaudio.get_widget()
    pulseaudio.volume_changed()
    return pulseaudio.__volume
end

function pulseaudio.set_widget(widget)
    pulseaudio.__volume = widget
    pulseaudio.__volume:buttons(pulseaudio.buttons())
    pulseaudio.volume_changed()
end

function pulseaudio.volume_changed()
    if not initialized then
        pulseaudio.__volume:set_text("nil")
        return
    end

    return pulseaudio.get_volume(function(v)
        return pulseaudio.get_mute(function(m)
            pulseaudio.__volume:set_text(
                " "..pulseaudio.get_emblem(m)..v.."%"
            )
        end)
    end)
end


-----------------------------------------------------------------------
---  Mouse and key bindings.
-----------------------------------------------------------------------

-- Mouse buttons for the volume widget.
--
function pulseaudio.buttons()
  return gears.table.join(
    awful.button({}       , 1, pulseaudio.next_sink),
    awful.button({}       , 2, pulseaudio.toggle_mute),
    awful.button({}       , 3, pulseaudio.pavucontrol),

    awful.button({}       , 4, pulseaudio.inc_volume),
    awful.button({}       , 5, pulseaudio.dec_volume),

    awful.button({}       , 8, pulseaudio.prev_sink),
    awful.button({}       , 9, pulseaudio.next_sink),

    awful.button({'Shift'}, 1, pulseaudio.next_sink),
    awful.button({'Shift'}, 3, pulseaudio.prev_sink),

    awful.button({'Shift'}, 4, pulseaudio.inc_volume_by(pulseaudio.big_volume_step)),
    awful.button({'Shift'}, 5, pulseaudio.dec_volume_by(pulseaudio.big_volume_step))
  )
end

-- Global key bindings for volume control and sink selection.
--
function pulseaudio.global_keys()
  return gears.table.join(
    awful.key({modkey} , "F10"                 , pulseaudio.pavucontrol),
    awful.key({modkey} , "F11"                 , pulseaudio.prev_sink),
    awful.key({modkey} , "F12"                 , pulseaudio.next_sink),

    awful.key({}       , "XF86AudioMute"       , pulseaudio.toggle_mute),
    awful.key({}       , "XF86AudioRaiseVolume", pulseaudio.inc_volume),
    awful.key({}       , "XF86AudioLowerVolume", pulseaudio.dec_volume),

    awful.key({modkey} , "XF86AudioRaiseVolume", pulseaudio.prev_sink),
    awful.key({modkey} , "XF86AudioLowerVolume", pulseaudio.next_sink),

    awful.key({'Shift'}, "XF86AudioRaiseVolume", pulseaudio.inc_volume_by(pulseaudio.big_volume_step)),
    awful.key({'Shift'}, "XF86AudioLowerVolume", pulseaudio.dec_volume_by(pulseaudio.big_volume_step))
  )
end


-----------------------------------------------------------------------
return pulseaudio
-- vim:ts=8:sts=4:sw=4:et:
