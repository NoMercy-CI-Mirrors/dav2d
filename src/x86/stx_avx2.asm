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

SECTION_RODATA

pd_63: dd 63

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
