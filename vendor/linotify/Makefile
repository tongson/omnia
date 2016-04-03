linotifySRC= vendor/linotify/linotify.c
linotifyOBJ= vendor/linotify/linotify.o
linotifyA= linotify.a
DEPS+=$(linotifyA)
CLEAN+= clean_linotify
CCWARN=

$(linotifyA): $(linotifyOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(linotifyOBJ): $(linotifySRC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) -Ivendor/linotify $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_linotify:
	$(RM) $(RMFLAGS) $(linotifyOBJ) $(linotifyA)

.PHONY: clean_linotify
