	    org 0000h

DLYTIM  equ 0ffffh      ; Delay loop for LED on and off times
TICKDIV equ 080h        ; How many ticks until LED is turned on

START:
	lxi sp, 0fff8h

	mvi c, TICKDIV    ; initial value of tick divider

	; Configure time to max val which is 188 hz square wave on scope
        mvi a, 0ffh
	out 04h        ; LSB
        mvi a, 07fh
	out 05h        ; MSB and Mode
        mvi a, 0ffh
	out 00h        ; Control and Status

BLINK_OFF:
	lxi h, DLYTIM	; pause
DELAY1:
        dcr l
		jnz DELAY1
        dcr h
        jnz DELAY1

        mvi a, 4bh	    ; turn led off, reset and unmask 7.5
        sim
	ei

halt:
	hlt
	; Return from RST7_5
	jnz halt            ; Still off per dcr in RST7_5
	jmp BLINK_OFF





	    org 003ch
RST7_5:
	dcr c
	jnz exit
        ; Tick divider reached zero
	mvi c, TICKDIV
        mvi a, 0dbh     ; turn led on, reset and unmask 7.5
        sim
exit:
	ei
	ret
