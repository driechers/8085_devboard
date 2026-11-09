#include <stdio.h>
#include "micro8085.h"

extern void halt(void);
extern void led_on(void);

int main(void)
{
	printf("Started System85\n");
	led_on();

	while(1) {
		printf("mstime = %d\n", get_msec());

		for(unsigned int i=0; i < 0x3fff; i++);
	}
	return 0;
}
