lpegA= vendor/lpeg/liblpeg.a
lpegOBJS= vendor/lpeg/lpcap.o vendor/lpeg/lpcode.o vendor/lpeg/lpprint.o vendor/lpeg/lptree.o vendor/lpeg/lpvm.o
DEPS+=$(lpegA)
CLEAN+= clean_lpeg
CCWARN=

$(lpegA): $(lpegOBJS)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

vendor/lpeg/%.o: vendor/lpeg/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(lpegDEFINES) $(INCLUDES) -Ivendor/lpeg $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_lpeg:
	$(RM) $(RMFLAGS) $(lpegOBJS) $(lpegA)

.PHONY: clean_lpeg
