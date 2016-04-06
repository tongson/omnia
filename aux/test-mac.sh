#!/bin/sh
$1 -dM -E -x c /dev/null | grep __APPLE__ | cut -f 2 -d ' '
