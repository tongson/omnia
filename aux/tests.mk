.POSIX:
.SUFFIXES:
export CC
export NM
NULSTRING:=
CFLAGS_LRT= -lrt
INCLUDES:= -Iaux/lua

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
ifeq ($(shell aux/test-gcc47.sh $(CC)), true)
  ifeq ($(shell aux/test-binutils-plugins.sh gcc-ar), true)
    CFLAGS+= -fwhole-program -flto -fuse-linker-plugin
    LDFLAGS+= -fwhole-program -flto
    RANLIB:= gcc-ranlib
    AR:= gcc-ar
    NM:= gcc-nm
  endif
endif

HAVE_LINUX_NETLINK_H:= $(shell aux/test-netlinkh.sh $(CC))
HAVE_POSIX_FADVISE:= $(shell aux/test-posix_fadvise.sh $(CC))
HAVE_STRLCPY:= $(shell aux/test-strlcpy.sh $(CC))
HAVE_FCNTL_CLOSEM:= $(shell aux/test-F_CLOSEM.sh $(CC))
HAVE_SYS_INOTIFY_H:= $(shell aux/test-inotifyh.sh $(CC))

### Lua Module specific defines and tests ####

## linotify

ifeq ($(filter linotify,$(VENDOR_C)), linotify)
	ifneq ($(HAVE_SYS_INOTIFY_H), true)
    $(error Linotify module requested but Inotify header \(sys/inotify.h\) missing!)
  endif
endif

## luaposix

ifeq ($(HAVE_LINUX_NETLINK_H), true)
  luaposixDEFINES+= -DHAVE_LINUX_NETLINK_H
endif
ifeq ($(HAVE_POSIX_FADVISE), true)
  luaposixDEFINES+= -DHAVE_POSIX_FADVISE
endif
ifeq ($(HAVE_STRLCPY), true)
  luaposixDEFINES+= -DHAVE_STRLCPY
endif

## lpeg
ifeq ($(DEBUG), 1)
  lpegDEFINES= -DLPEG_DEBUG
endif

## px
ifeq ($(HAVE_FCNTL_CLOSEM), true)
  pxDEFINES+= -DHAVE_FCNTL_CLOSEM
endif

ifeq ($(DEBUG), 1)
  CCWARN:= -Wall -Wextra -Wdeclaration-after-statement -Wredundant-decls -Wshadow -Wpointer-arith
  CFLAGS:= -O1 -fno-omit-frame-pointer -g
  CCOPT:= $(NULSTRING)
  LDFLAGS:= $(NULSTRING)
  MAKEFLAGS:= $(NULSTRING)
else
  DEFINES+= -DNDEBUG
endif

ifeq ($(STATIC), 1)
  PIE:= $(NULSTRING)
  LDFLAGS+= -static
else
  PIE:= -fPIE
  LDFLAGS+= -Wl,-pie
endif

ifeq ($(ASAN), 1)
  CFLAGS:= -fsanitize=address -O1 -fno-omit-frame-pointer -g
  CCOPT:= $(NULSTRING)
  LDFLAGS:= $(NULSTRING)
  MAKEFLAGS:= $(NULSTRING)
endif

ACFLAGS:= $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT)
