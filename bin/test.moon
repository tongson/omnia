T = require"tapered"

with T
   lfs = require"lfs"
   what "Function from a vendor/c module(lfs)"
   .same type(lfs.rmdir), "function", what
with T
   src = require"src"
   .same type(src.src), "function", "Function from a src/lua module(src)"
with T
   moon_slash_src = require"moon.src"
   .same type(moon_slash_src.moon_slash_src), "function", "Function from a src/lua module directory (moonscript) (moon.src)"
with T
   moon_src = require"moon_src"
   .same type(moon_src.moon_src), "function", "Function from a src/lua module (moonscript) (moon_src)"

T.done(4)
