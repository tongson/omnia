auxlibSRC= vendor/c/auxlib/auxlib.c
auxlibOBJ= vendor/c/auxlib/auxlib.o
auxlibA= auxlib.a
auxlibSO= auxlib.so
CLEAN+= clean_auxlib

$(auxlibA): $(auxlibOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(auxlibOBJ): $(auxlibSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

$(auxlibSO): $(auxlibOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_auxlib:
	$(RM) $(RMFLAGS) $(auxlibOBJ) $(auxlibA) $(auxlibSO)

.PHONY: clean_auxlib
