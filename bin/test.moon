T = require"tapered"

with T
   lfs = require"lfs"
   M = "Function from a vendor/c module(lfs)"
   .same type(lfs.rmdir), "function", M
with T
   libgen = require"posix.libgen"
   M = "Function from vendor/posix module(luaposix)"
   .same type(libgen.basename), "function", M
with T
   src = require"src"
   M = "Function from a src/lua module(src)"
   .same type(src.src), "function", M
with T
   moon_slash_src = require"moon.src"
   M = "Function from a src/lua module directory (moonscript) (moon.src)"
   .same type(moon_slash_src.moon_slash_src), "function", M
with T
   moon_src = require"moon_src"
   M = "Function from a src/lua module (moonscript) (moon_src)"
   .same type(moon_src.moon_src), "function", M

T.done(5)
