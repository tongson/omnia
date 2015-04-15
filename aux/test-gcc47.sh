#!/bin/sh
C=idCC-$$.c

cat >$C <<_EOF
#if __GNUC__ == 4
#  if __GNUC_MINOR__ >= 7
GCC47
#  endif
#endif
_EOF
$1 -E $C | tail -n1
rm -f $C

