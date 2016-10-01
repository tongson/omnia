T = require"cwtest".new!

with T
   \start "Function from a vendor/c module(lfs)"
   lfs = require"lfs"
   \eq type(lfs.rmdir), "function"
   \exit! if not \done!
with T
   \start "Function from a src/lua module(src)"
   src = require"src"
   \eq type(src.src), "function"
   \exit! if not \done!
with T
   \start "Function from a src/lua module directory (moonscript) (moon.src)"
   moon_slash_src = require"moon.src"
   \eq type(moon_slash_src.moon_slash_src), "function"
   \exit! if not \done!
with T
   \start "Function from a src/lua module (moonscript) (moon_src)"
   moon_src = require"moon_src"
   \eq type(moon_src.moon_src), "function"
   \exit! if not \done!
