qhttpSRC= vendor/c/qhttp/qhttp.c
qhttpOBJ= vendor/c/qhttp/qhttp.o
qhttpA= qhttp.a
qhttpSO= qhttp.so
CLEAN+= clean_qhttp

$(qhttpA): $(qhttpOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(qhttpOBJ): $(qhttpSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -std=c99 -o $@ -Ivendor/c/qhttp -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

$(qhttpSO): $(qhttpOBJ) vendor/c/auxlib/auxlib.o
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_qhttp:
	$(RM) $(RMFLAGS) $(qhttpOBJ) $(qhttpA) $(qhttpSO)

.PHONY: clean_qhttp
