setproctitleOBJ= vendor/c/setproctitle/setproctitle.o
setproctitleA= setproctitle.a
CLEAN+= clean_setproctitle

$(setproctitleA): $(setproctitleOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/setproctitle/%.o: vendor/c/setproctitle/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/setproctitle -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

clean_setproctitle:
	$(RM) $(RMFLAGS) $(setproctitleOBJ) $(setproctitleA)

.PHONY: clean_setproctitle
