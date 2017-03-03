lfsP= vendor/c/lfs
lfsSRC= $(lfsP)/lfs.c
lfsOBJ= $(lfsP)/lfs.o
lfsSO= lfs.so
lfsA= lfs.a
CLEAN+= clean_lfs

$(lfsA): $(lfsOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(lfsOBJ): $(lfsSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -I $(lfsP) $(TARGET_FLAGS) -c $<

$(lfsSO): $(lfsOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_lfs:
	$(RM) $(RMFLAGS) $(lfsOBJ) $(lfsA) $(lfsSO)

.PHONY: clean_lfs
