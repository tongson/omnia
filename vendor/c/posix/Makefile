LUAPOSIX= ctype dirent errno fcntl fnmatch getopt glob grp \
  libgen poll pwd sched signal stdio stdlib sys.msg \
  sys.resource sys.socket sys.stat sys.statvfs sys.time \
  sys.times sys.utsname sys.wait syslog termio time \
  unistd utime
posix_P= vendor/c/posix/src
C_MODULES+= $(foreach m, $(LUAPOSIX), posix.$m.a)
C_MODULES:= $(filter-out posix.a,$(C_MODULES))
CFLAGS+= $(CFLAGS_LRT)
VENDOR+= posix
CLEAN+= clean_posix

$(posix_P)/sys/%.o:  $(posix_P)/sys/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(luaposixDEFINES) -I$(posix_P) $(ACFLAGS) -c $<

posix.sys.%.a: $(posix_P)/sys/%.o
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(posix_P)/%.o:  $(posix_P)/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(luaposixDEFINES) -I$(posix_P) $(ACFLAGS) -c $<

posix.%.a: $(posix_P)/%.o
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

clean_posix:
	$(RM) $(RMFLAGS) $(posix_P)/*.o $(C_MODULES)

.PHONY: clean_posix

