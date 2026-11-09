;-------------------------------------------------------------------------
; Embedded target System85 by Daniel Riechers
; Based on Micro8085 by Anders Hjelm
; https://hackaday.io/project/176653-micro8085
; for target clib support see /z88dk/examples/micro8085/micro8085.h
;-------------------------------------------------------------------------
        module micro8085_crt0

;-------------------------------------------------------------------------
; Include zcc_opt.def to find out some info
;-------------------------------------------------------------------------
        defc    crt0 = 1
        INCLUDE "zcc_opt.def"
; TODO ifdefs for rom vs ram programs
;-------------------------------------------------------------------------
; Some scope definitions
;-------------------------------------------------------------------------
        EXTERN    _main           ;main() is always external to crt0 code

        PUBLIC    __Exit         ;jp'd to by exit()
        PUBLIC    l_dcal          ;jp(hl)
        
        PUBLIC    _urxbuf
        PUBLIC    _putidx
        PUBLIC    _getidx
        PUBLIC    _get_msec
        PUBLIC    _led_on
        PUBLIC    _led_off

        PUBLIC    puart_tbr
        PUBLIC    puart_usr
;        PUBLIC    pspiclk
;        PUBLIC    pselect
;        PUBLIC    padc1
;        PUBLIC    padc2

;        PUBLIC    uenabl
;        PUBLIC    udtr
;        PUBLIC    urts

;        PUBLIC    eepgsz
        PUBLIC    CPU_CLK_kHz

;-------------------------------------------------------------------------
; *** IO PORT MAP AND RELATED DEFINES FOR SYSTEM85 ***
piocmd    equ  00H
pioa      equ  01H
piob      equ  02H
pioc      equ  03H
ptiml     equ  04H
ptimh     equ  05H

puart_tbr  equ  80H
puart_ucr  equ  81H
puart_mcr  equ  82H ; R/W
puart_brsr equ  83H

puart_rbr  equ  80H
puart_usr  equ  81H
puart_msr  equ  83H

;pspiclk equ  20H    ;DUMMY WRITE TO GENERATE CLOCK
;pselect equ  30H    ;TWO BIT OUTPUT REGISTER
;padc1   equ  40H    ;ADC CONV.TIME 140 MICROSEC FROM
;padc2   equ  50H    ;OUT(WRITE/START) TO IN(READ)
;pdac    equ  60H

; *** 82c52 UART COMMANDS ETC ***
ucr_init  equ 3EH ;00111110b 00 = reserved, 11 = 8 DATA, 11x = 1 parity none, 0 = 1 stop bit
mcr_init  equ 20H ;00100100b 0 = must, 0 modem int disabled, 1 rx enable, 00 normal mode, 1 int en, 00 DTR RTS high
; TODO 24h to use intr. I have to have USR DR check even when using DR signal so .... why not use INTR?
; XTAL is 1.8432 MHz prescale 3 divisor 4 give 9600 baud
brsr_init equ 85H ;10000101b 1 = co is baud rate gen 00001 = divisor 4, 01 = prescale 3

; *** SERIAL EEPROM COMMANDS AND SIZE ***
;eepgsz  equ  64     ;IMPLEMENTATION ALLOWS MAX PAGE SIZE 256 BYTE
;eesize  equ  32768  ;IMPLEMENTATION ALLOWS MAX SIZE 65536 - PAGE SIZE

;-------------------------------------------------------------------------
        defc    CRT_ORG_CODE = 0x0000
        defc    CRT_ORG_DATA = 0x8000
        defc    CRT_ORG_BSS  = 0x8000

;------ place uart rx buff at top of ram align to 256 byte boundary ------
;------ locate get & put index together for single 16bit r/w access ------
        defc    _urxbuf   = 0xFF00
        defc    _putidx   = (_urxbuf-1)
        defc    _getidx   = (_urxbuf-2)
        defc    _mstick   = (_urxbuf-4)
        defc    _scrtchpd = (_urxbuf-16)

;------ below rx buffer and some additional data we place the stack ------
        defc    REGISTER_SP = _scrtchpd
        defc    CLIB_EXIT_STACK_SIZE = 0
        defc    __CPU_CLOCK = 6144000
        defc    CPU_CLK_kHz = 6144

;------ overide default definition clib_fopn_max = 10 in crt_rules ------
        defc    DEFINED_CLIB_FOPEN_MAX = 1
        defc    CLIB_FOPEN_MAX = 3
        INCLUDE "crt/classic/crt_rules.inc"

;-------------------------------------------------------------------------
        org     CRT_ORG_CODE
rst0:   ld      sp,__register_sp
        jp      program         ;RST0 standard entry 
        defs    $08-ASMPC

rst1:   ret                     ;RST1 not used
        defs    $10-ASMPC

rst2:   ret                     ;RST2 not used
        defs    $18-ASMPC

rst3:   ret                     ;RST3 not used
        defs    $20-ASMPC

rst4:   ret                     ;RST4 not used
        defs    $24-ASMPC

trap:   ret                     ;TRAP not used
        defs    $28-ASMPC

rst5:   ret                     ;RST5 not used
        defs    $2C-ASMPC

rst55:  ret                     ;RST5.5 not used
        defs    $30-ASMPC

rst6:   ret                     ;RST6 not used
        defs    $34-ASMPC

rst65:  di                      ;RST6.5 uart rx isr
        jp      intr65          ;jmp to interrupt code
        defs    $38-ASMPC

rst7:   ret                     ;RST7 not used
        defs    $3C-ASMPC

rst75:  di                      ;RST7.5 timer isr
        push    af
        push    hl 
        lhld    _mstick         ;millisec count location
        inc     hl              ;increment milliseconds
        shld    _mstick         ;back to its location
        ld      a,10H           ;reset rst7.5 f/f
        sim
        pop     hl 
        pop     af 
        ei
        ret

intr65: push    af
        push    hl
;	ld      a, 0C0h
;       sim
        ld      a,(_putidx)     ;get the buffer put index
        ld      l,a             ;prepare for memory access
        ld      h,_urxbuf/256   ;msb of buffer address
	in	a,(puart_usr)	; TODO move up and maybe try INTR and not DR again
	and	80h		; Make sure there is data ready
	jz	i_skip
        in      a,(puart_rbr)   ;get the char from uart
;        out     (puart_tbr),a   ;WRITE IT TO 8252 echo back for debug
        ld      (hl),a          ;poke it to buffer
        inc     l               ;bump buf put index
        ld      a,(_getidx)     ;peek the get index
        cp      l               ;compare with put
        jp      z,i_skip        ;put==get means buffer full
        ld      a,l             ;updated put index to a
        ld      (_putidx),a     ;and store it
i_skip: pop     hl
        pop     af
;	ld      a, 40h
;        sim
        ei
        ret

;-------------------------------------------------------------------------
; extern uint16 get_msec(void)  ;returns the millisec tick value
_get_msec:
        di
        lhld    _mstick         ;millisec count location
        ei
        ret

_led_on:
	push	af
	ld	a, 0C0h
	sim
	pop	af
	ret

_led_off:
	ld	a, 40h
	sim
	ret

;-------------------------------------------------------------------------
program:
        call    target_init
        call    crt0_init
        INCLUDE "crt/classic/crt_init_heap.inc"

        call    _main           ;void main(void) so no args or retval

__Exit:
        call    crt0_exit
        jp      rst0            ;restart if main should return

l_dcal:  jp     (hl)            ;Used for function pointer calls

;-------------------------------------------------------------------------
target_init:
        ld      hl,0
        shld    _getidx         ;RESET PUT & GET INDEXES
        shld    _mstick         ;RESET MILLISEC COUNT
;        ld      a,80H
;        out     (pdac),a        ;PUT OUT HALF VCC ON DAC
;        sub     a               ;RESET A
;        out     (pselect),a     ;RESET D F/F select LINES
;8252_uart
        ld      a,ucr_init      ;UART configuration
        out     (puart_ucr),a   ;WRITE IT TO 8252
        ld      a,brsr_init     ;Baud Generator configuration
        out     (puart_brsr),a  ;WRITE IT TO 8252
        ld      a,mcr_init      ;Modem Configuratoin and enable
        out     (puart_mcr),a   ;WRITE IT TO 8252
;8155_timer
        ld      hl,CPU_CLK_kHz
        sra     hl              ;DIV BY 2 TO GET TIMER COUNT
        ld      a,l             ;LOW BYTE OF COUNT
        out     (ptiml),a       ;SEND TO TIMER LOW REGISTER
        ld      a,h             ;COUNTER IN 8155 IS 14 BIT
        and     3FH             ;MAKE SURE BITS 6,7 ARE ZERO
        or      40H             ;SET MODE CONT. SQUARE WAVE
        out     (ptimh),a       ;SEND TO TIMER HI REGISTER
        ld      a,0C0H          ;START TIMER COMMAND
        out     (piocmd),a      ;SEND TO 8155 CONFIG REG
;8085_interrupt
	ld      a,1Dh
        ;ld      a,19H           ;RST F/F & ENABLE 7.5 & 6.5
        sim                     ;SET THE NEW MASK
        ei                      ;ENABLE INTERRUPT
        ret

;-------------------------------------------------------------------------
        defc    __crt_org_bss = CRT_ORG_BSS
        defc    __crt_model = 1

        INCLUDE "crt/classic/crt_runtime_selection.inc" 
        INCLUDE "crt/classic/crt_section.inc"

;-------------------------------------------------------------------------
