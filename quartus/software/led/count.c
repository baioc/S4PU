
#include "system.h"
#include "io.h"

#include <stdio.h>
#include <unistd.h>


int main(void) {
	printf("Hello, NiosII World.\n");

	unsigned short k = 0;

	while (1) {
		IOWR_16DIRECT(LED_PIO_BASE, 0, k);
		usleep(1000000);
		++k;
	}

	return 0;
}
