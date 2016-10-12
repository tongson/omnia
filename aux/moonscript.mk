MOONC_T= bin/moonc
MOONI_T= bin/mooni
MOONPICK_T= bin/moonpick
MOONC= bin/moonc.lua
MOONI= bin/mooni.lua
MOONPICK= bin/moonpick.lua
MOONSCRIPT= moonscript/*.lua moonscript/parse/*.lua moonscript/compile/*.lua moonscript/transform/*.lua
CLEAN+= clean_moonscript

$(MOONC_T): $(HOST_LUA_A) $(LUA_T) $(host_lpegA)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOONC) cimicida.lua $(MOONSCRIPT) $(host_lpegA) \
		 $(HOST_LUA_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) cimicida.lua $(MOONC).c
	$(RMRF) moonscript

$(MOONI_T): $(MOONC_T)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOONI) $(MOONSCRIPT) $(host_lpegA) \
		 $(HOST_LUA_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) cimicida.lua $(MOONI).c
	$(RMRF) moonscript

$(MOONPICK_T): $(HOST_LUA_A) $(LUA_T) $(host_lpegA)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonpick vendor/lua/moonscript .
	$(CP) vendor/lua/moonpick.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOONPICK) moonpick.lua moonpick/*.lua $(MOONSCRIPT) $(host_lpegA) \
		 $(HOST_LUA_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) moonpick.lua $(MOONPICK).c
	$(RMRF) moonpick moonscript


%.lua: $(MOONC_T) %.moon
	$(MOONC_T) $*.moon $@

clean_moonscript:
	$(RM) $(RMFLAGS) $(COMPILED) $(MOONC_T) $(MOONI_T) $(MOONPICK_T) $(host_lpegA) cimicida.lua
