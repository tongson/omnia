--- Configi standard library.
-- Lua extensions and some unix utilities.
-- Depends on cimicida and Luaposix.
--     VENDOR= lib cimicida inspect
--     VENDOR_C= posix px
-- @module lib

local rename, strlen, select, setmetatable, next, ipairs, require, type =
  os.rename, string.len, select, setmetatable, next, ipairs, require, type
local syslog = require"posix.syslog"
local unistd = require"posix.unistd"
local stdlib = require"posix.stdlib"
local libgen = require"posix.libgen"
local errno = require"posix.errno"
local fcntl = require"posix.fcntl"
local wait = require"posix.sys.wait"
local stat = require"posix.sys.stat"
local ptime = require"posix.time"
local A = require"array"
local P = require"px"
local I = require"inspect"
local C = require"cimicida"
C.fd = {}
C.os = os
_ENV = C

local retry = function(fn)
  return function(...)
    local ret, err, errnum, e, _
    repeat
      ret, err, errnum = fn(...)
      if ret == nil then
        _, e = errno.errno()
      end
    until(e ~= errno.EINTR)
    return ret, err, errnum
  end
end

-- Aliases
table.inspect = I.inspect
table.array = A
table.copy = P.table_copy
table.clear = P.table_clear
fd.close = unistd.close
path.base = libgen.basename
path.dir = libgen.dirname
os.closefrom = P.closefrom
os.chroot = P.chroot
file.stat = stat.stat
file.mkdir = stat.mkdir

-- Handle EINTR
os.chdir = retry(unistd.chdir)
os.dup2 = retry(unistd.dup2)
os.wait = retry(wait.wait)
fd.fcntl = retry(fcntl.fcntl)
fd.fsync = retry(unistd.fsync)
fd.open = retry(fcntl.open)
fd.mkstemp = retry(stdlib.mkstemp)
file.flopen = retry(P.flopen)
file.fdopen = retry(P.fdopen)

do -- chmod() and umask() from Luaposix compat.lua
  local st = stat
  local S_IRUSR, S_IWUSR, S_IXUSR = st.S_IRUSR, st.S_IWUSR, st.S_IXUSR
  local S_IRGRP, S_IWGRP, S_IXGRP = st.S_IRGRP, st.S_IWGRP, st.S_IXGRP
  local S_IROTH, S_IWOTH, S_IXOTH = st.S_IROTH, st.S_IWOTH, st.S_IXOTH
  local S_ISUID, S_ISGID, S_IRWXU, S_IRWXG, S_IRWXO =
    st.S_ISUID, st.S_ISGID, st.S_IRWXU, st.S_IRWXG, st.S_IRWXO
  local RWXALL = (st.S_IRWXU | st.S_IRWXG | st.S_IRWXO)
  local mode_map = {
    { c = "r", b = S_IRUSR }, { c = "w", b = S_IWUSR }, { c = "x", b = S_IXUSR },
    { c = "r", b = S_IRGRP }, { c = "w", b = S_IWGRP }, { c = "x", b = S_IXGRP },
    { c = "r", b = S_IROTH }, { c = "w", b = S_IWOTH }, { c = "x", b = S_IXOTH },
  }
  local pushmode = function(mode)
    local m = {}
    for i = 1, 9 do
      if (mode & mode_map[i].b) ~= 0 then m[i] = mode_map[i].c else m[i] = "-" end
    end
    if (mode & S_ISUID) ~= 0 then
      if (mode & S_IXUSR) ~= 0 then m[3] = "s" else m[3] = "S" end
    end
    if (mode & S_ISGID) ~= 0 then
      if (mode & S_IXGRP) ~= 0 then m[6] = "s" else m[6] = "S" end
    end
    return table.concat(m)
  end
  local rwxrwxrwx = function(modestr)
    local mode = 0
    for i = 1, 9 do
      if modestr:sub (i, i) == mode_map[i].c then
        mode = (mode | mode_map[i].b)
      elseif modestr:sub (i, i) == "s" then
        if i == 3 then
          mode = (mode | S_ISUID | S_IXUSR)
        elseif i == 6 then
          mode = (mode | S_ISGID | S_IXGRP)
        else
    return nil  -- bad mode
        end
      end
    end
    return mode
  end
  local octal_mode = function(modestr)
    local mode = 0
    for i = 1, #modestr do
      mode = mode * 8 + tonumber(modestr:sub (i, i))
    end
    return mode
  end
  local mode_munch = function(mode, modestr)
    if type(modestr) == "number" then
      return modestr
    end
    if #modestr == 9 and modestr:match "^[-rswx]+$" then
      return rwxrwxrwx (modestr)
    elseif modestr:match "^[0-7]+$" then
      return octal_mode (modestr)
    elseif modestr:match "^[ugoa]+%s*[-+=]%s*[rswx]+,*" then
      modestr:gsub ("%s*(%a+)%s*(.)%s*(%a+),*", function (who, op, what)
        local bits, bobs = 0, 0
        if who:match "[ua]" then bits = (bits | S_ISUID | S_IRWXU) end
        if who:match "[ga]" then bits = (bits | S_ISGID | S_IRWXG) end
        if who:match "[oa]" then bits = (bits | S_IRWXO) end
        if what:match "r" then bobs = (bobs | S_IRUSR | S_IRGRP | S_IROTH) end
        if what:match "w" then bobs = (bobs | S_IWUSR | S_IWGRP | S_IWOTH) end
        if what:match "x" then bobs = (bobs | S_IXUSR | S_IXGRP | S_IXOTH) end
        if what:match "s" then bobs = (bobs | S_ISUID | S_ISGID) end
        if op == "+" then
    -- mode |= bits & bobs
    mode = (mode | (bits & bobs))
        elseif op == "-" then
    -- mode &= ~(bits & bobs)
    mode = (mode & ~(bits & bobs))
        elseif op == "=" then
    -- mode = (mode & ~bits) | (bits & bobs)
    mode = ((mode & (~bits)) | (bits & bobs))
        end
      end)
      return mode
    else
      return nil, "bad mode"
    end
  end


  --- Change the mode of the path.
  -- @function chmod
  -- @string path existing file path
  -- @string mode one of the following formats:
  --
  --   * "rwxrwxrwx" (e.g. "rw-rw-r--")
  --   * "ugo+-=rwx" (e.g. "u+w")
  --   * +-=rwx" (e.g. "+w")
  --
  -- @return[1] int `0`, if successful
  -- @return[2] nil
  -- @treturn[2] string error message
  -- @treturn[2] int errnum
  -- @see chmod(2)
  -- @usage chmod ('bin/dof', '+x')


  function file.chmod (path, modestr)
    local mode = (st.stat (path) or {}).st_mode
    local bits, err = mode_munch(mode or 0, modestr)
    if bits == nil then
      return nil, err
    end
    mode = (bits & RWXALL)
    return st.chmod(path, mode)
  end


  --- Set file mode creation mask.
  -- @function umask
  -- @string[opt] mode file creation mask string
  -- @treturn string previous umask
  -- @see umask(2)
  -- @see posix.sys.stat.umask

  function os.umask(modestr)
    modestr = modestr or ""
    local mode = st.umask(0)
    st.umask(mode)
    mode = ((~mode) & RWXALL)
    if #modestr > 0 then
      local bits, err = mode_munch(mode, modestr)
      if bits == nil then
        return nil, err
      end
      mode = (bits & RWXALL)
      st.umask(~mode)
    end
    return pushmode(mode)
  end
end

function fd.write(f, buf)
  local sz = strlen(buf)
  local wr, err
  while (sz > 0) do
    wr, err = unistd.write(f, buf)
    if wr == nil then
      local _, no = errno.errno()
      if no == errno.EINTR then
        goto continue
      end
      return nil, err
    end
    sz = sz - wr
    ::continue::
  end
  return true
end

function file.stat(str)
  if stat.stat(str) then return str end
end

function path.bin(bin)
  -- If executable is not in any of these directories then it should be using the complete path.
  local t = { "/usr/bin/", "/bin/", "/usr/sbin/", "/sbin/", "/usr/local/bin/", "/usr/local/sbin/" }
  for _, p in ipairs(t) do
    if stat.stat(p..bin) then
      return p..bin
    end
  end
end

local pexec = function(args)
  if args.exe == nil then
    return nil, "No executable or program passed."
  end
  local stdin, fd0 = unistd.pipe()
  local fd1, stdout = unistd.pipe()
  local fd2, stderr = unistd.pipe()
  if not (stdin and fd1 and fd2) then
    return nil, "Error opening pipe."
  end
  local pid, err = unistd.fork()
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    unistd.close(fd0)
    unistd.close(fd1)
    unistd.close(fd2)
    os.dup2(stdin, unistd.STDIN_FILENO)
    os.dup2(stdout, unistd.STDOUT_FILENO)
    os.dup2(stderr, unistd.STDERR_FILENO)
    unistd.close(stdin)
    unistd.close(stdout)
    unistd.close(stderr)
    if args.cwd then
      local res
      res, err = os.chdir(args.cwd)
      if not res then return nil, err end
    end
    os.closefrom()
    P.execve(args.exe, args, args.env)
    local _, no = errno.errno()
    unistd._exit(no)
  end
  unistd.close(stdin)
  unistd.close(stdout)
  unistd.close(stderr)
  return pid, err, fd0, fd1, fd2
end

function exec.exec(args)
  local pid, err, fd0, fd1, fd2 = pexec(args)
  if not pid then return nil, err end
  local R = {stdout = {}, stderr = {}}
  local fdcopy = function(fileno, std, output)
    local str = {}
    local buf, fildes, res, msg
    if output then
      fildes, msg = fd.open(output, (fcntl.O_CREAT | fcntl.O_WRONLY))
      if not fildes then return nil, msg end
    end
    while true do
      buf = unistd.read(fileno, 4096)
      if buf == nil or strlen(buf) == 0 then
        if output then unistd.close(fildes) end
        break
      elseif output then
        res, msg = fd.write(fildes, buf)
        if not res then unistd.close(fildes) return nil, msg end
      else
        str[#str + 1] = buf
      end
    end
    if next(str) and not output then
      str = table.concat(str) -- table to string
      for ln in string.gmatch(str, "([^\n]*)\n") do
        if ln ~= "" then R[std][#R[std] + 1] = ln end
      end
      if #R[std] == 0 then
        R[std][1] = str
      end
    end
    return true
  end
  if args.stdin then
    local res, msg = fd.write(fd0, args.stdin)
    if not res then return nil, msg end
  end
  unistd.close(fd0)
  local copy, cerr
  copy, cerr = fdcopy(fd1, "stdout", args.stdout)
  if not copy then return nil, cerr end
  unistd.close(fd1)
  copy, cerr = fdcopy(fd2, "stderr", args.stderr)
  if not copy then return nil, cerr end
  unistd.close(fd2)
  R.pid, R.status, R.code = os.wait(pid)
  if R.pid == nil then return nil, R.status end
  R.exe = args.exe
  if R.code == 0 or args.ignore then
    return R.code, R
  else
    return nil, R
  end
end

function exec.qexec(args)
  local pid, err = unistd.fork()
  local R = {}
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    if args.cwd then
      local r, e = os.chdir(args.cwd)
      if not r then return nil, e end
    end
    os.closefrom()
    P.execve(args.exe, args, args.env)
    local _, no = errno.errno()
    unistd._exit(no)
  else
    R.pid, R.status, R.code = os.wait(pid)
    if R.pid == nil then return nil, R.status end
  end
  R.exe = args.exe
  -- return values depending on flags
  if R.code == 0 or args.ignore then
    return R.code, R
  else
    return nil, R
  end
end

function os.read_stdin(sz)
  local poll = require"posix.poll"
  local stdin = unistd.STDIN_FILENO
  local str = ""
  sz = sz or 1024
  local fds = {[stdin] = {events = {IN = true}}}
  while fds ~= nil do
    poll.poll(fds, -1)
    if fds[fd].revents.IN then
      local buf = unistd.read(stdin, sz)
      if buf == "" then fds = nil else str = string.format("%s%s", str, buf) end
    end
  end
  return str
end

function file.atomic_write(name, str, mode)
  local fil, temp = fd.mkstemp(libgen.dirname(name).."/._configiXXXXXX")
  if not fil then return nil, temp end
  ::WRITE::
  local wrok, wrerr = fd.write(fil, str) do
    if wrok then
      if not fd.fsync(fil) then
        goto WRITE
      end
      unistd.close(fil)
    else
      unistd.close(fil)
      return nil, wrerr
    end
  end
  local renok, renerr = rename(temp, name) do
    if renok then
      if mode then
        local r, e = file.chmod(name, mode)
        if r == nil then return nil, e end
      end
      return true
    else
      unistd.close(fil)
      return nil, renerr
    end
  end
end

function os.is_dir(str)
  local s = stat.stat(str)
  if s then
    if stat.S_ISDIR(s.st_mode) ~= 0 then
      return str
    end
  end
end

function os.is_file(str)
  local s = stat.stat(str)
  if s then
    if stat.S_ISREG(s.st_mode) ~= 0 then
      return str
    end
  end
end

function os.is_link(str)
  local s = stat.stat(str)
  if s then
    if stat.S_ISLNK(s.st_mode) ~= 0 then
      return str
    end
  end
end

function log.syslog(str, ident, msg, option, facility, level)
  level = level or syslog.LOG_DEBUG
  option = option or syslog.LOG_NDELAY
  facility = facility or syslog.LOG_USER
  if str then
    log.file(str, ident, msg)
  end
  syslog.openlog(ident, option, facility)
  syslog.syslog(level, msg)
  syslog.closelog()
end

function time.diff(finish, start)
  local sec, usec = 0, 0
  if finish.tv_sec then sec = finish.tv_sec end
  if start.tv_sec then sec = sec - start.tv_sec end
  if finish.tv_usec then usec = finish.tv_usec end
  if start.tv_usec then usec = usec - start.tv_usec end
  if usec < 0 then
    sec = sec - 1
    usec = usec + 1000000
  end
  return { sec = sec, usec = usec }
end

function os.effective_name()
  local pwd = require"posix.pwd"
  return pwd.getpwuid(unistd.geteuid()).pw_name
end

function os.real_name()
  local pwd = require"posix.pwd"
  return pwd.getpwuid(unistd.getuid()).pw_name
end

function exec.context(str)
  local E, exe, args
  if string.sub(str, 1, 1) == "-" then
    E = exec.qexec
    exe = string.sub(str, 2)
  else
    E = exec.exec
    exe = str
  end
  if strlen(path.split(exe)) == 0 then
    args = {exe = path.bin(exe)}
  else
    args = {exe = exe}
  end
  return setmetatable(args, {__call = function(_, ...)
    local a = {}
    table.copy(a, args)
    local n = select("#", ...)
    if n == 1 then
      for k in string.gmatch(..., "%S+") do
        a[#a+1] = k
      end
    elseif n > 1 then
      for _, k in ipairs({...}) do
        a[#a+1] = k
      end
    end
    return E(a)
  end})
end

exec.ctx = exec.context
exec.cmd = setmetatable({}, {__index =
  function (_, key)
    local E, exe
    -- silent execution (exec.qexec) when prepended with "-".
    if string.sub(key, 1, 1) == "-" then
      E = exec.qexec
      exe = string.sub(key, 2)
    else
      E = exec.exec
      exe = key
    end
    -- Search common executable directories if not a full path.
    if strlen(path.split(exe)) == 0 then
      exe = path.bin(exe)
    end
    return function(...)
      local args
      if not (...) then
        args = {}
      elseif type(...) == "table" then
        args = ...
      else
        args = {...}
      end
      args.exe = exe
      return E(args)
    end
  end
})

function path.decompose(str)
  local dir = libgen.dirname(str)
  local basename = libgen.basename(str)
  local base, ext = string.match(basename, "([%g%s]*)%.([%g]+)$")
  return dir, base, ext
end

function func.retry_f(on_fail, delay, retries)
  return function(fn, ...)
    fn = func.pcall_f(fn)
    delay = delay or 30
    retries = retries or 0
    local i = 0
    repeat
      local ok, err = fn(...)
      if not ok then
        i = i + 1
        on_fail(err)
        if delay > 0 then
          unistd.sleep(delay)
        end
      end
    until(ok or (i == retries))
  end
end

function time.unix(t, f)
  if not t then return nil, "Missing timestamp to convert." end
  f = f or "%Y-%m-%d %H:%M:%S"
  return ptime.strftime(f, ptime.gmtime(t))
end

return _ENV
