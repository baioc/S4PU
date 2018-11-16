
#include <stdio.h>
#include <inttypes.h>

#include "system.h"


const int LIMIT = 24;


int main(void) {
	int n;
	volatile uint16_t *s4pu = (uint16_t*) S4PU_CPU_BASE;
	volatile uint16_t *led = (uint16_t*) PIO_LED_BASE;

	// read shared memory sequentially
	for (n = 0; n <= LIMIT; ++n) {

		uint16_t word = *(s4pu + n);

		if (0 == n || 0 != word) {

			printf("fib(%d) = %d\n", n, word);
			*led = word;
		}

	}

	// daemon
	while (1);

	return 0;
}
