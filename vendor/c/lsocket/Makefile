lsocketSRC= vendor/c/lsocket/lsocket.c
lsocketOBJ= vendor/c/lsocket/lsocket.o
lsocketA= lsocket.a
CLEAN+= clean_lsocket
CCWARN=

$(lsocketA): $(lsocketOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(lsocketOBJ): $(lsocketSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(ACFLAGS) -c $<

clean_lsocket:
	$(RM) $(RMFLAGS) $(lsocketOBJ) $(lsocketA)

.PHONY: clean_lsocket
