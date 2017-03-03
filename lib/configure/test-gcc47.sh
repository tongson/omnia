#!/bin/sh
C=idCC-$$.c

cat >$C <<_EOF
#if __GNUC__ >= 5
true
#endif
#if __GNUC__ == 4
#  if __GNUC_MINOR__ >= 7
true
#  endif
#endif
_EOF
$1 -E $C | tail -n1
rm -f $C

