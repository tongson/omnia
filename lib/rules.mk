$(LUAC_T):
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ -DMAKE_LUAC $(FLAGS) $(ONE).c -lm

$(LUA_T):
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ -DMAKE_LUA -DLUA_USE_DLOPEN $(luaDEFINES) $(FLAGS) $(ONE).c -lm $(LUAT_FLAGS)

$(HOST_LUA_O):
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ -c -Ilib -DMAKE_LIB $(luaDEFINES) -fPIC $(FLAGS) $(ONE).c

$(HOST_LUA_A): $(HOST_LUA_O)
	$(ECHOT) AR $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(LUA_O):
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -c -Ilib -DMAKE_LIB $(luaDEFINES) $(TARGET_FLAGS) $(ONE).c

$(LUA_A): $(LUA_O)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(VENDOR_TOP):
	$(ECHOT) CP VENDOR
	for f in $(VENDOR); do $(CP) $(VENDOR_P)/$$f.lua .; done

$(SRC_TOP):
	$(ECHOT) CP SRC
	for f in $(SRC); do $(CP) $(SRC_P)/$$f.lua .; done

$(SRC_LUA):
	$(ECHOT) CP SRC_DIR
	for d in $(SRC_DIRS); do [ -d $$d ] || $(CPR) $(SRC_P)/$$d .; done

$(VENDOR_LUA):
	$(ECHOT) CP VENDOR_DIR
	for d in $(VENDOR_DIRS); do [ -d $$d ] || $(CPR) $(VENDOR_P)/$$d .; done

$(EXE_T): $(BUILD_DEPS) $(LIBLUA_A) $(LUA_T) $(C_MODULES) $(COMPILED_MOON) $(COMPILED_FNL) $(VENDOR_TOP) $(SRC_TOP) $(SRC_LUA) $(VENDOR_LUA)
	$(ECHOT) LN $(EXE_T)
	CC=$(TARGET_STCC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) $(MAIN) \
	   $(SRC_LUA) $(VENDOR_LUA) $(VENDOR_TOP) $(SRC_TOP) $(C_MODULES) $(LIBLUA_A) \
	   $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) $(MAIN).c $(VENDOR_TOP) $(SRC_TOP)
	$(RMRF) $(VENDOR_DIRS) $(SRC_DIRS)

development: $(LUA_T) $(C_SHARED) $(COMPILED_MOON) $(COMPILED_FNL) $(VENDOR_LUA) $(VENDOR_TOP)
	for f in $(SRC); do $(CP) $(SRC_P)/$$f.lua .; done
	$(RMRF) $(SRC_DIRS)
	for d in $(SRC_DIRS); do $(CPR) $(SRC_P)/$$d .; done
	$(ECHOT) RUN luacheck
	-bin/luacheck.lua src/lua/*.lua $(COMPILED_MOON) $(COMPILED_FNL) $(SRC_CHECK) --exclude-files 'vendor/lua/*'
	$(RM) $(RMFLAGS) luacov.stats.out

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(MAIN).c $(LUA_O) $(LUA_T) $(LUAC_T) $(LUA_A) $(EXE_T) \
	   $(HOST_LUA_A) $(HOST_LUA_O) $(COMPILED_MOON) $(COMPILED_FNL) $(VENDOR_TOP) $(SRC_TOP)
	$(RMRF) $(SRC_DIRS) $(VENDOR_DIRS)
	$(RMRF) *.a bin/*.dSYM luacheck luacov luacov.report.out luacov.stats.out
	$(ECHO) "Done!"

install: $(EXE_T)
	$(ECHO) "Installing..."
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -c $(EXE_T) $(DESTDIR)$(PREFIX)/$(EXE_T)
	$(ECHO) "Done!"

new:
	$(RMRF) vendor/lua/* vendor/c/* src/lua/* src/c/* \
		bin/test.moon bin/moonc.lua bin/moonpick.lua bin/moor.moon Makefile
	$(CP) lib/Makefile.pristine Makefile

