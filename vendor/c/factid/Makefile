factidSRC= vendor/c/factid/src/factidC.c
factidOBJ= vendor/c/factid/src/factidC.o
factidA= factidC.a
C_MODULES+= $(factidA)
C_MODULES:= $(filter-out factid.a,$(C_MODULES))
VENDOR+= factid
CLEAN+= clean_factid

$(factidA): $(factidOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(factidOBJ): $(factidSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(TARGET_FLAGS) -c $<

clean_factid:
	$(RM) $(RMFLAGS) $(factidA) $(factidOBJ)

.PHONY: clean_factid

