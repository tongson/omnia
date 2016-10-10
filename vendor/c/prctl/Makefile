prctlSRC= vendor/c/prctl/prctl.c
prctlOBJ= vendor/c/prctl/prctl.o
prctlA= prctl.a
CLEAN+= clean_prctl

$(prctlA): $(prctlOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(prctlOBJ): $(prctlSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/auxlib -Ivendor/c/prctl $(TARGET_FLAGS) -c $<

clean_prctl:
	$(RM) $(RMFLAGS) $(prctlOBJ) $(prctlA)

.PHONY: clean_prctl
