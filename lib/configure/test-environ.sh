#!/bin/sh
C=idCC-$$.c

cat >$C <<_EOF
int main(){}
#define _GNU_SOURCE
#include <unistd.h>
int
main(int c, char **v)
{
char **t = environ;
}
_EOF
$1 $C -o $$.out 2>&-
echo $?
rm -f $C $$.out

