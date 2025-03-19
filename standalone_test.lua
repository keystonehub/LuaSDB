--- @section Init

--- Assign package path.
package.path = package.path .. ";./modules/?.lua;"

--- Init database.
require("init")

--- @section Require Modules

local DEBUG = require("debugging")

print("DEBUG found:", DEBUG ~= nil)

local API = require("api")

print("API found:", API ~= nil)

--- @section Test Start

DEBUG.print("info", "LuaSDB API TEST START\n")

local command = arg[1] or "help"

--- @section Create Table

local schema_name = "test"
local schema_def = {
    { field = "varchar", type = "VARCHAR", limit = 100, default = "default varchar", not_null = true, primary = true },
    { field = "text", type = "TEXT", default = "default long text", not_null = true },
    { field = "enum", type = "ENUM", allowed = { "value1", "value2", "value3" }, default = "value2", not_null = true },
    { field = "tinyint", type = "TINYINT", default = 1, unsigned = true, not_null = true },
    { field = "smallint", type = "SMALLINT", default = 123, unsigned = true, not_null = true },
    { field = "int", type = "INT", auto_increment = true, default = 0, unsigned = true, not_null = true },
    { field = "bigint", type = "BIGINT", default = 1000000, unsigned = true, not_null = true },
    { field = "decimal", type = "DECIMAL", size = 10, d = 2, default = 123.45, unsigned = true, not_null = true },
    { field = "float", type = "FLOAT", default = 1.23, unsigned = true, not_null = true },
    { field = "date", type = "DATE", default = "2025-03-09", not_null = true },
    { field = "datetime", type = "DATETIME", default = "2025-03-09 22:00:00", not_null = true },
    { field = "timestamp", type = "TIMESTAMP", default = "CURRENT_TIMESTAMP", not_null = true },
    { field = "json", type = "JSON", default = {}, not_null = true },
}

local function create_table()
    local start_time = os.clock()
    DEBUG.print("info", ("Starting create_table command at OS time: %.4f"):format(start_time))
    
    local success, message = API.create_table(schema_name, schema_def)
    
    local elapsed = os.clock() - start_time
    DEBUG.print("info", ("Create Table: %s %s (Time: %.4f seconds)"):format(tostring(success), tostring(message), elapsed))
end

--- @section Insert Record

local function insert_record()
    local start_time = os.clock()
    DEBUG.print("info", ("Starting insert command at OS time: %.4f"):format(start_time))
    
    local test_record = {
        varchar = "Test varchar",
        text = "Test text field that is somewhat longer.",
        enum = "value1",
        tinyint = 10,
        smallint = 200,
        bigint = 987654321,
        decimal = 456.78,
        float = 3.1415,
        date = "2025-03-09",
        datetime = "2025-03-09 22:00:00",
        timestamp = "2025-03-09 22:00:00",
        json = { key = "value", numbers = { 1, 2, 3 } },
    }
    
    local success, message = API.insert(schema_name, test_record)
    
    local elapsed = os.clock() - start_time
    DEBUG.print("info", ("Insert Record: %s %s (Time: %.4f seconds)"):format(tostring(success), tostring(message), elapsed))
end

--- @section Insert Bulk Records

local function insert_bulk()
    local num = tonumber(arg[2]) or 10
    local start_time = os.clock()
    
    DEBUG.print("info", ("Starting insert_bulk command for %d records at OS time: %.4f"):format(num, start_time))

    for i = 1, num do
        local test_record = {
            varchar = ("Test varchar %d"):format(i),
            text = ("Test text field %d"):format(i),
            enum = (i % 2 == 0) and "value2" or "value1",
            tinyint = math.random(1, 100),
            smallint = math.random(100, 1000),
            bigint = 987654321 + i,
            decimal = 456.78 + i / 100,
            float = 3.1415 + i / 1000,
            date = "2025-03-09",
            datetime = "2025-03-09 22:00:00",
            timestamp = "2025-03-09 22:00:00",
            json = { key = "value", index = i },
        }

        local success, message = API.insert(schema_name, test_record)
        if not success then
            DEBUG.print("error", ("Insert failed for record %d: %s"):format(i, message))
        end
    end

    local elapsed = os.clock() - start_time
    DEBUG.print("info", ("Insert Bulk: Inserted %d records. (Time: %.4f seconds)"):format(num, elapsed))
end

--- @section Select All Records

local function select_all_records()
    local start_time = os.clock()
    DEBUG.print("info", ("Starting select_all command at OS time: %.4f"):format(start_time))

    local results, message = API.select(schema_name, nil, false)
    
    local elapsed = os.clock() - start_time
    if results then
        DEBUG.print("info", ("Select All Records: Retrieved %d records. (Time: %.4f seconds)"):format(#results, elapsed))
    else
        DEBUG.print("error", ("Select All Records: Failed %s (Time: %.4f seconds)"):format(tostring(message), elapsed))
    end
end

--- @section Update All Records

local function update_all_records()
    local start_time = os.clock()
    DEBUG.print("info", ("Starting update_all command at OS time: %.4f"):format(start_time))

    local filters = "all"
    local updates = {
        varchar = "Bulk Updated",
        int = 2
    }

    local success, message = API.update(schema_name, filters, updates, true)
    
    local elapsed = os.clock() - start_time
    DEBUG.print("info", ("Update All Records: %s %s (Time: %.4f seconds)"):format(tostring(success), tostring(message), elapsed))
end

--- @section Command Execution

if command == "create_table" then
    create_table()
elseif command == "insert" then
    insert_record()
elseif command == "insert_bulk" then
    insert_bulk()
elseif command == "select_all" then
    select_all_records()
elseif command == "update_all" then
    update_all_records()
else
    DEBUG.print("warn", "Usage: lua test.lua [create_table | insert | insert_bulk <num> | select_all | update_all]")
end

--- @section Test End

DEBUG.print("info", "TEST COMPLETE")