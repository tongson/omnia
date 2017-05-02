tweetnaclOBJs= vendor/c/tweetnacl/luatweetnacl.c vendor/c/tweetnacl/tweetnacl.c vendor/c/tweetnacl/randombytes.c
tweetnaclA= tweetnacl.a
tweetnaclSO= tweetnacl.so
CLEAN+= clean_tweetnacl

$(tweetnaclA): $(tweetnaclOBJs)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(TARGET_RANLIB) $@

vendor/c/tweetnacl/%.o: vendor/c/tweetnacl/%.c
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(tweetnaclDEFINES) -Ivendor/c/tweetnacl $(TARGET_FLAGS) -c $<

$(tweetnaclSO): $(tweetnaclOBJs)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_tweetnacl:
	$(RM) $(RMFLAGS) $(tweetnaclOBJs) $(tweetnaclA) $(tweetnaclSO)

.PHONY: clean_tweetnacl
