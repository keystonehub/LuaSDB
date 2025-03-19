# 3 - API

The follow `API` functions can be used to interact with the database.
Some more functions are planned to be included, these will be done in time.

---

# Accessing The API

## Standalone

- Add `local API <const> = require("modules.api")` into your LUA script.
- Use the functions through `API.` e.g, `API.create_table(...)`.

## CFX

- Add `local API <const> = exports.LuaSDB:get_api()` into your LUA script.
- Use the functions through `API.` e.g, `API.create_table(...)`.

---

# API Functions

## API.create_table(name, def)

Creates a new schema.
- **Parameters**
    - `name`: The schema name.
    - `def`: The schema definition.
- **Returns**:  
    - `boolean, string`: Success/failure and a message. 

```lua
local schema_name = "players"
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

local success, msg = API.create_table(schema_name, schema_def)
```

## API.insert(table_name, data)

Inserts a new record, following original schema order.
- **Parameters**:
    - `table_name`: The target table.  
    - `data`: A table of field-value pairs to insert.  
- **Returns**:
    - `boolean, string`: – Success/failure and a message.  

```lua
local table_name = "players"
local test_record = {
    varchar = "Test varchar",
    text = "Test text field that is somewhat longer.",
    enum = "value1",
    int = 1,
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
```

## API.select(table_name, filters, single)

Selects records from a table.
- **Parameters**:
    - `table_name`: The table to query.
    - `filters`: (Optional) Filter object, e.g. `{ username = "John" }`.  
    - `single`: If `true`, returns only the first match.  
- **Returns**: 
    - `table|nil, string`: The resulting records (or record) and a message.  

```lua
local table_name = "players"
local filters = { int = 1 } -- Select records matching filters only.
local single = true -- If true, returns only the first matching record.

local results, message = API.select(table_name, filters, single)
if results then
    print("Found record:", results.int)
else
    print("Select failed:", message)
end
```

## API.update(table_name, filters, updates)

Updates records that match the given filters.

- **Parameters**:
    - `table_name`: The table name.  
    - `filters`: If you pass `"all"`, it updates all records. Otherwise, a table like `{ username = "John" }`.  
    - `updates`: Fields to modify, e.g. `{ username = "JaneDoe" }`.  
- **Returns**: 
    - `boolean, string`: Success/failure and a message.

```lua
local table_name = "players"
local filters = { id = 1 }
local updates = { username = "NewName" } -- Apply updates to filter.

local success, message = API.update(table_name, filters, updates)
if success then
    print("Updated record.")
else
    print("Update failed:", message)
end
```