LUAPOSIX= ctype dirent errno fcntl fnmatch getopt glob grp \
  libgen poll pwd sched signal stdio stdlib sys.msg \
  sys.resource sys.socket sys.stat sys.statvfs sys.time \
  sys.times sys.utsname sys.wait syslog termio time \
  unistd utime
luaposix_P= vendor/c/luaposix/src
CLUA_MODS+= $(foreach m, $(LUAPOSIX), posix.$m.a)
CLUA_MODS:= $(filter-out luaposix.a,$(CLUA_MODS))
CFLAGS+= -lrt
VENDOR_LUA+= posix
CLEAN+= clean_posix
CCWARN=

$(luaposix_P)/sys/%.o:  $(luaposix_P)/sys/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(luaposixDEFINES) $(INCLUDES) -Ivendor/c/luaposix/src $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

posix.sys.%.a: $(luaposix_P)/sys/%.o
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(luaposix_P)/%.o:  $(luaposix_P)/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(luaposixDEFINES) $(INCLUDES) -Ivendor/c/luaposix/src $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

posix.%.a: $(luaposix_P)/%.o
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

clean_posix:
	$(RM) $(RMFLAGS) $(luaposix_P)/*.o $(CLUA_MODS)

.PHONY: clean_posix test_posix

