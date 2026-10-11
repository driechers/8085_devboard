extern void halt(void);
extern void led_on(void);

int main(void)
{
	led_on();
	halt();
	return 0;
}
