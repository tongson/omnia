local Script = arg[1]
local Lua_Script = arg[2]

local Lib = require"cimicida"
local Parse = require"moonscript.parse"
local Compile = require"moonscript.compile"

local String = Lib.fopen(Script)
if not String then
   Lib.errorf("ERROR: Error reading %s!", Script )
end

local Parse_Tree, Parse_Error = Parse.string(String)
if not Parse_Tree then
   Lib.errorf("ERROR: %s\n", Parse_Error)
end

local Compiled_Code, Compile_PosMap_Or_Error, Compile_Error_Position = Compile.tree(Parse_Tree)
if not Compiled_Code then
   Lib.errorf("ERROR: %s\n", Compile.format_error(Compile_PosMap_Or_Error, Compile_Error_Position, String))
end

local Written, Write_Error = Lib.fwrite(Lua_Script, Compiled_Code)
if not Written then
   Lib.errorf("ERROR: Failed writing %s: %s\n", Lua_Script, Write_Error)
end
