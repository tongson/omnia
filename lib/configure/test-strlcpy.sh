#!/bin/sh
C=test-strlcpy-$$.c

cat >$C <<_EOF
#include <string.h>

int
main(int argc, char **argv)
{
        strlcpy(argv[0], argv[1], 10);
        return 0;
}
_EOF
if $1 -Werror -o test-strlcpy $C 2>/dev/null; then
  echo true
fi
rm -f test-strlcpy $C
