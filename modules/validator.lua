--- @module Validation
--- Handles schema and data validator.

local TYPES <const> = require("modules.types")

local validator = {}

--- Validate schema definition against predefined schema types.
--- @param schema_def table: Schema definition to validate.
--- @return boolean, string: True and success message if valid, false and error message otherwise.
local function validate_schema(schema_def)
    if type(schema_def) ~= "table" then
        return false, "Schema definition must be a table."
    end

    if not TYPES then
        return false, "Schema types are not loaded."
    end

    local primary_count = 0
    for index, opts in ipairs(schema_def) do
        if type(opts) ~= "table" then
            return false, ("Schema entry at index %d must be a table."):format(index)
        end

        if not opts.field or type(opts.field) ~= "string" then
            return false, ("Schema entry at index %d is missing a valid field name."):format(index)
        end

        if not opts.type then
            return false, ("Field '%s' is missing a type definition."):format(opts.field)
        end

        local type_def = TYPES[opts.type:upper()]
        if not type_def then
            return false, ("Field '%s' has an invalid or undefined type '%s'."):format(opts.field, opts.type)
        end

        for key, expected_type in pairs(type_def) do
            if key ~= "type" and opts[key] ~= nil then
                if type(opts[key]) ~= expected_type then
                    return false, ("Field '%s' property '%s' has incorrect type. Expected %s, got %s."):format(
                        opts.field, key, expected_type, type(opts[key])
                    )
                end
            end
        end

        if opts.type:upper() == "VARCHAR" then
            if not opts.limit or type(opts.limit) ~= "number" or opts.limit < 1 or opts.limit > 65535 then
                return false, ("Field '%s' has an invalid VARCHAR limit. Must be between 1-65535."):format(opts.field)
            end
        elseif opts.type:upper() == "DECIMAL" then
            if not opts.size or type(opts.size) ~= "number" or opts.size < 1 or opts.size > 65 then
                return false, ("Field '%s' has an invalid DECIMAL size. Must be between 1-65."):format(opts.field)
            end
            if not opts.d or type(opts.d) ~= "number" or opts.d < 0 or opts.d > 30 then
                return false, ("Field '%s' has an invalid DECIMAL precision. Must be between 0-30."):format(opts.field)
            end
        end

        if opts.type:upper() == "ENUM" then
            if not opts.allowed or type(opts.allowed) ~= "table" then
                return false, ("Field '%s' must have an 'allowed' list of ENUM values."):format(opts.field)
            end
            for _, val in ipairs(opts.allowed) do
                if type(val) ~= "string" then
                    return false, ("Allowed values for ENUM field '%s' must be strings."):format(opts.field)
                end
            end
        end

        if opts.primary_key then
            local upper_type = opts.type:upper()
            if upper_type ~= "VARCHAR" and upper_type ~= "INT" and upper_type ~= "BIGINT" then
                return false, ("Field '%s' cannot be set as primary key because type '%s' is not allowed."):format(opts.field, opts.type)
            end
            primary_count = primary_count + 1
        end
    end

    if primary_count > 1 then
        return false, "Schema cannot have more than one primary key."
    end

    return true, "Schema validator passed."
end


--- Validate an entry against the correct schema before insertion.
--- @param table_name string: The name of the table to validate against.
--- @param data table: The data record to validate.
--- @return boolean, string: True if valid, false and an error message if not.
local function validate_insert(table_name, data)
    if not _G.ENV.SCHEMAS[table_name] then
        _G.ENV.SCHEMAS[table_name] = READER.schema(table_name)
    end

    local schema = _G.ENV.SCHEMAS[table_name]
    if not schema then
        return false, ("Schema '%s' not found. Cannot validate entry."):format(table_name)
    end

    if not _G.ENV.TABLES[table_name] then
        _G.ENV.TABLES[table_name] = READER.table(table_name) or {}
    end

    local table_data = _G.ENV.TABLES[table_name]

    for _, field_def in ipairs(schema) do
        local field_name = field_def.field
        local field_value = data[field_name]

        if field_def.auto_increment then
            if not data[field_name] then
                local max_id = 0
                for _, record in ipairs(table_data) do
                    if record[field_name] and type(record[field_name]) == "number" and record[field_name] > max_id then
                        max_id = record[field_name]
                    end
                end
                data[field_name] = max_id + 1
                field_value = data[field_name]
            end
        end

        if field_def.not_null and (field_value == nil or field_value == "") then
            return false, ("Field '%s' cannot be NULL."):format(field_name)
        end

        if field_def.type == "ENUM" and field_def.allowed then
            local valid_enum = false
            for _, allowed_value in ipairs(field_def.allowed) do
                if field_value == allowed_value then
                    valid_enum = true
                    break
                end
            end
            if not valid_enum then
                return false, ("Field '%s' value '%s' is not in allowed ENUM values."):format(field_name, field_value)
            end
        end

        local expected_type = TYPES[field_def.type:upper()] and TYPES[field_def.type:upper()].type or nil
        if field_def.type == "ENUM" then
            expected_type = "string"
        end

        if expected_type and field_value ~= nil and type(field_value) ~= expected_type then
            return false, ("Field '%s' type mismatch. Expected %s, got %s."):format(field_name, expected_type, type(field_value))
        end

        if field_def.type:upper() == "JSON" and field_value ~= nil and type(field_value) ~= "table" then
            return false, ("Field '%s' must be a valid JSON (Lua table)."):format(field_name)
        end

        if field_def.primary_key then
            for _, record in ipairs(table_data) do
                if record[field_name] == field_value then
                    return false, ("Field '%s' must be unique. The value '%s' already exists."):format(field_name, field_value)
                end
            end
        end
    end

    return true, "Entry validator passed."
end

--- @section Function Assignment

validator.validate_schema = validate_schema
validator.validate_insert = validate_insert

return validator
