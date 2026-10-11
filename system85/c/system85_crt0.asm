;-------------------------------------------------------------------------
; Embedded target Micro8085 by Anders Hjelm
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
        
        PUBLIC    _get_msec

        PUBLIC    CPU_CLK_kHz

;-------------------------------------------------------------------------
; *** IO PORT MAP AND RELATED DEFINES FOR MICRO8085 ***
piocmd  equ  00H
pioa    equ  01H
piob    equ  02H
pioc    equ  03H
ptiml   equ  04H
ptimh   equ  05H

;-------------------------------------------------------------------------
        defc    CRT_ORG_CODE = 0x0000
        defc    CRT_ORG_DATA = 0x8000
        defc    CRT_ORG_BSS  = 0x8000

;-------------------------------------------------------------------------
        defc    _mstick   = 0xFF00

;------ below rx buffer and some additional data we place the stack ------
        ;defc    REGISTER_SP = _scrtchpd
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

; TODO change org for each vector and delete unused
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

intr65: ei
	ret

;-------------------------------------------------------------------------
; extern uint16 get_msec(void)  ;returns the millisec tick value
_get_msec:
        di
        lhld    _mstick         ;millisec count location
        ei
        ret

;-------------------------------------------------------------------------
program:
        call    target_init
        call    crt0_init
        INCLUDE "crt/classic/crt_init_heap.inc"

        call    _main           ;void main(void) so no args or retval

__Exit:
        call    crt0_exit
        ;jp      rst0            ;restart if main should return
	rst 0;

l_dcal:  jp     (hl)            ;Used for function pointer calls

;-------------------------------------------------------------------------
target_init:
        ld      hl,0
        shld    _mstick         ;RESET MILLISEC COUNT
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
; TODO mask 6.5
;        ld      a,19H           ;RST F/F & ENABLE 7.5 & 6.5
;        sim                     ;SET THE NEW MASK
;        ei                      ;ENABLE INTERRUPT
        ret

;-------------------------------------------------------------------------
        defc    __crt_org_bss = CRT_ORG_BSS
        defc    __crt_model = 1

        ;INCLUDE "crt/classic/crt_runtime_selection.inc" 
        INCLUDE "crt/classic/crt_section.inc"

;-------------------------------------------------------------------------
