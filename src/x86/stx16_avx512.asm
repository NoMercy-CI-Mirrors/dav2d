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

SECTION_RODATA 64

; for each mapping index (3) and transpose flag (2), the index of the output
; (0-47) to write to each of the 64 coefficients of the 8x8 block (in memory
; order, i.e. rows of 8), or -1 to write 0
pb_out_idx: db  0,  1,  5,  6, 14, 15, -1, -1,  2,  4,  7, 13, 16, 26, -1, -1
            db  3,  8, 12, 17, 25, 27, -1, -1,  9, 11, 18, 24, 28, 37, -1, -1
            db 10, 19, 23, 29, 36, 38, -1, -1, 20, 22, 30, 35, 39, 44, -1, -1
            db 21, 31, 34, 40, 43, 45, -1, -1, 32, 33, 41, 42, 46, 47, -1, -1
            db  0,  2,  3,  9, 10, 20, 21, 32,  1,  4,  8, 11, 19, 22, 31, 33
            db  5,  7, 12, 18, 23, 30, 34, 41,  6, 13, 17, 24, 29, 35, 40, 42
            db 14, 16, 25, 28, 36, 39, 43, 46, 15, 26, 27, 37, 38, 44, 45, 47
            db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
            db  0,  1,  5,  6, 14, 15, 27, 28,  2,  4,  7, 13, 16, 26, 29, 42
            db  3,  8, 12, 17, 25, 30, 41, -1,  9, 11, 18, 24, 31, 40, 43, -1
            db 10, 19, 23, 32, 39, 44, -1, -1, 20, 22, 33, 38, 45, 47, -1, -1
            db 21, 34, 37, 46, -1, -1, -1, -1, 35, 36, -1, -1, -1, -1, -1, -1
            db  0,  2,  3,  9, 10, 20, 21, 35,  1,  4,  8, 11, 19, 22, 34, 36
            db  5,  7, 12, 18, 23, 33, 37, -1,  6, 13, 17, 24, 32, 38, 46, -1
            db 14, 16, 25, 31, 39, 45, -1, -1, 15, 26, 30, 40, 44, 47, -1, -1
            db 27, 29, 41, 43, -1, -1, -1, -1, 28, 42, -1, -1, -1, -1, -1, -1
            db  0,  1,  5,  6, 14, 15, 26, 27,  2,  4,  7, 13, 16, 25, 28, 37
            db  3,  8, 12, 17, 24, 29, 36, 38,  9, 11, 18, 23, 30, 35, 39, 44
            db 10, 19, 22, 31, 34, 40, 43, 45, 20, 21, 32, 33, 41, 42, 46, 47
            db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
            db  0,  2,  3,  9, 10, 20, -1, -1,  1,  4,  8, 11, 19, 21, -1, -1
            db  5,  7, 12, 18, 22, 32, -1, -1,  6, 13, 17, 23, 31, 33, -1, -1
            db 14, 16, 24, 30, 34, 41, -1, -1, 15, 25, 29, 35, 40, 42, -1, -1
            db 26, 28, 36, 39, 43, 46, -1, -1, 27, 37, 38, 44, 45, 47, -1, -1

pd_bdmax: dd 524287, 131071
pd_m32:   dd -32
pb_48:    times 4 db 48

SECTION .text

; %1 = output register, %2 = row pair (0-3) of the 8x8 block
%macro STX8_OUT 2
    mova           xm%1, [r3+16*%2]
    pmovzxbd         m3, xm%1
    vpcmpub          k1, xm%1, xm8, 1 ; index < 48
    vptestnmb        k2, xm%1, xm8    ; index < 16
    mova            m%1, m2
    vpermt2d m%1{k1}{z}, m3, m1
    vpermd      m%1{k2}, m3, m0
%endmacro

INIT_ZMM avx512icl
cglobal stx8_16bpc, 5, 7, 9, cf, stride, tp, mi, kernel, eob, bdmax
    lea              r2, [miq*2+tpq]
    lea              r3, [pb_out_idx]
    lzcnt        bdmaxd, bdmaxm             ; 20 (12bpc) or 22 (10bpc)
    vpbroadcastd     m8, [r3-pb_out_idx+pd_bdmax-40+bdmaxq*2]
    mov            eobd, eobm
    lea              r6, [cfq+eobq*4]
    neg            eobq
    REPX    {pxor x, x}, xm0, xm1, xm2
.loop:
    vpbroadcastd     m6, [r6+eobq*4]
    vpmovsxbd        m3, [kernelq+16*0]
    vpmovsxbd        m4, [kernelq+16*1]
    vpmovsxbd        m5, [kernelq+16*2]
    REPX {pmulld x, m6}, m3, m4, m5
    paddd            m0, m3
    paddd            m1, m4
    paddd            m2, m5
    add         kernelq, 48
    inc            eobq
    jle .loop
    ; round: (x + 64 - (x < 0)) >> 7
    vpbroadcastd     m5, [pd_m32]
    vpshrdd          m3, m0, m5, 31
    vpshrdd          m4, m1, m5, 31
    vpshrdd          m5, m2, m5, 31
    psubd            m0, m3
    psubd            m1, m4
    psubd            m2, m5
    REPX   {psrad x, 7}, m0, m1, m2
    vpternlogd       m7, m8, m8, 0x55       ; ~bdmax = -bdmax - 1
    REPX {pminsd x, m8}, m0, m1, m2
    REPX {pmaxsd x, m7}, m0, m1, m2

    ; write-out
    shl             r2d, 6
    add              r3, r2
    vpbroadcastd     m8, [pb_48]
    STX8_OUT          4, 0
    STX8_OUT          5, 1
    STX8_OUT          6, 2
    STX8_OUT          7, 3
    cmp         strideq, 8
    jg .write_rows
    mova     [cfq+64*0], m4
    mova     [cfq+64*1], m5
    mova     [cfq+64*2], m6
    mova     [cfq+64*3], m7
    RET
.write_rows:
    ; the input coefficients (cf[0-31]) also need to be zeroed: mova-ym zeroes
    ; the upper 256 bits, so the first write zeroes cf[8-15] while writing out
    ; the first row, and cf[16-31] are explicitly zeroed (before any following
    ; rows are written, since they can overlap with those)
    shl         strided, 2                  ; in bytes
    lea              r4, [strideq*3]
    mova            ym3, ym4
    pxor            xm8, xm8
    mova       [cfq+64*0], m3
    mova       [cfq+64*1], m8
    vextracti32x8 [cfq+strideq*1], m4, 1
    mova          [cfq+strideq*2], ym5
    vextracti32x8 [cfq+r4       ], m5, 1
    lea             cfq, [cfq+strideq*4]
    mova          [cfq+strideq*0], ym6
    vextracti32x8 [cfq+strideq*1], m6, 1
    mova          [cfq+strideq*2], ym7
    vextracti32x8 [cfq+r4       ], m7, 1
    RET
