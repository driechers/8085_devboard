PUBLIC _halt
PUBLIC _led_on

SDO_HIGH equ  0dbH

_halt:
	hlt
	ret

_led_on:
	ld a, SDO_HIGH
	sim
	ret
