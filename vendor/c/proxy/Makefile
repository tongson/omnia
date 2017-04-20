proxyOBJ= vendor/c/proxy/luaproxy.o
proxyA= proxy.a
proxySO= proxy.so
CLEAN+= clean_proxy

$(proxyA): $(proxyOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/proxy/%.o: vendor/c/proxy/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/proxy $(TARGET_FLAGS) -c $<

$(proxySO): $(proxyOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_proxy:
	$(RM) $(RMFLAGS) $(proxyOBJ) $(proxyA) $(proxySO)

.PHONY: clean_proxy
