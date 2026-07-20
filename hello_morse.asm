; foo
; assemble with: asm85 -b0000:00ff hello_morse.asm

	    org 0000h
START:
	LXI SP, 9000H
FOREVER:
        CALL DIT
        CALL DIT
        CALL DIT
        CALL DIT
        CALL LSPACE
        CALL DIT
        CALL LSPACE
        CALL DIT
        CALL DAH
        CALL DIT
        CALL DIT
        CALL LSPACE
        CALL DIT
        CALL DAH
        CALL DIT
        CALL DIT
        CALL LSPACE
        CALL DAH
        CALL DAH
        CALL DAH
        CALL WSPACE

        CALL DIT
        CALL DAH
        CALL DAH
        CALL LSPACE
        CALL DAH
        CALL DAH
        CALL DAH
        CALL LSPACE
        CALL DIT
        CALL DAH
        CALL DIT
        CALL LSPACE
        CALL DIT
        CALL DAH
        CALL DIT
        CALL DIT
        CALL LSPACE
        CALL DAH
        CALL DIT
        CALL DIT
        CALL WSPACE

        CALL WSPACE
        
        JMP FOREVER




SLEEP:
        MOV B, A           ; Outer loop counter
DELAY_OUTER:
        MVI C, 0FFH       ; Inner loop counter
DELAY_INNER:
        DCR C
        JNZ DELAY_INNER
        DCR B
        JNZ DELAY_OUTER
        RET

LSPACE:
        MVI A, 07FH
        CALL SLEEP
        RET

WSPACE:
        MVI A, 0FFH
        CALL SLEEP
        MVI A, 0FFH
        CALL SLEEP
        MVI A, 0FFH
        CALL SLEEP
        MVI A, 0FFH
        CALL SLEEP
        MVI A, 0FFH
        CALL SLEEP
        RET

DIT:
        mvi a, 0c0h     ; turn led on
        sim
        
        MVI A, 03FH
        CALL SLEEP
        
        mvi a, 40h	    ; turn led off
        sim
        
        MVI A, 03FH
        CALL SLEEP
        RET

DAH:
        mvi a, 0c0h     ; turn led on
        sim
        
        MVI A, 0FFH
        CALL SLEEP
        
        mvi a, 40h	    ; turn led off
        sim
        
        MVI A, 03FH
        CALL SLEEP
        RET
