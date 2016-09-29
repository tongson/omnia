lsocketSRC= vendor/c/lsocket/lsocket.c
lsocketOBJ= vendor/c/lsocket/lsocket.o
lsocketA= lsocket.a
CLEAN+= clean_lsocket
CCWARN=

$(lsocketA): $(lsocketOBJ)
	$(ECHOT) [AR] $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(lsocketOBJ): $(lsocketSRC)
	$(ECHOT) [CC] $@
	$(TARGET_CC) -o $@ $(TARGET_FLAGS) -c $<

clean_lsocket:
	$(RM) $(RMFLAGS) $(lsocketOBJ) $(lsocketA)

.PHONY: clean_lsocket
