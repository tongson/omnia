local ln = require('linenoise')
local remove, insert, concat
do
  local _obj_0 = table
  remove, insert, concat = _obj_0.remove, _obj_0.insert, _obj_0.concat
end
local printerr, to_lua, evalprint, init_moonpath, deinit_moonpath
do
  local _obj_0 = require('moor.utils')
  printerr, to_lua, evalprint, init_moonpath, deinit_moonpath = _obj_0.printerr, _obj_0.to_lua, _obj_0.evalprint, _obj_0.init_moonpath, _obj_0.deinit_moonpath
end
local prompt = {
  p = ">",
  deepen = function(self)
    self.p = "? "
  end,
  reset = function(self)
    self.p = ">"
  end
}
local cndgen
cndgen = function(env)
  return function(line)
    do
      local i1 = line:find('[.\\%w_]+$')
      if i1 then
        do
          local res = { }
          local front = line:sub(1, i1 - 1)
          local partial = line:sub(i1)
          local prefix, last = partial:match('(.-)([^.\\]*)$')
          local t, all = env
          if #prefix > 0 then
            local P = prefix:sub(1, -2)
            all = last == ''
            for w in P:gmatch('[^.\\]+') do
              t = t[w]
              if not (t) then
                return 
              end
            end
          end
          prefix = front .. prefix
          local append_candidates
          append_candidates = function(t)
            if type(t) == 'table' then
              for k in pairs(t) do
                if all or k:sub(1, #last) == last then
                  table.insert(res, prefix .. k)
                end
              end
            end
          end
          append_candidates(t)
          do
            local mt = getmetatable(t)
            if mt then
              append_candidates(mt.__index)
            end
          end
          return res
        end
      end
    end
  end
end
local compgen
compgen = function(env)
  local candidates = cndgen(env)
  return function(c, s)
    do
      local cc = candidates(s)
      if cc then
        local _list_0 = cc
        for _index_0 = 1, #_list_0 do
          local name = _list_0[_index_0]
          ln.addcompletion(c, name)
        end
      end
    end
  end
end
string.match_if_fncls = function(self)
  return self:match("[-=]>$") or self:match("class%s*$") or self:match("class%s+%w+$") or self:match("class%s+extends%s+%w+%s*$") or self:match("class%s+%w+%s+extends%s+%w+%s*$")
end
local get_line
get_line = function()
  do
    local line = ln.linenoise(prompt.p .. " ")
    if line and line:match('%S') then
      ln.historyadd(line)
    end
    return line
  end
end
local _G = _G
local replgen
replgen = function(get_line)
  return function(env, _ENV, ignorename)
    if env == nil then
      env = { }
    end
    if _ENV == nil then
      _ENV = _ENV
    end
    local iterlocals
    iterlocals = function()
      local i = 0
      return function()
        i = i + 1
        return _G.debug.getlocal(3, i)
      end
    end
    local added = { }
    if _G.type(ignorename) == "table" then
      for _index_0 = 1, #ignorename do
        local name = ignorename[_index_0]
        ignorename[name] = 1
      end
      for k, v in iterlocals() do
        if not (ignorename[k]) then
          env[k] = v
          if _ENV and not _ENV[k] then
            _ENV[k] = v
            added[k] = 1
          end
        end
      end
    elseif _G.type(ignorename) ~= "string" or ignorename == "*" then
      for k, v in iterlocals() do
        env[k] = v
        if _ENV and not _ENV[k] then
          _ENV[k] = v
          added[k] = 1
        end
      end
    end
    local block = { }
    ln.setcompletion(compgen(_ENV))
    local has_moonpath = init_moonpath()
    while true do
      local _continue_0 = false
      repeat
        local line = get_line()
        if not (line) then
          break
        elseif #line < 1 then
          _continue_0 = true
          break
        end
        local is_fncls, lua_code, err
        if line:match_if_fncls() then
          is_fncls, lua_code, err = true
        else
          is_fncls, lua_code, err = false, to_lua(line)
        end
        local ok = lua_code ~= nil
        if lua_code and not err then
          ok, err = evalprint(env, lua_code)
        elseif is_fncls or err:match("^Failed to parse") then
          insert(block, line)
          prompt.reset((function()
            do
              prompt:deepen()
              local is_conditionalstart = line:match("^if%s+" or line:match("^unless%s+"))
              while line and #line > 0 do
                line = get_line()
                if line and is_conditionalstart and line:match("^else$") or line:match("^else%s+") or line:match("^elseif%s+") then
                  _G.print("\x1b[1A\x1b[2K? " .. tostring(line))
                end
                insert(block, " " .. tostring(line))
              end
              return prompt
            end
          end)())
          lua_code, err = to_lua(concat(block, "\n"))
          if lua_code then
            local err_
            ok, err_ = evalprint(env, lua_code)
            if not (ok) then
              err = err_
            end
          end
          block = { }
        end
        if not ok and err then
          printerr(err)
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    for k in _G.pairs(added) do
      _ENV[k] = nil
    end
    deinit_moonpath(has_moonpath)
    return env
  end
end
local repl = replgen(get_line)
return setmetatable({
  replgen = replgen,
  repl = repl,
  printerr = printerr
}, {
  __call = function(self, env, _ENV, ignorename)
    return repl(env, _ENV, ignorename)
  end
})