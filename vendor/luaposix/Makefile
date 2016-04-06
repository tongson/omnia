LUAPOSIX= ctype dirent errno fcntl fnmatch getopt glob grp \
  libgen poll pwd sched signal stdio stdlib sys.msg \
  sys.resource sys.socket sys.stat sys.statvfs sys.time \
  sys.times sys.utsname sys.wait syslog termio time \
  unistd utime
posix_P= vendor/luaposix/src
CLUA_MODS+= $(foreach m, $(LUAPOSIX), posix.$m.a)
CLUA_MODS:= $(filter-out luaposix.a,$(CLUA_MODS))
CFLAGS+= -lrt
VENDOR_LUA+= posix
CLEAN+= clean_posix
CCWARN=

$(posix_P)/sys/%.o:  $(posix_P)/sys/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(luaposixDEFINES) $(INCLUDES) -Ivendor/luaposix/src $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

posix.sys.%.a: $(posix_P)/sys/%.o
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(posix_P)/%.o:  $(posix_P)/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(luaposixDEFINES) $(INCLUDES) -Ivendor/luaposix/src $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

posix.%.a: $(posix_P)/%.o
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

clean_posix:
	$(RM) $(RMFLAGS) $(posix_P)/*.o $(CLUA_MODS)

.PHONY: clean_posix test_posix

