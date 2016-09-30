EXE:= test
SRC:= src moon_src
SRC_DIR:= moon
SRC_C:=
VENDOR:= cwtest
VENDOR_DIR:=
VENDOR_C:= lfs
MAKEFLAGS=
HOST_CC= cc
CROSS=i486-openwrt-linux-musl-
CROSS_CC= gcc
CCOPT= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common
luaDEFINES:= -DLUA_COMPAT_BITLIB -DLUA_USE_POSIX
TARGET_CCOPT= $(CCOPT)
TARGET_CFLAGS= $(CFLAGS)
TARGET_LDFLAGS= $(LDFLAGS)
include aux/tests.mk
include aux/std.mk
include aux/rules.mk
