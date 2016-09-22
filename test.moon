a=require"re"
b=require"src"
c=require"moon.src"
d=require"moon_src"
assert(type(a.match) == "function")
assert(type(a.compile) == "function")
assert(type(a.gsub) == "function")
assert(type(a.updatelocale) == "function")
assert(type(a.find) == "function")
assert(type(b.src) == "function")
assert(type(c.moon_slash_src) == "function")
assert(type(d.moon_src) == "function")
print"OK!"
