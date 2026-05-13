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

SECTION_RODATA 64

pb_perm_a: db  4,  0,  84,  80,  5,  1,  85,  81
           db  6,  2,  86,  82,  7,  3,  87,  83
           db 12,  8,  92,  88, 13,  9,  93,  89
           db 14, 10,  94,  90, 15, 11,  95,  91
           db 20, 16, 100,  96, 21, 17, 101,  97
           db 22, 18, 102,  98, 23, 19, 103,  99
           db 28, 24, 108, 104, 29, 25, 109, 105
           db 30, 26, 110, 106, 31, 27, 111, 107
pb_perm_b: db 0,  0, 0, 48, 0,  1, 0, 49
           db 0,  2, 0, 50, 0,  3, 0, 51
           db 0,  8, 0, 56, 0,  9, 0, 57
           db 0, 10, 0, 58, 0, 11, 0, 59
           db 0,  4, 0, 52, 0,  5, 0, 53
           db 0,  6, 0, 54, 0,  7, 0, 55
           db 0, 12, 0, 60, 0, 13, 0, 61
           db 0, 14, 0, 62, 0, 15, 0, 63

pb_out_shuf: db  0, 10,  1, 19,  5, 23,  6, 29, 14, 36, 15, 38, -1, -1, -1, -1
             db  2, 20,  4, 22,  7, 30, 13, 35, 16, 39, 26, 44, -1, -1, -1, -1
             db  3, 21,  8, 31, 12, 34, 17, 40, 25, 43, 27, 45, -1, -1, -1, -1
             db  9, 32, 11, 33, 18, 41, 24, 42, 28, 46, 37, 47, -1, -1, -1, -1
             db  0, 14,  2, 16,  3, 25,  9, 28, 10, 36, 20, 39, 21, 43, 32, 46
             db  1, 15,  4, 26,  8, 27, 11, 37, 19, 38, 22, 44, 31, 45, 33, 47
             db  5, -1,  7, -1, 12, -1, 18, -1, 23, -1, 30, -1, 34, -1, 41, -1
             db  6, -1, 13, -1, 17, -1, 24, -1, 29, -1, 35, -1, 40, -1, 42, -1
             db  0, 10,  1, 19,  5, 23,  6, 32, 14, 39, 15, 44, 27, -1, 28, -1
             db  2, 20,  4, 22,  7, 33, 13, 38, 16, 45, 26, 47, 29, -1, 42, -1
             db  3, 21,  8, 34, 12, 37, 17, 46, 25, -1, 30, -1, 41, -1, -1, -1
             db  9, 35, 11, 36, 18, -1, 24, -1, 31, -1, 40, -1, 43, -1, -1, -1
             db  0, 14,  2, 16,  3, 25,  9, 31, 10, 39, 20, 45, 21, -1, 35, -1
             db  1, 15,  4, 26,  8, 30, 11, 40, 19, 44, 22, 47, 34, -1, 36, -1
             db  5, 27,  7, 29, 12, 41, 18, 43, 23, -1, 33, -1, 37, -1, -1, -1
             db  6, 28, 13, 42, 17, -1, 24, -1, 32, -1, 38, -1, 46, -1, -1, -1
             db  0, 10,  1, 19,  5, 22,  6, 31, 14, 34, 15, 40, 26, 43, 27, 45
             db  2, 20,  4, 21,  7, 32, 13, 33, 16, 41, 25, 42, 28, 46, 37, 47
             db  3, -1,  8, -1, 12, -1, 17, -1, 24, -1, 29, -1, 36, -1, 38, -1
             db  9, -1, 11, -1, 18, -1, 23, -1, 30, -1, 35, -1, 39, -1, 44, -1
             db  0, 14,  2, 16,  3, 24,  9, 30, 10, 34, 20, 41, -1, -1, -1, -1
             db  1, 15,  4, 25,  8, 29, 11, 35, 19, 40, 21, 42, -1, -1, -1, -1
             db  5, 26,  7, 28, 12, 36, 18, 39, 22, 43, 32, 46, -1, -1, -1, -1
             db  6, 27, 13, 37, 17, 38, 23, 44, 31, 45, 33, 47, -1, -1, -1, -1

pd_m32: dd -32

cextern coeff8x8_mapping

SECTION .text

INIT_ZMM avx512icl
cglobal stx8_8bpc, 5, 7, 9, cf, stride, tp, mi, kernel, eob
    movifnidn      eobd, eobm
    xor             r6d, r6d
    REPX    {pxor x, x}, xm0, xm1, xm2
    mova             m3, [pb_perm_a]
    mova             m4, [pb_perm_b]
.loop:
    mova            ym5, [kernelq+ 0]
    movu             m7, [kernelq+32]
    vpbroadcastd     m8, [cfq+r6*2]
    vpermt2b         m5, m3, m7
    vpermb           m7, m4, m7
    psllw            m6, m5, 8
    REPX   {psraw x, 8}, m5, m6, m7 ; sign-extend
    vpdpwssd         m0, m5, m8
    vpdpwssd         m1, m6, m8
    vpdpwssd         m2, m7, m8
    add         kernelq, 96
    add             r6d, 2
    cmp             r6d, eobd
    jle .loop
    vpbroadcastd     m5, [pd_m32]
    vpshrdd          m3, m0, m5, 31
    vpshrdd          m4, m1, m5, 31
    vpshrdd          m5, m2, m5, 31
    psubd            m0, m3
    psubd            m1, m4
    psubd            m2, m5
    REPX   {psrad x, 7}, m0, m1, m2
    vextracti32x8   ym3, m2, 1
    packssdw         m0, m1
    packssdw        ym2, ym3

    ; write-out
    lea              r2, [miq*2+tpq]
    lea              r3, [pb_out_shuf]
    shl             r2d, 6
    mova             m1, [r3+r2]
    psrlw            m3, m1, 8
    vpermi2w         m1, m0, m2
    vpermt2w         m0, m3, m2
    cmp         strideq, 8
    jg .write_lanes
    mova       [cfq+ 0], m1
    mova       [cfq+64], m0
    RET
.write_lanes:
    lea              r4, [strideq*3]
    ; mova zeroes the upper 3x128 bits, so the following write zeroes the upper
    ; 24 input coefficients while writing out the lower 8 output coefficients
    mova            xm2, xm1
    mova          [cfq+strideq*0], m2
    vextracti32x4 [cfq+strideq*2], ym1, 1
    vextracti32x4 [cfq+strideq*4], m1, 2
    vextracti32x4 [cfq+r4     *2], m1, 3
    lea             cfq, [cfq+strideq*8]
    mova          [cfq+strideq*0], xm0
    vextracti32x4 [cfq+strideq*2], ym0, 1
    vextracti32x4 [cfq+strideq*4], m0, 2
    vextracti32x4 [cfq+r4     *2], m0, 3
    RET
