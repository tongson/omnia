.POSIX:
.SUFFIXES:
EXE= main
MAIN= $(EXE).lua
VENDOR_C= lpeg
VENDOR_LUA= re
LIB=
MAKEFLAGS= --silent
CC= cc
export CC
LD= ld
RANLIB= ranlib
AR= ar
CCWARN= -Wall
CCOPT= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common
luaDEFINES:= -DLUA_COMPAT_BITLIB -DLUA_USE_POSIX
include aux/tests.mk
include aux/flags.mk
include aux/std.mk
ifneq ($(LIB),)
  include $(eval _d:=lib/$(LIB) $(_d)) $(call _lget,$(LIB))
endif
ifneq ($(VENDOR_C),)
  include $(eval _d:=vendor/c/$(VENDOR_C) $(_d)) $(call _vget,$(VENDOR_C))
endif
include aux/rules.mk
