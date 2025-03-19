local reader = {}

--- Reads and loads a file with io or CFX.
--- @param file_path string: The full file path.
--- @param cache_table table: The cache table (SCHEMAS or TABLES).
--- @param cache_key string: The key for caching.
--- @return table|nil: The loaded data or nil if the file is missing or invalid.
local function load_file(file_path, cache_table, cache_key)
    if cache_table[cache_key] then return cache_table[cache_key] end

    if _G.ENV.IS_CFX then
        local data = LoadResourceFile("LuaSDB", file_path)
        if not data or data == "" then print(("File %s not found or empty in CFX storage."):format(file_path)) return nil end

        cache_table[cache_key] = data
        return data
    else
        local file, err = io.open(file_path, "r")
        if not file then print(("[FS] Failed to open file %s - %s"):format(file_path, err)) return nil end

        local content = file:read("*all")
        file:close()

        if not content or content == "" then print(("File %s not found or empty."):format(file_path)) return nil end

        local fn, err = load(content, ("@@%s/%s"):format("LuaSDB", file_path), "t", _G)
        if not fn then print(("Error loading file %s: %s"):format(file_path, err)) return nil end

        local success, data = pcall(fn)
        if not success or type(data) ~= "table" then print(("File %s is invalid or did not return a table."):format(file_path)) return nil end

        cache_table[cache_key] = data
        return data
    end
end

--- Reads a schema file.
--- @param name string: The schema name.
--- @return table|nil: The loaded schema or nil if not found.
local function read_schema(name)
    local path = _G.ENV.SCHEMA_PATH .. name .. ".lua"

    return _G.ENV.SCHEMAS[name] or load_file(path, _G.ENV.SCHEMAS, name)
end

--- Reads a table file.
--- @param name string: The table name.
--- @return table: The loaded table data or an empty table if none exists.
local function read_table(name)
    local path = _G.ENV.TABLES_PATH .. name .. ".lua"

    if not _G.ENV.TABLES[name] then
        _G.ENV.TABLES[name] = load_file(path, _G.ENV.TABLES, name) or {}
    end

    return _G.ENV.TABLES[name]
end

--- @section Function Assignments

reader.schema = read_schema
reader.table = read_table

return reader