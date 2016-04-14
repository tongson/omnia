NULSTRING:=
CFLAGS_LRT= -lrt

# FLAGS when compiling for an OpenWRT target.
ifneq (,$(findstring openwrt,$(CC)))
  CCOPT:= -Os -fomit-frame-pointer -pipe
  LDFLAGS= -Wl,--gc-sections -Wl,--strip-all
  DEFINES+= -DHAVE_UCLIBC
endif

# Append -static-libgcc to CFLAGS if GCC is detected.
ifeq ($(shell aux/test-cc.sh $(CC)), GCC)
  CFLAGS+= -static-libgcc
endif

# Replace --gc-sections with -dead-strip on Mac
ifeq ($(shell aux/test-mac.sh $(CC)), APPLE)
  LDFLAGS:= -Wl,-dead_strip
  CFLAGS_LRT:= $(NULSTRING)
endif

# Test for GCC LTO capability.
ifeq ($(shell aux/test-gcc47.sh $(CC)), GCC47)
  ifeq ($(shell aux/test-binutils-plugins.sh gcc-ar), true)
    CFLAGS+= -fwhole-program -flto -fuse-linker-plugin
    LDFLAGS+= -fwhole-program -flto
    RANLIB:= gcc-ranlib
    AR:= gcc-ar
  endif
endif

### Lua Module specific defines ###

## luaposix
ifeq ($(shell aux/test-netlinkh.sh $(CC)), true)
  luaposixDEFINES+= -DHAVE_LINUX_NETLINK_H
endif
ifeq ($(shell aux/test-posix_fadvise.sh $(CC)), true)
  luaposixDEFINES+= -DHAVE_POSIX_FADVISE
endif
ifeq ($(shell aux/test-strlcpy.sh $(CC)), true)
  luaposixDEFINES+= -DHAVE_STRLCPY
endif

## lpeg
ifeq ($(DEBUG), 1)
  lpegDEFINES= -DLPEG_DEBUG
endif

## px
ifeq ($(shell aux/test-F_CLOSEM.sh $(CC)), true)
  pxDEFINES+= -DHAVE_FCNTL_CLOSEM
endif

ifeq ($(DEBUG), 1)
  CFLAGS:= -O1 -fno-omit-frame-pointer -g
  CCOPT:= $(NULSTRING)
  LDFLAGS:= $(NULSTRING)
  MAKEFLAGS:= $(NULSTRING)
else
  DEFINES+= -DNDEBUG
endif

ifeq ($(STATIC), 1)
  LDFLAGS+= -static
endif

ifeq ($(ASAN), 1)
  CFLAGS:= -fsanitize=address -O1 -fno-omit-frame-pointer -g
  CCOPT:= $(NULSTRING)
  LDFLAGS:= $(NULSTRING)
endif
