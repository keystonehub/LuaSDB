--- @module debugging
--- Handles debug functions.

--- @section Module

local debugging = {}

--- Get the current time for logging.
--- @return string: The formatted current time in 'YYYY-MM-DD HH:MM:SS' format.
local function get_timestamp()
    return os.date('%Y-%m-%d %H:%M:%S') or '0000-00-00 00:00:00'
end

--- Logs debugging messages with levels and optional data.
--- @param level string: The logging level ('debugging', 'info', 'success', 'warn', 'error').
--- @param message string: The message to log.
--- @param data table|nil: Additional optional data to include.
local function debug_print(level, message, data)
    local colours

    if _G.ENV.IS_CFX then
        colours = { debugging = '^6', info = '^5', success = '^2', warn = '^3', error = '^8', reset = '^7' }
    else
        colours = { debugging = "\27[36m", info = "\27[34m", success = "\27[32m",  warn = "\27[33m", error = "\27[31m", reset = "\27[0m" }
    end

    print(('%s[%s][%s]: %s%s'):format(colours[level] or colours.reset,  get_timestamp(),  level:upper(),  message or 'Undefined debugging message...',  colours.reset ))
end

--- @section Function Assignment

debugging.print = debug_print
debugging.get_timestamp = get_timestamp

return debugging