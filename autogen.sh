#!/bin/sh
# Run this to generate all the initial makefiles, etc.

intltoolize --force
aclocal
automake --add-missing --copy --foreign
autoconf
./configure $@
