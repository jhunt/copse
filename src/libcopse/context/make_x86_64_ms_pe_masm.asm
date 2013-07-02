
;           Copyright Oliver Kowalke 2009.
;  Distributed under the Boost Software License, Version 1.0.
;     (See accompanying file LICENSE_1_0.txt or copy at
;           http://www.boost.org/LICENSE_1_0.txt)

;  ----------------------------------------------------------------------------------
;  |    0    |    1    |    2    |    3    |    4     |    5    |    6    |    7    |
;  ----------------------------------------------------------------------------------
;  |   0x0   |   0x4   |   0x8   |   0xc   |   0x10   |   0x14  |   0x18  |   0x1c  |
;  ----------------------------------------------------------------------------------
;  |        R12        |         R13       |         R14        |        R15        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    8    |    9    |   10    |   11    |    12    |    13   |    14   |    15   |
;  ----------------------------------------------------------------------------------
;  |   0x20  |   0x24  |   0x28  |  0x2c   |   0x30   |   0x34  |   0x38  |   0x3c  |
;  ----------------------------------------------------------------------------------
;  |        RDI        |        RSI        |         RBX        |        RBP        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    16   |    17   |    18   |    19   |                                        |
;  ----------------------------------------------------------------------------------
;  |   0x40  |   0x44  |   0x48  |   0x4c  |                                        |
;  ----------------------------------------------------------------------------------
;  |        RSP        |        RIP        |                                        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    20   |    21   |    22   |    23   |    24    |    25   |                   |
;  ----------------------------------------------------------------------------------
;  |   0x50  |   0x54  |   0x58  |   0x5c  |   0x60   |   0x64  |                   |
;  ----------------------------------------------------------------------------------
;  |        sp         |       size        |        limit       |                   |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    26   |   27    |                                                            |
;  ----------------------------------------------------------------------------------
;  |   0x68  |   0x6c  |                                                            |
;  ----------------------------------------------------------------------------------
;  |      fbr_strg     |                                                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    28   |   29    |    30   |    31   |    32    |    33   |   34    |   35    |
;  ----------------------------------------------------------------------------------
;  |   0x70  |   0x74  |   0x78  |   0x7c  |   0x80   |   0x84  |  0x88   |  0x8c   |
;  ----------------------------------------------------------------------------------
;  | fc_mxcsr|fc_x87_cw|      fc_xmm       |      SEE registers (XMM6-XMM15)        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |   36    |    37   |    38   |    39   |    40    |    41   |   42    |   43    |
;  ----------------------------------------------------------------------------------
;  |  0x90   |   0x94  |   0x98  |   0x9c  |   0xa0   |   0xa4  |  0xa8   |  0xac   |
;  ----------------------------------------------------------------------------------
;  |                          SEE registers (XMM6-XMM15)                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    44    |   45    |    46   |    47  |    48    |    49   |   50    |   51    |
;  ----------------------------------------------------------------------------------
;  |   0xb0   |  0xb4   |  0xb8   |  0xbc  |   0xc0   |   0xc4  |  0xc8   |  0xcc   |
;  ----------------------------------------------------------------------------------
;  |                          SEE registers (XMM6-XMM15)                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    52    |   53    |    54   |   55   |    56    |    57   |   58    |   59    |
;  ----------------------------------------------------------------------------------
;  |   0xd0   |  0xd4   |   0xd8  |  0xdc  |   0xe0   |  0xe4   |  0xe8   |  0xec   |
;  ----------------------------------------------------------------------------------
;  |                          SEE registers (XMM6-XMM15)                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    60   |    61   |    62    |    63  |    64    |    65   |   66    |   67    |
;  ----------------------------------------------------------------------------------
;  |  0xf0   |  0xf4   |   0xf8   |  0xfc  |   0x100  |  0x104  |  0x108  |  0x10c  |
;  ----------------------------------------------------------------------------------
;  |                          SEE registers (XMM6-XMM15)                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    68   |    69   |    70    |    71  |    72    |    73   |   74    |   75    |
;  ----------------------------------------------------------------------------------
;  |  0x110  |  0x114  |   0x118  |  0x11c |   0x120  |  0x124  |  0x128  |  0x12c  |
;  ----------------------------------------------------------------------------------
;  |                          SEE registers (XMM6-XMM15)                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    76   |   77    |                                                            |
;  ----------------------------------------------------------------------------------
;  |  0x130  |  0x134  |                                                            |
;  ----------------------------------------------------------------------------------
;  |     fc_dealloc    |                                                            |
;  ----------------------------------------------------------------------------------

EXTERN  _exit:PROC            ; standard C library function
.code

cps_context_new_from_sp PROC EXPORT FRAME  ; generate function table entry in .pdata and unwind information in
    .endprolog                   ; .xdata for a function's structured exception handling unwind behavior

    lea  rax,        [rcx-0138h] ; reserve space for cps_context at top of context stack

    ; shift address in RAX to lower 16 byte boundary
    ; == pointer to cps_context and address of context stack
    and  rax,        -16

    mov  [rax+048h], r8          ; save address of context function in cps_context
    mov  [rax+058h], rdx         ; save context stack size in cps_context
    mov  [rax+050h], rcx         ; save address of context stack pointer (base) in cps_context

    neg  rdx                     ; negate stack size for LEA instruction (== substraction)
    lea  rcx,         [rcx+rdx]  ; compute bottom address of context stack (limit)
    mov  [rax+060h],  rcx        ; save bottom address of context stack (limit) in cps_context
    mov  [rax+0130h], rcx        ; save address of context stack limit as 'dealloction stack'

    stmxcsr [rax+070h]           ; save MMX control and status word
    fnstcw  [rax+074h]           ; save x87 control word

    lea  rdx,        [rax-028h]  ; reserve 32byte shadow space + return address on stack, (RSP - 0x8) % 16 == 0
    mov  [rax+040h], rdx         ; save address in RDX as stack pointer for context function

    lea  rcx,        finish      ; compute abs address of label finish
    mov  [rdx],      rcx         ; save address of finish as return address for context function
                                 ; entered after context function returns

    ret

finish:
    ; RSP points to same address as RSP on entry of context function + 0x8
    xor   rcx,       rcx         ; exit code is zero
    call  _exit                  ; exit application
    hlt
cps_context_new_from_sp ENDP
END
