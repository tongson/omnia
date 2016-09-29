lpegA= lpeg.a
lpegOBJS= vendor/c/lpeg/lpcap.o vendor/c/lpeg/lpcode.o vendor/c/lpeg/lptree.o vendor/c/lpeg/lpvm.o
ifeq ($(DEBUG), 1)
  lpegOBJS+= vendor/c/lpeg/lpprint.o
endif
CLEAN+= clean_lpeg

$(lpegA): $(lpegOBJS)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/lpeg/%.o: vendor/c/lpeg/%.c
	$(ECHOT) CC $@
	$(TARGET_CC) -o $@ $(lpegDEFINES) -Ivendor/c/lpeg -c $(TARGET_FLAGS) $<

clean_lpeg:
	$(RM) $(RMFLAGS) $(lpegOBJS) $(lpegA) vendor/c/lpeg/lpprint.o lpprint.o

.PHONY: clean_lpeg
