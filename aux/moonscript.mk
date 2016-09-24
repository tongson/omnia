MOONC_T= bin/moonc
MOONI_T= bin/mooni
MOONC= bin/moonc.lua
MOONI= bin/mooni.lua
MOONSCRIPT= moonscript/*.lua moonscript/parse/*.lua moonscript/compile/*.lua moonscript/transform/*.lua
VENDOR_C+= lpeg
CLEAN+= clean_moonscript

$(MOONC_T): $(LUA_A) $(LUA_T) $(lpegA)
	$(ECHOT) [CC] $@
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua .
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOONC) cimicida.lua $(MOONSCRIPT) $(lpegA) \
		 		 $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) 2>&1 >/dev/null

$(MOONI_T): $(MOONC_T)
	$(ECHOT) [CC] $@
	$(CP) $(MOONI_M) .
	$(CPR) vendor/lua/moonscript .
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOONI) $(MOONSCRIPT) $(lpegA) \
		 		 $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) 2>&1 >/dev/null

%.lua: $(MOONC_T)
	$(MOONC_T) $*.moon $@

clean_moonscript:
	$(RM) $(RMFLAGS) $(COMPILED) $(MOONC_T) $(MOONI_T) $(MOONC).c $(MOONI).c cimicida.lua $(lpegA)
	$(RMRF) moonscript
