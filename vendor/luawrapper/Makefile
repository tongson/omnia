luawrapperA= vendor/luawrapper/libluawrapper.a
luawrapperSRC= vendor/luawrapper/luawrapper.c
luawrapperOBJ= vendor/luawrapper/luawrapper.o
lw_dependenciesSRC= vendor/luawrapper/lw_dependencies.c
lw_dependenciesOBJ= vendor/luawrapper/lw_dependencies.o
CLEAN+= clean_luawrapper
CCWARN=

$(luawrapperA): $(luawrapperOBJ) $(lw_dependenciesOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(luawrapperOBJ): $(luawrapperSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) -Ivendor/libelf -Ivendor/luawrapper $(CCWARN) $(CFLAGS) $(CCOPT) -c $^

$(lw_dependenciesOBJ): $(lw_dependenciesSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(LDEFINES) $(INCLUDES) -Ivendor/luawrapper $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_luawrapper:
	$(RM) $(RMFLAGS) $(luawrapperOBJ) $(luawrapperA) $(lw_dependenciesOBJ)

.PHONY: clean_luawrapper
