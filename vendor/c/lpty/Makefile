lptySRC= vendor/c/lpty/lpty.c
lptyOBJ= vendor/c/lpty/lpty.o
lptyA= lpty.a
lptySO= lpty.so
CLEAN+= clean_lpty

$(lptyA): $(lptyOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(lptyOBJ): $(lptySRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/lpty $(TARGET_FLAGS) -c $<

$(lptySO): $(lptyOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_lpty:
	$(RM) $(RMFLAGS) $(lptyOBJ) $(lptyA) $(lptySO)

.PHONY: clean_lpty
