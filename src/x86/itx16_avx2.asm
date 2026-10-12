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

coef_min:       dd -131072, -524288
coef_max:       dd  131071,  524287
pd_128:         dd 128

SECTION .text

INIT_YMM avx2
cglobal cctx_16bpc, 4, 6, 9, u, v, angle, sz, bdmax
%define base r5-coef_min
    movifnidn        bdmaxd, bdmaxm
    lea                  r5, [coef_min]
    vpbroadcastd         m4, [angleq+0]
    lea                  uq, [uq+szq*4]
    vpbroadcastd         m5, [angleq-2]
    lea                  vq, [vq+szq*4]
    vpbroadcastd         m6, [base+pd_128]
    shr              bdmaxd, 11
    neg                 szq
    vpbroadcastd         m7, [base+coef_min+bdmaxq*4]
    psrad                m4, 16 ; cos
    vpbroadcastd         m8, [base+coef_max+bdmaxq*4]
    psrad                m5, 16 ; sin
.loop:
    mova                 m1, [uq+szq*4]
    mova                 m3, [vq+szq*4]
    pmulld               m0, m4, m1
    pmulld               m2, m5, m3
    pmulld               m1, m5
    pmulld               m3, m4
    psubd                m0, m2
    paddd                m1, m3
    pcmpgtd              m2, m6, m0
    paddd                m0, m6
    pcmpgtd              m3, m6, m1
    paddd                m1, m6
    paddd                m0, m2
    paddd                m1, m3
    psrad                m0, 8
    psrad                m1, 8
    pmaxsd               m0, m7
    pmaxsd               m1, m7
    pminsd               m0, m8
    pminsd               m1, m8
    mova         [uq+szq*4], m0
    mova         [vq+szq*4], m1
    add                 szq, 8
    jl .loop
    RET
