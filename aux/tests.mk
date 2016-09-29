.POSIX:
.SUFFIXES:
NULSTRING:=
CONFIGURE_P:= aux/configure
CFLAGS_LRT= -lrt
INCLUDES:= -Iaux/lua
ifeq ($(CROSS),)
  CROSS:= $(NULSTRING)
endif
TARGET_CC:= $(CROSS)$(CC)
TARGET_LD= $(CROSS)$(LD)
TARGET_RANLIB= $(CROSS)$(RANLIB)
TARGET_AR= $(CROSS)$(AR)
TARGET_NM= $(CROSS)$(NM)
TARGET_STRIP= $(CROSS)strip

# FLAGS when compiling for an OpenWRT target.
ifneq (,$(findstring openwrt,$(TARGET_CC)))
  TARGET_CCOPT:= -Os -fomit-frame-pointer -pipe
  TARGET_LDFLAGS= -Wl,--gc-sections -Wl,--strip-all
  DEFINES+= -DHAVE_UCLIBC
endif

# Append -static-libgcc to CFLAGS if GCC is detected.
IS_GCC:= $(shell $(CONFIGURE_P)/test-cc.sh $(TARGET_CC))
ifeq ($(IS_GCC), GCC)
  TARGET_CFLAGS+= -static-libgcc
endif

# Replace --gc-sections with -dead-strip on Mac
IS_APPLE:= $(shell $(CONFIGURE_P)/test-mac.sh $(TARGET_CC))
ifeq ($(IS_APPLE), APPLE)
  TARGET_LDFLAGS:= -Wl,-dead_strip
  CFLAGS_LRT:= $(NULSTRING)
endif

# Test for GCC LTO capability.
ifeq ($(shell $(CONFIGURE_P)/test-gcc47.sh $(TARGET_CC)), true)
  ifeq ($(shell $(CONFIGURE_P)/test-binutils-plugins.sh $(CROSS)gcc-ar), true)
    CFLAGS+= -fwhole-program -flto -fuse-linker-plugin
    LDFLAGS+= -fwhole-program -flto
    RANLIB:= $(CROSS)gcc-ranlib
    AR:= $(CROSS)gcc-ar
    NM:= $(CROSS)gcc-nm
  endif
endif

HAVE_LINUX_NETLINK_H:= $(shell $(CONFIGURE_P)/test-netlinkh.sh $(TARGET_CC))
HAVE_POSIX_FADVISE:= $(shell $(CONFIGURE_P)/test-posix_fadvise.sh $(TARGET_CC))
HAVE_STRLCPY:= $(shell $(CONFIGURE_P)/test-strlcpy.sh $(TARGET_CC))
HAVE_FCNTL_CLOSEM:= $(shell $(CONFIGURE_P)/test-F_CLOSEM.sh $(TARGET_CC))
HAVE_SYS_INOTIFY_H:= $(shell $(CONFIGURE_P)/test-inotifyh.sh $(TARGET_CC))

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
  TARGET_CFLAGS:= $(CCWARN) -O1 -fPIC -fno-omit-frame-pointer -g
  TARGET_CCOPT:= $(NULSTRING)
  TARGET_LDFLAGS:= $(NULSTRING)
  MAKEFLAGS:= $(NULSTRING)
else
  DEFINES+= -DNDEBUG
endif

ifeq ($(STATIC), 1)
  PIE:= $(NULSTRING)
  TARGET_LDFLAGS+= -static
else
  PIE:= -fPIE -pie
endif

ifeq ($(ASAN), 1)
  TARGET_CFLAGS:= -fsanitize=address -O1 -fno-omit-frame-pointer -g
  TARGET_CCOPT:= $(NULSTRING)
  TARGET_LDFLAGS:= $(NULSTRING)
  MAKEFLAGS:= $(NULSTRING)
endif

TARGET_FLAGS:= $(DEFINES) $(INCLUDES) $(TARGET_CFLAGS) $(TARGET_CCOPT)
FLAGS:= $(DEFINES) $(INCLUDES) $(CFLAGS) $(CCOPT)
