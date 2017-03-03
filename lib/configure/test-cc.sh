#!/bin/sh
C=idCC-$$.c

cat >$C <<_EOF
#ifdef __GNUC__
#  ifdef __clang__
CLANG
#else
GCC
#  endif
#endif
_EOF
$1 -E $C | tail -n1
rm -f $C

