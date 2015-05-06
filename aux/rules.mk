$(LUAC_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -lm -DMAKE_LUAC $(DEFINES) $(INCLUDES) $(CCWARN) $(ONE).c

$(LUAC2C_T): $(AUX_P)/luac2c.c
	$(ECHOT) [CC] $@
	cc -o $@ $(CCWARN) $<

$(LUA_O): $(BUILD_DEPS) $(LUAC_T) $(LUAC2C_T) $(DEPS)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -c -DMAKE_LIB $(DEFINES) $(luaDEFINES) $(LDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c $(LDLIBS)

$(LUA_T): $(LUA_O) $(luawrapperA) $(libelfA)
	$(ECHOT) [CC] $@
	$(CC) $(LUAWRAPPER) -o $@ $(CCWARN) $(CFLAGS) $(CCOPT) $(DLDFLAGS) $(LDLIBS) $(LUA_O)

ifneq ($(filter sections,$(MAKECMDGOALS)),)
.NOTPARALLEL:
%LUA:
	$(OBJCOPYA)$(*F)=vendor/$(*F)/$(*F).lua $(LUA_T) $(LUA_T)
sections: $(foreach m, $(VENDOR_LUA), $mLUA)
endif

exe:
	$(OBJCOPYA)main=$(MAIN) $(LUA_T) $(EXE)
	$(ECHOT) [LN] $(EXE)

clean: $(CLEAN) clean_luawrapper clean_libelf
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


