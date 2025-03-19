--- @module Types
--- Stores type definitions for validator.

--[[
    Schema Type Definitions

    This module defines the supported schema data types used for validator.

    Supported Lua Types:
        - number 
        - string
        - boolean
        - table

    Supported Schema Data Types:

    STRING DATA TYPES
        - VARCHAR(size)         -- Variable-length string
        - TEXT                  -- Long text
        - ENUM(val1, val2, ...) -- Fixed set of possible string values

    NUMERIC DATA TYPES
        - TINYINT         -- Very small int
        - SMALLINT        -- Small int
        - INT             -- Standard int
        - BIGINT          -- Large int
        - DECIMAL(size,d) -- Fixed-precision decimal
        - FLOAT           -- Floating-point number

    DATE & TIME DATA TYPES
        - DATE      -- YYYY-MM-DD formatted date
        - DATETIME  -- YYYY-MM-DD HH:MM:SS full timestamp
        - TIMESTAMP -- Unix-based timestamp

    **Excluded Data Types (Not Supported)**
        - BLOB / BINARY   -- Binary data storage not needed
        - MEDIUMINT       -- Covered by INT
        - DOUBLE          -- FLOAT is sufficient
        - TIME            -- Rarely useful alone
        - YEAR            -- Redundant with DATE
        - SET(val1, val2) -- ENUM is sufficient
]]

return {

    --- @section Strings

    --- Variable-length string type.
    --- @field field string: The name of the field (e.g., "id", "name", etc.)
    --- @field type string: Specifies the main type for the key.
    --- @field limit number: Maximum allowed string length.
    --- @field default string: Default string value.
    --- @field not_null boolean: If true, value cannot be nil or empty.
    --- @field primary boolean: If true value will be set as the primary key entry, only one primary key allowed per table.
    VARCHAR = { field = "string", type = "string", limit = "number", default = "string", not_null = "boolean", primary = "boolean" },

    --- Long text string type.
    --- @field field string: The name of the field (e.g., "description", "notes", etc.)
    --- @field type string: Specifies the main type for the key.
    --- @field default string: Default text value.
    --- @field not_null boolean: If true, value cannot be nil.
    TEXT = { field = "string", type = "string", default = "string", not_null = "boolean" },

    --- Enumeration type.
    --- @field field string: The name of the field (e.g., "status", "role", etc.)
    --- @field type string: Specifies the main type for the key.
    --- @field allowed table: Table of explicitly allowed string values.
    --- @field default string: Default value, must be one of the allowed values.
    --- @field not_null boolean: If true, value must explicitly be provided.
    ENUM = { field = "string", type = "table", allowed = "table", default = "string", not_null = "boolean" },

    --- @section Numerics

    --- Tiny integer.
    --- @field field string The name of the field (e.g., "status", "is_active", etc.)
    --- @field type string Specifies the main type for the key.
    --- @field default number Default numeric value.
    --- @field unsigned boolean If true, value must be positive or zero (no negatives).
    --- @field not_null boolean If true, value must explicitly be provided (cannot be nil).
    TINYINT = { field = "string", type = "number", default = "number", unsigned = "boolean", not_null = "boolean" },

    --- Small integer (2 bytes, useful for counters and IDs).
    SMALLINT = { field = "string", type = "number", default = "number", unsigned = "boolean", not_null = "boolean" },

    --- Standard integer (4 bytes, useful for primary keys and large counters).
    --- @field primary boolean: If true value will be set as the primary key entry, only one primary key allowed per table.
    INT = { field = "string", type = "number", auto_increment = "boolean", default = "number", unsigned = "boolean", not_null = "boolean", primary = "boolean"  },

    --- Large integer (8 bytes, useful for high-range unique identifiers).
    BIGINT = { field = "string", type = "number", default = "number", unsigned = "boolean", not_null = "boolean", primary = "boolean"  },

    --- Fixed-precision decimal number (useful for money or calculations requiring precision).
    --- @field size number Total number of digits.
    --- @field d number Number of digits after the decimal point.
    DECIMAL = { field = "string", type = "number", size = "number", d = "number", default = "number", unsigned = "boolean", not_null = "boolean" },

    --- Floating-point number (approximate calculations, fast but imprecise for currency).
    FLOAT = { field = "string", type = "number", default = "number", unsigned = "boolean", not_null = "boolean" },

    --- @section Date & Time

    --- Date type as a string (format YYYY-MM-DD).
    --- @field field string The name of the field (e.g., "birthdate", "start_date", etc.)
    --- @field type string Specifies the main type for the key.
    --- @field default string Default date value.
    --- @field not_null boolean If true, value cannot be nil.
    DATE = { field = "string", type = "string", default = "string", not_null = "boolean" },

    --- Date and time type as a string (format YYYY-MM-DD HH:MM:SS).
    --- @field field string The name of the field (e.g., "created_at", "updated_at", etc.)
    --- @field type string Specifies the main type for the key.
    --- @field default string Default datetime value.
    --- @field not_null boolean If true, value cannot be nil.
    DATETIME = { field = "string", type = "string", default = "string", not_null = "boolean" },

    --- Timestamp type as a string (format YYYY-MM-DD HH:MM:SS).
    --- Automatically updates when modified (if configured).
    --- @field field string The name of the field (e.g., "last_login", "timestamp", etc.)
    --- @field type string Specifies the main type for the key.
    --- @field default string Default timestamp value ("CURRENT_TIMESTAMP" for current time).
    --- @field not_null boolean If true, value cannot be nil.
    TIMESTAMP = { field = "string", type = "string", default = "string", not_null = "boolean" },

    --- @section Tables

    --- JSON object type, stored as a Lua table.
    --- @field field string The name of the field (e.g., "data", "metadata", etc.)
    --- @field type string Specifies the main type for the key.
    --- @field default table Default value as an empty table `{}`.
    --- @field not_null boolean If true, value cannot be nil.
    JSON = { field = "string", type = "table", default = "table", not_null = "boolean" },
}