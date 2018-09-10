lcurlOBJs= vendor/c/lcurl/l52util.o vendor/c/lcurl/lceasy.o vendor/c/lcurl/lchttppost.o vendor/c/lcurl/lcerror.o vendor/c/lcurl/lcmulti.o vendor/c/lcurl/lcshare.o vendor/c/lcurl/lcutils.o vendor/c/lcurl/lcurl.o vendor/c/lcurl/lmime.o
lcurlA= lcurl.a
lcurlSO= lcurl.so
CLEAN+= clean_lcurl

$(lcurlA): $(lcurlOBJs)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/lcurl/%.o: vendor/c/lcurl/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(lcurlDEFINES) -Ivendor/c/lcurl $(TARGET_FLAGS) -c $<

$(lcurlSO): $(lcurlOBJs)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_lcurl:
	$(RM) $(RMFLAGS) $(lcurlOBJs) $(lcurlA) $(lcurlSO)

.PHONY: clean_lcurl
