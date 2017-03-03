lsocketSRC= vendor/c/lsocket/lsocket.c
lsocketOBJ= vendor/c/lsocket/lsocket.o
lsocketA= lsocket.a
lsocketSO= lsocket.so
CLEAN+= clean_lsocket

$(lsocketA): $(lsocketOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(lsocketOBJ): $(lsocketSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(TARGET_FLAGS) -c $<

$(lsocketSO): $(lsocketOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_lsocket:
	$(RM) $(RMFLAGS) $(lsocketOBJ) $(lsocketA) $(lsocketSO)

.PHONY: clean_lsocket
