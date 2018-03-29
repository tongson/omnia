.POSIX:
.SUFFIXES:
NULSTRING:=
CONFIGURE_P:= lib/configure
INCLUDES_P:= -Ilib/lua
ifeq ($(CROSS),)
  CROSS:= $(NULSTRING)
endif
ifeq ($(CROSS_CC),)
  CROSS_CC:= $(HOST_CC)
endif
LD= ld
NM= nm
AR= ar
RANLIB= ranlib
STRIP= strip
CC= $(CROSS_CC)
TARGET_DYNCC:= $(CROSS)$(CC) -fPIC
TARGET_STCC:= $(CROSS)$(CC)
TARGET_LD= $(CROSS)$(LD)
TARGET_RANLIB= $(CROSS)$(RANLIB)
TARGET_AR= $(CROSS)$(AR)
TARGET_NM= $(CROSS)$(NM)
TARGET_STRIP= $(CROSS)$(STRIP)

# FLAGS when cross compiling
ifneq (,$(CROSS))
  TARGET_CCOPT:= -Os -fomit-frame-pointer -pipe
  TARGET_LDFLAGS= -Wl,--gc-sections -Wl,--strip-all
endif

# Append -static-libgcc to CFLAGS if GCC is detected.
IS_CC:= $(shell $(CONFIGURE_P)/test-cc.sh $(TARGET_STCC))
ifeq ($(IS_CC), GCC)
  TARGET_CFLAGS+= -static-libgcc
endif

ENVIRON_DECLARED:= $(shell $(CONFIGURE_P)/test-environ.sh $(TARGET_STCC))
ifeq ($(ENVIRON_DECLARED), 1)
  luaposixDEFINES+= -DHAVE_EXTERN_ENVIRON_DECLARED
endif

# Replace --gc-sections with -dead-strip on Mac
IS_APPLE:= $(shell $(CONFIGURE_P)/test-mac.sh $(TARGET_STCC))
ifeq ($(IS_APPLE), APPLE)
  LDFLAGS:= -Wl,-dead_strip
  TARGET_LDFLAGS:= -Wl,-dead_strip
  TARGET_DYNCC+= -undefined dynamic_lookup
  luaposixDEFINES+= -D_DARWIN_C_SOURCE
else
  LUAT_FLAGS:= -ldl -Wl,-E
endif

# luaposix needs to link to lrt < glibc 2.17
FOUND_RT:= $(shell $(CONFIGURE_P)/test-lrt.sh $(TARGET_STCC))
ifeq ($(FOUND_RT), 0)
  CFLAGS_LRT= -lrt
endif

# Test for GCC LTO capability.
ifneq (,$(findstring enable-lto,$(shell $(TARGET_STCC) -v 2>&1)))
  ifeq ($(shell $(CONFIGURE_P)/test-gcc47.sh $(TARGET_STCC)), true)
    ifeq ($(shell $(CONFIGURE_P)/test-binutils-plugins.sh $(CROSS)$(AR)), true)
      TARGET_CFLAGS+= -fwhole-program -flto -fuse-linker-plugin
      TARGET_LDFLAGS+= -fwhole-program -flto
      TARGET_RANLIB:= $(CROSS)gcc-$(RANLIB)
      TARGET_AR:= $(CROSS)gcc-$(AR)
      TARGET_NM:= $(CROSS)gcc-$(NM)
    endif
  endif
endif



ifeq ($(filter posix,$(VENDOR_C)), posix)
  HAVE_LINUX_NETLINK_H:= $(shell $(CONFIGURE_P)/test-netlinkh.sh $(TARGET_STCC))
  HAVE_POSIX_FADVISE:= $(shell $(CONFIGURE_P)/test-posix_fadvise.sh $(TARGET_STCC))
endif
ifeq ($(filter px,$(VENDOR_C)), px)
  HAVE_FCNTL_CLOSEM:= $(shell $(CONFIGURE_P)/test-F_CLOSEM.sh $(TARGET_STCC))
endif
ifeq ($(filter inotify,$(VENDOR_C)), inotify)
  HAVE_SYS_INOTIFY_H:= $(shell $(CONFIGURE_P)/test-inotifyh.sh $(TARGET_STCC))
endif

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

## lpeg
ifeq ($(DEBUG), 1)
  lpegDEFINES= -DLPEG_DEBUG
endif

## px
ifeq ($(HAVE_FCNTL_CLOSEM), true)
  pxDEFINES+= -DHAVE_FCNTL_CLOSEM
endif

ifeq ($(or $(MAKECMDGOALS),$(.DEFAULT_GOAL)), development)
  CCWARN:= -Wall -Wextra -Wredundant-decls -Wshadow -Wpointer-arith -Werror -Wfatal-errors
  TARGET_CFLAGS:= -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -O1 -fno-omit-frame-pointer -ggdb
  CFLAGS:= -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -O1 -fno-omit-frame-pointer -ggdb
  FOUND_ASAN:= $(shell $(CONFIGURE_P)/test-lasan.sh $(TARGET_STCC))
  ifeq ($(FOUND_ASAN), 0)
	CFLAGS+= -fsanitize=address
  endif
  FOUND_UBSAN:= $(shell $(CONFIGURE_P)/test-lubsan.sh $(TARGET_STCC))
  ifeq ($(FOUND_UBSAN), 0)
	CFLAGS+= -fsanitize=undefined
  endif
  TARGET_CCOPT:= $(NULSTRING)
  FOUND_LSAN:= $(shell $(CONFIGURE_P)/test-lsan.sh $(TARGET_STCC))
  ifeq ($(FOUND_LSAN), 0)
	CFLAGS+= -fsanitize=leak
  endif
  CCOPT:= $(NULSTRING)
  TARGET_LDFLAGS:= $(NULSTRING)
  LDFLAGS:= $(NULSTRING)
else
  DEFINES+= -DNDEBUG
endif

ifeq ($(STATIC), 1)
  PIE:= $(NULSTRING)
  TARGET_LDFLAGS+= -static
else
  ifneq ($(IS_CC), CLANG)
    PIE:= -fPIE -pie
  else
    PIE:= -fPIE -Wl,-pie
  endif
endif

TARGET_FLAGS:= $(DEFINES) $(INCLUDES_P) $(TARGET_CFLAGS) $(TARGET_CCOPT) $(CCWARN) $(CFLAGS_LRT)
FLAGS:= $(DEFINES) $(INCLUDES_P) $(CFLAGS) $(CCOPT) $(CCWARN)
