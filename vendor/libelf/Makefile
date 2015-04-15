libelfA= vendor/libelf/libelf.a
formatH= vendor/libelf/native-elf-format.h
fsizeSRC= vendor/libelf/libelf_fsize.c
msizeSRC= vendor/libelf/libelf_msize.c
convertSRC= vendor/libelf/libelf_convert.c
libelfSRCS=	vendor/libelf/elf.c							\
vendor/libelf/elf_begin.c						\
vendor/libelf/elf_cntl.c						\
vendor/libelf/elf_end.c							\
vendor/libelf/elf_errmsg.c		\
vendor/libelf/elf_errno.c			\
vendor/libelf/elf_data.c						\
vendor/libelf/elf_fill.c						\
vendor/libelf/elf_flag.c						\
vendor/libelf/elf_getarhdr.c						\
vendor/libelf/elf_getarsym.c						\
vendor/libelf/elf_getbase.c						\
vendor/libelf/elf_getident.c						\
vendor/libelf/elf_hash.c						\
vendor/libelf/elf_kind.c						\
vendor/libelf/elf_memory.c						\
vendor/libelf/elf_next.c						\
vendor/libelf/elf_open.c						\
vendor/libelf/elf_rand.c						\
vendor/libelf/elf_rawfile.c						\
vendor/libelf/elf_phnum.c						\
vendor/libelf/elf_shnum.c						\
vendor/libelf/elf_shstrndx.c						\
vendor/libelf/elf_scn.c						\
vendor/libelf/elf_strptr.c						\
vendor/libelf/elf_update.c						\
vendor/libelf/elf_version.c						\
vendor/libelf/gelf_cap.c						\
vendor/libelf/gelf_checksum.c						\
vendor/libelf/gelf_dyn.c						\
vendor/libelf/gelf_ehdr.c						\
vendor/libelf/gelf_getclass.c						\
vendor/libelf/gelf_fsize.c						\
vendor/libelf/gelf_move.c						\
vendor/libelf/gelf_phdr.c						\
vendor/libelf/gelf_rel.c						\
vendor/libelf/gelf_rela.c						\
vendor/libelf/gelf_shdr.c						\
vendor/libelf/gelf_sym.c						\
vendor/libelf/gelf_syminfo.c						\
vendor/libelf/gelf_symshndx.c						\
vendor/libelf/gelf_xlate.c						\
vendor/libelf/libelf_align.c						\
vendor/libelf/libelf_allocate.c					\
vendor/libelf/libelf_ar.c						\
vendor/libelf/libelf_ar_util.c					\
vendor/libelf/libelf_checksum.c					\
vendor/libelf/libelf_data.c						\
vendor/libelf/libelf_ehdr.c						\
vendor/libelf/libelf_extended.c					\
vendor/libelf/libelf_memory.c						\
vendor/libelf/libelf_open.c						\
vendor/libelf/libelf_phdr.c						\
vendor/libelf/libelf_shdr.c						\
vendor/libelf/libelf_xlate.c
libelfOBJS=	vendor/libelf/elf.o							\
vendor/libelf/elf_begin.o						\
vendor/libelf/elf_cntl.o						\
vendor/libelf/elf_end.o							\
vendor/libelf/elf_errmsg.o		\
vendor/libelf/elf_errno.o			\
vendor/libelf/elf_data.o						\
vendor/libelf/elf_fill.o						\
vendor/libelf/elf_flag.o						\
vendor/libelf/elf_getarhdr.o						\
vendor/libelf/elf_getarsym.o						\
vendor/libelf/elf_getbase.o						\
vendor/libelf/elf_getident.o						\
vendor/libelf/elf_hash.o						\
vendor/libelf/elf_kind.o						\
vendor/libelf/elf_memory.o						\
vendor/libelf/elf_next.o						\
vendor/libelf/elf_open.o						\
vendor/libelf/elf_rand.o						\
vendor/libelf/elf_rawfile.o						\
vendor/libelf/elf_phnum.o						\
vendor/libelf/elf_shnum.o						\
vendor/libelf/elf_shstrndx.o						\
vendor/libelf/elf_scn.o						\
vendor/libelf/elf_strptr.o						\
vendor/libelf/elf_update.o						\
vendor/libelf/elf_version.o						\
vendor/libelf/gelf_cap.o						\
vendor/libelf/gelf_checksum.o						\
vendor/libelf/gelf_dyn.o						\
vendor/libelf/gelf_ehdr.o						\
vendor/libelf/gelf_getclass.o						\
vendor/libelf/gelf_fsize.o						\
vendor/libelf/gelf_move.o						\
vendor/libelf/gelf_phdr.o						\
vendor/libelf/gelf_rel.o						\
vendor/libelf/gelf_rela.o						\
vendor/libelf/gelf_shdr.o						\
vendor/libelf/gelf_sym.o						\
vendor/libelf/gelf_syminfo.o						\
vendor/libelf/gelf_symshndx.o						\
vendor/libelf/gelf_xlate.o						\
vendor/libelf/libelf_align.o						\
vendor/libelf/libelf_allocate.o					\
vendor/libelf/libelf_ar.o						\
vendor/libelf/libelf_ar_util.o					\
vendor/libelf/libelf_checksum.o					\
vendor/libelf/libelf_data.o						\
vendor/libelf/libelf_ehdr.o						\
vendor/libelf/libelf_extended.o					\
vendor/libelf/libelf_memory.o						\
vendor/libelf/libelf_open.o						\
vendor/libelf/libelf_phdr.o						\
vendor/libelf/libelf_shdr.o						\
vendor/libelf/libelf_xlate.o \
vendor/libelf/libelf_fsize.o \
vendor/libelf/libelf_msize.o \
vendor/libelf/libelf_convert.o

CLEAN+= clean_libelf
CCWARN=

$(libelfA): $(libelfOBJS)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

vendor/libelf/%.o: $(libelfSRCS) $(convertSRC) $(fsizeSRC) $(msizeSRC) $(formatH) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -Ivendor/libelf -Ivendor/libelf/common $(CCWARN) $(CFLAGS) $(CCOPT) -c vendor/libelf/$*.c

clean_libelf:
	$(RM) $(RMFLAGS) $(libelfOBJS) $(libelfA) $(formatH) $(convertSRC) $(fsizeSRC) $(msizeSRC)

$(formatH):
	vendor/libelf/common/native-elf-format > $@

$(convertSRC):
	$(M4) -D SRCDIR=vendor/libelf vendor/libelf/libelf_convert.m4 > $@

$(fsizeSRC):
	$(M4) -D SRCDIR=vendor/libelf vendor/libelf/libelf_fsize.m4 > $@

$(msizeSRC):
	$(M4) -D SRCDIR=vendor/libelf vendor/libelf/libelf_msize.m4 > $@

.PHONY: clean_libelf
