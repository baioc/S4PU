(FORTH MATH)


: MIN	( x1 x2 -- min[x1,x2] )
	2DUP
	> IF
		SWAP
	THEN DROP
;

: MAX	( x1 x2 -- max[x1,x2] )
	2DUP
	< IF
		SWAP
	THEN DROP
;

: NEGATE	( n -- -n )
	NOT 1+
;

: ABS	( n -- |n| )
	DUP 0< IF
		NEGATE
	THEN
;

: FIB	( n -- fib[n] )
	DUP 2 < IF
		DROP 1
	ELSE
		DUP 1-
		SWAP 2 -
		FIB SWAP FIB +
	THEN
;
