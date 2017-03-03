#!/bin/sh
C=test-netlinkh-$$.c

cat >$C <<_EOF
#include <linux/netlink.h>
_EOF
if $1 -Werror -o test-netlinkh.o -c $C 2>/dev/null; then
  echo true
fi
rm -f test-netlinkh.o $C
