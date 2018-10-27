( FORTH UTILITIES )


: OVER	( x1 x2 -- x1 x2 x1 )
	1 PICK
;

: 2DUP	( x1 x2 -- x1 x2 x1 x2 )
	OVER OVER
;

: 2DROP	( x1 x2 -- )
	DROP DROP
;

: EMIT	( s -- )
	STDOUT !
;

: KEY	( -- k )
	STDIN @
;
