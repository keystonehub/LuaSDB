--[[
----------------------------------------------
 _  _________   ______ _____ ___  _   _ _____ 
| |/ / ____\ \ / / ___|_   _/ _ \| \ | | ____|
| " /|  _|  \ V /\___ \ | || | | |  \| |  _|  
| . \| |___  | |  ___) || || |_| | |\  | |___ 
|_|\_\_____| |_| |____/ |_| \___/|_| \_|_____|
----------------------------------------------                                               
              LUA Simple Database
                    V0.0.0              
----------------------------------------------
]]

fx_version "cerulean"
games { "gta5", "rdr3" }

name "keystone"
version "0.0.0"
description "Keystone - A Simple LUA File Based Database"
author "Case"
repository "https://github.com/keystonehub/luasdb"
lua54 "yes"

server_script "init.lua"

server_scripts {
    --- Database files
    "database/**/*.lua",

    --- Modules
    "modules/*.lua",

    --- Testing remove/comment out if not needed
    "cfx_tests.lua"
}