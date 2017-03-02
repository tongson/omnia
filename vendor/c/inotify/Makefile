inotifySRC= vendor/c/inotify/linotify.c
inotifyOBJ= vendor/c/inotify/linotify.o
inotifyA= inotify.a
inotifySO= inotify.so
CLEAN+= clean_inotify

$(inotifyA): $(inotifyOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(inotifyOBJ): $(inotifySRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/inotify $(TARGET_FLAGS) -c $<

$(inotifySO): $(inotifyOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_inotify:
	$(RM) $(RMFLAGS) $(inotifyOBJ) $(inotifyA) $(inotifySO)

.PHONY: clean_inotify
