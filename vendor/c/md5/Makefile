md5SRC= vendor/c/md5/md5.c
md5OBJ= vendor/c/md5/md5.o
md5A= md5.a
DEPS+=$(md5A)
CLEAN+= clean_md5

$(md5A): $(md5OBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(md5OBJ): $(md5SRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) -Ivendor/c/md5 $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_md5:
	$(RM) $(RMFLAGS) $(md5OBJ) $(md5A)

.PHONY: clean_md5
