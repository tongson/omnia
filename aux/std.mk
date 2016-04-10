all: $(EXE)

AUX_P= aux
MODULES_P= vendor/lua
ONE= $(AUX_P)/one
LUASTATIC= aux/luastatic.lua
LUAC_T= luac
LUA_O= $(ONE).o
LUA_A= liblua.a
LUA_T= lua
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
VENDOR_LUA_P= vendor/lua
APP_LUA_P= app/lua

_rest= $(wordlist 2,$(words $(1)),$(1))
_lget= $(firstword lib/$(1))/Makefile $(if $(_rest),$(call _lget,$(_rest)),)
_vget= $(firstword vendor/c/$(1))/Makefile $(if $(_rest),$(call _vget,$(_rest)),)
SRC_P= aux/lua
INCLUDES:= -I$(SRC_P) -Iinclude -I$(AUX_P)
CLUA_MODS+= $(foreach m, $(VENDOR_C), $m.a)
CLUA_MODS+= $(foreach m, $(APP_C), $m.a)
LUA_MODS+= $(foreach m, $(VENDOR_LUA), $m.lua)
LUA_MODS+= $(foreach m, $(APP_LUA), $m.lua)
BUILD_DEPS= has-$(CC) has-$(RANLIB) has-$(LD) has-$(AR) has-$(STRIP) has-$(RM) has-$(CP)
