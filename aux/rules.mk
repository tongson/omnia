$(LUAC_T):
	$(ECHOT) CC $@
	$(CC) -o $@ -DMAKE_LUAC $(FLAGS) $(ONE).c -lm

$(LUA_T):
	$(ECHOT) CC $@
	$(CC) -o $@ -DMAKE_LUA $(luaDEFINES) $(FLAGS) $(ONE).c -lm

$(LUA_O): $(LUA_T)
	$(ECHOT) CC $@
	$(TARGET_CC) -o $@ -c -Iaux -DMAKE_LIB $(luaDEFINES) $(TARGET_FLAGS) $(ONE).c

$(LUA_A): $(LUA_O)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(MODULES):
	$(ECHOT) CP $(MODULES)
	for f in $(VENDOR); do cp $(VENDOR_P)/$$f.lua .; done
	for f in $(SRC); do cp $(SRC_P)/$$f.lua .; done

$(SRC_LUA):
	$(ECHOT) CP $(SRC_DIRS)
	for d in $(SRC_DIRS); do cp -R $(SRC_P)/$$d .; done

$(VENDOR_LUA):
	$(ECHOT) CP $(VENDOR_DIRS)
	for d in $(VENDOR_DIRS); do cp -R $(VENDOR_P)/$$d .; done

$(EXE_T): $(BUILD_DEPS) $(LUA_A) $(C_MODULES) $(COMPILED) $(MODULES) $(SRC_LUA) $(VENDOR_LUA)
	$(ECHOT) LN $(EXE_T)
	CC=$(TARGET_CC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) $(MAIN) $(SRC_LUA) $(VENDOR_LUA) $(MODULES) $(C_MODULES) $(LUA_A) \
	  $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) $(MAIN).c $(MODULES)
	$(RMRF) $(VENDOR_DIRS) $(SRC_DIRS)

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(LUA_T) $(LUAC_T) $(LUA_A) $(EXE_T)
	$(ECHO) "Done!"

new:
	$(RMRF) vendor/lua/* vendor/c/* src/lua/* src/c/* bin/test.moon bin/main.lua Makefile
	$(CP) aux/Makefile.pristine Makefile

