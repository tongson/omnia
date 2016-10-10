auxlibSRC= vendor/c/auxlib/auxlib.c
auxlibOBJ= vendor/c/auxlib/auxlib.o
auxlibA= auxlib.a
CLEAN+= clean_auxlib

$(auxlibA): $(auxlibOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(auxlibOBJ): $(auxlibSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

clean_auxlib:
	$(RM) $(RMFLAGS) $(auxlibOBJ) $(auxlibA)

.PHONY: clean_auxlib
