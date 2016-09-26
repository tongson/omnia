luaffifb_P= vendor/c/luaffifb
luaffifbOBJS= $(luaffifb_P)/call.o $(luaffifb_P)/ctype.o $(luaffifb_P)/ffi.o $(luaffifb_P)/parser.o
luaffifbA= ffi.a
C_MODULES+= $(luaffifbA)
C_MODULES:= $(filter-out luaffifb.a,$(C_MODULES))
CLEAN+= clean_luaffifb

$(luaffifb_P)/%.o: $(luaffifb_P)/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I$(luaffifb_P) -I$(luaffifb_P)/dynasm $(ACFLAGS) -c $<

$(luaffifb_P)/test.so: $(luaffifb_P)/test.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I$(luaffifb_P) -I$(luaffifb_P)/dynasm $(ACFLAGS) -shared -fPIC $<

$(luaffifbA): $(luaffifbOBJS)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

clean_luaffifb:
	$(RM) $(RMFLAGS) $(luaffifbOBJS) $(luaffifbA)

.PHONY: clean_luaffifb
