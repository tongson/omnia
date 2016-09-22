MOONC_T= moonc
MOONI_T= mooni
MOONC_M= aux/moonc.lua
MOONI_M= aux/mooni.lua
MOONSCRIPT= moonscript/*.lua moonscript/parse/*.lua moonscript/compile/*.lua moonscript/transform/*.lua
VENDOR_C+= lpeg
CLEAN+= clean_moonscript

$(MOONC_T): $(LUA_A) $(LUA_T) $(lpegA)
	$(ECHOT) [CC] $@
	$(CP) $(MOONC_M) .
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua .
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) moonc.lua cimicida.lua $(MOONSCRIPT) $(lpegA) \
		 		 $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) 2>&1 >/dev/null

$(MOONI_T): $(MOONC_T)
	$(ECHOT) [CC] $@
	$(CP) $(MOONI_M) .
	$(CPR) vendor/lua/moonscript .
	CC=$(CC) NM=$(NM) $(LUA_T) $(LUASTATIC) mooni.lua $(MOONSCRIPT) $(lpegA) \
		 		 $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS) 2>&1 >/dev/null

%.lua: $(MOONC_T)
	./$(MOONC_T) $*.moon $@

clean_moonscript:
	$(RM) $(RMFLAGS) $(COMPILED) moonc moonc.lua.c moonc.lua mooni mooni.lua.c mooni.lua cimicida.lua $(lpegA)
	$(RMRF) moonscript
