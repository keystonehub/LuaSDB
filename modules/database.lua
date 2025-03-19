--- @module Database
--- Handles all database related functions.

--- @section Require Modules

local DEBUG <const> = require("modules.debugging")
local READER <const> = require("modules.reader")
local WRITER <const> = require("modules.writer")
local VALIDATOR <const> = require("modules.validator")
local QUEUE <const> = require("modules.queue")

--- @section Module

local database = {}

--- Creates a new schema, validates it, and writes it to storage.
--- @param name string: The schema name.
--- @param def table: The schema definition.
--- @return boolean, string: Success or failure message.
local function create_table(name, def)
    if _G.ENV.SCHEMAS[name] then return false, ("Schema '%s' already exists."):format(name) end

    local is_valid, message = VALIDATOR.validate_schema(def)
    if not is_valid then return false, ("Schema validator failed: %s"):format(message) end

    if not WRITER.schema(name, def) then return false, ("Failed to write schema file for '%s'."):format(name) end

    _G.ENV.SCHEMAS[name] = def
    _G.ENV.TABLES[name] = _G.ENV.TABLES[name] or {}

    return true, ("Schema '%s' successfully created."):format(name)
end

--- Inserts a record.
--- @param table_name string: The table name.
--- @param data table: The record to insert.
--- @return boolean, string: Success status and message.
local function insert_record(table_name, data)
    local schema = READER.schema(table_name)
    if not schema then return false, ("Schema '%s' not found."):format(table_name) end

    local table_data = READER.table(table_name) or {}
    _G.ENV.TABLES[table_name] = table_data

    local is_valid, validation_message = VALIDATOR.validate_insert(table_name, data)
    if not is_valid then return false, ("Entry validator failed: %s"):format(validation_message) end

    for _, field_def in ipairs(schema) do
        local field_name = field_def.field
        if field_def.auto_increment then
            local max_id = 0
            for _, record in ipairs(table_data) do
                if record[field_name] and type(record[field_name]) == "number" and record[field_name] > max_id then
                    max_id = record[field_name]
                end
            end
            data[field_name] = max_id + 1
        end
    end

    QUEUE.add_insert(table_name, data)
    return true, "Record queued for bulk insert."
end

--- Forces an immediate write of a record.
--- This bypasses bulk buffering and writes to disk immediately.
--- @param table_name string: The table name.
--- @param data table: The record to insert.
--- @return boolean, string: Success status and message.
local function force_insert(table_name, data)
    local schema = READER.schema(table_name)
    if not schema then return false, ("Schema '%s' not found."):format(table_name) end

    local table_data = READER.table(table_name) or {}
    _G.ENV.TABLES[table_name] = table_data

    local is_valid, validation_message = VALIDATOR.validate_insert(table_name, data)
    if not is_valid then return false, ("Entry validator failed: %s"):format(validation_message) end

    for _, field_def in ipairs(schema) do
        local field_name = field_def.field
        if field_def.auto_increment then
            local max_id = 0
            for _, record in ipairs(table_data) do
                if record[field_name] and type(record[field_name]) == "number" and record[field_name] > max_id then
                    max_id = record[field_name]
                end
            end
            data[field_name] = max_id + 1
        end
    end

    table.insert(table_data, data)

    if not WRITER.table(table_name, table_data, schema) then return false, "Failed to write updated table file." end

    return true, "Record inserted immediately."
end

--- Selects data from a table.
--- @param table_name string: The name of the table to query.
--- @param filters table|nil: Optional key-value pairs for filtering.
--- @param single boolean: If true, returns only the first matching record.
--- @return table|nil: A single record or multiple matching records, nil if no matches.
local function select_records(table_name, filters, single)
    local table_data = READER.table(table_name)
    if not table_data or #table_data == 0 then return nil, ("Table '%s' is empty or does not exist."):format(table_name) end

    if not filters or next(filters) == nil then
        return single and table_data[1] or table_data
    end

    local results = {}
    for _, record in ipairs(table_data) do
        local match = true
        for key, value in pairs(filters) do
            if record[key] ~= value then
                match = false
                break
            end
        end
        if match then
            if single then
                return record
            end
            table.insert(results, record)
        end
    end

    return #results > 0 and results or nil
end

--- Queues an update operation for a table.
--- @param table_name string: The name of the table to update.
--- @param filters table|string: Filters to match records for update.
--- @param updates table: The fields and new values to update.
--- @return boolean, string: Success status and message.
local function update_entry(table_name, filters, updates)
    local schema = READER.schema(table_name)
    if not schema then return false, ("Schema '%s' not found."):format(table_name) end

    local table_data = READER.table(table_name) or {}
    if #table_data == 0 then return false, ("Table '%s' is empty."):format(table_name) end

    QUEUE.add_update(table_name, filters, updates)
    return true, "Update queued and flushed."
end

--- Forces an immediate update of records in a table.
--- @param table_name string: The name of the table to update.
--- @param filters table|string: Filters to match records for update.
--- @param updates table: The fields and new values to update.
--- @return boolean, string: Success status and message.
local function force_update(table_name, filters, updates)
    local schema = READER.schema(table_name)
    if not schema then return false, ("Schema '%s' not found."):format(table_name) end

    local table_data = READER.table(table_name) or {}
    if #table_data == 0 then return false, ("Table '%s' is empty."):format(table_name) end

    local records_updated = 0
    for _, record in ipairs(table_data) do
        local match = true
        for key, value in pairs(filters) do
            if record[key] ~= value then
                match = false
                break
            end
        end
        if match then
            for field, new_value in pairs(updates) do
                record[field] = new_value
            end
            records_updated = records_updated + 1
        end
    end

    if records_updated == 0 then return false, "No matching records found to update." end

    if not WRITER.table(table_name, table_data, schema) then return false, "Failed to write updated table file." end

    return true, ("Updated %d record(s)."):format(records_updated)
end

--- @section Function Assignments

database.create_table = create_table
database.insert = insert_record
database.force_insert = force_insert
database.select = select_records
database.update = update_entry
database.force_update = force_update

return database