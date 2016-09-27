ffi_P= vendor/c/ffi
ffiOBJS= $(ffi_P)/call.o $(ffi_P)/ctype.o $(ffi_P)/ffi.o $(ffi_P)/parser.o
ffi_A= ffi.a
CLEAN+= clean_ffi

$(ffi_P)/%.o: $(ffi_P)/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I$(ffi_P) -I$(ffi_P)/dynasm $(ACFLAGS) -c $<

libtest.so: $(ffi_P)/test.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I$(ffi_P) -I$(ffi_P)/dynasm $(ACFLAGS) -shared -fPIC $<

$(ffi_A): $(ffiOBJS)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

bin/test_ffi: $(ffi_A) $(LUA_T) $(LUA_A) libtest.so
	$(ECHOT) CC $@
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(ffi_P)/test_ffi.lua $(ffi_A) $(LUA_A) $(ACFLAGS) $(PIE) $(LDFLAGS) 2>&1 >/dev/null

clean_ffi:
	$(RM) $(RMFLAGS) $(ffiOBJS) $(ffi_A) bin/test_ffi libtest.so $(ffi_P)/test_ffi.lua.c

.PHONY: clean_ffi
