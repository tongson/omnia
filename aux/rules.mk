$(LUAC_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -lm -DMAKE_LUAC $(DEFINES) $(INCLUDES) $(CCWARN) $(ONE).c

$(LUAC2C_T): $(AUX_P)/luac2c.c
	$(ECHOT) [CC] $@
	cc -o $@ $(CCWARN) $<

bootstrap: $(BUILD_DEPS) $(LUAC_T) $(LUAC2C_T)

deps: $(DEPS)

$(LUA_O): $(DEPS)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -c -DMAKE_LIB $(DEFINES) $(luaDEFINES) $(LDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c $(LDLIBS)

$(LUA_T): $(LUA_O) $(luawrapperA) $(libelfA)
	$(ECHOT) [CC] $@
	$(CC) $(LUAWRAPPER) -o $@ $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) $(LDLIBS) $(LUA_O)

%LUA: $(LUA_T)
	$(OBJCOPYA)$(*F)=vendor/$(*F)/$(*F).lua $(LUA_T) $(LUA_T)

lua: $(LUA_T) $(foreach m, $(VENDOR_LUA), $mLUA)
	$(CP) $(LUA_T) $(EXE)

sections: $(foreach m, $(VENDOR_LUA), $mLUA)

exe: $(LUA_T) lua sections
	$(OBJCOPYA)main=$(MAIN) $(LUA_T) $(EXE)
	$(ECHOT) [LN] $(EXE)

strip: $(LUA_T)
	$(STRIP) $(STRIPFLAGS) $^

compress: $(EXE)
	$(UPX) $(UPXFLAGS) $<

clean: $(CLEAN) clean_luawrapper clean_libelf
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(LUA_T) $(LUAC_T) $(LUAC2C_T) $(EXE) $(TESTLOG_F)
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

.PHONY: all init bootstrap deps modules compress strip clean lua sections exe print-% vprint-% has-% %LUA


