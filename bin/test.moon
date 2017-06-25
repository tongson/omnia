T = require "u-test"

T["Function from a vendor/c module(lfs)"] = ->
   with T
     lfs = require"lfs"
     .equal type(lfs.rmdir), "function"

T["Function from vendor/posix module(luaposix)"] = ->
   with T
     libgen = require"posix.libgen"
     .equal type(libgen.basename), "function"

T["Function from a src/lua module(src)"] = ->
   with T
     src = require"src"
     .equal type(src.src), "function"

T["Function from a src/lua module directory (moonscript) (moon.src)"] = ->
   with T
     moon_slash_src = require"moon.src"
     .equal type(moon_slash_src.moon_slash_src), "function"

T["Function from a src/lua module (moonscript) (moon_src)"] = ->
   with T
     moon_src = require"moon_src"
     .equal type(moon_src.moon_src), "function"

T.summary!

