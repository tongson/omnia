md5SRC= vendor/c/md5/md5.c
md5OBJ= vendor/c/md5/md5.o
md5A= md5.a
CLEAN+= clean_md5

$(md5A): $(md5OBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(md5OBJ): $(md5SRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/md5 $(TARGET_FLAGS) -c $<

clean_md5:
	$(RM) $(RMFLAGS) $(md5OBJ) $(md5A)

.PHONY: clean_md5
