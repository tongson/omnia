$(LUAC_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUAC $(DEFINES) $(INCLUDES) $(CCWARN) $(ONE).c -lm

$(LUA_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUA $(luaDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c -lm

$(LUA_O): $(LUA_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -c -DMAKE_LIB $(DEFINES) $(luaDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c

$(LUA_A): $(LUA_O)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(EXE): $(BUILD_DEPS) $(LUA_A) $(C_MODULES) $(COMPILED)
	$(ECHOT) [CP] $(MODULES)
	for f in $(VENDOR); do cp $(VENDOR_P)/$$f.lua .; done
	for f in $(SRC); do cp $(SRC_P)/$$f.lua .; done
	for d in $(VENDOR_DIRS); do cp -R $(VENDOR_P)/$$d .; done
	for d in $(SRC_DIRS); do cp -R $(SRC_P)/$$d .; done
	$(ECHOT) [LN] $(MAIN)
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MAIN) $(SRC_LUA) $(VENDOR_LUA) $(MODULES) $(C_MODULES) \
		 $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) $(MAIN).c $(MODULES)
	$(RMRF) $(VENDOR_DIRS) $(SRC_DIRS)

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(LUA_T) $(LUAC_T) $(LUA_A) $(MAIN).c $(EXE) $(MODULES)
	$(RMRF) $(VENDOR_DIRS) $(SRC_DIRS)
	$(ECHO) "Done!"
