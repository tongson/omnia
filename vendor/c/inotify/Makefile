inotifySRC= vendor/c/inotify/linotify.c
inotifyOBJ= vendor/c/inotify/linotify.o
inotifyA= inotify.a
CLEAN+= clean_inotify

$(inotifyA): $(inotifyOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(inotifyOBJ): $(inotifySRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -Ivendor/c/inotify $(ACFLAGS) -c $<

clean_inotify:
	$(RM) $(RMFLAGS) $(inotifyOBJ) $(inotifyA)

.PHONY: clean_inotify
