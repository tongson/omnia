lpeg_P= vendor/c/lpeg
lpegA= lpeg.a
lpegSO= lpeg.so
host_lpegA= host_lpeg.a
lpegOBJS= vendor/c/lpeg/lpcap.o vendor/c/lpeg/lpcode.o vendor/c/lpeg/lptree.o vendor/c/lpeg/lpvm.o
host_lpegOBJS= $(lpeg_P)/host_lpcap.o $(lpeg_P)/host_lpcode.o $(lpeg_P)/host_lptree.o $(lpeg_P)/host_lpvm.o
ifeq ($(DEBUG), 1)
  lpegOBJS+= vendor/c/lpeg/lpprint.o
	host_lpegOBJS+= $(lpeg_P)/host_lpprint.o
endif
CLEAN+= clean_lpeg

$(lpegA): $(lpegOBJS)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(host_lpegA): $(host_lpegOBJS)
	$(ECHOT) AR $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

vendor/c/lpeg/%.o: vendor/c/lpeg/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(lpegDEFINES) -Ivendor/c/lpeg -c $(TARGET_FLAGS) $<

vendor/c/lpeg/host_%.o: vendor/c/lpeg/%.c
	$(ECHOT) CC $@
	$(HOST_CC) -o $@ $(lpegDEFINES) -Ivendor/c/lpeg -fPIC -c $(FLAGS) $<

$(lpegSO): $(host_lpegOBJS)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_lpeg:
	$(RM) $(RMFLAGS) $(lpegOBJS) $(lpegA) $(lpegSO) $(host_lpegOBJS) $(host_lpegA) vendor/c/lpeg/lpprint.o lpprint.o

.PHONY: clean_lpeg
