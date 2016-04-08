lfsP= vendor/c/lfs
lfsSRC= $(lfsP)/lfs.c
lfsOBJ= $(lfsP)/lfs.o
lfsA= lfs.a
CLEAN+= clean_lfs
CCWARN=

$(lfsA): $(lfsOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(lfsOBJ): $(lfsSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -I $(lfsP) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_lfs:
	$(RM) $(RMFLAGS) $(lfsOBJ) $(lfsA)

.PHONY: clean_lfs
