$(LUAC_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUAC $(DEFINES) $(INCLUDES) $(CCWARN) $(ONE).c -lm

$(LUA_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUA $(luaDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c -lm

$(LUA_O): $(BUILD_DEPS) $(LUA_T) $(LUAC_T) $(DEPS)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -c -DMAKE_LIB $(DEFINES) $(luaDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c 

$(LUA_A): $(LUA_O)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

exe: $(LUA_A)
	$(LUA_T) aux/luastatic.lua $(MAIN) $(LUA_A) $(CLUA_MODS) $(LUA_MODS) $(INCLUDES)

clean: $(CLEAN) 
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(LUA_T) $(LUAC_T) $(LUAC2C_T) $(EXE)
	$(RMRF) test/tmp
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


