/*
            Copyright Oliver Kowalke 2009.
   Distributed under the Boost Software License, Version 1.0.
      (See accompanying file LICENSE_1_0.txt or copy at
            http://www.boost.org/LICENSE_1_0.txt)
*/

/****************************************************************************************
 *                                                                                      *
 *  ----------------------------------------------------------------------------------  *
 *  |    0    |    1    |    2    |    3    |    4     |    5    |    6    |    7    |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x0   |   0x4   |   0x8   |   0xc   |   0x10   |   0x14  |   0x18  |   0x1c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        RBX        |        R12        |         R13        |        R14        |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |    8    |    9    |   10    |   11    |    12    |    13   |    14   |    15   |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x20  |   0x24  |   0x28  |  0x2c   |   0x30   |   0x34  |   0x38  |   0x3c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        R15        |        RBP        |         RSP        |        RIP        |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |   16    |   17    |   18    |    19   |                                        |  *
 *  ----------------------------------------------------------------------------------  *
 *  |  0x40   |  0x44   |  0x48   |   0x4c  |                                        |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        sp         |        size       |                                        |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |    20   |    21   |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x50  |   0x54  |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  | fc_mxcsr|fc_x87_cw|                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *                                                                                      *
 * **************************************************************************************/

.text
.globl _cps_context_new_from_sp
.align 8
_cps_context_new_from_sp:
    leaq   -0x58(%rdi),     %rax        /* reserve space for cps_context at top of context stack */

    /* shift address in RAX to lower 16 byte boundary */
    /* == pointer to cps_context and address of context stack */
    movabs  $-16,           %r8
    andq    %r8,            %rax

    movq   %rdi,            0x40(%rax) /* save address of stack pointer (base) in cps_context */
    movq   %rsi,            0x48(%rax) /* save stack size in cps_context */
    movq   %rdx,            0x38(%rax) /* save address of context function in cps_context */

    stmxcsr  0x50(%rax)                /* save MMX control and status word */
    fnstcw   0x54(%rax)                /* save x87 control word */

    leaq   -0x8(%rax),      %rdx       /* reserve space for the return address on context stack, (RSP - 0x8) % 16 == 0 */
    movq   %rdx,            0x30(%rax) /* save address in RDX as stack pointer for context function */

    leaq   finish(%rip),    %rcx       /* compute abs address of label finish */
    movq   %rcx,            (%rdx)     /* save address of finish as return address for context function */
                                       /* entered after context function returns */

    ret                                /* return pointer to cps_context placed on context stack */

finish:
    /* RSP points to same address as RSP on entry of context function + 0x8 */
    xorq    %rdi,           %rdi       /* exit code is zero */
    call   __exit                      /* exit application */
