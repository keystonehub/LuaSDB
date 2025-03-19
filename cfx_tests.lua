local API = require("modules.api")
local DEBUG = require("modules.debugging")

--- @section Test Create

local schema_name = "test"
local schema_def = {
    { field = "varchar_field", type = "VARCHAR", limit = 100, default = "default varchar", not_null = true },
    { field = "text_field", type = "TEXT", default = "default long text", not_null = true },
    { field = "enum_field", type = "ENUM", allowed = { "value1", "value2", "value3" }, default = "value2", not_null = true },
    { field = "tinyint_field", type = "TINYINT", default = 1, unsigned = true, not_null = true },
    { field = "smallint_field", type = "SMALLINT", default = 123, unsigned = true, not_null = true },
    { field = "int_field", type = "INT", auto_increment = true, default = 0, unsigned = true, not_null = true },
    { field = "bigint_field", type = "BIGINT", default = 1000000, unsigned = true, not_null = true },
    { field = "decimal_field", type = "DECIMAL", size = 10, d = 2, default = 123.45, unsigned = true, not_null = true },
    { field = "float_field", type = "FLOAT", default = 1.23, unsigned = true, not_null = true },
    { field = "date_field", type = "DATE", default = "2025-03-09", not_null = true },
    { field = "datetime_field", type = "DATETIME", default = "2025-03-09 22:00:00", not_null = true },
    { field = "timestamp_field", type = "TIMESTAMP", default = "CURRENT_TIMESTAMP", not_null = true },
    { field = "json_field", type = "JSON", default = {}, not_null = true },
}

local function create_table()
    DEBUG.print("info", "Starting create_table command...")
    local start_time = GetGameTimer()
    local success, message = API.create_table(schema_name, schema_def)
    local elapsed = (GetGameTimer() - start_time) / 1000
    DEBUG.print("info", "Create Table: " .. tostring(success) .. " " .. tostring(message) .. " (Time: " .. tostring(elapsed) .. " seconds)")
end

RegisterCommand('create_table', function()
    create_table()
end, false)

--- @section Test Bulk Insert

RegisterCommand('test_bulk_insert', function(source, args)
    local num = tonumber(args[1]) or 10
    DEBUG.print("info", ("Starting insert_bulk command for %d records..."):format(num))
    for i = 1, num do
        local test_record = {
            varchar_field = ("Test varchar %d"):format(i),
            text_field = ("Test text field %d"):format(i),
            enum_field = (i % 2 == 0) and "value2" or "value1",
            tinyint_field = math.random(1, 100),
            smallint_field = math.random(100, 1000),
            bigint_field = 987654321 + i,
            decimal_field = 456.78 + i / 100,
            float_field = 3.1415 + i / 1000,
            date_field = "2025-03-09",
            datetime_field = "2025-03-09 22:00:00",
            timestamp_field = "2025-03-09 22:00:00",
            json_field = { key = "value", index = i },
        }
        local success, message = API.insert(schema_name, test_record)
        if not success then
            DEBUG.print("error", ("Insert failed for record %d: %s"):format(i, message))
            break
        end
    end
end, false)