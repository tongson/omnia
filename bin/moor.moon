env = {}
_ENV = setmetatable env, __index: _ENV

if (require'moor.opts') env, {k, v for k, v in pairs arg}
	moor = require'moor'

	L = require'linenoise'
	histfile = os.getenv"HOME" .. "/.moor_history"

	unless L.historyload histfile
		moor.printerr "failed to load commandline history"

	moor env, _ENV

	unless L.historysave histfile
		moor.printerr "failed to save commandline history"

os.exit env.MOOR_EXITCODE

