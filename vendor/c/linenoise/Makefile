linenoiseOBJS= vendor/c/linenoise/linenoise.o vendor/c/linenoise/lua-linenoise.o
linenoiseA= linenoise.a
CLEAN+= clean_linenoise

$(linenoiseA): $(linenoiseOBJS)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/linenoise/%.o: vendor/c/linenoise/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/linenoise $(TARGET_FLAGS) -c $<

clean_linenoise:
	$(RM) $(RMFLAGS) $(linenoiseOBJS) $(linenoiseA)

.PHONY: clean_linenoise
