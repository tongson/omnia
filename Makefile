.POSIX:
.SUFFIXES:
EXE= bin/main
MAIN= bin/main.lua
VENDOR_C= luaposix linotify lpeg lsocket
VENDOR_LUA= re
LIB=
MAKEFLAGS= --silent
CC= cc
LD= ld
RANLIB= ranlib
AR= ar
LUAC= bin/luac
CCWARN= -Wall
CCOPT= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common

all: bootstrap deps lua sections exe

luaDEFINES:= -DLUA_COMPAT_BITLIB -DLUA_USE_POSIX
DLDFLAGS:= -Wl,-E -lm -lcrypt -lrt $(LDFLAGS)

include aux/tests.mk
include aux/flags.mk
include vendor/libelf/Makefile
include vendor/luawrapper/Makefile
include aux/std.mk
ifneq ($(LIB),)
  include $(eval _d:=lib/$(LIB) $(_d)) $(call _lget,$(LIB))
endif
ifneq ($(VENDOR_C),)
  include $(eval _d:=vendor/$(VENDOR_C) $(_d)) $(call _vget,$(VENDOR_C))
endif
include aux/rules.mk
