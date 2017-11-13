#!/bin/sed -nf
N
s/\n/:/
:repeat
/Manager/s/^/*/
/\*\*\*/!t repeat
