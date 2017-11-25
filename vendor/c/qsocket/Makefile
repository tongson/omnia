qsocketSRC= vendor/c/qsocket/qsocket.c
qsocketOBJ= vendor/c/qsocket/qsocket.o
qsocketA= qsocket.a
qsocketSO= qsocket.so
CLEAN+= clean_qsocket

$(qsocketA): $(qsocketOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(qsocketOBJ): $(qsocketSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/qsocket -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

$(qsocketSO): $(qsocketOBJ) vendor/c/auxlib/auxlib.o
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_qsocket:
	$(RM) $(RMFLAGS) $(qsocketOBJ) $(qsocketA) $(qsocketSO)

.PHONY: clean_qsocket
