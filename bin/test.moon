T = require"cwtest".new!
lfs = require"lfs"
src = require"src"
moon_slash_src = require"moon.src"
moon_src = require"moon_src"

with T
   \start "Function from a vendor/c module(lfs)"
   \eq type(lfs.rmdir), "function"
   \exit! if not \done!
with T
   \start "Function from a src/lua module(src)"
   \eq type(src.src), "function"
   \exit! if not \done!
with T
   \start "Function from a src/lua module directory (moonscript) (moon.src)"
   \eq type(moon_slash_src.moon_slash_src), "function"
   \exit! if not \done!
with T
   \start "Function from a src/lua module (moonscript) (moon_src)"
   \eq type(moon_src.moon_src), "function"
   \exit! if not \done!
