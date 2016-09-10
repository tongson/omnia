all: $(EXE)
MAIN= $(EXE).lua
AUX_P= aux
ONE= $(AUX_P)/one
LUASTATIC= aux/luastatic.lua
LUAC_T= luac
LUA_O= $(ONE).o
LUA_A= liblua.a
LUA_T= ./lua
LUACFLAGS?= -s
ECHO= @printf '%s\n'
ECHON= @printf '%s'
ECHOT= @printf ' %s\t%s\n'
CP= cp
STRIP= strip
STRIPFLAGS= --strip-all
RM= rm
RMFLAGS= -f
RMRF= rm -rf
VENDOR_P= vendor/lua
APP_P= app/lua
SRC_P= aux/lua
INCLUDES:= -I$(SRC_P) -Iinclude -I$(AUX_P)
VENDOR_LUA:= $(addsuffix /*.lua,$(VENDOR_DIR))
APP_LUA:= $(addsuffix /*.lua,$(APP_DIR))
VENDOR_DIRS:= $(foreach f, $(VENDOR_DIR), $(firstword $(subst /, ,$f)))
APP_DIRS:= $(foreach f, $(APP_DIR), $(firstword $(subst /, ,$f)))
_rest= $(wordlist 2,$(words $(1)),$(1))
_lget= $(firstword app/c/$(1))/Makefile $(if $(_rest),$(call _lget,$(_rest)),)
_vget= $(firstword vendor/c/$(1))/Makefile $(if $(_rest),$(call _vget,$(_rest)),)
MODULES+= $(foreach m, $(VENDOR), $m.lua)
MODULES+= $(foreach m, $(APP), $m.lua)
C_MODULES+= $(foreach m, $(VENDOR_C), $m.a)
C_MODULES+= $(foreach m, $(APP_C), $m.a)
BUILD_DEPS= has-$(CC) has-$(RANLIB) has-$(NM) has-$(LD) has-$(AR) has-$(STRIP) has-$(RM) has-$(CP)
ifneq ($(APP_C),)
  include $(eval _d:=app/c/$(APP_C) $(_d)) $(call _lget,$(APP_C))
endif
ifneq ($(VENDOR_C),)
  include $(eval _d:=vendor/c/$(VENDOR_C) $(_d)) $(call _vget,$(VENDOR_C))
endif
