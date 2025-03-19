local serializer = {}

--- Property order for schema entries.
local property_order = { "field", "type", "allowed", "limit", "auto_increment", "default", "not_null", "primary" }

--- Generates an indentation string based on "PRETTY" & "INDENTATION" settings.
--- @param level number: The nesting level to indent.
--- @return string: The indentation string.
local function generate_indent(level)
    return _G.ENV.PRETTY and string.rep(" ", _G.ENV.INDENTATION * level) or ""
end

--- Recursively serializes any value.  
--- @param value any: The value to serialize (string, number, boolean, table, etc.).
--- @param indent_level number: Indentation level for pretty-printing.
--- @param visited table|nil: Table used for cyclic references.
--- @param max_depth number|nil: Maximum nesting depth before serialization cuts off.
--- @return string: Serialized string representation.
local function serialize_value(value, indent_level, visited, max_depth)
    max_depth = max_depth or _G.ENV.MAX_DEPTH
    if indent_level > max_depth then return '"<max depth reached>"' end
    visited = visited or {}
    local is_pretty = _G.ENV.PRETTY

    if type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "table" then
        if visited[value] then return '"<cyclic>"' end
        visited[value] = true

        local parts = {}
        if is_pretty then
            table.insert(parts, "{")
            for k, v in pairs(value) do
                local key_str = (type(k) == "string") and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
                table.insert(parts, generate_indent(indent_level + 1) .. key_str .. " = " .. serialize_value(v, indent_level + 1, visited, max_depth) .. ",")
            end
            table.insert(parts, generate_indent(indent_level) .. "}")
            visited[value] = nil
            return table.concat(parts, "\n")
        else
            table.insert(parts, "{")
            for k, v in pairs(value) do
                local key_str = (type(k) == "string") and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
                table.insert(parts, key_str .. " = " .. serialize_value(v, 0, visited, max_depth) .. ",")
            end
            table.insert(parts, "}")
            visited[value] = nil
            return table.concat(parts, " ")
        end
    else
        return "nil"
    end
end

--- Serializes a structured table.
--- @param structure table: The table to serialize.
--- @param indent_level number: The indentation level.
--- @param property_order string: Ordered list of keys to serialize.
--- @return string: Serialized string representation.
local function serialize_struct(structure, indent_level, property_order)
    local is_pretty = _G.ENV.PRETTY
    local parts = {}
    local visited = {}

    if is_pretty then
        table.insert(parts, generate_indent(indent_level) .. "{")
        for _, key in ipairs(property_order) do
            if structure[key] ~= nil then
                table.insert(parts, generate_indent(indent_level + 1) .. key .. " = " .. serialize_value(structure[key], indent_level + 1, visited) .. ",")
            end
        end
        table.insert(parts, generate_indent(indent_level) .. "}") 
        return table.concat(parts, "\n")
    else
        table.insert(parts, "{")
        for _, key in ipairs(property_order) do
            if structure[key] ~= nil then
                table.insert(parts, key .. " = " .. serialize_value(structure[key], 0, visited) .. ",")
            end
        end
        table.insert(parts, "}")
        return table.concat(parts, " ")
    end
end

--- Serializes an entire schema.
--- @param schema table: The table schema.
--- @return string: A serialized string `return {...}`.
local function serialize_schema(schema)
    local is_pretty = _G.ENV.PRETTY
    local parts = {}

    if is_pretty then
        table.insert(parts, "return {")
        for i, field_data in ipairs(schema) do
            if type(field_data) == "table" then
                local entry = serialize_struct(field_data, 1, property_order)
                table.insert(parts, generate_indent(1) .. string.format("[%d] = %s,", i, entry))
            end
        end
        table.insert(parts, "}")
        return table.concat(parts, "\n")
    else
        local entries = {}
        table.insert(parts, "return {")
        for i, field_data in ipairs(schema) do
            if type(field_data) == "table" then
                local entry = serialize_struct(field_data, 0, property_order)
                table.insert(entries, string.format("[%d] = %s,", i, entry))
            end
        end
        table.insert(parts, table.concat(entries, " ") .. " }")
        return table.concat(parts, " ")
    end
end

--- Serializes a set of records.
--- If primary_key is provided, each record is stored as `[key_value] = {...}`; otherwise numbered.
--- @param entries table: An array of record tables.
--- @param primary_key string: The field name used as the table key, or nil to use numeric indexing.
--- @return string: A serialized string `return {...}`.
local function serialize_entries(entries, primary_key)
    local is_pretty = _G.ENV.PRETTY
    local parts = {}

    if is_pretty then
        table.insert(parts, "return {")
        for i, entry in ipairs(entries) do
            local key_val = entry[primary_key] or i
            table.insert(parts, generate_indent(1) .. string.format("[%q] = %s,", tostring(key_val), serialize_value(entry, 1)))
        end
        table.insert(parts, "}")
        return table.concat(parts, "\n")
    else
        local entries_str = {}
        table.insert(parts, "return {")
        for i, entry in ipairs(entries) do
            local key_val = entry[primary_key] or i
            table.insert(entries_str, string.format("[%q] = %s,", tostring(key_val), serialize_value(entry, 0)))
        end
        table.insert(parts, table.concat(entries_str, " ") .. " }")
        return table.concat(parts, " ")
    end
end

--- @section Function Assignments

serializer.serialize_value   = serialize_value
serializer.serialize_struct  = serialize_struct
serializer.serialize_schema  = serialize_schema
serializer.serialize_entries = serialize_entries

return serializer
