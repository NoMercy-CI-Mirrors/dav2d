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

pd_bdmax: dd 524287, 131071
pd_63: dd 63

cextern coeff8x8_mapping

SECTION .text

INIT_YMM avx2
cglobal stx4_16bpc, 4, 7, 6, cf, stride, tp, kernel, eob, bdmax
    lea              r6, [pd_bdmax]
    lzcnt        bdmaxd, bdmaxm             ; 20 (12bpc) or 22 (10bpc)
    movifnidn      eobd, eobm
    vpbroadcastd     m5, [r6+bdmaxq*2-40]
    xor             r5d, r5d
    add            eobd, eobd
    vpbroadcastd     m0, [pd_63]
    mova             m1, m0
.loop:
    vpbroadcastd     m4, [cfq+r5*2]
    pmovsxbd         m2, [kernelq+r5*8+0]
    pmovsxbd         m3, [kernelq+r5*8+8]
    REPX {pmulld x, m4}, m2, m3
    paddd            m0, m2
    paddd            m1, m3
    add             r5d, 2
    cmp             r5d, eobd
    jle .loop
    pcmpeqd          m4, m4
    pcmpgtd          m2, m0, m4
    pcmpgtd          m3, m1, m4
    psubd            m4, m5
    psubd            m0, m2
    psubd            m1, m3
    REPX  {psrad x, 7 }, m0, m1
    REPX {pminsd x, m5}, m0, m1
    REPX {pmaxsd x, m4}, m0, m1
    test            tpd, tpd
    jz .tp
    cmp         strideq, 4
    jne .write_4x4
    mova       [cfq+ 0], m0
    mova       [cfq+32], m1
    RET
.write_4x4:
    ; mova-xm zeroes the upper lane, so the following write zeroes the upper
    ; 4 input coefficients while writing out the lower 4 output coefficients
    mova            xm2, xm0
    mova         [cfq+strideq*0], m2
    vextracti128 [cfq+strideq*4], m0, 1
    lea             cfq, [cfq+strideq*8]
    mova         [cfq+strideq*0], xm1
    vextracti128 [cfq+strideq*4], m1, 1
    RET
.tp:
    REPX {vpermq x, x, q3120}, m0, m1
    shufps           m2, m0, m1, q3131
    shufps           m0, m1, q2020
    ; mova-xm zeroes the upper lane, so the following write zeroes the upper
    ; 4 input coefficients while writing out the lower 4 output coefficients
    mova            xm1, xm0
    mova   [cfq+strideq*0], m1
    mova   [cfq+strideq*4], xm2
    lea             cfq, [cfq+strideq*8]
    vextracti128 [cfq+strideq*0], m0, 1
    vextracti128 [cfq+strideq*4], m2, 1
    RET

%if WIN64
DECLARE_REG_TMP 5
%else
DECLARE_REG_TMP 8
%endif

cglobal stx8_16bpc, 5, 7, 10, 48*4, cf, stride, tp, mi, kernel, eob, bdmax
    lea              t0, [pd_bdmax]
    lzcnt        bdmaxd, bdmaxm             ; 20 (12bpc) or 22 (10bpc)
    vpbroadcastd     m9, [t0+bdmaxq*2-40]
    mov            eobd, eobm
    vpbroadcastd     m0, [pd_63]
    lea              r6, [cfq+eobq*4]
    neg            eobq
    REPX   {mova x, m0}, m1, m2, m3, m4, m5
.loop:
    vpbroadcastd     m8, [r6+eobq*4]
    pmovsxbd         m6, [kernelq+8*0]
    pmovsxbd         m7, [kernelq+8*1]
    REPX {pmulld x, m8}, m6, m7
    paddd            m0, m6
    paddd            m1, m7
    pmovsxbd         m6, [kernelq+8*2]
    pmovsxbd         m7, [kernelq+8*3]
    REPX {pmulld x, m8}, m6, m7
    paddd            m2, m6
    paddd            m3, m7
    pmovsxbd         m6, [kernelq+8*4]
    pmovsxbd         m7, [kernelq+8*5]
    REPX {pmulld x, m8}, m6, m7
    paddd            m4, m6
    paddd            m5, m7
    add         kernelq, 48
    inc            eobq
    jle .loop
    pcmpeqd          m8, m8
    pcmpgtd          m6, m0, m8
    pcmpgtd          m7, m1, m8
    psubd            m0, m6
    psubd            m1, m7
    pcmpgtd          m6, m2, m8
    pcmpgtd          m7, m3, m8
    psubd            m2, m6
    psubd            m3, m7
    pcmpgtd          m6, m4, m8
    pcmpgtd          m7, m5, m8
    psubd            m4, m6
    psubd            m5, m7
    psubd            m8, m9
    REPX  {psrad x, 7 }, m0, m1, m2, m3, m4, m5
    REPX {pminsd x, m9}, m0, m1, m2, m3, m4, m5
    REPX {pmaxsd x, m8}, m0, m1, m2, m3, m4, m5

    lea             miq, [miq*3]
    mova [rsp+0*mmsize], m0
    mova [rsp+1*mmsize], m1
    mova [rsp+2*mmsize], m2
    mova [rsp+3*mmsize], m3
    mova [rsp+4*mmsize], m4
    mova [rsp+5*mmsize], m5
    lea              r4, [coeff8x8_mapping]
    shl             mid, 4
    lea             miq, [r4+miq+48]
    pxor             m1, m1
    mova     [cfq+0*32], m1
    mova     [cfq+1*32], m1
    mova     [cfq+2*32], m1
    mova     [cfq+3*32], m1

    test            tpd, tpd
    jz .tp
    mov              r2, -48
    sub         strideq, 8
    jg .stride
.plain:
    mov             r4d, [rsp+48*4+r2*4]
    movzx           r5d, byte [miq+r2]
    mov      [cfq+r5*4], r4d
    inc              r2
    jl .plain
    RET
.stride:
    movzx           r5d, byte [miq+r2]
    mov             r4d, [rsp+48*4+r2*4]
    rorx             r6, r5, 3
    imul            r6d, strided
    add             r5d, r6d
    mov      [cfq+r5*4], r4d
    inc              r2
    jl .stride
    RET
.tp:
    mov              r2, -48
    tzcnt       strided, strided
.loop_tp:
    movzx           r5d, byte [miq+r2]
    mov             r4d, [rsp+48*4+r2*4]
    rorx             r6, r5, 3
    and             r5d, 7
    shlx            r5d, r5d, strided
    add             r5d, r6d
    mov      [cfq+r5*4], r4d
    inc              r2
    jl .loop_tp
    RET
