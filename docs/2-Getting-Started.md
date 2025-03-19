# 2 - Getting Started

Below are general steps to help you begin using this file-based Lua database, either standalone or on CFX platforms (FiveM/RedM).

---

# Prerequisites

- **Basic Knowledge of Lua**: Familiarity with running Lua scripts, requiring modules, and basic Lua syntax.  
- **Lua 5.4 Installed** For standalone usage: Verify with `lua -v` in your terminal.  
- **CFX Server** If using FiveM/RedM: Ensure your environment is properly set up.  

--- 

# Configuration

```lua
--- Environment Variables.
ENV = setmetatable({
    --- Stores dont touch.
    SCHEMAS = {},
    TABLES = {},
    STATIC = {},
    MODULES = {},
    
    --- Configurable.
    MODE = "dev", -- Specifies where files should be loaded from/saved to; Options: "dev", "prod"
    QUEUE_THRESHOLD = 100, -- Queue will "auto-flush" and save to files once threshold has been reached.
    PRETTY = true, -- Toggle pretty printing this will put each entry onto a single line.
    INDENTATION = 4, -- Controls the amount of indentation applied. 
    MAX_DEPTH = 50 -- Maximum nesting depth before serialization cuts off.

}, { __index = _G })
```

---

# Standalone

- Download the latest release repo.
- Open terminal and navigate (`cd`) to the LuaSDB folder.
- Interact with the database through the LuaSDB `API` functions, for more details view **3-API.md**.
- For specific use case projects this is down to you to intergrate.

## Testing Standalone

- Use `lua standalone_test.lua command` where `command` can be:
    - `create_table`
    - `insert`
    - `insert_bulk [num]`
    - `select_all`
    - `update_all`

```bash
lua standalone_test.lua create_table
lua standalone_test.lua insert
lua standalone_test.lua insert_bulk 20
lua standalone_test.lua select_all
lua standalone_test.lua update_all
```

# CFX Platforms (FiveM / RedM)

- Download the latest release repo.
- Add LuaSDB into your server resources.
- Add `ensure LuaSDB` to your `server.cfg`.
- Get the `API` into your project through `exports.LuaSDB:get_api()`.
- Interact with the database through the LuaSDB `API` functions, for more details view **3-API.md**.
- For specific use case projects this is up to you, should be some places this can be used in script development.

## Testing CFX

- Use `/command` where `command` can be:
    - `test_create_table`
    - `test_bulk_insert [num]`

```bash
/test_create_table
/test_bulk_insert
```