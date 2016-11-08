qhttpSRC= vendor/c/qhttp/qhttp.c
qhttpOBJ= vendor/c/qhttp/qhttp.o
qhttpA= qhttp.a
CLEAN+= clean_qhttp

$(qhttpA): $(qhttpOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(qhttpOBJ): $(qhttpSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/qhttp -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

clean_qhttp:
	$(RM) $(RMFLAGS) $(qhttpOBJ) $(qhttpA)

.PHONY: clean_qhttp
