#!bin/lua
package.path = "vendor/lua/?.lua;vendor/lua/?/init.lua"
local script = arg[1]
local lua_script = arg[2]
local lib = require "cimicida"
local string = lib.string
local fmt = lib.fmt
local file = lib.file
local fennel = require "fennel"
local code = file.read_to_string(script)
if not code then
  fmt.panic("ERROR: Error reading %s!", script )
end
local compiled_code = fennel.compileString(code)
local n
while true do -- remove blank lines
  compiled_code, n = string.gsub(compiled_code, "(\n)[%s]*\n", "%1")
  if n == 0 then break end
end
while true do -- remove trailing spaces
  compiled_code, n = string.gsub(compiled_code, "[%s]+(\n)", "%1")
  if n == 0 then break end
end
local x = #(string.line_to_array(compiled_code))
while true do -- remove indention
  n = n + 1
  compiled_code = string.gsub(compiled_code, "\n[%s]+", "\n")
  if x == n then break end
end
compiled_code = compiled_code.."\n"
local written, write_error = file.write_all(lua_script, compiled_code)
if not written then
   fmt.panic("ERROR: Failed writing %s: %s\n", lua_script, write_error)
end
