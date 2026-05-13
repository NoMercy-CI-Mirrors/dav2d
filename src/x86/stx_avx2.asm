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
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHr4wT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%include "config.asm"
%include "ext/x86/x86inc.asm"

SECTION_RODATA

pd_63: dd 63

cextern coeff8x8_mapping

SECTION .text

INIT_YMM avx2
cglobal stx4_8bpc, 4, 6, 6, cf, stride, tp, kernel, eob
    movifnidn      eobd, eobm
    xor             r5d, r5d
    add            eobd, eobd
    vpbroadcastd     m0, [pd_63]
    mova             m1, m0
.loop:
    vpbroadcastd     m5, [cfq+r5]
    pmovsxbw         m2, [kernelq+r5*8+ 0]
    pmovsxbw         m4, [kernelq+r5*8+16]
    punpckhwd        m3, m2, m4
    punpcklwd        m2, m4
    REPX {pmaddwd x, m5}, m2, m3
    paddd            m0, m2
    paddd            m1, m3
    add             r5d, 4
    cmp             r5d, eobd
    jle .loop
    pcmpeqd          m3, m3
    pcmpgtd          m2, m0, m3
    pcmpgtd          m3, m1, m3
    psubd            m0, m2
    psubd            m1, m3
    REPX  {psrad x, 7 }, m0, m1
    packssdw         m0, m1
    test            tpd, tpd
    jz .tp
    cmp         strideq, 4
    jne .write_4x4
    mova          [cfq], m0
    RET
.write_4x4:
    ; movq zeroes the upper 64 bits, so the following write zeroes the upper
    ; 4 input coefficients while writing out the lower 4 output coefficients
    movq            xm1, xm0
    mova   [cfq+strideq*0], xm1
    movhps [cfq+strideq*2], xm0
    vextracti128    xm0, m0, 1
    lea             cfq, [cfq+strideq*4]
    movq   [cfq+strideq*0], xm0
    movhps [cfq+strideq*2], xm0
    RET
.tp:
    vextracti128    xm1, m0, 1
    punpckhwd       xm2, xm0, xm1
    punpcklwd       xm0, xm1
    punpcklwd       xm1, xm0, xm2
    punpckhwd       xm0, xm2
    ; movq zeroes the upper 64 bits, so the following write zeroes the upper
    ; 4 input coefficients while writing out the lower 4 output coefficients
    movq            xm2, xm1
    mova   [cfq+strideq*0], xm2
    movhps [cfq+strideq*2], xm1
    lea             cfq, [cfq+strideq*4]
    movq   [cfq+strideq*0], xm0
    movhps [cfq+strideq*2], xm0
    RET

cglobal stx8_8bpc, 5, 7, 10, -96, cf, stride, tp, mi, kernel, eob
    movifnidn      eobd, eobm
    xor             r6d, r6d
    vpbroadcastd     m0, [pd_63]
    REPX   {mova x, m0}, m1, m2, m3, m4, m5
.loop:
    vpbroadcastd     m9, [cfq+r6*2]
    pmovsxbw         m6, [kernelq+ 0]
    pmovsxbw         m8, [kernelq+48]
    punpckhwd        m7, m6, m8
    punpcklwd        m6, m8
    REPX {pmaddwd x, m9}, m6, m7
    paddd            m0, m6
    paddd            m1, m7
    pmovsxbw         m6, [kernelq+16]
    pmovsxbw         m8, [kernelq+64]
    punpckhwd        m7, m6, m8
    punpcklwd        m6, m8
    REPX {pmaddwd x, m9}, m6, m7
    paddd            m2, m6
    paddd            m3, m7
    pmovsxbw         m6, [kernelq+32]
    pmovsxbw         m8, [kernelq+80]
    punpckhwd        m7, m6, m8
    punpcklwd        m6, m8
    REPX {pmaddwd x, m9}, m6, m7
    paddd            m4, m6
    paddd            m5, m7
    add         kernelq, 96
    add             r6d, 2
    cmp             r6d, eobd
    jle .loop
    pcmpeqd          m9, m9
    pcmpgtd          m6, m0, m9
    pcmpgtd          m7, m1, m9
    pcmpgtd          m8, m2, m9
    psubd            m0, m6
    psubd            m1, m7
    psubd            m2, m8
    pcmpgtd          m6, m3, m9
    pcmpgtd          m7, m4, m9
    pcmpgtd          m8, m5, m9
    psubd            m3, m6
    psubd            m4, m7
    psubd            m5, m8
    REPX  {psrad x, 7 }, m0, m1, m2, m3, m4, m5
    packssdw         m0, m1
    packssdw         m2, m3
    packssdw         m4, m5

    lea             miq, [miq*3]
    mova [rsp+0*mmsize], m0
    mova [rsp+1*mmsize], m2
    mova [rsp+2*mmsize], m4
    lea              r4, [coeff8x8_mapping]
    shl             mid, 4
    lea             miq, [r4+miq+48]
    pxor             m1, m1
    mova     [cfq+0*32], m1
    mova     [cfq+1*32], m1

    test            tpd, tpd
    jz .tp
    mov              r2, -48
    sub         strideq, 8
    jg .stride
.plain:
    movzx           r4d, word [rsp+96+r2*2]
    movzx           r5d, byte [miq+r2]
    mov      [cfq+r5*2], r4w
    inc              r2
    jl .plain
    RET
.stride:
    movzx           r5d, byte [miq+r2]
    movzx           r4d, word [rsp+96+r2*2]
    rorx             r6, r5, 3
    imul            r6d, strided
    add             r5d, r6d
    mov      [cfq+r5*2], r4w
    inc              r2
    jl .stride
    RET
.tp:
    mov              r2, -48
    tzcnt       strided, strided
.loop_tp:
    movzx           r5d, byte [miq+r2]
    movzx           r4d, word [rsp+96+r2*2]
    rorx             r6, r5, 3
    and             r5d, 7
    shlx            r5d, r5d, strided
    add             r5d, r6d
    mov      [cfq+r5*2], r4w
    inc              r2
    jl .loop_tp
    RET
