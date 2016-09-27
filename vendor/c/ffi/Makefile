ffi_P= vendor/c/ffi
ffiOBJS= $(ffi_P)/call.o $(ffi_P)/ctype.o $(ffi_P)/ffi.o $(ffi_P)/parser.o
ffiA= ffi.a
CLEAN+= clean_ffi

$(ffi_P)/%.o: $(ffi_P)/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I$(ffi_P) -I$(ffi_P)/dynasm $(ACFLAGS) -c $<

$(ffi_P)/test.so: $(ffi_P)/test.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I$(ffi_P) -I$(ffi_P)/dynasm $(ACFLAGS) -shared -fPIC $<

$(ffiA): $(ffiOBJS)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

clean_ffi:
	$(RM) $(RMFLAGS) $(ffiOBJS) $(ffiA)

.PHONY: clean_ffi
