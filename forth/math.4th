( FORTH MATH )


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
	ELSE
		1- DUP 1-
		FIB SWAP FIB +
	THEN
;
