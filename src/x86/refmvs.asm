; Copyright © 2026, VideoLAN and dav2d authors
; Copyright © 2026, Two Orioles, LLC
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%include "config.asm"
%include "ext/x86/x86inc.asm"

SECTION_RODATA 32

pb_triple_mask: db 0, 1, 2, 3, 4, 5, 0, 1
                db 2, 3, 4, 5, 0, 1, 2, 3
                db 4, 5, 0, 1, 2, 3, 4, 5
                db 0, 1, 2, 3, 4, 5, 0, 1
                db 2, 3, 4, 5, 0, 1, 2, 3
                db 4, 5, 0, 1, 2, 3, 4, 5
t2_shuf: db 0, 1, 2, 3, 8, 10, 4, 5, 6, 7, 12, 14
         times 4 db -1
t4_shufA: db 8, 10, 12, 14
          ; this is actually "shufC"
          db 4, 5, 0, 1, 2, 3, 6, 7
          ; and thus is "shufA" again
          db 0, 2, 4, 6
t4_shufB: db 4, 5, 6, 7, 0, 1, 8, 9, 10, 11, 2, 3, 12, 13, 14, 15

pb_128: times 4 db 128
pw_257: times 2 dw 0x101
pd_0xffff: dd 0xffff

%macro JMP_TABLE 2-*
    %xdefine %%prefix mangle(private_prefix %+ _%1)
    %1_table:
    %xdefine %%base %1_table
    %rep %0 - 1
        dd %%prefix %+ .%2 - %%base
        %rotate 1
    %endrep
%endmacro

JMP_TABLE splat_mv_avx2, t1, t1, t2, t4, t8, t16, t32
JMP_TABLE splat_comp_wedgemv_avx2, t1, t2, t4, t8

SECTION .text

%if ARCH_X86_64
INIT_YMM avx2
cglobal splat_mv, 5, 8, 3, sdst, ssrc, tdst, tstride, tsrc, bw4, bh4
    test         tdstq, tdstq
    jz .spatial

    ; temporal loop
    vpbroadcastq    m0, [tsrcq]
    lea             r6, [splat_mv_avx2_table]
    tzcnt          r7d, bw4m
    movsxd          r7, [r6+r7*4]
    add             r7, r6
    mov           bh4d, bh4m
    lea       tstrideq, [tstrideq*3]
    inc           bh4d
    shr           bh4d, 1
    jmp             r7

.t1:
    movd    [tdstq+ 0], xm0
    pextrw  [tdstq+ 4], xm0, 2
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t1
    jmp .spatial

.t2:
    pshuflw        xm1, xm0, q1021
    pshuflw        xm0, xm0, q0210
.t2_loop:
    movq    [tdstq+ 0], xm0
    movd    [tdstq+ 8], xm1
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t2_loop
    jmp .spatial

.t4:
    pshufb         xm0, [pb_triple_mask]
    psrldq         xm1, xm0, 4
.t4_loop:
    movu    [tdstq+ 0], xm0
    movq    [tdstq+16], xm1
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t4_loop
    jmp .spatial

.t8:
    pshufb         xm1, xm0, [pb_triple_mask+8]
    pshufb          m0, [pb_triple_mask]
.t8_loop:
    movu    [tdstq+ 0], m0
    mova    [tdstq+32], xm1
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t8_loop
    jmp .spatial

.t16:
    pshufb          m1, m0, [pb_triple_mask+8]
    pshufb          m2, m0, [pb_triple_mask+16]
    pshufb          m0, [pb_triple_mask]
.t16_loop:
    mova    [tdstq+ 0], m0
    mova    [tdstq+32], m1
    mova    [tdstq+64], m2
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t16_loop
    jmp .spatial

.t32:
    pshufb          m1, m0, [pb_triple_mask+8]
    pshufb          m2, m0, [pb_triple_mask+16]
    pshufb          m0, [pb_triple_mask]
.t32_loop:
    mova   [tdstq+  0], m0
    mova   [tdstq+ 32], m1
    mova   [tdstq+ 64], m2
    mova   [tdstq+ 96], m0
    mova   [tdstq+128], m1
    mova   [tdstq+160], m2
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t32_loop
    ; fall-through

.spatial:
    mova            m0, [ssrcq]
    rorx          bw4d, bw4m, 26
    mov           bh4d, bh4m
    add          sdstq, bw4q
    neg           bw4q
    dec           bh4d
    jz .last_line
    cmp           bw4q, -64*2
    jl .s3
    je .s2
    ; fall-through
.s1:
    mova  [sdstq-64*1], m0
    add          sdstq, 128*64
    dec           bh4d
    jg .s1
    jmp .last_line
.s2:
    mova  [sdstq-64*2], m0
    mova  [sdstq-64*1], m0
    add          sdstq, 128*64
    dec           bh4d
    jg .s2
    jmp .last_line
.s3:
    mova  [sdstq-64*3], m0
    mova  [sdstq-64*2], m0
    mova  [sdstq-64*1], m0
    add          sdstq, 128*64
    dec           bh4d
    jg .s3
    ; fall-through
.last_line:
    mova  [sdstq+bw4q], m0
    add           bw4q, 64
    jl .last_line
    RET

INIT_YMM avx2
cglobal splat_comp_wedgemv, 5, 8, 3, sdst, ssrc, tdst, tstride, tsrc, bw4, bh4, wedge, wswap
    test         tdstq, tdstq
    jz mangle(private_prefix %+ _splat_mv_avx2).spatial

    ; temporal loop
    vpbroadcastd    m0, [tsrcq]
    vpbroadcastd    m1, [pb_128]
    vpbroadcastd    m2, wswapm
    vpbroadcastd    m3, [pd_0xffff]
    vpbroadcastw    m4, [tsrcq+4]
    pxor            m5, m5
    punpcklbw       m4, m4, m5          ; t_src.ref in 2 words
    pshuflw         m5, m4, q2301
    pshufhw         m5, m5, q2301       ; t_src.ref[1,0]
    lea             r6, [splat_comp_wedgemv_avx2_table]
    tzcnt          r7d, bw4m
    movsxd          r7, [r6+r7*4-4]
    add             r7, r6
    mov           bh4d, bh4m
    lea       tstrideq, [tstrideq*3]
    inc           bh4d
    shr           bh4d, 1
    jmp             r7

%macro COMP_WEDGEMV_LOOP_START 1 ; len
.t%1:
    mov         wedgeq, wedgemp
    WIN64_SPILL_XMM 12
%if mmsize == 16
    mova            m9, [t4_shufA]
    mova           m10, [t4_shufB]
%else
    vbroadcasti128  m9, [t4_shufA]
    vbroadcasti128 m10, [t4_shufB]
%endif
    psrldq         m11, m9, 4
.t%1_loop:
    pmovzxbd        m6, [wedgeq]        ; d [range: 0-2]
    pxor            m6, m2              ; d^wswap [range: 0-3]
    pslld           m6, 4
    vpsllvd         m6, m3, m6          ; if d^wswap==0:  2x-1,14x0
                                        ; if d^w_swap==1: 2x0,2x-1,12x0
                                        ; else:           16x0
    vpblendvb       m6, m0, m1, m6      ; t_src.mv w/ invalidated wedge-MVs

    pcmpeqw         m7, m6, m1          ; whether mv0 or mv1 are invalid
    pshuflw         m8, m6, q2301       ; t_src.mv[1,0]
    pshufhw         m8, m8, q2301       ; t_src.mv[1,0]
    vpblendvb       m6, m6, m8, m7      ; if both mvs are valid:    mv0, mv1
                                        ; if mv0=invalid&mv1=valid: mv1 [2x]
                                        ; if mv0=valid&mv1=invalid: mv0 [2x]
                                        ; if both mvs are invalid:  invalid_mv [2x]
    vpblendvb       m7, m4, m5, m7      ; if both mvs are valid:    ref0, ref1
                                        ; if mv0=invalid&mv1=valid: ref1 [2x]
                                        ; if mv0=valid&mv1=invalid: ref0 [2x]
    pcmpeqd         m8, m6, m1          ; whether mv0 and mv1 are invalid
    por             m7, m8              ; if both mvs are valid:    ref0, ref1
                                        ; if mv0=invalid&mv1=valid: ref1 [2x]
                                        ; if mv0=valid&mv1=invalid: ref0 [2x]
                                        ; if both mvs are invalid:  -1
    pshufb          m7, m9              ; ref2,ref3,8x?,ref0,ref1
    palignr         m8, m6, m7, 12      ; [0..3]ref0-1,[4..15]mv0-2
    palignr         m6, m7, m6, 12      ; [0..3]mv3,[4..7]ref2-3
    pshufb          m8, m10
    pshufb          m6, m11
%endmacro

    INIT_XMM avx2
    COMP_WEDGEMV_LOOP_START 1
    movd    [tdstq+ 0], m8
    pextrw  [tdstq+ 4], m8, 2
    dec           bh4d
    jz .t1_break
    pextrw  [tdstq+tstrideq*2+ 0], m8, 3
    pextrd  [tdstq+tstrideq*2+ 2], m8, 2
    dec           bh4d
    jz .t1_break
    lea          tdstq, [tdstq+tstrideq*4]
    pextrd  [tdstq+ 0], m8, 3
    pextrw  [tdstq+ 4], m6, 0
    pextrw  [tdstq+tstrideq*2+ 0], m6, 1
    pextrd  [tdstq+tstrideq*2+ 2], m6, 1
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*4]
    sub           bh4d, 2
    jg .t1_loop
.t1_break:
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

    INIT_YMM avx2
    COMP_WEDGEMV_LOOP_START 2
    movq    [tdstq+ 0], xm8
    pextrd  [tdstq+ 8], xm8, 2
    dec           bh4d
    jz .t2_break
    pextrd  [tdstq+tstrideq*2+ 0], xm8, 3
    movq    [tdstq+tstrideq*2+ 4], xm6
    dec           bh4d
    jz .t2_break
    lea          tdstq, [tdstq+tstrideq*4]
    vextracti128   xm8, m8, 1
    vextracti128   xm7, m6, 1
    movq    [tdstq+ 0], xm8
    pextrd  [tdstq+ 8], xm8, 2
    pextrd  [tdstq+tstrideq*2+ 0], xm8, 3
    movq    [tdstq+tstrideq*2+ 4], xm7
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*4]
    sub           bh4d, 2
    jg .t2_loop
.t2_break:
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

    COMP_WEDGEMV_LOOP_START 4
    movu    [tdstq+ 0], xm8
    movq    [tdstq+16], xm6
    dec           bh4d
    jz .t4_break
    vextracti128   xm7, m6, 1
    vextracti128 [tdstq+tstrideq*2+ 0], m8, 1
    movq         [tdstq+tstrideq*2+16], xm7
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*4]
    dec           bh4d
    jg .t4_loop
.t4_break:
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

    COMP_WEDGEMV_LOOP_START 8
    vextracti128   xm7, m6, 1
    movu         [tdstq+ 0], xm8
    movq         [tdstq+16], xm6
    vextracti128 [tdstq+24], m8, 1
    movq         [tdstq+40], xm7
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t8_loop
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial
%endif ; ARCH_X86_64
