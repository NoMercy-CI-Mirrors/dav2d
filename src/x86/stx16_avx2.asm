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
