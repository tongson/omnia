parse = require'moonscript.parse'
compile = require'moonscript.compile'
inspect = require'inspect'
ms = require'moonscript.base'
import remove, insert, concat from table

init_moonpath = ->
	moonpath = package.moonpath
	ms.insert_loader!

	moonpath != nil

deinit_moonpath = (has_moonpath) ->
	ms.remove_loader!
	unless has_moonpath
		package.moonpath = nil

printerr = (...) -> io.stderr\write "#{concat {...}, "\t"}\n"

to_lua = (code) ->
	tree, err = parse.string code

	return nil, err if err

	lua_code, err, pos = compile.tree tree

	unless lua_code
		nil, compile.format_error err, pos, code
	else lua_code

-- Lua evaluator & printer
fnwrap = (code) -> "return function(__newenv) local _ENV = setmetatable(__newenv, {__index = _ENV}) #{code} end"

evalprint = (env, lua_code, non_verbose) ->
	has_moonpath = init_moonpath!

	if nolocal = lua_code\match "^local%s+(.*)"
		lua_code = nolocal
		unless lua_code\match "^[^\n]*="
			lua_code = lua_code\match"^.-\n(.*)"

	luafn, err = load fnwrap(lua_code != nil and lua_code or ""), "tmp"

	return printerr err if err

	result = {pcall luafn!, env}

	deinit_moonpath has_moonpath

	ok = remove result, 1

	ok, unless ok then result[1]
	else
		if #result > 0
			print (inspect result)\match"^%s*{%s*(.*)%s*}%s*%n?%s*$" unless non_verbose
			table.unpack result

{:printerr, :to_lua, :fnwrap, :evalprint, :init_moonpath, :deinit_moonpath}
