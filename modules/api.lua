--- @module api
--- Handles all API functions to interact with the database externally.

--- @section Require Modules

local DEBUG <const> = require("modules.debugging")
local DATABASE <const> = require("modules.database")

--- @section Module

local api = {}

--- Retrieves api object function externally.
--- @return table: The api module.
local function get_api()
    return api
end

--- Creates a new schema.
--- @param name string: The schema name.
--- @param def table: The schema definition.
--- @return boolean, string: Success or failure message.
--- @see DATABASE.create_table
local function create_table(name, def)
    if type(name) ~= "string" or name == "" then
        DEBUG.print("error", "Invalid schema name provided.")
        return false, "Schema name must be a non-empty string."
    end
    if type(def) ~= "table" or next(def) == nil then
        DEBUG.print("error", "Invalid schema definition provided.")
        return false, "Schema definition must be a non-empty table."
    end

    local success, message = DATABASE.create_table(name, def)
    if not success then DEBUG.print("error", ("Schema creation failed: %s"):format(message)) end

    return success, message
end

--- Inserts a new record.
--- @param table_name string: The table name.
--- @param data table: The record data.
--- @return boolean, string: Success status and message.
local function insert_entry(table_name, data)
    if type(table_name) ~= "string" or table_name == "" then
        DEBUG.print("error", "Invalid table name provided.")
        return false, "Table name must be a non-empty string."
    end
    if type(data) ~= "table" or next(data) == nil then
        DEBUG.print("error", "Invalid record data provided.")
        return false, "Data must be a non-empty table."
    end

    local success, message = DATABASE.insert(table_name, data)
    if not success then DEBUG.print("error", ("Record insertion failed: %s"):format(message)) end

    return success, message
end

local function force_insert()
    --- @todo Force Insert
end

--- Selects records from a table.
--- @param table_name string: The table to query.
--- @param filters table|nil: Optional filters `{ field = value }`.
--- @param single boolean: If true, returns only the first matching record.
--- @return table|nil: A single record or multiple matching records, nil if no matches.
--- @see DATABASE.select
local function select_entry(table_name, filters, single)
    if type(table_name) ~= "string" or table_name == "" then
        DEBUG.print("error", "Invalid table name provided.")
        return nil, "Table name must be a non-empty string."
    end
    if filters ~= nil and type(filters) ~= "table" then
        DEBUG.print("error", "Invalid filters provided.")
        return nil, "Filters must be a table or nil."
    end
    if type(single) ~= "boolean" then
        DEBUG.print("warn", "Single flag is not a boolean, defaulting to false.")
        single = false
    end

    local result, message = DATABASE.select(table_name, filters, single)
    if result then DEBUG.print("error", ("Record selection failed: %s"):format(message)) end

    return result, message
end

--- Updates an existing record or records in a table.
--- @param table_name string: The table name.
--- @param filters table: Key-value pairs to match the record(s) to update.
--- @param updates table: The fields and new values to update.
--- @return boolean, string: Success status and message.
--- @see DATABASE.update
local function update_entry(table_name, filters, updates)
    if type(table_name) ~= "string" or table_name == "" then
        DEBUG.print("error", "Invalid table name provided.")
        return false, "Table name must be a non-empty string."
    end
    if type(filters) == "string" and filters == "all" then
        filters = {}
    elseif type(filters) ~= "table" or next(filters) == nil then
        DEBUG.print("error", "Invalid filters provided.")
        return false, "Filters must be a non-empty table or 'all'."
    end    
    if type(updates) ~= "table" or next(updates) == nil then
        DEBUG.print("error", "Invalid updates provided.")
        return false, "Updates must be a non-empty table."
    end

    local success, message = DATABASE.update(table_name, filters, updates)
    if success then
        DEBUG.print("success", ("Record(s) updated in '%s' successfully."):format(table_name))
    else
        DEBUG.print("error", ("Record update failed: %s"):format(message))
    end

    return success, message
end

local function force_update()
    --- @todo Force Update
end

local function delete_entry()
    --- @todo Delete
end

local function count_entries()
    --- @todo Count
end

local function existing_entry()
    --- @todo Exists
end

local function truncate_table()
    --- @todo Truncate
end

local function drop_table()
    --- @todo Drop
end

--- Gets all cached schemas.
local function get_schemas()
    return _G.ENV.SCHEMAS or nil
end

--- Gets all cached tables.
local function get_tables()
    return _G.ENV.TABLES or nil
end

--- @section Function Assignment

if _G.ENV.IS_CFX then 
    exports('get_api', get_api) 
end

api.get_api = get_api

api.create_table = create_table
api.insert = insert_entry
api.force_insert = force_insert
api.select = select_entry
api.update = update_entry
api.force_update = force_update
api.delete = delete_entry
api.count = count_entries
api.exists = existing_entry
api.truncate = truncate_table
api.drop = drop_table

return api