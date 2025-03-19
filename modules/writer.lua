--- @module writer
--- Handles writing to files via io. or SaveResourceFile if running on cfx platforms.

local writer = {}

local DEBUG = require("modules.debugging")
local SERIALIZER = require("modules.serializer")

--- Writes a schema definition to a Lua file and initializes an empty table file.
--- @param name string: The schema name.
--- @param def table: The raw schema definition.
--- @return boolean: Success or failure.
local function write_schema(name, def)
    local schema_path = _G.ENV.SCHEMA_PATH .. name .. ".lua"
    local table_path  = _G.ENV.TABLES_PATH  .. name .. ".lua"
    
    local serialized_schema = SERIALIZER.serialize_schema(def)

    if _G.ENV.IS_CFX then
        local success_schema = SaveResourceFile('LuaSDB', schema_path, serialized_schema, #serialized_schema)
        if not success_schema then
            DEBUG.print("error", ("[CFX] Failed to write schema file: %s"):format(schema_path))
            return false
        end

        local success_table = SaveResourceFile('LuaSDB', table_path, "return {}", -1)
        if not success_table then
            DEBUG.print("error", ("[CFX] Failed to create empty table file: %s"):format(table_path))
            return false
        end

        DEBUG.print("success", ("[CFX] Schema file written: %s"):format(schema_path))
        DEBUG.print("success", ("[CFX] Table file initialized: %s"):format(table_path))
    else
        local file, err = io.open(schema_path, "w")
        if not file then
            DEBUG.print("error", ("[FS] Failed to open schema file: %s - %s"):format(schema_path, err))
            return false
        end
        file:write(serialized_schema)
        file:close()
        DEBUG.print("success", ("[FS] Schema file written: %s"):format(schema_path))

        local file_check = io.open(table_path, "r")
        if not file_check then
            local table_file = io.open(table_path, "w")
            if table_file then
                table_file:write("return {}")
                table_file:close()
                DEBUG.print("success", ("[FS] Table file initialized: %s"):format(table_path))
            else
                DEBUG.print("error", ("[FS] Failed to create empty table file: %s"):format(table_path))
                return false
            end
        else
            file_check:close()
        end
    end

    return true
end

--- Writes or updates a table file.
--- Uses SaveResourceFile if running in CFX.
--- @param name string: The table name.
--- @param table_data table: The table data (an array of records) to serialize.
--- @param schema table: The schema used for serialization (an array of field definitions).
--- @return boolean: Success or failure.
local function write_table(name, table_data, schema)
    local file_path = _G.ENV.TABLES_PATH .. name .. ".lua"

    if not table_data or type(table_data) ~= "table" then
        DEBUG.print("error", ("Invalid data for table '%s'. Aborting write."):format(name))
        return false
    end

    local primary_key = nil
    for _, field_def in ipairs(schema) do
        if field_def.primary then
            primary_key = field_def.field
            break
        end
    end

    local serialized_data = SERIALIZER.serialize_entries(table_data, primary_key)

    if _G.ENV.IS_CFX then
        local success = SaveResourceFile("LuaSDB", file_path, serialized_data, #serialized_data)
        if not success then
            DEBUG.print("error", ("Failed to write table file: %s"):format(file_path))
            return false
        end
        DEBUG.print("success", ("Table file updated: %s"):format(file_path))
    else
        local file, err = io.open(file_path, "w")
        if not file then
            DEBUG.print("error", ("Failed to open table file: %s - %s"):format(file_path, err))
            return false
        end
        file:write(serialized_data)
        file:close()
        DEBUG.print("success", ("Table file updated: %s"):format(file_path))
    end

    return true
end

--- @section Function Assignments
writer.schema = write_schema
writer.table  = write_table

return writer
