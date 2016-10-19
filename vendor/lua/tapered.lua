-- Helper variables and functions
local get_info = debug.getinfo
local pcall = pcall
local slice = string.sub
local sprintf = string.format
local str_find = string.find
local tonumber = tonumber
-- Lua 5.3 moved unpack to table.unpack
local unpack = unpack or table.unpack
local write = io.write
local rawget = rawget
local getmetatable = getmetatable
local exit = os.exit

---- Helper methods

--- C-like printf method
local printf = function(fmt, ...)
  write(sprintf(fmt, ...))
end

--- Compare potentially complex tables or objects
--
-- Ideas here are taken from [Penlight][p], [Underscore][u], [cwtest][cw], and
-- [luassert][l].
-- [p]: https://github.com/stevedonovan/Penlight
-- [u]: https://github.com/mirven/underscore.lua
-- [cw]: https://github.com/catwell/cwtest
-- [l]: https://github.com/Olivine-Labs/luassert
--
-- Predeclare both function names
local keyvaluesame
local deepsame
--
--- keyvaluesame(table, table) => true or false
-- Helper method to compare all the keys and values of a table
keyvaluesame = function (t1, t2)
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not deepsame(v1, v2) then return false end
  end

  -- Check for any keys present in t2 but not t1
  for k2, _ in pairs(t2) do
    if t1[k2] == nil then return false end
  end

  return true
end
--
--- deepsame(item, item) => true or false
-- Compare two items of any type for identity
deepsame = function (t1, t2)
  local ty1, ty2 = type(t1), type(t2)
  if ty1 ~= ty2 then return false end
  if ty1 ~= 'table' then return t1 == t2 end

  -- If ._eq is found, use == and end quickly.
  -- As of Lua 5.3 == only cares if **one** of the two items has a __eq
  -- metamethod. Penlight, underscore and cwtest take the same approach,
  -- so I will as well.
  local eq = rawget(getmetatable(t1) or {}, '__eq')
  if (type(eq) == 'function') then
    return not not eq(t1, t2)
  else
    return keyvaluesame(t1, t2)
  end
end

---- tapered test suite

local exit_status = 0
local test_count = 0
local debug_level = 3

local setup_call = function ()
  if _G["setup"] then return _G["setup"]() end
end

local teardown_call = function ()
  if _G["teardown"] then return _G["teardown"]() end
end

-- All other tests are defined in terms of this primitive, which is
-- kept private.
local _test = function (exp, msg)
  test_count = test_count + 1

  if msg then
    msg = sprintf(" - %s", msg)
  else
    msg = ''
  end

  setup_call()

  if exp then
    printf("ok %s%s\n", test_count, msg)
  else
    exit_status = 1 + exit_status
    printf("not ok %s%s\n", test_count, msg)
    local info = get_info(debug_level)
    printf("# Trouble in %s around line %s\n",
           slice(info.source, 2), info.currentline)
  end

  teardown_call()
end

local ok = function (expression, msg)
  _test(expression, msg)
end

local nok = function (expression, msg)
  _test(not expression, msg)
end

local is = function (actual, expected, msg)
  _test(actual == expected, msg)
end

local isnt = function (actual, expected, msg)
  _test(actual ~= expected, msg)
end

local same = function (actual, expected, msg)
  _test(deepsame(actual, expected), msg)
end

local like = function (str, pattern, msg)
  _test(str_find(str, pattern), msg)
end

local unlike = function (str, pattern, msg)
  _test(not str_find(str, pattern), msg)
end

local pass = function (msg)
  _test(true, msg)
end

local fail = function (msg)
  _test(false, msg)
end

local boom = function (func, args, msg)
  local err, errmsg
  err, errmsg = pcall(func, unpack(args))
  _test(not err, msg)
  if not err and type(errmsg) == 'string' then
    printf('# Got this error: "%s"\n', errmsg)
  end
end

local done = function (n)
  local expected = tonumber(n)
  if not expected or test_count == expected then
    printf('1..%d\n', test_count)
  elseif expected ~= test_count then
    exit_status = 1 + exit_status
    local s
    if expected == 1 then s = '' else s = 's' end
    printf("# Bad plan. You planned %d test%s but ran %d\n",
      expected, s, test_count)
  end
  exit(exit_status)
end

local version = function ()
  return "2.1.0"
end

local author = function ()
  return "Peter Aronoff"
end

local url = function ()
  return "https://bitbucket.org/telemachus/tapered"
end

local license = function ()
  return "BSD 3-Clause"
end

return {
  ok = ok,
  nok = nok,
  is = is,
  isnt = isnt,
  same = same,
  like = like,
  unlike = unlike,
  pass = pass,
  fail = fail,
  boom = boom,
  done = done,
  version = version,
  author = author,
  url = url,
  license = license
}
