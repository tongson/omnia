linotifySRC= vendor/c/linotify/linotify.c
linotifyOBJ= vendor/c/linotify/linotify.o
linotifyA= inotify.a
C_MODULES+= $(linotifyA)
C_MODULES:= $(filter-out linotify.a,$(C_MODULES))
CLEAN+= clean_linotify

$(linotifyA): $(linotifyOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(linotifyOBJ): $(linotifySRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) -Ivendor/c/linotify $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_linotify:
	$(RM) $(RMFLAGS) $(linotifyOBJ) $(linotifyA)

.PHONY: clean_linotify
