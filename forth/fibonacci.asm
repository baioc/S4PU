( S4PU-Forth Stack Fibonacci )

( jump to main routine )
branch
main


( x1 x2 -- x1 x2 x1 )
$over:	lit
				1
				pick
				exit

( x1 x2 -- x1 x2 x1 x2 )
$2dup:	over
				over
				exit

( f[n-2] f[n-1] -- f[n-2] f[n-1] f[n] )
nop
$fibonacci:	2dup
						+
						exit


$main:		lit
					0		( stdout )
					>R

					lit
					0
					dup
					R>
					dup
					1+
					>R
					!

					lit
					1
					dup
					R>
					dup
					1+
					>R
					!

	( until stack overflow )
	$loop:	fibonacci
					dup
					R>
					dup
					1+
					>R
					!

					branch
					loop
