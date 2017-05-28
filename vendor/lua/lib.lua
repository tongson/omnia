--- Configi standard library.
-- Lua extensions and some unix utilities.
-- Depends on cimicida and Luaposix.
--     VENDOR= lib cimicida
--     VENDOR_C= posix
-- @module lib

local string, table, os = string, table, os
local setmetatable, pcall, type, next, ipairs = setmetatable, pcall, type, next, ipairs
local lc = require"cimicida"
local pwd = require"posix.pwd"
local unistd = require"posix.unistd"
local errno = require"posix.errno"
local wait = require"posix.sys.wait"
local stat = require"posix.sys.stat"
local poll = require"posix.poll"
local fcntl = require"posix.fcntl"
local stdlib = require"posix.stdlib"
local syslog = require"posix.syslog"
local libgen = require"posix.libgen"
local lib = require"px"
local ENV = {}
_ENV = ENV

local retry = function (fn)
    return function (...)
        local ret, err, errnum, e, _
        repeat
            ret, err, errnum = fn(...)
            if ret == -1 then
                _, e = errno.errno()
            end
        until(e ~= errno.EINTR)
        return ret, err, errnum
    end
end

-- Handle EINTR
lib.fsync = retry(unistd.fsync)
lib.chdir = retry(unistd.chdir)
lib.fcntl = retry(fcntl.fcntl)
lib.dup2 = retry(unistd.dup2)
lib.wait = retry(wait.wait)
lib.open = retry(fcntl.open)

--- Write to a file descriptor.
--  Wrapper to luaposix unistd.write.
-- @tparam int fd file descriptor
-- @tparam string buf string to write
-- @return true if successfully written.
function lib.write (fd, buf)
    local size = string.len(buf)
    local written, err
    while (size > 0) do
        written, err = unistd.write(fd, buf)
        if written == -1 then
            local _, errno = errno.errno()
            if errno == errno.EINTR then
                goto continue
            end
            return nil, err
        end
        size = size - written
        ::continue::
    end
    return true
end

-- exec for pipeline
function lib.execp (t, ...)
    local pid, err = unistd.fork()
    local status, code, _
    if pid == nil or pid == -1 then
        return nil, err
    elseif pid == 0 then
        if type(t) == "table" then
            unistd.exec(table.unpack(t))
            local _, no = errno.errno()
            unistd._exit(no)
        else
            unistd._exit(t(...) or 0)
        end
    else
        _, status, code = lib.wait(pid)
    end
    return code, status
end

-- Derived from luaposix/posix.lua pipeline()
local pipeline
pipeline = function (t, pipe_fn)
    local list = {
        sub = function (l, from, to)
            local r = {}
            local len = #l
            from = from or 1
            to = to or len
            if from < 0 then
                from = from + len + 1
            end
            if to < 0 then
                to = to + len + 1
            end
            for i = from, to do
                table.insert (r, l[i])
            end
            return r
        end
    }

    pipe_fn = pipe_fn or unistd.pipe
    local pid, read_fd, write_fd, save_stdout
    if #t > 1 then
        read_fd, write_fd = pipe_fn()
        if not read_fd then
            lc.errorf("error opening pipe")
        end
        pid = unistd.fork()
        if pid == nil then
            lc.errorf("error forking")
        elseif pid == 0 then
            if not lib.dup2(read_fd, unistd.STDIN_FILENO) then
                lc.errorf("error dup2-ing")
            end
            unistd.close(read_fd)
            unistd.close(write_fd)
            unistd._exit(pipeline(list.sub(t, 2), pipe_fn))
        else
            save_stdout = unistd.dup(unistd.STDOUT_FILENO)
            if not save_stdout then
                lc.errorf("error dup-ing")
            end
            if not lib.dup2(write_fd, unistd.STDOUT_FILENO) then
                lc.errorf("error dup2-ing")
            end
            unistd.close(read_fd)
            unistd.close(write_fd)
        end
    end

    local code, status = lib.execp(t[1])
    unistd.close(unistd.STDOUT_FILENO)

    if #t > 1 then
        unistd.close(write_fd)
        lib.wait(pid)
        if not lib.dup2 (save_stdout, unistd.STDOUT_FILENO) then
            lc.errorf("error dup2-ing")
        end
        unistd.close(save_stdout)
    end

    if code == 0 then
        return true, lc.exit_string("pipe", status, code)
    else
        return nil, lc.exit_string("pipe", status, code)
    end
end

--- Checks the existence of a given path.
-- @tparam string path the path to check for
-- @treturn string the path if path exists.
function lib.ret_path (path)
    if stat.stat(path) then
        return path
    end
end

--- Deduce the complete path name of an executable.
--  Only checks standard locations.
-- @tparam string bin executable name
-- @treturn string full path name
function lib.bin_path (bin)
    -- If executable is not in any of these directories then it should be using the complete path.
    local t = { "/usr/bin/", "/bin/", "/usr/sbin/", "/sbin/", "/usr/local/bin/", "/usr/local/sbin/" }
    for _, p in ipairs(t) do
        if stat.stat(p .. bin) then
            return p .. bin
        end
    end
end

--[[
    OVERRIDES for lib.exec and lib.qexec
    _bin=path to binary
    _env=environment
    _cwd=current working directory
    _stdin=standard input (STRING)
    _stdout=standard output (FILE)
    _stderr=standard error (FILE)
    _return_code=return the exit code instead of boolean true
    _ignore_error=always return boolean true
]]

local pexec = function (args)
    if args._bin == nil then
        return nil, "no executable passed"
    end
    local stdin, fd0    = unistd.pipe()
    local fd1, stdout = unistd.pipe()
    local fd2, stderr = unistd.pipe()
    if not (fd0 and fd1 and fd2) then
        return nil, "error opening pipe"
    end
    local _, res, no, pid, err = nil, nil, nil, unistd.fork()
    if pid == nil or pid == -1 then
        return nil, err
    elseif pid == 0 then
        unistd.close(fd0)
        unistd.close(fd1)
        unistd.close(fd2)
        lib.dup2(stdin, unistd.STDIN_FILENO)
        lib.dup2(stdout, unistd.STDOUT_FILENO)
        lib.dup2(stderr, unistd.STDERR_FILENO)
        unistd.close(stdin)
        unistd.close(stdout)
        unistd.close(stderr)
        if args._cwd then
            res, err = lib.chdir(args._cwd)
            if not res then
                return nil, err
            end
        end
        lib.closefrom()
        lib.execve(args._bin, args, args._env)
        _, no = errno.errno()
        unistd._exit(no)
    end
    unistd.close(stdin)
    unistd.close(stdout)
    unistd.close(stderr)
    return pid, err, fd0, fd1, fd2
end

--- Execute a file.
-- The sequence part of args are the arguments passed to the executable <br/>
-- The dictionary part of args has options and override. See the following.<br/>
-- @tparam table args
-- @param args._bin override path to binary
-- @param args._env environment variables
-- @param args._cwd current working directory
-- @param args._stdin string as standard input
-- @param args._stdout path to file as standard output
-- @param args._stderr path to file as standard error
-- @param args._return_code return the exit code instead of boolean true
-- @param args._ignore_error always return boolean true
-- @treturn bool true if no errors, nil otherwise
-- @treturn table result
-- @return result.stdout (table) sequence of stdout lines
-- @return result.stderr (table) sequence of stderr lines
-- @return result.pid (int) pid of terminated executable, if successful; nil otherwise
-- @return result.status (string) status: "exited", "killed" or "stopped"; otherwise, an error message
-- @return result.code (int) exit status, or signal number responsible for "killed" or "stopped"; otherwise, an errnum
-- @return result.bin (string) executable path
function lib.exec (args)
    local result = { stdout = {}, stderr = {} }
    local sz = 4096
    local pid, err, fd0, fd1, fd2 = pexec(args)
    if not pid then
        return nil, err
    end
    local fdcopy = function (fileno, std, output)
        local buf, str = nil, {}
        local fd, res, msg
        if output then
            fd, msg = lib.open(output, (fcntl.O_CREAT | fcntl.F_WRLCK | fcntl.O_WRONLY))
            if not fd then return nil, msg end
        end
        while true do
            buf = unistd.read(fileno, sz)
            if buf == nil or string.len(buf) == 0 then
                if output then
                    unistd.close(fd)
                end
                break
            elseif output then
                res, msg = lib.write(fd, buf)
                if not res then
                    return nil, msg
                end
            else
                str[#str + 1] = buf
            end
        end
        if next(str) and not output then
            str = table.concat(str) -- table to string
            for ln in string.gmatch(str, "([^\n]*)\n") do
                if ln ~= "" then result[std][#result[std] + 1] = ln end
            end
            if #result[std] == 0 then
                result[std][1] = str
            end
        end
        return true
    end
    if args._stdin then
        local res, msg = lib.write(fd0, args._stdin)
        if not res then
            return nil, msg
        end
    end
    unistd.close(fd0)
    fdcopy(fd1, "stdout", args._stdout)
    unistd.close(fd1)
    fdcopy(fd2, "stderr", args._stderr)
    unistd.close(fd2)
    result.pid, result.status, result.code = lib.wait(pid)
    result.bin = args._bin
    if args._return_code then
        return result.code, result
    elseif args._ignore_error or result.code == 0 then
        return true, result
    else
        return nil, result
    end
end

--- Execute a file.
--  Use if caller does not care for STDIN, STDOUT or STDERR. <br/>
-- The sequence part of args are the arguments passed to the executable <br/>
-- The dictionary part of args has options and override. See the following.<br/>
-- @tparam table args
-- @param args._bin override path to binary
-- @param args._env environment variables
-- @param args._cwd current working directory
-- @param args._stdin string as standard input
-- @param args._stdout path to file as standard output
-- @param args._stderr path to file as standard error
-- @param args._return_code return the exit code instead of boolean true
-- @param args._ignore_error always return boolean true
-- @treturn bool true if no errors, nil otherwise
-- @treturn table result
-- @return result.stdout (table) sequence of stdout lines
-- @return result.stderr (table) sequence of stderr lines
-- @return result.pid (int) pid of terminated executable, if successful; nil otherwise
-- @return result.status (string) status: "exited", "killed" or "stopped"; otherwise, an error message
-- @return result.code (int) exit status, or signal number responsible for "killed" or "stopped"; otherwise, an errnum
-- @return result.bin (string) executable path
function lib.qexec (args)
    local pid, err = unistd.fork()
    local result = {}
    if pid == nil or pid == -1 then
        return nil, err
    elseif pid == 0 then
        if args._cwd then
            local res, err = lib.chdir(args._cwd)
            if not res then
                return nil, err
            end
        end
        lib.closefrom()
        lib.execve(args._bin, args, args._env)
        local _, no = errno.errno()
        unistd._exit(no)
    else
        result.pid, result.status, result.code = lib.wait(pid)
        result.bin = args._bin
    end
    -- return values depending on flags
    if args._return_code then
        return result.code, result
    elseif args._ignore_error or result.code == 0 then
        return true, result
    else
        return nil, result
    end
end

--- Read string from a polled STDIN.
-- @tparam int sz bytes to read
-- @treturn string string read
function lib.readin (sz)
    local fd = unistd.STDIN_FILENO
    local str = ""
    sz = sz or 1024
    local fds = { [fd] = { events = { IN = true } } }
    while fds ~= nil do
        poll.poll(fds, -1)
        if fds[fd].revents.IN then
            local buf = unistd.read(fd, sz)
            if buf == "" then fds = nil else str = string.format("%s%s", str, buf) end
        end
    end
    return str
end

--- Write to given path name.
--  Wraps lib.write().
-- @tparam string path name
-- @tparam string str string to write
-- @treturn bool true if successfully written; otherwise it returns nil
function lib.write_path (path, str)
    local fd, err = lib.open(path, (fcntl.O_WRONLY))
    if not fd then
        return nil, err
    end
    return lib.write(fd, str)
end

--- Write to give path name atomically.
-- Wraps lib.write().
-- @tparam string path name
-- @tparam string str string to write
-- @tparam number mode octal mode when opening file
-- @treturn bool true when successfully writing; otherwise, return nil
-- @treturn string successful message string; otherwise, return a string describing the error
function lib.awrite (path, str, mode)
    mode = mode or 384
    local ok, err
    -- O_WRONLY and F_WRLCK for an advisory lock on the given path
    local fd = lib.open(path, (fcntl.O_CREAT | fcntl.O_WRONLY | fcntl.O_TRUNC), mode)
    local lock = {
        l_type = fcntl.F_WRLCK,
        l_whence = unistd.SEEK_SET,
        l_start = 0,
        l_len = 0
    }
    ok = pcall(lib.fcntl, fd, fcntl.F_SETLK, lock)
    if not ok then
        return nil, "lib.awrite: fcntl(2) error."
    end
    local dirname = libgen.dirname(path)
    local tmp, temp = stdlib.mkstemp(dirname .. "/._configiXXXXXX")
    lib.write(tmp, str)
    lib.fsync(tmp)
    ok, err = os.rename(temp, path)
    if not ok then
        return nil, err
    end
    unistd.close(tmp)
    lock.l_type = fcntl.F_UNLCK
    lib.fcntl(fd, fcntl.F_SETLK, lock)
    lib.fsync(fd)
    unistd.close(fd)
    return true, string.format("Successfully wrote %s", path)
end

--- Check if a given path name is a directory.
-- @tparam string path name
-- @treturn bool true if a directory; otherwise, return nil
function lib.is_dir (path)
    local path_stat = stat.stat(path)
    if path_stat then
        if stat.S_ISDIR(path_stat.st_mode) ~= 0 then
            return true
        end
    end
end

--- Check if a given path name is a file.
-- @tparam string path name
-- @treturn bool true if a file; otherwise, return nil
function lib.is_file (path)
    local path_stat = stat.stat(path)
    if path_stat then
        if stat.S_ISREG(path_stat.st_mode) ~= 0 then
            return true
        end
    end
end

--- Check if a given path name is a symbolic link.
-- @tparam string path name
-- @treturn bool true if a symbolic link; otherwise, return nil
function lib.is_link (path)
    local stat = stat.stat(path)
    if stat then
        if stat.S_ISLNK(stat.st_mode) ~= 0 then
            return true
        end
    end
end

--- Write to the syslog and a file if given.
-- @tparam string file path name to log to.
-- @tparam string ident arbitrary identification string
-- @tparam string msg message body
-- @tparam int option see luaposix syslog constants
-- @tparam int facility see luaposix syslog constants
-- @tparam int level see luaposix syslog constants
function lib.log (file, ident, msg, option, facility, level)
    local flog = lc.flog
    level = level or syslog.LOG_DEBUG
    option = option or syslog.LOG_NDELAY
    facility = facility or syslog.LOG_USER
    if file then
        flog(file, ident, msg)
    end
    syslog.openlog(ident, option, facility)
    syslog.syslog(level, msg)
    syslog.closelog()
end

--- Calculate difference in time.
-- From luaposix.
-- @tparam int finish end time
-- @tparam int start start time
-- @treturn {sec, usec} a table of results
function lib.diff_time (finish, start)
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

--- Get effective username.
-- @treturn string username
function lib.effective_username ()
    return pwd.getpwuid(unistd.geteuid()).pw_name
end

--- Get real username.
-- @treturn string username
function lib.real_username ()
    return pwd.getpwuid(unistd.getuid()).pw_name
end

lib.pipeline = pipeline

--- Execute command or executable as the key for this function-table.
-- @function cmd
-- Wraps lib.exec and lib.qexec so you can execute a given executable as the index to `cmd`.
-- See lib.exec() and lib.qexec() for the possible options and results.<br/><br/>
-- The invocation `cmd.ls` should also work since lib.bin_path() is called on the command.
-- Prepend '-' to the command to ignore the output ala lib.qexec(). <br/>
-- @usage cmd["/bin/ls"]{ "/tmp" }
-- @usage cmd.ls{"/tmp"}
-- @usage cmd["-/bin/ls"]{ "/tmp" }
lib.cmd = setmetatable({}, { __index =
    function (_, key)
        local exec, bin
        -- silent execution (lib.qexec) when prepended with "-".
        if string.sub(key, 1, 1) == "-" then
            exec = lib.qexec
            bin = string.sub(key, 2)
        else
            exec = lib.exec
            bin = key
        end
        -- Search common executable directories if not a full path.
        if string.len(lc.split_path(bin)) == 0 then
            bin = lib.bin_path(bin)
        end
        return function (args)
            args._bin = bin
            return exec(args)
        end
    end
})

--- File part of a path.
-- @function basename
-- Same as posix.libgen.basename. Copied here for convenience.
-- @tparam string file to act on
-- @treturn string filename part of path
lib.basename = libgen.basename

--- Directory name of path.
-- @function dirname
-- Same as posix.libgen.dirname. Copied here for convenience.
-- @tparam string file to act on
-- @treturn string directory parth of path
lib.dirname = libgen.dirname

--- Split a file name.
-- @tparam string str path name
-- @treturn string path Directory component
-- @treturn string base Basename minus the extension
-- @treturn string ext The extension
function lib.decomp_path(str)
    local path = libgen.dirname(str)
    local basename = libgen.basename(str)
    local base, ext = string.match(basename, "([%g%s]*)%.([%g]+)$")
    return path, base, ext
end

--- Retry factory.
-- @tparam function on_fail function to run in case of failure. Takes in the second return value from the retried function as an argument.
-- @tparam number delay seconds to sleep after a failure. Default is 30 seconds.
-- @tparam number retries number of tries. Default is to retry indefinitely.
-- @treturn function a function that runs ...
-- @usage run = retry_f(function() end, 3, 1)
--run(string.match, "match", "match")
function lib.retry_f(on_fail, delay, retries)
    return function(fn, ...)
        fn = lc.pcall_f(fn)
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

return setmetatable({}, { __index = function(_, func)
    return lib[func] or lc[func]
end})
