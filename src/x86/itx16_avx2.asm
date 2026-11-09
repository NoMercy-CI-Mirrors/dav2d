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

adst16_mat:
dd   8,  25,  41,  55,  67,  77,  84,  88,  89,  87,  81,  73,  62,  48,  33,  17
dd  17,  48,  73,  87,  88,  77,  55,  25,  -8, -41, -67, -84, -89, -81, -62, -33
dd  25,  67,  88,  81,  48,   0, -48, -81, -88, -67, -25,  25,  67,  88,  81,  48
dd  33,  81,  84,  41, -25, -77, -87, -48,  17,  73,  88,  55,  -8, -67, -89, -62
dd  41,  88,  62, -17, -81, -77,  -8,  67,  87,  33, -48, -89, -55,  25,  84,  73
dd  48,  88,  25, -67, -81,   0,  81,  67, -25, -88, -48,  48,  88,  25, -67, -81
dd  55,  81, -17, -89, -25,  77,  62, -48, -84,   8,  88,  33, -73, -67,  41,  87
dd  62,  67, -55, -73,  48,  77, -41, -81,  33,  84, -25, -87,  17,  88,  -8, -89
dd  67,  48, -81, -25,  88,   0, -88,  25,  81, -48, -67,  67,  48, -81, -25,  88
dd  73,  25, -89,  33,  67, -77, -17,  88, -41, -62,  81,   8, -87,  48,  55, -84
dd  77,   0, -77,  77,   0, -77,  77,   0, -77,  77,   0, -77,  77,   0, -77,  77
dd  81, -25, -48,  88, -67,   0,  67, -88,  48,  25, -81,  81, -25, -48,  88, -67
dd  84, -48,  -8,  62, -88,  77, -33, -25,  73, -89,  67, -17, -41,  81, -87,  55
dd  87, -67,  33,   8, -48,  77, -89,  81, -55,  17,  25, -62,  84, -88,  73, -41
dd  88, -81,  67, -48,  25,   0, -25,  48, -67,  81, -88,  88, -81,  67, -48,  25
dd  89, -88,  87, -84,  81, -77,  73, -67,  62, -55,  48, -41,  33, -25,  17,  -8
flipadst16_mat:
dd  89,  88,  87,  84,  81,  77,  73,  67,  62,  55,  48,  41,  33,  25,  17,   8
dd  88,  81,  67,  48,  25,   0, -25, -48, -67, -81, -88, -88, -81, -67, -48, -25
dd  87,  67,  33,  -8, -48, -77, -89, -81, -55, -17,  25,  62,  84,  88,  73,  41
dd  84,  48,  -8, -62, -88, -77, -33,  25,  73,  89,  67,  17, -41, -81, -87, -55
dd  81,  25, -48, -88, -67,   0,  67,  88,  48, -25, -81, -81, -25,  48,  88,  67
dd  77,   0, -77, -77,   0,  77,  77,   0, -77, -77,   0,  77,  77,   0, -77, -77
dd  73, -25, -89, -33,  67,  77, -17, -88, -41,  62,  81,  -8, -87, -48,  55,  84
dd  67, -48, -81,  25,  88,   0, -88, -25,  81,  48, -67, -67,  48,  81, -25, -88
dd  62, -67, -55,  73,  48, -77, -41,  81,  33, -84, -25,  87,  17, -88,  -8,  89
dd  55, -81, -17,  89, -25, -77,  62,  48, -84,  -8,  88, -33, -73,  67,  41, -87
dd  48, -88,  25,  67, -81,   0,  81, -67, -25,  88, -48, -48,  88, -25, -67,  81
dd  41, -88,  62,  17, -81,  77,  -8, -67,  87, -33, -48,  89, -55, -25,  84, -73
dd  33, -81,  84, -41, -25,  77, -87,  48,  17, -73,  88, -55,  -8,  67, -89,  62
dd  25, -67,  88, -81,  48,   0, -48,  81, -88,  67, -25, -25,  67, -88,  81, -48
dd  17, -48,  73, -87,  88, -77,  55, -25,  -8,  41, -67,  84, -89,  81, -62,  33
dd   8, -25,  41, -55,  67, -77,  84, -88,  89, -87,  81, -73,  62, -48,  33, -17
ddt16_mat:
dd  12,  17,  37,  45,  47,  60,  64,  82,  89, 100,  92,  84,  69,  50,  51,  44
dd  15,  23,  49,  60,  60,  74,  70,  73,  48,   9, -35, -71, -83, -79, -89, -95
dd  19,  30,  60,  69,  61,  64,  40,   3, -53, -99, -91, -46,   2,  47,  73, 124
dd  23,  38,  69,  73,  49,  28, -19, -80, -96, -45,  42,  88,  75,  14, -17,-126
dd  30,  48,  75,  66,  19, -31, -79, -91,  -5,  84,  71, -16, -78, -60, -45, 108
dd  39,  61,  75,  40, -29, -87, -78,  10,  89,  36, -69, -67,  18,  67,  89, -81
dd  51,  76,  61,  -8, -77, -82,  11,  94,  16, -81, -22,  79,  50, -37,-103,  54
dd  66,  87,  29, -65, -83,   4,  92,  18, -83,   4,  85, -22, -85,  -6,  97, -30
dd  78,  83, -18, -91, -16,  88,  28, -84,  12,  73, -60, -46,  81,  49, -83,  16
dd  88,  59, -67, -57,  75,  54, -85,  -5,  75, -60, -17,  84, -43, -80,  71,  -6
dd  94,  19, -96,  21,  93, -55, -41,  80, -51, -17,  77, -68,  -6,  98, -56,   1
dd  97, -30, -83,  86,   3, -77,  82, -17, -43,  76, -70,  15,  53, -99,  44,   3
dd  93, -73, -28,  81, -92,  29,  39, -70,  81, -55,  11,  46, -81,  90, -31,  -4
dd  83, -99,  40,   8, -74,  88, -83,  47, -14, -21,  56, -83,  88, -71,  22,   5
dd  68, -99,  84, -69,  32,   3, -37,  55, -75,  81, -83,  82, -69,  48, -11,  -3
flipddt16_mat:
dd  50, -76,  83, -90,  97, -86,  83, -68,  67, -56,  49, -40,  32, -19,   5,   2
dd  68, -99,  84, -69,  32,   3, -37,  55, -75,  81, -83,  82, -69,  48, -11,  -3
dd  83, -99,  40,   8, -74,  88, -83,  47, -14, -21,  56, -83,  88, -71,  22,   5
dd  93, -73, -28,  81, -92,  29,  39, -70,  81, -55,  11,  46, -81,  90, -31,  -4
dd  97, -30, -83,  86,   3, -77,  82, -17, -43,  76, -70,  15,  53, -99,  44,   3
dd  94,  19, -96,  21,  93, -55, -41,  80, -51, -17,  77, -68,  -6,  98, -56,   1
dd  88,  59, -67, -57,  75,  54, -85,  -5,  75, -60, -17,  84, -43, -80,  71,  -6
dd  78,  83, -18, -91, -16,  88,  28, -84,  12,  73, -60, -46,  81,  49, -83,  16
dd  66,  87,  29, -65, -83,   4,  92,  18, -83,   4,  85, -22, -85,  -6,  97, -30
dd  51,  76,  61,  -8, -77, -82,  11,  94,  16, -81, -22,  79,  50, -37,-103,  54
dd  39,  61,  75,  40, -29, -87, -78,  10,  89,  36, -69, -67,  18,  67,  89, -81
dd  30,  48,  75,  66,  19, -31, -79, -91,  -5,  84,  71, -16, -78, -60, -45, 108
dd  23,  38,  69,  73,  49,  28, -19, -80, -96, -45,  42,  88,  75,  14, -17,-126
dd  19,  30,  60,  69,  61,  64,  40,   3, -53, -99, -91, -46,   2,  47,  73, 124
dd  15,  23,  49,  60,  60,  74,  70,  73,  48,   9, -35, -71, -83, -79, -89, -95
dd  12,  17,  37,  45,  47,  60,  64,  82,  89, 100,  92,  84,  69,  50,  51,  44
dct16_mat:      dd  90,  87,  80,  70,  57,  43,  26,   9
                dd  87,  57,   9, -43, -80, -90, -70, -26
                dd  80,   9, -70, -87, -26,  57,  90,  43
                dd  70, -43, -87,   9,  90,  26, -80, -57
adst8_mat:      dd  11,  34,  54,  71,  84,  88,  79,  50
                dd  28,  74,  89,  68,  17, -44, -83, -69
                dd  44,  89,  48, -41, -89, -44,  50,  81
                dd  58,  76, -34, -86,  10,  88,   6, -84
                dd  70,  39, -87,   1,  86, -44, -59,  78
                dd  79, -12, -66,  87, -35, -44,  86, -62
                dd  86, -58,  12,  38, -75,  88, -74,  40
flipadst8_mat:  dd  89, -86,  79, -70,  58, -44,  29, -14
                dd  86, -58,  12,  38, -75,  88, -74,  40
                dd  79, -12, -66,  87, -35, -44,  86, -62
                dd  70,  39, -87,   1,  86, -44, -59,  78
                dd  58,  76, -34, -86,  10,  88,   6, -84
                dd  44,  89,  48, -41, -89, -44,  50,  81
                dd  28,  74,  89,  68,  17, -44, -83, -69
                dd  11,  34,  54,  71,  84,  88,  79,  50
ddt8_mat:       dd   4,   6,  22,  57,  96, 103,  78,  56
                dd   7,  14,  48,  94,  73, -17, -79, -96
                dd  15,  36,  85,  76, -43, -80,   7,  98
                dd  33,  77,  88, -26, -69,  56,  56, -77
                dd  65, 100,   0, -73,  55,  15, -82,  54
                dd  98,  45, -86,  34,  20, -66,  79, -33
                dd 106, -57, -23,  54, -71,  75, -56,  19
flipddt8_mat:   dd  80, -98,  82, -66,  53, -41,  26,  -6
                dd 106, -57, -23,  54, -71,  75, -56,  19
                dd  98,  45, -86,  34,  20, -66,  79, -33
                dd  65, 100,   0, -73,  55,  15, -82,  54
                dd  33,  77,  88, -26, -69,  56,  56, -77
                dd  15,  36,  85,  76, -43, -80,   7,  98
                dd   7,  14,  48,  94,  73, -17, -79, -96
                dd   4,   6,  22,  57,  96, 103,  78,  56
adst4_mat:      dd  18,  50,  75,  89;  89,  75,  50,  18
flipadst4_mat:  dd  89,  75,  50,  18, -18,  50,  75, -89

pw_181x32:      times 2 dw 181*32
pw_4096:        times 2 dw 4096
dconly_add:     dw 0x7c00, 0x7c00, 0x7000, 0x7000 ; 10bpc, 12bpc
pixel_max:      dw 0x03ff, 0x03ff, 0x0fff, 0x0fff
coef_min:       dd 0xfffe0000, 0xfff80000
coef_max:       dd 0x0001ffff, 0x0007ffff
pd_4:           dd 4
pd_8:           dd 8
pd_16:          dd 16
pd_17:          dd 17
pd_32:          dd 32
pd_33:          dd 33
pd_64:          dd 64
pd_128:         dd 128
pd_181:         dd 181
pd_512:         dd 512
pd_1024:        dd 1024
pd_2048:        dd 2048

%define pd_18  (adst4_mat+4*0)
%define pd_50  (adst4_mat+4*1)
%define pd_75  (adst4_mat+4*2)
%define pd_89  (adst4_mat+4*3)

%define o_base (adst4_mat + 128)
%define o(x) (r6 - o_base + (x))
%define m(x) mangle(private_prefix %+ _ %+ x %+ _avx2)

%macro ITX_JMP_TABLE 2 ; w, h
    %if %1 <= 16
        itx_%1x%2_table_p1:
        dd m(inv_txfm_add_%1x%2_16bpc).pass1_dct - o_base
        dd m(inv_txfm_add_%1x%2_16bpc).pass1_identity - o_base
        dd m(inv_txfm_add_%1x%2_16bpc).pass1_adst - o_base
        dd m(inv_txfm_add_%1x%2_16bpc).pass1_flipadst - o_base
        %if %1 >= 8
            dd m(inv_txfm_add_%1x%2_16bpc).pass1_ddt - o_base
            dd m(inv_txfm_add_%1x%2_16bpc).pass1_flipddt - o_base
        %elif %2 == 4 ; wht
            pd_35: dd 35 ; There are two unused entries, make use
            pd_83: dd 83 ; of the space to store some constants
            dd m(inv_txfm_add_%1x%2_16bpc).wht - o_base
        %endif
    %endif
    %if %2 <= 16
        itx_%1x%2_table_p2:
        dd m(inv_txfm_add_%1x%2_16bpc).pass2_dct - o_base
        dd m(inv_txfm_add_%1x%2_16bpc).pass2_identity - o_base
        dd m(inv_txfm_add_%1x%2_16bpc).pass2_adst - o_base
        dd m(inv_txfm_add_%1x%2_16bpc).pass2_flipadst - o_base
        %if %2 >= 8
            dd m(inv_txfm_add_%1x%2_16bpc).pass2_ddt - o_base
            dd m(inv_txfm_add_%1x%2_16bpc).pass2_flipddt - o_base
        %endif
    %endif
%endmacro

ITX_JMP_TABLE  4,  4
ITX_JMP_TABLE  4,  8
ITX_JMP_TABLE  4, 16
ITX_JMP_TABLE  8,  4
ITX_JMP_TABLE  8,  8
ITX_JMP_TABLE 16,  4

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

%macro INV_TXFM_FN 2 ; w, h
cglobal inv_txfm_add_%1x%2_16bpc, 4, 7, 0, dst, ds, cf, tx1, eob, bdmax, _, tx2
    lea                  r6, [o_base]
%if WIN64
    rorx               eobd, eobm, 16
%else
    shl                eobd, 16
%endif
    movifnidn        bdmaxd, bdmaxm
    shr              bdmaxd, 11
    add                eobd, tx1d
    jz .dconly
    %assign       regs_used  8
%if WIN64
    PUSH                 r7
%endif
%if %1 < 32 && %2 < 32
    movzx              tx2d, tx1b
    and                tx1d, 7
    shr                tx2d, 5
    movsxd             tx1q, [o(itx_%1x%2_table_p1)+tx1q*4]
    movsxd             tx2q, [o(itx_%1x%2_table_p2)+tx2q*4]
    add                tx1q, r6
    add                tx2q, r6
%elif %1 < 32
    and                tx1d, 7
    movsxd             tx1q, [o(itx_%1x%2_table_p1)+tx1q*4]
    add                tx1q, r6
%elif %2 < 32
    movzx              tx2d, tx1b
    shr                tx2d, 5
    movsxd             tx2q, [o(itx_%1x%2_table_p2)+tx2q*4]
    add                tx2q, r6
%endif
%endmacro

%macro WRAP_XMM 1+
    INIT_XMM cpuname
    %1
    INIT_YMM cpuname
%endmacro

%macro IDCT4_1D 1 ; rnd
    vpbroadcastd         m4, [o(pd_83)]
    vpbroadcastd         m5, [o(pd_35)]
    pmulld               m6, m1, m4
    pmulld               m4, m3
    pmulld               m3, m5
    pmulld               m5, m1
    pslld                m0, 6
    pslld                m2, 6
    paddd                m0, %1
    psubd                m1, m0, m2  ; a1
    paddd                m0, m2      ; a0
    paddd                m6, m3      ; b0
    psubd                m5, m4      ; b1
    psubd                m3, m0, m6  ; out3
    paddd                m0, m6      ; out0
    psubd                m2, m1, m5  ; out2
    paddd                m1, m5      ; out1
    ret
%endmacro

%macro IDCT8_1D_FAST 0
    vpbroadcastd         m8, [o(pd_83)]
    vpbroadcastd         m9, [o(pd_35)]
    vpbroadcastd         m6, [o(pd_89)]
    vpbroadcastd         m5, [o(pd_75)]
    vpbroadcastd         m4, [o(pd_50)]
    vpbroadcastd        m10, [o(pd_18)]
    pmulld               m8, m2      ; dct4 b0
    pmulld               m9, m2      ; dct4 b1
    pslld                m0, 6       ; dct4 a
    pmulld               m7, m6, m3
    pmulld               m6, m1
    pmulld              m12, m5, m3
    pmulld               m5, m1
    paddd                m0, m11     ; rnd
    pmulld               m2, m4, m3
    pmulld               m4, m1
    pmulld               m3, m10
    pmulld              m10, m1
    paddd                m6, m12     ; b0
    psubd                m5, m3      ; b1
    psubd                m4, m7      ; b2
    psubd               m10, m2      ; b3
%endmacro

%macro IDCT8_1D 0
    vpbroadcastd        m10, [o(pd_83)]
    vpbroadcastd         m8, [o(pd_35)]
    pmulld               m9, m8, m2
    pmulld               m2, m10
    pmulld               m8, m6
    pmulld               m6, m10
    pslld                m0, 6
    pslld                m4, 6
    paddd                m0, m11     ; rnd
    paddd                m8, m2      ; dct4 b0
    psubd                m9, m6      ; dct4 b1
    vpbroadcastd        m10, [o(pd_75)]
    vpbroadcastd         m6, [o(pd_89)]
    psubd                m2, m0, m4  ; dct4 a1
    paddd                m0, m4      ; dct4 a0
    pmulld              m14, m10, m3
    pmulld               m4, m6, m1
    paddd               m14, m4
    pmulld              m12, m10, m1
    pmulld               m4, m6, m5
    psubd               m12, m4
    pmulld              m13, m10, m7
    pmulld               m4, m6, m3
    psubd               m13, m4
    vpbroadcastd         m4, [o(pd_50)]
    pmulld              m10, m5
    pmulld               m6, m7
    psubd               m10, m6
    pmulld               m6, m4, m5
    paddd               m14, m6
    pmulld               m6, m4, m7
    psubd               m12, m6
    pmulld               m6, m4, m1
    paddd               m13, m6
    vpbroadcastd         m6, [o(pd_18)]
    pmulld               m4, m3
    psubd               m10, m4
    pmulld               m7, m6
    pmulld               m3, m6
    pmulld               m5, m6
    pmulld               m1, m6
    paddd                m6, m14, m7 ; b0
    paddd                m4, m13, m5 ; b2
    psubd                m5, m12, m3 ; b1
    paddd               m10, m1      ; b3
%endmacro

%macro IDCT16_ODDHALF_1D_4ROWS_FAST 0
%if mmsize == 16
    SWAP 0, 5
    SWAP 2, 7
%endif
    vpbroadcastd         m8, [r3+4* 0]
    vpbroadcastd         m9, [r3+4* 8]
    vpbroadcastd         m4, [r3+4*15]
    vpbroadcastd        m11, [r3+4* 7]
    vpbroadcastd         m0, [r3+4* 1]
    vpbroadcastd         m2, [r3+4* 9]
    vpbroadcastd        m10, [r3+4*14]
    vpbroadcastd         m6, [r3+4* 6]
    REPX     {pmulld x, m1}, m8, m9, m4, m11
    REPX     {pmulld x, m3}, m0, m2, m10, m6
    paddd                m8, m0
    vpbroadcastd         m0, [r3+4* 2]
    paddd                m9, m2
    vpbroadcastd         m2, [r3+4*10]
    psubd               m10, m4
    vpbroadcastd         m4, [r3+4*13]
    psubd               m11, m6
    vpbroadcastd         m6, [r3+4* 5]
    REPX     {pmulld x, m5}, m0, m2, m4, m6
    paddd                m8, m0
    vpbroadcastd         m0, [r3+4* 3]
    paddd                m9, m2
    vpbroadcastd         m2, [r3+4*11]
    psubd               m10, m4
    vpbroadcastd         m4, [r3+4*12]
    paddd               m11, m6
    vpbroadcastd         m6, [r3+4* 4]
    REPX     {pmulld x, m7}, m0, m2, m4, m6
    paddd                m8, m0
    paddd                m9, m2
    paddd               m10, m4
    psubd               m11, m6
    ret
%endmacro

%macro IDCT16_ODDHALF_1D_4ROWS 0
%if mmsize == 16
    SWAP 0, 5
    SWAP 2, 7
%endif
    vpbroadcastd        m13, [r3+4* 0]
    vpbroadcastd        m10, [r3+4* 8]
    vpbroadcastd        m11, [r3+4* 1]
    vpbroadcastd        m14, [r3+4* 9]
    pmulld               m8, m13, m1 ;  a0
    pmulld              m13, m6      ; -h7
    pmulld               m9, m10, m1 ;  b0
    pmulld              m10, m6      ;  g7
    pmulld              m12, m11, m3 ;  a1
    pmulld              m11, m4      ;  h6
    paddd                m8, m12
    psubd               m11, m13
    vpbroadcastd        m13, [r3+4* 2]
    pmulld              m12, m14, m3 ;  b1
    pmulld              m14, m4      ; -g6
    paddd                m9, m12
    vpbroadcastd        m12, [r3+4*10]
    psubd               m10, m14     ; g67
    pmulld              m14, m13, m5 ;  a2
    pmulld              m13, m2      ; -h5
    paddd                m8, m14
    psubd               m11, m13
    vpbroadcastd        m13, [r3+4* 3]
    pmulld              m14, m12, m5 ;  b2
    pmulld              m12, m2      ;  g5
    paddd                m9, m14
    vpbroadcastd        m14, [r3+4*11]
    paddd               m10, m12     ; g567
    pmulld              m12, m13, m7 ;  a3
    pmulld              m13, m0      ;  h4
    paddd                m8, m12
    paddd               m11, m13
    vpbroadcastd        m13, [r3+4* 4]
    pmulld              m12, m14, m7 ;  b3
    pmulld              m14, m0      ; -g4
    paddd                m9, m12
    vpbroadcastd        m12, [r3+4*12]
    psubd               m10, m14     ; g4567
    pmulld              m14, m13, m0 ;  a4
    pmulld              m13, m7      ; -h3
    paddd                m8, m14
    psubd               m11, m13
    vpbroadcastd        m13, [r3+4* 5]
    pmulld              m14, m12, m0 ;  b4
    pmulld              m12, m7      ;  g3
    paddd                m9, m14
    vpbroadcastd        m14, [r3+4*13]
    paddd               m10, m12
    pmulld              m12, m13, m2 ;  a5
    pmulld              m13, m5      ;  h2
    paddd                m8, m12
    paddd               m11, m13
    vpbroadcastd        m13, [r3+4* 6]
    pmulld              m12, m14, m2 ;  b5
    pmulld              m14, m5      ; -g2
    paddd                m9, m12
    vpbroadcastd        m12, [r3+4*14]
    psubd               m10, m14     ; g234567
    pmulld              m14, m13, m4 ;  a6
    pmulld              m13, m3      ; -h1
    paddd                m8, m14
    psubd               m11, m13
    vpbroadcastd        m13, [r3+4* 7]
    pmulld              m14, m12, m4 ;  b6
    pmulld              m12, m3      ;  g1
    paddd                m9, m14
    vpbroadcastd        m14, [r3+4*15]
    paddd               m10, m12
    pmulld              m12, m13, m6 ;  a7
    pmulld              m13, m1      ;  h0
    paddd                m8, m12     ;  a
    paddd               m11, m13     ;  h
    pmulld              m12, m14, m6 ;  b7
    pmulld              m14, m1      ; -g0
    paddd                m9, m12     ;  b
    psubd               m10, m14     ;  g
    ret
%endmacro

%macro IDST4_1D 0
    vpbroadcastd         m5, [r3+4*0]
    vpbroadcastd         m7, [r3+4*3]
    pmulld               m8, m0, m5  ;  a0
    pmulld               m5, m3      ; -d3
    pmulld               m4, m3, m7  ;  a3
    pmulld               m7, m0      ;  d0
    vpbroadcastd         m6, [r3+4*6]
    paddd                m8, m4
    vpbroadcastd         m4, [r3+4*5]
    psubd                m7, m5
    pmulld               m5, m0, m6  ;  b0
    pmulld               m6, m3      ;  c3
    pmulld               m3, m4      ; -b3
    pmulld               m0, m4      ;  c0
    psubd                m5, m3
    vpbroadcastd         m3, [r3+4*1]
    paddd                m6, m0
    vpbroadcastd         m4, [r3+4*7]
    pmulld               m0, m1, m3  ;  a1
    pmulld               m3, m2      ;  d2
    paddd                m0, m8
    paddd                m3, m7
    pmulld               m8, m2, m4  ;  b2
    pmulld               m4, m1      ;  c1
    vpbroadcastd         m7, [r3+4*2]
    paddd                m5, m8
    vpbroadcastd         m8, [r3+4*4]
    paddd                m6, m4
    pmulld               m4, m2, m7  ;  a2
    pmulld               m7, m1      ; -d1
    pmulld               m1, m8      ;  b1
    pmulld               m2, m8      ; -c2
    paddd                m0, m4
    psubd                m3, m7
    paddd                m1, m5
    psubd                m2, m6, m2
    ret
%endmacro

%macro IWHT4_1D 0
    paddd               xm0, xm1      ; t0
    psubd               xm4, xm2, xm3 ; t2
    psubd               xm5, xm0, xm4
    psrad               xm5, 1        ; t4
    psubd               xm2, xm5, xm1 ; out2 (t1)
    psubd               xm1, xm5, xm3 ; out1 (t3)
    psubd               xm0, xm1      ; out0
    paddd               xm3, xm4, xm2 ; out3
%endmacro

INV_TXFM_FN 4, 4
    mova                xm0, [cfq+16*0]
    mova                xm1, [cfq+16*1]
    mova                xm2, [cfq+16*2]
    mova                xm3, [cfq+16*3]
    WIN64_SPILL_XMM       9
    jmp                tx1q

.pass1_dct:
    vpbroadcastd        xm7, [o(pd_64)]
    call .dct4
.pass1_end:
    vpbroadcastd        xm4, [o(coef_min)+bdmaxq*4]
    vpbroadcastd        xm5, [o(coef_max)+bdmaxq*4]
    REPX    {psrad  x, 7  }, xm0, xm1, xm2, xm3
    REPX    {pmaxsd x, xm4}, xm0, xm1, xm2, xm3
    REPX    {pminsd x, xm5}, xm0, xm1, xm2, xm3
.pass1_identity:
    punpckhdq           xm4, xm2, xm3
    punpckldq           xm2, xm3
    punpckhdq           xm3, xm0, xm1
    punpckldq           xm0, xm1
    punpckhqdq          xm1, xm0, xm2
    punpcklqdq          xm0, xm2
    punpcklqdq          xm2, xm3, xm4
    punpckhqdq          xm3, xm4
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        xm7, [o(pd_512)]
    call .dct4
.pass2_end:
    REPX      {psrad x, 10}, xm0, xm1, xm2, xm3
.pass2_end2:
    packssdw            xm0, xm1
    packssdw            xm2, xm3
.pass2_end3:
    lea                  r3, [dstq+dsq*2]
    movq                xm1, [dstq+dsq*0]
    movhps              xm1, [dstq+dsq*1]
    movq                xm3, [r3  +dsq*0]
    movhps              xm3, [r3  +dsq*1]
    vpbroadcastd        xm5, [o(pixel_max)+bdmaxq*4]
    pxor                xm4, xm4
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m4
    paddsw              xm0, xm1
    paddsw              xm2, xm3
    pmaxsw              xm0, xm4
    pmaxsw              xm2, xm4
    pminsw              xm0, xm5
    pminsw              xm2, xm5
    movq       [dstq+dsq*0], xm0
    movhps     [dstq+dsq*1], xm0
    movq       [r3  +dsq*0], xm2
    movhps     [r3  +dsq*1], xm2
    RET
ALIGN function_align
.dct4:
    WRAP_XMM IDCT4_1D xm7

.dconly:
    movd                xm2, [o(pd_17)]
    paddd               xm2, [cfq]
    mov               [cfq], r4d
    psrad               xm2, 5
.dconly2:
    vpbroadcastd        xm3, [o(dconly_add)+bdmaxq*4]
    lea                  r6, [dsq*3]
    vpbroadcastw        xm2, xm2
    paddsw              xm2, xm3
.dconly_loop:
    movq                xm0, [dstq+dsq*0]
    movhps              xm0, [dstq+dsq*1]
    movq                xm1, [dstq+dsq*2]
    movhps              xm1, [dstq+r6   ]
    paddsw              xm0, xm2
    paddsw              xm1, xm2
    psubusw             xm0, xm3
    psubusw             xm1, xm3
    movq       [dstq+dsq*0], xm0
    movhps     [dstq+dsq*1], xm0
    movq       [dstq+dsq*2], xm1
    movhps     [dstq+r6   ], xm1
    lea                dstq, [dstq+dsq*4]
    dec                 r4d
    jg .dconly_loop
    ret

.wht:
    REPX       {psrad x, 3}, xm0, xm1, xm2, xm3
    IWHT4_1D
    punpckhdq           xm4, xm2, xm3
    punpckldq           xm2, xm3
    punpckhdq           xm3, xm0, xm1
    punpckldq           xm0, xm1
    punpckhqdq          xm1, xm0, xm2
    punpcklqdq          xm0, xm2
    punpcklqdq          xm2, xm3, xm4
    punpckhqdq          xm3, xm4
    IWHT4_1D
    test               eobd, 0x300
    jz .pass2_end2
    test               eobd, 0x200
    jnz .vdpcm2
    vinserti128          m0, xm2, 1
    vinserti128          m1, xm3, 1
    jmp .hdpcm2

.pass2_identity:
    test               eobd, 0x300
    jnz .dpcm
    vpbroadcastd        xm4, [o(pw_4096)]
    packssdw            xm0, xm1
    packssdw            xm2, xm3
    pmulhrsw            xm0, xm4
    pmulhrsw            xm2, xm4
    jmp .pass2_end3
.dpcm:
    vpbroadcastd         m4, [o(pd_4)]
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    vinserti128          m0, xm2, 1
    vinserti128          m1, xm3, 1
    paddd                m0, m4
    paddd                m1, m4
    psrad                m0, 3
    psrad                m1, 3
.hdpcm2:
    pslldq               m2, m0, 4
    pslldq               m3, m1, 4
    paddd                m0, m2
    paddd                m1, m3
    pslldq               m2, m0, 8
    pslldq               m3, m1, 8
    paddd                m0, m2
    paddd                m1, m3
    packssdw             m0, m1
    vextracti128        xm2, m0, 1
    jmp .pass2_end3
.vdpcm:
    REPX     {paddd x, xm4}, xm0, xm1, xm2, xm3
    REPX     {psrad x, 3  }, xm0, xm1, xm2, xm3
.vdpcm2:
    paddd               xm1, xm0
    paddd               xm2, xm1
    paddd               xm3, xm2
    jmp .pass2_end2

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    call .dst4
    vpbroadcastd        xm4, [o(pd_64)]
    REPX     {paddd x, xm4}, xm0, xm1, xm2, xm3
    jmp .pass1_end
.pass2_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst4_mat)]
.pass2_dst:
    call .dst4
    vpbroadcastd        xm4, [o(pd_512)]
    REPX     {paddd x, xm4}, xm0, xm1, xm2, xm3
    jmp .pass2_end
ALIGN function_align
.dst4:
    WRAP_XMM IDST4_1D

INV_TXFM_FN 4, 8
    vpbroadcastd         m3, [o(pd_181)]
    pmulld               m0, m3, [cfq+32*0]
    pmulld               m1, m3, [cfq+32*1]
    pmulld               m2, m3, [cfq+32*2]
    pmulld               m3, [cfq+32*3]
    vpbroadcastd         m4, [o(pd_128)]
    REPX      {paddd x, m4}, m0, m1, m2, m3
    REPX      {psrad x, 8 }, m0, m1, m2, m3
    WIN64_SPILL_XMM      15, 16
    jmp                tx1q

.pass1_dct:
    vpbroadcastd         m9, [o(pd_64)]
    call m(inv_txfm_add_8x4_16bpc).dct4
.pass1_end:
    vpbroadcastd         m4, [o(coef_min)+bdmaxq*4]
    vpbroadcastd         m5, [o(coef_max)+bdmaxq*4]
    REPX     {psrad  x, 7 }, m0, m1, m2, m3
    REPX     {pmaxsd x, m4}, m0, m1, m2, m3
    REPX     {pminsd x, m5}, m0, m1, m2, m3
.pass1_identity:
    punpckhdq            m4, m2, m3
    punpckldq            m2, m3
    punpckhdq            m3, m0, m1
    punpckldq            m0, m1
    punpckhqdq           m1, m0, m2 ; 1 5
    punpcklqdq           m0, m2     ; 0 4
    punpcklqdq           m2, m3, m4 ; 2 6
    punpckhqdq           m3, m4     ; 3 7
    jmp                tx2q
.pass2_dct:
    vpbroadcastd       xm11, [o(pd_512)]
    vextracti128        xm4, m0, 1
    vextracti128        xm5, m1, 1
    vextracti128        xm6, m2, 1
    vextracti128        xm7, m3, 1
    call .dct8
    REPX      {psrad x, 10}, m0, m1, m2, m3
    call .write_4x8_dct
    jmp m(inv_txfm_add_8x4_16bpc).pass2_end4
.write_4x8_dct:
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
.write_4x8_dct2:
    packssdw             m0, m1     ; 0 3   1 2
    call .write_4x4_dct
    packssdw             m0, m2, m3 ; 4 7   5 6
.write_4x4_dct:
    movq                xm8, [dstq+dsq*0]
    movhps              xm8, [dstq+r3   ]
    vpbroadcastq         m9, [dstq+dsq*1]
    vpblendd             m8, m9, 0x30
    vpbroadcastq         m9, [dstq+dsq*2]
    vpblendd             m8, m9, 0xc0
    paddsw               m8, m0
    pmaxsw               m8, m12
    pminsw               m8, m13
    vextracti128        xm9, m8, 1
    movq       [dstq+dsq*0], xm8
    movhps     [dstq+r3   ], xm8
    movq       [dstq+dsq*1], xm9
    movhps     [dstq+dsq*2], xm9
    lea                dstq, [dstq+dsq*4]
    ret
ALIGN function_align
.dct8_fast:
    WRAP_XMM IDCT8_1D_FAST
    vinserti128          m2, m0, xm0, 1
    jmp .dct8b
ALIGN function_align
.dct8:
    WRAP_XMM IDCT8_1D
    vinserti128          m2, m0, xm2, 1
.dct8b:
    vinserti128          m0, m8, xm9, 1
    vinserti128          m1, m6, xm5, 1
    vinserti128          m4, m10, xm4, 1
    paddd                m3, m2, m0 ; a0   a1
    psubd                m2, m0     ; a3   a2
    paddd                m0, m3, m1 ; out0 out1
    psubd                m3, m1     ; out7 out6
    paddd                m1, m2, m4 ; out3 out2
    psubd                m2, m4     ; out4 out5
    ret

.dconly:
    imul                r3d, [cfq], 181
    mov               [cfq], r4d
    or                  r4d, 2
    add                 r3d, 4480
    sar                 r3d, 13
    movd                xm2, r3d
    jmp m(inv_txfm_add_4x4_16bpc).dconly2

.pass2_identity:
    test               eobd, 0x300
    jnz .dpcm
    vpbroadcastd         m4, [o(pw_181x32)]
    packssdw             m0, m1
    packssdw             m1, m2, m3
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    jmp .pass2_end2
.dpcm:
    vpbroadcastd         m4, [o(pd_181)]
    vpbroadcastd         m5, [o(pd_512)]
    REPX     {pmulld x, m4}, m0, m1, m2, m3
    REPX     {paddd  x, m5}, m0, m1, m2, m3
    REPX     {psrad  x, 10}, m0, m1, m2, m3
    pxor               xm12, xm12
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    vpbroadcastd       xm13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    call .write_4x8_hdpcm
    jmp m(inv_txfm_add_8x4_16bpc).pass2_end4
.vdpcm:
    paddd                m1, m0
    paddd                m2, m1
    paddd                m3, m2
    vinserti128          m4, m12, xm3, 1
    REPX      {paddd x, m4}, m0, m1, m2, m3
.pass2_end:
    packssdw             m0, m1
    packssdw             m1, m2, m3
.pass2_end2:
    vpbroadcastd       xm13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
    call .write_4x8
    jmp m(inv_txfm_add_8x4_16bpc).pass2_end4
.write_4x8_hdpcm:
    pslldq               m8, m0, 4
    pslldq               m9, m1, 4
    pslldq              m10, m2, 4
    pslldq              m11, m3, 4
    paddd                m0, m8
    paddd                m1, m9
    paddd                m2, m10
    paddd                m3, m11
    punpcklqdq           m8, m12, m0
    punpcklqdq           m9, m12, m1
    punpcklqdq          m10, m12, m2
    punpcklqdq          m11, m12, m3
    paddd                m0, m8
    paddd                m1, m9
    paddd                m2, m10
    paddd                m3, m11
    packssdw             m0, m1
    packssdw             m1, m2, m3
.write_4x8:
    call .write_4x4
    vextracti128        xm0, m0, 1
    vextracti128        xm1, m1, 1
.write_4x4:
    movq                xm8, [dstq+dsq*0]
    movhps              xm8, [dstq+dsq*1]
    movq                xm9, [dstq+dsq*2]
    movhps              xm9, [dstq+r3   ]
    paddsw              xm8, xm0
    paddsw              xm9, xm1
    pmaxsw              xm8, xm12
    pmaxsw              xm9, xm12
    pminsw              xm8, xm13
    pminsw              xm9, xm13
    movq       [dstq+dsq*0], xm8
    movhps     [dstq+dsq*1], xm8
    movq       [dstq+dsq*2], xm9
    movhps     [dstq+r3   ], xm9
    lea                dstq, [dstq+dsq*4]
    ret

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    call m(inv_txfm_add_8x4_16bpc).dst4
    vpbroadcastd         m4, [o(pd_64)]
    REPX     {paddd x,  m4}, m0, m1, m2, m3
    jmp .pass1_end
.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat+128)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat+128)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat+128)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat+128)]
.pass2_dst:
    call .dst8
    vpbroadcastd         m4, [o(pd_512)]
    REPX      {paddd x, m4}, m0, m1, m2, m3
    REPX      {psrad x, 10}, m0, m1, m2, m3
    jmp .pass2_end
ALIGN function_align
.dst8:
    mova                 m7, [r3-32*4]
    pshufd               m8, m7, q0000
    pmulld               m8, m0  ; a0 a4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; a1 a5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; a2 a6
    pshufd               m6, m7, q3333
    mova                 m7, [r3-32*3]
    pmulld               m6, m3  ; a3 a7
    pshufd               m9, m7, q0000
    pmulld               m9, m0  ; b0 b4
    paddd                m8, m4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; b1 b5
    paddd                m6, m5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; b2 b6
    paddd                m8, m6
    pshufd               m6, m7, q3333
    mova                 m7, [r3-32*2]
    pmulld               m6, m3  ; b3 b7
    pshufd              m10, m7, q0000
    pmulld              m10, m0  ; c0 c4
    paddd                m9, m4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; c1 c5
    paddd                m6, m5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; c2 c6
    paddd                m9, m6
    pshufd               m6, m7, q3333
    mova                 m7, [r3-32*1]
    pmulld               m6, m3  ; c3 c7
    pshufd              m11, m7, q0000
    pmulld              m11, m0  ; d0 d4
    paddd               m10, m4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; d1 d5
    paddd                m6, m5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; d2 d6
    paddd               m10, m6
    pshufd               m6, m7, q3333
    mova                 m7, [r3+32*0]
    pmulld               m6, m3  ; d3 d7
    pshufd              m12, m7, q0000
    pmulld              m12, m0  ; e0 e4
    paddd               m11, m4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; e1 e5
    paddd                m6, m5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; e2 e6
    paddd               m11, m6
    pshufd               m6, m7, q3333
    mova                 m7, [r3+32*1]
    pmulld               m6, m3  ; e3 e7
    pshufd              m13, m7, q0000
    pmulld              m13, m0  ; f0 f4
    paddd               m12, m4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; f1 f5
    paddd                m6, m5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; f2 f6
    paddd               m12, m6
    pshufd               m6, m7, q3333
    mova                 m7, [r3+32*2]
    pmulld               m6, m3  ; f3 f7
    pshufd              m14, m7, q0000
    pmulld              m14, m0  ; g0 g4
    paddd               m13, m4
    pshufd               m4, m7, q1111
    pmulld               m4, m1  ; g1 g5
    paddd                m6, m5
    pshufd               m5, m7, q2222
    pmulld               m5, m2  ; g2 g6
    paddd               m13, m6
    pshufd               m6, m7, q3333
    mova                 m7, [r3+32*3]
    pmulld               m6, m3  ; g3 g7
    paddd               m14, m4
    pshufd               m4, m7, q0000
    pmulld               m4, m0  ; h0 h4
    paddd                m6, m5
    pshufd               m5, m7, q1111
    pmulld               m5, m1  ; h1 h5
    paddd               m14, m6
    pshufd               m6, m7, q2222
    pmulld               m6, m2  ; h2 h6
    pshufd               m7, m7, q3333
    pmulld               m7, m3  ; h3 h7
    vinserti128          m0, m8, xm12, 1
    vperm2i128           m8, m12, 0x31
    paddd                m4, m5
    vinserti128          m1, m9, xm13, 1
    paddd                m7, m6
    vperm2i128           m9, m13, 0x31
    paddd                m7, m4
    vinserti128          m2, m10, xm14, 1
    paddd                m0, m8  ; out0 out4
    vperm2i128          m10, m14, 0x31
    paddd                m1, m9  ; out1 out5
    vinserti128          m3, m11, xm7, 1
    paddd                m2, m10 ; out2 out6
    vperm2i128          m11, m7, 0x31
    paddd                m3, m11 ; out3 out7
    ret

INV_TXFM_FN 8, 4
    vpbroadcastd         m4, [o(pd_181)]
    mova                xm0, [cfq+16*0]
    vinserti128          m0, [cfq+16*4], 1
    mova                xm1, [cfq+16*1]
    vinserti128          m1, [cfq+16*5], 1
    mova                xm2, [cfq+16*2]
    vinserti128          m2, [cfq+16*6], 1
    mova                xm3, [cfq+16*3]
    vinserti128          m3, [cfq+16*7], 1
    vpbroadcastd         m5, [o(pd_128)]
    REPX     {pmulld x, m4}, m0, m1, m2, m3
    REPX     {paddd  x, m5}, m0, m1, m2, m3
    REPX     {psrad  x, 8 }, m0, m1, m2, m3
    WIN64_SPILL_XMM      15, 16
    jmp                tx1q

.pass1_dct:
    vpbroadcastd       xm11, [o(pd_64)]
    vextracti128        xm4, m0, 1
    vextracti128        xm5, m1, 1
    vextracti128        xm6, m2, 1
    vextracti128        xm7, m3, 1
    call m(inv_txfm_add_4x8_16bpc).dct8
    vperm2i128           m5, m0, m2, 0x31 ; 1 5
    vinserti128          m0, xm2, 1       ; 0 4
    vperm2i128           m4, m1, m3, 0x31 ; 2 6
    vinserti128          m1, xm3, 1       ; 3 7
.pass1_end2:
    vpbroadcastd         m2, [o(coef_min)+bdmaxq*4]
    vpbroadcastd         m3, [o(coef_max)+bdmaxq*4]
    REPX     {psrad  x, 7 }, m0, m5, m4, m1
    REPX     {pmaxsd x, m2}, m0, m5, m4, m1
    REPX     {pminsd x, m3}, m0, m5, m4, m1
    punpckhdq            m2, m0, m5
    punpckldq            m0, m5
    punpckldq            m3, m4, m1
    punpckhdq            m4, m1
    punpckhqdq           m1, m0, m3
    punpcklqdq           m0, m3
    punpckhqdq           m3, m2, m4
    punpcklqdq           m2, m4
    jmp                tx2q
.pass2_dct:
    vpbroadcastd         m9, [o(pd_512)]
    call .dct4
.pass2_end:
    REPX      {psrad x, 10}, m0, m1, m2, m3
.pass2_end2:
    packssdw             m0, m1
    packssdw             m1, m2, m3
.pass2_end3:
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
    call .write_8x4
.pass2_end4:
    REPX {mova [cfq+32*x], m12}, 0, 1, 2, 3
    RET
.write_8x8_hdpcm:
    call m(inv_txfm_add_8x4_16bpc).write_8x4_hdpcm
    mova                 m0, m4
    mova                 m1, m5
    mova                 m2, m6
    mova                 m3, m7
.write_8x4_hdpcm:
    pslldq               m8, m0, 4
    pslldq               m9, m1, 4
    pslldq              m10, m2, 4
    pslldq              m11, m3, 4
    paddd                m0, m8
    paddd                m1, m9
    paddd                m2, m10
    paddd                m3, m11
    punpcklqdq           m8, m12, m0
    punpcklqdq           m9, m12, m1
    punpcklqdq          m10, m12, m2
    punpcklqdq          m11, m12, m3
    paddd                m0, m8
    paddd                m1, m9
    paddd                m2, m10
    paddd                m3, m11
    shufps              xm9, xm0, xm1, q3333
    shufps             xm11, xm2, xm3, q3333
    vpermq               m8, m9, q0022
    vpermq               m9, m9, q1133
    vpermq              m10, m11, q0022
    vpermq              m11, m11, q1133
    paddd                m0, m8
    paddd                m1, m9
    paddd                m2, m10
    paddd                m3, m11
.write_8x4_pack:
    packssdw             m0, m1
    packssdw             m1, m2, m3
.write_8x4:
    movu                xm8, [dstq+dsq*0]
    vinserti128          m8, [dstq+dsq*1], 1
    movu                xm9, [dstq+dsq*2]
    vinserti128          m9, [dstq+r3   ], 1
    vpermq               m0, m0, q3120
    vpermq               m1, m1, q3120
    paddsw               m0, m8
    paddsw               m1, m9
    pmaxsw               m0, m12
    pmaxsw               m1, m12
    pminsw               m0, m13
    pminsw               m1, m13
    movu         [dstq+dsq*0], xm0
    vextracti128 [dstq+dsq*1], m0, 1
    movu         [dstq+dsq*2], xm1
    vextracti128 [dstq+r3   ], m1, 1
    lea                dstq, [dstq+dsq*4]
    ret
.write_8x8:
    call m(inv_txfm_add_8x4_16bpc).write_8x4_pack
    packssdw             m0, m4, m5
    packssdw             m1, m6, m7
    jmp m(inv_txfm_add_8x4_16bpc).write_8x4
ALIGN function_align
.dct4:
    IDCT4_1D m9

.dconly:
    imul                r3d, [cfq], 181
    mov               [cfq], r4d
    add                 r3d, 4480
    sar                 r3d, 13
    movd                xm2, r3d
.dconly2:
    vpbroadcastd         m3, [o(dconly_add)+bdmaxq*4]
    lea                  r6, [dsq*3]
    paddsw              xm2, xm3
    vpbroadcastw         m2, xm2
.dconly_loop:
    movu                xm0, [dstq+dsq*0]
    vinserti128          m0, [dstq+dsq*1], 1
    movu                xm1, [dstq+dsq*2]
    vinserti128          m1, [dstq+r6   ], 1
    paddsw               m0, m2
    paddsw               m1, m2
    psubusw              m0, m3
    psubusw              m1, m3
    movu         [dstq+dsq*0], xm0
    vextracti128 [dstq+dsq*1], m0, 1
    movu         [dstq+dsq*2], xm1
    vextracti128 [dstq+r6   ], m1, 1
    lea                dstq, [dstq+dsq*4]
    dec                 r4d
    jg .dconly_loop
    vzeroupper
    ret

.pass1_identity:
    vpbroadcastd         m5, [o(pd_64)]
    REPX     {pmulld x, m4}, m0, m1, m2, m3
    REPX     {paddd  x, m5}, m0, m1, m2, m3
    REPX     {psrad  x, 7 }, m0, m1, m2, m3
    jmp m(inv_txfm_add_4x8_16bpc).pass1_identity ; no clipping required
.pass2_identity:
    test               eobd, 0x300
    jnz .dpcm
    vpbroadcastd         m4, [o(pw_4096)]
    packssdw             m0, m1
    packssdw             m1, m2, m3
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    jmp .pass2_end3
.dpcm:
    vpbroadcastd         m4, [o(pd_4)]
    REPX      {paddd x, m4}, m0, m1, m2, m3
    REPX      {psrad x, 3 }, m0, m1, m2, m3
    test               eobd, 0x200
    jz .hdpcm
.vdpcm:
    paddd                m1, m0
    paddd                m2, m1
    paddd                m3, m2
    jmp .pass2_end2
.hdpcm:
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    pxor               xm12, xm12
    lea                  r3, [dsq*3]
    call .write_8x4_hdpcm
    jmp .pass2_end4

.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat+128)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat+128)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat+128)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat+128)]
.pass1_dst:
    call m(inv_txfm_add_4x8_16bpc).dst8
.pass1_end:
    vpbroadcastd         m6, [o(pd_64)]
    paddd                m0, m6     ; 0 4
    paddd                m4, m6, m2 ; 2 6
    paddd                m5, m6, m1 ; 3 7
    paddd                m1, m6, m3 ; 1 5
    jmp .pass1_end2
.pass2_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst4_mat)]
.pass2_dst:
    call .dst4
    vpbroadcastd         m4, [o(pd_512)]
    REPX      {paddd x, m4}, m0, m1, m2, m3
    jmp .pass2_end
ALIGN function_align
.dst4:
    IDST4_1D

INV_TXFM_FN 8, 8
    WIN64_SPILL_XMM      15, 16
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    add                 cfq, 32*4
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    mova                 m7, [cfq+32*3]
    jmp                tx1q

.pass1_dct:
    vpbroadcastd        m11, [o(pd_64)]
    call .dct8
    jmp .pass1_end2
.pass2_dct:
    vpbroadcastd        m11, [o(pd_1024)]
    call .dct8
    REPX     {psrad  x, 11}, m0, m1, m2, m3, m4, m5, m6, m7
    jmp .pass2_end
ALIGN function_align
.dct8:
    IDCT8_1D
    psubd                m3, m0, m8  ; a3
    paddd                m0, m8      ; a0
    paddd                m1, m2, m9  ; a1
    psubd                m2, m9      ; a2
    psubd                m7, m0, m6  ; out7
    paddd                m0, m6      ; out0
    psubd                m6, m1, m5  ; out6
    paddd                m1, m5      ; out1
    psubd                m5, m2, m4  ; out5
    paddd                m2, m4      ; out2
    psubd                m4, m3, m10 ; out4
    paddd                m3, m10     ; out3
    ret

.dconly:
    movd                xm2, [o(pd_33)]
    paddd               xm2, [cfq]
    mov               [cfq], r4d
    or                  r4d, 2
    psrad               xm2, 6
    jmp m(inv_txfm_add_8x4_16bpc).dconly2

.pass1_identity:
    call .identity8
    jmp .pass1_end
.pass2_identity:
    call .identity8
    vpbroadcastd         m8, [o(pd_1024)]
    REPX     {paddd  x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    REPX     {psrad  x, 11}, m0, m1, m2, m3, m4, m5, m6, m7
    test               eobd, 0x300
    jz .pass2_end
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
    call m(inv_txfm_add_8x4_16bpc).write_8x8_hdpcm
    jmp .pass2_end2
.vdpcm:
    paddd                m1, m0
    paddd                m2, m1
    paddd                m3, m2
    paddd                m4, m3
    paddd                m5, m4
    paddd                m6, m5
    paddd                m7, m6
.pass2_end:
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
    call m(inv_txfm_add_8x4_16bpc).write_8x8
.pass2_end2:
    REPX {mova [cfq+32*x], m12}, -4, -3, -2, -1
    jmp m(inv_txfm_add_8x4_16bpc).pass2_end4
ALIGN function_align
.identity8:
    vpbroadcastd         m8, [o(pd_181)]
    REPX     {pmulld x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    ret

.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat+128)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat+128)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat+128)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat+128)]
.pass1_dst:
%if WIN64
    movaps            [cfq], xm15
%endif
    call .dst8
%if WIN64
    movaps             xm15, [cfq]
%endif
.pass1_end:
    vpbroadcastd         m8, [o(pd_64)]
    REPX     {paddd x,  m8}, m0, m1, m2, m3, m4, m5, m6, m7
.pass1_end2:
    REPX     {psrad  x, 7 }, m0, m1, m2, m3, m4, m5, m6, m7
    call .transpose_8x8_clip
    jmp                tx2q
.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat+128)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat+128)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat+128)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat+128)]
.pass2_dst:
%if WIN64
    movaps            [cfq], xm15
%endif
    call .dst8
%if WIN64
    movaps             xm15, [cfq]
%endif
    vpbroadcastd         m8, [o(pd_1024)]
    REPX     {paddd  x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    REPX     {psrad  x, 11}, m0, m1, m2, m3, m4, m5, m6, m7
    jmp .pass2_end
ALIGN function_align
.dst8:
    vpbroadcastd         m8, [r3-4*32]
    vpbroadcastd         m9, [r3-4*24]
    vpbroadcastd        m10, [r3-4*16]
    vpbroadcastd        m11, [r3-4* 8]
    vpbroadcastd        m12, [r3+4* 0]
    vpbroadcastd        m13, [r3+4* 8]
    vpbroadcastd        m14, [r3+4*16]
    vpbroadcastd        m15, [r3+4*24]
    REPX     {pmulld x, m0}, m8, m9, m10, m11, m12, m13, m14, m15
%macro IDST8_MUL_ACCUM 1 ; src
%assign %%i 8
%rep 8
    vpbroadcastd         m0, [r3+4*(%1+%%i*8-96)]
    pmulld               m0, m%1
    paddd          m %+ %%i, m0
%assign %%i %%i + 1
%endrep
%endmacro
    IDST8_MUL_ACCUM       1
    IDST8_MUL_ACCUM       2
    IDST8_MUL_ACCUM       3
    IDST8_MUL_ACCUM       4
    IDST8_MUL_ACCUM       5
    IDST8_MUL_ACCUM       6
    vpbroadcastd         m0, [r3-4*25]
    pmulld               m0, m7
    paddd                m0, m8
    vpbroadcastd         m1, [r3-4*17]
    pmulld               m1, m7
    paddd                m1, m9
    vpbroadcastd         m2, [r3-4* 9]
    pmulld               m2, m7
    paddd                m2, m10
    vpbroadcastd         m3, [r3-4* 1]
    pmulld               m3, m7
    paddd                m3, m11
    vpbroadcastd         m4, [r3+4* 7]
    pmulld               m4, m7
    paddd                m4, m12
    vpbroadcastd         m5, [r3+4*15]
    pmulld               m5, m7
    paddd                m5, m13
    vpbroadcastd         m6, [r3+4*23]
    pmulld               m6, m7
    paddd                m6, m14
    vpbroadcastd         m8, [r3+4*31]
    pmulld               m7, m8
    paddd                m7, m15
    ret
ALIGN function_align
.transpose_8x8_clip:
    vpbroadcastd         m8, [o(coef_min)+bdmaxq*4]
    vpbroadcastd         m9, [o(coef_max)+bdmaxq*4]
    REPX     {pmaxsd x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    REPX     {pminsd x, m9}, m0, m1, m2, m3, m4, m5, m6, m7
.transpose_8x8:
    punpckhdq            m8, m4, m5
    punpckldq            m4, m5
    punpckhdq            m5, m2, m3
    punpckldq            m2, m3
    punpckhdq            m3, m0, m1
    punpckldq            m0, m1
    punpckhdq            m1, m6, m7
    punpckldq            m6, m7
    punpcklqdq           m7, m4, m6
    punpckhqdq           m4, m6
    punpckhqdq           m6, m8, m1
    punpcklqdq           m8, m1
    punpckhqdq           m1, m0, m2
    punpcklqdq           m0, m2
    punpcklqdq           m2, m3, m5
    punpckhqdq           m3, m5
    vperm2i128           m5, m1, m4, 0x31
    vinserti128          m1, xm4, 1
    vperm2i128           m4, m0, m7, 0x31
    vinserti128          m0, xm7, 1
    vperm2i128           m7, m3, m6, 0x31
    vinserti128          m3, xm6, 1
    vperm2i128           m6, m2, m8, 0x31
    vinserti128          m2, xm8, 1
    ret

INV_TXFM_FN 4, 16
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*2]
    add                 cfq, 32*4
    mova                 m2, [cfq+32*0]
    mova                 m3, [cfq+32*2]
    WIN64_SPILL_XMM      15, 16
    jmp                tx1q

.pass1_dct:
    vpbroadcastd         m9, [o(pd_32)]
    lea                 r3d, [eobq+(18<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    sub                eobd, 26<<16
    jl .pass1_dct_fast
    mova                 m4, [cfq-32*3]
    mova                 m5, [cfq-32*1]
    mova                 m6, [cfq+32*1]
    mova                 m7, [cfq+32*3]
    call m(inv_txfm_add_16x4_16bpc).dct4
    REPX       {psrad x, 6}, m0, m1, m2, m3, m4, m5, m6, m7
.pass1_end:
    vpbroadcastd        m10, [o(coef_min)+bdmaxq*4]
    vpbroadcastd        m11, [o(coef_max)+bdmaxq*4]
    punpckhdq            m8, m6, m7
    punpckldq            m6, m7
    punpckhdq            m7, m4, m5
    punpckldq            m4, m5
    REPX    {pmaxsd x, m10}, m4, m6, m7, m8
    punpckhqdq           m5, m4, m6 ;  9 13
    punpcklqdq           m4, m6     ;  8 12
    punpcklqdq           m6, m7, m8 ; 10 14
    punpckhqdq           m7, m8     ; 11 15
    REPX    {pminsd x, m11}, m4, m5, m6, m7
    jmp .pass1_end2
.pass1_dct_fast:
    call m(inv_txfm_add_8x4_16bpc).dct4
.pass1_fast_end:
    REPX     {psrad  x, 6 }, m0, m1, m2, m3
.pass1_fast_end2:
    vpbroadcastd        m10, [o(coef_min)+bdmaxq*4]
    vpbroadcastd        m11, [o(coef_max)+bdmaxq*4]
.pass1_end2:
    punpckhdq            m8, m2, m3
    punpckldq            m2, m3
    punpckhdq            m3, m0, m1
    punpckldq            m0, m1
    REPX    {pmaxsd x, m10}, m0, m2, m3, m8
    punpckhqdq           m1, m0, m2 ; 1 5
    punpcklqdq           m0, m2     ; 0 4
    punpcklqdq           m2, m3, m8 ; 2 6
    punpckhqdq           m3, m8     ; 3 7
    REPX    {pminsd x, m11}, m0, m1, m2, m3
    jmp                tx2q
.pass2_dct:
    lea                  r3, [o(dct16_mat)]
    mova         [cfq-32*4], m0
    vextracti128        xm0, m1, 1 ;  5
    mova         [cfq-32*3], m2
    vextracti128        xm2, m3, 1 ;  7
    test               eobd, eobd
    jl .pass2_dct_fast
    mova         [cfq-32*2], m4
    vextracti128        xm4, m5, 1 ; 13
    mova         [cfq-32*1], m6
    vextracti128        xm6, m7, 1 ; 15
    call .dct16
    add                  r3, 4*16
    mova         [cfq+16*0], xm8   ; b0
    mova         [cfq+16*1], xm9   ; b1
    mova         [cfq+16*7], xm10  ; b6
    mova         [cfq+16*6], xm11  ; b7
    call .dct16
    mova                xm0, [cfq-16*8] ;  0
    mova                xm1, [cfq-16*6] ;  2
    mova                xm2, [cfq-16*7] ;  4
    mova                xm3, [cfq-16*5] ;  6
    mova                xm4, [cfq-16*4] ;  8
    mova                xm5, [cfq-16*2] ; 10
    mova                xm6, [cfq-16*3] ; 12
    mova                xm7, [cfq-16*1] ; 14
    mova         [cfq+16*3], xm8   ; b2
    mova         [cfq+16*2], xm9   ; b3
    mova         [cfq+16*4], xm10  ; b4
    mova         [cfq+16*5], xm11  ; b5
    vpbroadcastd       xm11, [o(pd_2048)]
    call m(inv_txfm_add_4x8_16bpc).dct8
    jmp .pass2_dct_end
.pass2_dct_fast:
    call .dct16_fast
    add                  r3, 4*16
    mova         [cfq+16*0], xm8   ; b0
    mova         [cfq+16*1], xm9   ; b1
    mova         [cfq+16*7], xm10  ; b6
    mova         [cfq+16*6], xm11  ; b7
    call .dct16_fast
    mova                xm0, [cfq-16*8] ;  0
    mova                xm1, [cfq-16*6] ;  2
    mova                xm2, [cfq-16*7] ;  4
    mova                xm3, [cfq-16*5] ;  6
    mova         [cfq+16*3], xm8   ; b2
    mova         [cfq+16*2], xm9   ; b3
    mova         [cfq+16*4], xm10  ; b4
    mova         [cfq+16*5], xm11  ; b5
    vpbroadcastd       xm11, [o(pd_2048)]
    call m(inv_txfm_add_4x8_16bpc).dct8_fast
.pass2_dct_end:
    mova                 m6, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m4, [cfq+32*2]
    mova                 m8, [cfq+32*3]
    psubd                m7, m0, m6 ; out15 out14
    paddd                m0, m6     ; out0  out1
    psubd                m6, m1, m5 ; out12 out13
    paddd                m1, m5     ; out3  out2
    psubd                m5, m2, m4 ; out11 out10
    paddd                m2, m4     ; out4  out5
    psubd                m4, m3, m8 ; out8  out9
    paddd                m3, m8     ; out7  out6
    REPX      {psrad x, 12}, m0, m1, m2, m3
    call m(inv_txfm_add_4x8_16bpc).write_4x8_dct
    psrad                m0, m4, 12
    psrad                m1, m5, 12
    psrad                m2, m6, 12
    psrad                m3, m7, 12
    call m(inv_txfm_add_4x8_16bpc).write_4x8_dct2
    jmp m(inv_txfm_add_8x8_16bpc).pass2_end2
ALIGN function_align
.dct16_fast:
    WRAP_XMM IDCT16_ODDHALF_1D_4ROWS_FAST
    ret
ALIGN function_align
.dct16:
    WRAP_XMM IDCT16_ODDHALF_1D_4ROWS
    ret

.dconly:
    movd                xm2, [o(pd_32)]
    paddd               xm2, [cfq]
    mov               [cfq], r4d
    or                  r4d, 4
    psrad               xm2, 6
    jmp m(inv_txfm_add_4x4_16bpc).dconly2

.pass1_identity:
    lea                 r3d, [eobq-(32<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    REPX       {paddd x, x}, m0, m1, m2, m3
    test               eobd, eobd
    jl .pass1_fast_end2
    mova                 m4, [cfq-32*3]
    mova                 m5, [cfq-32*1]
    mova                 m6, [cfq+32*1]
    mova                 m7, [cfq+32*3]
    REPX       {paddd x, x}, m4, m5, m6, m7
    jmp .pass1_end
.pass2_identity:
    vpbroadcastd         m8, [o(pd_8)]
    vpbroadcastd       xm13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
    REPX      {paddd x, m8}, m0, m1, m2, m3
    REPX      {psrad x, 4 }, m0, m1, m2, m3
    test               eobd, eobd
    jl .pass2_identity_fast
    REPX      {paddd x, m8}, m4, m5, m6, m7
    REPX      {psrad x, 4 }, m4, m5, m6, m7
    test               eobd, 0x300
    jz .pass2_end2
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    call m(inv_txfm_add_4x8_16bpc).write_4x8_hdpcm
    mova                 m0, m4
    mova                 m1, m5
    mova                 m2, m6
    mova                 m3, m7
    call m(inv_txfm_add_4x8_16bpc).write_4x8_hdpcm
    jmp m(inv_txfm_add_8x8_16bpc).pass2_end2
.vdpcm:
    paddd                m1, m0
    paddd                m5, m4
    paddd                m2, m1
    paddd                m6, m5
    paddd                m3, m2
    paddd                m7, m6
    vinserti128          m8, m12, xm3, 1
    vinserti128          m9, m12, xm7, 1
    REPX      {paddd x, m8}, m0, m1, m2, m3
    vperm2i128           m8, m3, m3, 0x11
    paddd                m8, m9
    REPX      {paddd x, m8}, m4, m5, m6, m7
    jmp .pass2_end2
.pass2_identity_fast:
    packssdw             m0, m1
    packssdw             m1, m2, m3
    jmp .pass2_end3
.pass2_end:
    vpbroadcastd       xm13, [o(pixel_max)+bdmaxq*4]
    lea                  r3, [dsq*3]
    pxor               xm12, xm12
.pass2_end2:
    packssdw             m0, m1
    packssdw             m1, m2, m3
    call m(inv_txfm_add_4x8_16bpc).write_4x8
    packssdw             m0, m4, m5
    packssdw             m1, m6, m7
.pass2_end3:
    call m(inv_txfm_add_4x8_16bpc).write_4x8
    jmp m(inv_txfm_add_8x8_16bpc).pass2_end2

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    call m(inv_txfm_add_8x4_16bpc).dst4
    vpbroadcastd         m9, [o(pd_32)]
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(18<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r8d
%if WIN64
    pop                  r8
%endif
    REPX      {paddd x, m9}, m0, m1, m2, m3
    sub                eobd, 26<<16
    jl .pass1_fast_end
    psrad               m10, m0, 6
    mova                 m0, [cfq-32*3]
    psrad               m11, m1, 6
    mova                 m1, [cfq-32*1]
    psrad               m12, m2, 6
    mova                 m2, [cfq+32*1]
    psrad               m13, m3, 6
    mova                 m3, [cfq+32*3]
    call m(inv_txfm_add_8x4_16bpc).dst4
    REPX      {paddd x, m9}, m0, m1, m2, m3
    psrad                m4, m0, 6
    mova                 m0, m10
    psrad                m5, m1, 6
    mova                 m1, m11
    psrad                m6, m2, 6
    mova                 m2, m12
    psrad                m7, m3, 6
    mova                 m3, m13
    jmp .pass1_end
.pass2_flipddt:
    lea                  r3, [o(flipddt16_mat)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt16_mat)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst16_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst16_mat)]
.pass2_dst:
    call .pass2_dst_main
    mova         [cfq-32*4], m8
    mova         [cfq-32*3], m9
    call .pass2_dst_main
    mova         [cfq-32*2], m8
    mova         [cfq-32*1], m9
    call .pass2_dst_main
    mova         [cfq+32*0], m8
    mova         [cfq+32*1], m9
    call .pass2_dst_main
    vpbroadcastd         m7, [o(pd_2048)]
    paddd                m0, m7, [cfq-32*4]
    paddd                m1, m7, [cfq-32*2]
    paddd                m2, m7, [cfq+32*0]
    paddd                m3, m8, m7
    paddd                m4, m7, [cfq-32*3]
    paddd                m5, m7, [cfq-32*1]
    paddd                m6, m7, [cfq+32*1]
    paddd                m7, m9
    REPX      {psrad x, 12}, m0, m1, m2, m3, m4, m5, m6, m7
    jmp .pass2_end
.pass2_dst_main:
    call .dst16
    vinserti128         m12, m8, xm9, 1
    vperm2i128           m8, m9, 0x31
    vinserti128          m9, m10, xm11, 1
    vperm2i128          m10, m11, 0x31
    paddd                m8, m12 ; out0  out4
    paddd                m9, m10 ; out8  out12
    ret
ALIGN function_align
.dst16: ; 4 rows
    mova                m10, [r3+32* 0]
    mova                m11, [r3+32* 8]
    mova                m12, [r3+32*16]
    mova                m13, [r3+32*24]
    pshufd               m8, m10, q0000
    pmulld               m8, m0 ; a0  a4
    pshufd               m9, m10, q1111
    pmulld               m9, m1 ; a1  a5
    pshufd              m14, m10, q2222
    pmulld              m14, m2 ; a2  a6
    pshufd              m10, m10, q3333
    pmulld              m10, m3 ; a3  a7
    paddd                m8, m9
    pshufd               m9, m11, q0000
    pmulld               m9, m0 ; b0  b4
    paddd               m14, m10
    pshufd              m10, m11, q1111
    pmulld              m10, m1 ; b1  b5
    paddd                m8, m14
    pshufd              m14, m11, q2222
    pmulld              m14, m2 ; b2  b6
    pshufd              m11, m11, q3333
    pmulld              m11, m3 ; b3  b7
    paddd                m9, m10
    pshufd              m10, m12, q0000
    pmulld              m10, m0 ; c0  c4
    paddd               m14, m11
    pshufd              m11, m12, q1111
    pmulld              m11, m1 ; c1  c5
    paddd                m9, m14
    pshufd              m14, m12, q2222
    pmulld              m14, m2 ; c2  c6
    pshufd              m12, m12, q3333
    pmulld              m12, m3 ; c3  c7
    paddd               m10, m11
    pshufd              m11, m13, q0000
    pmulld              m11, m0 ; d0  d4
    paddd               m14, m12
    pshufd              m12, m13, q1111
    pmulld              m12, m1 ; d1  d5
    paddd               m10, m14
    pshufd              m14, m13, q2222
    pmulld              m14, m2 ; d2  d6
    pshufd              m13, m13, q3333
    pmulld              m13, m3 ; d3  d7
    paddd               m11, m12
    paddd               m14, m13
    paddd               m11, m14
    test               eobd, eobd
    jl .dct16_end
    mova                m14, [r3+32* 1]
    pshufd              m12, m14, q0000
    pmulld              m12, m4 ; a8  a12
    pshufd              m13, m14, q1111
    pmulld              m13, m5 ; a9  a13
    paddd               m12, m13
    pshufd              m13, m14, q2222
    pmulld              m13, m6 ; a10 a14
    pshufd              m14, m14, q3333
    pmulld              m14, m7 ; a11 a15
    paddd               m13, m14
    mova                m14, [r3+32* 9]
    paddd                m8, m12
    pshufd              m12, m14, q0000
    pmulld              m12, m4 ; b8  b12
    paddd                m8, m13
    pshufd              m13, m14, q1111
    pmulld              m13, m5 ; b9  b13
    paddd               m12, m13
    pshufd              m13, m14, q2222
    pmulld              m13, m6 ; b10 b14
    pshufd              m14, m14, q3333
    pmulld              m14, m7 ; b11 b15
    paddd               m13, m14
    mova                m14, [r3+32*17]
    paddd                m9, m12
    pshufd              m12, m14, q0000
    pmulld              m12, m4 ; c8  c12
    paddd                m9, m13
    pshufd              m13, m14, q1111
    pmulld              m13, m5 ; c9  c13
    paddd               m12, m13
    pshufd              m13, m14, q2222
    pmulld              m13, m6 ; c10 c14
    pshufd              m14, m14, q3333
    pmulld              m14, m7 ; c11 c15
    paddd               m13, m14
    mova                m14, [r3+32*25]
    paddd               m10, m12
    pshufd              m12, m14, q0000
    pmulld              m12, m4 ; d8  d12
    paddd               m10, m13
    pshufd              m13, m14, q1111
    pmulld              m13, m5 ; d9  d13
    paddd               m12, m13
    pshufd              m13, m14, q2222
    pmulld              m13, m6 ; d10 d14
    pshufd              m14, m14, q3333
    pmulld              m14, m7 ; d11 d15
    paddd               m13, m14
    paddd               m11, m12
    paddd               m11, m13
.dct16_end:
    add                  r3, 32*2
    ret

INV_TXFM_FN 16, 4
    add                 cfq, 32*4
    WIN64_SPILL_XMM      15, 16
    jmp                tx1q

.pass1_dct:
    mova                xm1, [cfq-16*7] ;  1
    mova                xm3, [cfq-16*5] ;  3
    mova                xm0, [cfq-16*3] ;  5
    mova                xm2, [cfq-16*1] ;  7
    lea                 r3d, [eobq+(3<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r3d
    lea                  r3, [o(dct16_mat)]
    sub                eobd, 32<<16
    jl .pass1_dct_fast
    mova                xm5, [cfq+16*1] ;  9
    mova                xm7, [cfq+16*3] ; 11
    mova                xm4, [cfq+16*5] ; 13
    mova                xm6, [cfq+16*7] ; 15
    call m(inv_txfm_add_4x16_16bpc).dct16
    add                  r3, 4*16
    mova         [cfq-16*7], xm8   ; b0
    mova         [cfq-16*5], xm9   ; b1
    mova         [cfq-16*1], xm10  ; b6
    mova         [cfq-16*3], xm11  ; b7
    call m(inv_txfm_add_4x16_16bpc).dct16
    mova                xm0, [cfq-16*8] ;  0
    mova                xm1, [cfq-16*6] ;  2
    mova                xm2, [cfq-16*4] ;  4
    mova                xm3, [cfq-16*2] ;  6
    mova                xm4, [cfq+16*0] ;  8
    mova                xm5, [cfq+16*2] ; 10
    mova                xm6, [cfq+16*4] ; 12
    mova                xm7, [cfq+16*6] ; 14
    mova         [cfq+16*1], xm8   ; b2
    mova         [cfq+16*0], xm9   ; b3
    mova         [cfq+16*2], xm10  ; b4
    mova         [cfq+16*3], xm11  ; b5
    vpbroadcastd       xm11, [o(pd_32)]
    call m(inv_txfm_add_4x8_16bpc).dct8
    jmp .pass1_dct_end
.pass1_dct_fast:
    call m(inv_txfm_add_4x16_16bpc).dct16_fast
    add                  r3, 4*16
    mova         [cfq-16*7], xm8   ; b0
    mova         [cfq-16*5], xm9   ; b1
    mova         [cfq-16*1], xm10  ; b6
    mova         [cfq-16*3], xm11  ; b7
    call m(inv_txfm_add_4x16_16bpc).dct16_fast
    mova                xm0, [cfq-16*8] ;  0
    mova                xm1, [cfq-16*6] ;  2
    mova                xm2, [cfq-16*4] ;  4
    mova                xm3, [cfq-16*2] ;  6
    mova         [cfq+16*1], xm8   ; b2
    mova         [cfq+16*0], xm9   ; b3
    mova         [cfq+16*2], xm10  ; b4
    mova         [cfq+16*3], xm11  ; b5
    vpbroadcastd       xm11, [o(pd_32)]
    call m(inv_txfm_add_4x8_16bpc).dct8_fast
.pass1_dct_end:
    mova                xm6, [cfq-16*7]
    vinserti128          m6, [cfq-16*5], 1
    mova                 m8, [cfq+32*0]
    mova                 m4, [cfq+32*1]
    mova                xm5, [cfq-16*3]
    vinserti128          m5, [cfq-16*1], 1
    psubd                m7, m2, m4 ; out11 out10
    paddd                m4, m2     ; out4  out5
    paddd                m2, m1, m8 ; out3  out2
    psubd                m1, m8     ; out12 out13
    psubd                m8, m0, m6 ; out15 out14
    paddd                m0, m6     ; out0  out1
    paddd                m6, m3, m5 ; out7  out6
    psubd                m3, m5     ; out8  out9
    vperm2i128           m5, m4, m1, 0x31 ;  5 13
    vinserti128          m4, xm1, 1       ;  4 12
    vperm2i128           m1, m0, m3, 0x31 ;  1  9
    vinserti128          m0, xm3, 1       ;  0  8
    vinserti128          m3, m2, xm7, 1   ;  3 11
    vperm2i128           m2, m7, 0x31     ;  2 10
    vinserti128          m7, m6, xm8, 1   ;  7 15
    vperm2i128           m6, m8, 0x31     ;  6 14
.pass1_end:
    REPX       {psrad x, 6}, m0, m1, m2, m3, m4, m5, m6, m7
    jmp m(inv_txfm_add_4x16_16bpc).pass1_end
.pass2_dct:
    vpbroadcastd         m9, [o(pd_2048)]
    call .dct4
    REPX     {psrad  x, 12}, m0, m1, m2, m3
.pass2_end:
    REPX     {psrad  x, 12}, m4, m5, m6, m7
.pass2_end2:
    vpbroadcastd         m8, [o(pd_16)]
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    pxor               xm12, xm12
    call .write_16x4
    jmp m(inv_txfm_add_8x8_16bpc).pass2_end2
ALIGN function_align
.dct4:
    vpbroadcastd        m12, [o(pd_83)]
    vpbroadcastd        m13, [o(pd_35)]
    pmulld               m8, m1, m12
    pmulld              m11, m5, m12
    pmulld              m10, m3, m12
    pmulld              m12, m7
    REPX    {pmulld x, m13}, m3, m7, m1, m5
    REPX    {pslld  x, 6  }, m0, m2, m4, m6
    paddd                m0, m9      ; rnd
    paddd                m4, m9
    paddd                m8, m3      ; b0
    paddd               m11, m7
    psubd                m1, m10     ; b1
    psubd                m5, m12
    psubd               m10, m0, m2  ; a1
    psubd               m12, m4, m6
    paddd                m0, m2      ; a0
    paddd                m4, m6
    psubd                m2, m10, m1 ; out2
    psubd                m6, m12, m5
    paddd                m1, m10     ; out1
    paddd                m5, m12
    psubd                m3, m0, m8  ; out3
    psubd                m7, m4, m11
    paddd                m0, m8      ; out0
    paddd                m4, m11
    ret

.dconly:
    movd                xm4, [o(pd_32)]
    paddd               xm4, [cfq]
    mov               [cfq], r4d
    psrad               xm4, 6
.dconly2:
    vpbroadcastd         m5, [o(dconly_add)+bdmaxq*4]
    lea                  r6, [dsq*3]
    paddsw              xm4, xm5
    vpbroadcastw         m4, xm4
.dconly_loop:
    paddsw               m0, m4, [dstq+dsq*0]
    paddsw               m1, m4, [dstq+dsq*1]
    paddsw               m2, m4, [dstq+dsq*2]
    paddsw               m3, m4, [dstq+r6   ]
    REPX    {psubusw x, m5}, m0, m1, m2, m3
    movu       [dstq+dsq*0], m0
    movu       [dstq+dsq*1], m1
    movu       [dstq+dsq*2], m2
    movu       [dstq+r6   ], m3
    lea                dstq, [dstq+dsq*4]
    dec                 r4d
    jg .dconly_loop
    vzeroupper
    ret

.pass1_identity:
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [cfq+16*0], 1
    mova                xm1, [cfq-16*7]
    vinserti128          m1, [cfq+16*1], 1
    mova                xm2, [cfq-16*6]
    vinserti128          m2, [cfq+16*2], 1
    mova                xm3, [cfq-16*5]
    vinserti128          m3, [cfq+16*3], 1
    REPX       {pslld x, 2}, m0, m1, m2, m3
    mova                xm4, [cfq-16*4]
    vinserti128          m4, [cfq+16*4], 1
    mova                xm5, [cfq-16*3]
    vinserti128          m5, [cfq+16*5], 1
    mova                xm6, [cfq-16*2]
    vinserti128          m6, [cfq+16*6], 1
    mova                xm7, [cfq-16*1]
    vinserti128          m7, [cfq+16*7], 1
    REPX       {pslld x, 2}, m4, m5, m6, m7
    jmp m(inv_txfm_add_4x16_16bpc).pass1_end
.pass2_identity:
    vpbroadcastd         m8, [o(pd_16)]
    REPX      {paddd x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    REPX      {psrad x, 5 }, m0, m1, m2, m3, m4, m5, m6, m7
    test               eobd, 0x300
    jz .pass2_end2
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    vpbroadcastd        m13, [o(pixel_max)+bdmaxq*4]
    pxor               xm12, xm12
    call .write_16x4_hdpcm
    jmp m(inv_txfm_add_8x8_16bpc).pass2_end2
.vdpcm:
    paddd                m1, m0
    paddd                m5, m4
    paddd                m2, m1
    paddd                m6, m5
    paddd                m3, m2
    paddd                m7, m6
    jmp .pass2_end2
.write_16x4_hdpcm:
    call .write_16x2_hdpcm
    mova                 m0, m2
    mova                 m1, m3
    mova                 m4, m6
    mova                 m5, m7
.write_16x2_hdpcm:
    pslldq               m8, m0, 4
    pslldq               m9, m1, 4
    palignr             m10, m4, m0, 12
    palignr             m11, m5, m1, 12
    paddd                m0, m8
    paddd                m1, m9
    paddd                m4, m10
    paddd                m5, m11
    punpcklqdq           m8, m12, m0
    punpcklqdq           m9, m12, m1
    shufpd              m10, m0, m4, 0x05
    shufpd              m11, m1, m5, 0x05
    paddd                m0, m8
    paddd                m1, m9
    paddd                m4, m10
    paddd                m5, m11
    paddd               xm9, xm0, xm4
    paddd               xm8, xm1, xm5
    shufps              xm9, xm8, q3333
    vpermq               m8, m9, q0022
    vpermq               m9, m9, q1133
    paddd                m0, m8
    paddd                m1, m9
    paddd                m4, m0
    paddd                m5, m1
.write_16x2_pack:
    packssdw             m0, m4
    packssdw             m1, m5
.write_16x2:
    paddsw               m0, [dstq+dsq*0]
    paddsw               m1, [dstq+dsq*1]
    pmaxsw               m0, m12
    pmaxsw               m1, m12
    pminsw               m0, m13
    pminsw               m1, m13
    movu       [dstq+dsq*0], m0
    movu       [dstq+dsq*1], m1
    lea                dstq, [dstq+dsq*2]
    ret
.write_16x4:
    call .write_16x2_pack
    packssdw             m0, m2, m6
    packssdw             m1, m3, m7
    jmp .write_16x2

.pass1_flipddt:
    lea                  r3, [o(flipddt16_mat)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt16_mat)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst16_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst16_mat)]
.pass1_dst:
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [cfq-16*4], 1
    mova                xm1, [cfq-16*7]
    vinserti128          m1, [cfq-16*3], 1
    mova                xm2, [cfq-16*6]
    vinserti128          m2, [cfq-16*2], 1
    mova                xm3, [cfq-16*5]
    vinserti128          m3, [cfq-16*1], 1
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(3<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r8d
%if WIN64
    pop                  r8
%endif
    sub                eobd, 32<<16
    jl .pass1_dst2
    mova                xm4, [cfq+16*0]
    vinserti128          m4, [cfq+16*4], 1
    mova                xm5, [cfq+16*1]
    vinserti128          m5, [cfq+16*5], 1
    mova                xm6, [cfq+16*2]
    vinserti128          m6, [cfq+16*6], 1
    mova                xm7, [cfq+16*3]
    vinserti128          m7, [cfq+16*7], 1
.pass1_dst2:
    call .pass1_dst_main
    mova         [cfq-32*4], m8
    mova         [cfq-32*3], m9
    call .pass1_dst_main
    mova         [cfq-32*2], m8
    mova         [cfq-32*1], m9
    call .pass1_dst_main
    mova         [cfq+32*0], m8
    mova         [cfq+32*1], m9
    call .pass1_dst_main
    vpbroadcastd         m7, [o(pd_32)]
    paddd                m0, m7, [cfq-32*4]
    paddd                m1, m7, [cfq-32*2]
    paddd                m2, m7, [cfq+32*0]
    paddd                m3, m8, m7
    paddd                m4, m7, [cfq-32*3]
    paddd                m5, m7, [cfq-32*1]
    paddd                m6, m7, [cfq+32*1]
    paddd                m7, m9
    jmp .pass1_end
.pass1_dst_main:
    call m(inv_txfm_add_4x16_16bpc).dst16
    vinserti128         m12, m8, xm10, 1
    vperm2i128           m8, m10, 0x31
    vinserti128         m10, m9, xm11, 1
    vperm2i128           m9, m11, 0x31
    paddd                m8, m12 ; out0  out8
    paddd                m9, m10 ; out4  out12
    ret
.pass2_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst4_mat)]
.pass2_dst:
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    call m(inv_txfm_add_8x4_16bpc).dst4
    vpbroadcastd         m9, [o(pd_2048)]
    paddd               m10, m9, m0
    mova                 m0, [cfq-32*4]
    paddd               m11, m9, m1
    mova                 m1, [cfq-32*3]
    paddd               m12, m9, m2
    mova                 m2, [cfq-32*2]
    paddd               m13, m9, m3
    mova                 m3, [cfq-32*1]
    call m(inv_txfm_add_8x4_16bpc).dst4
    paddd                m4, m9, m0
    psrad                m0, m10, 12
    paddd                m5, m9, m1
    psrad                m1, m11, 12
    paddd                m6, m9, m2
    psrad                m2, m12, 12
    paddd                m7, m9, m3
    psrad                m3, m13, 12
    jmp .pass2_end
