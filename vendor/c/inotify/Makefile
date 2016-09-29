inotifySRC= vendor/c/inotify/linotify.c
inotifyOBJ= vendor/c/inotify/linotify.o
inotifyA= inotify.a
CLEAN+= clean_inotify

$(inotifyA): $(inotifyOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(inotifyOBJ): $(inotifySRC)
	$(ECHOT) CC $@
	$(TARGET_CC) -o $@ -Ivendor/c/inotify $(TARGET_FLAGS) -c $<

clean_inotify:
	$(RM) $(RMFLAGS) $(inotifyOBJ) $(inotifyA)

.PHONY: clean_inotify
