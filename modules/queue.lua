--- @module Queue
--- Handles bulk database operations.

--- @section Require Modules

local DEBUG = require("modules.debugging") 
local WRITER = require("modules.writer")
local READER = require("modules.reader")

--- @section Constants

--- The number of operations to buffer before auto-flush.
local THRESHOLD = _G.ENV.QUEUE_THRESHOLD or 100

--- @section Stores

--- Store buffers.
local insert_buffers = {}
local update_buffers = {}

--- Store tasks.
local tasks = {}

--- @section Module

local queue = {}

--- Capture the main thread for yielding checks.
local main_thread = coroutine.running()

--- Runs all tasks in the task queue.
--- @return void
local function run_tasks()
    while #tasks > 0 do
        for i = #tasks, 1, -1 do
            local task = tasks[i]
            local ok, err = coroutine.resume(task.co, table.unpack(task.args))
            if coroutine.status(task.co) == "dead" then
                table.remove(tasks, i)
            end
        end

        if coroutine.running() and coroutine.running() ~= main_thread then
            coroutine.yield()
        end
    end
end

--- Adds a task to the task queue.
--- @param fn function: The function to run as a task.
--- @param ... any: Arguments for the task.
local function add_task(fn, ...)
    local co = coroutine.create(fn)
    table.insert(tasks, { co = co, args = { ... } })
    run_tasks()
end

--- @section Bulk Insert Functions

--- Flushes the bulk insert buffer.
--- @param table_name string: The name of the table.
--- @return boolean, string: Success status and message.
local function flush_inserts(table_name)
    local buffer = insert_buffers[table_name]
    if not buffer or #buffer == 0 then return true, "No pending inserts." end

    local table_data = READER.table(table_name) or {}
    for _, record in ipairs(buffer) do
        table.insert(table_data, record)
    end

    local schema = READER.schema(table_name)
    if not schema then return false, ("Schema '%s' not found."):format(table_name) end

    local success = WRITER.table(table_name, table_data, schema, true)
    if success then
        DEBUG.print('info', ("Queue: Flushed %d insert operations to table '%s'."):format(#buffer, table_name))
        insert_buffers[table_name] = {}
        return true, "Flushed inserts successfully."
    else
        return false, "Failed to flush bulk inserts."
    end
end

--- Task function to flush inserts for a given table.
--- @param table_name string: The name of the table.
local function flush_inserts_task(table_name)
    local ok, msg = flush_inserts(table_name)
    if not ok then
        DEBUG.print('error', ("Queue: Task insert flush failed for '%s': %s"):format(table_name, msg))
    end
end

--- Adds a record to the bulk insert buffer for the given table.
--- If the buffer reaches threshold, adds a flush task.
--- @param table_name string: The name of the table.
--- @param record table: The record to insert.
local function add_insert(table_name, record)
    if not insert_buffers[table_name] then
        insert_buffers[table_name] = {}
    end
    table.insert(insert_buffers[table_name], record)

    if #insert_buffers[table_name] >= THRESHOLD then
        add_task(flush_inserts_task, table_name)
    end
end

--- @section Bulk Update Functions

--- Flushes the update buffer for the given table to disk.
--- @param table_name string: The name of the table.
--- @return boolean, string: Success status and message.
local function flush_updates(table_name)
    local buffer = update_buffers[table_name]
    if not buffer or #buffer == 0 then return true, "No pending updates." end

    local table_data = READER.table(table_name) or {}
    local schema = READER.schema(table_name)
    if not schema then return false, ("Schema '%s' not found."):format(table_name) end

    local total_updates = 0

    for _, upd in ipairs(buffer) do
        local filters = upd.filters
        local updates = upd.updates
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
                total_updates = total_updates + 1
            end
        end
    end

    local success = WRITER.table(table_name, table_data, schema, true)
    if success then
        DEBUG.print('info', ("Queue: Flushed %d update operations to table '%s'."):format(#buffer, table_name))
        update_buffers[table_name] = {}
        return true, ("Updated %d record(s)."):format(total_updates)
    else
        return false, "Failed to flush bulk updates."
    end
end

--- Task function to flush updates for a given table.
--- @param table_name string: The name of the table.
local function flush_updates_task(table_name)
    local ok, msg = flush_updates(table_name)
    if not ok then
        DEBUG.print('error', ("Queue: Task update flush failed for '%s': %s"):format(table_name, msg))
    end
end

--- Adds an update operation.
--- @param table_name string: The name of the table.
--- @param filters table: The filters to match records for update.
--- @param updates table: The fields and new values to update.
local function add_update(table_name, filters, updates)
    if not update_buffers[table_name] then
        update_buffers[table_name] = {}
    end
    table.insert(update_buffers[table_name], { filters = filters, updates = updates })

    if #update_buffers[table_name] >= THRESHOLD then
        add_task(flush_updates_task, table_name)
    end
end

--- @section Flush All

--- Flushes all pending inserts and updates.
local function flush_all()
    for table_name, _ in pairs(insert_buffers) do
        add_task(flush_inserts_task, table_name)
    end
    for table_name, _ in pairs(update_buffers) do
        add_task(flush_updates_task, table_name)
    end
    run_tasks()
end

--- @section Function Assignments

queue.add_insert = add_insert
queue.flush_inserts = flush_inserts
queue.add_update = add_update
queue.flush_updates = flush_updates
queue.flush_all = flush_all

return queue
