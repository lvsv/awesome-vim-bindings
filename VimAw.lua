local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local utils = require("utils")
local dbg = require("dbg")

local VimAw = {}

-- Informative textbox showing actual mode
VimAw.modeBox = wibox.widget.textbox()

-- Modes definition
local NORMAL_MODE = "NORMAL"
local INSERT_MODE = "INSERT"

local actualMode = NORMAL_MODE

local function changeMode(mode)
    actualMode = mode
    VimAw.modeBox:set_text("[--" .. mode .. "--]")
end

WIN_BORDER_ACTIVE_INSERT_MODE = "#00C000"
WIN_BORDER_ACTIVE_NORMAL_MODE = "#ff0d11"
WIN_BORDER_SIZE = 3


-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.border_width = WIN_BORDER_SIZE
beautiful.border_focus = WIN_BORDER_ACTIVE_NORMAL_MODE


local function redrawBorders(color)
    local c = awful.client.next(0)
    beautiful.border_focus = color
    if c then client.emit_signal("focus", c) end
end


-- TODO-X use VimAw prefix
function insertMode()
    changeMode(INSERT_MODE)
    redrawBorders(WIN_BORDER_ACTIVE_INSERT_MODE)
    keygrabber.stop()
end


require("actions")



-- Constants
local END = 0
local START = 1
local READ_NEXT = 2
local COMPLETE = 3

local status = START;
local cmdCount = 0;

-- Buffer for cmds
local cmd = ""


-- Reset automat state
local function reset()
    status = START
    cmdCount = 0
    cmd = ""
end


-- Automat
local function doAction(key)
    while status ~= END do
        -- READY STATUS - reading the first char
        if status == START then
            if utils.isNumber(key) then
                cmdCount = cmdCount * 10 + tonumber(key)
                return
            elseif isQuickCmd(key) then
                cmd = key
                status = COMPLETE
            elseif isLongCmd(key) then
                cmd = key
                status = READ_NEXT
                return
            else
                -- Unknown key
                return
            end

        elseif status == READ_NEXT then
            -- TODO If this format of command is given: Y-cmd-X-cmd, resultant count should be cmdCount = Y+X
            if utils.isNumber(key) then
                cmdCount = cmdCount * 10 + tonumber(key)
                action = READ_NEXT
                return
            else
                cmd = cmd .. key
                status = COMPLETE
            end

        elseif status == COMPLETE then
            callAction(cmd, cmdCount)
            reset()
            break; -- or return
        end
    end
end


-- Switch to NORMAL mode
function VimAw.normalMode()
    changeMode(NORMAL_MODE)
    redrawBorders(WIN_BORDER_ACTIVE_NORMAL_MODE)

    if not keygrabber.isrunning() then
        keygrabber.run(function(mod, key, event)
            if event == "press" then doAction(key) end
        end)
    end
end


require("command_mode")



return VimAw
