factidSRC= vendor/c/factid/src/factidC.c
factidOBJ= vendor/c/factid/src/factidC.o
factidA= factidC.a
factidSO= factidC.so
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

$(factidSO): $(factidOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_factid:
	$(RM) $(RMFLAGS) $(factidA) $(factidOBJ) $(factidSO)

.PHONY: clean_factid

