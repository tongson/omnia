linenoiseOBJS= vendor/c/linenoise/encodings/utf8.o vendor/c/linenoise/linenoise.o vendor/c/linenoise/lua-linenoise.o
linenoiseA= linenoise.a
linenoiseSO= linenoise.so
CLEAN+= clean_linenoise

$(linenoiseA): $(linenoiseOBJS)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/linenoise/%.o: vendor/c/linenoise/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/linenoise $(TARGET_FLAGS) -c $<

vendor/c/linenoise/encodings/%.o: vendor/c/linenoise/encodings/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/linenoise $(TARGET_FLAGS) -c $<

$(linenoiseSO): $(linenoiseOBJS)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_linenoise:
	$(RM) $(RMFLAGS) $(linenoiseOBJS) $(linenoiseA) $(linenoiseSO)

.PHONY: clean_linenoise
