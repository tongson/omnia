local C = require "lib"
local T = require "u-test"
local fcntl = require"posix.fcntl"
local unistd = require"posix.unistd"

T["All tests"] = function()
  do
    local os = C.os
    T.os.effective_name = function()
      T.equal(os.effective_name(), "tongson")
    end
    T.os.real_name = function()
      T.equal(os.real_name(), "tongson")
    end
    T.os.readin = function()
    end
    T.os.is_file = function()
      os.execute[[
        mkdir tmp
        touch tmp/file
      ]]
      T.equal(os.is_file("tmp/file"), "tmp/file")
      os.execute[[
        rm tmp/file
      ]]
    end
    T.os.is_dir = function()
      T.equal(os.is_dir("tmp"), "tmp")
      os.execute[[
        rmdir tmp
      ]]
    end
    T.os.is_link = function()
      -- XXX T.is_true(file.is_link("tmp/symlink"))
    end
  end
  do
    local fd = C.fd
    local fildes
    os.execute[[
      mkdir tmp
    ]]
    T.fd.open = function()
      fildes = fd.open("tmp/fd", (fcntl.O_WRONLY | fcntl.O_CREAT))
      T.is_number(fildes)
    end
    T.fd.write = function()
      T.is_function(fd.write)
      T.is_true(fd.write(fildes, "one"))
      for s in io.lines("tmp/fd") do
        T.equal("one", s)
      end
      os.execute[[
        rm tmp/fd
      ]]
    end
    os.execute[[
      rmdir tmp
    ]]
  end

  do
    local func = C.func
    T.func.retry_f = function()
      local b = 0
      local r = func.retry_f(function() b = b + 1 end, 1, 2)
      r(string.find, "xxx", "XXX")
      T.equal(b, 2)
      b = 0
      r(string.find, "xxx", "xxx")
      T.equal(b, 0)
    end
    T.func.pcall_f = function()
      local fn
      local r = function(str)
        error(str)
      end
      fn = func.pcall_f(r)
      local one, two = fn("message")
      T.is_nil(one)
      T.equal(string.match(two, ".*(message)$"), "message")
    end
    T.func.try_f = function()
      local a, fn
      local finalizer = function()
        a = true
      end
      fn = func.try_f(finalizer)
      local x, y = fn(true, "good")
      T.is_nil(a)
      T.is_true(x)
      T.equal(y, "good")
      pcall(fn, false, "error")
      T.is_true(a)
    end
    T.func.time = function()
      local fn, bool, str, elapsed
      fn = function(s)
        return true, s
      end
      bool, str, elapsed = func.time(fn, "string")
      T.is_true(bool)
      T.equal(str, "string")
      T.is_number(elapsed)
      T.equal(elapsed, 0.0)
    end
  end
  do
    local fmt = C.fmt
    T.fmt.skip = true
    T.fmt.printf = function()
    end
    T.fmt.fprintf = function()
    end
    T.fmt.warnf = function()
    end
    T.fmt.errorf = function()
    end
    T.fmt.panicf =function()
    end
    T.fmt.assertf = function()
    end
  end
  do
    local string = C.string
    local text = "one"
    T.string.append = function()
      local s = string.append(text, "two")
      T.equal(s, "one\ntwo")
    end
    T.string.line_to_table = function()
      local tbl = string.line_to_table("one\ntwo\nthree")
      T.equal(tbl[1], "one")
      T.equal(tbl[2], "two")
      T.equal(tbl[3], "three")
    end
    T.string.word_to_table = function()
      local tbl = string.word_to_table("one!two.three")
      T.equal(tbl[1], "one")
      T.equal(tbl[2], "two")
      T.equal(tbl[3], "three")
    end
    T.string.to_table = function()
      local tbl = string.to_table("one\ntwo three")
      T.equal(tbl[1], "one")
      T.equal(tbl[2], "two")
      T.equal(tbl[3], "three")
    end
    T.string.escape_pattern = function()
      local str = string.escape_pattern("%s\n")
      T.equal("%%s\n", str)
    end
    T.string.template = function()
      local str = "My name is ${n}"
      local tbl = { n = "Ed" }
      T.equal("My name is Ed", string.template(str, tbl))
    end
    T.string.escape_quotes = function()
      local str = string.escape_quotes([['test' and "TEST"]])
      T.equal([[\'test\' and \"TEST\"]], str)
    end
  end
  do
    local time = C.time
    T.time.hm = function()
      T.is_string(time.hm())
    end
    T.time.ymd = function()
      T.is_string(time.ymd())
    end
    T.time.stamp = function()
      T.is_string(time.stamp())
    end
    T.time.unix = function()
      local s = time.unix(1508766437923)
      T.is_string(s)
      T.equal("2009-01-25 20:57:07", s)
    end
  end
  do
    local table = C.table
    local t = { "one", "two", "three" }
    T.table.find = function()
      T.is_true(table.find(t, "two"))
      T.is_nil(table.find(t, "xxx"))
    end
    T.table.to_dict = function()
      local nt = table.to_dict(t)
      T.equal(nt.one, true)
      T.equal(nt.two, true)
      T.equal(nt.three, true)
      nt = table.to_dict(t, 1)
      T.equal(nt.one, 1)
      T.equal(nt.two, 1)
      T.equal(nt.three, 1)
    end
    T.table.filter = function()
      local t = { "one", "two", "three" }
      local nt = table.filter(t, "two")
      T.equal(#nt, 2)
      T.equal(nt[1], "one")
      T.equal(nt[2], "three")
    end
    T.table.copy = function()
      local nt = {}
      table.copy(nt, t)
      T.equal(nt[1], "one")
      T.equal(nt[2], "two")
      T.equal(nt[3], "three")
      local xt = {}
      xt.one = true
      xt.two = true
      table.copy(nt, xt)
      T.is_true(nt.one)
      T.is_true(nt.two)
      T.is_nil(nt.three)
    end
    T.table.clone = function()
      t[4] = { "x", "y", "z", { "1", "2", "3"} }
      t.x = { "xxx" }
      local nt = table.clone(t)
      T.equal(nt[1], "one")
      T.equal(nt[2], "two")
      T.equal(nt[3], "three")
      T.equal(nt[4][1], "x")
      T.equal(nt[4][2], "y")
      T.equal(nt[4][3], "z")
      T.equal(nt[4][4][1], "1")
      T.equal(nt[4][4][2], "2")
      T.equal(nt[4][4][3], "3")
      T.equal(nt.x[1], "xxx")
    end
    T.table.insert_if = function()
      table.insert_if(true, t, 4, false)
      T.is_false(t[4])
      T.is_table(t[5])
    end
    T.table.auto = function()
      table.auto(t)
      T.is_table(t[6])
      T.is_table(t[6][1][2][3].xxx)
    end
    T.table.count = function()
      local nt = { "x", "y", "z" }
      local n = table.count(nt, "z")
      T.equal(n, 1)
      n = table.count(nt, 2)
      T.equal(n, 0)
    end
    T.table.array = function()
      local a, n
      a = table.array()
      a[1] = "a"
      a[2] = nil
      a[3] = "c"
      a[5] = "e"
      T.equal(#a, 5)
      n = 0
      for x, y in pairs(a) do
        n = n + 1
        if n == 3 then
          T.equal(x, 5)
          T.equal(y, "e")
        end
      end
      n = 0
      for x, y in ipairs(a) do
        n = n + 1
        if n == 3 then
          T.equal(x, 5)
          T.equal(y, "e")
        end
      end
      n = 0
      for x = 1, #a do
        n = n + 1
        if n == 3 then
          T.equal(x, 3)
          T.equal(a[x], "c")
        end
      end
      n = 0
      for x, y in next, a do
        n = n + 1
        if n == 3 then
          T.not_equal(x, 5)
          T.not_equal(y, "e")
        end
      end
    end
  end
  do
    local file = C.file
    T.file.start_up = function()
      os.execute[[
        mkdir tmp
        touch tmp/flopen
        touch tmp/stat
        ln -s tmp/stat tmp/symlink
        echo "one\ntwo\nthree" > tmp/file
      ]]
    end
    T.file.tear_down = function()
      os.execute[[
        rm tmp/file
        rm tmp/flopen
        rm tmp/stat
        unlink tmp/symlink
        rmdir tmp
      ]]
    end
    T.file.atomic_write = function()
      local r = file.atomic_write("tmp/atomic_write", "two three")
      T.is_true(r)
      for s in io.lines("tmp/atomic_write") do
        T.equal("two three", s)
      end
      os.execute[[
        rm tmp/atomic_write
      ]]
    end
    T.file.flopen = function()
      T.is_function(file.flopen)
      local fil = file.flopen("tmp/flopen")
      fil:write("one")
      for s in io.lines("tmp/flopen") do
        T.equal("one", s)
      end
      fil:close()
    end
    T.file.stat = function()
      T.equal("tmp/stat", file.stat("tmp/stat"))
    end
    T.file.find = function()
      T.is_true(file.find("tmp/file", "two"))
      T.is_nil(file.find("tmp/file", "xxx"))
    end
    T.file.match = function()
      T.equal(file.match("tmp/file", "o.."), "one")
      T.is_nil(file.match("tmp/file", "o..[%S]"))
      T.equal(file.match("tmp/file", "o..[%s]"), "one\n")
    end
    T.file.to_table = function()
      local t = file.to_table("tmp/file", "l")
      T.is_table(t)
      T.equal(t[1], "one")
      T.equal(t[2], "two")
      T.equal(t[3], "three")
    end
    T.file.test = function()
      T.is_true(file.test("tmp/file"))
      T.is_nil(file.test("tmp/xxx"))
    end
    T.file.read = function()
      local s = file.read("tmp/file")
      T.equal(s, "one\ntwo\nthree\n")
    end
    T.file.write = function()
      T.is_true(file.write("tmp/file.write", "one"))
      for s in io.lines("tmp/file.write") do
        T.equal(s, "one")
      end
      os.execute[[
        rm tmp/file.write
      ]]
    end
    T.file.line = function()
      T.equal(file.line("tmp/file", 2), "two")
    end
    T.file.truncate = function()
      os.execute[[
        echo "one" > tmp/file.truncate
      ]]
      T.is_true(file.truncate("tmp/file.truncate"))
      for s in io.lines("tmp/file.truncate") do
        T.equal(s, "")
      end
      os.execute[[
        rm tmp/file.truncate
      ]]
    end
    T.file.read_all = function()
      T.equal(file.read_all("tmp/file"), "one\ntwo\nthree\n")
    end
  end
  do
    local path = C.path
    T.path.split = function()
      local dir, base = path.split("tmp/one")
      T.equal(dir, "tmp")
      T.equal(base, "one")
      dir, base = path.split("/tmp/one")
      T.equal(dir, "/tmp")
      T.equal(base, "one")
      dir, base = path.split("/home/ed/one")
      T.equal(dir, "/home/ed")
      T.equal(base, "one")
      dir, base = path.split("one")
      T.equal(dir, "")
      T.equal(base, "one")
    end
    T.path.bin = function()
      T.equal("/usr/bin/xargs", path.bin("xargs"))
    end
    T.path.decompose = function()
      local dir, base, ext = path.decompose("tmp/one/test.lua")
      T.equal(dir, "tmp/one")
      T.equal(base, "test")
      T.equal(ext, "lua")
    end
  end
  do
    local exec = C.exec
    T.exec.start_up = function()
      os.execute[[
        mkdir tmp
      ]]
    end
    T.exec.tear_down = function()
      os.execute[[
        rmdir tmp
      ]]
    end
    T.exec.exec = function()
      local stdin = ".PHONY: test\ntest:\n\techo $(TEST)"
      -- args.stdin
      local args = {exe = "/usr/bin/tee", stdin = stdin, "tmp/Makefile"}
      local res, tbl = exec.exec(args)
      T.equal(res, 0)
      -- args.stdout
      args = {exe = "/usr/bin/tee", stdin = stdin, stdout = "tmp/Makefile2"}
      res, tbl = exec.exec(args)
      T.equal(res, 0)
      -- args.env, args.cwd
      args = {exe = "/usr/bin/make", env = {"TEST=ok"}, cwd = "tmp", "-f", "Makefile2"}
      res, tbl = exec.exec(args)
      T.equal(res, 0)
      -- result.stdout
      T.equal(tbl.stdout[1], "echo ok")
      T.equal(tbl.stdout[2], "ok")
      -- result.status
      T.equal(tbl.status, "exited")
      -- result.pid
      T.is_number(tbl.pid)
      -- args.ignoe
      args = {exe = "/usr/bin/make", ignore = true, "-f", "XXX"}
      res, tbl = exec.exec(args)
      T.equal(res, 2)
      -- result.stderr
      T.is_number(string.find(tbl.stderr[1], "No such file or directory"))
      os.execute[[
        rm tmp/Makefile
        rm tmp/Makefile2
      ]]
    end
    T.exec.qexec = function()
      local stdin = ".PHONY: test\ntest:\n\techo $(TEST)"
      local file = io.open("tmp/Makefile", "w")
      file:write(stdin)
      file:close()
      -- args.cwd, args.env
      local args = {exe = "/usr/bin/make", env = {"TEST=ok"}, "-f", "Makefile"}
      res, tbl = exec.qexec(args)
      T.equal(res, 0)
      -- result.status
      T.equal(tbl.status, "exited")
      -- result.pid
      T.is_number(tbl.pid)
      -- args.ignore
      args = {exe = "/usr/bin/make", ignore = true, "-f", "XXX"}
      res, tbl = exec.qexec(args)
      T.equal(res, 2)
      os.execute[[
        rm tmp/Makefile
      ]]
    end
    T.exec.context = function()
      local stdin = ".PHONY: test\ntest:\n\techo $(TEST)"
      local tee = exec.ctx("tee")
      tee.stdin = stdin
      local res, tbl = tee("tmp/Makefile")
      T.equal(res, 0)
      tee.stdout = "tmp/Makefile2"
      res, tbl = tee()
      T.equal(res, 0)
      local make = exec.ctx("make")
      make.env = {"TEST=ok"}
      res, tbl = make("-f", "tmp/Makefile2")
      T.equal(res, 0)
      T.equal(tbl.status, "exited")
      T.is_number(tbl.pid)
      make.ignore = true
      res, tbl = make("-f", "XXX")
      T.equal(res, 2)
      make.ignore = false
      res, tbl = make("-f", "XXX")
      T.is_nil(res)
      os.execute[[
        rm tmp/Makefile
        rm tmp/Makefile2
      ]]
    end
    T.exec.cmd = function()
      local stdin = ".PHONY: test\ntest:\n\techo $(TEST)"
      local res, tbl = exec.cmd.tee{stdin = stdin, "tmp/Makefile"}
      T.equal(res, 0)
      -- args.stdout
      res, tbl = exec.cmd.tee{stdin = stdin, stdout = "tmp/Makefile2"}
      T.equal(res, 0)
      -- args.env, args.cwd
      res, tbl = exec.cmd.make{env = {"TEST=ok"}, cwd = "tmp", "-f", "Makefile2"}
      T.equal(res, 0)
      -- result.stdout
      T.equal(tbl.stdout[1], "echo ok")
      T.equal(tbl.stdout[2], "ok")
      -- result.status
      T.equal(tbl.status, "exited")
      -- result.pid
      T.is_number(tbl.pid)
      -- args.ignore
      res, tbl = exec.cmd.make{ignore = true, "-f", "XXX"}
      T.equal(res, 2)
      -- result.stderr
      T.is_number(string.find(tbl.stderr[1], "No such file or directory"))
      res, tbl = exec.cmd.make("-f", "XXX")
      T.is_nil(res)
      T.is_number(string.find(tbl.stderr[1], "No such file or directory"))
      os.execute[[
        rm tmp/Makefile
        rm tmp/Makefile2
      ]]
    end
    T.exec.popen = function()
      os.execute[[
        touch tmp/one
        touch tmp/two
      ]]
      local t, r = exec.popen("ls", "tmp")
      T.equal(t, 0)
      T.is_table(r)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      T.equal(r.output[1], "one")
      T.equal(r.output[2], "two")
      T.is_nil(r.output[3])
      t, r = exec.popen("xxx")
      T.is_nil(t)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      t, r = exec.popen("xxx", ".", true)
      T.equal(t, 127)
      T.equal(r.output[1], "sh: 7: xxx: not found")
      os.execute[[
        rm tmp/one
        rm tmp/two
      ]]
    end
    T.exec.pwrite = function()
      local t, r = exec.pwrite("cat>pwrite", "written", "tmp")
      T.equal(t, 0)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      for s in io.lines("tmp/pwrite") do
        T.equal(s, "written")
      end
      os.execute[[
        rm tmp/pwrite
      ]]
    end
    T.exec.system = function()
      local t, r = exec.system("ls", "tmp")
      T.equal(t, 0)
      T.equal(r.exe, "os.execute")
      T.equal(r.status, "exit")
      t, r = exec.system("ls XXX")
      T.is_nil(t)
      t, r = exec.system("ls XXX", ".", true)
      T.equal(t, 2)
    end
    T.exec.script = function()
      os.execute[[
        echo "touch tmp/three" > tmp/exec_script
        echo "touch tmp/four" >> tmp/exec_script
      ]]
      local t, r = exec.script("tmp/exec_script")
      T.equal(t, 0)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      local script = [[
        touch xxx/three
      ]]
      os.execute[[
        echo "touch xxx/three" > tmp/exec_script2
      ]]
      t, r = exec.script("tmp/exec_script2", true)
      T.equal(t, 1)
      os.execute[[
        rm tmp/three
        rm tmp/four
        rm tmp/exec_script
        rm tmp/exec_script2
      ]]
    end
    T.exec.pipe_args = function()
      local t, r = exec.pipe_args("popen", "ls", "cat>tmp/pipe_args")
      T.equal(t, 0)
      T.is_table(r)
      for s in io.lines("tmp/pipe_args") do
        T.is_string(s)
      end
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      os.execute[[
        rm tmp/pipe_args
      ]]
    end
    T.exec.exit_string = function()
      T.equal(exec.exit_string("exe", "exit", 0), "exe: Exited with code 0")
      T.equal(exec.exit_string("exe", "exited", 0), "exe: Exited with code 0")
      T.equal(exec.exit_string("exe", "signal", 255), "exe: Caught signal 255")
      T.equal(exec.exit_string("exe", "killed", 255), "exe: Caught signal 255")
    end
  end
  do
    local log = C.log
    T.log.start_up = function()
      os.execute[[
        mkdir tmp
      ]]
    end
    T.log.tear_down = function()
      os.execute[[
        rmdir tmp
      ]]
    end
    T.log.file = function()
      T.is_true(log.file("tmp/log", "T", "Ting one two three") )
      for s in io.lines("tmp/log") do
        T.equal(string.find(s, ".+Ting%sone%stwo%sthree"), 1)
      end
      os.execute[[
        rm tmp/log
      ]]
    end
    T.log.syslog = function()
    end
  end

  do
    local util = C.util
    T.util.truthy = function()
      T.is_true(util.truthy("yes"))
      T.is_true(util.truthy("Yes"))
      T.is_true(util.truthy("true"))
      T.is_true(util.truthy("True"))
      T.is_true(util.truthy("on"))
      T.is_true(util.truthy("On"))
    end
    T.util.falsy = function()
      T.is_true(util.falsy("no"))
      T.is_true(util.falsy("No"))
      T.is_true(util.falsy("false"))
      T.is_true(util.falsy("False"))
      T.is_true(util.falsy("off"))
      T.is_true(util.falsy("Off"))
    end
    T.util.return_if = function()
      T.is_not_nil(util.return_if(true, 1))
      T.is_nil(util.return_if(false, 1))
    end
    T.util.return_if_not = function()
      T.is_not_nil(util.return_if_not(false, 1))
      T.is_nil(util.return_if_not(true, 1))
    end
    T.util.octal = function()
      T.equal(1232, util.octal(666))
    end
  end
  do
    T["Function from a vendor/c module(lfs)"] = function()
      local lfs = require"lfs"
      T.equal(type(lfs.rmdir), "function")
    end
    T["Function from vendor/posix module(luaposix)"] = function()
      local libgen = require"posix.libgen"
      T.equal(type(libgen.basename), "function")
    end
    T["Function from a src/lua module(src)"] = function()
      local src = require"src"
      T.equal(type(src.src), "function")
    end
    T["Function from a src/lua module directory (moonscript) (moon.src)"] = function()
      local moon_slash_src = require"moon.src"
      T.equal(type(moon_slash_src.moon_slash_src), "function")
    end
    T["Function from a src/lua module (moonscript) (moon_src)"] = function()
      local moon_src = require"moon_src"
      T.equal(type(moon_src.moon_src), "function")
    end
    T["No _ENV leak"] = function()
      T.is_nil(C.wait)
      T.is_table(C.time)
    end
  end
end
T.summary()
