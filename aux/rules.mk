$(LUAC_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUAC $(DEFINES) $(INCLUDES) $(CCWARN) $(ONE).c -lm

$(LUA_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUA $(luaDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c -lm

$(LUA_O): $(BUILD_DEPS) $(LUA_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -c -DMAKE_LIB $(DEFINES) $(luaDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c

$(LUA_A): $(LUA_O)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(EXE): $(LUA_A) $(CLUA_MODS)
	$(ECHOT) [CP] $(LUA_MODS)
	for f in $(VENDOR_LUA); do cp $(VENDOR_LUA_P)/$$f.lua .; done
	for f in $(APP_LUA); do cp $(APP_LUA_P)/$$f.lua .; done
	for d in $(VENDOR_SUBDIRS); do cp -R $(MODULES_P)/$$d .; done
	$(ECHOT) [LN] $(MAIN)
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MAIN) $(LUA_MODS) $(VENDOR_DEPS) $(CLUA_MODS) $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) 2>&1 >/dev/null

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(LUA_T) $(LUAC_T) $(EXE) $(LUA_A) $(MAIN).c $(LUA_MODS)
	$(RMRF) $(VENDOR_SUBDIRS)
	$(ECHO) "Done!"

print-%: ; @echo $*=$($*)

vprint-%:
	@echo '$*=$($*)'
	@echo ' origin = $(origin $*)'
	@echo ' flavor = $(flavor $*)'
	@echo ' value = $(value $*)'

has-%:
	@command -v "${*}" >/dev/null 2>&1 || { \
		echo "Missing build-time dependency: ${*}"; \
		exit -1; \
	}

.PHONY: all clean sections exe print-% vprint-% has-% %LUA


