; Test program to look for memory issue started from TomNisbet rom serial test
; Test program to bit-bang a single character out SOD as serial async data
; assemble with: asm85 -b0000:00ff test3-rom-serial.asm
;
; This program does not use any RAM or stack instructions, so it can be run
; from a ROM-only system.
;
; The BITTIME is calculated for a 6.144MHz processor clock.

        org     00000H

BITTIME equ     0113H           ; 6.144 time delay for a single bit
;BITTIME equ     0112H           ; 6.000 time delay for a single bit
OUTBITS equ	    11              ; Serial bits to send (start, 8 data, 2 stop)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;   COUT 
; Args
;    C - the char to print
; Clobbers
;    A, F, B, H, L
;;;;;;;;;;;;;;;;;;;;;;;;;;
COUT macro
        di
        mvi     b,OUTBITS       ; Number of output bits
        xra     a               ; Clear carry for start bit
CO1:
        mvi     a,080H          ; Set the SDE flag
        rar                     ; Shift carry into SOD flag
        cmc                     ;   and invert carry.  Why? (serial is inverted?)
        sim                     ; Output data bit
        lxi     h,BITTIME       ; Load the time delay for one bit width
CO2:
        dcr     l               ; Wait for bit time
        jnz     CO2
        dcr     h
        jnz     CO2
        stc                     ; Shift in stop bit(s)
        mov     a,c             ; Get char to send
        rar                     ; LSB into carry
        mov     c,a             ; Store rotated data
        dcr     b
        jnz     CO1             ; Send next bit
        ei

	lxi     h,0100h
CHILL:
        dcr     l
        jnz     CHILL
        dcr     h
        jnz     CHILL

        endm

START:
        ; Anounce Test Start
        mvi c, '\r'
	COUT
        mvi c, '\r'
	COUT
        mvi c, 'S'
	COUT
        mvi c, 't'
	COUT
        mvi c, 'a'
	COUT
        mvi c, 'r'
	COUT
        mvi c, 't'
	COUT
        mvi c, '\r'
	COUT
        mvi c, '\n'
	COUT

        lxi h, 8000h           ; SRAM start
        mvi a, 055h
        mvi b, 055h

	mvi d, 0h
	mvi e, 1h              ; used to incriment and check hl for overflow 0h
TEST_B:
	mov m, a
	mov a, m
	cmp b
	jnz FAULT
	dad d                  ; I'll settle for dad d since i dont have dadi
	jc PASS                ; Overflow indicates we tested every byte
	jmp TEST_B

PASS:                          ; We shouldnt hit this. We should fault at 0x8800 end of SRAM
        mvi c, 'P'
	COUT
        mvi c, 'a'
	COUT
        mvi c, 's'
	COUT
        mvi c, 's'
	COUT
	HLT


;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Fault - Print fault message and halt
; Args
;    Hl - Faulty Address aka addr
; Clobbers
;    Everything
;;;;;;;;;;;;;;;;;;;;;;;;;;

FAULT:
        xchg                   ; Put addr in DE

                               ; Print Failure Message
        mvi c, 'F'
	COUT
        mvi c, 'a'
	COUT
        mvi c, 69h ; 'i' - Nice!
	COUT
        mvi c, 'l'
	COUT
        mvi c, ' '
	COUT

	mov a,d                ; Do (addr_high >> 4) & 0xf -> a
	rrc
	rrc
	rrc
	rrc
	ani 0fh
	mvi b,0
	mov c,a                ; BC is now the nibble value
        lxi h, NIBS            ; Point HL to ASCII table for nibbles
	dad b                  ; Add nibble value to HL
	mov c,m                ; Load nibble ascii value
	COUT                   ; Print nibble

	mov a,d                ; Do addr_high & 0xf -> a
	ani 0fh
	mvi b,0
	mov c,a                ; BC is now the nibble value
        lxi h, NIBS            ; Point HL to ASCII table for nibbles
	dad b                  ; Add nibble value to HL
	mov c,m                ; Load nibble ascii value
	COUT                   ; Print nibble

	mov a,e                ; Do (addr_low >> 4) & 0xf -> a
	rrc
	rrc
	rrc
	rrc
	ani 0fh
	mvi b,0
	mov c,a                ; BC is now the nibble value
        lxi h, NIBS            ; Point HL to ASCII table for nibbles
	dad b                  ; Add nibble value to HL
	mov c,m                ; Load nibble ascii value
	COUT                   ; Print nibble

	mov a,e                ; Do addr_low & 0xf -> a
	ani 0fh
	mvi b,0
	mov c,a                ; BC is now the nibble value
        lxi h, NIBS            ; Point HL to ASCII table for nibbles
	dad b                  ; Add nibble value to HL
	mov c,m                ; Load nibble ascii value
	COUT                   ; Print nibble

        mvi c, 'h'
	COUT
        mvi c, '\r'
	COUT
        mvi c, '\n'
	COUT

	HLT



NIBS:
	DB '0'
	DB '1'
	DB '2'
	DB '3'
	DB '4'
	DB '5'
	DB '6'
	DB '7'
	DB '8'
	DB '9'
	DB 'a'
	DB 'b'
	DB 'c'
	DB 'd'
	DB 'e'
	DB 'f'
