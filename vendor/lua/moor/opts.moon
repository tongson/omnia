import printerr, to_lua, fnwrap, evalprint, init_moonpath, deinit_moonpath from require'moor.utils'

-- lasting loop or not
loopflag = true
-- send 0 or 1 to `os.exit` at the end of repl
exitcode = 0

eval_moon = (env, txt, non_verbose) ->
	lua_code, err = to_lua txt

	if err then nil, err
	else evalprint env, lua_code, non_verbose

nextagen = => -> table.remove @, 1

msg = ->
	printerr 'Usage: moonr [options]\n',
		'\n',
		'   -h         print this message\n',
		'   -e STR     execute string as MoonScript code and exit\n',
		'   -E STR     execute string as MoonScript code and run REPL\n',
		'   -l LIB     load library before running REPL\n',
		'   -L LIB     execute `LIB = require"LIB"` before running REPL\n',
		''

	loopflag = false
	exitcode = 1

loadlib = (env, lib) ->
	ok, cont = eval_moon env, "return require '#{lib}'", true

	unless ok
		printerr cont

		msg!

	cont

evalline = (env, line) ->
	ok, err = eval_moon env, line

	unless ok
		printerr err

		msg!

(env, arg) ->
	local is_exit
	is_splash = true
	nexta = nextagen arg

	while loopflag
		a = nexta!

		break unless a

		flag, rest = a\match '^%-(%a)(.*)'

		unless flag
			printerr "Failed to parse argument: #{a}"
			msg!

		lstuff = #rest > 0 and rest or nexta!

		switch flag
			when 'l'
				loadlib env, lstuff
			when 'L'
				if lib = loadlib env, lstuff
					env[rest] = lib
			when 'e'
				is_exit = true
				is_splash = evalline env, lstuff
			when 'E'
				is_splash = evalline env, lstuff
			else
				if "#{flag}#{rest}" == "no-splash" then is_splash = false
				else
					printerr "invlid flag: #{flag}" unless flag == "h"
					is_splash = msg!
					is_exit = true

	printerr "moor on MoonScript version #{(require 'moonscript.version').version} on #{_VERSION}" if is_splash

	env.MOOR_EXITCODE =  exitcode
	not is_exit

