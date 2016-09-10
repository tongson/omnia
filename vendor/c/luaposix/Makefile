LUAPOSIX= ctype dirent errno fcntl fnmatch getopt glob grp \
  libgen poll pwd sched signal stdio stdlib sys.msg \
  sys.resource sys.socket sys.stat sys.statvfs sys.time \
  sys.times sys.utsname sys.wait syslog termio time \
  unistd utime
luaposix_P= vendor/c/luaposix/src
C_MODULES+= $(foreach m, $(LUAPOSIX), posix.$m.a)
C_MODULES:= $(filter-out luaposix.a,$(C_MODULES))
CFLAGS+= $(CFLAGS_LRT)
VENDOR+= posix
CLEAN+= clean_posix

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
	$(RM) $(RMFLAGS) $(luaposix_P)/*.o $(C_MODULES)

.PHONY: clean_posix test_posix

