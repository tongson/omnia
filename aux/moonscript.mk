MOONC_T= bin/moonc
MOONI_T= bin/mooni
MOONC= bin/moonc.lua
MOONI= bin/mooni.lua
MOONSCRIPT= moonscript/*.lua moonscript/parse/*.lua moonscript/compile/*.lua moonscript/transform/*.lua
CLEAN+= clean_moonscript

$(MOONC_T): $(LUA_A) $(LUA_T) $(lpegA)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua .
	CC=$(TARGET_CC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) $(MOONC) cimicida.lua $(MOONSCRIPT) $(lpegA) \
		 $(LUA_A) $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) cimicida.lua $(MOONC).c
	$(RMRF) moonscript

$(MOONI_T): $(MOONC_T)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua .
	CC=$(TARGET_CC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) $(MOONI) $(MOONSCRIPT) $(lpegA) \
		 $(LUA_A) $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) cimicida.lua $(MOONI).c
	$(RMRF) moonscript

%.lua: $(MOONC_T) %.moon
	$(MOONC_T) $*.moon $@

clean_moonscript:
	$(RM) $(RMFLAGS) $(COMPILED) $(MOONC_T) $(MOONI_T) $(lpegA)
