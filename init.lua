--- @script Resource Initialization
--- Loads all required modules.

--- @section Environment

--- Check for native IsDuplicityVersion; used to determine if running on a cfx platform.
local is_cfx = IsDuplicityVersion

--- Debug colours.
local colours

if is_cfx then
    colours = { debugging = "^6", info = "^5", success = "^2", warn = "^3", error = "^8", reset = "^7" }
else
    colours = { debugging = "\27[36m", info = "\27[34m", success = "\27[32m",  warn = "\27[33m", error = "\27[31m", reset = "\27[0m" }
end

--- If running on a cfx platform, override the default require with a cfx-friendly version.
if is_cfx then
    MODULES = {}

    --- Loads a module and caches.
    --- @param module_name string: The name of the module to load.
    --- @return table|nil: The loaded module, or nil if loading fails.
    function cfx_require(module_name)
        if MODULES[module_name] then return MODULES[module_name] end

        local clean_name = module_name:gsub("^modules%.", "")
        local path = ("modules/%s.lua"):format(clean_name)

        local content = LoadResourceFile("LuaSDB", path)
        if not content then print(("%s[%s][ERROR]: Module not found: %s%s"):format(colours.error, os.date("%Y-%m-%d %H:%M:%S"), module_name, colours.reset)) return nil end

        local fn, err = load(content, ("@@%s/%s.lua"):format("LuaSDB", module_name), "t", _G)
        if not fn then print(("%s[%s][ERROR]: Error loading module (%s): %s%s"):format(colours.error, os.date("%Y-%m-%d %H:%M:%S"), module_name, err, colours.reset)) return nil end

        local result = fn()
        if type(result) ~= "table" then print(("%s[%s][ERROR]: Module (%s) did not return a table.%s"):format(colours.error, os.date("%Y-%m-%d %H:%M:%S"), module_name, colours.reset)) return nil end

        MODULES[module_name] = result
        return result
    end

    --- Overrides the global "require" to "cfx_require" in a CFX environment.
    _G.require = cfx_require
end

--- Environment Variables.
ENV = setmetatable({
    --- Stores dont touch.
    SCHEMAS = {},
    TABLES = {},
    STATIC = {},
    MODULES = {},

    RESOURCE_NAME = "LuaSDB",
    
    --- Configurable.
    MODE = "dev", -- Specifies where files should be loaded from/saved to; Options: "dev", "prod"
    QUEUE_THRESHOLD = 100, -- Queue will "auto-flush" and save to files once threshold has been reached.
    PRETTY = true, -- Toggle pretty printing this will put each entry onto a single line.
    INDENTATION = 4, -- Controls the amount of indentation applied. 
    MAX_DEPTH = 50 -- Maximum nesting depth before serialization cuts off.

}, { __index = _G })

--- Determines the absolute resource path.
--- @return string: The absolute path to the current resource.
local function get_resource_path()
    local cwd = nil

    local p = io.popen("cd 2>nul || pwd")
    if p then
        cwd = p:read("*l")
        p:close()
    end

    if not cwd or cwd == "" then
        local str = debug.getinfo(1, "S").source:sub(2)
        str = str:gsub("\\", "/"):gsub("@", "")
        cwd = str:match("^(.-/)[^/]+$") or "./"
    end

    if not cwd or cwd == "" then
        error("Failed to determine absolute path.")
    end

    cwd = cwd:gsub("//", "/")

    if package.config:sub(1, 1) == "\\" then
        cwd = cwd:gsub("/", "\\")
    end

    return cwd
end

--- Assign resource paths based on the running environment.
if is_cfx then
    ENV.IS_CFX = true 

    -- CFX platform uses relative paths.
    ENV.SCHEMA_PATH = ("database/%s/schemas/"):format(ENV.MODE)
    ENV.TABLES_PATH = ("database/%s/tables/"):format(ENV.MODE)
else
    -- The absolute path to the LuaSDB resource.
    local base_path = get_resource_path()
    base_path = base_path:gsub("([^/\\\\]+)[/\\\\]?$", ENV.RESOURCE_NAME)

    ENV.RESOURCE_PATH = base_path
    ENV.SCHEMA_PATH = ("%s/database/%s/schemas/"):format(ENV.RESOURCE_PATH, ENV.MODE)
    ENV.TABLES_PATH = ("%s/database/%s/tables/"):format(ENV.RESOURCE_PATH, ENV.MODE)

    if package.config:sub(1, 1) == "\\" then
        ENV.RESOURCE_PATH = ENV.RESOURCE_PATH:gsub("/", "\\")
        ENV.SCHEMA_PATH = ENV.SCHEMA_PATH:gsub("/", "\\")
        ENV.TABLES_PATH = ENV.TABLES_PATH:gsub("/", "\\")
    end
end

--- @section Database Initialization

--- Gets all database files.
--- @param directory string: The directory containing database files.
function get_database_files(directory)
    local file_list = {}

    if is_cfx then
        local full_path = GetResourcePath("LuaSDB") .. "/" .. directory
        local p = io.popen(("ls '%s'"):format(full_path))
        if p then
            for file in p:lines() do
                if file:match("%.lua$") then
                    table.insert(file_list, file)
                end
            end
            p:close()
        end
    else
        local command
        if package.config:sub(1, 1) == "\\" then
            local fixed_directory = directory:gsub("\\+$", "") .. "\\."
            command = ('dir "%s" /b 2>nul'):format(fixed_directory)
        else
            command = ('ls "%s" 2>/dev/null'):format(directory)
        end

        for file in io.popen(command):lines() do
            if file:match("%.lua$") then
                table.insert(file_list, file)
            end
        end
    end

    return file_list
end

--- Loads database files from a directory and caches them in the provided table.
--- @param directory string: The directory containing database files.
--- @param cache_table table: The table to cache the loaded database schemas or tables.
local function load_database(directory, cache_table)
    local files = get_database_files(directory)
    if #files == 0 then
        print(("%s[%s][WARN]: No files found in directory: %s%s"):format(colours.warn, os.date("%Y-%m-%d %H:%M:%S"), directory, colours.reset))
        return
    end

    for _, file in ipairs(files) do
        local name = file:gsub("%.lua$", "")
        local path = directory .. file
        local content

        if is_cfx then
            content = LoadResourceFile("LuaSDB", path)
        else
            local f = io.open(path, "r")
            if f then
                content = f:read("*a")
                f:close()
            end
        end

        if content then
            local fn, err = load(content, ("@@%s/%s"):format("LuaSDB", path), "t", _G)
            if fn then
                cache_table[name] = fn()
                print(("%s[%s][SUCCESS]: Loaded and cached: %s%s"):format(colours.success, os.date("%Y-%m-%d %H:%M:%S"), name, colours.reset))
            else
                print(("%s[%s][ERROR]: Error loading file %s: %s%s"):format(colours.error, os.date("%Y-%m-%d %H:%M:%S"), path, err, colours.reset))
            end
        else
            print(("%s[%s][ERROR]: File not found: %s%s"):format(colours.error, os.date("%Y-%m-%d %H:%M:%S"), path, colours.reset))
        end
    end
end

--- Initializes the database files.
local function database_init()
    print(("%s[%s][INFO]: Initializing database...%s"):format(colours.info, os.date("%Y-%m-%d %H:%M:%S"), colours.reset))
    load_database(ENV.SCHEMA_PATH, ENV.SCHEMAS)
    load_database(ENV.TABLES_PATH, ENV.TABLES)
    print(("%s[%s][INFO]: Database initialization complete.%s"):format(colours.info, os.date("%Y-%m-%d %H:%M:%S"), colours.reset))
end

if is_cfx then

    --- Initilizes database onResourceStart when running on cfx platforms.
    AddEventHandler("onResourceStart", function(res)
        if res == ENV.RESOURCE_NAME then
            database_init()
        end
    end)
else
    database_init()
end

--- Assign ENV globally.
_G.ENV = ENV

return {}