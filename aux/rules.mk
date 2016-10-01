$(LUAC_T):
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ -DMAKE_LUAC $(FLAGS) $(ONE).c -lm

$(LUA_T):
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ -DMAKE_LUA $(luaDEFINES) $(FLAGS) $(ONE).c -lm

$(HOST_LUA_O):
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ -c -Iaux -DMAKE_LIB $(luaDEFINES) -fPIC $(FLAGS) $(ONE).c

$(HOST_LUA_A): $(HOST_LUA_O)
	$(ECHOT) AR $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(LUA_O):
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -c -Iaux -DMAKE_LIB $(luaDEFINES) $(TARGET_FLAGS) $(ONE).c

$(LUA_A): $(LUA_O)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(MODULES):
	$(ECHOT) CP $(MODULES)
	for f in $(VENDOR); do cp $(VENDOR_P)/$$f.lua .; done
	for f in $(SRC); do cp $(SRC_P)/$$f.lua .; done

$(SRC_LUA):
	$(ECHOT) CP $(SRC_LUA)
	for d in $(SRC_DIRS); do $(CPR) $(SRC_P)/$$d .; done

$(VENDOR_LUA):
	$(ECHOT) CP $(VENDOR_LUA)
	for d in $(VENDOR_DIRS); do $(CPR) $(VENDOR_P)/$$d .; done

$(EXE_T): $(BUILD_DEPS) $(LUA_A) $(LUA_T) $(C_MODULES) $(COMPILED) $(MODULES) $(SRC_LUA) $(VENDOR_LUA)
	$(ECHOT) LN $(EXE_T)
	CC=$(TARGET_STCC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) $(MAIN) $(SRC_LUA) $(VENDOR_LUA) $(MODULES) $(C_MODULES) $(LUA_A) \
	  $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) $(MAIN).c $(MODULES)
	$(RMRF) $(VENDOR_DIRS) $(SRC_DIRS)

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(LUA_T) $(LUAC_T) $(LUA_A) $(EXE_T) $(HOST_LUA_A) $(HOST_LUA_O)
	$(ECHO) "Done!"

new:
	$(RMRF) vendor/lua/* vendor/c/* src/lua/* src/c/* bin/test.moon bin/main.lua Makefile
	$(CP) aux/Makefile.pristine Makefile

