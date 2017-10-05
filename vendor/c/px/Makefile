pxSRC= vendor/c/px/src/px.c
pxOBJ= vendor/c/px/src/px.o
pxdepsSRC = vendor/c/px/src/flopen.c vendor/c/px/src/closefrom.c
pxdepsOBJ= vendor/c/px/src/flopen.o vendor/c/px/src/closefrom.o vendor/c/auxlib/auxlib.o
pxA= px.a
pxSO= px.so
CLEAN+= clean_px

$(pxA): $(pxOBJ) $(pxdepsOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(pxOBJ): $(pxSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(pxDEFINES) -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

vendor/c/px/src/%.o: vendor/c/px/src/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(pxDEFINES) $(TARGET_FLAGS) -c $<

$(pxSO): $(pxOBJ) $(pxdepsOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_px:
	$(RM) $(RMFLAGS) $(pxA) $(pxOBJ) $(pxdepsOBJ) $(pxSO)

.PHONY: clean_px

