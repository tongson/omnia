local parse = require("moonscript.parse")
local compile = require("moonscript.compile")
local append = table.insert
local quote
quote = function(v)
  if type(v) == 'string' then
    return ('%q'):format(v)
  else
    return tostring(v)
  end
end
local dump
dump = function(t, options)
  options = options or { }
  local limit = options.limit or 1000
  local buff = {
    tables = {
      [t] = true
    }
  }
  local k, tbuff = 1, nil
  local put
  put = function(v)
    buff[k] = v
    k = k + 1
  end
  local put_value
  put_value = function(value)
    if type(value) ~= 'table' then
      put(quote(value))
      if limit and k > limit then
        buff[k] = "..."
        error("buffer overrun")
      end
    else
      if not buff.tables[value] then
        buff.tables[value] = true
        tbuff(value)
      else
        put("<cycle>")
      end
    end
    return put(',')
  end
  tbuff = function(t)
    local mt
    if not (options.raw) then
      mt = getmetatable(t)
    end
    if type(t) ~= 'table' or mt and mt.__tostring then
      return put(quote(t))
    else
      put('{')
      local indices = #t > 0 and (function()
        local _tbl_0 = { }
        for i = 1, #t do
          _tbl_0[i] = true
        end
        return _tbl_0
      end)()
      for key, value in pairs(t) do
        local _continue_0 = false
        repeat
          if indices and indices[key] then
            _continue_0 = true
            break
          end
          if type(key) ~= 'string' then
            key = '[' .. tostring(key) .. ']'
          elseif key:match('%s') then
            key = quote(key)
          end
          put(key .. ':')
          put_value(value)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      if indices then
        for _index_0 = 1, #t do
          local v = t[_index_0]
          put_value(v)
        end
      end
      if buff[k - 1] == "," then
        k = k - 1
      end
      return put('}')
    end
  end
  pcall(tbuff, t)
  return table.concat(buff)
end
local is_pair_iterable
is_pair_iterable = function(t)
  return type(t) == 'table'
end
local lua_candidates
lua_candidates = function(line)
  local i1, i2 = line:find('[.\\%w_]+$')
  if i1 == nil then
    return
  end
  local front = line:sub(1, i1 - 1)
  local partial = line:sub(i1)
  local prefix, last = partial:match('(.-)([^.\\]*)$')
  local t, all = _G
  if #prefix > 0 then
    local P = prefix:sub(1, -2)
    all = last == ''
    for w in P:gmatch('[^.\\]+') do
      t = t[w]
      if not t then
        return
      end
    end
  end
  prefix = front .. prefix
  local res = { }
  local append_candidates
  append_candidates = function(t)
    for k, v in pairs(t) do
      if all or k:sub(1, #last) == last then
        append(res, prefix .. k)
      end
    end
  end
  if is_pair_iterable(t) then
    append_candidates(t)
  end
  local mt = getmetatable(t)
  if mt and is_pair_iterable(mt.__index) then
    append_candidates(mt.__index)
  end
  return res
end
local oldg
do
  local _tbl_0 = { }
  for k, v in pairs(_G) do
    _tbl_0[k] = v
  end
  oldg = _tbl_0
end
_G._FOO = true
local newglobs
newglobs = function()
  local _accum_0 = { }
  local _len_0 = 1
  for k in pairs(_G) do
    if not oldg[k] then
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local chopline
chopline = function(txt)
  return txt:gsub('^[^\n]+\n', '', 1)
end
local firstline
firstline = function(txt)
  return txt:match('^[^\n]*')
end
local mytostring = tostring
local capture
capture = function(ok, ...)
  local t = {
    ...
  }
  t.n = select('#', ...)
  return ok, t
end
local eval_lua
eval_lua = function(lua_code)
  local chunk, err = load(lua_code, 'tmp')
  if err then
    print(err)
    return
  end
  local res
  ok, res = capture(pcall(chunk))
  if not ok then
    print(res[1])
    return
  elseif #res > 0 then
    _G._l = res[1]
    local out
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, res.n do
        _accum_0[_len_0] = mytostring(res[i])
        _len_0 = _len_0 + 1
      end
      out = _accum_0
    end
    return io.write(table.concat(out, '\t'), '\n')
  end
end
local old_lua_code = nil
local eval_moon
eval_moon = function(moon_code)
  local locs = 'local ' .. table.concat(newglobs(), ',')
  moon_code = locs .. '\n' .. moon_code
  local tree, err = parse.string(moon_code)
  if not tree then
    print(err)
    return
  end
  local lua_code, pos
  lua_code, err, pos = compile.tree(tree)
  if not lua_code then
    print(compile.format_error(err, pos, moon_code))
    return
  end
  lua_code = chopline(lua_code)
  local was_local, rest = lua_code:match('^local (%S+)(.+)')
  if was_local then
    if rest:match('\n') then
      rest = firstline(rest)
    end
    if rest:match('=') then
      lua_code = lua_code:gsub('^local%s+', '')
    else
      lua_code = chopline(lua_code)
    end
  end
  old_lua_code = lua_code
  return eval_lua(lua_code)
end
local opts, i = { }, 0
local nexta
nexta = function()
  i = i + 1
  return arg[i]
end
while true do
  local a = nexta()
  if not a then
    break
  end
  local flag, rest = a:match('^%-(%a)(%S*)')
  if flag == 'l' then
    local lib = (rest and #rest > 0) and rest or nexta()
    require(lib)
  elseif flag == 'e' then
    eval_moon(nexta())
    os.exit(0)
  end
end
mytostring = dump
_G.tstring = mytostring
local normal, block = '> ', '>> '
local prompt = normal
local get_line = nil
get_line = function()
  io.write(prompt)
  return io.read()
end
print('MoonScript version 0.2.3')
print('Note: use backslash at line end to start a block')
while true do
  local line = get_line()
  if not line then
    break
  end
  if line:match('[\t\\]$') then
    prompt = block
    line = line:gsub('\\$', '')
    local code = {
      line
    }
    line = get_line()
    while #line > 0 do
      append(code, line)
      line = get_line()
    end
    prompt = normal
    code = table.concat(code, '\n')
    eval_moon(code)
  elseif line:match('^%?que') then
    print(old_lua_code)
  else
    eval_moon(line)
  end
end
