local script = arg[1]
local lua_script = arg[2]

local lib = require "cimicida"
local fmt = lib.fmt
local file = lib.file
local parse = require "moonscript.parse"
local compile = require "moonscript.compile"
local moonpick = require "moonpick"
local moonpick_config = require "moonpick.config"

local string = file.read_to_string(script)
if not string then
   fmt.panic("ERROR: Error reading %s!", script )
end

local parse_tree, parse_error = parse.string(string)
if not parse_tree then
   fmt.panic("ERROR: %s\n", parse_error)
end

local lint = function (linter, filename)
    local errors = 0
    local inspections, err = linter()
    if not inspections then
        errors = errors + 1
        fmt.warn("LINT: %s\n%s\n", filename, err)
    else
        if #inspections > 0 then
          errors = errors + #inspections
          fmt.warn("LINT: %s\n%s\n", filename, moonpick.format_inspections(inspections))
        end
    end
    if errors > 0 then fmt.panic("LINT: Found %d errors.\n", errors) end
end
local config_file = moonpick_config.config_for("bin/")
local config = config_file and moonpick_config.load_config_from(config_file, script) or {}
lint(function() return moonpick.lint(string, config) end, script)

local compiled_code, compile_posmap_or_error, compile_error_position = compile.tree(parse_tree)
if not compiled_code then
   fmt.panic("ERROR: %s\n", compile.format_error(compile_posmap_or_error, compile_error_position, string))
end

local written, write_error = file.write_all(lua_script, compiled_code)
if not written then
   fmt.panic("ERROR: Failed writing %s: %s\n", lua_script, write_error)
end
