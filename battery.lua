-- Uses UPower over DBus
-- Originally based on "obvious.battery"
--
-- TODO notification of battery info when widget is clicked
--

local awful = require "awful"
local wibox = require "wibox"
local naughty = require "naughty"
local beautiful = require "beautiful"

--local lgi = require "lgi"
--local up  = lgi.UPowerGlib
local dbus = dbus

local emblem = {
  ["charged"] = "↯",
  ["fully-charged"] = "↯",
  ["full"] = "↯",
  ["high"] = "↯",
  ["discharging"] = "▼",
  ["not connected"] = "▼",
  ["charging"] = "▲",
  ["unknown"] = "?"
}

local M = {}

function M.on_change()
	return awful.spawn.easy_async_with_shell(
		"upower -i $(upower -e |grep battery_) "..
		"|awk '/\\s+(state|percentage):/ {printf \"%s%s;\", $1, $2} END {printf \"\\n\"}'",
		function(line)
			local t = {}
			for k, v in line:gmatch("([^:]+):([^;]+);") do
				t[k] = v
			end
			--naughty.notify{text=line}

			local n = tonumber(t.percentage:match("([%d%.]+)%%"))
			local color = "#900000"
			if n >= 60 then
				color = "#009000"
			elseif n > 30 then
				color = "#909000"
			end

			local status = emblem[t.state or "unknown"] or "???"
			status = '<span color="'..color..'">'..status..'</span>'

			M.widget.markup = " "..status..t.percentage.." "
		end
	)
end

function M._callback(...)
	return M.on_change(...)
end

function M.init()
	M.widget = wibox.widget.textbox()
	M.on_change()

	dbus.request_name("system", "org.freedesktop.UPower.Device")
	dbus.add_match("system", "interface='org.freedesktop.UPower.Device',member='Changed'")
	dbus.connect_signal("org.freedesktop.UPower.Device", M._callback)

	return M.widget
end

--[[
	### Enumerate:
	 $ dbus-send --system --dest=org.freedesktop.UPower --print-reply /org/freedesktop/UPower org.freedesktop.UPower.EnumerateDevices
	
	### Get all properties:
	 $ dbus-send --system --dest=org.freedesktop.UPower --print-reply /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.DBus.Properties.GetAll string:org.freedesktop.UPower.Device
	
	### Get single properties:
	 $ dbus-send --system --dest=org.freedesktop.UPower --print-reply /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.DBus.Properties.Get string:org.freedesktop.UPower.Device string:Percentage
	 $ dbus-send --system --dest=org.freedesktop.UPower --print-reply /org/freedesktop/UPower/devices/battery_BAT1 org.freedesktop.DBus.Properties.Get string:org.freedesktop.UPower.Device string:State
--]]

return M
