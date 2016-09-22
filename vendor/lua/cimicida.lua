--- Additional functions. Can also be called from the `lib` module.
-- @module lib
local io, string, os, table = io, string, os, table
local type, pcall, load, setmetatable, ipairs, next = type, pcall, load, setmetatable, ipairs, next
local has_px, px = pcall(require, "px")
if has_px then
end
local ENV = {}
_ENV = ENV

--- Output formatted string to the current output.
-- @tparam string str C-like string
-- @tparam varargs ... Variable number of arguments to interpolate str
local printf = function (str, ...)
  io.write(string.format(str, ...))
end

--- Output formatted string to a specified output.
-- @tparam userdata fd stream/descriptor
-- @tparam string str C-like string
-- @tparam varargs ... Variable number of arguments to interpolate str
local fprintf = function (fd, str, ...)
  local o = io.output()
  io.output(fd)
  local ret, err = printf(str, ...)
  io.output(o)
  return ret, err
end

--- Output formatted string to STDERR.
-- @tparam string str C-like string
-- @tparam varargs ... Variable number of arguments to interpolate str
local warn = function (str, ...)
  fprintf(io.stderr, str, ...)
end

--- Output formatted string to STDERR and return 1 as the exit status.
-- @tparam string str C-like string
-- @tparam varargs ... Variable number of arguments to interpolate str
local errorf = function (str, ...)
  warn(str, ...)
  os.exit(1)
end

--- Call cimicida.errorf if the first argument is false (i.e. nil or false).
-- @tparam bool v value to evaluate
-- @tparam string str C-like string
-- @tparam varargs ... Variable number of arguments to interpolate str
local assertf = function (v, str, ...)
  if v then
    return true
  else
    errorf(str, ...)
  end
end

--- Append a line break and string to an input string.
-- @tparam string str input string
-- @tparam string a string to append to str
-- @treturn string new string
local append = function (str, a)
  return string.format("%s\n%s", str, a)
end

--- Time in the strftime(3) format %H:%M.
-- @treturn string the time as a string
local time_hm = function ()
  return os.date("%H:%M")
end


--- Date in the strftime(3) format %Y-%m-%d.
-- @treturn string the date as a string
local date_ymd = function ()
  return os.date("%Y-%m-%d")
end

--- Timestamp in the strftime(3) format %Y-%m-%d %H:%M:%S %Z%z.
-- @treturn string the timestamp as a string
local timestamp = function ()
  return os.date("%Y-%m-%d %H:%M:%S %Z%z")
end

--- Check if a table has an specified string.
-- @tparam table tbl table to search
-- @tparam string str plain string or pattern to look for in tbl
-- @tparam bool plain if true, turns off pattern matching facilities
-- @treturn bool a boolean value, true if v is found, nil otherwise
local find_string = function (tbl, str, plain)
  for _, tval in next, tbl do
    tval = string.gsub(tval, '[%c]', '')
    if string.find(tval, str, 1, plain) then return true end
  end
end

--- Convert an array to a record.
-- Array values are converted into field names.
-- @warning Does not check if input table is a sequence.
-- @tparam table tbl the properly sequenced table to convert
-- @param def default value for each field in the record. Should not be nil
-- @treturn table the converted table
local arr_to_rec = function (tbl, def)
  local t = {}
  for n = 1, #tbl do t[tbl[n]] = def end
  return t
end

--- Convert string to table.
-- Each line is a table value.
-- @tparam string str string to convert
-- @treturn table a new table
local ln_to_tbl = function (str)
  local tbl = {}
  if not str then
    return tbl
  end
  for ln in string.gmatch(str, "([^\n]*)\n") do
    tbl[#tbl + 1] = ln
  end
  return tbl
end

--- Split alphanumeric matches of a string into table values.
-- @tparam string str string to convert
-- @treturn table a new
local word_to_tbl = function (str)
  local t = {}
  for s in string.gmatch(str, "%w+") do
    t[#t + 1] = s
  end
  return t
end

--- Split non-space character matches of a string into table values.
-- @tparam string str string to convert
-- @treturn table a new table
local str_to_tbl = function (str)
  local t = {}
  for s in string.gmatch(str, "%S+") do
    t[#t + 1] = s
  end
  return t
end

--- Escape a string for pattern usage.
-- From lua-nucleo.
-- @tparam string str string to escape
-- @treturn string a new string
local escape_pattern = function (str)
  local matches =
  {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
    ["\0"] = "%z"
  }
  return string.gsub(str, ".", matches)
end

--- Filter table values.
-- Adapted from <http://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating>
-- @tparam table tbl table to operate on
-- @tparam string patt pattern to filter
-- @tparam bool plain set to true if true, turns of pattern matching facilities
-- @treturn table modified table
local filter_tbl_value = function (tbl, patt, plain)
  plain = plain or nil
  local s, c = #tbl, 0
  for n = 1, s do
    if string.find(tbl[n], patt, 1, plain) then
      tbl[n] = nil
    end
  end
  for n = 1, s do
    if tbl[n] ~= nil then
      c = c + 1
      tbl[c] = tbl[n]
    end
  end
  for n = c + 1, s do
    tbl[n] = nil
  end
  return tbl
end

--- Convert file into a table.
-- Each line is a table value
-- @tparam string file file to convert
-- @treturn table a new table
local file_to_tbl = function (file)
  local _, fd = pcall(io.open, file, "re")
  if fd then
    io.flush(fd)
    local tbl = {}
    for ln in fd:lines("*L") do
      tbl[#tbl + 1] = ln
    end
    io.close(fd)
    return tbl
  end
end

--- Find a string in a table value.
-- string is a plain string not a pattern
-- @tparam table tbl properly sequenced table to traverse
-- @tparam string str string or pattern to look for
-- @tparam bool plain set to true if true, turns of pattern matching facilities
-- @treturn number the matching index if string is found, nil otherwise
local find_in_tbl = function (tbl, str, plain)
  plain = plain or nil
  local ok, found
  for n = 1, #tbl do
    ok, found = pcall(Lua.find, tbl[n], str, 1, plain)
    if ok and found then
      return n
    end
  end
end

--- Do a shallow copy of a table.
-- An empty table is created in the copy when a table is encountered
-- @tparam table tbl table to be copied
-- @treturn table a new table
local shallow_cp = function (tbl)
  local copy = {}
  for f, v in next, tbl do
    if type(v) == "table" then
      copy[f] = {} -- first level only
    else
      copy[f] = v
    end
  end
  return copy
end

--- Split a path into its immediate location and file/directory components.
-- @tparam string path path to split
-- @treturn string location
-- @treturn string file/directory
local split_path = function (path)
  local l = string.len(path)
  local c = string.sub(path, l, l)
  while l > 0 and c ~= "/" do
    l = l - 1
    c = string.sub(path, l, l)
  end
  if l == 0 then
    return '', path
  else
    return string.sub(path, 1, l - 1), string.sub(path, l + 1)
  end
end


--- Check if a path is a file or not.
-- @tparam string file path to the file
-- @return true if path is a file, nil otherwise
local test_open = function (file)
  local fd = io.open(file, "rb")
  if fd then
    io.close(fd)
    return true
  end
end

--- Read a file/path.
-- @tparam string file path to the file
-- @treturn string the contents of the file, nil if the file cannot be read or opened
local fopen = function (file)
  local str
  for s in io.lines(file, 2^12) do
    str = string.format("%s%s", str or "", s)
  end
  if string.len(str) ~= 0 then
    return str
  end
end

--- Write a string to a file/path.
-- @tparam string path path to the file
-- @tparam string str string to write
-- @tparam string mode io.open mode
-- @return true if the write succeeded, nil and the error message otherwise
local fwrite = function (path, str, mode)
  local setvbuf, write = io.setvbuf, io.write
  mode = mode or "we+"
  local fd = io.open(path, mode)
  if fd then
    fd:setvbuf("no")
    local _, err = fd:write(str)
    io.flush(fd)
    io.close(fd)
    if err then
      return nil, err
    end
    return true
  end
end

--- Get line.
-- Given a line number return the line as a string.
-- @tparam number ln line number
-- @tparam string file
-- @treturn string the line
local get_ln = function (ln, file)
  local str = fopen(file)
  local i = 0
  for line in string.gmatch(str, "([^\n]*)\n") do
    i = i + 1
    if i == ln then return line end
  end
end

--- Simple string interpolation.
-- Given a record, interpolate by replacing field names with the respective value
-- Example:
-- tbl = { "field" = "value" }
-- str = [[ this is the {{ field }} ]]
-- If passed with these arguments 'this is the {{ field }}' becomes 'this is the value'
-- @tparam string str string to interpolate
-- @tparam table tbl table (record) to deduce values from
-- @treturn string processed string
local sub = function (str, tbl)
  local t, _ = {}, nil
  _, str = pcall(string.gsub, str, "{{[%s]-([%g]+)[%s]-}}",
    function (s)
      t.type = type
      local code = [[
        V=%s
        if type(V) == "function" then
          V=V()
        end
      ]]
      local lua = string.format(code, s)
      local chunk, err = load(lua, lua, "t", setmetatable(t, {__index=tbl}))
      if chunk then
        chunk()
        return t.V
      else
        return s
      end
    end) -- pcall
  return str
end

--- Generate a string based on the values returned by os.execute or px.exec.
-- @tparam string proc process name
-- @tparam string status exit status
-- @tparam number code exit code
-- @treturn string a formatted string
local exit_string = function (proc, status, code)
  if status == "exit" or status == "exited" then
    return string.format("%s: Exited with code %s", proc, code)
  end
  if status == "signal" or status == "killed" then
    return string.format("%s: Caught signal %s", proc, code)
  end
end

--- Convert the string "yes" or "true" to boolean true.
-- @tparam string s string to evaluate
-- @treturn bool the boolean true if the string matches, nil otherwise
local truthy = function (s)
  if s == "yes" or
     s == "YES" or
     s == "true" or
     s == "True" or
     s == "TRUE" then
     return true
  end
end

--- Convert the string "no" or "false" to boolean false.
-- @tparam string s string to evaluate
-- @treturn bool the boolean true if the string matches, nil otherwise
local falsy = function (s)
  if s == "no" or
     s == "NO" or
     s == "false" or
     s == "False" or
     s == "FALSE" then
     return true
  end
end

--- Wrap io.popen also known as popen(3).
-- <br/>
-- 1. Exit immediately if a command exits with a non-zero status<br/>
-- 2. Pathname expansion is disabled<br/>
-- 3. STDIN is closed<br/>
-- 4. Copy STDERR to STDOUT<br/>
-- 5. Finally replace the shell with the command
-- @warning The command has a script preamble
-- @tparam string str command to popen(3)
-- @tparam string cwd current working directory
-- @tparam bool _ignore_error boolean setting to ignore errors
-- @tparam bool _return_code boolean setting to return exit code
-- @treturn string the output as a string if the command exits with a non-zero status, nil otherwise
-- @treturn string a status output from cimicida.exit_string as a string
local popen = function (str, cwd, _ignore_error, _return_code)
  local result = {}
  local header = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&1
  ]]
  if cwd then
    str = string.format("%scd %s\n%s", header, cwd, str)
  else
    str = string.format("%s%s", header, str)
  end
  local pipe = io.popen(str, "re")
  io.flush(pipe)
  local tbl = {}
  for ln in pipe:lines() do
    tbl[#tbl + 1] = ln
  end
  local _
  _, result.status, result.code = io.close(pipe)
  result.bin = "io.popen"
  if _return_code then
    return result.code, result
  elseif _ignore_error or result.code == 0 then
    return tbl, result
  else
    return nil, result
  end
end

--- Wrap io.popen also known as popen(3).
-- Unlike cimicida.popen this writes to the pipe.
-- The command has a script preamble.<br/>
-- 1. Exit immediately if a command exits with a non-zero status<br/>
-- 2. Pathname expansion is disabled<br/>
-- 3. STDOUT is closed<br/>
-- 4. STDERR is closed<br/>
-- 5. Finally replace the shell with the command
-- @tparam string str command to popen(3)
-- @tparam string data string to feed to the pipe
-- @treturn bool true if the command exits with a non-zero status, nil otherwise
-- @treturn string a status output from cimicida.exit_string as a string
local pwrite = function (str, data)
  local result = {}
  local write = io.write
  str = [[  set -ef
  export LC_ALL=C
  exec ]] .. str
  local pipe = io.popen(str, "we")
  io.flush(pipe)
  pipe:write(data)
  local _
  _, result.status, result.code = io.close(pipe)
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Wrap os.execute also known as system(3).
-- The command has a script preamble.<br/>
-- 1. Exit immediately if a command exits with a non-zero status<br/>
-- 2. Pathname expansion is disabled<br/>
-- 3. STDERR and STDIN are closed<br/>
-- 4. STDOUT is piped to /dev/null<br/>
-- 5. Finally replace the shell with the command
-- @tparam string str command to pass to system(3)
-- @treturn bool true if exit code is equal to zero, nil otherwise
-- @treturn string a status output from cimicida.exit_string as a string
local system = function (str)
  local result = {}
  local set = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&- 1>/dev/null
  exec ]]
  local redir = [[ 0>&- 2>&- 1>/dev/null ]]
  local _
  _, result.status, result.code = os.execute(set .. str .. redir)
  result.bin = "os.execute"
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Wrap os.execute also known as system(3).
-- Similar to cimicida.system but it does not replace the shell.
-- Suitable for scripts.
-- @tparam string str string to pass to system(3)
-- @treturn bool true if exit code is equal to zero, nil otherwise
-- @treturn string a status output from cimicida.exit_string as a string
local execute = function (str)
  local result = {}
  local set = [[  set -ef
  exec 0>&- 2>&- 1>/dev/null
  ]]
  local _
  _, result.status, result.code = os.execute(set .. str)
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Run a shell pipe.
-- @tparam varargs ... a vararg containing the command pipe. The first argument should be popen or execute
-- @treturn string the output from cimicida.popen or cimicida.execute, nil if popen or execute was not passed
local pipeline = function (...)
  local pipe = {}
  local cmds = {...}
  for n = 2, #cmds do
    pipe[#pipe + 1] = table.concat(cmds[n], " ")
    if n ~= #cmds then pipe[#pipe + 1] = " | " end
  end
  if cmds[1] == "popen" then
    return popen(table.concat(pipe))
  elseif cmds[1] == "execute" then
    return execute(table.concat(pipe))
  else
    return
  end
end

--- Time a function run.
-- @tparam func f the function
-- @tparam varargs ... a vararg containing the arguments for the function
-- @return the return value(s) of f(...)
-- @treturn number the seconds elapsed as a number
local time = function (f, ...)
  local t1 = os.time()
  local fn = {f(...)}
  return table.unpack(fn), os.diff_time(os.time() , t1)
end

--- Escape quotes ",'.
-- @tparam string str string to quote
-- @treturn string quoted string
local escape_quotes = function (str)
  str = string.gsub(str, [["]], [[\"]])
  str = string.gsub(str, [[']], [[\']])
  return str
end

--- Log to a file.
-- @tparam string file path name of the file
-- @tparam string ident identification
-- @tparam string msg string to log (STRING)
-- @treturn bool a boolean value, true if no errors, nil otherwise
local flog = function (file, ident, msg)
  local setvbuf = io.setvbuf
  local openlog = function (f)
    local fd = io.open(f, "ae+")
    if fd then
      return fd
    end
  end
  local fd = openlog(file)
  local log = "%s %s: %s\n"
  local timestamp = os.date("%a %b %d %T")
  fd:setvbuf("line")
  local _, err = fprintf(fd, log, timestamp, ident, msg)
  io.flush(fd)
  io.close(fd)
  if err then
    return nil, err
  end
  return true
end

--- Insert a value to a table position if the first argument is not nil or not false.
-- Wraps table.insert().
-- @tparam bool bool value to evaluate
-- @tparam table list table to insert into
-- @tparam number pos position index in the table
-- @param value value to insert (VALUE)
local insert_if = function (bool, list, pos, value)
  if bool then
    if type(value) == "table" then
      for n, i in ipairs(value) do
        local p = n - 1
        table.insert(list, pos + p, i)
      end
    else
      table.insert(list, pos, value)
    end
  end
end

--- Return the second argument if the first argument is not nil or not false.
-- For value functions there should be no evaluation in the arguments.
-- @param bool value to evaluate
-- @param value value to return if first argument does not evaluate to nil or false
-- @return value if first argument does not evaluate to nil or false
local return_if = function (bool, value)
  if bool then
    return (value)
  end
end

--- Return the second argument if the first argument is nil or false.
-- @param bool value to evaluate
-- @param value value to return if first argument evaluates to nil or false
-- @return value if first argument evaluates to nil or false
local return_if_not = function (bool, value)
  if bool == false or bool == nil then
    return value
  end
end

--- @export
return {
  printf = printf,
  fprintf = fprintf,
  errorf = errorf,
  assertf = assertf,
  warn = warn,
  append = append,
  time_hm = time_hm,
  date_ymd = date_ymd,
  timestamp = timestamp,
  find_string = find_string,
  string_find = find_string,
  arr_to_rec = arr_to_rec,
  ln_to_tbl = ln_to_tbl,
  word_to_tbl = word_to_tbl,
  str_to_tbl = str_to_tbl,
  escape_pattern = escape_pattern,
  filter_tbl_value = filter_tbl_value,
  file_to_tbl = file_to_tbl,
  find_in_tbl = find_in_tbl,
  shallow_cp = shallow_cp,
  split_path = split_path,
  test_open = test_open,
  fopen = fopen,
  fwrite = fwrite,
  get_ln = get_ln,
  sub = sub,
  exit_string = exit_string,
  truthy = truthy,
  falsy = falsy,
  popen = popen,
  pwrite = pwrite,
  system = system,
  execute = execute,
  pipeline = pipeline,
  time = time,
  escape_quotes = escape_quotes,
  flog = flog,
  insert_if = insert_if,
  return_if = return_if,
  return_if_not = return_if_not
}
