local script = arg[1]
local lua_script = arg[2]
local lib = require "cimicida"
local fmt = lib.fmt
local file = lib.file
local fennel = require "fennel"
local string = file.read_to_string(script)
if not string then
   fmt.panic("ERROR: Error reading %s!", script )
end
local compiled_code = fennel.compileString(string)
compiled_code = compiled_code.."\n"
local written, write_error = file.write_all(lua_script, compiled_code)
if not written then
   fmt.panic("ERROR: Failed writing %s: %s\n", lua_script, write_error)
end
