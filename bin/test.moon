a=require"lfs"
b=require"src"
c=require"moon.src"
d=require"moon_src"
assert(type(a.rmdir) == "function")
assert(type(b.src) == "function")
assert(type(c.moon_slash_src) == "function")
assert(type(d.moon_src) == "function")
print"OK!"
