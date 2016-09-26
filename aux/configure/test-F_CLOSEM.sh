#!/bin/sh
C=test-F_CLOSEM-$$.c

cat >$C <<_EOF
#include <limits.h>
#include <fcntl.h>

void
main(int argc, char **argv)
{
    fcntl(3, F_CLOSEM, 0)
}
_EOF
if $1 -Werror -o test-F_CLOSEM $C 2>/dev/null; then
  echo true
fi
rm -f test-F_CLOSEM $C
