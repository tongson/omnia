posix_P= vendor/c/posix/src
posixA= ctype dirent errno fcntl fnmatch glob grp \
  libgen poll pwd sched signal stdio stdlib sys.msg \
  sys.resource sys.socket sys.stat sys.statvfs sys.time \
  sys.times sys.utsname sys.wait syslog termio time \
  unistd utime
posixO= ctype dirent errno fcntl fnmatch glob grp \
  libgen poll pwd sched signal stdio stdlib sys/msg  \
  sys/resource sys/socket sys/stat sys/statvfs sys/time \
  sys/times sys/utsname sys/wait syslog termio time \
  unistd utime
posixOBJS= $(foreach m, $(posixO), $(posix_P)/$m.o)
posixSO= posix.so
C_MODULES+= $(foreach m, $(posixA), posix.$m.a)
C_MODULES:= $(filter-out posix.a, $(C_MODULES))
VENDOR+= posix
CLEAN+= clean_posix
luaposixDEFINES+= -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -DPACKAGE=\"luaposix\" -DVERSION=\"34.0-1\" -DHAVE_STATVFS -DHAVE_FDATASYNC -DHAVE_NET_IF_H -DHAVE_SYS_MSG_H -DHAVE_MSGRCV -DHAVE_MSGSND

$(posix_P)/sys/socket.o:  $(posix_P)/sys/socket.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -Wno-error=address -Wno-error=unused-function -Wno-error=unused-variable -o $@ $(luaposixDEFINES) -I$(posix_P) $(TARGET_FLAGS) -c $<

$(posix_P)/sys/%.o:  $(posix_P)/sys/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -Wno-error=unused-function -Wno-error=unused-variable -o $@ $(luaposixDEFINES) -I$(posix_P) $(TARGET_FLAGS) -c $<

posix.sys.%.a: $(posix_P)/sys/%.o
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(posix_P)/unistd.o:  $(posix_P)/unistd.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -Wno-error=redundant-decls -Wno-error=unused-function -Wno-error=unused-variable -o $@ $(luaposixDEFINES) -I$(posix_P) $(TARGET_FLAGS) -c $<

$(posix_P)/%.o:  $(posix_P)/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -Wno-error=unused-function -Wno-error=unused-variable -o $@ $(luaposixDEFINES) -I$(posix_P) $(TARGET_FLAGS) -c $<


posix.%.a: $(posix_P)/%.o
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(posixSO): $(posixOBJS)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_posix:
	$(RM) $(RMFLAGS) $(posix_P)/*.o $(posix_P)/sys/*.o $(C_MODULES) $(posixSO)

.PHONY: clean_posix

