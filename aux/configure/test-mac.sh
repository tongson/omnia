#!/bin/sh
C=idCC-$$.c

cat >$C <<_EOF
#ifdef __APPLE__
APPLE
#endif
_EOF
$1 -E $C | tail -n1
rm -f $C
