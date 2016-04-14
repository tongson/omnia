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


