posix_cSRC= vendor/luaposix/src/posix.c
posix_cOBJ= vendor/luaposix/posix_c.o
posixSRC= vendor/luaposix/src/init.lua
posixOBJ= vendor/luaposix/posix.o
posixC= vendor/luaposix/posix.c
posixLUAC= vendor/luaposix/posix.luac
posixA= luaposix.a
DEPS+= $(posixA)
CLEAN+= clean_posix
TEST+= test_posix
TESTS= dir.lua fork2.lua fork.lua getopt.lua signal.lua
CCWARN=

$(posixA): $(posix_cOBJ) $(posixOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(posix_cOBJ): $(posix_cSRC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(luaposixDEFINES) $(INCLUDES) -Ivendor/luaposix/src $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(posixOBJ): $(posixC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(posixC): $(posixLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n posix -o $@ $<

$(posixLUAC): $(posixSRC) $(LUAC_T)
	@$(LUAC) -s -o $@ $<

clean_posix:
	$(RM) $(RMFLAGS) $(posix_cOBJ) $(posixA) $(posixOBJ) $(posixC) $(posixLUAC)

test_posix: $(LUA_T)
	cd vendor/luaposix/test; for i in $(TESTS); do ../../../bin/lua $$i; done

.PHONY: clean_posix test_posix

