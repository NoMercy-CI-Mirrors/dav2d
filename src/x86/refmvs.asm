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
%endif ; ARCH_X86_64
