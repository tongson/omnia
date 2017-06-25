local script = arg[1]
local lua_script = arg[2]

local lib = require "cimicida"
local fmt = lib.fmt
local file = lib.file
local parse = require "moonscript.parse"
local compile = require "moonscript.compile"

local string = file.read_to_string(script)
if not string then
   fmt.panic("ERROR: Error reading %s!", script )
end

local parse_tree, parse_error = parse.string(string)
if not parse_tree then
   fmt.panic("ERROR: %s\n", parse_error)
end

local compiled_code, compile_posmap_or_error, compile_error_position = compile.tree(parse_tree)
if not compiled_code then
   fmt.panic("ERROR: %s\n", compile.format_error(compile_posmap_or_error, compile_error_position, string))
end

local written, write_error = file.write_all(lua_script, compiled_code)
if not written then
   fmt.panic("ERROR: Failed writing %s: %s\n", lua_script, write_error)
end
