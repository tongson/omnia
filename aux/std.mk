all: $(EXE)
MAIN:= $(EXE).lua
ONE:= aux/one
LUASTATIC:= aux/luastatic.lua
LUAC_T:= luac
LUA_O:= $(ONE).o
LUA_A:= liblua.a
LUA_T:= ./lua
LUACFLAGS?= -s
ECHO:= @printf '%s\n'
ECHON:= @printf '%s'
ECHOT:= @printf ' %s\t%s\n'
CP:= cp
STRIP:= strip
STRIPFLAGS:= --strip-all
RM:= rm
RMFLAGS:= -f
RMRF:= rm -rf
VENDOR_P:= vendor/lua
SRC_P:= src/lua
INCLUDES:= -Iaux/lua -Iinclude -Iaux
VENDOR_LUA:= $(addsuffix /*.lua,$(VENDOR_DIR))
SRC_LUA:= $(addsuffix /*.lua,$(SRC_DIR))
VENDOR_DIRS:= $(foreach f, $(VENDOR_DIR), $(firstword $(subst /, ,$f)))
SRC_DIRS:= $(foreach f, $(SRC_DIR), $(firstword $(subst /, ,$f)))
_rest= $(wordlist 2,$(words $(1)),$(1))
_lget= $(firstword src/c/$(1))/Makefile $(if $(_rest),$(call _lget,$(_rest)),)
_vget= $(firstword vendor/c/$(1))/Makefile $(if $(_rest),$(call _vget,$(_rest)),)
MODULES+= $(foreach m, $(VENDOR), $m.lua)
MODULES+= $(foreach m, $(SRC), $m.lua)
C_MODULES+= $(foreach m, $(VENDOR_C), $m.a)
C_MODULES+= $(foreach m, $(SRC_C), $m.a)
BUILD_DEPS= has-$(CC) has-$(RANLIB) has-$(NM) has-$(LD) has-$(AR) has-$(STRIP) has-$(RM) has-$(CP)
ifneq ($(SRC_C),)
  include $(eval _d:=src/c/$(SRC_C) $(_d)) $(call _lget,$(SRC_C))
endif
ifneq ($(VENDOR_C),)
  include $(eval _d:=vendor/c/$(VENDOR_C) $(_d)) $(call _vget,$(VENDOR_C))
endif
