ifeq ($(filter bin/moor,$(MAKECMDGOALS)),bin/moor)
  include vendor/c/linenoise/Makefile
endif

ifeq ($(filter lpeg,$(VENDOR_C)),)
  include vendor/c/lpeg/Makefile
endif

MOONC_T= bin/moonc
MOOR_T= bin/moor
MOONC= bin/moonc.lua
MOOR= bin/moor.lua
MOONPICK= moonpick/config.lua moonpick.lua
MOONSCRIPT= moonscript/*.lua moonscript/parse/*.lua moonscript/compile/*.lua moonscript/transform/*.lua
CLEAN+= clean_moonscript

$(MOONC_T): $(HOST_LUA_A) $(LUA_T) $(host_lpegA)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonscript vendor/lua/cimicida.lua vendor/lua/moonpick vendor/lua/moonpick.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOONC) cimicida.lua $(MOONPICK) $(MOONSCRIPT) $(host_lpegA) \
		 $(HOST_LUA_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) cimicida.lua moonpick.lua $(MOONC).c
	$(RMRF) moonscript moonpick

$(MOOR_T): $(MOONC_T) vendor/lua/moor.lua bin/moor.lua vendor/lua/moor/opts.lua vendor/lua/moor/utils.lua $(linenoiseA)
	$(ECHOT) CC $@
	$(CPR) vendor/lua/moonscript vendor/lua/moor .
	$(CP) vendor/lua/moor.lua vendor/lua/inspect.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(MOOR) moor.lua moor/*.lua inspect.lua $(MOONSCRIPT) \
	   $(linenoiseA) $(host_lpegA) \
		 $(HOST_LUA_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) moor.lua inspect.lua $(MOOR).c
	$(RMRF) moor moonscript

%.lua: $(MOONC_T) %.moon
	$(MOONC_T) $*.moon $@

clean_moonscript:
	$(RM) $(RMFLAGS) $(COMPILED_MOON) $(MOONC_T) $(host_lpegA) cimicida.lua \
	  vendor/c/linenoise/*.o vendor/lua/moor/*.lua vendor/lua/moor.lua bin/moor
