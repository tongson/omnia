FNLC= bin/fennelc.lua
FNLC_T= bin/fennelc
FNL = bin/fennel.lua
FNL_T= bin/fennel
CLEAN+= clean_fennel

$(FNL_T): $(FNLC_T)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/fennel/fennel.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(FNL) fennel.lua $(HOST_LUA_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) fennel.lua $(FNL).c

%.lua: %.fnl
	$(FNLC) $*.fnl $@

clean_fennel:
	$(RM) $(RMFLAGS) $(COMPILED_FNL) $(FNLC_T) $(FNL_T) cimicida.lua
