setproctitleOBJ= vendor/c/setproctitle/setproctitle.o
setproctitleA= setproctitle.a
setproctitleSO= setproctitle.so
CLEAN+= clean_setproctitle

$(setproctitleA): $(setproctitleOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/setproctitle/%.o: vendor/c/setproctitle/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/setproctitle -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

$(setproctitleSO): $(setproctitleOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_setproctitle:
	$(RM) $(RMFLAGS) $(setproctitleOBJ) $(setproctitleA) $(setproctitleSO)

.PHONY: clean_setproctitle
