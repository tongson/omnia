ln = require'linenoise'
import remove, insert, concat from table
import printerr, to_lua, evalprint, init_moonpath, deinit_moonpath from require'moor.utils'

prompt =
	p: ">"
	deepen: => @p = "? "
	reset: => @p = ">"

---- tab completion
cndgen = (env) ->  (line) ->
	if i1 = line\find '[.\\%w_]+$' -- if completable
		with res = {}
			front = line\sub(1, i1 - 1)
			partial = line\sub i1
			prefix, last = partial\match '(.-)([^.\\]*)$'
			t, all = env

			if #prefix > 0 -- tbl.ky or not
				P = prefix\sub(1, -2)
				all = last == ''

				for w in P\gmatch '[^.\\]+'
					t = t[w]

					return unless t

			prefix = front .. prefix

			append_candidates = (t) ->
				if type(t) == 'table'
					table.insert(res, prefix .. k) for k in pairs t when all or k\sub(1, #last) == last

			append_candidates t

			if mt = getmetatable t then append_candidates mt.__index

compgen = (env) ->
	candidates = cndgen env

	(c, s) -> if cc = candidates s
		ln.addcompletion c, name for name in *cc

string.match_if_fncls = =>
	@\match"[-=]>$" or
	@\match"class%s*$" or
	@\match"class%s+%w+$" or
	@\match"class%s+extends%s+%w+%s*$" or
	@\match"class%s+%w+%s+extends%s+%w+%s*$"

-- for busted unit test, repl is sepalated with `get_line` and `replgen`
-- and using the former for the test, the latter is only needed by `repl`.

get_line = ->
	with line = ln.linenoise prompt.p .. " "
		if line and line\match '%S' then ln.historyadd line


-- because `_ENV` overrides itself, we must save global vars
_G = _G

replgen = (get_line) -> (env = {}, _ENV = _ENV, ignorename) ->
	iterlocals = ->
		i = 0
		->
			i += 1
			_G.debug.getlocal 3, i -- 3, caller's top level

	added = {}

	if _G.type(ignorename) == "table"
		for name in *ignorename
			ignorename[name] = 1

		for k, v in iterlocals!
			unless ignorename[k]
				env[k] = v

				if _ENV and not _ENV[k]
					_ENV[k] = v
					added[k] = 1
	elseif _G.type(ignorename) != "string" or ignorename == "*"
		for k, v in iterlocals!
			env[k] = v

			if _ENV and not _ENV[k]
				_ENV[k] = v
				added[k] = 1

	block = {}

	ln.setcompletion compgen _ENV

	-- `require`able moon file
	has_moonpath = init_moonpath!

	while true
		line = get_line!

		unless line then break
		elseif #line < 1 then continue

		-- if line\match"^:"
			-- (require'moor.replcmd') line
			-- continue

		is_fncls, lua_code, err =  if line\match_if_fncls!
			true
		else
			false, to_lua line

		ok = lua_code != nil

		if lua_code and not err
			ok, err = evalprint env, lua_code
		elseif is_fncls or err\match "^Failed to parse"
			insert block, line

			prompt.reset with prompt
				\deepen!

				is_conditionalstart = line\match "^if%s+" or line\match"^unless%s+"

				while line and #line > 0
					line = get_line!

					-- display-specific `else` indent adjust with escape sequence
					if line and is_conditionalstart and line\match"^else$" or line\match"^else%s+" or line\match"^elseif%s+"
						_G.print "\x1b[1A\x1b[2K? #{line}"
					insert block, " #{line}"

			lua_code, err = to_lua concat block, "\n"

			if lua_code
				ok, err_ = evalprint env, lua_code
				err = err_ unless ok

			block = {}

		if not ok and err
			printerr err

	for k in _G.pairs added
		_ENV[k] = nil

	-- `require`able moon file deinit
	deinit_moonpath has_moonpath

	env

-- this is main repl
repl = replgen get_line

setmetatable {:replgen, :repl, :printerr},
	__call: (env, _ENV, ignorename) => repl env, _ENV, ignorename

