#!/bin/sed -nf
h;n;H;x
s/\n/:/
/Manager/!b label
s/^/*/
:label
p
