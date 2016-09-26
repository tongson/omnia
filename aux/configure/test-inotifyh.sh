#!/bin/sh
C=test-inotifyh-$$.c

cat >$C <<_EOF
#include <sys/inotify.h>
_EOF
if $1 -Werror -o test-inotifyh.o -c $C 2>/dev/null; then
  echo true
fi
rm -f test-inotifyh.o $C
