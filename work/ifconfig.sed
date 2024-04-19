#!/usr/bin/sed -f
 
/^[^ ]/{
	s/^([^ ]*) .*/\1/g;
	h;
	: top;
	n;
	/^$/b;
	s/^.*RX bytes:([0-9]{1,}).*/\1/g;
	T top;
	H;
	x;
	s/\n/:/g;
#	p;
	w result
}
