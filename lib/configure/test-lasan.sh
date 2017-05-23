#!/bin/sh
C=idCC-$$.c

cat >$C <<_EOF
int main(){}
_EOF
$1 -lasan $C -o $$.out 2>&-
echo $?
rm -f $C $$.out

