arraySRC= vendor/c/array/lua-array.c
arrayOBJ= vendor/c/array/lua-array.o
arrayA= array.a
arraySO= array.so
CLEAN+= clean_array

$(arrayA): $(arrayOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(arrayOBJ): $(arraySRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ $(TARGET_FLAGS) -Wno-error=sign-compare -c $<

$(arraySO): $(arrayOBJ)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $<

clean_array:
	$(RM) $(RMFLAGS) $(arrayOBJ) $(arrayA) $(arraySO)

.PHONY: clean_array
