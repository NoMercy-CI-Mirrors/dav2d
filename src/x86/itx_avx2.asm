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

adst16_mat:
dw   8,  41,  25,  55,  67,  84,  77,  88,  89,  81,  87,  73,  62,  33,  48,  17
dw  17,  73,  48,  87,  88,  55,  77,  25,  -8, -67, -41, -84, -89, -62, -81, -33
dw  25,  88,  67,  81,  48, -48,   0, -81, -88, -25, -67,  25,  67,  81,  88,  48
dw  33,  84,  81,  41, -25, -87, -77, -48,  17,  88,  73,  55,  -8, -89, -67, -62
dw  41,  62,  88, -17, -81,  -8, -77,  67,  87, -48,  33, -89, -55,  84,  25,  73
dw  48,  25,  88, -67, -81,  81,   0,  67, -25, -48, -88,  48,  88, -67,  25, -81
dw  55, -17,  81, -89, -25,  62,  77, -48, -84,  88,   8,  33, -73,  41, -67,  87
dw  62, -55,  67, -73,  48, -41,  77, -81,  33, -25,  84, -87,  17,  -8,  88, -89
dw  67, -81,  48, -25,  88, -88,   0,  25,  81, -67, -48,  67,  48, -25, -81,  88
dw  73, -89,  25,  33,  67, -17, -77,  88, -41,  81, -62,   8, -87,  55,  48, -84
dw  77, -77,   0,  77,   0,  77, -77,   0, -77,   0,  77, -77,  77, -77,   0,  77
dw  81, -48, -25,  88, -67,  67,   0, -88,  48, -81,  25,  81, -25,  88, -48, -67
dw  84,  -8, -48,  62, -88, -33,  77, -25,  73,  67, -89, -17, -41, -87,  81,  55
dw  87,  33, -67,   8, -48, -89,  77,  81, -55,  25,  17, -62,  84,  73, -88, -41
dw  88,  67, -81, -48,  25, -25,   0,  48, -67, -88,  81,  88, -81, -48,  67,  25
dw  89,  87, -88, -84,  81,  73, -77, -67,  62,  48, -55, -41,  33,  17, -25,  -8
flipadst16_mat:
dw  89,  87,  88,  84,  81,  73,  77,  67,  62,  48,  55,  41,  33,  17,  25,   8
dw  88,  67,  81,  48,  25, -25,   0, -48, -67, -88, -81, -88, -81, -48, -67, -25
dw  87,  33,  67,  -8, -48, -89, -77, -81, -55,  25, -17,  62,  84,  73,  88,  41
dw  84,  -8,  48, -62, -88, -33, -77,  25,  73,  67,  89,  17, -41, -87, -81, -55
dw  81, -48,  25, -88, -67,  67,   0,  88,  48, -81, -25, -81, -25,  88,  48,  67
dw  77, -77,   0, -77,   0,  77,  77,   0, -77,   0, -77,  77,  77, -77,   0, -77
dw  73, -89, -25, -33,  67, -17,  77, -88, -41,  81,  62,  -8, -87,  55, -48,  84
dw  67, -81, -48,  25,  88, -88,   0, -25,  81, -67,  48, -67,  48, -25,  81, -88
dw  62, -55, -67,  73,  48, -41, -77,  81,  33, -25, -84,  87,  17,  -8, -88,  89
dw  55, -17, -81,  89, -25,  62, -77,  48, -84,  88,  -8, -33, -73,  41,  67, -87
dw  48,  25, -88,  67, -81,  81,   0, -67, -25, -48,  88, -48,  88, -67, -25,  81
dw  41,  62, -88,  17, -81,  -8,  77, -67,  87, -48, -33,  89, -55,  84, -25, -73
dw  33,  84, -81, -41, -25, -87,  77,  48,  17,  88, -73, -55,  -8, -89,  67,  62
dw  25,  88, -67, -81,  48, -48,   0,  81, -88, -25,  67, -25,  67,  81, -88, -48
dw  17,  73, -48, -87,  88,  55, -77, -25,  -8, -67,  41,  84, -89, -62,  81,  33
dw   8,  41, -25, -55,  67,  84, -77, -88,  89,  81, -87, -73,  62,  33, -48, -17
ddt16_mat:
dw  12,  37,  17,  45,  47,  64,  60,  82,  89,  92, 100,  84,  69,  51,  50,  44
dw  15,  49,  23,  60,  60,  70,  74,  73,  48, -35,   9, -71, -83, -89, -79, -95
dw  19,  60,  30,  69,  61,  40,  64,   3, -53, -91, -99, -46,   2,  73,  47, 124
dw  23,  69,  38,  73,  49, -19,  28, -80, -96,  42, -45,  88,  75, -17,  14,-126
dw  30,  75,  48,  66,  19, -79, -31, -91,  -5,  71,  84, -16, -78, -45, -60, 108
dw  39,  75,  61,  40, -29, -78, -87,  10,  89, -69,  36, -67,  18,  89,  67, -81
dw  51,  61,  76,  -8, -77,  11, -82,  94,  16, -22, -81,  79,  50,-103, -37,  54
dw  66,  29,  87, -65, -83,  92,   4,  18, -83,  85,   4, -22, -85,  97,  -6, -30
dw  78, -18,  83, -91, -16,  28,  88, -84,  12, -60,  73, -46,  81, -83,  49,  16
dw  88, -67,  59, -57,  75, -85,  54,  -5,  75, -17, -60,  84, -43,  71, -80,  -6
dw  94, -96,  19,  21,  93, -41, -55,  80, -51,  77, -17, -68,  -6, -56,  98,   1
dw  97, -83, -30,  86,   3,  82, -77, -17, -43, -70,  76,  15,  53,  44, -99,   3
dw  93, -28, -73,  81, -92,  39,  29, -70,  81,  11, -55,  46, -81, -31,  90,  -4
dw  83,  40, -99,   8, -74, -83,  88,  47, -14,  56, -21, -83,  88,  22, -71,   5
dw  68,  84, -99, -69,  32, -37,   3,  55, -75, -83,  81,  82, -69, -11,  48,  -3
flipddt16_mat:
dw  50,  83, -76, -90,  97,  83, -86, -68,  67,  49, -56, -40,  32,   5, -19,   2
dw  68,  84, -99, -69,  32, -37,   3,  55, -75, -83,  81,  82, -69, -11,  48,  -3
dw  83,  40, -99,   8, -74, -83,  88,  47, -14,  56, -21, -83,  88,  22, -71,   5
dw  93, -28, -73,  81, -92,  39,  29, -70,  81,  11, -55,  46, -81, -31,  90,  -4
dw  97, -83, -30,  86,   3,  82, -77, -17, -43, -70,  76,  15,  53,  44, -99,   3
dw  94, -96,  19,  21,  93, -41, -55,  80, -51,  77, -17, -68,  -6, -56,  98,   1
dw  88, -67,  59, -57,  75, -85,  54,  -5,  75, -17, -60,  84, -43,  71, -80,  -6
dw  78, -18,  83, -91, -16,  28,  88, -84,  12, -60,  73, -46,  81, -83,  49,  16
dw  66,  29,  87, -65, -83,  92,   4,  18, -83,  85,   4, -22, -85,  97,  -6, -30
dw  51,  61,  76,  -8, -77,  11, -82,  94,  16, -22, -81,  79,  50,-103, -37,  54
dw  39,  75,  61,  40, -29, -78, -87,  10,  89, -69,  36, -67,  18,  89,  67, -81
dw  30,  75,  48,  66,  19, -79, -31, -91,  -5,  71,  84, -16, -78, -45, -60, 108
dw  23,  69,  38,  73,  49, -19,  28, -80, -96,  42, -45,  88,  75, -17,  14,-126
dw  19,  60,  30,  69,  61,  40,  64,   3, -53, -91, -99, -46,   2,  73,  47, 124
dw  15,  49,  23,  60,  60,  70,  74,  73,  48, -35,   9, -71, -83, -89, -79, -95
dw  12,  37,  17,  45,  47,  64,  60,  82,  89,  92, 100,  84,  69,  51,  50,  44
dct32_mat:
dw  90,  88,  90,  85,  82,  73,  78,  67,  47,  61,  39,  54,  13,  30,   4,  22
dw  90,  67,  82,  47,  22, -30,  -4, -54, -90, -73, -88, -85, -39, -78, -13, -61
dw  88,  30,  67, -13, -54, -90, -82, -78,  39, -47,  73,  -4,  61,  90,  22,  85
dw  85, -13,  47, -67, -90, -22, -73,  39,  54,  82,  -4,  88, -78, -61, -30, -90
dw  82, -54,  22, -90, -61,  78,  13,  85, -90,  30, -67, -47,  88,   4,  39,  73
dw  78, -82,  -4, -73,  13,  67,  85, -22,  30, -88,  90, -61, -90,  54, -47, -39
dw  73, -90, -30, -22,  78, -39,  67, -90,  61, -13, -47,  82,  85, -88,  54,  -4
dw  67, -78, -54,  39,  85, -90, -22,   4, -88,  90, -30,  13, -73,  82, -61,  47
; The dct32 and dct16 coefficients must be adjacent in memory
dct16_mat:      dw  90,  80,  87,  70,  26,  57,   9,  43
                dw  87,   9,  57, -43, -70, -80, -26, -90
                dw  80, -70,   9, -87,  90, -26,  43,  57
                dw  70, -87, -43,   9, -80,  90, -57,  26
adst8_mat:      dw  11,  54,  34,  71,  84,  79,  88,  50
                dw  28,  89,  74,  68,  17, -83, -44, -69
                dw  44,  48,  89, -41, -89,  50, -44,  81
                dw  58, -34,  76, -86,  10,   6,  88, -84
                dw  70, -87,  39,   1,  86, -59, -44,  78
                dw  79, -66, -12,  87, -35,  86, -44, -62
                dw  86,  12, -58,  38, -75, -74,  88,  40
flipadst8_mat:  dw  89,  79, -86, -70,  58,  29, -44, -14
                dw  86,  12, -58,  38, -75, -74,  88,  40
                dw  79, -66, -12,  87, -35,  86, -44, -62
                dw  70, -87,  39,   1,  86, -59, -44,  78
                dw  58, -34,  76, -86,  10,   6,  88, -84
                dw  44,  48,  89, -41, -89,  50, -44,  81
                dw  28,  89,  74,  68,  17, -83, -44, -69
                dw  11,  54,  34,  71,  84,  79,  88,  50
ddt8_mat:       dw   4,  22,   6,  57,  96,  78, 103,  56
                dw   7,  48,  14,  94,  73, -79, -17, -96
                dw  15,  85,  36,  76, -43,   7, -80,  98
                dw  33,  88,  77, -26, -69,  56,  56, -77
                dw  65,   0, 100, -73,  55, -82,  15,  54
                dw  98, -86,  45,  34,  20,  79, -66, -33
                dw 106, -23, -57,  54, -71, -56,  75,  19
flipddt8_mat:   dw  80,  82, -98, -66,  53,  26, -41,  -6
                dw 106, -23, -57,  54, -71, -56,  75,  19
                dw  98, -86,  45,  34,  20,  79, -66, -33
                dw  65,   0, 100, -73,  55, -82,  15,  54
                dw  33,  88,  77, -26, -69,  56,  56, -77
                dw  15,  85,  36,  76, -43,   7, -80,  98
                dw   7,  48,  14,  94,  73, -79, -17, -96
                dw   4,  22,   6,  57,  96,  78, 103,  56
adst4_mat:      dw  18,  75,  50,  18,  75, -89;  89,  50
flipadst4_mat:  dw  89,  50,  75, -89,  50,  18,  18,  75

pb_14_15:       times 2 db 14, 15
pw_256:         times 2 dw 256
pw_512:         times 2 dw 512
pw_1024:        times 2 dw 1024
pw_2048:        times 2 dw 2048
pw_4096:        times 2 dw 4096
pw_53x256:      times 2 dw 53*256
pw_53x512:      times 2 dw 53*512
pw_181x4:       times 2 dw 181*4
pw_181x8:       times 2 dw 181*8
pw_181x16:      times 2 dw 181*16
pw_181x32:      times 2 dw 181*32
pw_181x128:     times 2 dw 181*128
pd_32:          dd 32
pd_64:          dd 64
pd_128:         dd 128
pd_512:         dd 512
pd_1024:        dd 1024
pd_2048:        dd 2048
pd_4096:        dd 4096

pw_64_64:       dw  64,  64
pw_64_m64:      dw  64, -64
pw_35_83:       dw  35,  83
pw_m83_35:      dw -83,  35
pw_0_83:        dw   0,  83
pw_0_35:        dw   0,  35
pw_89_75:       dw  89,  75
pw_75_m18:      dw  75, -18
pw_50_m89:      dw  50, -89
pw_18_m50:      dw  18, -50

%define pw_18_75  (adst4_mat+4*0)
%define pw_50_18  (adst4_mat+4*1)
%define pw_75_m89 (adst4_mat+4*2)
%define pw_89_50  (adst4_mat+4*3)

%define o_base (adst4_mat + 128)
%define o(x) (r6 - o_base + (x))
%define m(x) mangle(private_prefix %+ _ %+ x %+ _avx2)

%macro ITX_JMP_TABLE 2 ; w, h
    %if %1 <= 16
        itx_%1x%2_table_p1:
        dd m(inv_txfm_add_%1x%2_8bpc).pass1_dct - o_base
        dd m(inv_txfm_add_%1x%2_8bpc).pass1_identity - o_base
        dd m(inv_txfm_add_%1x%2_8bpc).pass1_adst - o_base
        dd m(inv_txfm_add_%1x%2_8bpc).pass1_flipadst - o_base
        %if %1 >= 8
            dd m(inv_txfm_add_%1x%2_8bpc).pass1_ddt - o_base
            dd m(inv_txfm_add_%1x%2_8bpc).pass1_flipddt - o_base
        %elif %2 == 4 ; wht
            pw_17: times 2 dw 17 ; There are two unused entries, make use
            pw_33: times 2 dw 33 ; of the space to store some constants
            dd m(inv_txfm_add_%1x%2_8bpc).wht - o_base
        %endif
    %endif
    %if %2 <= 16
        itx_%1x%2_table_p2:
        dd m(inv_txfm_add_%1x%2_8bpc).pass2_dct - o_base
        dd m(inv_txfm_add_%1x%2_8bpc).pass2_identity - o_base
        dd m(inv_txfm_add_%1x%2_8bpc).pass2_adst - o_base
        dd m(inv_txfm_add_%1x%2_8bpc).pass2_flipadst - o_base
        %if %2 >= 8
            dd m(inv_txfm_add_%1x%2_8bpc).pass2_ddt - o_base
            dd m(inv_txfm_add_%1x%2_8bpc).pass2_flipddt - o_base
        %endif
    %endif
%endmacro

ITX_JMP_TABLE  4,  4
ITX_JMP_TABLE  4,  8
ITX_JMP_TABLE  4, 16
ITX_JMP_TABLE  4, 32
ITX_JMP_TABLE  4, 64
ITX_JMP_TABLE  8,  4
ITX_JMP_TABLE  8,  8
ITX_JMP_TABLE  8, 16
ITX_JMP_TABLE  8, 32
ITX_JMP_TABLE  8, 64
ITX_JMP_TABLE 16,  4
ITX_JMP_TABLE 16,  8
ITX_JMP_TABLE 16, 16
ITX_JMP_TABLE 16, 32
ITX_JMP_TABLE 16, 64
ITX_JMP_TABLE 32,  4
ITX_JMP_TABLE 32,  8
ITX_JMP_TABLE 32, 16
ITX_JMP_TABLE 64,  4
ITX_JMP_TABLE 64,  8
ITX_JMP_TABLE 64, 16

SECTION .text

%macro CCTX_ROUND 1
    pcmpgtd              m4, m7, %1
    paddd                %1, m7
    paddd                %1, m4
%endmacro

INIT_YMM avx2
cglobal cctx_8bpc, 4, 4, 8, u, v, angle, sz
    vpbroadcastd         m5, [angleq+2] ; cos, -sin
    lea                  uq, [uq+szq*2]
    vpbroadcastd         m6, [angleq+0] ; sin,  cos
    lea                  vq, [vq+szq*2]
    vpbroadcastd         m7, [pd_128]
    neg                 szq
.loop:
    mova                 m3, [uq+szq*2]
    mova                 m2, [vq+szq*2]
    punpcklwd            m1, m3, m2
    punpckhwd            m3, m2
    pmaddwd              m0, m5, m1 ; a
    pmaddwd              m2, m5, m3
    pmaddwd              m1, m6     ; b
    pmaddwd              m3, m6
    REPX     {CCTX_ROUND x}, m0, m2, m1, m3
    REPX       {psrad x, 8}, m0, m2, m1, m3
    packssdw             m0, m2
    packssdw             m1, m3
    mova         [uq+szq*2], m0
    mova         [vq+szq*2], m1
    add                 szq, 16
    jl .loop
    RET

%macro INV_TXFM_FN 2 ; w, h
cglobal inv_txfm_add_%1x%2_8bpc, 4, 7, 0, dst, ds, cf, tx1, eob, tx2
    lea                  r6, [o_base]
%if WIN64
    rorx               eobd, eobm, 16
%else
    shl                eobd, 16
%endif
    add                eobd, tx1d
    jz .dconly
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

%macro IDCT4_1D_PACKED 1 ; rnd
    vpbroadcastd         m3, [o(pw_64_64)]
    punpckhwd            m4, m1, m0 ; 3 1
    vpbroadcastd         m2, [o(pw_64_m64)]
    punpcklwd            m0, m1     ; 0 2
    vpbroadcastd         m1, [o(pw_35_83)]
    pmaddwd              m3, m0     ; a0
    pmaddwd              m2, m0     ; a1
    vpbroadcastd         m0, [o(pw_m83_35)]
    pmaddwd              m1, m4     ; b0
    pmaddwd              m4, m0     ; b1
    paddd                m3, %1
    paddd                m2, %1
    paddd                m0, m3, m1 ; out0
    psubd                m3, m1     ; out3
    paddd                m1, m2, m4 ; out1
    psubd                m2, m4     ; out2
    ret
%endmacro

%macro IDCT8_1D_PACKED 0
    punpckhwd            m7, m0, m2 ; 1 5
    punpcklwd            m0, m2     ; 0 4
    punpckhwd            m2, m3, m1 ; 7 3
    punpcklwd            m1, m3, m1 ; 2 6
.dct8b:
    vpbroadcastd         m6, [o(pw_18_75)]
    vpbroadcastd         m4, [o(pw_75_m89)]
    pmaddwd              m8, m6, m7
    pmaddwd              m6, m2
    vpbroadcastd         m9, [o(pw_89_50)]
    pmaddwd              m5, m4, m7
    pmaddwd              m4, m2
    pmaddwd              m3, m9, m2
    pmaddwd              m9, m7
    psubd                m8, m3     ; b3
    vpbroadcastd         m3, [o(pw_50_18)]
    paddd                m6, m9     ; b0
    pmaddwd              m2, m3
    pmaddwd              m7, m3
    psubd                m5, m2     ; b1
    vpbroadcastd         m3, [o(pw_64_64)]
    paddd                m4, m7     ; b2
    vpbroadcastd         m2, [o(pw_64_m64)]
    pmaddwd              m3, m0     ; dct4 a0
    vpbroadcastd         m7, [o(pw_35_83)]
    pmaddwd              m2, m0     ; dct4 a1
    vpbroadcastd         m0, [o(pw_m83_35)]
    pmaddwd              m7, m1     ; dct4 b0
    pmaddwd              m0, m1     ; dct4 b1
%endmacro

%macro IDST4_1D_PACKED 0
%if WIN64 && xmm_regs_used <= 6 ; avoid xmm spills
    vpbroadcastd         m2, [r3+4*0]
    punpcklwd            m4, m0, m1
    vpbroadcastd         m3, [r3+4*3]
    punpckhwd            m5, m1, m0
    pmaddwd              m0, m2, m4
    pmaddwd              m1, m3, m5
    pmaddwd              m3, m4
    pmaddwd              m2, m5
    paddd                m0, m1
    vpbroadcastd         m1, [r3+4*1]
    psubd                m3, m2
    vpbroadcastd         m2, [r3+4*2]
    pmaddwd              m1, m4
    pmaddwd              m2, m4
    vpbroadcastd         m4, [r3+4*2]
    pmaddwd              m4, m5
    psubd                m1, m4
    vpbroadcastd         m4, [r3+4*1]
    pmaddwd              m4, m5
    paddd                m2, m4
%else
    vpbroadcastd         m4, [r3+4*0]
    punpcklwd            m3, m0, m1
    vpbroadcastd         m5, [r3+4*1]
    punpckhwd            m8, m1, m0
    vpbroadcastd         m6, [r3+4*2]
    pmaddwd              m0, m4, m3
    vpbroadcastd         m7, [r3+4*3]
    pmaddwd              m1, m5, m3
    pmaddwd              m2, m6, m3
    pmaddwd              m3, m7
    REPX    {pmaddwd x, m8}, m7, m6, m5, m4
    paddd                m0, m7
    psubd                m1, m6
    paddd                m2, m5
    psubd                m3, m4
%endif
    ret
%endmacro

%macro IDST8_1D_PACKED 0
    SWAP                  7, 8      ; reduces code size by avoiding C4 prefixes
    punpcklwd            m8, m0, m1 ; 0 2
    punpckhwd            m9, m0, m1 ; 1 3
    vpbroadcastd         m0, [r3+16*0]
    vpbroadcastd         m1, [r3+16*1]
    punpcklwd           m10, m2, m3 ; 4 6
    punpckhwd           m11, m2, m3 ; 5 7
    vpbroadcastd         m2, [r3+16*2]
    vpbroadcastd         m3, [r3+16*3]
    vpbroadcastd         m4, [r3+16*4]
    vpbroadcastd         m5, [r3+16*5]
    vpbroadcastd         m6, [r3+16*6]
    vpbroadcastd         m7, [r3+16*7]
    REPX    {pmaddwd x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
%assign %%i 1
%rep 3
    %assign %%j 0
    %assign %%k %%i+8
    %rep 8
        vpbroadcastd     m8, [r3+%%i*4+%%j*16]
        pmaddwd          m8, m%+%%k
        %if %%i == 3 && %%j == 7
            SWAP          7, 8 ; swap back on the last instruction
        %endif
        paddd        m%+%%j, m8
        %assign %%j %%j+1
    %endrep
    %assign %%i %%i+1
%endrep
    ret
%endmacro

%macro IDST16_1D_PACKED_1ROW 0
    vpbroadcastd         m0, [r3+4*0]
    vpbroadcastd         m1, [r3+4*1]
    vpbroadcastd         m8, [r3+4*2]
    vpbroadcastd         m9, [r3+4*3]
%if mmsize == 16
    pmaddwd              m0, m13
%else
    pmaddwd              m0, m10
%endif
    pmaddwd              m1, m11
    pmaddwd              m8, m12
    pmaddwd              m9, m2
    paddd                m0, m8
    vpbroadcastd         m8, [r3+4*4]
    paddd                m1, m9
    vpbroadcastd         m9, [r3+4*5]
    pmaddwd              m8, m3
    pmaddwd              m9, m4
    paddd                m0, m8
    vpbroadcastd         m8, [r3+4*6]
    paddd                m1, m9
    vpbroadcastd         m9, [r3+4*7]
    pmaddwd              m8, m5
    pmaddwd              m9, m6
    paddd                m0, m8
    paddd                m1, m9
    paddd                m0, m1
    ret
%endmacro

%macro IDST16_1D_PACKED_2ROWS_FAST 1 ; row_offset
    vpbroadcastd         m0, [r3+4*0]
    vpbroadcastd         m3, [r3+4*1]
    vpbroadcastd         m8, [r3+4*2]
    vpbroadcastd         m9, [r3+4*3]
%if mmsize == 16
    pmaddwd              m0, m13
%else
    pmaddwd              m0, m10
%endif
    pmaddwd              m3, m11
    pmaddwd              m8, m12
    vpbroadcastd         m1, [r3+4*0+32*%1]
    pmaddwd              m9, m2
    vpbroadcastd         m4, [r3+4*1+32*%1]
    paddd                m0, m8
    vpbroadcastd         m8, [r3+4*2+32*%1]
    paddd                m3, m9
    vpbroadcastd         m9, [r3+4*3+32*%1]
%if mmsize == 16
    pmaddwd              m1, m13
%else
    pmaddwd              m1, m10
%endif
    pmaddwd              m4, m11
    pmaddwd              m8, m12
    pmaddwd              m9, m2
    paddd                m1, m8
    paddd                m4, m9
    paddd                m0, m3
    paddd                m1, m4
%endmacro

%macro IWHT4_1D_PACKED 0
    punpckhqdq           m3, m0, m1 ; in1 in3
    punpcklqdq           m0, m1     ; in0 in2
    psubw                m2, m0, m3
    paddw                m0, m3
    punpckhqdq           m2, m2     ; t2 t2
    punpcklqdq           m0, m0     ; t0 t0
    psubw                m1, m0, m2
    psraw                m1, 1
    psubw                m1, m3     ; t1 t3
    psubw                m0, m1     ; ____ out0
    paddw                m2, m1     ; out3 ____
%endmacro

INIT_XMM avx2
INV_TXFM_FN 4, 4
    mova                 m0, [cfq+16*0]
    mova                 m1, [cfq+16*1]
    jmp                tx1q

.dconly:
    vpbroadcastw         m3, [cfq]
.dconly2:
    vpbroadcastd         m2, [o(pw_17)]
    paddsw               m3, m2
    psraw                m3, 5
.dconly3:
    pxor                 m2, m2
    lea                  r3, [dsq*3]
    mova              [cfq], m2
.dconly_loop:
    movd                 m0, [dstq+dsq*0]
    pinsrd               m0, [dstq+dsq*1], 1
    movd                 m1, [dstq+dsq*2]
    pinsrd               m1, [dstq+r3   ], 1
    punpcklbw            m0, m2
    punpcklbw            m1, m2
    paddw                m0, m3
    paddw                m1, m3
    packuswb             m0, m1
    movd       [dstq+dsq*0], m0
    pextrd     [dstq+dsq*1], m0, 1
    pextrd     [dstq+dsq*2], m0, 2
    pextrd     [dstq+r3   ], m0, 3
    lea                dstq, [dstq+dsq*4]
    dec                 r4d
    jg .dconly_loop
    ret

.pass1_dct:
    vpbroadcastd         m5, [o(pd_64)]
    call .dct4
.pass1_end:
    REPX       {psrad x, 7}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
.pass1_identity:
    punpckhwd            m2, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m0, m2
    punpcklwd            m0, m2
    jmp                tx2q
.pass2_dct:
    vpbroadcastd         m5, [o(pd_512)]
    call .dct4
    REPX      {psrad x, 10}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
    jmp .pass2_end
ALIGN function_align
.dct4:
    IDCT4_1D_PACKED      m5

.wht:
    psraw                m0, 3
    psraw                m1, 3
    IWHT4_1D_PACKED
    punpckhwd            m0, m1
    punpcklwd            m3, m1, m2
    punpckhdq            m1, m0, m3
    punpckldq            m0, m3
    IWHT4_1D_PACKED
    punpckhqdq           m0, m1
    punpcklqdq           m1, m2
    jmp .pass2_identity_end

.pass2_identity:
    vpbroadcastd         m2, [o(pw_4096)]
    pmulhrsw             m0, m2
    pmulhrsw             m1, m2
.pass2_identity_end:
    test               eobd, 0x300
    jz .pass2_end
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    psllq                m2, m0, 16
    psllq                m3, m1, 16
    paddw                m0, m2
    paddw                m1, m3
    psllq                m2, m0, 32
    psllq                m3, m1, 32
    jmp .dpcm_end
.vdpcm:
    pslldq               m2, m0, 8
    paddw                m1, m0
    shufpd               m3, m0, m1, 0x01
.dpcm_end:
    paddw                m0, m2
    paddw                m1, m3
.pass2_end:
    lea                  r6, [dstq+dsq*2]
    movd                 m2, [dstq+dsq*0]
    pinsrd               m2, [dstq+dsq*1], 1
    movd                 m3, [r6  +dsq*0]
    pinsrd               m3, [r6  +dsq*1], 1
    pxor                 m4, m4
    mova         [cfq+16*0], m4
    mova         [cfq+16*1], m4
    punpcklbw            m2, m4
    punpcklbw            m3, m4
    paddw                m0, m2
    paddw                m1, m3
    packuswb             m0, m1
    movd       [dstq+dsq*0], m0
    pextrd     [dstq+dsq*1], m0, 1
    pextrd     [r6  +dsq*0], m0, 2
    pextrd     [r6  +dsq*1], m0, 3
    RET

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    call .dst4
    vpbroadcastd         m4, [o(pd_64)]
    REPX      {paddd x, m4}, m0, m1, m2, m3
    jmp .pass1_end
.pass2_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst4_mat)]
.pass2_dst:
    call .dst4
    vpbroadcastd         m4, [o(pw_4096)]
    REPX       {psrad x, 7}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    jmp .pass2_end
ALIGN function_align
.dst4:
    IDST4_1D_PACKED

INIT_YMM avx2
INV_TXFM_FN 4, 8
    vpbroadcastd         m1, [o(pw_181x128)]
    pmulhrsw             m0, m1, [cfq+32*0]
    pmulhrsw             m1, [cfq+32*1]
    WIN64_SPILL_XMM      12
    jmp                tx1q

.dconly:
    vpbroadcastw        xm3, [cfq]
    vpbroadcastd        xm2, [o(pw_181x128)]
    or                  r4d, 2
    pmulhrsw            xm3, xm2
    jmp m(inv_txfm_add_4x4_8bpc).dconly2

.pass1_dct:
    vpbroadcastd        m10, [o(pd_64)]
    vpermq               m0, m0, q3120
    vpermq               m1, m1, q3120
    call m(inv_txfm_add_8x4_8bpc).dct4
.pass1_end:
    REPX       {psrad x, 7}, m0, m1, m2, m3
.pass1_end2:
    packssdw             m0, m1
    packssdw             m1, m2, m3
    punpckhwd            m2, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m0, m2
    punpcklwd            m0, m2
    vextracti128        xm2, m0, 1
    vextracti128        xm3, m1, 1
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        m10, [o(pd_512)]
    call .dct8
.pass2_end:
    psrad                m0, 10
    psrad                m1, 10
    call .write_4x4_dct_start
    psrad                m0, m2, 10
    psrad                m1, m3, 10
    call .write_4x4_dct
    jmp m(inv_txfm_add_8x4_8bpc).pass2_end3
ALIGN function_align
.write_4x4_dct_start:
    lea                  r6, [dsq*3]
    pxor                m10, m10
.write_4x4_dct:
    movd                xm8, [dstq+dsq*0]
    vpbroadcastd         m9, [dstq+dsq*1]
    packssdw             m0, m1
    movd                xm1, [dstq+r6   ]
    vpblendd             m8, m9, 0x10
    vpbroadcastd         m9, [dstq+dsq*2]
    vpblendd             m1, m9, 0x10
    punpckldq            m8, m1
    punpcklbw            m8, m10
    paddw                m0, m8
    packuswb             m0, m0
    vextracti128        xm1, m0, 1
    movd       [dstq+dsq*0], xm0
    movd       [dstq+dsq*1], xm1
    pextrd     [dstq+dsq*2], xm1, 1
    pextrd     [dstq+r6   ], xm0, 1
    lea                dstq, [dstq+dsq*4]
    ret
ALIGN function_align
.dct8:
    WRAP_XMM IDCT8_1D_PACKED
    vinserti128          m2, m3, xm2, 1
    vinserti128          m0, m7, xm0, 1
    vinserti128          m1, m6, xm5, 1
    vinserti128          m4, m8, xm4, 1
    paddd                m2, m10    ; round
    paddd                m3, m2, m0 ; a0   a1
    psubd                m2, m0     ; a3   a2
.dct8c:
    paddd                m0, m3, m1 ; out0 out1
    psubd                m3, m1     ; out7 out6
    paddd                m1, m2, m4 ; out3 out2
    psubd                m2, m4     ; out4 out5
    ret

.pass1_identity:
    punpckhwd            m2, m0, m1
    punpcklwd            m0, m1
    vextracti128        xm3, m0, 1
    vextracti128        xm4, m2, 1
    punpckhwd           xm1, xm0, xm3
    punpcklwd           xm0, xm3
    punpckhwd           xm3, xm2, xm4
    punpcklwd           xm2, xm4
    jmp                tx2q
.pass2_identity:
    vpbroadcastd         m4, [o(pw_181x32)]
    lea                  r6, [dsq*3]
    pxor               xm10, xm10
    test               eobd, 0x100
    jnz .hdpcm
    pmulhrsw            xm0, xm4
    pmulhrsw            xm1, xm4
    test               eobd, 0x200
    jnz .vdpcm
    call .write_4x4
    pmulhrsw            xm0, xm4, xm2
    pmulhrsw            xm1, xm4, xm3
    call .write_4x4
    jmp m(inv_txfm_add_8x4_8bpc).pass2_end3
.hdpcm:
    vinserti128          m0, xm2, 1
    vinserti128          m1, xm3, 1
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    call .write_4x8_hdpcm
    jmp m(inv_txfm_add_8x4_8bpc).pass2_end3
.vdpcm:
    pmulhrsw            xm2, xm4
    pmulhrsw            xm3, xm4
    punpcklqdq          xm4, xm10, xm0
    paddw               xm1, xm0
    shufpd              xm5, xm0, xm1, 0x01
    paddw               xm2, xm1
    paddw               xm0, xm4
    shufpd              xm4, xm1, xm2, 0x01
    paddw               xm3, xm2
    paddw               xm1, xm5
    shufpd              xm5, xm2, xm3, 0x01
    call .write_4x4
    paddw               xm0, xm2, xm4
    paddw               xm1, xm3, xm5
    call .write_4x4
    jmp m(inv_txfm_add_8x4_8bpc).pass2_end3
ALIGN function_align
.write_4x8_hdpcm:
    psllq                m8, m0, 16
    psllq                m9, m1, 16
    paddw                m0, m8
    paddw                m1, m9
    psllq                m8, m0, 32
    psllq                m9, m1, 32
    paddw                m0, m8
    paddw                m1, m9
    call .write_4x4
    vextracti128        xm0, m0, 1
    vextracti128        xm1, m1, 1
.write_4x4:
    movd                xm8, [dstq+dsq*0]
    pinsrd              xm8, [dstq+dsq*1], 1
    movd                xm9, [dstq+dsq*2]
    pinsrd              xm9, [dstq+r6   ], 1
    punpcklbw           xm8, xm10
    punpcklbw           xm9, xm10
    paddsw              xm8, xm0
    paddsw              xm9, xm1
.write_4x4_end:
    packuswb            xm8, xm9
    movd       [dstq+dsq*0], xm8
    pextrd     [dstq+dsq*1], xm8, 1
    pextrd     [dstq+dsq*2], xm8, 2
    pextrd     [dstq+r6   ], xm8, 3
    lea                dstq, [dstq+dsq*4]
    ret

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    vpermq               m0, m0, q3120
    vpermq               m1, m1, q3120
    call m(inv_txfm_add_8x4_8bpc).dst4
    vpbroadcastd         m4, [o(pd_64)]
    REPX      {paddd x, m4}, m0, m1, m2, m3
    jmp .pass1_end
.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat)]
.pass2_dst:
    call .dst8
    vpbroadcastd         m8, [o(pd_512)]
    vinserti128          m0, xm1, 1
    vinserti128          m1, m3, xm2, 1
    vinserti128          m2, m4, xm5, 1
    vinserti128          m3, m7, xm6, 1
    REPX      {paddd x, m8}, m0, m1, m2, m3
    jmp .pass2_end
ALIGN function_align
.dst8:
    WRAP_XMM IDST8_1D_PACKED

INV_TXFM_FN 8, 4
    WIN64_SPILL_XMM      12
    jmp                tx1q

.dconly:
    movd                xm5, [o(pw_181x128)]
    pmulhrsw            xm5, [cfq]
    movd                xm4, [o(pw_17)]
    paddw               xm5, xm4
    psraw               xm5, 5
.dconly2:
    vpbroadcastw         m5, xm5
    lea                  r6, [dsq*3]
    pxor                xm4, xm4
    mova              [cfq], xm4
.dconly_loop:
    movq                xm0, [dstq+dsq*0]
    movq                xm1, [dstq+dsq*1]
    vpbroadcastq         m2, [dstq+dsq*2]
    vpbroadcastq         m3, [dstq+r6   ]
    vpblendd             m0, m2, 0x30
    vpblendd             m1, m3, 0x30
    punpcklbw            m0, m4
    punpcklbw            m1, m4
    paddw                m0, m5
    paddw                m1, m5
    packuswb             m0, m1
    vextracti128        xm1, m0, 1
    movq       [dstq+dsq*0], xm0
    movhps     [dstq+dsq*1], xm0
    movq       [dstq+dsq*2], xm1
    movhps     [dstq+r6   ], xm1
    lea                dstq, [dstq+dsq*4]
    dec                 r4d
    jg .dconly_loop
    vzeroupper
    ret

.pass1_dct:
    vpbroadcastd        xm3, [o(pw_181x128)]
    pmulhrsw            xm0, xm3, [cfq+16*0]
    pmulhrsw            xm1, xm3, [cfq+16*1]
    pmulhrsw            xm2, xm3, [cfq+16*2]
    pmulhrsw            xm3, [cfq+16*3]
    vpbroadcastd        m10, [o(pd_64)]
    call m(inv_txfm_add_4x8_8bpc).dct8
    REPX       {psrad x, 7}, m0, m1, m2, m3
    packssdw             m0, m2        ; 0 4   1 5
    packssdw             m1, m3        ; 3 7   2 6
    vpermq               m0, m0, q3120 ; 0 1   4 5
    vpermq               m1, m1, q1302 ; 2 3   6 7
.pass1_end:
    punpckhwd            m2, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m0, m2
    punpcklwd            m0, m2
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        m10, [o(pd_512)]
    call .dct4
    REPX      {psrad x, 10}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
.pass2_end:
    call .write_8x4_start
.pass2_end3:
    mova         [cfq+32*0], m10
    mova         [cfq+32*1], m10
    RET
ALIGN function_align
.write_8x4_hdpcm_start:
    lea                  r6, [dsq*3]
    pxor                m10, m10
.write_8x4_hdpcm_vpermq:
    vpermq               m0, m0, q3120
    vpermq               m1, m1, q3120
.write_8x4_hdpcm:
    pslldq               m8, m0, 2
    pslldq               m9, m1, 2
    paddw                m0, m8
    paddw                m1, m9
    pslldq               m8, m0, 4
    pslldq               m9, m1, 4
    paddw                m0, m8
    paddw                m1, m9
    punpcklqdq           m8, m10, m0
    punpcklqdq           m9, m10, m1
    paddw                m0, m8
    paddw                m1, m9
    jmp .write_8x4
.write_8x4_start:
    lea                  r6, [dsq*3]
    pxor                m10, m10
.write_8x4_vpermq:
    vpermq               m0, m0, q3120
    vpermq               m1, m1, q3120
.write_8x4:
    movq                xm8, [dstq+dsq*0]
    vpbroadcastq        m11, [dstq+dsq*1]
    movq                xm9, [dstq+dsq*2]
    vpblendd             m8, m11, 0x30
    vpbroadcastq        m11, [dstq+r6   ]
    vpblendd             m9, m11, 0x30
    punpcklbw            m8, m10
    punpcklbw            m9, m10
    paddsw               m0, m8
    paddsw               m1, m9
    packuswb             m0, m1
    vextracti128        xm1, m0, 1
    movq       [dstq+dsq*0], xm0
    movq       [dstq+dsq*1], xm1
    movhps     [dstq+dsq*2], xm0
    movhps     [dstq+r6   ], xm1
    lea                dstq, [dstq+dsq*4]
    ret
ALIGN function_align
.dct4:
    IDCT4_1D_PACKED     m10

.pass1_identity:
    vpbroadcastd         m2, [o(pw_181x128)]
    vpbroadcastd         m3, [o(pw_53x256)]
    mova                xm0, [cfq+16*0]
    vinserti128          m0, [cfq+16*2], 1
    mova                xm1, [cfq+16*1]
    vinserti128          m1, [cfq+16*3], 1
    pmulhrsw             m0, m2
    pmulhrsw             m1, m2
    pmulhrsw             m2, m3, m0 ; (x * 181 + 64) >> 7
    pmulhrsw             m3, m1     ; = x + ((x * 53 + 64) >> 7)
    paddw                m0, m2
    paddw                m1, m3
    jmp .pass1_end
.pass2_identity:
    vpbroadcastd         m2, [o(pw_4096)]
    pmulhrsw             m0, m2
    pmulhrsw             m1, m2
    test               eobd, 0x300
    jz .pass2_end
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    call .write_8x4_hdpcm_start
    jmp .pass2_end3
.vdpcm:
    pslldq               m2, m0, 8
    paddw                m1, m0
    shufpd               m3, m0, m1, 0x05
    paddw                m0, m2
    paddw                m1, m3
    jmp .pass2_end

.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat)]
.pass1_dst:
    vpbroadcastd        xm3, [o(pw_181x128)]
    pmulhrsw            xm0, xm3, [cfq+16*0]
    pmulhrsw            xm1, xm3, [cfq+16*1]
    pmulhrsw            xm2, xm3, [cfq+16*2]
    pmulhrsw            xm3, [cfq+16*3]
    call m(inv_txfm_add_4x8_8bpc).dst8
    vpbroadcastd         m8, [o(pd_64)]
    vinserti128          m0, xm4, 1
    vinserti128          m1, xm5, 1
    vinserti128          m2, xm6, 1
    vinserti128          m3, xm7, 1
    REPX      {paddd x, m8}, m0, m1, m2, m3
    REPX       {psrad x, 7}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
    jmp .pass1_end
.pass2_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst4_mat)]
.pass2_dst:
    call .dst4
    vpbroadcastd         m4, [o(pw_4096)]
    REPX       {psrad x, 7}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    jmp .pass2_end
ALIGN function_align
.dst4:
    IDST4_1D_PACKED

INV_TXFM_FN 8, 8
    WIN64_SPILL_XMM      12
    jmp                tx1q

.dconly:
    movd                xm5, [o(pw_33)]
    paddsw              xm5, [cfq]
    or                  r4d, 2
    psraw               xm5, 6
    jmp m(inv_txfm_add_8x4_8bpc).dconly2

.pass1_dct:
    vpermq               m0, [cfq+32*0], q3120
    vpermq               m1, [cfq+32*1], q3120
    vpermq               m2, [cfq+32*2], q3120
    vpermq               m3, [cfq+32*3], q3120
.pass1_dct2:
    vpbroadcastd        m10, [o(pd_64)]
    call .dct8
.pass1_end:
    call .shift7_pack
    punpckhwd            m4, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m2, m3
    punpcklwd            m2, m3
    punpckhdq            m3, m0, m2
    punpckldq            m0, m2
    punpckhdq            m2, m4, m1
    punpckldq            m4, m1
    vinserti128          m1, m3, xm2, 1
    vperm2i128           m3, m2, 0x31
    vperm2i128           m2, m0, m4, 0x31
    vinserti128          m0, xm4, 1
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        m10, [o(pd_1024)]
    call .dct8
    REPX      {psrad x, 11}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
    REPX      {psrad x, 11}, m4, m5, m6, m7
    packssdw             m2, m4, m5
    packssdw             m3, m6, m7
.pass2_end:
    lea                  r6, [dsq*3]
    pxor                m10, m10
    call .write_8x8
.pass2_end2:
    REPX {mova [cfq+32*x], m10}, 0, 1, 2, 3
    RET
ALIGN function_align
.shift7_pack:
    REPX       {psrad x, 7}, m0, m4, m1, m5
    packssdw             m0, m4
    packssdw             m1, m5
    REPX       {psrad x, 7}, m2, m6, m3, m7
    packssdw             m2, m6
    packssdw             m3, m7
    ret
ALIGN function_align
.dct8:
    IDCT8_1D_PACKED
    paddd                m3, m10    ; rnd
    paddd                m2, m10
    paddd                m1, m2, m0 ; a1
    psubd                m2, m0     ; a2
    paddd                m0, m3, m7 ; a0
    psubd                m3, m7     ; a3
.dct8c:
    psubd                m7, m0, m6 ; out7
    paddd                m0, m6     ; out0
    psubd                m6, m1, m5 ; out6
    paddd                m1, m5     ; out1
    psubd                m5, m2, m4 ; out5
    paddd                m2, m4     ; out2
    psubd                m4, m3, m8 ; out4
    paddd                m3, m8     ; out3
    ret

.pass1_identity:
    mova                xm0, [cfq+16*0]
    vinserti128          m0, [cfq+16*4], 1
    mova                xm1, [cfq+16*1]
    vinserti128          m1, [cfq+16*5], 1
    mova                xm2, [cfq+16*2]
    vinserti128          m2, [cfq+16*6], 1
    mova                xm3, [cfq+16*3]
    vinserti128          m3, [cfq+16*7], 1
.pass1_identity2:
    vpbroadcastd         m7, [o(pw_53x256)]
    pmulhrsw             m4, m7, m0
    pmulhrsw             m5, m7, m1
    pmulhrsw             m6, m7, m2
    pmulhrsw             m7, m3
    paddsw               m0, m4
    paddsw               m1, m5
    paddsw               m2, m6
    paddsw               m3, m7
    jmp m(inv_txfm_add_4x16_8bpc).pass1_end2
.pass2_identity:
    vpbroadcastd         m4, [o(pw_181x16)]
    REPX   {pmulhrsw x, m4}, m0, m1, m2, m3
    test               eobd, 0x300
    jz .pass2_end
    lea                  r6, [dsq*3]
    pxor                m10, m10
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    call m(inv_txfm_add_8x4_8bpc).write_8x4_hdpcm_vpermq
    vpermq               m0, m2, q3120
    vpermq               m1, m3, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4_hdpcm
    jmp .pass2_end2
.vdpcm:
    call .write_8x8_vdpcm
    jmp .pass2_end2
ALIGN function_align
.write_8x8_vdpcm:
    pslldq               m8, m0, 8
    paddw                m1, m0
    shufpd               m9, m0, m1, 0x05
    paddw                m2, m1
    paddw                m0, m8
    shufpd               m8, m1, m2, 0x05
    paddw                m3, m2
    paddw                m1, m9
    shufpd               m9, m2, m3, 0x05
    paddw                m2, m8
    paddw                m3, m9
.write_8x8:
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    vpermq               m0, m2, q3120
    vpermq               m1, m3, q3120
    jmp m(inv_txfm_add_8x4_8bpc).write_8x4

.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat)]
.pass1_dst:
    vpermq               m0, [cfq+32*0], q3120
    vpermq               m1, [cfq+32*1], q3120
    vpermq               m2, [cfq+32*2], q3120
    vpermq               m3, [cfq+32*3], q3120
.pass1_dst2:
    call .dst8
    vpbroadcastd         m8, [o(pd_64)]
    REPX      {paddd x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    jmp .pass1_end
.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat)]
.pass2_dst:
    call .dst8
    vpbroadcastd         m8, [o(pw_4096)]
    REPX       {psrad x, 8}, m0, m1, m2, m3
    packssdw             m0, m1
    packssdw             m1, m2, m3
    REPX       {psrad x, 8}, m4, m5, m6, m7
    packssdw             m2, m4, m5
    packssdw             m3, m6, m7
    REPX   {pmulhrsw x, m8}, m0, m1, m2, m3
    jmp .pass2_end
ALIGN function_align
.dst8:
    IDST8_1D_PACKED

INV_TXFM_FN 4, 16
    WIN64_SPILL_XMM      13
    jmp                tx1q

.dconly:
    vpbroadcastw        xm3, [cfq]
    vpbroadcastd        xm2, [o(pw_512)]
    or                  r4d, 4
    pmulhrsw            xm3, xm2
    jmp m(inv_txfm_add_4x4_8bpc).dconly3

.pass1_dct_fast:
    vbroadcasti128       m0, [cfq+32*0]
    vbroadcasti128       m2, [cfq+32*1]
    vbroadcasti128       m1, [cfq+32*2]
    vbroadcasti128       m3, [cfq+32*3]
    shufpd               m0, m2, 0x0c
    shufpd               m1, m3, 0x0c
    call m(inv_txfm_add_8x4_8bpc).dct4
.pass1_fast_end:
    REPX       {psrad x, 6}, m0, m1, m2, m3
    jmp m(inv_txfm_add_4x8_8bpc).pass1_end2
.pass1_dct:
    vpbroadcastd        m10, [o(pd_32)]
    lea                 r3d, [eobq+(18<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    sub                eobd, 26<<16
    jl .pass1_dct_fast
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    call m(inv_txfm_add_16x4_8bpc).dct4
.pass1_end:
    call .shift6_pack
.pass1_end2:
    punpckhwd            m4, m2, m3
    punpcklwd            m2, m3
    punpckhwd            m3, m0, m1
    punpcklwd            m0, m1
    punpckhdq            m1, m0, m2
    punpckldq            m0, m2
    punpckldq            m2, m3, m4
    punpckhdq            m3, m4
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        m10, [o(pd_2048)]
    test               eobd, eobd
    jl .pass2_dct_fast
    vextracti128        xm4, m0, 1
    vextracti128        xm5, m1, 1
    vextracti128        xm6, m2, 1
    vextracti128        xm7, m3, 1
    call .dct16
    jmp .pass2_dct2
.pass2_dct_fast:
    call .dct16_fast
.pass2_dct2:
    mova                 m5, [cfq+32*0]
    mova                 m6, [cfq+32*1]
    psubd                m4, m0, m5 ; out15 out14
    paddd                m0, m5     ; out0  out1
    psubd                m5, m1, m6 ; out12 out13
    paddd                m1, m6     ; out3  out2
    psrad                m0, 12
    psrad                m1, 12
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct_start
    mova                 m1, [cfq+32*2]
    mova                 m6, [cfq+32*3]
    paddd                m0, m2, m1 ; out4  out5
    psubd                m2, m1     ; out11 out10
    paddd                m1, m3, m6 ; out7  out6
    psubd                m3, m6     ; out8  out9
    psrad                m0, 12
    psrad                m1, 12
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    psrad                m0, m3, 12
    psrad                m1, m2, 12
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    psrad                m0, m5, 12
    psrad                m1, m4, 12
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
ALIGN function_align
.shift6_pack:
    REPX       {psrad x, 6}, m0, m4, m1, m5
    packssdw             m0, m4
    packssdw             m1, m5
    REPX       {psrad x, 6}, m2, m6, m3, m7
    packssdw             m2, m6
    packssdw             m3, m7
    ret
ALIGN function_align
.dct16_fast:
    lea                  r3, [o(dct16_mat)]
    punpcklwd           xm9, xm0, xm2 ; 0 4
    punpckhwd           xm0, xm2      ; 1 5
    punpcklwd           xm8, xm1, xm3 ; 2 6
    punpckhwd           xm1, xm3      ; 3 7
.dct16_fast2:
    call .dct16_fast3
    add                  r3, 4*8
    mova         [cfq+16*0], xm4     ; c0
    mova         [cfq+16*1], xm5     ; c1
    mova         [cfq+16*6], xm7     ; c7
    mova         [cfq+16*7], xm6     ; c6
    call .dct16_fast3
    vpbroadcastd        xm2, [o(pd_64)]
    vpbroadcastd        xm1, [o(pw_0_83)]
    vpbroadcastd       xm11, [o(pw_0_35)]
    mova         [cfq+16*2], xm5     ; c3
    mova         [cfq+16*3], xm4     ; c2
    mova         [cfq+16*4], xm6     ; c4
    mova         [cfq+16*5], xm7     ; c5
    vpbroadcastd        xm6, [o(pw_89_75)]
    pmaddwd             xm2, xm9
    vpbroadcastd        xm5, [o(pw_75_m18)]
    pmaddwd             xm1, xm9
    vpbroadcastd        xm4, [o(pw_50_m89)]
    pmaddwd            xm11, xm9
    vpbroadcastd        xm7, [o(pw_18_m50)]
    pmaddwd             xm6, xm8      ; b0
    pmaddwd             xm5, xm8      ; b1
    pmaddwd             xm4, xm8      ; b2
    pmaddwd             xm8, xm7      ; b3
    paddd               xm2, xm10     ; rnd
    vinserti128          m2, xm2, 1
    vinserti128          m1, xm11, 1
    paddd                m3, m2, m1  ; a0 a1
    psubd                m2, m1      ; a3 a2
    vinserti128          m1, m6, xm5, 1
    vinserti128          m4, m8, xm4, 1
    jmp m(inv_txfm_add_4x8_8bpc).dct8c
.dct16_fast3:
    vpbroadcastd        xm4, [r3+4*0]
    vpbroadcastd        xm6, [r3+4*1]
    vpbroadcastd        xm2, [r3+4*2]
    vpbroadcastd        xm7, [r3+4*3]
    pmaddwd             xm4, xm0
    pmaddwd             xm6, xm1
    pmaddwd             xm2, xm1
    pmaddwd             xm7, xm0
    vpbroadcastd        xm5, [r3+4*4]
    vpbroadcastd        xm3, [r3+4*5]
    paddd               xm4, xm6 ; b0 / b2
    vpbroadcastd        xm6, [r3+4*6]
    psubd               xm7, xm2 ; b7 / b5
    vpbroadcastd        xm2, [r3+4*7]
    pmaddwd             xm5, xm0
    pmaddwd             xm3, xm1
    pmaddwd             xm6, xm1
    pmaddwd             xm2, xm0
    paddd               xm5, xm3 ; b1 / b3
    psubd               xm6, xm2 ; b6 / b4
    ret
ALIGN function_align
.dct16:
    lea                  r3, [o(dct16_mat)]
    punpcklwd           xm8, xm0, xm4 ;  0  8
    punpckhwd           xm0, xm2      ;  1  5
    mova         [cfq+16*3], xm8
    punpcklwd           xm9, xm1, xm5 ;  2 10
    punpckhwd           xm1, xm3      ;  3  7
    mova         [cfq+16*2], xm9
    punpcklwd           xm8, xm6, xm2 ; 12  4
    punpckhwd           xm2, xm6, xm4 ; 13  9
    mova         [cfq+16*5], xm8
    punpcklwd           xm6, xm7, xm3 ; 14  6
    punpckhwd           xm3, xm7, xm5 ; 15 11
    mova         [cfq+16*4], xm6
    call .dct16b
    add                  r3, 4*8
    ; Order the output such that the sumsub
    ; step to be done using ymm registers
    mova         [cfq+16*0], xm8  ; b0
    mova         [cfq+16*1], xm9  ; b1
    mova         [cfq+16*6], xm12 ; b7
    mova         [cfq+16*7], xm11 ; b6
    call .dct16b
    mova                xm7, [cfq+16*2]
    mova                xm0, [cfq+16*3]
    mova                xm2, [cfq+16*4]
    mova                xm1, [cfq+16*5]
    mova         [cfq+16*2], xm9  ; b3
    mova         [cfq+16*3], xm8  ; b2
    mova         [cfq+16*4], xm11 ; b4
    mova         [cfq+16*5], xm12 ; b5
    jmp m(inv_txfm_add_4x8_8bpc).dct8b
.dct16b:
    vpbroadcastd        xm7, [r3+4*0]
    vpbroadcastd       xm12, [r3+4*1]
    vpbroadcastd       xm11, [r3+4*4]
    vpbroadcastd        xm6, [r3+4*5]
    pmaddwd             xm8, xm7, xm0
    pmaddwd             xm4, xm12, xm1
    pmaddwd             xm9, xm11, xm0
    pmaddwd             xm5, xm6, xm1
    pmaddwd             xm7, xm3
    pmaddwd            xm12, xm2
    pmaddwd            xm11, xm3
    pmaddwd             xm6, xm2
    paddd               xm8, xm4
    paddd               xm9, xm5
    psubd              xm12, xm7
    vpbroadcastd        xm7, [r3+4*2]
    psubd              xm11, xm6
    vpbroadcastd        xm6, [r3+4*6]
    pmaddwd             xm4, xm7, xm2
    pmaddwd             xm5, xm6, xm2
    pmaddwd             xm7, xm1
    pmaddwd             xm6, xm1
    paddd               xm8, xm4
    paddd               xm9, xm5
    psubd              xm12, xm7
    vpbroadcastd        xm7, [r3+4*3]
    paddd              xm11, xm6
    vpbroadcastd        xm6, [r3+4*7]
    pmaddwd             xm4, xm7, xm3
    pmaddwd             xm5, xm6, xm3
    pmaddwd             xm7, xm0
    pmaddwd             xm6, xm0
    paddd               xm8, xm4 ; b0 / b2
    paddd               xm9, xm5 ; b1 / b3
    paddd              xm12, xm7 ; b7 / b5
    psubd              xm11, xm6 ; b6 / b4
    ret

.pass1_identity:
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    REPX      {paddsw x, x}, m0, m1, m2, m3
    lea                 r3d, [eobq-(32<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    jmp .pass1_end2
.pass2_identity_fast:
    call m(inv_txfm_add_4x8_8bpc).write_4x4
    pmulhrsw            xm0, xm4, xm2
    pmulhrsw            xm1, xm4, xm3
    call m(inv_txfm_add_4x8_8bpc).write_4x4
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
.pass2_identity:
    vpbroadcastd         m4, [o(pw_2048)]
    lea                  r6, [dsq*3]
    pxor                m10, m10
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    test               eobd, 0x80000100
    jl .pass2_identity_fast
    pmulhrsw             m2, m4
    pmulhrsw             m3, m4
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
    call .write_4x16
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
.hdpcm:
    call .write_4x16_hdpcm
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
.vdpcm:
    call .write_4x16_vdpcm
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
ALIGN function_align
.write_4x16_hdpcm:
    psllq                m8, m0, 16
    psllq                m9, m1, 16
    paddw                m0, m8
    paddw                m1, m9
    psllq                m8, m0, 32
    psllq                m9, m1, 32
    paddw                m0, m8
    paddw                m1, m9
    psllq                m8, m2, 16
    psllq                m9, m3, 16
    paddw                m2, m8
    paddw                m3, m9
    psllq                m8, m2, 32
    psllq                m9, m3, 32
    paddw                m2, m8
    paddw                m3, m9
.write_4x16:
    call .write_4x8
    vextracti128        xm0, m0, 1
    vextracti128        xm1, m1, 1
    vextracti128        xm2, m2, 1
    vextracti128        xm3, m3, 1
.write_4x8:
    call m(inv_txfm_add_4x8_8bpc).write_4x4
    movd                xm8, [dstq+dsq*0]
    pinsrd              xm8, [dstq+dsq*1], 1
    movd                xm9, [dstq+dsq*2]
    pinsrd              xm9, [dstq+r6   ], 1
    pmovzxbw            xm8, xm8
    pmovzxbw            xm9, xm9
    paddsw              xm8, xm2
    paddsw              xm9, xm3
    jmp m(inv_txfm_add_4x8_8bpc).write_4x4_end
.write_4x16_vdpcm:
    pslldq               m8, m0, 8
    paddsw               m1, m0
    shufpd               m9, m0, m1, 0x05
    paddsw               m2, m1
    paddsw               m0, m8
    shufpd               m8, m1, m2, 0x05
    paddsw               m3, m2
    paddsw               m1, m9
    shufpd               m9, m2, m3, 0x05
    paddsw               m2, m8
    paddsw               m3, m9
    call .write_4x8
    punpckhqdq          xm8, xm3, xm3
    vextracti128        xm0, m0, 1
    vextracti128        xm1, m1, 1
    vextracti128        xm2, m2, 1
    vextracti128        xm3, m3, 1
    REPX    {paddsw x, xm8}, xm0, xm1, xm2, xm3
    jmp .write_4x8

.pass1_dst_fast:
    vbroadcasti128       m0, [cfq+32*0]
    vbroadcasti128       m2, [cfq+32*1]
    vbroadcasti128       m1, [cfq+32*2]
    vbroadcasti128       m3, [cfq+32*3]
    shufpd               m0, m2, 0x0c
    shufpd               m1, m3, 0x0c
    call m(inv_txfm_add_8x4_8bpc).dst4
    REPX     {paddd x, m12}, m0, m1, m2, m3
    jmp .pass1_fast_end
.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    vpbroadcastd        m12, [o(pd_32)]
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(18<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r8d
%if WIN64
    pop                  r8
%endif
    sub                eobd, 26<<16
    jl .pass1_dst_fast
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    call m(inv_txfm_add_16x4_8bpc).dst4
    REPX     {paddd x, m12}, m0, m4, m1, m5, m2, m6, m3, m7
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
    vpbroadcastd         m7, [o(pd_2048)]
    lea                  r6, [dsq*3]
    pxor                m10, m10
%if WIN64
    movaps       [cfq+16*3], xm13
%endif
    punpcklwd           m13, m0, m1 ;  0  2
    punpckhwd           m11, m0, m1 ;  1  3
    punpcklwd           m12, m2, m3 ;  4  6
    punpckhwd            m2, m3     ;  5  7
    test               eobd, eobd
    jl .pass2_dst_fast
    vextracti128        xm3, m13, 1 ;  8 10
    vextracti128        xm4, m11, 1 ;  9 11
    vextracti128        xm5, m12, 1 ; 12 14
    vextracti128        xm6, m2, 1  ; 13 15
    call .pass2_dst_4x4
    call .pass2_dst_4x4
    call .pass2_dst_4x4
    call .pass2_dst_4x4
%if WIN64
    movaps             xm13, [cfq+16*3]
%endif
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
.pass2_dst_fast:
    call .pass2_dst_4x4_fast
    call .pass2_dst_4x4_fast
    call .pass2_dst_4x4_fast
    call .pass2_dst_4x4_fast
%if WIN64
    movaps             xm13, [cfq+16*3]
%endif
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end2
ALIGN function_align
.pass2_dst_4x4:
    call .dst16x1
    add                  r3, 32
    mova         [cfq+16*0], xm0
    call .dst16x1
    add                  r3, 32
    mova         [cfq+16*1], xm0
    call .dst16x1
    add                  r3, 32
    mova         [cfq+16*2], xm0
    call .dst16x1
    add                  r3, 32
    vinserti128          m1, m0, [cfq+16*2], 1
    paddd                m0, m7, [cfq+32*0]
    jmp .pass2_dst_4x4b
.pass2_dst_4x4_fast:
    call .dst16x2
    vinserti128          m6, m0, xm1, 1
    call .dst16x2
    vinserti128          m1, xm0, 1
    paddd                m0, m7, m6
.pass2_dst_4x4b:
    paddd                m1, m7
    psrad                m0, 12
    psrad                m1, 12
    jmp m(inv_txfm_add_4x8_8bpc).write_4x4_dct
ALIGN function_align
.dst16x1:
    WRAP_XMM IDST16_1D_PACKED_1ROW
ALIGN function_align
.dst16x2:
    WRAP_XMM IDST16_1D_PACKED_2ROWS_FAST 1
    add                  r3, 32*2
    ret

INV_TXFM_FN 16, 4
    mova                xm0, [cfq+16*0]
    mova                xm1, [cfq+16*1]
    mova                xm2, [cfq+16*2]
    mova                xm3, [cfq+16*3]
    WIN64_SPILL_XMM      13
    jmp                tx1q

.dconly:
    movd                xm3, [o(pw_512)]
    or                  r4d, 2
.dconly2:
    pmulhrsw            xm3, [cfq]
.dconly3:
    vpbroadcastw         m3, xm3
    pxor                xm2, xm2
    mova              [cfq], xm2
.dconly_loop:
    movu                xm1, [dstq+dsq*0]
    vinserti128          m1, [dstq+dsq*1], 1
    punpcklbw            m0, m1, m2
    punpckhbw            m1, m2
    paddw                m0, m3
    paddw                m1, m3
    packuswb             m0, m1
    movu         [dstq+dsq*0], xm0
    vextracti128 [dstq+dsq*1], m0, 1
    lea                dstq, [dstq+dsq*2]
    dec                 r4d
    jg .dconly_loop
    vzeroupper
    ret

.pass1_dct:
    vpbroadcastd        m10, [o(pd_32)]
    lea                 r3d, [eobq+(3<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r3d
    cmp                eobd, 32<<16
    jl .pass1_dct_fast
    mova                xm4, [cfq+16*4]
    mova                xm5, [cfq+16*5]
    mova                xm6, [cfq+16*6]
    mova                xm7, [cfq+16*7]
    call m(inv_txfm_add_4x16_8bpc).dct16
    jmp .pass1_dct2
.pass1_dct_fast:
    call m(inv_txfm_add_4x16_8bpc).dct16_fast
.pass1_dct2:
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
    call m(inv_txfm_add_4x16_8bpc).shift6_pack
    vpermq               m0, m0, q3120 ;  0  1    8  9
    vpermq               m1, m1, q1302 ;  2  3   10 11
    vpermq               m2, m2, q3120 ;  4  5   12 13
    vpermq               m3, m3, q1302 ;  6  7   14 15
.pass1_end:
    punpckhwd            m4, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m2, m3
    punpcklwd            m2, m3
    punpckhwd            m3, m0, m4
    punpcklwd            m0, m4
    punpckhwd            m4, m2, m1
    punpcklwd            m2, m1
    punpckhqdq           m1, m0, m2
    punpcklqdq           m0, m2
    punpcklqdq           m2, m3, m4
    punpckhqdq           m3, m4
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        m10, [o(pd_2048)]
    call .dct4
    REPX      {psrad x, 12}, m0, m4, m1, m5
    packssdw             m0, m4
    packssdw             m1, m5
    call .write_16x2
    REPX      {psrad x, 12}, m2, m6, m3, m7
    packssdw             m0, m2, m6
    packssdw             m1, m3, m7
.pass2_end:
    call .write_16x2
.pass2_end2:
    pxor                m10, m10
.pass2_end3:
    REPX {mova [cfq+32*x], m10}, 0, 1, 2, 3
    RET
ALIGN function_align
.write_16x2_hdpcm:
    pslldq               m8, m0, 2
    pslldq               m9, m1, 2
    paddw                m0, m8
    paddw                m1, m9
    pslldq               m8, m0, 4
    pslldq               m9, m1, 4
    paddw                m0, m8
    paddw                m1, m9
    pslldq               m8, m0, 8
    pslldq               m9, m1, 8
    paddw                m0, m8
    paddw                m1, m9
    pshufhw             xm8, xm0, q3333
    pshufhw             xm9, xm1, q3333
    vpermq               m8, m8, q1133
    vpermq               m9, m9, q1133
    paddsw               m0, m8
    paddsw               m1, m9
.write_16x2:
    pmovzxbw             m8, [dstq+dsq*0]
    pmovzxbw             m9, [dstq+dsq*1]
    paddsw               m8, m0
    paddsw               m9, m1
    packuswb             m8, m9
    vpermq               m8, m8, q3120
    movu         [dstq+dsq*0], xm8
    vextracti128 [dstq+dsq*1], m8, 1
    lea                dstq, [dstq+dsq*2]
    ret
ALIGN function_align
.dct4:
    punpcklwd            m7, m0, m2 ; 0 2
    vpbroadcastd         m6, [o(pw_64_64)]
    punpckhwd            m0, m2
    vpbroadcastd         m8, [o(pw_64_m64)]
    punpckhwd            m5, m3, m1 ; 3 1
    vpbroadcastd         m4, [o(pw_35_83)]
    punpcklwd            m1, m3, m1
    vpbroadcastd         m3, [o(pw_m83_35)]
    pmaddwd              m2, m6, m7 ; a0
    pmaddwd              m6, m0
    pmaddwd              m7, m8     ; a1
    pmaddwd              m8, m0
    pmaddwd              m0, m4, m1 ; b0
    pmaddwd              m4, m5
    pmaddwd              m1, m3     ; b1
    pmaddwd              m5, m3
    REPX     {paddd x, m10}, m2, m6, m7, m8
    psubd                m3, m2, m0 ; out3a
    paddd                m0, m2     ; out0a
    psubd                m2, m7, m1 ; out2a
    paddd                m1, m7     ; out1a
    psubd                m7, m6, m4 ; out3b
    paddd                m4, m6     ; out0b
    psubd                m6, m8, m5 ; out2b
    paddd                m5, m8     ; out1b
    ret

.pass1_identity:
    vinserti128          m0, [cfq+16*4], 1 ;  0  1    8  9
    vinserti128          m1, [cfq+16*5], 1 ;  2  3   10 11
    vinserti128          m2, [cfq+16*6], 1 ;  4  5   12 13
    vinserti128          m3, [cfq+16*7], 1 ;  6  7   14 15
    REPX      {paddsw x, x}, m0, m1, m2, m3, m0, m1, m2, m3
    jmp .pass1_end
.pass2_identity:
    vpbroadcastd         m4, [o(pw_1024)]
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
    test               eobd, 0x300
    jz .pass2_dst_end
    test               eobd, 0x200
    jnz .vdpcm
.hdpcm:
    call .write_16x2_hdpcm
    pmulhrsw             m0, m4, m2
    pmulhrsw             m1, m4, m3
    call .write_16x2_hdpcm
    jmp .pass2_end2
.vdpcm:
    pmulhrsw             m2, m4
    pmulhrsw             m3, m4
    paddw                m1, m0
    call .write_16x2
    paddw                m0, m2, m1
    paddw                m1, m3, m0
    jmp .pass2_end

.pass1_flipddt:
    lea                  r3, [o(flipddt16_mat+32*6)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt16_mat+32*6)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst16_mat+32*6)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst16_mat+32*6)]
.pass1_dst:
    vpbroadcastd         m7, [o(pd_32)]
%if WIN64
    movaps             xm10, xm13
    push                 r8
    %define             tmp  rsp+8
%else
    %define             tmp  rsp-24
%endif
    punpcklwd          xm13, xm0, xm1 ;  0  2
    punpckhwd          xm11, xm0, xm1 ;  1  3
    punpcklwd          xm12, xm2, xm3 ;  4  6
    punpckhwd           xm2, xm3      ;  5  7
    lea                 r8d, [eobq+(3<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r8d
    mov                 r8d, 32*3
    cmp                eobd, 32<<16
    jl .pass1_dst_fast
    mova                xm4, [cfq+16*4]
    mova                xm5, [cfq+16*5]
    mova                xm6, [cfq+16*6]
    mova                xm0, [cfq+16*7]
    punpcklwd           xm3, xm4, xm5 ;  8 10
    punpckhwd           xm4, xm5      ;  9 11
    punpcklwd           xm5, xm6, xm0 ; 12 14
    punpckhwd           xm6, xm0      ; 13 15
.pass1_dst_loop:
    call m(inv_txfm_add_4x16_8bpc).dst16x1 ;  6
    add                  r3, 32*8
    mova         [cfq+16*0], xm0
    call m(inv_txfm_add_4x16_8bpc).dst16x1 ; 14
    add                  r3, 32*1
    mova         [cfq+16*1], xm0
    call m(inv_txfm_add_4x16_8bpc).dst16x1 ; 15
    sub                  r3, 32*8
    mova              [tmp], xm0
    call m(inv_txfm_add_4x16_8bpc).dst16x1 ;  7
    sub                  r3, 32*3
    vinserti128          m1, m0, [tmp], 1
    paddd                m0, m7, [cfq]
    paddd                m1, m7
    psrad                m0, 6  ;  6 14
    psrad                m1, 6  ;  7 15
    packssdw             m0, m1
    mova           [cfq+r8], m0
    sub                 r8d, 32
    jge .pass1_dst_loop
    jmp .pass1_dst_end
.pass1_dst_fast:
    call .dst16x2_fast
    add                  r3, 32
    vinserti128          m6, m0, xm1, 1
    call .dst16x2_fast
    sub                  r3, 32*3
    vinserti128          m1, m0, xm1, 1
    paddd                m0, m7, m6
    paddd                m1, m7
    psrad                m0, 6  ;  6 14
    psrad                m1, 6  ;  7 15
    packssdw             m0, m1
    mova           [cfq+r8], m0
    sub                 r8d, 32
    jge .pass1_dst_fast
.pass1_dst_end:
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
%if WIN64
    movaps             xm13, xm10
    pop                  r8
%endif
    jmp .pass1_end
.pass2_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst4_mat)]
.pass2_dst:
    call .dst4
    call m(inv_txfm_add_8x8_8bpc).shift7_pack
    vpbroadcastd         m4, [o(pw_1024)]
    pmulhrsw             m0, m4
    pmulhrsw             m1, m4
.pass2_dst_end:
    call .write_16x2
    pmulhrsw             m0, m4, m2
    pmulhrsw             m1, m4, m3
    jmp .pass2_end
ALIGN function_align
.dst16x2_fast:
    WRAP_XMM IDST16_1D_PACKED_2ROWS_FAST 8
    ret
ALIGN function_align
.dst4:
    vpbroadcastd         m5, [r3+4*0]
    punpcklwd            m8, m0, m2 ; 0 2
    vpbroadcastd         m7, [r3+4*3]
    punpckhwd            m9, m0, m2
    vpbroadcastd        m10, [r3+4*1]
    punpcklwd            m2, m3, m1 ; 3 1
    vpbroadcastd        m11, [r3+4*2]
    punpckhwd            m6, m3, m1
    pmaddwd              m0, m5, m8
    pmaddwd              m3, m7, m2
    pmaddwd              m4, m5, m9
    pmaddwd              m1, m7, m6
    paddd                m0, m3     ; out0a
    paddd                m4, m1     ; out0b
    pmaddwd              m3, m7, m8
    pmaddwd              m1, m5, m2
    pmaddwd              m7, m9
    pmaddwd              m5, m6
    psubd                m3, m1     ; out3a
    psubd                m7, m5     ; out3b
    pmaddwd              m1, m10, m8
    pmaddwd              m5, m11, m2
    pmaddwd              m8, m11
    pmaddwd              m2, m10
    psubd                m1, m5     ; out1a
    paddd                m2, m8     ; out2a
    pmaddwd              m5, m10, m9
    pmaddwd              m9, m11
    pmaddwd             m11, m6
    pmaddwd              m6, m10
    psubd                m5, m11    ; out1b
    paddd                m6, m9     ; out2b
    ret

INV_TXFM_FN 8, 16
    add                 cfq, 32*4
    WIN64_SPILL_XMM      13
    vpbroadcastd         m8, [o(pw_181x128)]
    jmp                tx1q

.dconly:
    movd                xm5, [o(pw_181x128)]
    pmulhrsw            xm5, [cfq]
    movd                xm4, [o(pw_33)]
    or                  r4d, 4
    paddw               xm5, xm4
    psraw               xm5, 6
    jmp m(inv_txfm_add_8x4_8bpc).dconly2

ALIGN function_align
.pass1_fast_load:
    vbroadcasti128       m0, [cfq-32*4]
    vbroadcasti128       m4, [cfq-32*3]
    vbroadcasti128       m1, [cfq-32*2]
    vbroadcasti128       m5, [cfq-32*1]
    vbroadcasti128       m2, [cfq+32*0]
    vbroadcasti128       m6, [cfq+32*1]
    vbroadcasti128       m3, [cfq+32*2]
    vbroadcasti128       m7, [cfq+32*3]
    shufpd               m0, m4, 0x0c
    shufpd               m1, m5, 0x0c
    shufpd               m2, m6, 0x0c
    shufpd               m3, m7, 0x0c
    ret
.pass1_dct_fast:
    call .pass1_fast_load
    REPX   {pmulhrsw x, m8}, m0, m1, m2, m3
    jmp m(inv_txfm_add_8x8_8bpc).pass1_dct2
.pass1_dct:
    lea                 r3d, [eobq+(28<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    sub                eobd, 36<<16
    jl .pass1_dct_fast
    pmulhrsw             m1, m8, [cfq-32*3]
    pmulhrsw             m3, m8, [cfq-32*1]
    pmulhrsw             m5, m8, [cfq+32*1]
    pmulhrsw             m7, m8, [cfq+32*3]
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*3], m3
    vpbroadcastd         m3, [o(pw_181x128)]
    pmulhrsw             m0, m3, [cfq-32*4]
    pmulhrsw             m1, m3, [cfq-32*2]
    pmulhrsw             m2, m3, [cfq+32*0]
    pmulhrsw             m3, [cfq+32*2]
    mova         [cfq-32*4], m4
    mova         [cfq-32*2], m5
    mova         [cfq+32*0], m6
    mova         [cfq+32*2], m7
    vpbroadcastd        m10, [o(pd_64)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                 m8, [cfq-32*3] ; b0
    mova                 m9, [cfq-32*4]
    psubd               m10, m0, m8     ; out7a
    paddd                m0, m8         ; out0a
    mova                 m8, [cfq+32*3] ; b3
    psubd               m11, m4, m9     ; out7b
    paddd                m4, m9         ; out0b
    mova                 m9, [cfq+32*2]
    REPX       {psrad x, 7}, m0, m4, m10, m11
    packssdw             m0, m4
    psubd                m4, m3, m8     ; out4a
    paddd                m3, m8         ; out3a
    psubd                m8, m7, m9     ; out4b
    paddd                m7, m9         ; out3b
    mova                 m9, [cfq-32*1] ; b1
    REPX       {psrad x, 7}, m4, m8, m3, m7
    packssdw             m4, m8
    mova                 m8, [cfq-32*2]
    packssdw             m3, m7
    packssdw             m7, m10, m11
    psubd               m10, m1, m9     ; out6a
    paddd                m1, m9         ; out1a
    mova                 m9, [cfq+32*1] ; b2
    psubd               m11, m5, m8     ; out6b
    paddd                m5, m8         ; out1b
    mova                 m8, [cfq+32*0]
    REPX       {psrad x, 7}, m1, m5, m10, m11
    packssdw             m1, m5
    psubd                m5, m2, m9     ; out5a
    paddd                m2, m9         ; out2a
    psubd                m9, m6, m8     ; out5b
    paddd                m6, m8         ; out2b
    REPX       {psrad x, 7}, m5, m9, m2, m6
    packssdw             m5, m9
    packssdw             m2, m6
    packssdw             m6, m10, m11
.pass1_end:
    call .transpose16x8
    jmp                tx2q
.pass2_dct:
    vpbroadcastd        m10, [o(pd_1024)]
    test               eobd, eobd
    jl .pass2_dct_fast
    call .dct16
    jmp .pass2_dct2
.pass2_dct_fast:
    call .dct16_fast
.pass2_dct2:
    mova                m12, [cfq-32*4]
    mova                 m9, [cfq-32*3]
    psubd                m8, m0, m12 ; out15
    paddd                m0, m12     ; out0
    psubd               m12, m1, m9  ; out14
    paddd                m1, m9      ; out1
    REPX      {psrad x, 11}, m0, m1, m8, m12
    packssdw             m0, m1
    mova                 m1, [cfq-32*2]
    packssdw            m12, m8
    mova                 m8, [cfq-32*1]
    psubd                m9, m2, m1  ; out13
    paddd                m1, m2      ; out2
    paddd                m2, m3, m8  ; out3
    psubd                m3, m8      ; out12
    REPX      {psrad x, 11}, m1, m2, m9, m3
    packssdw             m1, m2
    packssdw             m3, m9
    call m(inv_txfm_add_8x4_8bpc).write_8x4_start
    mova                 m1, [cfq+32*3]
    mova                 m2, [cfq+32*2]
    paddd                m0, m4, m1  ; out4
    psubd                m4, m1      ; out11
    psubd                m1, m5, m2  ; out5
    paddd                m5, m2      ; out10
    mova                 m2, [cfq+32*1]
    mova                 m8, [cfq+32*0]
    REPX      {psrad x, 11}, m0, m1, m4, m5
    packssdw             m0, m1
    paddd                m1, m6, m2  ; out6
    psubd                m6, m2      ; out9
    paddd                m2, m7, m8  ; out8
    psubd                m7, m8      ; out7
    REPX      {psrad x, 11}, m1, m7, m6, m2
    packssdw             m1, m7
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    packssdw             m0, m2, m6
    packssdw             m1, m5, m4
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    vpermq               m0, m3, q3120
    vpermq               m1, m12, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
ALIGN function_align
.dct16_fast:
    punpcklwd            m9, m0, m2  ; 0 4
    punpckhwd            m0, m2      ; 1 5
    punpcklwd            m8, m1, m3  ; 2 6
    punpckhwd            m1, m3      ; 3 7
.dct16_fast2:
    mov                 r3d, 16*3
.dct16_fast_loop:
    vpbroadcastd         m2, [o(dct16_mat)+r3+4*0]
    vpbroadcastd         m4, [o(dct16_mat)+r3+4*1]
    vpbroadcastd         m3, [o(dct16_mat)+r3+4*2]
    vpbroadcastd         m5, [o(dct16_mat)+r3+4*3]
    pmaddwd              m2, m0
    pmaddwd              m3, m1
    pmaddwd              m4, m1
    pmaddwd              m5, m0
    paddd                m2, m4
    psubd                m3, m5
    mova    [cfq+r3*2-32*4], m2
    mova    [cfq+r3*2+32*0], m3
    sub                 r3d, 16
    jge .dct16_fast_loop
    vpbroadcastd         m2, [o(pd_64)]
    vpbroadcastd         m1, [o(pw_0_83)]
    vpbroadcastd         m7, [o(pw_0_35)]
    vpbroadcastd         m6, [o(pw_89_75)]
    pmaddwd              m2, m9
    vpbroadcastd         m5, [o(pw_75_m18)]
    pmaddwd              m1, m9
    vpbroadcastd         m4, [o(pw_50_m89)]
    pmaddwd              m9, m7
    vpbroadcastd         m7, [o(pw_18_m50)]
    pmaddwd              m6, m8      ; b0
    pmaddwd              m5, m8      ; b1
    pmaddwd              m4, m8      ; b2
    pmaddwd              m8, m7      ; b3
    paddd                m2, m10     ; rnd
    paddd                m0, m2, m1  ; a0
    psubd                m3, m2, m1  ; a3
    paddd                m1, m9, m2  ; a1
    psubd                m2, m9      ; a2
    jmp m(inv_txfm_add_8x8_8bpc).dct8c
ALIGN function_align
.dct16:
    punpckhwd            m8, m0, m2 ;  1  5
    punpckhwd            m9, m1, m3 ;  3  7
    punpckhwd           m11, m6, m4 ; 13  9
    punpckhwd           m12, m7, m5 ; 15 11
    punpcklwd            m0, m4     ;  0  8
    punpcklwd            m4, m1, m5 ;  2 10
    punpcklwd            m1, m6, m2 ; 12  4
    punpcklwd            m2, m7, m3 ; 14  6
    mova                 m7, m4
.dct16b:
    mov                 r3d, 16*3
.dct16_loop:
    vpbroadcastd         m4, [o(dct16_mat)+r3+4*0]
    vpbroadcastd         m5, [o(dct16_mat)+r3+4*1]
    pmaddwd              m3, m8, m4
    pmaddwd              m4, m12
    pmaddwd              m6, m9, m5
    pmaddwd              m5, m11
    paddd                m3, m6
    vpbroadcastd         m6, [o(dct16_mat)+r3+4*2]
    psubd                m4, m5
    pmaddwd              m5, m11, m6
    pmaddwd              m6, m9
    paddd                m3, m5
    vpbroadcastd         m5, [o(dct16_mat)+r3+4*3]
    paddd                m4, m6
    pmaddwd              m6, m12, m5
    pmaddwd              m5, m8
    paddd                m3, m6
    psubd                m4, m5
    mova    [cfq+r3*2-32*4], m3
    mova    [cfq+r3*2+32*0], m4
    sub                 r3d, 16
    jge .dct16_loop
    jmp m(inv_txfm_add_8x8_8bpc).dct8b
ALIGN function_align
.transpose16x8:
    vperm2i128           m9, m3, m7, 0x31
    vinserti128          m3, xm7, 1
    vperm2i128           m8, m2, m6, 0x31
    vinserti128          m2, xm6, 1
    vperm2i128           m6, m1, m5, 0x31
    vinserti128          m1, xm5, 1
    vperm2i128           m5, m0, m4, 0x31
    vinserti128          m0, xm4, 1
    punpckhwd            m4, m2, m3
    punpcklwd            m2, m3
    punpckhwd            m3, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m7, m5, m6
    punpcklwd            m5, m6
    punpcklwd            m6, m8, m9
    punpckhwd            m8, m9
    punpckhdq            m1, m0, m2
    punpckldq            m0, m2
    punpckldq            m2, m3, m4
    punpckhdq            m3, m4
    punpckldq            m4, m5, m6
    punpckhdq            m5, m6
    punpckldq            m6, m7, m8
    punpckhdq            m7, m8
    ret

.pass1_identity_fast:
    mova                xm0, [cfq-32*4]
    vinserti128          m0, [cfq+32*0], 1
    mova                xm1, [cfq-32*3]
    vinserti128          m1, [cfq+32*1], 1
    mova                xm2, [cfq-32*2]
    vinserti128          m2, [cfq+32*2], 1
    mova                xm3, [cfq-32*1]
    vinserti128          m3, [cfq+32*3], 1
    REPX   {pmulhrsw x, m8}, m0, m1, m2, m3
    jmp m(inv_txfm_add_8x8_8bpc).pass1_identity2
.pass1_identity:
    lea                 r3d, [eobq-(64<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    test               eobd, eobd
    jl .pass1_identity_fast
    pmulhrsw             m0, m8, [cfq-32*4]
    pmulhrsw             m1, m8, [cfq-32*3]
    pmulhrsw             m2, m8, [cfq-32*2]
    pmulhrsw             m3, m8, [cfq-32*1]
    vpbroadcastd        m12, [o(pw_53x256)]
    pmulhrsw             m4, m8, [cfq+32*0]
    pmulhrsw             m5, m8, [cfq+32*1]
    pmulhrsw             m6, m8, [cfq+32*2]
    pmulhrsw             m7, m8, [cfq+32*3]
    pmulhrsw             m8, m12, m0
    pmulhrsw             m9, m12, m1
    pmulhrsw            m10, m12, m2
    pmulhrsw            m11, m12, m3
    paddw                m0, m8
    pmulhrsw             m8, m12, m4
    paddw                m1, m9
    pmulhrsw             m9, m12, m5
    paddw                m2, m10
    pmulhrsw            m10, m12, m6
    paddw                m3, m11
    pmulhrsw            m12, m7
    paddw                m4, m8
    paddw                m5, m9
    paddw                m6, m10
    paddw                m7, m12
    jmp .pass1_end
.pass2_identity:
    vpbroadcastd         m8, [o(pw_4096)]
    REPX   {pmulhrsw x, m8}, m0, m1, m2, m3
    lea                  r6, [dsq*3]
    pxor                m10, m10
    test               eobd, 0x80000100
    jl .pass2_identity_fast
    REPX   {pmulhrsw x, m8}, m4, m5, m6, m7
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
    call .write_8x16
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
.hdpcm:
    call .write_8x16_hdpcm
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
.vdpcm:
    call .write_8x16_vdpcm
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
.pass2_identity_fast:
    call m(inv_txfm_add_8x8_8bpc).write_8x8
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
ALIGN function_align
.write_8x16_hdpcm:
    call m(inv_txfm_add_8x4_8bpc).write_8x4_hdpcm_vpermq
    vpermq               m0, m2, q3120
    vpermq               m1, m3, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4_hdpcm
    vpermq               m0, m4, q3120
    vpermq               m1, m5, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4_hdpcm
    vpermq               m0, m6, q3120
    vpermq               m1, m7, q3120
    jmp m(inv_txfm_add_8x4_8bpc).write_8x4_hdpcm
.write_8x16_vdpcm:
    punpcklqdq           m8, m10, m0
    paddsw               m1, m0
    shufpd               m9, m0, m1, 0x05
    paddsw               m2, m1
    paddsw               m0, m8
    shufpd               m8, m1, m2, 0x05
    paddsw               m3, m2
    paddsw               m1, m9
    shufpd               m9, m2, m3, 0x05
    paddsw               m4, m3
    paddsw               m2, m8
    shufpd               m8, m3, m4, 0x05
    paddsw               m5, m4
    paddsw               m3, m9
    shufpd               m9, m4, m5, 0x05
    paddsw               m6, m5
    paddsw               m4, m8
    shufpd               m8, m5, m6, 0x05
    paddsw               m7, m6
    paddsw               m5, m9
    shufpd               m9, m6, m7, 0x05
    paddsw               m6, m8
    paddsw               m7, m9
.write_8x16:
    call m(inv_txfm_add_8x8_8bpc).write_8x8
    vpermq               m0, m4, q3120
    vpermq               m1, m5, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    vpermq               m0, m6, q3120
    vpermq               m1, m7, q3120
    jmp m(inv_txfm_add_8x4_8bpc).write_8x4

.pass1_dst_fast:
    call .pass1_fast_load
    REPX   {pmulhrsw x, m8}, m0, m1, m2, m3
%if WIN64
    pop                  r8
%endif
    jmp m(inv_txfm_add_8x8_8bpc).pass1_dst2
.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat)]
.pass1_dst:
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(28<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r8d
    sub                eobd, 36<<16
    jl .pass1_dst_fast
    pmulhrsw             m0, m8, [cfq-32*4]
    pmulhrsw             m1, m8, [cfq-32*3]
    pmulhrsw             m2, m8, [cfq-32*2]
    pmulhrsw             m3, m8, [cfq-32*1]
    pmulhrsw             m4, m8, [cfq+32*0]
    pmulhrsw             m5, m8, [cfq+32*1]
    pmulhrsw             m6, m8, [cfq+32*2]
    pmulhrsw             m7, m8, [cfq+32*3]
    punpcklwd           m10, m0, m2 ; 0 2
    punpckhwd            m0, m2
    punpcklwd            m2, m1, m3 ; 1 3
    punpckhwd            m1, m3
    punpcklwd            m3, m4, m6 ; 4 6
    punpckhwd            m4, m6
    punpcklwd           m11, m5, m7 ; 5 7
    punpckhwd            m5, m7
    vpbroadcastd        m12, [o(pd_64)]
    mov                  r8, -32*7
.pass1_dst_loop:
    call m(inv_txfm_add_16x8_8bpc).dst8
    paddd                m6, m12
    paddd                m7, m12
    psrad                m6, 7
    psrad                m7, 7
    packssdw             m7, m6, m7
    mova      [cfq+r8+32*3], m7
    add                  r8, 32
    jle .pass1_dst_loop
%if WIN64
    pop                  r8
%endif
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    jmp .pass1_end
.pass2_dst_fast:
    IDST16_1D_PACKED_2ROWS_FAST 1
    add                  r3, 32*2
    psrad                m0, 8
    psrad                m1, 8
    packssdw             m0, m1
    vpermq               m0, m0, q3120
    mova      [cfq+r5+32*3], m0
    add                  r5, 32
    jle .pass2_dst_fast
    jmp .pass2_dst_end
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
    punpcklwd           m10, m0, m1 ;  0  2
    punpckhwd           m11, m0, m1 ;  1  3
    punpcklwd           m12, m2, m3 ;  4  6
    punpckhwd            m2, m3     ;  5  7
    mov                  r5, -32*7
    test               eobd, eobd
    jl .pass2_dst_fast
    punpcklwd            m3, m4, m5 ;  8 10
    punpckhwd            m4, m5     ;  9 11
    punpcklwd            m5, m6, m7 ; 12 14
    punpckhwd            m6, m7     ; 13 15
.pass2_dst_loop:
    call .dst16x1
    add                  r3, 32
    psrad                m7, m0, 8
    call .dst16x1
    add                  r3, 32
    psrad                m0, 8
    packssdw             m0, m7
    vpermq               m0, m0, q2031
    mova      [cfq+r5+32*3], m0
    add                  r5, 32
    jle .pass2_dst_loop
.pass2_dst_end:
    vpbroadcastd         m2, [o(pw_4096)]
    pmulhrsw             m0, m2, [cfq-32*4]
    pmulhrsw             m1, m2, [cfq-32*3]
    lea                  r6, [dsq*3]
    pxor                m10, m10
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    pmulhrsw             m0, m2, [cfq-32*2]
    pmulhrsw             m1, m2, [cfq-32*1]
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    pmulhrsw             m0, m2, [cfq+32*0]
    pmulhrsw             m1, m2, [cfq+32*1]
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    pmulhrsw             m0, m2, [cfq+32*2]
    pmulhrsw             m1, m2, [cfq+32*3]
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
ALIGN function_align
.dst16x1:
    IDST16_1D_PACKED_1ROW
    ret

INV_TXFM_FN 16, 8
    add                 cfq, 32*4
    WIN64_SPILL_XMM      13
    vpbroadcastd         m8, [o(pw_181x128)]
    jmp                tx1q

.dconly:
    movd                xm3, [o(pw_181x128)]
    pmulhrsw            xm3, [cfq]
    movd                xm2, [o(pw_33)]
    or                  r4d, 4
    paddw               xm3, xm2
    psraw               xm3, 6
    jmp m(inv_txfm_add_16x4_8bpc).dconly3

.pass1_dct:
    pmulhrsw             m0, m8, [cfq-32*4]
    pmulhrsw             m1, m8, [cfq-32*3]
    pmulhrsw             m2, m8, [cfq-32*2]
    pmulhrsw             m3, m8, [cfq-32*1]
    vpbroadcastd        m10, [o(pd_64)]
    REPX {vpermq x, x, q3120}, m0, m1, m2, m3
    lea                 r3d, [eobq+(21<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r3d
    cmp                eobd, 64<<16
    jl .pass1_dct_fast
    pmulhrsw             m4, m8, [cfq+32*0]
    pmulhrsw             m5, m8, [cfq+32*1]
    pmulhrsw             m6, m8, [cfq+32*2]
    pmulhrsw             m7, m8, [cfq+32*3]
    REPX {vpermq x, x, q3120}, m4, m5, m6, m7
    call m(inv_txfm_add_8x16_8bpc).dct16
    jmp .pass1_dct2
.pass1_dct_fast:
    call m(inv_txfm_add_8x16_8bpc).dct16_fast
.pass1_dct2:
%macro IDCT_8X16_PASS1_END 4 ; a[1-2], b_mem, shift
    mova                 m9, [cfq+32*(%3+0)]
    mova                m10, [cfq+32*(%3+4)]
    psubd                m8, %1, m9
    paddd                %1, m9
%if %3 & 1
    psubd                m9, %2, m10
    paddd                %2, m10
%else ; odd upper rows are inverted
    paddd                m9, %2, m10
    psubd                %2, m10
%endif
    REPX      {psrad x, %4}, %1, m9, m8, %2
    packssdw             %1, m9
    packssdw             %2, m8
%endmacro
    IDCT_8X16_PASS1_END  m0, m7, -4, 7
    IDCT_8X16_PASS1_END  m1, m6, -3, 7
    IDCT_8X16_PASS1_END  m2, m5, -2, 7
    IDCT_8X16_PASS1_END  m3, m4, -1, 7
.pass1_end:
    call .transpose8x8_vpermq
    jmp                tx2q
.pass2_dct:
    mova         [cfq+32*0], m0
    mova         [cfq+32*1], m2
    mova         [cfq+32*2], m4
    mova         [cfq+32*3], m6
    call .dct8
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    mova         [cfq+32*2], m6
    mova         [cfq+32*3], m7
    vpbroadcastd        m10, [o(pd_1024)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m11, [cfq-32*4]
    mova                 m9, [cfq+32*0]
    psubd               m10, m0, m11
    paddd                m0, m11
    paddd               m11, m4, m9
    psubd                m4, m9
    mova                 m8, [cfq-32*3]
    mova                 m9, [cfq+32*1]
    psrad                m0, 11
    psrad               m11, 11
    packssdw             m0, m11
    psubd               m11, m1, m8
    paddd                m1, m8
    paddd                m8, m5, m9
    psubd                m5, m9
    psrad                m1, 11
    psrad                m8, 11
    packssdw             m1, m8
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    mova                 m1, [cfq-32*2]
    mova                 m9, [cfq+32*2]
    paddd                m0, m2, m1
    psubd                m2, m1
    paddd                m1, m6, m9
    psubd                m6, m9
    mova                 m8, [cfq-32*1]
    mova                 m9, [cfq+32*3]
    psrad                m0, 11
    psrad                m1, 11
    packssdw             m0, m1
    paddd                m1, m3, m8
    psubd                m3, m8
    paddd                m8, m7, m9
    psubd                m7, m9
    psrad                m1, 11
    psrad                m8, 11
    packssdw             m1, m8
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    REPX      {psrad x, 11}, m3, m7, m2, m6
    packssdw             m0, m3, m7
    packssdw             m1, m2, m6
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    REPX      {psrad x, 11}, m11, m5, m10, m4
    packssdw             m0, m11, m5
    packssdw             m1, m10, m4
.pass2_end:
    call m(inv_txfm_add_16x4_8bpc).write_16x2
.pass2_end2:
    pxor                m10, m10
.pass2_end3:
    REPX {mova [cfq+32*x], m10}, -4, -3, -2, -1
    jmp m(inv_txfm_add_16x4_8bpc).pass2_end3
ALIGN function_align
.transpose8x8_vpermq:
    REPX {vpermq x, x, q3120}, m0, m1, m2, m3, m4, m5, m6, m7
.transpose8x8:
    punpckhwd            m8, m4, m5
    punpcklwd            m4, m5
    punpckhwd            m5, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m2, m3
    punpcklwd            m2, m3
    punpckhdq            m3, m0, m2
    punpckldq            m0, m2
    punpckldq            m2, m4, m6
    punpckhdq            m4, m6
    punpckhdq            m6, m5, m7
    punpckldq            m5, m7
    punpckldq            m7, m8, m1
    punpckhdq            m8, m1
    punpckhqdq           m1, m0, m2
    punpcklqdq           m0, m2
    punpcklqdq           m2, m3, m4
    punpckhqdq           m3, m4
    punpcklqdq           m4, m5, m7
    punpckhqdq           m5, m7
    punpckhqdq           m7, m6, m8
    punpcklqdq           m6, m8
    ret
ALIGN function_align
.dct8:
    vpbroadcastd         m4, [o(pw_18_75)]
    vpbroadcastd         m6, [o(pw_89_50)]
    punpcklwd            m8, m1, m5
    punpckhwd            m9, m1, m5
    punpcklwd           m11, m7, m3
    punpckhwd           m12, m7, m3
    pmaddwd              m1, m8, m6  ;  a0
    pmaddwd              m5, m9, m6
    pmaddwd              m3, m8, m4  ;  d0
    pmaddwd              m7, m9, m4
    pmaddwd              m0, m11, m4 ;  a1
    pmaddwd              m4, m12
    pmaddwd              m2, m11, m6 ; -d1
    pmaddwd              m6, m12
    paddd                m0, m1      ; out0a
    paddd                m4, m5      ; out0b
    psubd                m3, m2      ; out3a
    psubd                m7, m6      ; out3b
    vpbroadcastd         m6, [o(pw_75_m89)]
    vpbroadcastd         m2, [o(pw_50_18)]
    pmaddwd              m1, m8, m6  ;  b0
    pmaddwd              m8, m2      ;  c0
    pmaddwd              m5, m11, m2 ; -b1
    psubd                m1, m5      ; out1a
    pmaddwd              m5, m9, m6
    pmaddwd              m9, m2
    pmaddwd              m2, m12
    psubd                m5, m2      ; out1b
    pmaddwd              m2, m11, m6 ;  c1
    pmaddwd              m6, m12
    paddd                m2, m8      ; out2a
    paddd                m6, m9      ; out2b
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
    mova                xm4, [cfq-16*4]
    vinserti128          m4, [cfq+16*4], 1
    mova                xm5, [cfq-16*3]
    vinserti128          m5, [cfq+16*5], 1
    mova                xm6, [cfq-16*2]
    vinserti128          m6, [cfq+16*6], 1
    mova                xm7, [cfq-16*1]
    vinserti128          m7, [cfq+16*7], 1
    REPX   {pmulhrsw x, m8}, m0, m1, m2, m3, m4, m5, m6, m7
    REPX   {paddsw   x, x }, m0, m1, m2, m3, m4, m5, m6, m7
    call .transpose8x8
    jmp                tx2q
.pass2_identity:
    vpbroadcastd        m11, [o(pw_181x16)]
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
    call .write_16x8_rnd
    jmp .pass2_end2
.hdpcm:
    call .write_16x8_rnd_hdpcm
    jmp .pass2_end2
.vdpcm:
    call .write_16x8_rnd_vdpcm
    jmp .pass2_end2

.pass1_dst_fast:
    call .dst16x2_fast
    psrad                m0, 7
    psrad                m1, 7
    packssdw             m0, m1
    mova      [cfq+r8+32*3], m0
    add                  r8, 32
    jle .pass1_dst_fast
    jmp .pass1_dst_end
.pass1_flipddt:
    lea                  r3, [o(flipddt16_mat+32*7)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt16_mat+32*7)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst16_mat+32*7)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst16_mat+32*7)]
.pass1_dst:
    pmulhrsw            m11, m8, [cfq-32*4]
    pmulhrsw             m1, m8, [cfq-32*3]
    pmulhrsw             m2, m8, [cfq-32*2]
    pmulhrsw             m3, m8, [cfq-32*1]
    vpbroadcastd         m7, [o(pd_64)]
    REPX {vpermq x, x, q3120}, m11, m1, m2, m3
    punpcklwd           m10, m11, m1 ;  0  2
    punpckhwd           m11, m1      ;  1  3
    punpcklwd           m12, m2, m3  ;  4  6
    punpckhwd            m2, m3      ;  5  7
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(21<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r8d
    mov                  r8, -32*7
    cmp                eobd, 64<<16
    jl .pass1_dst_fast
    pmulhrsw             m4, m8, [cfq+32*0]
    pmulhrsw             m5, m8, [cfq+32*1]
    pmulhrsw             m6, m8, [cfq+32*2]
    pmulhrsw             m0, m8, [cfq+32*3]
    REPX {vpermq x, x, q3120}, m4, m5, m6, m0
    punpcklwd            m3, m4, m5 ;  8 10
    punpckhwd            m4, m5     ;  9 11
    punpcklwd            m5, m6, m0 ; 12 14
    punpckhwd            m6, m0     ; 13 15
.pass1_dst_loop:
    call m(inv_txfm_add_8x16_8bpc).dst16x1
    add                  r3, 32*8
    mova      [cfq+r8+32*3], m0
    call m(inv_txfm_add_8x16_8bpc).dst16x1
    sub                  r3, 32*9
    paddd                m1, m7, [cfq+r8+32*3]
    paddd                m0, m7
    psrad                m1, 7
    psrad                m0, 7
    packssdw             m0, m1, m0
    mova      [cfq+r8+32*3], m0
    add                  r8, 32
    jle .pass1_dst_loop
.pass1_dst_end:
%if WIN64
    pop                  r8
%endif
.pass1_dst_end2:
    mova                 m7, [cfq-32*4]
    mova                 m6, [cfq-32*3]
    mova                 m5, [cfq-32*2]
    mova                 m4, [cfq-32*1]
    mova                 m3, [cfq+32*0]
    mova                 m2, [cfq+32*1]
    mova                 m1, [cfq+32*2]
    jmp .pass1_end
.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat)]
.pass2_dst:
    punpcklwd           m10, m0, m2 ; 0 2
    punpckhwd            m0, m2
    punpcklwd            m2, m1, m3 ; 1 3
    punpckhwd            m1, m3
    punpcklwd            m3, m4, m6 ; 4 6
    punpckhwd            m4, m6
    punpcklwd           m11, m5, m7 ; 5 7
    punpckhwd            m5, m7
    mov                  r5, -32*7
.pass2_dst_loop:
    call .dst8
    psrad                m6, 8
    psrad                m7, 8
    packssdw             m6, m7
    mova      [cfq+r5+32*3], m6
    add                  r5, 32
    jle .pass2_dst_loop
    vpbroadcastd        m11, [o(pw_4096)]
    call .write_16x8_rnd2
    jmp .pass2_end2
ALIGN function_align
.dst8:
    vpbroadcastd         m7, [r3+4*0]
    vpbroadcastd         m9, [r3+4*1]
    pmaddwd              m6, m10, m7
    pmaddwd              m7, m0
    pmaddwd              m8, m2, m9
    pmaddwd              m9, m1
    paddd                m6, m8
    vpbroadcastd         m8, [r3+4*2]
    paddd                m7, m9
    pmaddwd              m9, m3, m8
    pmaddwd              m8, m4
    paddd                m6, m9
    vpbroadcastd         m9, [r3+4*3]
    add                  r3, 4*4
    paddd                m7, m8
    pmaddwd              m8, m11, m9
    pmaddwd              m9, m5
    paddd                m6, m8
    paddd                m7, m9
    ret
ALIGN function_align
.dst16x2_fast:
    IDST16_1D_PACKED_2ROWS_FAST 8
    sub                  r3, 32
    paddd                m0, m7
    paddd                m1, m7
    ret
ALIGN function_align
.write_16x8_rnd:
    pmulhrsw             m0, m11
    pmulhrsw             m1, m11
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    pmulhrsw             m0, m11, m2
    pmulhrsw             m1, m11, m3
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    pmulhrsw             m0, m11, m4
    pmulhrsw             m1, m11, m5
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    pmulhrsw             m0, m11, m6
    pmulhrsw             m1, m11, m7
    jmp m(inv_txfm_add_16x4_8bpc).write_16x2
ALIGN function_align
.write_16x8_rnd2:
    pmulhrsw             m0, m11, [cfq-32*4]
    pmulhrsw             m1, m11, [cfq-32*3]
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    pmulhrsw             m0, m11, [cfq-32*2]
    pmulhrsw             m1, m11, [cfq-32*1]
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    pmulhrsw             m0, m11, [cfq+32*0]
    pmulhrsw             m1, m11, [cfq+32*1]
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    pmulhrsw             m0, m11, [cfq+32*2]
    pmulhrsw             m1, m11, [cfq+32*3]
    jmp m(inv_txfm_add_16x4_8bpc).write_16x2
ALIGN function_align
.write_16x8_rnd_hdpcm:
    pmulhrsw             m0, m11
    pmulhrsw             m1, m11
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    pmulhrsw             m0, m11, m2
    pmulhrsw             m1, m11, m3
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    pmulhrsw             m0, m11, m4
    pmulhrsw             m1, m11, m5
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    pmulhrsw             m0, m11, m6
    pmulhrsw             m1, m11, m7
    jmp m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
ALIGN function_align
.write_16x8_rnd_hdpcm2:
    pmulhrsw             m0, m11, [cfq-32*4]
    pmulhrsw             m1, m11, [cfq-32*3]
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    pmulhrsw             m0, m11, [cfq-32*2]
    pmulhrsw             m1, m11, [cfq-32*1]
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    pmulhrsw             m0, m11, [cfq+32*0]
    pmulhrsw             m1, m11, [cfq+32*1]
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    pmulhrsw             m0, m11, [cfq+32*2]
    pmulhrsw             m1, m11, [cfq+32*3]
    jmp m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
ALIGN function_align
.write_16x8_rnd_vdpcm:
    REPX  {pmulhrsw x, m11}, m0, m1, m2, m3, m4, m5, m6, m7
.write_16x8_vdpcm:
    paddw                m1, m0
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    paddw                m0, m2, m1
    paddw                m1, m3, m0
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    paddw                m0, m4, m1
    paddw                m1, m5, m0
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    paddw                m0, m6, m1
    paddw                m1, m7, m0
    jmp m(inv_txfm_add_16x4_8bpc).write_16x2

; At the start of pass2 rows 0-7 are stored in m0-m7 and rows 8-15 in cfq
INV_TXFM_FN 16, 16
    add                 cfq, 32*4
    PROLOGUE              0, 8, 14, 32*32
    jmp                tx1q

.dconly:
    movd                xm3, [o(pw_256)]
    or                  r4d, 8
    jmp m(inv_txfm_add_16x4_8bpc).dconly2

.pass1_dct_fast:
    call m(inv_txfm_add_8x16_8bpc).pass1_fast_load
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_8x16_8bpc).dct16_fast
    IDCT_8X16_PASS1_END  m0, m7, -4, 6
    IDCT_8X16_PASS1_END  m1, m6, -3, 6
    IDCT_8X16_PASS1_END  m2, m5, -2, 6
    IDCT_8X16_PASS1_END  m3, m4, -1, 6
    jmp m(inv_txfm_add_16x8_8bpc).pass1_end
.pass1_dct:
    lea                 r3d, [eobq+(28<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    lea                  r7, [rsp+32*4]
    sub                eobd, 36<<16
    jl .pass1_dct_fast
    mova                 m1, [cfq-32* 3]
    mova                 m3, [cfq-32* 1]
    mova                 m5, [cfq+32* 1]
    mova                 m7, [cfq+32* 3]
    mova                 m8, [cfq+32* 5]
    mova                 m9, [cfq+32* 7]
    mova                m10, [cfq+32* 9]
    mova                m11, [cfq+32*11]
    call .dct16
    lea                  r3, [cfq+32* 8]
    mova                 m1, [cfq-32* 2] ;  2
    mova                 m3, [cfq+32* 2] ;  6
    mova                 m5, [r3 -32* 2] ; 10
    mova                 m7, [r3 +32* 2] ; 14
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32* 0] ;  4
    mova                 m2, [r3 -32* 4] ;  8
    mova                 m3, [r3 +32* 0] ; 12
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq+32*1], m6
    mova         [cfq+32*0], m7
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                 m8, [cfq+32* 3] ; dct8  b0
    mova                 m9, [cfq-32* 4]
    mova                m10, [r7 -32* 4] ; dct16 c0
    mova                m11, [r7 +32* 4]
    psubd               m12, m0, m8      ; a7
    paddd                m0, m8          ; a0
    psubd                m8, m4, m9
    paddd                m4, m9
    psubd                m9, m0, m10     ; out15a
    paddd               m10, m0          ; out0a
    psubd                m0, m4, m11     ; out15b
    paddd                m4, m11         ; out0b
    mova                m11, [r7 +32* 0] ; dct16 b7
    mova                m13, [r7 +32* 8]
    REPX       {psrad x, 6}, m10, m4, m9, m0
    packssdw            m10, m4
    packssdw             m9, m0
    psubd                m4, m12, m11    ; out7a
    paddd               m12, m11         ; out8a
    psubd                m0, m8, m13     ; out7b
    paddd                m8, m13         ; out8b
    mova                m11, [cfq+32* 2] ; dct8  b1
    mova                m13, [cfq-32* 3]
    REPX       {psrad x, 6}, m4, m0, m12, m8
    packssdw             m4, m0
    packssdw            m12, m8
    mova         [r3 +16*6], xm10
    vextracti128 [cfq+16*6], m10, 1
    mova         [r3 -16*7], xm9
    vextracti128 [cfq-16*7], m9, 1
    mova         [r3 -16*8], xm4
    vextracti128 [cfq-16*8], m4, 1
    mova         [r3 +16*7], xm12
    vextracti128 [cfq+16*7], m12, 1
    mova                 m4, [r7 -32* 3] ; dct16 b1
    mova                 m0, [r7 +32* 5]
    psubd               m10, m1, m11     ; a6
    paddd                m1, m11         ; a1
    psubd                m9, m5, m13
    paddd                m5, m13
    psubd                m8, m1, m4      ; out14a
    paddd                m1, m4          ; out1a
    psubd                m4, m5, m0      ; out14b
    paddd                m5, m0          ; out1b
    mova                m11, [r7 +32* 1] ; dct16 b6
    mova                 m0, [r7 +32* 9]
    REPX       {psrad x, 6}, m1, m5, m8, m4
    packssdw             m1, m5
    packssdw             m8, m4
    psubd                m5, m10, m11    ; out9a
    paddd               m10, m11         ; out6a
    psubd               m11, m9, m0      ; out9b
    paddd                m0, m9          ; out6b
    REPX       {psrad x, 6}, m10, m0, m5, m11
    packssdw            m10, m0
    packssdw             m5, m11
    mova         [r3 +16*4], xm1
    vextracti128 [cfq+16*4], m1, 1
    mova         [r3 -16*5], xm8
    vextracti128 [cfq-16*5], m8, 1
    mova         [r3 -16*6], xm10
    vextracti128 [cfq-16*6], m10, 1
    mova         [r3 +16*5], xm5
    vextracti128 [cfq+16*5], m5, 1
    mova                 m0, [cfq-32* 2] ; dct8  b2
    mova                 m4, [cfq+32* 1]
    mova                 m1, [r7 -32* 2] ; dct16 b2
    mova                 m5, [r7 +32* 6]
    psubd                m8, m2, m0      ; a5
    paddd                m2, m0          ; a2
    psubd                m0, m6, m4
    paddd                m6, m4
    psubd                m4, m2, m1      ; out13a
    paddd                m2, m1          ; out2a
    psubd                m1, m6, m5      ; out13b
    paddd                m6, m5          ; out2b
    mova                 m5, [r7 +32* 2] ; dct16 b5
    mova                 m9, [r7 +32*10]
    REPX       {psrad x, 6}, m2, m6, m4, m1
    packssdw             m2, m6
    packssdw             m4, m1
    psubd                m6, m8, m5      ; out5a
    paddd                m8, m5          ; out10a
    psubd                m5, m0, m9      ; out5b
    paddd                m0, m9          ; out10b
    REPX       {psrad x, 6}, m6, m5, m8, m0
    packssdw             m6, m5
    packssdw             m8, m0
    mova         [r3 +16*2], xm2
    vextracti128 [cfq+16*2], m2, 1
    mova         [r3 -16*3], xm4
    vextracti128 [cfq-16*3], m4, 1
    mova         [r3 -16*4], xm6
    vextracti128 [cfq-16*4], m6, 1
    mova         [r3 +16*3], xm8
    vextracti128 [cfq+16*3], m8, 1
    mova                 m5, [cfq-32* 1] ; dct8  b3
    mova                 m1, [cfq+32* 0]
    mova                 m4, [r7 -32* 1] ; dct16 b3
    mova                 m0, [r7 +32* 7]
    psubd                m9, m3, m5      ; a4
    paddd                m3, m5          ; a3
    psubd                m5, m7, m1
    paddd                m7, m1
    psubd                m1, m3, m4      ; out12a
    paddd                m3, m4          ; out3a
    psubd                m4, m7, m0      ; out12b
    paddd                m7, m0          ; out3b
    mova                m10, [r7 +32* 3] ; dct16 b4
    mova                 m0, [r7 +32*11]
    REPX       {psrad x, 6}, m3, m7, m1, m4
    packssdw             m3, m7
    packssdw             m1, m4
    psubd                m7, m9, m10     ; out11a
    paddd                m9, m10         ; out4a
    psubd                m4, m5, m0      ; out11b
    paddd                m5, m0          ; out4b
    REPX       {psrad x, 6}, m9, m5, m7, m4
    packssdw             m9, m5
    packssdw             m7, m4
    mova         [r3 +16*0], xm3
    vextracti128 [cfq+16*0], m3, 1
    mova         [r3 -16*1], xm1
    vextracti128 [cfq-16*1], m1, 1
    mova         [r3 -16*2], xm9
    vextracti128 [cfq-16*2], m9, 1
    mova         [r3 +16*1], xm7
    vextracti128 [cfq+16*1], m7, 1
.pass1_end:
    mova                 m0, [cfq+32*3]
    mova                 m1, [cfq+32*2]
    mova                 m2, [cfq+32*1]
    mova                 m3, [cfq+32*0]
    mova                 m4, [cfq-32*1]
    mova                 m5, [cfq-32*2]
    mova                 m6, [cfq-32*3]
    mova                 m7, [cfq-32*4]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    mova         [cfq+32*2], m6
    mova         [cfq+32*3], m7
    mova                 m0, [r3+32*3]
    mova                 m1, [r3+32*2]
    mova                 m2, [r3+32*1]
    mova                 m3, [r3+32*0]
    mova                 m4, [r3-32*1]
    mova                 m5, [r3-32*2]
    mova                 m6, [r3-32*3]
    mova                 m7, [r3-32*4]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    jmp                tx2q
.pass2_dct:
    lea                  r7, [rsp+32*4]
    test               eobd, eobd
    jl .pass2_dct_fast
    mova                 m8, [cfq-32*3] ;  9
    mova                 m9, [cfq-32*1] ; 11
    mova                m10, [cfq+32*1] ; 13
    mova                m11, [cfq+32*3] ; 15
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m2
    mova         [cfq+32*1], m4
    mova         [cfq+32*3], m6
    call .dct16
    mova                 m1, [cfq-32*1] ;  2
    mova                 m3, [cfq+32*3] ;  6
    mova                 m5, [cfq-32*2] ; 10
    mova                 m7, [cfq+32*2] ; 14
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova                 m0, [cfq-32*3] ;  0
    mova                 m1, [cfq+32*1] ;  4
    mova                 m2, [cfq-32*4] ;  8
    mova                 m3, [cfq+32*0] ; 12
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq+32*1], m6
    mova         [cfq+32*0], m7
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass2_dct_end
.pass2_dct_fast:
    call .dct16_fast
    mova         [cfq+32*3], m1
    mova         [cfq+32*2], m2
    mova         [cfq-32*2], m3
    mova         [cfq-32*1], m8
    mova         [cfq-32*4], m5
    mova         [cfq-32*3], m6
    mova         [cfq+32*1], m7
    mova         [cfq+32*0], m9
    vpbroadcastd        m10, [o(pd_4096)]
    call .dct4_fast
.pass2_dct_end:
    mova                m11, [cfq+32* 3]
    mova                m12, [cfq-32* 4]
    mova                 m9, [r7 -32* 4]
    mova                m13, [r7 +32* 4]
    psubd               m10, m0, m11
    paddd                m0, m11
    psubd               m11, m4, m12
    paddd                m4, m12
    psubd               m12, m0, m9  ; out15a
    paddd                m0, m9      ; out0a
    psubd                m9, m4, m13 ; out15b
    paddd                m4, m13     ; out0b
    mova                 m8, [cfq+32* 2]
    mova                m13, [cfq-32* 3]
    REPX      {psrad x, 13}, m0, m4, m12, m9
    packssdw             m0, m4
    mova                 m4, [r7 -32* 3]
    packssdw            m12, m9
    mova                 m9, [r7 +32* 5]
    mova         [cfq-32*4], m12
    psubd               m12, m1, m8
    paddd                m1, m8
    paddd                m8, m5, m13
    psubd                m5, m13
    psubd               m13, m1, m4  ; out14a
    paddd                m1, m4      ; out1a
    psubd                m4, m8, m9  ; out14b
    paddd                m8, m9      ; out1b
    REPX      {psrad x, 13}, m1, m8, m13, m4
    packssdw             m1, m8
    packssdw            m13, m4
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    mova                 m4, [cfq-32* 2]
    mova                 m1, [cfq+32* 1]
    mova                 m9, [r7 -32* 2]
    mova                 m8, [r7 +32* 6]
    mova         [cfq-32*3], m13
    paddd                m0, m2, m4
    psubd                m2, m4
    psubd                m4, m6, m1
    paddd                m1, m6
    psubd                m6, m0, m9  ; out13a
    paddd                m0, m9      ; out2a
    psubd                m9, m1, m8  ; out13b
    paddd                m1, m8      ; out2b
    mova                 m8, [cfq-32* 1]
    mova                m13, [cfq+32* 0]
    REPX      {psrad x, 13}, m0, m1, m6, m9
    packssdw             m0, m1
    mova                 m1, [r7 -32* 1]
    packssdw             m6, m9
    mova                 m9, [r7 +32* 7]
    mova         [cfq-32*2], m6
    psubd                m6, m3, m8
    paddd                m8, m3
    paddd                m3, m7, m13
    psubd                m7, m13
    psubd               m13, m8, m1  ; out12a
    paddd                m1, m8      ; out3a
    paddd                m8, m3, m9  ; out3b
    psubd                m3, m9      ; out12b
    REPX      {psrad x, 13}, m1, m8, m13, m3
    packssdw             m1, m8
    packssdw            m13, m3
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    mova                 m0, [r7+32* 3]
    mova                 m1, [r7+32*11]
    mova         [cfq-32*1], m13
    psubd               m13, m6, m0  ; out11a
    paddd                m0, m6      ; out4a
    psubd                m6, m7, m1  ; out11b
    paddd                m1, m7      ; out4b
    mova                 m7, [r7+32* 2]
    mova                 m3, [r7+32*10]
    REPX      {psrad x, 13}, m0, m1
    packssdw             m0, m1
    psubd                m1, m2, m7  ; out5a
    paddd                m7, m2      ; out10a
    paddd                m2, m4, m3  ; out10b
    psubd                m4, m3      ; out5b
    REPX      {psrad x, 13}, m1, m4
    packssdw             m1, m4
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    mova                 m1, [r7+32* 1]
    mova                 m3, [r7+32* 9]
    paddd                m0, m12, m1 ; out6a
    psubd               m12, m1      ; out9a
    paddd                m1, m5, m3  ; out6b
    psubd                m5, m3      ; out9b
    mova                 m3, [r7+32* 0]
    mova                 m4, [r7+32* 8]
    REPX      {psrad x, 13}, m0, m1
    packssdw             m0, m1
    psubd                m1, m10, m3 ; out7a
    paddd               m10, m3      ; out8a
    psubd                m3, m11, m4 ; out7b
    paddd                m4, m11     ; out8b
    REPX      {psrad x, 13}, m1, m3
    packssdw             m1, m3
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    REPX      {psrad x, 13}, m10, m4, m12, m5
    packssdw             m0, m10, m4
    packssdw             m1, m12, m5
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    REPX      {psrad x, 13}, m7, m2, m13, m6
    packssdw             m0, m7, m2
    packssdw             m1, m13, m6
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    mova                 m0, [cfq-32*1]
    mova                 m1, [cfq-32*2]
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    mova                 m0, [cfq-32*3]
    mova                 m1, [cfq-32*4]
.pass2_end:
    call m(inv_txfm_add_16x4_8bpc).write_16x2
.pass2_end2:
    mov                  r6, -32*16
    call .zero_cf
    RET
ALIGN function_align
.zero_cf:
    sub                 cfq, r6
    pxor                 m0, m0
.zero_cf_loop:
    mova      [cfq+r6-32*4], m0
    mova      [cfq+r6-32*3], m0
    mova      [cfq+r6-32*2], m0
    mova      [cfq+r6-32*1], m0
    add                  r6, 32*4
    jl .zero_cf_loop
    ret
ALIGN function_align
.dct16:
    punpcklwd            m0, m1, m5
    punpckhwd            m1, m5
    punpcklwd            m2, m3, m7
    punpckhwd            m3, m7
    mov                 r3d, 16*3
    punpcklwd           m12, m10, m8
    punpckhwd           m10, m8
    punpcklwd           m13, m11, m9
    punpckhwd           m11, m9
.dct16_loop:
    vpbroadcastd         m7, [o(dct16_mat)+r3+4*0]
    vpbroadcastd         m5, [o(dct16_mat)+r3+4*1]
    pmaddwd              m8, m0, m7
    pmaddwd              m9, m1, m7
    pmaddwd              m6, m13, m7
    pmaddwd              m7, m11
    pmaddwd              m4, m2, m5
    paddd                m8, m4
    pmaddwd              m4, m3, m5
    paddd                m9, m4
    pmaddwd              m4, m12, m5
    pmaddwd              m5, m10
    psubd                m6, m4
    vpbroadcastd         m4, [o(dct16_mat)+r3+4*2]
    psubd                m7, m5
    pmaddwd              m5, m12, m4
    paddd                m8, m5
    pmaddwd              m5, m10, m4
    paddd                m9, m5
    pmaddwd              m5, m2, m4
    pmaddwd              m4, m3
    paddd                m6, m5
    vpbroadcastd         m5, [o(dct16_mat)+r3+4*3]
    paddd                m7, m4
    pmaddwd              m4, m13, m5
    paddd                m8, m4
    pmaddwd              m4, m11, m5
    paddd                m9, m4
    pmaddwd              m4, m0, m5
    pmaddwd              m5, m1
    psubd                m6, m4
    psubd                m7, m5
    mova     [r7+r3*2-32*4], m8
    mova     [r7+r3*2+32*4], m9
    mova     [r7+r3*2+32*0], m6
    mova     [r7+r3*2+32*8], m7
    sub                 r3d, 16
    jge .dct16_loop
    ret
ALIGN function_align
.dct16_fast:
    punpcklwd            m8, m1, m5
    punpckhwd            m9, m1, m5
    mov                 r3d, 16*3
    punpcklwd           m11, m3, m7
    punpckhwd           m12, m3, m7
.dct16_fast_loop:
    vpbroadcastd         m3, [o(dct16_mat)+r3+4*0]
    vpbroadcastd         m7, [o(dct16_mat)+r3+4*1]
    pmaddwd              m1, m8, m3
    pmaddwd              m3, m9
    pmaddwd              m5, m11, m7
    pmaddwd              m7, m12
    paddd                m1, m5
    vpbroadcastd         m5, [o(dct16_mat)+r3+4*2]
    paddd                m3, m7
    vpbroadcastd         m7, [o(dct16_mat)+r3+4*3]
    mova     [r7+r3*2-32*4], m1
    mova     [r7+r3*2+32*4], m3
    pmaddwd              m1, m11, m5
    pmaddwd              m5, m12
    pmaddwd              m3, m8, m7
    pmaddwd              m7, m9
    psubd                m1, m3
    psubd                m5, m7
    mova     [r7+r3*2+32*0], m1
    mova     [r7+r3*2+32*8], m5
    sub                 r3d, 16
    jge .dct16_fast_loop
; dct8_fast:
    punpcklwd            m8, m2, m6
    punpckhwd            m9, m2, m6
    vpbroadcastd         m5, [o(pw_89_75)]
    vpbroadcastd         m6, [o(pw_75_m18)]
    vpbroadcastd         m7, [o(pw_50_m89)]
    vpbroadcastd        m11, [o(pw_18_m50)]
    pmaddwd              m1, m8, m5 ; out0a
    pmaddwd              m5, m9     ; out0b
    pmaddwd              m2, m8, m6 ; out1a
    pmaddwd              m6, m9     ; out1b
    pmaddwd              m3, m8, m7 ; out2a
    pmaddwd              m7, m9     ; out2b
    pmaddwd              m8, m11    ; out3a
    pmaddwd              m9, m11    ; out3b
    ret
ALIGN function_align
.dct4_fast:
    vpbroadcastd         m8, [o(pd_64)]
    punpcklwd            m2, m0, m4
    punpckhwd            m3, m0, m4
    vpbroadcastd         m4, [o(pw_0_83)]
    vpbroadcastd         m5, [o(pw_0_35)]
    pmaddwd              m6, m2, m8 ; a
    pmaddwd              m8, m3
    pmaddwd              m0, m2, m4 ; b0
    pmaddwd              m4, m3
    pmaddwd              m1, m2, m5 ; b1
    pmaddwd              m5, m3
    paddd                m6, m10
    paddd                m8, m10
    psubd                m3, m6, m0 ; out3a
    paddd                m0, m6     ; out0a
    psubd                m7, m8, m4 ; out3b
    paddd                m4, m8     ; out0b
    psubd                m2, m6, m1 ; out2a
    paddd                m1, m6     ; out1a
    psubd                m6, m8, m5 ; out2b
    paddd                m5, m8     ; out1b
    ret

.pass1_identity_fast:
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [r3 -16*8], 1
    mova                xm1, [cfq-16*6]
    vinserti128          m1, [r3 -16*6], 1
    mova                xm2, [cfq-16*4]
    vinserti128          m2, [r3 -16*4], 1
    mova                xm3, [cfq-16*2]
    vinserti128          m3, [r3 -16*2], 1
    mova                xm4, [cfq+16*0]
    vinserti128          m4, [r3 +16*0], 1
    mova                xm5, [cfq+16*2]
    vinserti128          m5, [r3 +16*2], 1
    mova                xm6, [cfq+16*4]
    vinserti128          m6, [r3 +16*4], 1
    mova                xm7, [cfq+16*6]
    vinserti128          m7, [r3 +16*6], 1
    jmp .pass1_identity_end
.pass1_identity:
    lea                 r3d, [eobq-(128<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    lea                  r3, [cfq+32*8]
    test               eobd, eobd
    jl .pass1_identity_fast
    mova                xm0, [cfq-16*7]
    vinserti128          m0, [r3 -16*7], 1
    mova                xm1, [cfq-16*5]
    vinserti128          m1, [r3 -16*5], 1
    mova                xm2, [cfq-16*3]
    vinserti128          m2, [r3 -16*3], 1
    mova                xm3, [cfq-16*1]
    vinserti128          m3, [r3 -16*1], 1
    mova                xm4, [cfq+16*1]
    vinserti128          m4, [r3 +16*1], 1
    mova                xm5, [cfq+16*3]
    vinserti128          m5, [r3 +16*3], 1
    mova                xm6, [cfq+16*5]
    vinserti128          m6, [r3 +16*5], 1
    mova                xm7, [cfq+16*7]
    vinserti128          m7, [r3 +16*7], 1
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    paddsw               m8, m0, m0
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [r3 -16*8], 1
    paddsw               m9, m1, m1
    mova                xm1, [cfq-16*6]
    vinserti128          m1, [r3 -16*6], 1
    paddsw              m10, m2, m2
    mova                xm2, [cfq-16*4]
    vinserti128          m2, [r3 -16*4], 1
    paddsw              m11, m3, m3
    mova                xm3, [cfq-16*2]
    vinserti128          m3, [r3 -16*2], 1
    mova         [cfq-32*4], m8
    mova         [cfq-32*3], m9
    mova         [cfq-32*2], m10
    mova         [cfq-32*1], m11
    paddsw               m8, m4, m4
    mova                xm4, [cfq+16*0]
    vinserti128          m4, [r3 +16*0], 1
    paddsw               m9, m5, m5
    mova                xm5, [cfq+16*2]
    vinserti128          m5, [r3 +16*2], 1
    paddsw              m10, m6, m6
    mova                xm6, [cfq+16*4]
    vinserti128          m6, [r3 +16*4], 1
    paddsw              m11, m7, m7
    mova                xm7, [cfq+16*6]
    vinserti128          m7, [r3 +16*6], 1
    mova         [cfq+32*0], m8
    mova         [cfq+32*1], m9
    mova         [cfq+32*2], m10
    mova         [cfq+32*3], m11
.pass1_identity_end:
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    jmp                tx2q
.pass2_identity:
    vpbroadcastd        m11, [o(pw_1024)]
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
    call m(inv_txfm_add_16x8_8bpc).write_16x8_rnd
    call m(inv_txfm_add_16x8_8bpc).write_16x8_rnd2
    jmp .pass2_end2
.hdpcm:
    call m(inv_txfm_add_16x8_8bpc).write_16x8_rnd_hdpcm
    call m(inv_txfm_add_16x8_8bpc).write_16x8_rnd_hdpcm2
    jmp .pass2_end2
.vdpcm:
    call m(inv_txfm_add_16x8_8bpc).write_16x8_rnd_vdpcm
    pmulhrsw             m0, m11, [cfq-32*4]
    paddw                m0, m1
    pmulhrsw             m1, m11, [cfq-32*3]
    pmulhrsw             m2, m11, [cfq-32*2]
    pmulhrsw             m3, m11, [cfq-32*1]
    pmulhrsw             m4, m11, [cfq+32*0]
    pmulhrsw             m5, m11, [cfq+32*1]
    pmulhrsw             m6, m11, [cfq+32*2]
    pmulhrsw             m7, m11, [cfq+32*3]
    call m(inv_txfm_add_16x8_8bpc).write_16x8_vdpcm
    jmp .pass2_end2

.pass1_dst_fast:
    call m(inv_txfm_add_8x16_8bpc).pass1_fast_load
    punpcklwd           m10, m0, m1 ;  0  2
    vpbroadcastd         m7, [o(pd_32)]
    punpckhwd           m11, m0, m1 ;  1  3
    mov                  r7, -32*7
    punpcklwd           m12, m2, m3 ;  4  6
    sub                  r3, r7
    punpckhwd            m2, m3     ;  5  7
.pass1_dst_fast_loop:
    call m(inv_txfm_add_16x8_8bpc).dst16x2_fast
    psrad                m0, 6
    psrad                m1, 6
    packssdw             m0, m1
    mova      [cfq+r7+32*3], m0
    add                  r7, 32
    jle .pass1_dst_fast_loop
    jmp m(inv_txfm_add_16x8_8bpc).pass1_dst_end2
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
    lea                 r7d, [eobq+(28<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r7d
    sub                eobd, 36<<16
    jl .pass1_dst_fast
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    mova                 m7, [cfq+32*3]
    call .dst16x1
    mov                 r7d, 32*28
    mova      [rsp+r7+32*3], m1
    mova      [rsp+r7+32*2], m7
.pass1_dst_loop1:
    call .dst16x1b
    mova      [rsp+r7+32*1], m1
    mova      [rsp+r7+32*0], m7
    sub                 r7d, 32*2
    jge .pass1_dst_loop1
    lea                  r7, [cfq+32*8]
    mova                 m0, [r7-32*4]
    mova                 m1, [r7-32*3]
    mova                 m2, [r7-32*2]
    mova                 m3, [r7-32*1]
    mova                 m4, [r7+32*0]
    mova                 m5, [r7+32*1]
    mova                 m6, [r7+32*2]
    mova                 m7, [r7+32*3]
    add                  r3, 4*4-32*16
    call .dst16x1
    vpbroadcastd        m13, [o(pd_32)]
    mov                 r7d, 32*7
    jmp .pass1_dst_loop2a_start
.pass1_dst_loop2a: ; rows 0-7
    call .dst16x1b
.pass1_dst_loop2a_start:
    paddd                m8, m13, [rsp+r7*2+32*17]
    paddd                m9, m13, [rsp+r7*2+32*16]
    paddd                m1, m8
    paddd                m7, m9
    psrad                m1, 6
    psrad                m7, 6
    packssdw             m1, m7
    mova         [cfq+r7+16*8], xm1   ; storing xmm lanes separately avoids
    vextracti128 [cfq+r7-16*8], m1, 1 ; having to transpose them later
    sub                 r7d, 32
    jge .pass1_dst_loop2a
    mov                 r7d, 32*7
.pass1_dst_loop2b: ; rows 8-15
    call .dst16x1b
    paddd                m8, m13, [rsp+r7*2+32*1]
    paddd                m9, m13, [rsp+r7*2+32*0]
    paddd                m1, m8
    paddd                m7, m9
    psrad                m1, 6
    psrad                m7, 6
    packssdw             m1, m7
    mova         [cfq+r7+16*9], xm1
    vextracti128 [cfq+r7-16*7], m1, 1
    sub                 r7d, 32
    jge .pass1_dst_loop2b
    lea                  r3, [cfq+32*8]
    jmp .pass1_end
.pass2_dst_fast_loop:
    call .dst16x1b
.pass2_dst_fast:
    psrad                m1, 10
    psrad                m7, 10
    packssdw             m0, m1, m7
    call .dst16x1b
    psrad                m1, 10
    psrad                m7, 10
    packssdw             m1, m7
    pmulhrsw             m0, m13
    pmulhrsw             m1, m13
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    sub                 r5d, 32*4
    jge .pass2_dst_fast_loop
    jmp .pass2_end2
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
    call .dst16x1
    vpbroadcastd        m13, [o(pw_4096)]
    mov                 r5d, 32*28
    test               eobd, eobd
    jl .pass2_dst_fast
    mova      [rsp+r5+32*3], m1
    mova      [rsp+r5+32*2], m7
.pass2_loop1:
    call .dst16x1b
    mova      [rsp+r5+32*1], m1
    mova      [rsp+r5+32*0], m7
    sub                 r5d, 32*2
    jge .pass2_loop1
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    mova                 m7, [cfq+32*3]
    add                  r3, 4*4-32*16
    call .dst16x1
    mov                 r5d, 32*28
    jmp .pass2_dst_loop2_start
.pass2_dst_loop2:
    call .dst16x1b
.pass2_dst_loop2_start:
    paddd                m1, [rsp+r5+32*3]
    paddd                m7, [rsp+r5+32*2]
    psrad                m1, 10
    psrad                m7, 10
    packssdw             m0, m1, m7
    call .dst16x1b
    paddd                m1, [rsp+r5+32*1]
    paddd                m7, [rsp+r5+32*0]
    psrad                m1, 10
    psrad                m7, 10
    packssdw             m1, m7
    pmulhrsw             m0, m13
    pmulhrsw             m1, m13
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    sub                 r5d, 32*4
    jge .pass2_dst_loop2
    jmp .pass2_end2
ALIGN function_align
.dst16x1:
    punpcklwd           m10, m0, m2
    punpckhwd           m11, m0, m2
    punpcklwd            m2, m1, m3
    punpckhwd           m12, m1, m3
    punpcklwd            m3, m4, m6
    punpckhwd            m4, m6
    punpcklwd            m6, m5, m7
    punpckhwd            m5, m7
.dst16x1b:
    vpbroadcastd         m7, [r3+4*0]
    vpbroadcastd         m8, [r3+4*1]
    pmaddwd              m1, m10, m7
    pmaddwd              m7, m11
    pmaddwd              m9, m2, m8
    pmaddwd              m8, m12
    paddd                m1, m9
    vpbroadcastd         m9, [r3+4*2]
    paddd                m7, m8
    pmaddwd              m8, m3, m9
    pmaddwd              m9, m4
    paddd                m1, m8
    vpbroadcastd         m8, [r3+4*3]
    add                  r3, 32
    paddd                m7, m9
    pmaddwd              m9, m6, m8
    pmaddwd              m8, m5
    paddd                m1, m9
    paddd                m7, m8
    ret
ALIGN function_align
.dst16x2_fast:
    vpbroadcastd         m7, [r3+4*0]
    vpbroadcastd         m8, [r3+4*1]
    pmaddwd              m1, m10, m7
    pmaddwd              m7, m11
    pmaddwd              m9, m2, m8
    pmaddwd              m8, m12
    paddd                m1, m9
    vpbroadcastd         m9, [r3+4*2]
    paddd                m7, m8
    pmaddwd              m8, m3, m9
    pmaddwd              m9, m4
    paddd                m1, m8
    vpbroadcastd         m8, [r3+4*3]
    add                  r3, 32
    paddd                m7, m9
    pmaddwd              m9, m6, m8
    pmaddwd              m8, m5
    paddd                m1, m9
    paddd                m7, m8
    ret

INV_TXFM_FN 4, 32
    add                 cfq, 32*4
    WIN64_SPILL_XMM      13
    vpbroadcastd        m12, [o(pw_181x128)]
    pmulhrsw             m0, m12, [cfq-32*4]
    pmulhrsw             m1, m12, [cfq-32*2]
    pmulhrsw             m2, m12, [cfq+32*0]
    pmulhrsw             m3, m12, [cfq+32*2]
    jmp                tx1q

.dconly:
    vpbroadcastw        xm3, [cfq]
    vpbroadcastd        xm2, [o(pw_181x128)]
    or                  r4d, 8
    pmulhrsw            xm3, xm2
    vpbroadcastd        xm2, [o(pw_33)]
    paddw               xm3, xm2
    psraw               xm3, 6
    jmp m(inv_txfm_add_4x4_8bpc).dconly3

.pass1_dct:
    vpbroadcastd        m10, [o(pd_64)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    lea                 r3d, [eobq+(42<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    call m(inv_txfm_add_8x8_8bpc).shift7_pack
    sub                eobd, 58<<16
    jl .pass1_end3
    mova         [cfq-32*4], m0
    mova         [cfq-32*2], m1
    mova         [cfq+32*0], m2
    mova         [cfq+32*2], m3
    pmulhrsw             m0, m12, [cfq-32*3]
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m2, m12, [cfq+32*1]
    pmulhrsw             m3, m12, [cfq+32*3]
    call m(inv_txfm_add_16x4_8bpc).dct4
.pass1_end:
    REPX       {psrad x, 7}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    mova                 m0, [cfq-32*4]
    packssdw             m5, m1, m5
    mova                 m1, [cfq-32*2]
    REPX       {psrad x, 7}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    mova                 m2, [cfq+32*0]
    packssdw             m7, m3, m7
    mova                 m3, [cfq+32*2]
.pass1_end2:
    punpckhwd            m8, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m4, m5
    punpcklwd            m4, m5
    punpckhdq            m5, m4, m6 ; 18 19   26 27
    punpckldq            m4, m6     ; 16 17   24 25
    punpckldq            m6, m7, m8 ; 20 21   28 29
    punpckhdq            m7, m8     ; 22 23   30 31
.pass1_end3:
    punpckhwd            m8, m2, m3
    punpcklwd            m2, m3
    punpckhwd            m3, m0, m1
    punpcklwd            m0, m1
    punpckhdq            m1, m0, m2 ;  2  3   10 11
    punpckldq            m0, m2     ;  0  1    8  9
    punpckldq            m2, m3, m8 ;  4  5   12 13
    punpckhdq            m3, m8     ;  6  7   14 15
    test               eobb, 0x20
    jnz .pass2_identity
.pass2_dct:
    mov                  r5, rsp
    and                 rsp, ~31
    sub                 rsp, 32*8
    punpckhwd            m8, m0, m2 ;  1  5    9 13
    punpckhwd            m9, m1, m3 ;  3  7   11 15
    mova         [cfq-32*4], m0
    mova         [cfq+32*0], m1
    mova         [cfq-32*3], m2
    mova         [cfq+32*1], m3
    test               eobd, eobd
    jl .pass2_dct_fast
    mova         [cfq-32*1], m4
    mova         [cfq+32*2], m5
    mova         [cfq-32*2], m6
    mova         [cfq+32*3], m7
    punpckhwd            m6, m4     ; 21 17   29 25
    punpckhwd            m7, m5     ; 23 19   31 27
    vextracti128        xm2, m8, 1
    vextracti128        xm3, m9, 1
    vextracti128        xm4, m6, 1
    vextracti128        xm5, m7, 1
%if WIN64
    movaps             [r5], xm13
%endif
    call .dct32
    movq                xm0, [cfq+16*0]
    punpcklwd           xm0, [cfq+16*1] ;  2 10
    movq                xm1, [cfq+16*2]
    punpcklwd           xm1, [cfq+16*3] ;  6 14
    movq                xm2, [cfq+16*5]
    punpcklwd           xm2, [cfq+16*4] ; 26 18
    movq                xm3, [cfq+16*7]
    punpcklwd           xm3, [cfq+16*6] ; 30 22
    vpbroadcastd        m10, [o(pd_1024)]
    call m(inv_txfm_add_4x16_8bpc).dct16b
    add                  r3, 4*8
    mova         [cfq+16*0], xm8        ; b0
    mova         [cfq+16*1], xm9        ; b1
    mova         [cfq+16*6], xm12       ; b7
    mova         [cfq+16*7], xm11       ; b6
    call m(inv_txfm_add_4x16_8bpc).dct16b
    movq                xm7, [cfq-16*6]
    punpcklwd           xm7, [cfq-16*4] ;  4 20
    movq                xm2, [cfq-16*3]
    punpcklwd           xm2, [cfq-16*5] ; 28 12
    movq                xm0, [cfq-16*8]
    punpcklwd           xm0, [cfq-16*2] ;  0 16
    movq                xm1, [cfq-16*1]
    punpcklwd           xm1, [cfq-16*7] ; 24  8
    mova         [cfq+16*2], xm9        ; b3
    mova         [cfq+16*3], xm8        ; b2
    mova         [cfq+16*4], xm11       ; b4
    mova         [cfq+16*5], xm12       ; b5
    call m(inv_txfm_add_4x8_8bpc).dct8b
%if WIN64
    movaps             xm13, [r5]
%endif
    jmp .pass2_dct2
.pass2_dct_fast:
    vpbroadcastd        m10, [o(pd_1024)]
    vextracti128        xm2, m8, 1
    vextracti128        xm3, m9, 1
    call .dct32_fast
    movq                xm9, [cfq-16*8]
    punpcklwd           xm9, [cfq-16*7] ;  0  8
    movq                xm0, [cfq+16*0]
    punpcklwd           xm0, [cfq+16*1] ;  2 10
    movq                xm8, [cfq-16*6]
    punpcklwd           xm8, [cfq-16*5] ;  4 12
    movq                xm1, [cfq+16*2]
    punpcklwd           xm1, [cfq+16*3] ;  6 14
    call m(inv_txfm_add_4x16_8bpc).dct16_fast2
.pass2_dct2:
    mova                 m5, [cfq+32*0] ; b0    b1
    mova                 m7, [cfq+32*1] ; b3    b2
    mova                 m6, [rsp+32*0] ; c0    c1
    mova                 m8, [rsp+32*1] ; c3    c2
    psubd                m4, m0, m5     ; a15   a14
    paddd                m0, m5         ; a0    a1
    psubd                m5, m1, m7     ; a12   a13
    paddd                m1, m7         ; a3    a2
    psubd               m12, m0, m6     ; out31 out30
    paddd                m0, m6         ; out0  out1
    psubd               m11, m1, m8     ; out28 out29
    paddd                m1, m8         ; out3  out2
    psrad                m0, 11
    psrad                m1, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct_start
    mova                 m1, [cfq+32*2] ; b4    b5
    mova                 m7, [cfq+32*3] ; b7    b6
    mova                 m6, [rsp+32*2] ; c4    c5
    mova                 m8, [rsp+32*3] ; c7    c6
    paddd                m0, m2, m1     ; a4    a5
    psubd                m2, m1         ; a11   a10
    paddd                m1, m3, m7     ; a7    a6
    psubd                m3, m7         ; a8    a9
    psubd                m7, m0, m6     ; out27 out26
    paddd                m0, m6         ; out4  out5
    psubd                m6, m1, m8     ; out24 out25
    paddd                m1, m8         ; out7  out6
    psrad                m0, 11
    psrad                m1, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    mova                 m1, [rsp+32*4] ; c8    c9
    mova                 m8, [rsp+32*5] ; c11   c10
    paddd                m0, m3, m1     ; out8  out9
    psubd                m3, m1         ; out23 out22
    paddd                m1, m2, m8     ; out11 out10
    psubd                m2, m8         ; out20 out21
    psrad                m0, 11
    psrad                m1, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    mova                 m1, [rsp+32*6] ; c12   c13
    mova                 m8, [rsp+32*7] ; c15   c14
    paddd                m0, m5, m1     ; out12 out13
    psubd                m5, m1         ; out19 out18
    paddd                m1, m4, m8     ; out15 out14
    psubd                m4, m8         ; out16 out17
    psrad                m0, 11
    psrad                m1, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    psrad                m0, m4, 11
    psrad                m1, m5, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    psrad                m0, m2, 11
    psrad                m1, m3, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    psrad                m0, m6, 11
    psrad                m1, m7, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    psrad                m0, m11, 11
    psrad                m1, m12, 11
    call m(inv_txfm_add_4x8_8bpc).write_4x4_dct
    mov                 rsp, r5
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end2
ALIGN function_align
.dct32:
    ; Order the output such that the sumsub
    ; step to be done using ymm registers
    lea                  r3, [o(dct32_mat)]
    call .dct32b
    mova [rsp+gprsize+16* 0], xm0  ; b0
    mova [rsp+gprsize+16* 1], xm1  ; b1
    mova [rsp+gprsize+16*14], xm11 ; b15
    mova [rsp+gprsize+16*15], xm10 ; b14
    call .dct32b
    mova [rsp+gprsize+16* 2], xm1  ; b3
    mova [rsp+gprsize+16* 3], xm0  ; b2
    mova [rsp+gprsize+16*12], xm10 ; b12
    mova [rsp+gprsize+16*13], xm11 ; b13
    call .dct32b
    mova [rsp+gprsize+16* 4], xm0  ; b4
    mova [rsp+gprsize+16* 5], xm1  ; b5
    mova [rsp+gprsize+16*10], xm11 ; b11
    mova [rsp+gprsize+16*11], xm10 ; b10
    call .dct32b
    mova [rsp+gprsize+16* 6], xm1  ; b7
    mova [rsp+gprsize+16* 7], xm0  ; b6
    mova [rsp+gprsize+16* 8], xm10 ; b8
    mova [rsp+gprsize+16* 9], xm11 ; b9
    ret
.dct32b:
    vpbroadcastd       xm12, [r3+4* 0]
    vpbroadcastd       xm11, [r3+4* 1]
    vpbroadcastd       xm10, [r3+4* 8]
    vpbroadcastd       xm13, [r3+4* 9]
    pmaddwd             xm0, xm12, xm8
    pmaddwd             xm1, xm11, xm9
    pmaddwd            xm12, xm5
    pmaddwd            xm11, xm4
    paddd               xm0, xm1
    pmaddwd             xm1, xm10, xm8
    psubd              xm11, xm12
    pmaddwd            xm12, xm13, xm9
    pmaddwd            xm10, xm5
    pmaddwd            xm13, xm4
    paddd               xm1, xm12
    vpbroadcastd       xm12, [r3+4* 2]
    psubd              xm10, xm13
    pmaddwd            xm13, xm12, xm2
    pmaddwd            xm12, xm7
    paddd               xm0, xm13
    vpbroadcastd       xm13, [r3+4*10]
    psubd              xm11, xm12
    pmaddwd            xm12, xm13, xm2
    pmaddwd            xm13, xm7
    paddd               xm1, xm12
    vpbroadcastd       xm12, [r3+4* 3]
    paddd              xm10, xm13
    pmaddwd            xm13, xm12, xm3
    pmaddwd            xm12, xm6
    paddd               xm0, xm13
    vpbroadcastd       xm13, [r3+4*11]
    paddd              xm11, xm12
    pmaddwd            xm12, xm13, xm3
    pmaddwd            xm13, xm6
    paddd               xm1, xm12
    vpbroadcastd       xm12, [r3+4* 4]
    psubd              xm10, xm13
    pmaddwd            xm13, xm12, xm6
    pmaddwd            xm12, xm3
    paddd               xm0, xm13
    vpbroadcastd       xm13, [r3+4*12]
    psubd              xm11, xm12
    pmaddwd            xm12, xm13, xm6
    pmaddwd            xm13, xm3
    paddd               xm1, xm12
    vpbroadcastd       xm12, [r3+4* 5]
    paddd              xm10, xm13
    pmaddwd            xm13, xm12, xm7
    pmaddwd            xm12, xm2
    paddd               xm0, xm13
    vpbroadcastd       xm13, [r3+4*13]
    paddd              xm11, xm12
    pmaddwd            xm12, xm13, xm7
    pmaddwd            xm13, xm2
    paddd               xm1, xm12
    vpbroadcastd       xm12, [r3+4* 6]
    psubd              xm10, xm13
    pmaddwd            xm13, xm12, xm4
    pmaddwd            xm12, xm9
    paddd               xm0, xm13
    vpbroadcastd       xm13, [r3+4*14]
    psubd              xm11, xm12
    pmaddwd            xm12, xm13, xm4
    pmaddwd            xm13, xm9
    paddd               xm1, xm12
    vpbroadcastd       xm12, [r3+4* 7]
    paddd              xm10, xm13
    pmaddwd            xm13, xm12, xm5
    pmaddwd            xm12, xm8
    paddd               xm0, xm13 ; b0  + 2n
    vpbroadcastd       xm13, [r3+4*15]
    add                  r3, 4*16
    paddd              xm11, xm12 ; b15 - 2n
    pmaddwd            xm12, xm13, xm5
    pmaddwd            xm13, xm8
    paddd               xm1, xm12 ; b1  + 2n
    psubd              xm10, xm13 ; b14 - 2n
    ret
.dct32_fast:
    lea                  r3, [o(dct32_mat)]
    call .dct32_fast2
    mova [rsp+gprsize+16* 0], xm0 ; b0
    mova [rsp+gprsize+16* 1], xm1 ; b1
    mova [rsp+gprsize+16*14], xm7 ; b15
    mova [rsp+gprsize+16*15], xm6 ; b14
    call .dct32_fast2
    mova [rsp+gprsize+16* 2], xm1 ; b3
    mova [rsp+gprsize+16* 3], xm0 ; b2
    mova [rsp+gprsize+16*12], xm6 ; b12
    mova [rsp+gprsize+16*13], xm7 ; b13
    call .dct32_fast2
    mova [rsp+gprsize+16* 4], xm0 ; b4
    mova [rsp+gprsize+16* 5], xm1 ; b5
    mova [rsp+gprsize+16*10], xm7 ; b11
    mova [rsp+gprsize+16*11], xm6 ; b10
    call .dct32_fast2
    mova [rsp+gprsize+16* 6], xm1 ; b7
    mova [rsp+gprsize+16* 7], xm0 ; b6
    mova [rsp+gprsize+16* 8], xm6 ; b8
    mova [rsp+gprsize+16* 9], xm7 ; b9
    ret
.dct32_fast2:
    vpbroadcastd        xm0, [r3+4* 0]
    vpbroadcastd        xm7, [r3+4* 1]
    vpbroadcastd        xm1, [r3+4* 8]
    vpbroadcastd        xm5, [r3+4* 9]
    vpbroadcastd        xm4, [r3+4* 2]
    vpbroadcastd        xm6, [r3+4*10]
    pmaddwd             xm0, xm8
    pmaddwd             xm7, xm9
    pmaddwd             xm1, xm8
    pmaddwd             xm5, xm9
    pmaddwd             xm4, xm2
    pmaddwd             xm6, xm2
    paddd               xm0, xm7
    vpbroadcastd        xm7, [r3+4* 3]
    paddd               xm1, xm5
    vpbroadcastd        xm5, [r3+4*11]
    pmaddwd             xm7, xm3
    paddd               xm0, xm4
    vpbroadcastd        xm4, [r3+4* 4]
    pmaddwd             xm5, xm3
    paddd               xm1, xm6
    vpbroadcastd        xm6, [r3+4*12]
    paddd               xm0, xm7 ; b0  + 2n
    vpbroadcastd        xm7, [r3+4* 5]
    paddd               xm1, xm5 ; b1  + 2n
    vpbroadcastd        xm5, [r3+4*13]
    pmaddwd             xm4, xm3
    pmaddwd             xm6, xm3
    pmaddwd             xm7, xm2
    pmaddwd             xm5, xm2
    psubd               xm7, xm4
    vpbroadcastd        xm4, [r3+4* 6]
    psubd               xm6, xm5
    vpbroadcastd        xm5, [r3+4*14]
    pmaddwd             xm4, xm9
    pmaddwd             xm5, xm9
    psubd               xm7, xm4
    vpbroadcastd        xm4, [r3+4* 7]
    paddd               xm6, xm5
    vpbroadcastd        xm5, [r3+4*15]
    add                  r3, 4*16
    pmaddwd             xm4, xm8
    pmaddwd             xm5, xm8
    paddd               xm7, xm4 ; b15 - 2n
    psubd               xm6, xm5 ; b14 - 2n
    ret

.pass1_identity:
    lea                 r3d, [eobq-(64<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    test               eobd, eobd
    jl .pass1_end3
    pmulhrsw             m4, m12, [cfq-32*3]
    pmulhrsw             m5, m12, [cfq-32*1]
    pmulhrsw             m6, m12, [cfq+32*1]
    pmulhrsw             m7, m12, [cfq+32*3]
    jmp .pass1_end2
.pass2_identity:
    vpbroadcastd        m12, [o(pw_181x32)]
    REPX  {pmulhrsw x, m12}, m0, m1, m2, m3
    lea                  r6, [dsq*3]
    pxor                m10, m10
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
    call m(inv_txfm_add_4x16_8bpc).write_4x16
    test               eobd, eobd
    jl m(inv_txfm_add_16x8_8bpc).pass2_end2
    pmulhrsw             m0, m12, m4
    pmulhrsw             m1, m12, m5
    pmulhrsw             m2, m12, m6
    pmulhrsw             m3, m12, m7
    call m(inv_txfm_add_4x16_8bpc).write_4x16
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end2
.hdpcm:
    call m(inv_txfm_add_4x16_8bpc).write_4x16_hdpcm
    pmulhrsw             m0, m12, m4
    pmulhrsw             m1, m12, m5
    pmulhrsw             m2, m12, m6
    pmulhrsw             m3, m12, m7
    call m(inv_txfm_add_4x16_8bpc).write_4x16_hdpcm
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end2
.vdpcm:
    call m(inv_txfm_add_4x16_8bpc).write_4x16_vdpcm
    pmulhrsw             m4, m12
    pmulhrsw             m1, m12, m5
    psrldq              xm0, xm3, 8
    pmulhrsw             m2, m12, m6
    pmulhrsw             m3, m12, m7
    paddsw               m0, m4
    call m(inv_txfm_add_4x16_8bpc).write_4x16_vdpcm
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end2

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    call m(inv_txfm_add_16x4_8bpc).dst4
    vpbroadcastd         m8, [o(pd_64)]
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(42<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r8d
%if WIN64
    pop                  r8
%endif
    REPX      {paddd x, m8}, m0, m4, m1, m5, m2, m6, m3, m7
    call m(inv_txfm_add_8x8_8bpc).shift7_pack
    sub                eobd, 58<<16
    jl .pass1_end3
    mova         [cfq-32*4], m0
    mova         [cfq-32*2], m1
    mova         [cfq+32*0], m2
    mova         [cfq+32*2], m3
    pmulhrsw             m0, m12, [cfq-32*3]
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m2, m12, [cfq+32*1]
    pmulhrsw             m3, m12, [cfq+32*3]
    call m(inv_txfm_add_16x4_8bpc).dst4
    vpbroadcastd         m8, [o(pd_64)]
    REPX      {paddd x, m8}, m0, m4, m1, m5, m2, m6, m3, m7
    jmp .pass1_end

INV_TXFM_FN 32, 4
    add                 cfq, 32*4
    WIN64_SPILL_XMM      13
    vpbroadcastd        m11, [o(pw_181x128)]
    test               tx1b, 0x01
    jnz .pass1_identity

.pass1_dct:
    pmulhrsw             m0, m11, [cfq-32*4]
    pmulhrsw             m1, m11, [cfq-32*3]
    pmulhrsw             m2, m11, [cfq-32*2]
    pmulhrsw             m3, m11, [cfq-32*1]
%if WIN64
    push                 r8
%endif
    mov                  r8, rsp
    and                 rsp, ~31
    punpckhwd            m8, m0, m1     ;  1  5    3  7
    lea                 r3d, [eobq+(3<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r3d
    sub                 rsp, 32*8
    vextracti128        xm9, m8, 1
    cmp                eobd, 64<<16
    jl .pass1_dct_fast
    pmulhrsw            m12, m11, [cfq+32*0]
    pmulhrsw             m6, m11, [cfq+32*1]
    pmulhrsw             m5, m11, [cfq+32*2]
    pmulhrsw             m4, m11, [cfq+32*3]
    vpblendd             m7, m2, m12, 0x0f
    vpblendd            m11, m2, m12, 0xf0
    punpckhwd            m2, m3         ;  9 13   11 15
    punpcklwd            m0, m7         ;  0 16    2 10
    vpblendd             m7, m3, m6, 0xf0
    vpblendd             m3, m6, 0x0f
    punpckhwd            m6, m12        ; 21 17   23 19
    punpcklwd            m1, m3         ;  4 20    6 14
    punpcklwd            m7, m4, m7     ; 28 12   30 22
    punpckhwd            m4, m5         ; 29 25   31 27
    punpcklwd            m5, m11        ; 24  8   26 18
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m5
    mova         [cfq-32*1], m7
    vextracti128        xm3, m2, 1
    vextracti128        xm5, m4, 1
    vextracti128        xm7, m6, 1
%if WIN64
    movaps           [r8+8], xm13
%endif
    call m(inv_txfm_add_4x32_8bpc).dct32
    mova                xm0, [cfq-16*7] ;  2 10
    mova                xm1, [cfq-16*5] ;  6 14
    mova                xm2, [cfq-16*3] ; 26 18
    mova                xm3, [cfq-16*1] ; 30 22
    vpbroadcastd        m10, [o(pd_64)]
    call m(inv_txfm_add_4x16_8bpc).dct16b
    add                  r3, 4*8
    mova         [cfq+16*0], xm8        ; b0
    mova         [cfq+16*1], xm9        ; b1
    mova         [cfq+16*6], xm12       ; b7
    mova         [cfq+16*7], xm11       ; b6
    call m(inv_txfm_add_4x16_8bpc).dct16b
    mova                xm7, [cfq-16*6] ;  4 20
    mova                xm0, [cfq-16*8] ;  0 16
    mova                xm2, [cfq-16*2] ; 28 12
    mova                xm1, [cfq-16*4] ; 24  8
    mova         [cfq+16*2], xm9        ; b3
    mova         [cfq+16*3], xm8        ; b2
    mova         [cfq+16*4], xm11       ; b4
    mova         [cfq+16*5], xm12       ; b5
    call m(inv_txfm_add_4x8_8bpc).dct8b
%if WIN64
    movaps             xm13, [r8+8]
%endif
    jmp .pass1_dct2
.pass1_dct_fast:
    punpcklwd            m0, m2         ;  0  8    2 10
    punpckhwd            m2, m3         ;  9 13   11 15
    punpcklwd            m1, m3         ;  4 12    6 14
    vpbroadcastd        m10, [o(pd_64)]
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    vextracti128        xm3, m2, 1
    call m(inv_txfm_add_4x32_8bpc).dct32_fast
    mova                xm9, [cfq-16*8] ;  0  8
    mova                xm0, [cfq-16*7] ;  2 10
    mova                xm8, [cfq-16*6] ;  4 12
    mova                xm1, [cfq-16*5] ;  6 14
    call m(inv_txfm_add_4x16_8bpc).dct16_fast2
.pass1_dct2:
    mova                 m4, [cfq+32*0] ; b0    b1
    mova                 m5, [cfq+32*1] ; b3    b2
    mova                 m7, [rsp+32*0] ; c0    c1
    mova                 m6, [rsp+32*1] ; c3    c2
    psubd               m12, m0, m4     ; a15   a14
    paddd                m0, m4         ; a0    a1
    psubd               m11, m1, m5     ; a12   a13
    paddd                m1, m5         ; a3    a2
    psubd                m5, m0, m7     ; out31 out30
    paddd                m0, m7         ; out0  out1
    psubd                m7, m1, m6     ; out28 out29
    paddd                m1, m6         ; out3  out2
    REPX       {psrad x, 7}, m0, m1, m5, m7
    packssdw             m0, m1         ;  0  3    1  2
    packssdw             m7, m5         ; 28 31   29 30
    mova                 m4, [cfq+32*2] ; b4    b5
    mova                 m1, [cfq+32*3] ; b7    b6
    mova                 m6, [rsp+32*2] ; c4    c5
    mova                 m8, [rsp+32*3] ; c7    c6
    psubd                m5, m2, m4     ; a11   a10
    paddd                m2, m4         ; a4    a5
    paddd                m4, m3, m1     ; a7    a6
    psubd                m3, m1         ; a8    a9
    paddd                m1, m2, m6     ; out4  out5
    psubd                m2, m6         ; out27 out26
    psubd                m6, m4, m8     ; out24 out25
    paddd                m4, m8         ; out7  out6
    REPX       {psrad x, 7}, m1, m4, m2, m6
    packssdw             m1, m4         ;  4  7    5  6
    packssdw             m6, m2         ; 24 27   25 26
    mova                 m4, [rsp+32*4] ; c8    c9
    mova                 m8, [rsp+32*5] ; c11   c10
    paddd                m2, m3, m4     ; out8  out9
    psubd                m3, m4         ; out23 out22
    paddd                m4, m5, m8     ; out11 out10
    psubd                m5, m8         ; out20 out21
    REPX       {psrad x, 7}, m2, m4, m3, m5
    packssdw             m2, m4         ;  8 11    9 10
    packssdw             m5, m3         ; 20 23   21 22
    mova                 m4, [rsp+32*6] ; c12   c13
    mova                 m8, [rsp+32*7] ; c15   c14
    paddd                m3, m11, m4    ; out12 out13
    psubd               m11, m4         ; out19 out18
    psubd                m4, m12, m8    ; out16 out17
    paddd               m12, m8         ; out15 out14
    REPX       {psrad x, 7}, m3, m12, m11, m4
    packssdw             m3, m12        ; 12 15   13 14
    packssdw             m4, m11        ; 16 19   17 18
    mov                 rsp, r8
%if WIN64
    pop                  r8
%endif
    punpckhwd            m8, m4, m5
    punpcklwd            m4, m5
    punpckhwd            m5, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m2, m3
    punpcklwd            m2, m3
    vperm2i128           m3, m0, m4, 0x31
    vinserti128          m0, xm4, 1
    vinserti128          m4, m2, xm6, 1
    vperm2i128           m2, m6, 0x31
    vperm2i128           m6, m7, m8, 0x31
    vinserti128          m7, xm8, 1
    vperm2i128           m8, m1, m5, 0x31
    vinserti128          m1, xm5, 1
.pass1_dct_end:
    punpckhwd            m5, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m4, m2
    punpcklwd            m4, m2
    punpckhwd            m2, m0, m3
    punpcklwd            m0, m3
    punpckhwd            m3, m8, m1
    punpcklwd            m8, m1
    punpckhdq            m1, m0, m6
    punpckldq            m0, m6
    punpckldq            m6, m7, m3
    punpckhdq            m7, m3
    punpckhdq            m3, m2, m5
    punpckldq            m2, m5
    punpckhdq            m5, m4, m8
    punpckldq            m4, m8
    jmp                tx2q
.pass2_dct:
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    vpbroadcastd        m10, [o(pd_1024)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    REPX      {psrad x, 11}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    packssdw             m5, m1, m5
    REPX      {psrad x, 11}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    packssdw             m7, m3, m7
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    call m(inv_txfm_add_16x4_8bpc).dct4
    REPX      {psrad x, 11}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    mova                 m0, [cfq-32*4]
    packssdw             m5, m1, m5
    mova                 m1, [cfq-32*3]
    pxor                m10, m10
    call .write_32x2
    REPX      {psrad x, 11}, m2, m6, m3, m7
    mova                 m0, [cfq-32*2]
    mova                 m1, [cfq-32*1]
    packssdw             m4, m2, m6
    packssdw             m5, m3, m7
    call .write_32x2
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3

.dconly:
    movd                xm3, [o(pw_181x128)]
    pmulhrsw            xm3, [cfq]
    movd                xm2, [o(pw_33)]
    or                  r4d, 4
    paddw               xm3, xm2
    psraw               xm3, 6
.dconly2:
    vpbroadcastw         m3, xm3
    pxor                xm2, xm2
    mova              [cfq], xm2
.dconly_loop:
    movu                 m1, [dstq]
    punpcklbw            m0, m1, m2
    punpckhbw            m1, m2
    paddw                m0, m3
    paddw                m1, m3
    packuswb             m0, m1
    movu             [dstq], m0
    add                dstq, dsq
    dec                 r4d
    jg .dconly_loop
    vzeroupper
    ret

.pass1_identity:
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [cfq+16*0], 1 ;  0  1 16 17
    mova                xm1, [cfq-16*7]
    vinserti128          m1, [cfq+16*1], 1 ;  2  3 18 19
    mova                xm2, [cfq-16*6]
    vinserti128          m2, [cfq+16*2], 1 ;  4  5 20 21
    mova                xm3, [cfq-16*5]
    vinserti128          m3, [cfq+16*3], 1 ;  6  7 22 23
    mova                xm4, [cfq-16*4]
    vinserti128          m4, [cfq+16*4], 1 ;  8  9 24 25
    mova                xm5, [cfq-16*3]
    vinserti128          m5, [cfq+16*5], 1 ; 10 11 26 27
    mova                xm6, [cfq-16*2]
    vinserti128          m6, [cfq+16*6], 1 ; 12 13 28 29
    mova                xm7, [cfq-16*1]
    vinserti128          m7, [cfq+16*7], 1 ; 14 15 30 31
    vpbroadcastd        m12, [o(pw_53x512)]
    REPX  {pmulhrsw x, m11}, m0, m1, m2, m3, m4, m5, m6, m7
    punpckhwd            m8, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m2, m3
    punpcklwd            m2, m3
    punpckhwd            m3, m0, m8
    punpcklwd            m0, m8
    punpckhwd            m8, m2, m1
    punpcklwd            m2, m1
    punpckhqdq           m1, m0, m2
    punpcklqdq           m0, m2
    punpcklqdq           m2, m3, m8
    punpckhqdq           m3, m8
    call .identity_main
    punpckhwd            m8, m4, m5
    punpcklwd            m4, m5
    punpckhwd            m5, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m4, m8
    punpcklwd            m4, m8
    punpckhwd            m8, m6, m5
    punpcklwd            m6, m5
    punpckhqdq           m5, m4, m6
    punpcklqdq           m4, m6
    punpcklqdq           m6, m7, m8
    punpckhqdq           m7, m8
    jmp                tx2q
.pass2_identity:
    vpbroadcastd        m12, [o(pw_2048)]
    pxor                m10, m10
    REPX  {pmulhrsw x, m12}, m0, m4, m1, m5
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
.pass2_identity2:
    call .write_32x2
    pmulhrsw             m0, m12, m2
    pmulhrsw             m4, m12, m6
    pmulhrsw             m1, m12, m3
    pmulhrsw             m5, m12, m7
    call .write_32x2
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
.hdpcm:
    call .write_32x2_hdpcm
    pmulhrsw             m0, m12, m2
    pmulhrsw             m1, m12, m3
    pmulhrsw             m4, m12, m6
    pmulhrsw             m5, m12, m7
    call .write_32x2_hdpcm2
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
.vdpcm:
    paddw                m1, m0
    paddw                m5, m4
    call .write_32x2
    pmulhrsw             m0, m12, m2
    pmulhrsw             m4, m12, m6
    pmulhrsw             m2, m12, m3
    pmulhrsw             m3, m12, m7
    call .write_32x2_vdpcm2
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
ALIGN function_align
.write_32x2_hdpcm:
    vpbroadcastd        m11, [o(pb_14_15)]
.write_32x2_hdpcm2:
    pslldq               m8, m0, 2
    pslldq               m9, m1, 2
    paddw                m0, m8
    pslldq               m8, m4, 2
    paddw                m1, m9
    pslldq               m9, m5, 2
    paddw                m4, m8
    pslldq               m8, m0, 4
    paddw                m5, m9
    pslldq               m9, m1, 4
    paddw                m0, m8
    pslldq               m8, m4, 4
    paddw                m1, m9
    pslldq               m9, m5, 4
    paddw                m4, m8
    punpcklqdq           m8, m10, m0
    paddw                m5, m9
    punpcklqdq           m9, m10, m1
    paddw                m0, m8
    punpcklqdq           m8, m10, m4
    paddw                m1, m9
    punpcklqdq           m9, m10, m5
    paddw                m4, m8
    pshufb               m8, m0, m11
    paddw                m5, m9
    pshufb               m9, m1, m11
    paddsw               m4, m8
    paddsw               m5, m9
    pshufb              xm8, xm4, xm11
    pshufb              xm9, xm5, xm11
    vinserti128          m8, m10, xm8, 1
    vinserti128          m9, m10, xm9, 1
    paddsw               m0, m8
    paddsw               m4, m8
    paddsw               m1, m9
    paddsw               m5, m9
    jmp .write_32x2
.write_32x2_vdpcm2:
    paddsw               m0, m1
    paddsw               m4, m5
    paddsw               m1, m0, m2
    paddsw               m5, m4, m3
.write_32x2:
    movu                 m9, [dstq+dsq*0]
    punpcklbw            m8, m9, m10
    punpckhbw            m9, m10
    paddsw               m8, m0
    paddsw               m9, m4
    packuswb             m8, m9
    movu                 m9, [dstq+dsq*1]
    movu       [dstq+dsq*0], m8
    punpcklbw            m8, m9, m10
    punpckhbw            m9, m10
    paddsw               m8, m1
    paddsw               m9, m5
    packuswb             m8, m9
    movu       [dstq+dsq*1], m8
    lea                dstq, [dstq+dsq*2]
    ret
ALIGN function_align
.identity_main:
    pmulhrsw             m8, m12, m0 ; (x * 362 + 64) >> 7
    pmulhrsw             m9, m12, m1 ; = x * 2 + ((x * (181 - 128) + 32) >> 6)
    pmulhrsw            m10, m12, m2 ; = x * 2 + ((x * 53 * 512 + 16384) >> 15)
    pmulhrsw            m11, m12, m3
    REPX      {paddsw x, x}, m0, m1, m2, m3
    paddsw               m0, m8
    pmulhrsw             m8, m12, m4
    paddsw               m1, m9
    pmulhrsw             m9, m12, m5
    paddsw               m2, m10
    pmulhrsw            m10, m12, m6
    paddsw               m3, m11
    pmulhrsw            m11, m12, m7
    REPX      {paddsw x, x}, m4, m5, m6, m7
    paddsw               m4, m8
    paddsw               m5, m9
    paddsw               m6, m10
    paddsw               m7, m11
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
    call m(inv_txfm_add_16x4_8bpc).dst4
    vpbroadcastd        m12, [o(pw_2048)]
    REPX       {psrad x, 7}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    packssdw             m5, m1, m5
    REPX       {psrad x, 7}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    packssdw             m7, m3, m7
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    call m(inv_txfm_add_16x4_8bpc).dst4
    REPX       {psrad x, 7}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    pmulhrsw             m0, m12, [cfq-32*4]
    packssdw             m5, m1, m5
    pmulhrsw             m1, m12, [cfq-32*3]
    pmulhrsw             m4, m12
    pmulhrsw             m5, m12
    REPX       {psrad x, 7}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    mova                 m2, [cfq-32*2]
    packssdw             m7, m3, m7
    mova                 m3, [cfq-32*1]
    pxor                m10, m10
    jmp .pass2_identity2

INV_TXFM_FN 8, 32
    add                 cfq, 32*4
    PROLOGUE              0, 8, 13
    jmp                tx1q

.dconly:
    movd                xm5, [o(pw_256)]
    pmulhrsw            xm5, [cfq]
    or                  r4d, 8
    jmp m(inv_txfm_add_8x4_8bpc).dconly2

.pass1_dct:
    lea                 r3d, [eobq+(84<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    sub                eobd, 100<<16
    jl .pass1_dct_fast
    add                 cfq, 32
    call .pass1_dct_main
    mova         [cfq-32*4], m0
    mova         [cfq-32*2], m1
    mova         [cfq+32*0], m2
    mova         [cfq+32*2], m3
    sub                 cfq, 32
    mova         [r3 -32*4], m4
    mova         [r3 -32*2], m5
    mova         [r3 +32*0], m6
    mova         [r3 +32*2], m7
.pass1_dct_fast:
    call .pass1_dct_main
.pass1_end:
    test               eobb, 0x20
    jnz .pass2_identity
.pass2_dct:
    punpckhwd            m8, m0, m2      ;  1  5
    punpckhwd            m9, m1, m3      ;  3  7
    punpcklwd            m1, m5          ;  2 10
    punpcklwd           m10, m3, m7      ;  6 14
    punpckhwd            m3, m5, m7      ; 11 15
    mova         [cfq-32*4], m1
    mova         [cfq+32*0], m10
    mov                  r5, rsp
    and                 rsp, ~31
%if WIN64
    mova               [r5], xm13
%endif
    sub                 rsp, 32*16
    lea                  r7, [rsp+32*4]
    test               eobd, eobd
    jl .pass2_dct_fast
    mova                m10, [cfq-32* 3] ; 16 17
    mova                 m1, [cfq-32* 1] ; 18 19
    mova                m11, [cfq+32* 1] ; 20 21
    mova                 m7, [cfq+32* 3] ; 22 23
    punpcklwd            m0, m10         ;  0 16
    mova         [cfq-32*1], m0
    punpcklwd            m2, m11         ;  4 20
    mova         [cfq-32*2], m2
    punpckhwd            m2, m4, m6      ;  9 13
    mova                 m0, [cfq+32* 5] ; 24 25
    mova                m13, [cfq+32* 7] ; 26 27
    mova                m12, [cfq+32* 9] ; 28 29
    mova                 m5, [cfq+32*11] ; 30 31
    punpcklwd            m4, m0, m4      ; 24  8
    mova         [cfq+32*3], m4
    punpckhwd            m4, m12, m0     ; 29 25
    punpcklwd           m12, m6          ; 28 12
    mova         [cfq+32*2], m12
    punpckhwd            m6, m11, m10    ; 21 17
    punpcklwd            m0, m5, m7      ; 30 22
    mova         [cfq+32*1], m0
    punpckhwd            m7, m1          ; 23 19
    punpckhwd            m5, m13         ; 31 27
    punpcklwd           m13, m1          ; 26 18
    mova         [cfq-32*3], m13
    call .dct32
    mova                 m8, [cfq-32*4]  ;  2 10
    mova                 m9, [cfq+32*0]  ;  6 14
    mova                m11, [cfq-32*3]  ; 26 18
    mova                m12, [cfq+32*1]  ; 30 22
    mova                 m0, [cfq-32*1]  ;  0 16
    mova                 m7, [cfq-32*2]  ;  4 20
    mova                 m1, [cfq+32*3]  ; 24  8
    mova                 m2, [cfq+32*2]  ; 28 12
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_8x16_8bpc).dct16b
    jmp .pass2_dct2
.pass2_dct_fast:
    punpcklwd            m0, m4          ;  0  8
    punpcklwd           m10, m2, m6      ;  4 12
    punpckhwd            m2, m4, m6      ;  9 13
    mova         [cfq-32*2], m0
    mova         [cfq+32*2], m10
    call .dct32_fast
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq+32*0]
    mova                 m8, [cfq+32*2]
    mova                 m9, [cfq-32*2]
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_8x16_8bpc).dct16_fast2
.pass2_dct2:
    mova                m13, [cfq-32*4]  ; b0
    mova                 m9, [cfq-32*3]  ; b1
    mova                m10, [r7 -32*4]  ; c0
    mova                 m8, [r7 -32*3]  ; c1
    psubd               m11, m0, m13     ; a15
    paddd                m0, m13         ; a0
    psubd               m13, m1, m9      ; a14
    paddd                m1, m9          ; a1
    psubd                m9, m0, m10     ; out31
    paddd                m0, m10         ; out0
    psubd               m10, m1, m8      ; out30
    paddd                m1, m8          ; out1
    REPX      {psrad x, 13}, m0, m1, m9, m10
    packssdw             m0, m1          ;  0  1
    packssdw            m10, m9          ; 30 31
    mova                m12, [cfq-32*2]  ; b2
    mova                 m1, [cfq-32*1]  ; b3
    mova                 m8, [r7 -32*2]  ; c2
    mova                 m9, [r7 -32*1]  ; c3
    mova         [cfq-32*4], m13
    mova         [cfq-32*3], m11
    mova         [cfq-32*2], m10
    psubd               m13, m2, m12     ; a13
    paddd                m2, m12         ; a2
    psubd               m12, m3, m1      ; a12
    paddd                m3, m1          ; a3
    paddd                m1, m2, m8      ; out2
    psubd                m2, m8          ; out29
    psubd                m8, m3, m9      ; out28
    paddd                m3, m9          ; out3
    REPX      {psrad x, 13}, m1, m3, m2, m8
    packssdw             m1, m3          ;  2  3
    packssdw             m8, m2          ; 28 29
    mova         [cfq-32*1], m8
    call m(inv_txfm_add_8x4_8bpc).write_8x4_start
    mova                 m3, [cfq+32*3]  ; b4
    mova                 m0, [cfq+32*2]  ; b5
    mova                 m1, [r7 +32*0]  ; c4
    mova                 m8, [r7 +32*1]  ; c5
    psubd                m2, m4, m3      ; a11
    paddd                m4, m3          ; a4
    paddd                m3, m5, m0      ; a10
    psubd                m5, m0          ; a5
    paddd                m0, m4, m1      ; out4
    psubd                m4, m1          ; out27
    paddd                m1, m5, m8      ; out5
    psubd                m5, m8          ; out26
    REPX      {psrad x, 13}, m0, m1, m4, m5
    packssdw             m0, m1          ;  4  5
    packssdw             m5, m4          ; 26 27
    mova                 m4, [cfq+32*1]  ; b6
    mova                 m1, [cfq+32*0]  ; b7
    mova                 m8, [r7 +32*2]  ; c6
    mova                m11, [r7 +32*3]  ; c7
    add                  r7, 32*8
    paddd                m9, m6, m4      ; a6
    psubd                m6, m4          ; a9
    paddd                m4, m7, m1      ; a8
    psubd                m7, m1          ; a7
    paddd                m1, m9, m8      ; out6
    psubd                m9, m8          ; out25
    paddd                m8, m7, m11     ; out7
    psubd                m7, m11         ; out24
    REPX      {psrad x, 13}, m1, m8, m9, m7
    packssdw             m1, m8          ;  6  7
    packssdw             m7, m9          ; 24 25
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    mova                 m1, [r7 +32*3]  ; c8
    mova                 m8, [r7 +32*2]  ; c9
    paddd                m0, m4, m1      ; out8
    psubd                m4, m1          ; out23
    psubd                m1, m6, m8      ; out9
    paddd                m6, m8          ; out22
    REPX      {psrad x, 13}, m0, m1, m4, m6
    packssdw             m0, m1          ;  8  9
    packssdw             m6, m4          ; 22 23
    mova                 m4, [r7 +32*1]  ; c10
    mova                 m8, [r7 +32*0]  ; c11
    paddd                m1, m3, m4      ; out10
    psubd                m3, m4          ; out21
    psubd                m4, m2, m8      ; out11
    paddd                m2, m8          ; out20
    REPX      {psrad x, 13}, m1, m4, m3, m2
    packssdw             m1, m4          ; 10 11
    packssdw             m2, m3          ; 20 21
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    mova                 m1, [r7 -32*1]  ; c12
    mova                 m3, [r7 -32*2]  ; c13
    paddd                m0, m12, m1     ; out12
    psubd               m12, m1          ; out19
    psubd                m1, m13, m3     ; out13
    paddd               m13, m3          ; out18
    mova                 m3, [cfq-32*4]  ; a14
    mova                 m8, [r7 -32*3]  ; c14
    mova                 m4, [cfq-32*3]  ; a15
    mova                 m9, [r7 -32*4]  ; c15
    REPX      {psrad x, 13}, m0, m1, m12, m13
    packssdw             m0, m1          ; 12 13
    paddd                m1, m3, m8      ; out14
    psubd                m3, m8          ; out17
    psubd                m8, m4, m9      ; out15
    paddd                m4, m9          ; out16
    REPX      {psrad x, 13}, m1, m8, m3, m4
    packssdw             m1, m8          ; 14 15
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    packssdw             m0, m4, m3      ; 16 17
    packssdw             m1, m13, m12    ; 18 19
    call m(inv_txfm_add_8x4_8bpc).write_8x4_vpermq
    vpermq               m0, m2, q3120
    vpermq               m1, m6, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    vpermq               m0, m7, q3120
    vpermq               m1, m5, q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4
    vpermq               m0, [cfq-32*1], q3120
    vpermq               m1, [cfq-32*2], q3120
    call m(inv_txfm_add_8x4_8bpc).write_8x4
%if WIN64
    mova               xm13, [r5]
%endif
    mov                 rsp, r5
    jmp m(inv_txfm_add_32x8_8bpc).pass2_end
ALIGN function_align
.pass1_dct_main:
    lea                  r3, [cfq+32*8]
    mova                 m1, [cfq-32*2]
    mova                 m3, [cfq+32*2]
    mova                 m5, [r3 -32*2]
    mova                 m7, [r3 +32*2]
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq-32*2], m0
    mova         [cfq+32*2], m1
    mova         [r3 -32*2], m2
    mova         [r3 +32*2], m3
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq+32*0]
    mova                 m2, [r3 -32*4]
    mova                 m3, [r3 +32*0]
.pass1_dct_main2:
    mova         [cfq-32*4], m4
    mova         [cfq+32*0], m5
    mova         [r3 -32*4], m6
    mova         [r3 +32*0], m7
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                 m8, [cfq-32*2] ; b0
    mova                 m9, [cfq-32*4]
    psubd               m10, m0, m8     ; out7a
    paddd                m0, m8         ; out0a
    mova                 m8, [r3 +32*2] ; b3
    psubd               m11, m4, m9     ; out7b
    paddd                m4, m9         ; out0b
    mova                 m9, [r3 +32*0]
    REPX       {psrad x, 6}, m0, m4, m10, m11
    packssdw             m0, m4
    psubd                m4, m3, m8     ; out4a
    paddd                m3, m8         ; out3a
    psubd                m8, m7, m9     ; out4b
    paddd                m7, m9         ; out3b
    mova                 m9, [cfq+32*2] ; b1
    REPX       {psrad x, 6}, m4, m8, m3, m7
    packssdw             m4, m8
    mova                 m8, [cfq+32*0]
    packssdw             m3, m7
    packssdw             m7, m10, m11
    psubd               m10, m1, m9     ; out6a
    paddd                m1, m9         ; out1a
    mova                 m9, [r3 -32*2] ; b2
    psubd               m11, m5, m8     ; out6b
    paddd                m5, m8         ; out1b
    mova                 m8, [r3 -32*4]
    REPX       {psrad x, 6}, m1, m5, m10, m11
    packssdw             m1, m5
    psubd                m5, m2, m9     ; out5a
    paddd                m2, m9         ; out2a
    psubd                m9, m6, m8     ; out5b
    paddd                m6, m8         ; out2b
    REPX       {psrad x, 6}, m5, m9, m2, m6
    packssdw             m5, m9
    packssdw             m2, m6
    packssdw             m6, m10, m11
    jmp m(inv_txfm_add_8x16_8bpc).transpose16x8
ALIGN function_align
.dct32:
    mov                 r3d, 32*7
.dct32_loop:
    vpbroadcastd         m1, [o(dct32_mat)+r3+4*0]
    vpbroadcastd        m10, [o(dct32_mat)+r3+4*1]
    vpbroadcastd        m11, [o(dct32_mat)+r3+4*2]
    pmaddwd              m0, m8, m1
    pmaddwd              m1, m5
    pmaddwd             m12, m9, m10
    pmaddwd             m10, m4
    pmaddwd             m13, m2, m11
    pmaddwd             m11, m7
    paddd                m0, m12
    vpbroadcastd        m12, [o(dct32_mat)+r3+4*3]
    psubd                m1, m10
    vpbroadcastd        m10, [o(dct32_mat)+r3+4*4]
    paddd                m0, m13
    pmaddwd             m13, m3, m12
    pmaddwd             m12, m6
    paddd                m1, m11
    pmaddwd             m11, m6, m10
    pmaddwd             m10, m3
    paddd                m0, m13
    vpbroadcastd        m13, [o(dct32_mat)+r3+4*5]
    psubd                m1, m12
    vpbroadcastd        m12, [o(dct32_mat)+r3+4*6]
    paddd                m0, m11
    pmaddwd             m11, m7, m13
    pmaddwd             m13, m2
    paddd                m1, m10
    pmaddwd             m10, m4, m12
    pmaddwd             m12, m9
    paddd                m0, m11
    vpbroadcastd        m11, [o(dct32_mat)+r3+4*7]
    psubd                m1, m13
    pmaddwd             m13, m5, m11
    pmaddwd             m11, m8
    paddd                m0, m10
    paddd                m1, m12
    paddd                m0, m13
    psubd                m1, m11
    mova       [r7+r3-32*4], m0
    mova       [r7+r3+32*4], m1
    sub                 r3d, 32
    jge .dct32_loop
    ret
.dct32_fast:
    mov                 r3d, 32*7
.dct32_fast_loop:
    vpbroadcastd         m0, [o(dct32_mat)+r3+4*0]
    vpbroadcastd         m5, [o(dct32_mat)+r3+4*1]
    vpbroadcastd         m4, [o(dct32_mat)+r3+4*2]
    vpbroadcastd         m6, [o(dct32_mat)+r3+4*3]
    pmaddwd              m0, m8
    pmaddwd              m5, m9
    pmaddwd              m4, m2
    vpbroadcastd         m1, [o(dct32_mat)+r3+4*4]
    pmaddwd              m6, m3
    vpbroadcastd         m7, [o(dct32_mat)+r3+4*5]
    paddd                m0, m5
    vpbroadcastd         m5, [o(dct32_mat)+r3+4*6]
    paddd                m4, m6
    vpbroadcastd         m6, [o(dct32_mat)+r3+4*7]
    pmaddwd              m1, m3
    pmaddwd              m7, m2
    pmaddwd              m5, m9
    pmaddwd              m6, m8
    psubd                m1, m7
    psubd                m5, m6
    paddd                m0, m4
    paddd                m1, m5
    mova       [r7+r3-32*4], m0
    mova       [r7+r3+32*4], m1
    sub                 r3d, 32
    jge .dct32_fast_loop
    ret

.pass1_identity:
    vpbroadcastd        m12, [o(pw_53x512)]
    lea                 r3d, [eobq-(128<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    lea                  r3, [cfq+32*8]
    test               eobd, eobd
    jl .pass1_identity_fast
    mova                 m0, [cfq-32*3]
    mova                 m1, [cfq-32*1]
    mova                 m2, [cfq+32*1]
    mova                 m3, [cfq+32*3]
    mova                 m4, [r3 -32*3]
    mova                 m5, [r3 -32*1]
    mova                 m6, [r3 +32*1]
    mova                 m7, [r3 +32*3]
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_8x16_8bpc).transpose16x8
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*3], m3
    mova         [r3 -32*3], m4
    mova         [r3 -32*1], m5
    mova         [r3 +32*1], m6
    mova         [r3 +32*3], m7
.pass1_identity_fast:
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*2]
    mova                 m2, [cfq+32*0]
    mova                 m3, [cfq+32*2]
    mova                 m4, [r3 -32*4]
    mova                 m5, [r3 -32*2]
    mova                 m6, [r3 +32*0]
    mova                 m7, [r3 +32*2]
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_8x16_8bpc).transpose16x8
    test               eobb, 0x20
    jz .pass2_dct
.pass2_identity:
    vpbroadcastd        m12, [o(pw_181x8)]
    REPX  {pmulhrsw x, m12}, m0, m1, m2, m3, m4, m5, m6, m7
    lea                  r6, [dsq*3]
    pxor                m10, m10
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
    call m(inv_txfm_add_8x16_8bpc).write_8x16
    test               eobd, eobd
    jl m(inv_txfm_add_32x8_8bpc).pass2_end
    call .pass2_identity_load_round_bottomhalf
    call m(inv_txfm_add_8x16_8bpc).write_8x16
    jmp m(inv_txfm_add_32x8_8bpc).pass2_end
.hdpcm:
    call m(inv_txfm_add_8x16_8bpc).write_8x16_hdpcm
    call .pass2_identity_load_round_bottomhalf
    call m(inv_txfm_add_8x16_8bpc).write_8x16_hdpcm
    jmp m(inv_txfm_add_32x8_8bpc).pass2_end
.vdpcm:
    call m(inv_txfm_add_8x16_8bpc).write_8x16_vdpcm
    punpckhqdq           m8, m7, m10
    call .pass2_identity_load_round_bottomhalf
    paddsw               m0, m8
    call m(inv_txfm_add_8x16_8bpc).write_8x16_vdpcm
    jmp m(inv_txfm_add_32x8_8bpc).pass2_end
.pass2_identity_load_round_bottomhalf:
    lea                  r3, [cfq+32*8]
    pmulhrsw             m0, m12, [cfq-32*3]
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m2, m12, [cfq+32*1]
    pmulhrsw             m3, m12, [cfq+32*3]
    pmulhrsw             m4, m12, [r3 -32*3]
    pmulhrsw             m5, m12, [r3 -32*1]
    pmulhrsw             m6, m12, [r3 +32*1]
    pmulhrsw             m7, m12, [r3 +32*3]
    ret

.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat)]
.pass1_dst:
%if WIN64
    push                 r8
%endif
    lea                 r8d, [eobq+(84<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r8d
    sub                eobd, 100<<16
    jl .pass1_dst_fast
    add                 cfq, 32
    call .pass1_dst_main
    mova         [cfq-64*2], m0
    mova         [cfq-64*1], m1
    mova         [cfq+64*0], m2
    mova         [cfq+64*1], m3
    sub                  r3, 16*8
    mova         [cfq+64*2], m4
    mova         [cfq+64*3], m5
    mova         [cfq+64*4], m6
    mova         [cfq+64*5], m7
    sub                 cfq, 32
.pass1_dst_fast:
    call .pass1_dst_main
%if WIN64
    pop                  r8
%endif
    jmp .pass1_end
ALIGN function_align
.pass1_dst_main:
    mova                 m0, [cfq-64*2]
    mova                 m1, [cfq-64*1]
    mova                 m2, [cfq+64*0]
    mova                 m3, [cfq+64*1]
    mova                 m4, [cfq+64*2]
    mova                 m5, [cfq+64*3]
    mova                 m6, [cfq+64*4]
    mova                 m7, [cfq+64*5]
.pass1_dst_main2:
    punpcklwd           m10, m0, m2 ; 0 2
    punpckhwd            m0, m2
    punpcklwd            m2, m1, m3 ; 1 3
    punpckhwd            m1, m3
    punpcklwd            m3, m4, m6 ; 4 6
    punpckhwd            m4, m6
    punpcklwd           m11, m5, m7 ; 5 7
    punpckhwd            m5, m7
    vpbroadcastd        m12, [o(pd_32)]
    mov                 r8d, 64*7
.pass1_dst_loop:
    call m(inv_txfm_add_16x8_8bpc).dst8
    paddd                m6, m12
    paddd                m7, m12
    psrad                m6, 6
    psrad                m7, 6
    packssdw             m7, m6, m7
    mova      [cfq+r8-64*2], m7
    sub                 r8d, 64
    jge .pass1_dst_loop
    mova                 m0, [cfq+64*5]
    mova                 m1, [cfq+64*4]
    mova                 m2, [cfq+64*3]
    mova                 m3, [cfq+64*2]
    mova                 m4, [cfq+64*1]
    mova                 m5, [cfq+64*0]
    mova                 m6, [cfq-64*1]
    jmp m(inv_txfm_add_8x16_8bpc).transpose16x8

INV_TXFM_FN 32, 8
    add                 cfq, 32*4
    PROLOGUE              0, 8, 13
    test               tx1b, 0x01
    jnz .pass1_identity

.pass1_dct:
    vbroadcasti128       m9, [cfq-16*7]
    vbroadcasti128       m0, [cfq-16*5]
    vbroadcasti128       m2, [cfq-16*3]
    vbroadcasti128       m7, [cfq-16*1]
    vbroadcasti128       m3, [cfq+16*1]
    vbroadcasti128       m4, [cfq+16*3]
    vbroadcasti128       m6, [cfq+16*5]
    vbroadcasti128       m1, [cfq+16*7]
    shufpd               m9, m0, 0x0c
    shufpd               m2, m7, 0x0c
    shufpd               m3, m4, 0x0c
    shufpd               m6, m1, 0x0c
    punpcklwd            m8, m9, m2      ;  1  5
    punpckhwd            m9, m2          ;  3  7
    punpcklwd            m2, m3, m6      ;  9 13
    punpckhwd            m3, m6          ; 11 15
%if WIN64
    push                 r8
%endif
    push                 r9
    mov                  r8, rsp
    and                 rsp, ~31
    lea                 r3d, [eobq+(21<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    lea                  r9, [cfq+32*8]
    cmovz              eobd, r3d
    sub                 rsp, 32*16
    lea                  r7, [rsp+32*4]
    cmp                eobd, 128<<16
    jl .pass1_dct_fast
    vbroadcasti128       m4, [r9-16*7]
    vbroadcasti128      m11, [r9-16*5]
    vbroadcasti128       m7, [r9-16*3]
    vbroadcasti128      m12, [r9-16*1]
    vbroadcasti128       m0, [r9+16*1]
    vbroadcasti128       m1, [r9+16*3]
    vbroadcasti128       m5, [r9+16*5]
    vbroadcasti128       m6, [r9+16*7]
    shufpd               m4, m11, 0x0c
    shufpd               m7, m12, 0x0c
    shufpd               m0, m1, 0x0c
    shufpd               m5, m6, 0x0c
    punpcklwd            m6, m7, m4      ; 21 17
    punpckhwd            m7, m4          ; 23 19
    punpcklwd            m4, m5, m0      ; 29 25
    punpckhwd            m5, m0          ; 31 27
%if WIN64
    mova            [r8+16], xm13
%endif
    call m(inv_txfm_add_8x32_8bpc).dct32
%if WIN64
    mova               xm13, [r8+16]
%endif
    call .pass1_dct_load_dct16
    vbroadcasti128       m4, [r9-16*8]
    vbroadcasti128       m8, [r9-16*6]
    vbroadcasti128       m5, [r9-16*4]
    vbroadcasti128       m9, [r9-16*2]
    vbroadcasti128       m6, [r9+16*0]
    vbroadcasti128      m11, [r9+16*2]
    vbroadcasti128       m7, [r9+16*4]
    vbroadcasti128      m12, [r9+16*6]
    shufpd               m4, m8, 0x0c    ; 16 18
    shufpd               m5, m9, 0x0c    ; 20 22
    shufpd               m6, m11, 0x0c   ; 24 26
    shufpd               m7, m12, 0x0c   ; 28 30
    call m(inv_txfm_add_8x16_8bpc).dct16
    jmp .pass1_dct2
.pass1_dct_load_dct16:
    vbroadcasti128       m0, [cfq-16*8]
    vbroadcasti128       m4, [cfq-16*6]
    vbroadcasti128       m1, [cfq-16*4]
    vbroadcasti128       m5, [cfq-16*2]
    vbroadcasti128       m2, [cfq+16*0]
    vbroadcasti128       m6, [cfq+16*2]
    vbroadcasti128       m3, [cfq+16*4]
    vbroadcasti128       m7, [cfq+16*6]
    vpbroadcastd        m10, [o(pd_32)]
    shufpd               m0, m4, 0x0c    ;  0  2
    shufpd               m1, m5, 0x0c    ;  4  6
    shufpd               m2, m6, 0x0c    ;  8 10
    shufpd               m3, m7, 0x0c    ; 12 14
    ret
.pass1_dct_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    call .pass1_dct_load_dct16
    call m(inv_txfm_add_8x16_8bpc).dct16_fast
.pass1_dct2:
%macro IDCT_8X32_PASS1_END 5-6 0 ; a, b_mem, c_mem, shift, out_high_mem, dct64
    mova                 m9, [cfq+32*%2]     ; b0  + n
    mova                m10, [r7 +32*(%3+8)] ; c15 - n
    mova                m11, [r7 +32*(%3+0)] ; c0  + n
%if %2 & ~2
    psubd                m8, %1, m9  ; a15 - n
    paddd                %1, m9      ; a0  + n
%else ; odd upper rows are inverted
    paddd                m8, %1, m9
    psubd                %1, m9
%endif
%if %3 & 1
    psubd                m9, m8, m10 ; out16 + n
    paddd                m8, m10     ; out15 - n
%else
    paddd                m9, m8, m10
    psubd                m8, m10
%endif
    psubd               m10, %1, m11 ; out31 - n
    paddd                %1, m11     ; out0  + n
    REPX      {psrad x, %4}, m9, %1, m8, m10
%if %6
    packssdw             %1, m8
    packssdw             m9, m10
    mova               [%5], m9
%else
    packssdw             %1, m9      ;  0 16 + n
    packssdw             m8, m10     ; 15 31 - n
    mova               [%5], m8
%endif
%endmacro
    IDCT_8X32_PASS1_END  m0, -4, -4,  6, r9 +32*3
    IDCT_8X32_PASS1_END  m1, -3, -3,  6, r9 +32*2
    IDCT_8X32_PASS1_END  m2, -2, -2,  6, r9 +32*1
    IDCT_8X32_PASS1_END  m3, -1, -1,  6, r9 +32*0
    IDCT_8X32_PASS1_END  m4,  3,  0,  6, cfq+32*3
    IDCT_8X32_PASS1_END  m5,  2,  1,  6, cfq+32*2
    IDCT_8X32_PASS1_END  m6,  1,  2,  6, cfq+32*1
    IDCT_8X32_PASS1_END  m7,  0,  3,  6, cfq+32*0
    call m(inv_txfm_add_16x8_8bpc).transpose8x8_vpermq
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [r9 -32*4], m4
    mova         [r9 -32*3], m5
    mova         [r9 -32*2], m6
    mova         [r9 -32*1], m7
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    mova                 m4, [r9 +32*0]
    mova                 m5, [r9 +32*1]
    mova                 m6, [r9 +32*2]
    mova                 m7, [r9 +32*3]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8_vpermq
    mov                 rsp, r8
    pop                  r9
%if WIN64
    pop                  r8
%endif
    jmp                tx2q
.pass2_dct:
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*0], m0
    mova         [cfq+32*1], m2
    mova         [cfq+32*2], m4
    mova         [cfq+32*3], m6
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [r3 +32*0], m0
    mova         [r3 +32*1], m1
    mova         [r3 +32*2], m2
    mova         [r3 +32*3], m3
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    vpbroadcastd        m10, [o(pd_4096)]
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    mova         [cfq+32*2], m6
    mova         [cfq+32*3], m7
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m11, [r3 +32*0]
    mova                 m9, [cfq+32*0]
    psubd               m12, m0, m11
    paddd                m0, m11
    paddd               m11, m4, m9
    psubd                m4, m9
    mova                 m8, [r3 +32*1]
    mova                 m9, [cfq+32*1]
    psrad                m0, 13
    psrad               m11, 13
    packssdw             m0, m11
    psubd               m11, m1, m8
    paddd                m1, m8
    paddd                m8, m5, m9
    psubd                m5, m9
    psrad                m1, 13
    psrad                m8, 13
    packssdw             m1, m8
    mova         [cfq+32*0], m0
    mova         [cfq+32*1], m1
    mova                 m1, [r3 +32*2]
    mova                 m9, [cfq+32*2]
    paddd                m0, m2, m1
    psubd                m2, m1
    paddd                m1, m6, m9
    psubd                m6, m9
    mova                 m8, [r3 +32*3]
    mova                 m9, [cfq+32*3]
    psrad                m0, 13
    psrad                m1, 13
    packssdw             m0, m1
    paddd                m1, m3, m8
    psubd                m3, m8
    paddd                m8, m7, m9
    psubd                m7, m9
    psrad                m1, 13
    psrad                m8, 13
    packssdw             m1, m8
    mova         [cfq+32*2], m0
    mova         [cfq+32*3], m1
    REPX      {psrad x, 13}, m3, m7, m2, m6
    packssdw             m3, m7
    packssdw             m2, m6
    mova         [r3 +32*0], m3
    mova         [r3 +32*1], m2
    REPX      {psrad x, 13}, m11, m5, m12, m4
    packssdw            m11, m5
    packssdw            m12, m4
    mova         [r3 +32*2], m11
    mova         [r3 +32*3], m12
    mova                 m1, [cfq-32*3]
    mova                 m3, [cfq-32*1]
    mova                 m5, [r3 -32*3]
    mova                 m7, [r3 -32*1]
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m1
    mova         [r3 -32*3], m2
    mova         [r3 -32*1], m3
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*2]
    mova                 m2, [r3 -32*4]
    mova                 m3, [r3 -32*2]
    mova         [cfq-32*4], m4
    mova         [cfq-32*2], m5
    mova         [r3 -32*4], m6
    mova         [r3 -32*2], m7
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m11, [cfq-32*3]
    mova                 m9, [cfq-32*4]
    psubd               m12, m0, m11
    paddd                m0, m11
    paddd               m11, m4, m9
    psubd                m4, m9
    mova                 m8, [cfq-32*1]
    mova                 m9, [cfq-32*2]
    REPX      {psrad x, 13}, m0, m11, m12, m4
    packssdw             m0, m11
    packssdw            m12, m4
    psubd               m11, m1, m8
    paddd                m1, m8
    paddd                m8, m5, m9
    psubd                m5, m9
    REPX      {psrad x, 13}, m1, m8, m11, m5
    packssdw             m1, m8
    packssdw            m11, m5
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    pxor                m10, m10
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    mova                 m1, [r3 -32*3]
    mova                 m9, [r3 -32*4]
    paddd                m0, m2, m1
    psubd                m2, m1
    paddd                m1, m6, m9
    psubd                m6, m9
    mova                 m8, [r3 -32*1]
    mova                 m9, [r3 -32*2]
    psrad                m0, 13
    psrad                m1, 13
    packssdw             m0, m1
    paddd                m1, m3, m8
    psubd                m3, m8
    paddd                m8, m7, m9
    psubd                m7, m9
    psrad                m1, 13
    psrad                m8, 13
    packssdw             m1, m8
    mova                 m4, [cfq+32*2]
    mova                 m5, [cfq+32*3]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    mova                 m4, [r3 +32*0]
    mova                 m5, [r3 +32*1]
    REPX      {psrad x, 13}, m3, m7, m2, m6
    packssdw             m0, m3, m7
    packssdw             m1, m2, m6
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    mova                 m4, [r3 +32*2]
    mova                 m5, [r3 +32*3]
    mova                 m0, m11
    mova                 m1, m12
    call m(inv_txfm_add_32x4_8bpc).write_32x2
.pass2_end:
    mov                  r6, -32*16
    call m(inv_txfm_add_16x16_8bpc).zero_cf
    RET

.dconly:
    movd                xm3, [o(pw_256)]
    pmulhrsw            xm3, [cfq]
    or                  r4d, 8
    jmp m(inv_txfm_add_32x4_8bpc).dconly2

.pass1_identity:
    vpbroadcastd        m12, [o(pw_53x512)]
    call .pass1_identity_main
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    add                 cfq, 32*4
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    mova         [cfq+32*2], m6
    mova         [cfq+32*3], m7
    call .pass1_identity_main
    sub                 cfq, 32*4
    jmp                tx2q
.pass2_identity:
    vpbroadcastd        m12, [o(pw_181x4)]
    lea                  r3, [cfq+32*8]
    pxor                m10, m10
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    pmulhrsw             m4, m12, m0
    pmulhrsw             m0, m12, [cfq-32*4]
    pmulhrsw             m5, m12, m1
    pmulhrsw             m1, m12, [cfq-32*3]
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
.pass2_identity2:
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [cfq-32*2]
    pmulhrsw             m4, m12, m2
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m5, m12, m3
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [r3 -32*4]
    pmulhrsw             m4, m12, [cfq+32*0]
    pmulhrsw             m1, m12, [r3 -32*3]
    pmulhrsw             m5, m12, [cfq+32*1]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [r3 -32*2]
    pmulhrsw             m4, m12, m6
    pmulhrsw             m1, m12, [r3 -32*1]
    pmulhrsw             m5, m12, m7
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    jmp .pass2_end
.hdpcm:
    call m(inv_txfm_add_32x4_8bpc).write_32x2_hdpcm
    pmulhrsw             m0, m12, [cfq-32*2]
    pmulhrsw             m4, m12, m2
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m5, m12, m3
    call m(inv_txfm_add_32x4_8bpc).write_32x2_hdpcm2
    pmulhrsw             m0, m12, [r3 -32*4]
    pmulhrsw             m4, m12, [cfq+32*0]
    pmulhrsw             m1, m12, [r3 -32*3]
    pmulhrsw             m5, m12, [cfq+32*1]
    call m(inv_txfm_add_32x4_8bpc).write_32x2_hdpcm2
    pmulhrsw             m0, m12, [r3 -32*2]
    pmulhrsw             m4, m12, m6
    pmulhrsw             m1, m12, [r3 -32*1]
    pmulhrsw             m5, m12, m7
    call m(inv_txfm_add_32x4_8bpc).write_32x2_hdpcm2
    jmp .pass2_end
.vdpcm:
    paddw                m1, m0
    paddw                m5, m4
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [cfq-32*2]
    pmulhrsw             m4, m12, m2
    pmulhrsw             m2, m12, [cfq-32*1]
    pmulhrsw             m3, m12, m3
    call m(inv_txfm_add_32x4_8bpc).write_32x2_vdpcm2
    pmulhrsw             m0, m12, [r3 -32*4]
    pmulhrsw             m4, m12, [cfq+32*0]
    pmulhrsw             m2, m12, [r3 -32*3]
    pmulhrsw             m3, m12, [cfq+32*1]
    call m(inv_txfm_add_32x4_8bpc).write_32x2_vdpcm2
    pmulhrsw             m0, m12, [r3 -32*2]
    pmulhrsw             m4, m12, m6
    pmulhrsw             m2, m12, [r3 -32*1]
    pmulhrsw             m3, m12, m7
    call m(inv_txfm_add_32x4_8bpc).write_32x2_vdpcm2
    jmp .pass2_end
ALIGN function_align
.pass1_identity_main:
    lea                  r3, [cfq+16*16]
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [r3 -16*8], 1
    mova                xm1, [cfq-16*7]
    vinserti128          m1, [r3 -16*7], 1
    mova                xm2, [cfq-16*6]
    vinserti128          m2, [r3 -16*6], 1
    mova                xm3, [cfq-16*5]
    vinserti128          m3, [r3 -16*5], 1
    mova                xm4, [cfq-16*4]
    vinserti128          m4, [r3 -16*4], 1
    mova                xm5, [cfq-16*3]
    vinserti128          m5, [r3 -16*3], 1
    mova                xm6, [cfq-16*2]
    vinserti128          m6, [r3 -16*2], 1
    mova                xm7, [cfq-16*1]
    vinserti128          m7, [r3 -16*1], 1
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    call m(inv_txfm_add_32x4_8bpc).identity_main
    jmp m(inv_txfm_add_16x8_8bpc).transpose8x8

.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat)]
.pass2_dst:
    add                 cfq, 32*4
    call .pass2_dst_main
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    mova                 m7, [cfq+32*3]
    sub                 cfq, 32*4
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    sub                  r3, 16*8
    call .pass2_dst_main
    vpbroadcastd        m12, [o(pw_2048)]
    lea                  r3, [cfq+32*8]
    pxor                m10, m10
    pmulhrsw             m0, m12, [r3 -32*1]
    pmulhrsw             m4, m12, [r3 +32*3]
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m5, m12, [cfq+32*3]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [r3 -32*2]
    pmulhrsw             m4, m12, [r3 +32*2]
    pmulhrsw             m1, m12, [cfq-32*2]
    pmulhrsw             m5, m12, [cfq+32*2]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [r3 -32*3]
    pmulhrsw             m4, m12, [r3 +32*1]
    pmulhrsw             m1, m12, [cfq-32*3]
    pmulhrsw             m5, m12, [cfq+32*1]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    pmulhrsw             m0, m12, [r3 -32*4]
    pmulhrsw             m4, m12, [r3 +32*0]
    pmulhrsw             m1, m12, m6
    pmulhrsw             m5, m12, [cfq+32*0]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    jmp .pass2_end
ALIGN function_align
.pass2_dst_main:
    punpcklwd           m10, m0, m2 ; 0 2
    punpckhwd            m0, m2
    punpcklwd            m2, m1, m3 ; 1 3
    punpckhwd            m1, m3
    punpcklwd            m3, m4, m6 ; 4 6
    punpckhwd            m4, m6
    punpcklwd           m11, m5, m7 ; 5 7
    punpckhwd            m5, m7
    mov                 r5d, 32*3
.pass2_dst_main_loop:
    call m(inv_txfm_add_16x8_8bpc).dst8
    psrad                m6, 9
    psrad                m7, 9
    packssdw             m6, m7
    mova      [cfq+r5+32*4], m6
    call m(inv_txfm_add_16x8_8bpc).dst8
    psrad                m6, 9
    psrad                m7, 9
    packssdw             m6, m7
    mova      [cfq+r5-32*4], m6
    sub                 r5d, 32
    jge .pass2_dst_main_loop
    ret

INV_TXFM_FN 16, 32
    add                 cfq, 32*4
    PROLOGUE              0, 8, 15, 32*48
    vpbroadcastd        m14, [o(pw_181x128)]
    jmp                tx1q

.dconly:
    movd                xm3, [o(pw_181x128)]
    pmulhrsw            xm3, [cfq]
    movd                xm2, [o(pw_512)]
    or                  r4d, 16
    pmulhrsw            xm3, xm2
    jmp m(inv_txfm_add_16x4_8bpc).dconly3

.pass1_dct:
    lea                 r3d, [eobq+(120<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r3d
    lea                  r7, [rsp+32*4]
    sub                eobd, 136<<16
    jl .pass1_dct_fast
    add                 cfq, 32
    call .pass1_dct_main
    sub                 cfq, 32
    call .pass1_dct_main
.pass1_end:
    add                 cfq, 64*8+32
    call .transpose8x8_mem
    sub                 cfq, 64*8
    call .transpose8x8_mem
    add                 cfq, 64*8-32
    jmp .pass1_end3
.pass1_dct_fast:
    call .pass1_dct_main
.pass1_end2:
    add                 cfq, 64*8
.pass1_end3:
    call .transpose8x8_mem
    sub                 cfq, 64*8
    call .transpose8x8_mem
    test               eobb, 0x20
    jnz .pass2_identity
.pass2_dct:
    lea                  r5, [cfq+32* 8]
    mova                 m0, [cfq-32* 2] ;  1
    mova                 m5, [cfq+32* 2] ;  3
    mova                 m1, [r5 -32* 2] ;  5
    mova                 m2, [r5 +32* 2] ;  7
    mova                 m4, [cfq+32*14] ;  9
    mova                 m7, [cfq+32*18] ; 11
    mova                 m3, [cfq+32*22] ; 13
    mova                 m6, [cfq+32*26] ; 15
    punpcklwd            m8, m0, m1  ;  1  5
    punpckhwd            m0, m1
    punpcklwd            m9, m5, m2  ;  3  7
    punpckhwd            m5, m2
    punpcklwd            m2, m4, m3  ;  9 13
    punpckhwd            m4, m3
    punpcklwd            m3, m7, m6  ; 11 15
    punpckhwd            m7, m6
    lea                  r7, [rsp+32*20]
    mova         [cfq-32*2], m0
    mova         [cfq+32*2], m5
    mova         [r5 -32*2], m4
    mova         [r5 +32*2], m7
    test               eobd, eobd
    jl .pass2_dct_fast
    mova                 m7, [cfq-32* 1] ; 17
    mova                 m4, [cfq+32* 3] ; 19
    mova                m10, [r5 -32* 1] ; 21
    mova                m11, [r5 +32* 3] ; 23
    mova                 m5, [cfq+32*15] ; 25
    mova                 m1, [cfq+32*19] ; 27
    mova                m12, [cfq+32*23] ; 29
    mova                 m0, [cfq+32*27] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova         [cfq-32*1], m10
    mova         [cfq+32*3], m11
    mova         [r5 -32*1], m12
    mova         [r5 +32*3], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-32* 2]
    mova                 m9, [cfq+32* 2]
    mova                 m2, [r5 -32* 2]
    mova                 m3, [r5 +32* 2]
    mova                 m6, [cfq-32* 1]
    mova                 m7, [cfq+32* 3]
    mova                 m4, [r5 -32* 1]
    mova                 m5, [r5 +32* 3]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m1, [cfq+32* 0] ;  2
    mova                 m3, [r5 +32* 0] ;  6
    mova                 m5, [cfq+32*16] ; 10
    mova                 m7, [cfq+32*24] ; 14
    mova                 m8, [cfq+32* 1] ; 18
    mova                 m9, [r5 +32* 1] ; 22
    mova                m10, [cfq+32*17] ; 26
    mova                m11, [cfq+32*25] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [r5 -32* 4] ;  4
    mova                 m3, [cfq+32*20] ; 12
    mova                 m5, [r5 -32* 3] ; 20
    mova                 m7, [cfq+32*21] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*0], m3
    mova         [r3 +32*3], m4
    mova         [r3 +32*2], m5
    mova         [r3 +32*1], m6
    mova         [r3 +32*0], m7
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32*12] ;  8
    mova                 m2, [cfq-32* 3] ; 16
    mova                 m3, [cfq+32*13] ; 24
    vpbroadcastd        m10, [o(pd_2048)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass2_dct2
.pass2_dct_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m8, [cfq-32* 2]
    mova                 m9, [cfq+32* 2]
    mova                 m2, [r5 -32* 2]
    mova                 m3, [r5 +32* 2]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32* 0] ;  2
    mova                 m2, [r5 -32* 4] ;  4
    mova                 m3, [r5 +32* 0] ;  6
    mova                 m4, [cfq+32*12] ;  8
    mova                 m5, [cfq+32*16] ; 10
    mova                 m6, [cfq+32*20] ; 12
    mova                 m7, [cfq+32*24] ; 14
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16_fast
    vpbroadcastd        m10, [o(pd_2048)]
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m1
    mova         [cfq+32*2], m2
    mova         [cfq+32*1], m3
    mova         [cfq+32*0], m8
    mova         [r3 +32*3], m5
    mova         [r3 +32*2], m6
    mova         [r3 +32*1], m7
    mova         [r3 +32*0], m9
    call m(inv_txfm_add_16x16_8bpc).dct4_fast
.pass2_dct2:
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [r3 -32*4], m4
    mova         [r3 -32*3], m5
    mova         [r3 -32*2], m6
    mova         [r3 -32*1], m7
    sub                  r7, cfq
    mov                  r3, cfq
    add                 cfq, 32*2
    call .pass2_dct_end
    mov                 cfq, r3
    add                  r3, 32*2
    call .pass2_dct_end
    mov                 r6d, 32*30
.pass2_dct_write_loop:
    mova                 m0, [cfq+r6-32*3]
    mova                 m1, [cfq+r6-32*4]
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    sub                 r6d, 32*2
    jge .pass2_dct_write_loop
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end
ALIGN function_align
.pass1_dct_main:
    pmulhrsw             m1, m14, [cfq-64* 1] ;  1
    pmulhrsw             m3, m14, [cfq+64* 1] ;  3
    pmulhrsw             m5, m14, [cfq+64* 3] ;  5
    pmulhrsw             m7, m14, [cfq+64* 5] ;  7
    pmulhrsw             m8, m14, [cfq+64* 7] ;  9
    pmulhrsw             m9, m14, [cfq+64* 9] ; 11
    pmulhrsw            m10, m14, [cfq+64*11] ; 13
    pmulhrsw            m11, m14, [cfq+64*13] ; 15
    call m(inv_txfm_add_16x16_8bpc).dct16
    pmulhrsw             m1, m14, [cfq+64* 0] ;  2
    pmulhrsw             m3, m14, [cfq+64* 4] ;  6
    pmulhrsw             m5, m14, [cfq+64* 8] ; 10
    pmulhrsw             m7, m14, [cfq+64*12] ; 14
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq+64*5], m0
    mova         [cfq+64*4], m1
    mova         [cfq+64*0], m2
    mova         [cfq+64*1], m3
    pmulhrsw             m0, m14, [cfq-64* 2] ;  0
    pmulhrsw             m1, m14, [cfq+64* 2] ;  4
    pmulhrsw             m2, m14, [cfq+64* 6] ;  8
    pmulhrsw             m3, m14, [cfq+64*10] ; 12
.pass1_dct_main2:
    mova         [cfq-64*2], m4
    mova         [cfq-64*1], m5
    mova         [cfq+64*3], m6
    mova         [cfq+64*2], m7
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    lea                  r3, [r7 +32*8]
    mova                 m8, [cfq+64*5] ; dct8  b0
    mova                 m9, [cfq-64*2]
    mova                m10, [r7 -32*4] ; dct16 c0
    mova                m11, [r3 -32*4]
    psubd               m12, m0, m8     ; a7
    paddd                m0, m8         ; a0
    psubd                m8, m4, m9
    paddd                m4, m9
    psubd                m9, m0, m10    ; out15a
    paddd               m10, m0         ; out0a
    psubd                m0, m4, m11    ; out15b
    paddd                m4, m11        ; out0b
    mova                m11, [r7 +32*0] ; dct16 b7
    mova                m13, [r3 +32*0]
    REPX       {psrad x, 6}, m10, m4, m9, m0
    packssdw            m10, m4
    packssdw             m9, m0
    psubd                m4, m12, m11   ; out7a
    paddd               m12, m11        ; out8a
    psubd                m0, m8, m13    ; out7b
    paddd                m8, m13        ; out8b
    mova                m11, [cfq+64*4] ; dct8  b1
    mova                m13, [cfq-64*1]
    REPX       {psrad x, 6}, m4, m0, m12, m8
    packssdw             m4, m0
    packssdw            m12, m8
    mova         [cfq+16*20], xm10
    vextracti128 [cfq+16*52], m10, 1
    mova         [cfq-16* 7], xm9
    vextracti128 [cfq+16*25], m9, 1
    mova         [cfq-16* 8], xm4
    vextracti128 [cfq+16*24], m4, 1
    mova         [cfq+16*21], xm12
    vextracti128 [cfq+16*53], m12, 1
    mova                 m4, [r7 -32*3] ; dct16 b1
    mova                 m0, [r3 -32*3]
    psubd               m10, m1, m11    ; a6
    paddd                m1, m11        ; a1
    psubd                m9, m5, m13
    paddd                m5, m13
    psubd                m8, m1, m4     ; out14a
    paddd                m1, m4         ; out1a
    psubd                m4, m5, m0     ; out14b
    paddd                m5, m0         ; out1b
    mova                m11, [r7 +32*1] ; dct16 b6
    mova                 m0, [r3 +32*1]
    REPX       {psrad x, 6}, m1, m5, m8, m4
    packssdw             m1, m5
    packssdw             m8, m4
    psubd                m5, m10, m11   ; out9a
    paddd               m10, m11        ; out6a
    psubd               m11, m9, m0     ; out9b
    paddd                m0, m9         ; out6b
    REPX       {psrad x, 6}, m10, m0, m5, m11
    packssdw            m10, m0
    packssdw             m5, m11
    mova         [cfq+16*16], xm1
    vextracti128 [cfq+16*48], m1, 1
    mova         [cfq-16* 3], xm8
    vextracti128 [cfq+16*29], m8, 1
    mova         [cfq-16* 4], xm10
    vextracti128 [cfq+16*28], m10, 1
    mova         [cfq+16*17], xm5
    vextracti128 [cfq+16*49], m5, 1
    mova                 m0, [cfq+64*0] ; dct8  b2
    mova                 m4, [cfq+64*3]
    mova                 m1, [r7 -32*2] ; dct16 b2
    mova                 m5, [r3 -32*2]
    psubd                m8, m2, m0     ; a5
    paddd                m2, m0         ; a2
    psubd                m0, m6, m4
    paddd                m6, m4
    psubd                m4, m2, m1     ; out13a
    paddd                m2, m1         ; out2a
    psubd                m1, m6, m5     ; out13b
    paddd                m6, m5         ; out2b
    mova                 m5, [r7 +32*2] ; dct16 b5
    mova                 m9, [r3 +32*2]
    REPX       {psrad x, 6}, m2, m6, m4, m1
    packssdw             m2, m6
    packssdw             m4, m1
    psubd                m6, m8, m5     ; out5a
    paddd                m8, m5         ; out10a
    psubd                m5, m0, m9     ; out5b
    paddd                m0, m9         ; out10b
    REPX       {psrad x, 6}, m6, m5, m8, m0
    packssdw             m6, m5
    packssdw             m8, m0
    mova         [cfq+16*12], xm2
    vextracti128 [cfq+16*44], m2, 1
    mova         [cfq+16* 1], xm4
    vextracti128 [cfq+16*33], m4, 1
    mova         [cfq+16* 0], xm6
    vextracti128 [cfq+16*32], m6, 1
    mova         [cfq+16*13], xm8
    vextracti128 [cfq+16*45], m8, 1
    mova                 m5, [cfq+64*1] ; dct8  b3
    mova                 m1, [cfq+64*2]
    mova                 m4, [r7 -32*1] ; dct16 b3
    mova                 m0, [r3 -32*1]
    psubd                m9, m3, m5     ; a4
    paddd                m3, m5         ; a3
    psubd                m5, m7, m1
    paddd                m7, m1
    psubd                m1, m3, m4     ; out12a
    paddd                m3, m4         ; out3a
    psubd                m4, m7, m0     ; out12b
    paddd                m7, m0         ; out3b
    mova                m10, [r7 +32*3] ; dct16 b4
    mova                 m0, [r3 +32*3]
    REPX       {psrad x, 6}, m3, m7, m1, m4
    packssdw             m3, m7
    packssdw             m1, m4
    psubd                m7, m9, m10    ; out11a
    paddd                m9, m10        ; out4a
    psubd                m4, m5, m0     ; out11b
    paddd                m5, m0         ; out4b
    REPX       {psrad x, 6}, m9, m5, m7, m4
    packssdw             m9, m5
    packssdw             m7, m4
    mova         [cfq+16* 8], xm3
    vextracti128 [cfq+16*40], m3, 1
    mova         [cfq+16* 5], xm1
    vextracti128 [cfq+16*37], m1, 1
    mova         [cfq+16* 4], xm9
    vextracti128 [cfq+16*36], m9, 1
    mova         [cfq+16* 9], xm7
    vextracti128 [cfq+16*41], m7, 1
    ret
ALIGN function_align
.pass2_dct_end:
%macro IDCT_16X32_PASS2_END 1 ; shift
    mova                 m0, [cfq   -32* 4] ; dct4  a0
    mova                 m1, [cfq   +32* 4]
    mova                 m2, [r3    +32* 1] ; dct8  b0
    mova                 m3, [r3    +32* 9]
    mova                 m4, [cfq+r7-32* 4] ; dct16 c0
    mova                 m5, [cfq+r7+32* 4]
    mova                 m6, [cfq+r7+32*12] ; dct32 d0
    mova                 m7, [cfq+r7+32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX      {psrad x, %1}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [cfq+r7+32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [cfq+r7+32*36]
    mova        [r3 +32*25], m0
    mova        [cfq-32* 4], m5
    mova                 m0, [cfq+r7+32* 0] ; dct16 c7
    mova                 m5, [cfq+r7+32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX      {psrad x, %1}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r3 +r7+32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r3 +r7+32*33]
    mova        [cfq+32*12], m3
    mova        [r3 +32* 9], m7
    mova                 m3, [r3 +r7+32*25] ; dct32 d8
    mova                 m7, [r3 +r7+32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX      {psrad x, %1}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova        [cfq+32*20], m6
    mova        [r3 +32* 1], m5
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX      {psrad x, %1}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova        [r3 +32*17], m3
    mova        [cfq+32* 4], m1
    mova                 m0, [cfq   -32* 3] ; dct4  a1
    mova                 m1, [cfq   +32* 5]
    mova                 m2, [r3    +32* 0] ; dct8  b1
    mova                 m3, [r3    +32* 8]
    mova                 m4, [cfq+r7-32* 3] ; dct16 c1
    mova                 m5, [cfq+r7+32* 5]
    mova                 m6, [cfq+r7+32*13] ; dct32 d1
    mova                 m7, [cfq+r7+32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX      {psrad x, %1}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [cfq+r7+32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [cfq+r7+32*37]
    mova        [r3 +32*24], m0
    mova        [cfq-32* 3], m5
    mova                 m0, [cfq+r7+32* 1] ; dct16 c6
    mova                 m5, [cfq+r7+32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX      {psrad x, %1}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r3 +r7+32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r3 +r7+32*40]
    mova        [cfq+32*13], m3
    mova        [r3 +32* 8], m7
    mova                 m3, [r3 +r7+32*16] ; dct32 d6
    mova                 m7, [r3 +r7+32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX      {psrad x, %1}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova        [r3 +32*16], m6
    mova        [cfq+32* 5], m5
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX      {psrad x, %1}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova        [cfq+32*21], m3
    mova        [r3 +32* 0], m1
    ret
%endmacro
    IDCT_16X32_PASS2_END 12
ALIGN function_align
.transpose8x8_mem:
    lea                  r3, [cfq+64*4]
    mova                 m0, [r3 +64*1]
    mova                 m1, [r3 +64*0]
    mova                 m2, [r3 -64*1]
    mova                 m3, [r3 -64*2]
    mova                 m4, [cfq+64*1]
    mova                 m5, [cfq+64*0]
    mova                 m6, [cfq-64*1]
    mova                 m7, [cfq-64*2]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    mova         [cfq-64*2], m0
    mova         [cfq-64*1], m1
    mova         [cfq+64*0], m2
    mova         [cfq+64*1], m3
    mova         [r3 -64*2], m4
    mova         [r3 -64*1], m5
    mova         [r3 +64*0], m6
    mova         [r3 +64*1], m7
    ret

.pass1_identity:
    lea                 r3d, [eobq-(256<<16)]
    test               eobb, 0x10 ; TX_CLASS_V
    cmovnz             eobd, r3d
    test               eobd, eobd
    jl .pass1_identity_fast
    add                 cfq, 32
    call .pass1_identity_main
    sub                 cfq, 64*2+32
    call .pass1_identity_main
    sub                 cfq, 64*2
    jmp .pass1_end
.pass1_identity_fast:
    call .pass1_identity_main
    sub                 cfq, 64*2
    jmp .pass1_end2
.pass2_identity:
    vpbroadcastd        m11, [o(pw_181x16)]
    lea                  r5, [cfq+64*14]
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
.pass2_identity_regular:
    mov                  r3, -64*16
.pass2_identity_loop:
    pmulhrsw             m0, m11, [r5+r3+64*0]
    pmulhrsw             m1, m11, [r5+r3+64*1]
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    add                  r3, 64*2
    jl .pass2_identity_loop
    add                  r5, 32
    add                eobd, 0x80000000
    jnc .pass2_identity_regular
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end
.hdpcm:
    mov                  r3, -64*16
.hdpcm_loop:
    pmulhrsw             m0, m11, [r5+r3+64*0]
    pmulhrsw             m1, m11, [r5+r3+64*1]
    call m(inv_txfm_add_16x4_8bpc).write_16x2_hdpcm
    add                  r3, 64*2
    jl .hdpcm_loop
    add                  r5, 32
    add                eobd, 0x80000000
    jnc .hdpcm
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end
.vdpcm:
    pxor                 m1, m1
.vdpcm2:
    mov                  r3, -64*16
.vdpcm_loop:
    pmulhrsw             m0, m11, [r5+r3+64*0]
    paddsw               m0, m1
    pmulhrsw             m1, m11, [r5+r3+64*1]
    paddsw               m1, m0
    call m(inv_txfm_add_16x4_8bpc).write_16x2
    add                  r3, 64*2
    jl .vdpcm_loop
    add                  r5, 32
    add                eobd, 0x80000000
    jnc .vdpcm2
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end
ALIGN function_align
.pass1_identity_main:
    mov                  r3, cfq
    call .pass1_identity_main2
    add                 cfq, 64*2
    sub                  r3, 64*2
.pass1_identity_main2:
    pmulhrsw             m0, m14, [cfq-64* 2]
    pmulhrsw             m1, m14, [cfq+64* 6]
    pmulhrsw             m2, m14, [cfq-64* 1]
    pmulhrsw             m3, m14, [cfq+64* 7]
    pmulhrsw             m4, m14, [r3 +64* 4]
    pmulhrsw             m5, m14, [r3 +64*12]
    pmulhrsw             m6, m14, [r3 +64* 5]
    pmulhrsw             m7, m14, [r3 +64*13]
.pass1_identity_main3:
    REPX      {paddsw x, x}, m0, m1, m2, m3, m0, m1, m2, m3
    REPX      {paddsw x, x}, m4, m5, m6, m7, m4, m5, m6, m7
    mova         [r3 +16*20], xm0
    vextracti128 [r3 +16*52], m0, 1
    mova         [r3 +16*21], xm1
    vextracti128 [r3 +16*53], m1, 1
    mova         [r3 +16*16], xm2
    vextracti128 [r3 +16*48], m2, 1
    mova         [r3 +16*17], xm3
    vextracti128 [r3 +16*49], m3, 1
    mova         [cfq-16* 4], xm4
    vextracti128 [cfq+16*28], m4, 1
    mova         [cfq-16* 3], xm5
    vextracti128 [cfq+16*29], m5, 1
    mova         [cfq-16* 8], xm6
    vextracti128 [cfq+16*24], m6, 1
    mova         [cfq-16* 7], xm7
    vextracti128 [cfq+16*25], m7, 1
    ret

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
    vpbroadcastd        m13, [o(pd_32)]
    lea                 r7d, [eobq+(120<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz             eobd, r7d
    sub                eobd, 136<<16
    jl .pass1_dst_fast
    add                 cfq, 32
    call .pass1_dst_main
    sub                 cfq, 32
    sub                  r3, 32*16+4*4
    call .pass1_dst_main
    jmp .pass1_end
.pass1_dst_fast:
    call .pass1_dst_main
    jmp .pass1_end2
ALIGN function_align
.pass1_dst_main:
    pmulhrsw             m0, m14, [cfq-64*2]
    pmulhrsw             m1, m14, [cfq-64*1]
    pmulhrsw             m2, m14, [cfq+64*0]
    pmulhrsw             m3, m14, [cfq+64*1]
    pmulhrsw             m4, m14, [cfq+64*2]
    pmulhrsw             m5, m14, [cfq+64*3]
    pmulhrsw             m6, m14, [cfq+64*4]
    pmulhrsw             m7, m14, [cfq+64*5]
    call m(inv_txfm_add_16x16_8bpc).dst16x1
    mov                 r7d, 32*28+gprsize
    mova      [rsp+r7+32*3], m1
    mova      [rsp+r7+32*2], m7
.pass1_dst_loop1:
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
    mova      [rsp+r7+32*1], m1
    mova      [rsp+r7+32*0], m7
    sub                 r7d, 32*2
    jg .pass1_dst_loop1
    pmulhrsw             m0, m14, [cfq+64* 6]
    pmulhrsw             m1, m14, [cfq+64* 7]
    pmulhrsw             m2, m14, [cfq+64* 8]
    pmulhrsw             m3, m14, [cfq+64* 9]
    pmulhrsw             m4, m14, [cfq+64*10]
    pmulhrsw             m5, m14, [cfq+64*11]
    pmulhrsw             m6, m14, [cfq+64*12]
    pmulhrsw             m7, m14, [cfq+64*13]
    add                  r3, 4*4-32*16
    call m(inv_txfm_add_16x16_8bpc).dst16x1
    mov                 r7d, 64*7
    jmp .pass1_dst_loop2a_start
.pass1_dst_loop2a: ; rows 0-7
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
.pass1_dst_loop2a_start:
    paddd                m8, m13, [rsp+gprsize+r7+32*17]
    paddd                m9, m13, [rsp+gprsize+r7+32*16]
    paddd                m1, m8
    paddd                m7, m9
    psrad                m1, 6
    psrad                m7, 6
    packssdw             m1, m7
    mova         [cfq+r7-16* 8], xm1
    vextracti128 [cfq+r7+16*24], m1, 1
    sub                 r7d, 64
    jge .pass1_dst_loop2a
    mov                 r7d, 64*7
.pass1_dst_loop2b: ; rows 8-15
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
    paddd                m8, m13, [rsp+gprsize+r7+32*1]
    paddd                m9, m13, [rsp+gprsize+r7+32*0]
    paddd                m1, m8
    paddd                m7, m9
    psrad                m1, 6
    psrad                m7, 6
    packssdw             m1, m7
    mova         [cfq+r7-16* 7], xm1
    vextracti128 [cfq+r7+16*25], m1, 1
    sub                 r7d, 64
    jge .pass1_dst_loop2b
    ret

INV_TXFM_FN 32, 16
    add                 cfq, 32*4
    PROLOGUE              0, 8, 15, 32*48
    vpbroadcastd        m14, [o(pw_181x128)]
    test               tx1b, 0x01
    jnz .pass1_identity

.pass1_dct:
    pmulhrsw             m0, m14, [cfq-32* 3] ;  1
    pmulhrsw             m5, m14, [cfq-32* 1] ;  3
    pmulhrsw             m1, m14, [cfq+32* 1] ;  5
    pmulhrsw             m2, m14, [cfq+32* 3] ;  7
    pmulhrsw             m4, m14, [cfq+32* 5] ;  9
    pmulhrsw             m7, m14, [cfq+32* 7] ; 11
    pmulhrsw             m3, m14, [cfq+32* 9] ; 13
    pmulhrsw             m6, m14, [cfq+32*11] ; 15
    punpcklwd            m8, m0, m1  ;  1  5
    punpckhwd            m0, m1
    punpcklwd            m9, m5, m2  ;  3  7
    punpckhwd            m5, m2
    punpcklwd            m2, m4, m3  ;  9 13
    punpckhwd            m4, m3
    punpcklwd            m3, m7, m6  ; 11 15
    punpckhwd            m7, m6
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m5
    mova         [cfq+32*1], m4
    mova         [cfq+32*3], m7
    lea                 r3d, [eobq+(105<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r3d
    lea                  r7, [rsp+32*20]
    cmp                eobd, 256<<16
    jl .pass1_dct_fast
    pmulhrsw             m7, m14, [cfq+32*13] ; 17
    pmulhrsw             m4, m14, [cfq+32*15] ; 19
    pmulhrsw            m10, m14, [cfq+32*17] ; 21
    pmulhrsw            m11, m14, [cfq+32*19] ; 23
    pmulhrsw             m5, m14, [cfq+32*21] ; 25
    pmulhrsw             m1, m14, [cfq+32*23] ; 27
    pmulhrsw            m12, m14, [cfq+32*25] ; 29
    pmulhrsw             m0, m14, [cfq+32*27] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova        [cfq+32* 5], m10
    mova        [cfq+32* 7], m11
    mova        [cfq+32* 9], m12
    mova        [cfq+32*11], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-32* 3]
    mova                 m9, [cfq-32* 1]
    mova                 m2, [cfq+32* 1]
    mova                 m3, [cfq+32* 3]
    mova                 m6, [cfq+32* 5]
    mova                 m7, [cfq+32* 7]
    mova                 m4, [cfq+32* 9]
    mova                 m5, [cfq+32*11]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    pmulhrsw             m1, m14, [cfq-32* 2] ;  2
    pmulhrsw             m3, m14, [cfq+32* 2] ;  6
    pmulhrsw             m5, m14, [cfq+32* 6] ; 10
    pmulhrsw             m7, m14, [cfq+32*10] ; 14
    pmulhrsw             m8, m14, [cfq+32*14] ; 18
    pmulhrsw             m9, m14, [cfq+32*18] ; 22
    pmulhrsw            m10, m14, [cfq+32*22] ; 26
    pmulhrsw            m11, m14, [cfq+32*26] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    pmulhrsw             m1, m14, [cfq+32* 0] ;  4
    pmulhrsw             m3, m14, [cfq+32* 8] ; 12
    pmulhrsw             m5, m14, [cfq+32*16] ; 20
    pmulhrsw             m7, m14, [cfq+32*24] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*0], m3
    mova         [r3 +32*3], m4
    mova         [r3 +32*2], m5
    mova         [r3 +32*1], m6
    mova         [r3 +32*0], m7
    pmulhrsw             m0, m14, [cfq-32* 4] ;  0
    pmulhrsw             m1, m14, [cfq+32* 4] ;  8
    pmulhrsw             m2, m14, [cfq+32*12] ; 16
    pmulhrsw             m3, m14, [cfq+32*20] ; 24
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass1_dct2
.pass1_dct_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m8, [cfq-32* 3]
    mova                 m9, [cfq-32* 1]
    mova                 m2, [cfq+32* 1]
    mova                 m3, [cfq+32* 3]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    pmulhrsw             m0, m14, [cfq-32* 4] ;  0
    pmulhrsw             m1, m14, [cfq-32* 2] ;  2
    pmulhrsw             m2, m14, [cfq+32* 0] ;  4
    pmulhrsw             m3, m14, [cfq+32* 2] ;  6
    pmulhrsw             m4, m14, [cfq+32* 4] ;  8
    pmulhrsw             m5, m14, [cfq+32* 6] ; 10
    pmulhrsw             m6, m14, [cfq+32* 8] ; 12
    pmulhrsw             m7, m14, [cfq+32*10] ; 14
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16_fast
    vpbroadcastd        m10, [o(pd_32)]
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m1
    mova         [cfq+32*2], m2
    mova         [cfq+32*1], m3
    mova         [cfq+32*0], m8
    mova         [r3 +32*3], m5
    mova         [r3 +32*2], m6
    mova         [r3 +32*1], m7
    mova         [r3 +32*0], m9
    call m(inv_txfm_add_16x16_8bpc).dct4_fast
.pass1_dct2:
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [r3 -32*4], m4
    mova         [r3 -32*3], m5
    mova         [r3 -32*2], m6
    mova         [r3 -32*1], m7
    sub                  r7, cfq
    mov                  r3, cfq
    add                 cfq, 32*2
    call .pass1_dct_end
    mov                 cfq, r3
    add                  r3, 32*2
    call .pass1_dct_end
    mov                 r3d, 32*24
.transpose_loop:
    mova                 m0, [cfq+r3-32*4]
    mova                 m1, [cfq+r3-32*3]
    mova                 m2, [cfq+r3-32*2]
    mova                 m3, [cfq+r3-32*1]
    mova                 m4, [cfq+r3+32*0]
    mova                 m5, [cfq+r3+32*1]
    mova                 m6, [cfq+r3+32*2]
    mova                 m7, [cfq+r3+32*3]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    mova      [cfq+r3-32*4], m0
    mova      [cfq+r3-32*3], m1
    mova      [cfq+r3-32*2], m2
    mova      [cfq+r3-32*1], m3
    mova      [cfq+r3+32*0], m4
    mova      [cfq+r3+32*1], m5
    mova      [cfq+r3+32*2], m6
    mova      [cfq+r3+32*3], m7
    sub                 r3d, 32*8
    jge .transpose_loop
    jmp                tx2q
.pass2_dct:
    lea                  r7, [rsp+32*4]
    call .pass2_dct_main
    add                 cfq, 32*8
    call .pass2_dct_main
    mov                 r6d, 32*7
    pxor                m10, m10
.pass2_dct_write_loop:
    mova                 m0, [cfq+r6+32* 4]
    mova                 m4, [cfq+r6+32*12]
    mova                 m1, [cfq+r6-32*12]
    mova                 m5, [cfq+r6-32* 4]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    sub                 r6d, 32
    jge .pass2_dct_write_loop
    sub                 cfq, 32*8
.pass2_end:
    mov                  r6, -32*32
    call m(inv_txfm_add_16x16_8bpc).zero_cf
    RET
ALIGN function_align
.pass1_dct_end:
    mova                 m0, [cfq   -32* 4] ; dct4  a0
    mova                 m1, [cfq   +32* 4]
    mova                 m2, [r3    +32* 1] ; dct8  b0
    mova                 m3, [r3    +32* 9]
    mova                 m4, [cfq+r7-32* 4] ; dct16 c0
    mova                 m5, [cfq+r7+32* 4]
    mova                 m6, [cfq+r7+32*12] ; dct32 d0
    mova                 m7, [cfq+r7+32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [cfq+r7+32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [cfq+r7+32*36]
    mova         [cfq-16* 8], xm0
    vextracti128 [cfq+16*24], m0, 1
    mova         [r3 +16*19], xm5
    vextracti128 [r3 +16*51], m5, 1
    mova                 m0, [cfq+r7+32* 0] ; dct16 c7
    mova                 m5, [cfq+r7+32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r3 +r7+32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r3 +r7+32*33]
    mova         [r3 +16*18], xm3
    vextracti128 [r3 +16*50], m3, 1
    mova         [cfq-16* 7], xm7
    vextracti128 [cfq+16*25], m7, 1
    mova                 m3, [r3 +r7+32*25] ; dct32 d8
    mova                 m7, [r3 +r7+32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova         [r3 +16* 2], xm6
    vextracti128 [r3 +16*34], m6, 1
    mova         [cfq+16* 9], xm5
    vextracti128 [cfq+16*41], m5, 1
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova         [cfq+16* 8], xm3
    vextracti128 [cfq+16*40], m3, 1
    mova         [r3 +16* 3], xm1
    vextracti128 [r3 +16*35], m1, 1
    mova                 m0, [cfq   -32* 3] ; dct4  a1
    mova                 m1, [cfq   +32* 5]
    mova                 m2, [r3    +32* 0] ; dct8  b1
    mova                 m3, [r3    +32* 8]
    mova                 m4, [cfq+r7-32* 3] ; dct16 c1
    mova                 m5, [cfq+r7+32* 5]
    mova                 m6, [cfq+r7+32*13] ; dct32 d1
    mova                 m7, [cfq+r7+32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [cfq+r7+32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [cfq+r7+32*37]
    mova         [cfq-16* 6], xm0
    vextracti128 [cfq+16*26], m0, 1
    mova         [r3 +16*17], xm5
    vextracti128 [r3 +16*49], m5, 1
    mova                 m0, [cfq+r7+32* 1] ; dct16 c6
    mova                 m5, [cfq+r7+32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r3 +r7+32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r3 +r7+32*40]
    mova         [r3 +16*16], xm3
    vextracti128 [r3 +16*48], m3, 1
    mova         [cfq-16* 5], xm7
    vextracti128 [cfq+16*27], m7, 1
    mova                 m3, [r3 +r7+32*16] ; dct32 d6
    mova                 m7, [r3 +r7+32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova         [cfq+16*10], xm6
    vextracti128 [cfq+16*42], m6, 1
    mova         [r3 +16* 1], xm5
    vextracti128 [r3 +16*33], m5, 1
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova         [r3 +16* 0], xm3
    vextracti128 [r3 +16*32], m3, 1
    mova         [cfq+16*11], xm1
    vextracti128 [cfq+16*43], m1, 1
    ret
ALIGN function_align
.pass2_dct_main:
    mova                 m1, [cfq-32 *3] ;  1
    mova                 m3, [cfq-32 *1] ;  3
    mova                 m5, [cfq+32 *1] ;  5
    mova                 m7, [cfq+32 *3] ;  7
    mova                 m8, [cfq+32*13] ;  9
    mova                 m9, [cfq+32*15] ; 11
    mova                m10, [cfq+32*17] ; 13
    mova                m11, [cfq+32*19] ; 15
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [cfq-32* 2] ;  2
    mova                 m3, [cfq+32* 2] ;  6
    mova                 m5, [cfq+32*14] ; 10
    mova                 m7, [cfq+32*18] ; 14
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32* 0] ;  4
    mova                 m2, [cfq+32*12] ;  8
    mova                 m3, [cfq+32*16] ; 12
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq+32*1], m6
    mova         [cfq+32*0], m7
    vpbroadcastd        m10, [o(pd_2048)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m11, [cfq+32* 3]
    mova                m12, [cfq-32* 4]
    mova                 m9, [r7 -32* 4]
    mova                m13, [r7 +32* 4]
    psubd               m10, m0, m11
    paddd                m0, m11
    psubd               m11, m4, m12
    paddd                m4, m12
    psubd               m12, m0, m9  ; out15a
    paddd                m0, m9      ; out0a
    psubd                m9, m4, m13 ; out15b
    paddd                m4, m13     ; out0b
    mova                 m8, [cfq+32* 2]
    mova                m13, [cfq-32* 3]
    REPX      {psrad x, 12}, m0, m4, m12, m9
    packssdw             m0, m4
    mova                 m4, [r7 -32* 3]
    packssdw            m12, m9
    mova                 m9, [r7 +32* 5]
    mova        [cfq+32*19], m0
    mova        [cfq-32* 4], m12
    psubd               m12, m1, m8
    paddd                m8, m1
    paddd                m1, m5, m13
    psubd                m5, m13
    psubd               m13, m8, m4  ; out14a
    paddd                m8, m4      ; out1a
    psubd                m4, m1, m9  ; out14b
    paddd                m1, m9      ; out1b
    mova                 m9, [cfq-32* 2]
    mova                 m0, [cfq+32* 1]
    REPX      {psrad x, 12}, m8, m1, m13, m4
    packssdw             m8, m1
    mova                 m1, [r7 -32* 2]
    packssdw            m13, m4
    mova                 m4, [r7 +32* 6]
    mova        [cfq+32* 3], m8
    mova        [cfq+32*12], m13
    psubd                m8, m2, m9
    paddd                m2, m9
    psubd                m9, m6, m0
    paddd                m6, m0
    psubd                m0, m2, m1  ; out13a
    paddd                m2, m1      ; out2a
    psubd                m1, m6, m4  ; out13b
    paddd                m6, m4      ; out2b
    mova                 m4, [cfq-32* 1]
    mova                m13, [cfq+32* 0]
    REPX      {psrad x, 12}, m2, m6, m0, m1
    packssdw             m2, m6
    mova                 m6, [r7 -32* 1]
    packssdw             m0, m1
    mova                 m1, [r7 +32* 7]
    mova        [cfq+32*18], m2
    mova        [cfq-32* 3], m0
    psubd                m2, m3, m4
    paddd                m3, m4
    paddd                m4, m7, m13
    psubd                m7, m13
    psubd               m13, m3, m6  ; out12a
    paddd                m3, m6      ; out3a
    paddd                m6, m4, m1  ; out3b
    psubd                m4, m1      ; out12b
    mova                 m0, [r7+32* 3]
    mova                 m1, [r7+32*11]
    REPX      {psrad x, 12}, m3, m6, m13, m4
    packssdw             m3, m6
    mova                 m6, [r7+32* 2]
    packssdw            m13, m4
    mova                 m4, [r7+32*10]
    mova        [cfq+32* 2], m3
    mova        [cfq+32*13], m13
    psubd                m3, m2, m0  ; out11a
    paddd                m2, m0      ; out4a
    psubd                m0, m7, m1  ; out11b
    paddd                m7, m1      ; out4b
    REPX      {psrad x, 12}, m2, m7, m3, m0
    packssdw             m2, m7
    mova                 m7, [r7+32* 1]
    packssdw             m3, m0
    mova                 m0, [r7+32* 9]
    mova        [cfq+32*17], m2
    mova        [cfq-32* 2], m3
    psubd                m3, m8, m6  ; out5a
    paddd                m6, m8      ; out10a
    psubd                m2, m9, m4  ; out5b
    paddd                m4, m9      ; out10b
    REPX      {psrad x, 12}, m3, m2, m6, m4
    packssdw             m3, m2
    mova                 m2, [r7+32* 0]
    packssdw             m6, m4
    mova                 m4, [r7+32* 8]
    mova        [cfq+32* 1], m3
    mova        [cfq+32*14], m6
    psubd                m3, m12, m7 ; out9a
    paddd                m7, m12     ; out6a
    paddd                m1, m5, m0  ; out6b
    psubd                m5, m0      ; out9b
    REPX      {psrad x, 12}, m7, m1, m3, m5
    packssdw             m7, m1
    packssdw             m3, m5
    mova        [cfq+32*16], m7
    mova        [cfq-32* 1], m3
    psubd                m0, m10, m2 ; out7a
    paddd                m2, m10     ; out8a
    psubd                m3, m11, m4 ; out7b
    paddd                m4, m11     ; out8b
    REPX      {psrad x, 12}, m0, m3, m2, m4
    packssdw             m0, m3
    packssdw             m2, m4
    mova        [cfq+32* 0], m0
    mova        [cfq+32*15], m2
    ret

.dconly:
    movd                xm3, [o(pw_181x128)]
    pmulhrsw            xm3, [cfq]
    movd                xm2, [o(pw_512)]
    or                  r4d, 16
    pmulhrsw            xm3, xm2
    jmp m(inv_txfm_add_32x4_8bpc).dconly2

.pass1_identity:
    vpbroadcastd        m12, [o(pw_53x512)]
    call .pass1_identity_main
    add                 cfq, 32*8
    call .pass1_identity_main
    sub                 cfq, 32*8
    jmp                tx2q
.pass2_identity:
    vpbroadcastd        m12, [o(pw_2048)]
    mov                  r3, cfq
    pxor                m10, m10
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
.pass2_identity_regular:
    mov                  r6, -32*6
.pass2_identity_regular_loop:
    pmulhrsw             m0, m12, [r3+r6+32* 2]
    pmulhrsw             m4, m12, [r3+r6+32*10]
    pmulhrsw             m1, m12, [r3+r6+32* 3]
    pmulhrsw             m5, m12, [r3+r6+32*11]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    add                  r6, 32*2
    jle .pass2_identity_regular_loop
    add                  r3, 32*16
    add                eobd, 0x80000000
    jnc .pass2_identity_regular
    jmp .pass2_end
.hdpcm:
    vpbroadcastd        m11, [o(pb_14_15)]
.hdpcm2:
    mov                  r6, -32*6
.hdpcm_loop:
    pmulhrsw             m0, m12, [r3+r6+32* 2]
    pmulhrsw             m4, m12, [r3+r6+32*10]
    pmulhrsw             m1, m12, [r3+r6+32* 3]
    pmulhrsw             m5, m12, [r3+r6+32*11]
    call m(inv_txfm_add_32x4_8bpc).write_32x2_hdpcm2
    add                  r6, 32*2
    jle .hdpcm_loop
    add                  r3, 32*16
    add                eobd, 0x80000000
    jnc .hdpcm2
    jmp .pass2_end
.vdpcm:
    pxor                 m1, m1
    pxor                 m5, m5
.vdpcm2:
    mov                  r6, -32*6
.vdpcm_loop:
    pmulhrsw             m0, m12, [r3+r6+32* 2]
    pmulhrsw             m4, m12, [r3+r6+32*10]
    pmulhrsw             m2, m12, [r3+r6+32* 3]
    pmulhrsw             m3, m12, [r3+r6+32*11]
    call m(inv_txfm_add_32x4_8bpc).write_32x2_vdpcm2
    add                  r6, 32*2
    jle .vdpcm_loop
    add                  r3, 32*16
    add                eobd, 0x80000000
    jnc .vdpcm2
    jmp .pass2_end
ALIGN function_align
.pass1_identity_main:
    lea                  r3, [cfq+32*16]
    pmulhrsw             m0, m14, [cfq-32*4]
    pmulhrsw             m1, m14, [cfq-32*3]
    pmulhrsw             m2, m14, [cfq-32*2]
    pmulhrsw             m3, m14, [cfq-32*1]
    pmulhrsw             m4, m14, [cfq+32*0]
    pmulhrsw             m5, m14, [cfq+32*1]
    pmulhrsw             m6, m14, [cfq+32*2]
    pmulhrsw             m7, m14, [cfq+32*3]
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    pmulhrsw             m8, m14, [r3 -32*4]
    pmulhrsw             m9, m14, [r3 -32*3]
    pmulhrsw            m10, m14, [r3 -32*2]
    pmulhrsw            m11, m14, [r3 -32*1]
    mova         [cfq-16*8], xm0
    vextracti128 [r3 -16*8], m0, 1
    mova         [cfq-16*6], xm1
    vextracti128 [r3 -16*6], m1, 1
    mova         [cfq-16*4], xm2
    vextracti128 [r3 -16*4], m2, 1
    mova         [cfq-16*2], xm3
    vextracti128 [r3 -16*2], m3, 1
    paddsw               m0, m8, m8
    pmulhrsw             m8, m14, [r3 +32*0]
    paddsw               m1, m9, m9
    pmulhrsw             m9, m14, [r3 +32*1]
    paddsw               m2, m10, m10
    pmulhrsw            m10, m14, [r3 +32*2]
    paddsw               m3, m11, m11
    pmulhrsw            m11, m14, [r3 +32*3]
    mova         [cfq+16*0], xm4
    vextracti128 [r3 +16*0], m4, 1
    mova         [cfq+16*2], xm5
    vextracti128 [r3 +16*2], m5, 1
    mova         [cfq+16*4], xm6
    vextracti128 [r3 +16*4], m6, 1
    mova         [cfq+16*6], xm7
    vextracti128 [r3 +16*6], m7, 1
    paddsw               m4, m8, m8
    paddsw               m5, m9, m9
    paddsw               m6, m10, m10
    paddsw               m7, m11, m11
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    mova         [cfq-16*7], xm0
    vextracti128 [r3 -16*7], m0, 1
    mova         [cfq-16*5], xm1
    vextracti128 [r3 -16*5], m1, 1
    mova         [cfq-16*3], xm2
    vextracti128 [r3 -16*3], m2, 1
    mova         [cfq-16*1], xm3
    vextracti128 [r3 -16*1], m3, 1
    mova         [cfq+16*1], xm4
    vextracti128 [r3 +16*1], m4, 1
    mova         [cfq+16*3], xm5
    vextracti128 [r3 +16*3], m5, 1
    mova         [cfq+16*5], xm6
    vextracti128 [r3 +16*5], m6, 1
    mova         [cfq+16*7], xm7
    vextracti128 [r3 +16*7], m7, 1
    ret

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
    mov                  r7, r3
    call .pass2_dst_main
    add                 cfq, 32*8
    mov                  r3, r7
    call .pass2_dst_main
    vpbroadcastd        m12, [o(pw_4096)]
    mov                 r3d, 32*7
    pxor                m10, m10
.pass2_dst_write_loop:
    pmulhrsw             m0, m12, [cfq+r3-32*12]
    pmulhrsw             m4, m12, [cfq+r3-32* 4]
    pmulhrsw             m1, m12, [cfq+r3+32* 4]
    pmulhrsw             m5, m12, [cfq+r3+32*12]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    sub                 r3d, 32
    jge .pass2_dst_write_loop
    sub                 cfq, 32*8
    jmp .pass2_end
ALIGN function_align
.pass2_dst_main:
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    mova                 m7, [cfq+32*3]
    call m(inv_txfm_add_16x16_8bpc).dst16x1
    mov                 r5d, 32*28
    mova [rsp+gprsize+r5+32*3], m1
    mova [rsp+gprsize+r5+32*2], m7
.pass2_loop1:
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
    mova [rsp+gprsize+r5+32*1], m1
    mova [rsp+gprsize+r5+32*0], m7
    sub                 r5d, 32*2
    jge .pass2_loop1
    lea                  r5, [cfq+32*16]
    mova                 m0, [r5-32*4]
    mova                 m1, [r5-32*3]
    mova                 m2, [r5-32*2]
    mova                 m3, [r5-32*1]
    mova                 m4, [r5+32*0]
    mova                 m5, [r5+32*1]
    mova                 m6, [r5+32*2]
    mova                 m7, [r5+32*3]
    add                  r3, 4*4-32*16
    call m(inv_txfm_add_16x16_8bpc).dst16x1
    mov                 r5d, 32*7
    jmp .pass2_dst_loop2_start
.pass2_dst_loop2:
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
.pass2_dst_loop2_start:
    paddd                m1, [rsp+gprsize+r5*4+32*3]
    paddd                m7, [rsp+gprsize+r5*4+32*2]
    psrad                m1, 9
    psrad                m7, 9
    packssdw             m0, m1, m7
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
    paddd                m1, [rsp+gprsize+r5*4+32*1]
    paddd                m7, [rsp+gprsize+r5*4+32*0]
    psrad                m1, 9
    psrad                m7, 9
    packssdw             m1, m7
    mova     [cfq+r5-32* 4], m0
    mova     [cfq+r5+32*12], m1
    sub                  r5, 32
    jge .pass2_dst_loop2
    ret

INV_TXFM_FN 32, 32
    add                 cfq, 32*4
    PROLOGUE              0, 7, 14
    test               tx1d, tx1d
    jnz .identity

.pass1_dct:
%if WIN64
    push                 r7
    push                 r8
%endif
    mov                  r8, rsp
    and                 rsp, ~31
    mov                 r3d, 136<<16
    sub                 rsp, 32*48
    call .pass1_dct_main
    call .pass1_dct_main2
    sub                eobd, 136<<16
    jl .pass1_dct_end
    add                 cfq, 32
    mov                 r3d, 172<<16
    call .pass1_dct_main
    call .pass1_dct_main2
    sub                 cfq, 32
    mov                 r3d, 64*24+32
    call .transpose
.pass1_dct_end:
    mov                 r3d, 64*24
    call .transpose
.pass2_dct:
    add                 cfq, 64*16
    call .pass2_dct_main
    sub                 cfq, 64*16
    call .pass2_dct_main
    pxor                m10, m10
    mov                 r6d, 64*14
    call .write_32x16
    mov                 r6d, 64*14+32
    call .write_32x16
    mov                 rsp, r8
%if WIN64
    pop                  r8
    pop                  r7
%endif
.end:
    mov                  r6, -64*32
    call m(inv_txfm_add_16x16_8bpc).zero_cf
    RET
ALIGN function_align
.write_32x16:
    mova                 m0, [cfq+r6-64* 1]
    mova                 m4, [cfq+r6+64*15]
    mova                 m1, [cfq+r6-64* 2]
    mova                 m5, [cfq+r6+64*14]
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    sub                 r6d, 64*2
    jge .write_32x16
    ret
ALIGN function_align
.pass1_dct_main:
    call .dct32_load_lowhalf
    cmp                eobd, r3d
    jl .pass1_dct_main_fast
    mova                 m7, [cfq+64*15] ; 17
    mova                 m4, [cfq+64*17] ; 19
    mova                m10, [cfq+64*19] ; 21
    mova                m11, [cfq+64*21] ; 23
    mova                 m5, [cfq+64*23] ; 25
    mova                 m1, [cfq+64*25] ; 27
    mova                m12, [cfq+64*27] ; 29
    mova                 m0, [cfq+64*29] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova        [cfq+64* 7], m10
    mova        [cfq+64* 9], m11
    mova        [cfq+64*11], m12
    mova        [cfq+64*13], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-64* 1]
    mova                 m9, [cfq+64* 1]
    mova                 m2, [cfq+64* 3]
    mova                 m3, [cfq+64* 5]
    mova                 m6, [cfq+64* 7]
    mova                 m7, [cfq+64* 9]
    mova                 m4, [cfq+64*11]
    mova                 m5, [cfq+64*13]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m1, [cfq+64* 0] ;  2
    mova                 m3, [cfq+64* 4] ;  6
    mova                 m5, [cfq+64* 8] ; 10
    mova                 m7, [cfq+64*12] ; 14
    mova                 m8, [cfq+64*16] ; 18
    mova                 m9, [cfq+64*20] ; 22
    mova                m10, [cfq+64*24] ; 26
    mova                m11, [cfq+64*28] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [cfq+64* 2] ;  4
    mova                 m3, [cfq+64*10] ; 12
    mova                 m5, [cfq+64*18] ; 20
    mova                 m7, [cfq+64*26] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova        [cfq+64* 5], m0
    mova        [cfq+64* 4], m1
    mova        [cfq+64* 3], m2
    mova        [cfq+64* 2], m3
    mova        [cfq+64*13], m4
    mova        [cfq+64*12], m5
    mova        [cfq+64*11], m6
    mova        [cfq+64*10], m7
    mova                 m0, [cfq-64* 2] ;  0
    mova                 m1, [cfq+64* 6] ;  8
    mova                 m2, [cfq+64*14] ; 16
    mova                 m3, [cfq+64*22] ; 24
    vpbroadcastd        m10, [o(pd_32)]
    jmp m(inv_txfm_add_16x4_8bpc).dct4
.pass1_dct_main_fast:
    vpbroadcastd        m10, [o(pd_32)]
.dct_main_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m8, [cfq-64* 1]
    mova                 m9, [cfq+64* 1]
    mova                 m2, [cfq+64* 3]
    mova                 m3, [cfq+64* 5]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m0, [cfq-64* 2] ;  0
    mova                 m1, [cfq+64* 0] ;  2
    mova                 m2, [cfq+64* 2] ;  4
    mova                 m3, [cfq+64* 4] ;  6
    mova                 m4, [cfq+64* 6] ;  8
    mova                 m5, [cfq+64* 8] ; 10
    mova                 m6, [cfq+64*10] ; 12
    mova                 m7, [cfq+64*12] ; 14
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16_fast
    mova        [cfq+64* 5], m1
    mova        [cfq+64* 4], m2
    mova        [cfq+64* 3], m3
    mova        [cfq+64* 2], m8
    mova        [cfq+64*13], m5
    mova        [cfq+64*12], m6
    mova        [cfq+64*11], m7
    mova        [cfq+64*10], m9
    jmp m(inv_txfm_add_16x16_8bpc).dct4_fast
ALIGN function_align
.pass1_dct_main2:
    mova        [cfq-64* 2], m0
    mova        [cfq-64* 1], m1
    mova        [cfq+64* 0], m2
    mova        [cfq+64* 1], m3
    mova        [cfq+64* 6], m4
    mova        [cfq+64* 7], m5
    mova        [cfq+64* 8], m6
    mova        [cfq+64* 9], m7
    lea                  r5, [r7+32*2]
    mov                  r3, cfq
    add                 cfq, 64*2
    call .pass1_dct_main_end
    mov                  r5, r7
    add                  r7, 32*2
    mov                 cfq, r3
    add                  r3, 64*2
.pass1_dct_main_end:
    mova                 m0, [cfq-64* 2] ; dct4  a0
    mova                 m1, [cfq+64* 6]
    mova                 m2, [r3 +64* 3] ; dct8  b0
    mova                 m3, [r3 +64*11]
    mova                 m4, [r5 -32* 4] ; dct16 c0
    mova                 m5, [r5 +32* 4]
    mova                 m6, [r5 +32*12] ; dct32 d0
    mova                 m7, [r5 +32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [r5 +32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [r5 +32*36]
    mova         [cfq-16*  8], xm0
    vextracti128 [cfq+16* 24], m0, 1
    mova         [r3 +16* 77], xm5
    vextracti128 [r3 +16*109], m5, 1
    mova                 m0, [r5 +32* 0] ; dct16 c7
    mova                 m5, [r5 +32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r7 +32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r7 +32*33]
    mova         [r3 +16* 76], xm3
    vextracti128 [r3 +16*108], m3, 1
    mova         [cfq-16*  7], xm7
    vextracti128 [cfq+16* 25], m7, 1
    mova                 m3, [r7 +32*25] ; dct32 d8
    mova                 m7, [r7 +32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova         [r3 +16* 12], xm6
    vextracti128 [r3 +16* 44], m6, 1
    mova         [cfq+16* 57], xm5
    vextracti128 [cfq+16* 89], m5, 1
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova         [cfq+16* 56], xm3
    vextracti128 [cfq+16* 88], m3, 1
    mova         [r3 +16* 13], xm1
    vextracti128 [r3 +16* 45], m1, 1
    mova                 m0, [cfq-64* 1] ; dct4  a1
    mova                 m1, [cfq+64* 7]
    mova                 m2, [r3 +64* 2] ; dct8  b1
    mova                 m3, [r3 +64*10]
    mova                 m4, [r5 -32* 3] ; dct16 c1
    mova                 m5, [r5 +32* 5]
    mova                 m6, [r5 +32*13] ; dct32 d1
    mova                 m7, [r5 +32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [r5 +32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [r5 +32*37]
    mova         [cfq-16*  4], xm0
    vextracti128 [cfq+16* 28], m0, 1
    mova         [r3 +16* 73], xm5
    vextracti128 [r3 +16*105], m5, 1
    mova                 m0, [r5 +32* 1] ; dct16 c6
    mova                 m5, [r5 +32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r7 +32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r7 +32*40]
    mova         [r3 +16* 72], xm3
    vextracti128 [r3 +16*104], m3, 1
    mova         [cfq-16*  3], xm7
    vextracti128 [cfq+16* 29], m7, 1
    mova                 m3, [r7 +32*16] ; dct32 d6
    mova                 m7, [r7 +32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova         [cfq+16* 60], xm6
    vextracti128 [cfq+16* 92], m6, 1
    mova         [r3 +16*  9], xm5
    vextracti128 [r3 +16* 41], m5, 1
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova         [r3 +16*  8], xm3
    vextracti128 [r3 +16* 40], m3, 1
    mova         [cfq+16* 61], xm1
    vextracti128 [cfq+16* 93], m1, 1
    ret
ALIGN function_align
.transpose:
    mova                 m0, [cfq+r3-64*2]
    mova                 m1, [cfq+r3-64*1]
    mova                 m2, [cfq+r3+64*0]
    mova                 m3, [cfq+r3+64*1]
    mova                 m4, [cfq+r3+64*2]
    mova                 m5, [cfq+r3+64*3]
    mova                 m6, [cfq+r3+64*4]
    mova                 m7, [cfq+r3+64*5]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    mova      [cfq+r3-64*2], m0
    mova      [cfq+r3-64*1], m1
    mova      [cfq+r3+64*0], m2
    mova      [cfq+r3+64*1], m3
    mova      [cfq+r3+64*2], m4
    mova      [cfq+r3+64*3], m5
    mova      [cfq+r3+64*4], m6
    mova      [cfq+r3+64*5], m7
    sub                 r3d, 64*8
    jge .transpose
    ret
ALIGN function_align
.dct32_load_lowhalf:
    mova                 m0, [cfq-64* 1] ;  1
    mova                 m5, [cfq+64* 1] ;  3
    mova                 m1, [cfq+64* 3] ;  5
    mova                 m2, [cfq+64* 5] ;  7
    mova                 m4, [cfq+64* 7] ;  9
    mova                 m7, [cfq+64* 9] ; 11
    mova                 m3, [cfq+64*11] ; 13
    mova                 m6, [cfq+64*13] ; 15
.dct32_load_lowhalf2:
    lea                  r7, [rsp+gprsize*2+32*20]
    punpcklwd            m8, m0, m1  ;  1  5
    punpckhwd            m0, m1
    punpcklwd            m9, m5, m2  ;  3  7
    punpckhwd            m5, m2
    punpcklwd            m2, m4, m3  ;  9 13
    punpckhwd            m4, m3
    punpcklwd            m3, m7, m6  ; 11 15
    punpckhwd            m7, m6
    mova         [cfq-64*1], m0
    mova         [cfq+64*1], m5
    mova         [cfq+64*3], m4
    mova         [cfq+64*5], m7
    ret
ALIGN function_align
.pass2_dct_main:
    call .dct32_load_lowhalf
    test               eobd, eobd
    jl .pass2_dct_fast
    call .pass2_dct_main2
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass2_dct2
.pass2_dct_fast:
    vpbroadcastd        m10, [o(pd_4096)]
    call .dct_main_fast
.pass2_dct2:
    mova        [cfq-32* 4], m0
    mova        [cfq-32* 2], m1
    mova        [cfq+32* 0], m2
    mova        [cfq+32* 2], m3
    mova        [cfq+32*12], m4
    mova        [cfq+32*14], m5
    mova        [cfq+32*16], m6
    mova        [cfq+32*18], m7
    mov                  r3, cfq
    add                 cfq, 64*2
    lea                  r5, [r7+32*2]
    call .pass2_dct_main_end
    mov                 cfq, r3
    add                  r3, 64*2
    mov                  r5, r7
    add                  r7, 32*2
.pass2_dct_main_end:
    mova                 m0, [cfq-32* 4] ; dct4  a0
    mova                 m1, [cfq+32*12]
    mova                 m2, [r3 +32* 6] ; dct8  b0
    mova                 m3, [r3 +32*22]
    mova                 m4, [r5 -32* 4] ; dct16 c0
    mova                 m5, [r5 +32* 4]
    mova                 m6, [r5 +32*12] ; dct32 d0
    mova                 m7, [r5 +32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX      {psrad x, 13}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [r5 +32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [r5 +32*36]
    mova        [r3 +32*22], m0
    mova        [cfq-32* 3], m5
    mova                 m0, [r5 +32* 0] ; dct16 c7
    mova                 m5, [r5 +32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX      {psrad x, 13}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r7 +32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r7 +32*33]
    mova        [cfq-32* 4], m3
    mova        [r3 +32*23], m7
    mova                 m3, [r7 +32*25] ; dct32 d8
    mova                 m7, [r7 +32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX      {psrad x, 13}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova        [cfq+32*12], m6
    mova        [r3 +32* 7], m5
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX      {psrad x, 13}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova        [r3 +32* 6], m3
    mova        [cfq+32*13], m1
    mova                 m0, [cfq-32* 2] ; dct4  a1
    mova                 m1, [cfq+32*14]
    mova                 m2, [r3 +32* 4] ; dct8  b1
    mova                 m3, [r3 +32*20]
    mova                 m4, [r5 -32* 3] ; dct16 c1
    mova                 m5, [r5 +32* 5]
    mova                 m6, [r5 +32*13] ; dct32 d1
    mova                 m7, [r5 +32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX      {psrad x, 13}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [r5 +32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [r5 +32*37]
    mova        [r3 +32*20], m0
    mova        [cfq-32* 1], m5
    mova                 m0, [r5 +32* 1] ; dct16 c6
    mova                 m5, [r5 +32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX      {psrad x, 13}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r7 +32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r7 +32*40]
    mova        [cfq-32* 2], m3
    mova        [r3 +32*21], m7
    mova                 m3, [r7 +32*16] ; dct32 d6
    mova                 m7, [r7 +32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX      {psrad x, 13}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova        [r3 +32* 4], m6
    mova        [cfq+32*15], m5
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX      {psrad x, 13}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova        [cfq+32*14], m3
    mova        [r3 +32* 5], m1
    ret
ALIGN function_align
.pass2_dct_main2:
    mova                 m7, [cfq-32* 1] ; 17
    mova                 m4, [cfq+32* 3] ; 19
    mova                m10, [cfq+32* 7] ; 21
    mova                m11, [cfq+32*11] ; 23
    mova                 m5, [cfq+32*15] ; 25
    mova                 m1, [cfq+32*19] ; 27
    mova                m12, [cfq+32*23] ; 29
    mova                 m0, [cfq+32*27] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova        [cfq-32* 1], m10
    mova        [cfq+32* 3], m11
    mova        [cfq+32* 7], m12
    mova        [cfq+32*11], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-32* 2]
    mova                 m9, [cfq+32* 2]
    mova                 m2, [cfq+32* 6]
    mova                 m3, [cfq+32*10]
    mova                 m6, [cfq-32* 1]
    mova                 m7, [cfq+32* 3]
    mova                 m4, [cfq+32* 7]
    mova                 m5, [cfq+32*11]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m1, [cfq+32* 0] ;  2
    mova                 m3, [cfq+32* 8] ;  6
    mova                 m5, [cfq+32*16] ; 10
    mova                 m7, [cfq+32*24] ; 14
    mova                 m8, [cfq+32* 1] ; 18
    mova                 m9, [cfq+32* 9] ; 22
    mova                m10, [cfq+32*17] ; 26
    mova                m11, [cfq+32*25] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [cfq+32* 4] ;  4
    mova                 m3, [cfq+32*20] ; 12
    mova                 m5, [cfq+32* 5] ; 20
    mova                 m7, [cfq+32*21] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova        [cfq+32*10], m0
    mova        [cfq+32* 8], m1
    mova        [cfq+32* 6], m2
    mova        [cfq+32* 4], m3
    mova        [cfq+32*26], m4
    mova        [cfq+32*24], m5
    mova        [cfq+32*22], m6
    mova        [cfq+32*20], m7
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32*12] ;  8
    mova                 m2, [cfq-32* 3] ; 16
    mova                 m3, [cfq+32*13] ; 24
    ret

.dconly:
    movd                xm3, [o(pw_256)]
    pmulhrsw            xm3, [cfq]
    or                  r4d, 32
    jmp m(inv_txfm_add_32x4_8bpc).dconly2

.identity:
    vpbroadcastd        m12, [o(pw_53x512)]
    vpbroadcastd        m13, [o(pw_181x8)]
    mov                 r3d, 64*24
.identity_loop:
    mova                 m0, [cfq+r3-64*2]
    mova                 m1, [cfq+r3-64*1]
    mova                 m2, [cfq+r3+64*0]
    mova                 m3, [cfq+r3+64*1]
    mova                 m4, [cfq+r3+64*2]
    mova                 m5, [cfq+r3+64*3]
    mova                 m6, [cfq+r3+64*4]
    mova                 m7, [cfq+r3+64*5]
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    REPX  {pmulhrsw x, m13}, m0, m1, m2, m3, m4, m5, m6, m7
    mova      [cfq+r3-64*2], m0
    mova      [cfq+r3-64*1], m1
    mova      [cfq+r3+64*0], m2
    mova      [cfq+r3+64*1], m3
    mova      [cfq+r3+64*2], m4
    mova      [cfq+r3+64*3], m5
    mova      [cfq+r3+64*4], m6
    mova      [cfq+r3+64*5], m7
    btc                 r3d, 5
    jnc .identity_loop
    sub                 r3d, 64*8
    jge .identity_loop
    pxor                m10, m10
    mov                  r3, -16*4
    test               eobd, 0x100
    jnz .hdpcm
    test               eobd, 0x200
    jnz .vdpcm
.identity_write:
    lea                  r6, [r3-64*6]
.identity_write_loop:
    mova                xm0, [cfq+r6+64* 5]
    vinserti128          m0, [cfq+r6+64*21], 1
    mova                xm4, [cfq+r6+64*13]
    vinserti128          m4, [cfq+r6+64*29], 1
    mova                xm1, [cfq+r6+64* 6]
    vinserti128          m1, [cfq+r6+64*22], 1
    mova                xm5, [cfq+r6+64*14]
    vinserti128          m5, [cfq+r6+64*30], 1
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    add                  r6, 64*2
    jl .identity_write_loop
    add                  r3, 16
    jl .identity_write
    jmp .end
.hdpcm:
    vpbroadcastd        m11, [o(pb_14_15)]
.hdpcm2:
    lea                  r6, [r3-64*6]
.hdpcm_loop:
    mova                xm0, [cfq+r6+64* 5]
    vinserti128          m0, [cfq+r6+64*21], 1
    mova                xm4, [cfq+r6+64*13]
    vinserti128          m4, [cfq+r6+64*29], 1
    mova                xm1, [cfq+r6+64* 6]
    vinserti128          m1, [cfq+r6+64*22], 1
    mova                xm5, [cfq+r6+64*14]
    vinserti128          m5, [cfq+r6+64*30], 1
    call m(inv_txfm_add_32x4_8bpc).write_32x2_hdpcm2
    add                  r6, 64*2
    jl .hdpcm_loop
    add                  r3, 16
    jl .hdpcm2
    jmp .end
.vdpcm:
    pxor                 m1, m1
    pxor                 m5, m5
.vdpcm2:
    lea                  r6, [r3-64*6]
.vdpcm_loop:
    mova                xm0, [cfq+r6+64* 5]
    vinserti128          m0, [cfq+r6+64*21], 1
    mova                xm4, [cfq+r6+64*13]
    vinserti128          m4, [cfq+r6+64*29], 1
    paddsw               m0, m1
    mova                xm1, [cfq+r6+64* 6]
    vinserti128          m1, [cfq+r6+64*22], 1
    paddsw               m4, m5
    mova                xm5, [cfq+r6+64*14]
    vinserti128          m5, [cfq+r6+64*30], 1
    paddsw               m1, m0
    paddsw               m5, m4
    call m(inv_txfm_add_32x4_8bpc).write_32x2
    add                  r6, 64*2
    jl .vdpcm_loop
    add                  r3, 16
    jl .vdpcm2
    jmp .end

INV_TXFM_FN 4, 64
    add                 cfq, 32*4
    WIN64_SPILL_XMM      13
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*2]
    mova                 m2, [cfq+32*0]
    mova                 m3, [cfq+32*2]
    jmp                tx1q

.dconly:
    vpbroadcastw        xm3, [cfq]
    vpbroadcastd        xm2, [o(pw_256)]
    or                  r4d, 16
    pmulhrsw            xm3, xm2
    jmp m(inv_txfm_add_4x4_8bpc).dconly3

.pass1_dct:
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    call m(inv_txfm_add_4x16_8bpc).shift6_pack
    sub                eobd, 58<<16
    jl .pass1_end3
    mova         [cfq-32*4], m0
    mova         [cfq-32*2], m1
    mova         [cfq+32*0], m2
    mova         [cfq+32*2], m3
    mova                 m0, [cfq-32*3]
    mova                 m1, [cfq-32*1]
    mova                 m2, [cfq+32*1]
    mova                 m3, [cfq+32*3]
    call m(inv_txfm_add_16x4_8bpc).dct4
.pass1_end:
    REPX       {psrad x, 6}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    mova                 m0, [cfq-32*4]
    packssdw             m5, m1, m5
    mova                 m1, [cfq-32*2]
    REPX       {psrad x, 6}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    mova                 m2, [cfq+32*0]
    packssdw             m7, m3, m7
    mova                 m3, [cfq+32*2]
.pass1_end2:
    punpckhwd            m8, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m4, m5
    punpcklwd            m4, m5
    punpckhdq            m5, m4, m6 ; 18 19   26 27
    punpckldq            m4, m6     ; 16 17   24 25
    punpckldq            m6, m7, m8 ; 20 21   28 29
    punpckhdq            m7, m8     ; 22 23   30 31
.pass1_end3:
    punpckhwd            m8, m2, m3
    punpcklwd            m2, m3
    punpckhwd            m3, m0, m1
    punpcklwd            m0, m1
    punpckhdq            m1, m0, m2 ;  2  3   10 11
    punpckldq            m0, m2     ;  0  1    8  9
    punpckldq            m2, m3, m8 ;  4  5   12 13
    punpckhdq            m3, m8     ;  6  7   14 15
.pass2_dct:
    mov                  r5, rsp
    and                 rsp, ~31
%if WIN64
    movaps             [r5], xm13
%endif
    sub                 rsp, 32*8
    punpckhwd            m8, m0, m2 ;  1  5    9 13
    punpckhwd            m9, m1, m3 ;  3  7   11 15
    mova         [cfq-32*4], m0
    mova         [cfq+32*0], m1
    mova         [cfq-32*3], m2
    mova         [cfq+32*1], m3
    test               eobd, eobd
    jl .pass2_dct_fast
    mova         [cfq-32*1], m4
    mova         [cfq+32*2], m5
    mova         [cfq-32*2], m6
    mova         [cfq+32*3], m7
    punpckhwd            m6, m4     ; 21 17   29 25
    punpckhwd            m7, m5     ; 23 19   31 27
    vextracti128        xm2, m8, 1
    vextracti128        xm3, m9, 1
    vextracti128        xm4, m6, 1
    vextracti128        xm5, m7, 1
    call m(inv_txfm_add_4x32_8bpc).dct32
    movq                xm0, [cfq+16*0]
    punpcklwd           xm0, [cfq+16*1] ;  2 10
    movq                xm1, [cfq+16*2]
    punpcklwd           xm1, [cfq+16*3] ;  6 14
    movq                xm2, [cfq+16*5]
    punpcklwd           xm2, [cfq+16*4] ; 26 18
    movq                xm3, [cfq+16*7]
    punpcklwd           xm3, [cfq+16*6] ; 30 22
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_4x16_8bpc).dct16b
    add                  r3, 4*8
    mova         [cfq+16*0], xm8        ; b0
    mova         [cfq+16*1], xm9        ; b1
    mova         [cfq+16*6], xm12       ; b7
    mova         [cfq+16*7], xm11       ; b6
    call m(inv_txfm_add_4x16_8bpc).dct16b
    movq                xm7, [cfq-16*6]
    punpcklwd           xm7, [cfq-16*4] ;  4 20
    movq                xm2, [cfq-16*3]
    punpcklwd           xm2, [cfq-16*5] ; 28 12
    movq                xm0, [cfq-16*8]
    punpcklwd           xm0, [cfq-16*2] ;  0 16
    movq                xm1, [cfq-16*1]
    punpcklwd           xm1, [cfq-16*7] ; 24  8
    mova         [cfq+16*2], xm9        ; b3
    mova         [cfq+16*3], xm8        ; b2
    mova         [cfq+16*4], xm11       ; b4
    mova         [cfq+16*5], xm12       ; b5
    call m(inv_txfm_add_4x8_8bpc).dct8b
    jmp .pass2_dct2
.pass2_dct_fast:
    vpbroadcastd        m10, [o(pd_4096)]
    vextracti128        xm2, m8, 1
    vextracti128        xm3, m9, 1
    call m(inv_txfm_add_4x32_8bpc).dct32_fast
    movq                xm9, [cfq-16*8]
    punpcklwd           xm9, [cfq-16*7] ;  0  8
    movq                xm0, [cfq+16*0]
    punpcklwd           xm0, [cfq+16*1] ;  2 10
    movq                xm8, [cfq-16*6]
    punpcklwd           xm8, [cfq-16*5] ;  4 12
    movq                xm1, [cfq+16*2]
    punpcklwd           xm1, [cfq+16*3] ;  6 14
    call m(inv_txfm_add_4x16_8bpc).dct16_fast2
.pass2_dct2:
    mova                 m5, [cfq+32*0] ; b0    b1
    mova                 m7, [cfq+32*1] ; b3    b2
    mova                 m6, [rsp+32*0] ; c0    c1
    mova                 m8, [rsp+32*1] ; c3    c2
    psubd                m4, m0, m5     ; a15   a14
    paddd                m0, m5         ; a0    a1
    psubd                m5, m1, m7     ; a12   a13
    paddd                m1, m7         ; a3    a2
    psubd               m13, m0, m6     ; out31 out30
    paddd                m0, m6         ; out0  out1
    psubd               m12, m1, m8     ; out28 out29
    paddd                m1, m8         ; out3  out2
    psrad                m0, 13
    psrad                m1, 13
    lea                  r6, [dsq*3]
    pxor                m10, m10
    call .write_4x8
    mova                 m1, [cfq+32*2] ; b4    b5
    mova                 m7, [cfq+32*3] ; b7    b6
    mova                 m6, [rsp+32*2] ; c4    c5
    mova                 m8, [rsp+32*3] ; c7    c6
    paddd                m0, m2, m1     ; a4    a5
    psubd                m2, m1         ; a11   a10
    paddd                m1, m3, m7     ; a7    a6
    psubd                m3, m7         ; a8    a9
    psubd                m7, m0, m6     ; out27 out26
    paddd                m0, m6         ; out4  out5
    psubd                m6, m1, m8     ; out24 out25
    paddd                m1, m8         ; out7  out6
    psrad                m0, 13
    psrad                m1, 13
    call .write_4x8
    mova                 m1, [rsp+32*4] ; c8    c9
    mova                 m8, [rsp+32*5] ; c11   c10
    paddd                m0, m3, m1     ; out8  out9
    psubd                m3, m1         ; out23 out22
    paddd                m1, m2, m8     ; out11 out10
    psubd                m2, m8         ; out20 out21
    psrad                m0, 13
    psrad                m1, 13
    call .write_4x8
    mova                 m1, [rsp+32*6] ; c12   c13
    mova                 m8, [rsp+32*7] ; c15   c14
    paddd                m0, m5, m1     ; out12 out13
    psubd                m5, m1         ; out19 out18
    paddd                m1, m4, m8     ; out15 out14
    psubd                m4, m8         ; out16 out17
    psrad                m0, 13
    psrad                m1, 13
    call .write_4x8
    psrad                m0, m4, 13
    psrad                m1, m5, 13
    call .write_4x8
    psrad                m0, m2, 13
    psrad                m1, m3, 13
    call .write_4x8
    psrad                m0, m6, 13
    psrad                m1, m7, 13
    call .write_4x8
    psrad                m0, m12, 13
    psrad                m1, m13, 13
    call .write_4x8
%if WIN64
    movaps             xm13, [r5]
%endif
    mov                 rsp, r5
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end2
ALIGN function_align
.write_4x8:
    movd                xm8, [dstq+dsq*0]
    lea                  r4, [dstq+dsq*4]
    vpbroadcastd        m11, [dstq+dsq*2]
    packssdw             m0, m1
    movd                xm1, [dstq+r6 *2]
    vpblendd             m8, m11, 0x10
    vpbroadcastd        m11, [r4  +dsq*0]
    movd                xm9, [dstq+dsq*1]
    vpblendd             m1, m11, 0x10
    vpbroadcastd        m11, [dstq+r6 *1]
    punpckldq            m8, m1
    movd                xm1, [r4  +r6 *1]
    vpblendd             m9, m11, 0x10
    vpbroadcastd        m11, [r4  +dsq*1]
    vpblendd             m1, m11, 0x10
    punpckldq            m9, m1
    punpcklbw            m8, m10
    punpcklbw            m9, m10
    paddw                m8, m0
    paddw                m9, m0
    packuswb             m8, m9
    vextracti128        xm9, m8, 1
    movd       [dstq+dsq*0], xm8
    pextrd     [dstq+dsq*1], xm8, 2
    movd       [dstq+dsq*2], xm9
    pextrd     [dstq+r6 *1], xm9, 2
    lea                dstq, [dstq+dsq*8]
    pextrd     [r4  +dsq*0], xm9, 1
    pextrd     [r4  +dsq*1], xm9, 3
    pextrd     [r4  +dsq*2], xm8, 1
    pextrd     [r4  +r6 *1], xm8, 3
    ret

.pass1_identity:
    REPX      {paddsw x, x}, m0, m1, m2, m3
    sub                eobd, 64<<16
    jl .pass1_end3
    mova                 m4, [cfq-32*3]
    mova                 m5, [cfq-32*1]
    mova                 m6, [cfq+32*1]
    mova                 m7, [cfq+32*3]
    REPX      {paddsw x, x}, m4, m5, m6, m7
    jmp .pass1_end2

.pass1_flipadst:
    lea                  r3, [o(flipadst4_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst4_mat)]
.pass1_dst:
    call m(inv_txfm_add_16x4_8bpc).dst4
    vpbroadcastd         m8, [o(pd_32)]
    REPX      {paddd x, m8}, m0, m4, m1, m5, m2, m6, m3, m7
    call m(inv_txfm_add_4x16_8bpc).shift6_pack
    sub                eobd, 58<<16
    jl .pass1_end3
    mova         [cfq-32*4], m0
    mova         [cfq-32*2], m1
    mova         [cfq+32*0], m2
    mova         [cfq+32*2], m3
    mova                 m0, [cfq-32*3]
    mova                 m1, [cfq-32*1]
    mova                 m2, [cfq+32*1]
    mova                 m3, [cfq+32*3]
    call m(inv_txfm_add_16x4_8bpc).dst4
    vpbroadcastd         m8, [o(pd_32)]
    REPX      {paddd x, m8}, m0, m4, m1, m5, m2, m6, m3, m7
    jmp .pass1_end


INV_TXFM_FN 64, 4
    add                 cfq, 32*4
    WIN64_SPILL_XMM      13

.pass1_dct:
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    punpckhwd            m8, m0, m1     ;  1  5    3  7
    lea                 r3d, [eobq+(3<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovnz              r3d, eobd
    mov                  r4, rsp
    and                 rsp, ~31
    vextracti128        xm9, m8, 1
    sub                 rsp, 32*8
    cmp                 r3d, 64<<16
    jl .pass1_dct_fast
    mova                m12, [cfq+32*0]
    mova                 m6, [cfq+32*1]
    mova                 m5, [cfq+32*2]
    mova                 m4, [cfq+32*3]
    vpblendd             m7, m2, m12, 0x0f
    vpblendd            m11, m2, m12, 0xf0
    punpckhwd            m2, m3         ;  9 13   11 15
    punpcklwd            m0, m7         ;  0 16    2 10
    vpblendd             m7, m3, m6, 0xf0
    vpblendd             m3, m6, 0x0f
    punpckhwd            m6, m12        ; 21 17   23 19
    punpcklwd            m1, m3         ;  4 20    6 14
    punpcklwd            m7, m4, m7     ; 28 12   30 22
    punpckhwd            m4, m5         ; 29 25   31 27
    punpcklwd            m5, m11        ; 24  8   26 18
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m5
    mova         [cfq-32*1], m7
    vextracti128        xm3, m2, 1
    vextracti128        xm5, m4, 1
    vextracti128        xm7, m6, 1
%if WIN64
    movaps             [r4], xm13
%endif
    call m(inv_txfm_add_4x32_8bpc).dct32
    mova                xm0, [cfq-16*7] ;  2 10
    mova                xm1, [cfq-16*5] ;  6 14
    mova                xm2, [cfq-16*3] ; 26 18
    mova                xm3, [cfq-16*1] ; 30 22
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_4x16_8bpc).dct16b
    add                  r3, 4*8
    mova         [cfq+16*0], xm8        ; b0
    mova         [cfq+16*1], xm9        ; b1
    mova         [cfq+16*6], xm12       ; b7
    mova         [cfq+16*7], xm11       ; b6
    call m(inv_txfm_add_4x16_8bpc).dct16b
    mova                xm7, [cfq-16*6] ;  4 20
    mova                xm0, [cfq-16*8] ;  0 16
    mova                xm2, [cfq-16*2] ; 28 12
    mova                xm1, [cfq-16*4] ; 24  8
    mova         [cfq+16*2], xm9        ; b3
    mova         [cfq+16*3], xm8        ; b2
    mova         [cfq+16*4], xm11       ; b4
    mova         [cfq+16*5], xm12       ; b5
    call m(inv_txfm_add_4x8_8bpc).dct8b
%if WIN64
    movaps             xm13, [r4]
%endif
    jmp .pass1_dct2
.pass1_dct_fast:
    punpcklwd            m0, m2         ;  0  8    2 10
    punpckhwd            m2, m3         ;  9 13   11 15
    punpcklwd            m1, m3         ;  4 12    6 14
    vpbroadcastd        m10, [o(pd_32)]
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    vextracti128        xm3, m2, 1
    call m(inv_txfm_add_4x32_8bpc).dct32_fast
    mova                xm9, [cfq-16*8] ;  0  8
    mova                xm0, [cfq-16*7] ;  2 10
    mova                xm8, [cfq-16*6] ;  4 12
    mova                xm1, [cfq-16*5] ;  6 14
    call m(inv_txfm_add_4x16_8bpc).dct16_fast2
.pass1_dct2:
    mova                 m4, [cfq+32*0] ; b0    b1
    mova                 m5, [cfq+32*1] ; b3    b2
    mova                 m7, [rsp+32*0] ; c0    c1
    mova                 m6, [rsp+32*1] ; c3    c2
    psubd               m12, m0, m4     ; a15   a14
    paddd                m0, m4         ; a0    a1
    psubd               m11, m1, m5     ; a12   a13
    paddd                m1, m5         ; a3    a2
    psubd                m5, m0, m7     ; out31 out30
    paddd                m0, m7         ; out0  out1
    psubd                m7, m1, m6     ; out28 out29
    paddd                m1, m6         ; out3  out2
    REPX       {psrad x, 6}, m0, m1, m5, m7
    packssdw             m0, m1         ;  0  3    1  2
    packssdw             m7, m5         ; 28 31   29 30
    mova                 m4, [cfq+32*2] ; b4    b5
    mova                 m1, [cfq+32*3] ; b7    b6
    mova                 m6, [rsp+32*2] ; c4    c5
    mova                 m8, [rsp+32*3] ; c7    c6
    psubd                m5, m2, m4     ; a11   a10
    paddd                m2, m4         ; a4    a5
    paddd                m4, m3, m1     ; a7    a6
    psubd                m3, m1         ; a8    a9
    paddd                m1, m2, m6     ; out4  out5
    psubd                m2, m6         ; out27 out26
    psubd                m6, m4, m8     ; out24 out25
    paddd                m4, m8         ; out7  out6
    REPX       {psrad x, 6}, m1, m4, m2, m6
    packssdw             m1, m4         ;  4  7    5  6
    packssdw             m6, m2         ; 24 27   25 26
    mova                 m4, [rsp+32*4] ; c8    c9
    mova                 m8, [rsp+32*5] ; c11   c10
    paddd                m2, m3, m4     ; out8  out9
    psubd                m3, m4         ; out23 out22
    paddd                m4, m5, m8     ; out11 out10
    psubd                m5, m8         ; out20 out21
    REPX       {psrad x, 6}, m2, m4, m3, m5
    packssdw             m2, m4         ;  8 11    9 10
    packssdw             m5, m3         ; 20 23   21 22
    mova                 m4, [rsp+32*6] ; c12   c13
    mova                 m8, [rsp+32*7] ; c15   c14
    paddd                m3, m11, m4    ; out12 out13
    psubd               m11, m4         ; out19 out18
    psubd                m4, m12, m8    ; out16 out17
    paddd               m12, m8         ; out15 out14
    REPX       {psrad x, 6}, m3, m12, m11, m4
    packssdw             m3, m12        ; 12 15   13 14
    packssdw             m4, m11        ; 16 19   17 18
    mov                 rsp, r4
    punpckhwd            m8, m4, m5
    punpcklwd            m4, m5
    punpckhwd            m5, m6, m7
    punpcklwd            m6, m7
    punpckhwd            m7, m0, m1
    punpcklwd            m0, m1
    punpckhwd            m1, m2, m3
    punpcklwd            m2, m3
    vperm2i128           m3, m0, m2, 0x31
    vinserti128          m0, xm2, 1
    vperm2i128           m2, m4, m6, 0x31
    vinserti128          m4, xm6, 1
    vperm2i128           m6, m7, m1, 0x31
    vinserti128          m7, xm1, 1
    vinserti128          m1, m8, xm5, 1
    vperm2i128           m8, m5, 0x31
    jmp m(inv_txfm_add_32x4_8bpc).pass1_dct_end
.pass2_dct:
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    REPX      {psrad x, 13}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    packssdw             m5, m1, m5
    REPX      {psrad x, 13}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    packssdw             m7, m3, m7
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    call m(inv_txfm_add_16x4_8bpc).dct4
    REPX      {psrad x, 13}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    mova                 m0, [cfq-32*4]
    packssdw             m5, m1, m5
    mova                 m1, [cfq-32*3]
    pxor                m10, m10
    call .write_64x2
    REPX      {psrad x, 13}, m2, m6, m3, m7
    mova                 m0, [cfq-32*2]
    packssdw             m4, m2, m6
    mova                 m1, [cfq-32*1]
    packssdw             m5, m3, m7
    call .write_64x2
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3
ALIGN function_align
.write_64x2:
    mova                 m9, [dstq+dsq*0+32*0]
    punpcklbw            m8, m9, m10
    punpckhbw            m9, m10
    punpcklwd           m11, m0, m0
    punpckhwd            m0, m0
    paddw               m11, m8
    mova                 m8, [dstq+dsq*0+32*1]
    paddw                m0, m9
    punpcklbw            m9, m8, m10
    punpckhbw            m8, m10
    packuswb            m11, m0
    punpcklwd            m0, m4, m4
    punpckhwd            m4, m4
    paddw                m0, m9
    mova                 m9, [dstq+dsq*1+32*0]
    paddw                m4, m8
    packuswb             m0, m4
    punpcklbw            m8, m9, m10
    punpckhbw            m9, m10
    punpcklwd            m4, m1, m1
    punpckhwd            m1, m1
    paddw                m4, m8
    mova                 m8, [dstq+dsq*1+32*1]
    paddw                m1, m9
    punpcklbw            m9, m8, m10
    punpckhbw            m8, m10
    packuswb             m4, m1
    punpcklwd            m1, m5, m5
    punpckhwd            m5, m5
    paddw                m1, m9
    paddw                m5, m8
    packuswb             m1, m5
    mova  [dstq+dsq*0+32*0], m11
    mova  [dstq+dsq*0+32*1], m0
    mova  [dstq+dsq*1+32*0], m4
    mova  [dstq+dsq*1+32*1], m1
    lea                dstq, [dstq+dsq*2]
    ret

.dconly:
    or                  r4d, 4
.dconly2:
    movd                xm5, [o(pw_256)]
    pmulhrsw            xm5, [cfq]
.dconly3:
    vpbroadcastw         m5, xm5
    pxor                xm4, xm4
    mova              [cfq], xm4
.dconly_loop:
    mova                 m2, [dstq+32*0]
    mova                 m3, [dstq+32*1]
    punpcklbw            m0, m2, m4
    punpckhbw            m2, m4
    punpcklbw            m1, m3, m4
    punpckhbw            m3, m4
    REPX      {paddw x, m5}, m0, m2, m1, m3
    packuswb             m0, m2
    packuswb             m1, m3
    mova        [dstq+32*0], m0
    mova        [dstq+32*1], m1
    add                dstq, dsq
    dec                 r4d
    jg .dconly_loop
    vzeroupper
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
    call m(inv_txfm_add_16x4_8bpc).dst4
    REPX       {psrad x, 7}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    packssdw             m5, m1, m5
    REPX       {psrad x, 7}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    packssdw             m7, m3, m7
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq-32*2], m6
    mova         [cfq-32*1], m7
    call m(inv_txfm_add_16x4_8bpc).dst4
    REPX       {psrad x, 7}, m0, m4, m1, m5
    packssdw             m4, m0, m4
    mova                 m0, [cfq-32*4]
    packssdw             m5, m1, m5
    mova                 m1, [cfq-32*3]
    REPX       {psrad x, 7}, m2, m6, m3, m7
    packssdw             m6, m2, m6
    mova                 m2, [cfq-32*2]
    packssdw             m7, m3, m7
    mova                 m3, [cfq-32*1]

.pass2_identity:
    vpbroadcastd        m12, [o(pw_512)]
    pxor                m10, m10
    REPX  {pmulhrsw x, m12}, m0, m4, m1, m5
    call .write_64x2
    pmulhrsw             m0, m12, m2
    pmulhrsw             m4, m12, m6
    pmulhrsw             m1, m12, m3
    pmulhrsw             m5, m12, m7
    call .write_64x2
    jmp m(inv_txfm_add_16x8_8bpc).pass2_end3

INV_TXFM_FN 8, 64
    add                 cfq, 32*4
    PROLOGUE              0, 8, 14
    vpbroadcastd        m13, [o(pw_181x128)]
    jmp                tx1q

.dconly:
    movd                xm5, [o(pw_181x128)]
    pmulhrsw            xm5, [cfq]
    movd                xm4, [o(pw_512)]
    or                  r4d, 16
    pmulhrsw            xm5, xm4
    jmp m(inv_txfm_add_8x4_8bpc).dconly2

.pass1_dct:
    sub                eobd, 100<<16
    jl .pass1_dct_fast
    add                 cfq, 32
    call .pass1_dct_main
    mova         [cfq-32*4], m0
    mova         [cfq-32*2], m1
    mova         [cfq+32*0], m2
    mova         [cfq+32*2], m3
    sub                 cfq, 32
    mova         [r3 -32*4], m4
    mova         [r3 -32*2], m5
    mova         [r3 +32*0], m6
    mova         [r3 +32*2], m7
.pass1_dct_fast:
    call .pass1_dct_main
.pass2_dct:
    punpckhwd            m8, m0, m2      ;  1  5
    punpckhwd            m9, m1, m3      ;  3  7
    punpcklwd            m1, m5          ;  2 10
    punpcklwd           m10, m3, m7      ;  6 14
    punpckhwd            m3, m5, m7      ; 11 15
    mova         [cfq-32*4], m1
    mova         [cfq+32*0], m10
    mov                  r5, rsp
    and                 rsp, ~31
    sub                 rsp, 32*16
    lea                  r7, [rsp+32*4]
    test               eobd, eobd
    jl .pass2_dct_fast
    mova                m10, [cfq-32* 3] ; 16 17
    mova                 m1, [cfq-32* 1] ; 18 19
    mova                m11, [cfq+32* 1] ; 20 21
    mova                 m7, [cfq+32* 3] ; 22 23
    punpcklwd            m0, m10         ;  0 16
    mova         [cfq-32*1], m0
    punpcklwd            m2, m11         ;  4 20
    mova         [cfq-32*2], m2
    punpckhwd            m2, m4, m6      ;  9 13
    mova                 m0, [cfq+32* 5] ; 24 25
    mova                m13, [cfq+32* 7] ; 26 27
    mova                m12, [cfq+32* 9] ; 28 29
    mova                 m5, [cfq+32*11] ; 30 31
    punpcklwd            m4, m0, m4      ; 24  8
    mova         [cfq+32*3], m4
    punpckhwd            m4, m12, m0     ; 29 25
    punpcklwd           m12, m6          ; 28 12
    mova         [cfq+32*2], m12
    punpckhwd            m6, m11, m10    ; 21 17
    punpcklwd            m0, m5, m7      ; 30 22
    mova         [cfq+32*1], m0
    punpckhwd            m7, m1          ; 23 19
    punpckhwd            m5, m13         ; 31 27
    punpcklwd           m13, m1          ; 26 18
    mova         [cfq-32*3], m13
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-32*4]  ;  2 10
    mova                 m9, [cfq+32*0]  ;  6 14
    mova                m11, [cfq-32*3]  ; 26 18
    mova                m12, [cfq+32*1]  ; 30 22
    mova                 m0, [cfq-32*1]  ;  0 16
    mova                 m7, [cfq-32*2]  ;  4 20
    mova                 m1, [cfq+32*3]  ; 24  8
    mova                 m2, [cfq+32*2]  ; 28 12
    vpbroadcastd        m10, [o(pd_2048)]
    call m(inv_txfm_add_8x16_8bpc).dct16b
    jmp .pass2_dct2
.pass2_dct_fast:
    punpcklwd            m0, m4          ;  0  8
    punpcklwd           m10, m2, m6      ;  4 12
    punpckhwd            m2, m4, m6      ;  9 13
    mova         [cfq-32*2], m0
    mova         [cfq+32*2], m10
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq+32*0]
    mova                 m8, [cfq+32*2]
    mova                 m9, [cfq-32*2]
    vpbroadcastd        m10, [o(pd_2048)]
    call m(inv_txfm_add_8x16_8bpc).dct16_fast2
.pass2_dct2:
    mova                m13, [cfq-32*4]  ; b0
    mova                 m9, [cfq-32*3]  ; b1
    mova                m10, [r7 -32*4]  ; c0
    mova                 m8, [r7 -32*3]  ; c1
    psubd               m11, m0, m13     ; a15
    paddd                m0, m13         ; a0
    psubd               m13, m1, m9      ; a14
    paddd                m1, m9          ; a1
    psubd                m9, m0, m10     ; out31
    paddd                m0, m10         ; out0
    psubd               m10, m1, m8      ; out30
    paddd                m1, m8          ; out1
    REPX      {psrad x, 12}, m0, m1, m9, m10
    packssdw             m0, m1          ;  0  1
    packssdw            m10, m9          ; 30 31
    mova                m12, [cfq-32*2]  ; b2
    mova                 m1, [cfq-32*1]  ; b3
    mova                 m8, [r7 -32*2]  ; c2
    mova                 m9, [r7 -32*1]  ; c3
    mova         [cfq-32*4], m13
    mova         [cfq-32*3], m11
    mova         [cfq-32*2], m10
    psubd               m13, m2, m12     ; a13
    paddd                m2, m12         ; a2
    psubd               m12, m3, m1      ; a12
    paddd                m3, m1          ; a3
    paddd                m1, m2, m8      ; out2
    psubd                m2, m8          ; out29
    psubd                m8, m3, m9      ; out28
    paddd                m3, m9          ; out3
    REPX      {psrad x, 12}, m1, m3, m2, m8
    packssdw             m1, m3          ;  2  3
    packssdw             m8, m2          ; 28 29
    mova         [cfq-32*1], m8
    lea                  r6, [dsq*3]
    pxor                m10, m10
    call .write_8x8_vpermq
    mova                 m3, [cfq+32*3]  ; b4
    mova                 m0, [cfq+32*2]  ; b5
    mova                 m1, [r7 +32*0]  ; c4
    mova                 m8, [r7 +32*1]  ; c5
    psubd                m2, m4, m3      ; a11
    paddd                m4, m3          ; a4
    paddd                m3, m5, m0      ; a10
    psubd                m5, m0          ; a5
    paddd                m0, m4, m1      ; out4
    psubd                m4, m1          ; out27
    paddd                m1, m5, m8      ; out5
    psubd                m5, m8          ; out26
    REPX      {psrad x, 12}, m0, m1, m4, m5
    packssdw             m0, m1          ;  4  5
    packssdw             m5, m4          ; 26 27
    mova                 m4, [cfq+32*1]  ; b6
    mova                 m1, [cfq+32*0]  ; b7
    mova                 m8, [r7 +32*2]  ; c6
    mova                m11, [r7 +32*3]  ; c7
    add                  r7, 32*8
    paddd                m9, m6, m4      ; a6
    psubd                m6, m4          ; a9
    paddd                m4, m7, m1      ; a8
    psubd                m7, m1          ; a7
    paddd                m1, m9, m8      ; out6
    psubd                m9, m8          ; out25
    paddd                m8, m7, m11     ; out7
    psubd                m7, m11         ; out24
    REPX      {psrad x, 12}, m1, m8, m9, m7
    packssdw             m1, m8          ;  6  7
    packssdw             m7, m9          ; 24 25
    call .write_8x8_vpermq
    mova                 m1, [r7 +32*3]  ; c8
    mova                 m8, [r7 +32*2]  ; c9
    paddd                m0, m4, m1      ; out8
    psubd                m4, m1          ; out23
    psubd                m1, m6, m8      ; out9
    paddd                m6, m8          ; out22
    REPX      {psrad x, 12}, m0, m1, m4, m6
    packssdw             m0, m1          ;  8  9
    packssdw             m6, m4          ; 22 23
    mova                 m4, [r7 +32*1]  ; c10
    mova                 m8, [r7 +32*0]  ; c11
    paddd                m1, m3, m4      ; out10
    psubd                m3, m4          ; out21
    psubd                m4, m2, m8      ; out11
    paddd                m2, m8          ; out20
    REPX      {psrad x, 12}, m1, m4, m3, m2
    packssdw             m1, m4          ; 10 11
    packssdw             m2, m3          ; 20 21
    call .write_8x8_vpermq
    mova                 m1, [r7 -32*1]  ; c12
    mova                 m3, [r7 -32*2]  ; c13
    paddd                m0, m12, m1     ; out12
    psubd               m12, m1          ; out19
    psubd                m1, m13, m3     ; out13
    paddd               m13, m3          ; out18
    mova                 m3, [cfq-32*4]  ; a14
    mova                 m8, [r7 -32*3]  ; c14
    mova                 m4, [cfq-32*3]  ; a15
    mova                 m9, [r7 -32*4]  ; c15
    REPX      {psrad x, 12}, m0, m1, m12, m13
    packssdw             m0, m1          ; 12 13
    paddd                m1, m3, m8      ; out14
    psubd                m3, m8          ; out17
    psubd                m8, m4, m9      ; out15
    paddd                m4, m9          ; out16
    REPX      {psrad x, 12}, m1, m8, m3, m4
    packssdw             m1, m8          ; 14 15
    call .write_8x8_vpermq
    packssdw             m0, m4, m3      ; 16 17
    packssdw             m1, m13, m12    ; 18 19
    call .write_8x8_vpermq
    vpermq               m0, m2, q3120
    vpermq               m1, m6, q3120
    call .write_8x8
    vpermq               m0, m7, q3120
    vpermq               m1, m5, q3120
    call .write_8x8
    vpermq               m0, [cfq-32*1], q3120
    vpermq               m1, [cfq-32*2], q3120
    call .write_8x8
    mov                 rsp, r5
    jmp m(inv_txfm_add_64x8_8bpc).pass2_end
ALIGN function_align
.write_8x8_vpermq:
    vpermq               m0, m0, q3120
    vpermq               m1, m1, q3120
.write_8x8:
    movq                xm8, [dstq+dsq*0]
    vpbroadcastq        m11, [dstq+dsq*2]
    movq                xm9, [dstq+dsq*1]
    vpblendd             m8, m11, 0x30
    vpbroadcastq        m11, [dstq+r6   ]
    lea                  r4, [dstq+dsq*4]
    vpblendd             m9, m11, 0x30
    punpcklbw            m8, m10
    punpcklbw            m9, m10
    paddw                m8, m0
    paddw                m0, m9
    movq                xm9, [r4  +dsq*0]
    vpbroadcastq        m11, [r4  +dsq*2]
    packuswb             m8, m0
    movq                xm0, [r4  +dsq*1]
    vpblendd             m9, m11, 0x30
    vpbroadcastq        m11, [r4  +r6   ]
    vpblendd             m0, m11, 0x30
    punpcklbw            m9, m10
    punpcklbw            m0, m10
    paddw                m9, m1
    paddw                m1, m0
    packuswb             m9, m1
    vextracti128        xm0, m8, 1
    vextracti128        xm1, m9, 1
    movq       [dstq+dsq*0], xm8
    movhps     [dstq+dsq*1], xm8
    movq       [dstq+dsq*2], xm0
    movhps     [dstq+r6   ], xm0
    lea                dstq, [dstq+dsq*8]
    movq       [r4  +dsq*0], xm9
    movhps     [r4  +dsq*1], xm9
    movq       [r4  +dsq*2], xm1
    movhps     [r4  +r6   ], xm1
    ret
ALIGN function_align
.pass1_dct_main:
    lea                  r3, [cfq+32*8]
    pmulhrsw             m1, m13, [cfq-32*2]
    pmulhrsw             m3, m13, [cfq+32*2]
    pmulhrsw             m5, m13, [r3 -32*2]
    pmulhrsw             m7, m13, [r3 +32*2]
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq-32*2], m0
    mova         [cfq+32*2], m1
    mova         [r3 -32*2], m2
    mova         [r3 +32*2], m3
    pmulhrsw             m0, m13, [cfq-32*4]
    pmulhrsw             m1, m13, [cfq+32*0]
    pmulhrsw             m2, m13, [r3 -32*4]
    pmulhrsw             m3, m13, [r3 +32*0]
    jmp m(inv_txfm_add_8x32_8bpc).pass1_dct_main2

.pass1_identity:
    vpbroadcastd        m12, [o(pw_53x512)]
    lea                  r3, [cfq+32*8]
    cmp                eobd, 128<<16
    jl .pass1_identity_fast
    pmulhrsw             m0, m13, [cfq-32*3]
    pmulhrsw             m1, m13, [cfq-32*1]
    pmulhrsw             m2, m13, [cfq+32*1]
    pmulhrsw             m3, m13, [cfq+32*3]
    pmulhrsw             m4, m13, [r3 -32*3]
    pmulhrsw             m5, m13, [r3 -32*1]
    pmulhrsw             m6, m13, [r3 +32*1]
    pmulhrsw             m7, m13, [r3 +32*3]
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_8x16_8bpc).transpose16x8
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*3], m3
    mova         [r3 -32*3], m4
    mova         [r3 -32*1], m5
    mova         [r3 +32*1], m6
    mova         [r3 +32*3], m7
.pass1_identity_fast:
    pmulhrsw             m0, m13, [cfq-32*4]
    pmulhrsw             m1, m13, [cfq-32*2]
    pmulhrsw             m2, m13, [cfq+32*0]
    pmulhrsw             m3, m13, [cfq+32*2]
    pmulhrsw             m4, m13, [r3 -32*4]
    pmulhrsw             m5, m13, [r3 -32*2]
    pmulhrsw             m6, m13, [r3 +32*0]
    pmulhrsw             m7, m13, [r3 +32*2]
    call m(inv_txfm_add_32x4_8bpc).identity_main
    call m(inv_txfm_add_8x16_8bpc).transpose16x8
    jmp .pass2_dct

.pass1_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass1_dst
.pass1_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass1_dst
.pass1_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass1_dst
.pass1_adst:
    lea                  r3, [o(adst8_mat)]
.pass1_dst:
%if WIN64
    push                 r8
%endif
    sub                eobd, 100<<16
    jl .pass1_dst_fast
    add                 cfq, 32
    call .pass1_dst_main
    mova         [cfq-64*2], m0
    mova         [cfq-64*1], m1
    mova         [cfq+64*0], m2
    mova         [cfq+64*1], m3
    sub                  r3, 16*8
    mova         [cfq+64*2], m4
    mova         [cfq+64*3], m5
    mova         [cfq+64*4], m6
    mova         [cfq+64*5], m7
    sub                 cfq, 32
.pass1_dst_fast:
    call .pass1_dst_main
%if WIN64
    pop                  r8
%endif
    jmp .pass2_dct
ALIGN function_align
.pass1_dst_main:
    pmulhrsw             m0, m13, [cfq-64*2]
    pmulhrsw             m1, m13, [cfq-64*1]
    pmulhrsw             m2, m13, [cfq+64*0]
    pmulhrsw             m3, m13, [cfq+64*1]
    pmulhrsw             m4, m13, [cfq+64*2]
    pmulhrsw             m5, m13, [cfq+64*3]
    pmulhrsw             m6, m13, [cfq+64*4]
    pmulhrsw             m7, m13, [cfq+64*5]
    jmp m(inv_txfm_add_8x32_8bpc).pass1_dst_main2

INV_TXFM_FN 64, 8
    add                 cfq, 32*4
    PROLOGUE              0, 8, 14
%if WIN64
    movaps         [rsp+16], xm14
%endif
    vpbroadcastd        m14, [o(pw_181x128)]

.pass1_dct:
    vbroadcasti128       m9, [cfq-16*7]
    vbroadcasti128       m0, [cfq-16*5]
    vbroadcasti128       m2, [cfq-16*3]
    vbroadcasti128       m7, [cfq-16*1]
    vbroadcasti128       m3, [cfq+16*1]
    vbroadcasti128       m4, [cfq+16*3]
    vbroadcasti128       m6, [cfq+16*5]
    vbroadcasti128       m1, [cfq+16*7]
    shufpd               m9, m0, 0x0c
    shufpd               m2, m7, 0x0c
    shufpd               m3, m4, 0x0c
    shufpd               m6, m1, 0x0c
    REPX  {pmulhrsw x, m14}, m9, m2, m3, m6
    punpcklwd            m8, m9, m2      ;  1  5
    punpckhwd            m9, m2          ;  3  7
    punpcklwd            m2, m3, m6      ;  9 13
    punpckhwd            m3, m6          ; 11 15
%if WIN64
    push                 r8
%endif
    push                 r9
    mov                  r8, rsp
    and                 rsp, ~31
    lea                 r3d, [eobq+(21<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    lea                  r9, [cfq+32*8]
    cmovz              eobd, r3d
    sub                 rsp, 32*16
    lea                  r7, [rsp+32*4]
    cmp                eobd, 128<<16
    jl .pass1_dct_fast
    vbroadcasti128       m4, [r9-16*7]
    vbroadcasti128      m11, [r9-16*5]
    vbroadcasti128       m7, [r9-16*3]
    vbroadcasti128      m12, [r9-16*1]
    vbroadcasti128       m0, [r9+16*1]
    vbroadcasti128       m1, [r9+16*3]
    vbroadcasti128       m5, [r9+16*5]
    vbroadcasti128       m6, [r9+16*7]
    shufpd               m4, m11, 0x0c
    shufpd               m7, m12, 0x0c
    shufpd               m0, m1, 0x0c
    shufpd               m5, m6, 0x0c
    REPX  {pmulhrsw x, m14}, m4, m7, m0, m5
    punpcklwd            m6, m7, m4      ; 21 17
    punpckhwd            m7, m4          ; 23 19
    punpcklwd            m4, m5, m0      ; 29 25
    punpckhwd            m5, m0          ; 31 27
    call m(inv_txfm_add_8x32_8bpc).dct32
    call m(inv_txfm_add_32x8_8bpc).pass1_dct_load_dct16
    vbroadcasti128       m4, [r9-16*8]
    vbroadcasti128       m8, [r9-16*6]
    vbroadcasti128       m5, [r9-16*4]
    vbroadcasti128       m9, [r9-16*2]
    vbroadcasti128       m6, [r9+16*0]
    vbroadcasti128      m11, [r9+16*2]
    vbroadcasti128       m7, [r9+16*4]
    vbroadcasti128      m12, [r9+16*6]
    REPX  {pmulhrsw x, m14}, m0, m1, m2, m3
    shufpd               m4, m8, 0x0c    ; 16 18
    shufpd               m5, m9, 0x0c    ; 20 22
    shufpd               m6, m11, 0x0c   ; 24 26
    shufpd               m7, m12, 0x0c   ; 28 30
    REPX  {pmulhrsw x, m14}, m4, m5, m6, m7
    call m(inv_txfm_add_8x16_8bpc).dct16
    jmp .pass1_dct2
.pass1_dct_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    call m(inv_txfm_add_32x8_8bpc).pass1_dct_load_dct16
    REPX  {pmulhrsw x, m14}, m0, m1, m2, m3
    call m(inv_txfm_add_8x16_8bpc).dct16_fast
.pass1_dct2:
    IDCT_8X32_PASS1_END  m0, -4, -4,  6, r9 +32*3, 1 ;  0 15
    IDCT_8X32_PASS1_END  m1, -3, -3,  6, r9 +32*2, 1 ;  1 14
    IDCT_8X32_PASS1_END  m2, -2, -2,  6, r9 +32*1, 1 ;  2 13
    IDCT_8X32_PASS1_END  m3, -1, -1,  6, r9 +32*0, 1 ;  3 12
    IDCT_8X32_PASS1_END  m4,  3,  0,  6, cfq+32*3, 1 ;  4 11
    IDCT_8X32_PASS1_END  m5,  2,  1,  6, cfq+32*2, 1 ;  5 10
    IDCT_8X32_PASS1_END  m6,  1,  2,  6, cfq+32*1, 1 ;  6  9
    IDCT_8X32_PASS1_END  m7,  0,  3,  6, cfq+32*0, 1 ;  7  8
    call .transpose
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [r9 -32*4], m4
    mova         [r9 -32*3], m5
    mova         [r9 -32*2], m6
    mova         [r9 -32*1], m7
    mova                 m0, [r9 +32*3]
    mova                 m1, [r9 +32*2]
    mova                 m2, [r9 +32*1]
    mova                 m3, [r9 +32*0]
    mova                 m4, [cfq+32*3]
    mova                 m5, [cfq+32*2]
    mova                 m6, [cfq+32*1]
    mova                 m7, [cfq+32*0]
    call .transpose
    mov                 rsp, r8
    pop                  r9
%if WIN64
    pop                  r8
    movaps             xm14, [rsp+16]
%endif
    jmp                tx2q
.pass2_dct:
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*0], m0
    mova         [cfq+32*1], m2
    mova         [cfq+32*2], m4
    mova         [cfq+32*3], m6
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [r3 +32*0], m0
    mova         [r3 +32*1], m1
    mova         [r3 +32*2], m2
    mova         [r3 +32*3], m3
    mova                 m0, [cfq+32*0]
    mova                 m1, [cfq+32*1]
    mova                 m2, [cfq+32*2]
    mova                 m3, [cfq+32*3]
    vpbroadcastd        m10, [o(pd_2048)]
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    mova         [cfq+32*2], m6
    mova         [cfq+32*3], m7
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m11, [r3 +32*0]
    mova                 m9, [cfq+32*0]
    psubd               m12, m0, m11
    paddd                m0, m11
    paddd               m11, m4, m9
    psubd                m4, m9
    mova                 m8, [r3 +32*1]
    mova                 m9, [cfq+32*1]
    psrad                m0, 12
    psrad               m11, 12
    packssdw             m0, m11
    psubd               m11, m1, m8
    paddd                m1, m8
    paddd                m8, m5, m9
    psubd                m5, m9
    psrad                m1, 12
    psrad                m8, 12
    packssdw             m1, m8
    mova         [cfq+32*0], m0
    mova         [cfq+32*1], m1
    mova                 m1, [r3 +32*2]
    mova                 m9, [cfq+32*2]
    paddd                m0, m2, m1
    psubd                m2, m1
    paddd                m1, m6, m9
    psubd                m6, m9
    mova                 m8, [r3 +32*3]
    mova                 m9, [cfq+32*3]
    psrad                m0, 12
    psrad                m1, 12
    packssdw             m0, m1
    paddd                m1, m3, m8
    psubd                m3, m8
    paddd                m8, m7, m9
    psubd                m7, m9
    psrad                m1, 12
    psrad                m8, 12
    packssdw             m1, m8
    mova         [cfq+32*2], m0
    mova         [cfq+32*3], m1
    REPX      {psrad x, 12}, m3, m7, m2, m6
    packssdw             m3, m7
    packssdw             m2, m6
    mova         [r3 +32*0], m3
    mova         [r3 +32*1], m2
    REPX      {psrad x, 12}, m11, m5, m12, m4
    packssdw            m11, m5
    packssdw            m12, m4
    mova         [r3 +32*2], m11
    mova         [r3 +32*3], m12
    mova                 m1, [cfq-32*3]
    mova                 m3, [cfq-32*1]
    mova                 m5, [r3 -32*3]
    mova                 m7, [r3 -32*1]
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m1
    mova         [r3 -32*3], m2
    mova         [r3 -32*1], m3
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*2]
    mova                 m2, [r3 -32*4]
    mova                 m3, [r3 -32*2]
    mova         [cfq-32*4], m4
    mova         [cfq-32*2], m5
    mova         [r3 -32*4], m6
    mova         [r3 -32*2], m7
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m12, [cfq-32*3]
    mova                 m9, [cfq-32*4]
    psubd               m13, m0, m12
    paddd                m0, m12
    paddd               m12, m4, m9
    psubd                m4, m9
    mova                 m8, [cfq-32*1]
    mova                 m9, [cfq-32*2]
    REPX      {psrad x, 12}, m0, m12, m13, m4
    packssdw             m0, m12
    packssdw            m13, m4
    psubd               m12, m1, m8
    paddd                m1, m8
    paddd                m8, m5, m9
    psubd                m5, m9
    REPX      {psrad x, 12}, m1, m8, m12, m5
    packssdw             m1, m8
    packssdw            m12, m5
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    pxor                m10, m10
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    mova                 m1, [r3 -32*3]
    mova                 m9, [r3 -32*4]
    paddd                m0, m2, m1
    psubd                m2, m1
    paddd                m1, m6, m9
    psubd                m6, m9
    mova                 m8, [r3 -32*1]
    mova                 m9, [r3 -32*2]
    psrad                m0, 12
    psrad                m1, 12
    packssdw             m0, m1
    paddd                m1, m3, m8
    psubd                m3, m8
    paddd                m8, m7, m9
    psubd                m7, m9
    psrad                m1, 12
    psrad                m8, 12
    packssdw             m1, m8
    mova                 m4, [cfq+32*2]
    mova                 m5, [cfq+32*3]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    mova                 m4, [r3 +32*0]
    mova                 m5, [r3 +32*1]
    REPX      {psrad x, 12}, m3, m7, m2, m6
    packssdw             m0, m3, m7
    packssdw             m1, m2, m6
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    mova                 m4, [r3 +32*2]
    mova                 m5, [r3 +32*3]
    mova                 m0, m12
    mova                 m1, m13
    call m(inv_txfm_add_64x4_8bpc).write_64x2
.pass2_end:
    mov                  r6, -32*16
    call m(inv_txfm_add_16x16_8bpc).zero_cf
    RET
ALIGN function_align
.transpose:
    punpckhwd             m8, m3, m2
    punpcklwd             m2, m3
    punpckhwd             m3, m1, m0
    punpcklwd             m0, m1
    punpckhwd             m1, m5, m4
    punpcklwd             m4, m5
    punpckhwd             m5, m7, m6
    punpcklwd             m6, m7
    vperm2i128            m7, m0, m5, 0x31
    vinserti128           m0, xm5, 1
    vinserti128           m5, m2, xm1, 1
    vperm2i128            m2, m1, 0x31
    vperm2i128            m1, m4, m8, 0x31
    vinserti128           m4, xm8, 1
    vinserti128           m8, m6, xm3, 1
    vperm2i128            m6, m3, 0x31
    punpckhdq             m3, m0, m5
    punpckldq             m0, m5
    punpckldq             m5, m7, m2
    punpckhdq             m7, m2
    punpckldq             m2, m4, m8
    punpckhdq             m4, m8
    punpckldq             m8, m1, m6
    punpckhdq             m1, m6
    punpcklqdq            m6, m7, m1
    punpckhqdq            m7, m1
    punpckhqdq            m1, m0, m2
    punpcklqdq            m0, m2
    punpcklqdq            m2, m3, m4
    punpckhqdq            m3, m4
    punpcklqdq            m4, m5, m8
    punpckhqdq            m5, m8
    ret

.dconly:
    movd                xm5, [o(pw_181x128)]
    pmulhrsw            xm5, [cfq]
    movd                xm4, [o(pw_512)]
    or                  r4d, 8
    pmulhrsw            xm5, xm4
    jmp m(inv_txfm_add_64x4_8bpc).dconly3

.pass2_identity:
    vpbroadcastd        m12, [o(pw_181x8)]
    lea                  r3, [cfq+32*8]
    pxor                m10, m10
    mova         [cfq+32*0], m4
    mova         [cfq+32*1], m5
    pmulhrsw             m4, m12, m0
    pmulhrsw             m0, m12, [cfq-32*4]
    pmulhrsw             m5, m12, m1
    pmulhrsw             m1, m12, [cfq-32*3]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    pmulhrsw             m0, m12, [cfq-32*2]
    pmulhrsw             m4, m12, m2
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m5, m12, m3
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    pmulhrsw             m0, m12, [r3 -32*4]
    pmulhrsw             m4, m12, [cfq+32*0]
    pmulhrsw             m1, m12, [r3 -32*3]
    pmulhrsw             m5, m12, [cfq+32*1]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    pmulhrsw             m0, m12, [r3 -32*2]
    pmulhrsw             m4, m12, m6
    pmulhrsw             m1, m12, [r3 -32*1]
    pmulhrsw             m5, m12, m7
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    jmp .pass2_end
ALIGN function_align
.pass1_identity_main:
    lea                  r3, [cfq+16*16]
    mova                xm0, [cfq-16*8]
    vinserti128          m0, [r3 -16*8], 1
    mova                xm1, [cfq-16*7]
    vinserti128          m1, [r3 -16*7], 1
    mova                xm2, [cfq-16*6]
    vinserti128          m2, [r3 -16*6], 1
    mova                xm3, [cfq-16*5]
    vinserti128          m3, [r3 -16*5], 1
    mova                xm4, [cfq-16*4]
    vinserti128          m4, [r3 -16*4], 1
    mova                xm5, [cfq-16*3]
    vinserti128          m5, [r3 -16*3], 1
    mova                xm6, [cfq-16*2]
    vinserti128          m6, [r3 -16*2], 1
    mova                xm7, [cfq-16*1]
    vinserti128          m7, [r3 -16*1], 1
    REPX      {paddsw x, x}, m0, m1, m2, m3, m4, m5, m6, m7
    call m(inv_txfm_add_32x4_8bpc).identity_main
    jmp m(inv_txfm_add_16x8_8bpc).transpose8x8

.pass2_flipddt:
    lea                  r3, [o(flipddt8_mat)]
    jmp .pass2_dst
.pass2_ddt:
    lea                  r3, [o(ddt8_mat)]
    jmp .pass2_dst
.pass2_flipadst:
    lea                  r3, [o(flipadst8_mat)]
    jmp .pass2_dst
.pass2_adst:
    lea                  r3, [o(adst8_mat)]
.pass2_dst:
    add                 cfq, 32*4
    call m(inv_txfm_add_32x8_8bpc).pass2_dst_main
    mova                 m4, [cfq+32*0]
    mova                 m5, [cfq+32*1]
    mova                 m6, [cfq+32*2]
    mova                 m7, [cfq+32*3]
    sub                 cfq, 32*4
    mova                 m0, [cfq-32*4]
    mova                 m1, [cfq-32*3]
    mova                 m2, [cfq-32*2]
    mova                 m3, [cfq-32*1]
    sub                  r3, 16*8
    call m(inv_txfm_add_32x8_8bpc).pass2_dst_main
    vpbroadcastd        m12, [o(pw_4096)]
    lea                  r3, [cfq+32*8]
    pxor                m10, m10
    pmulhrsw             m0, m12, [r3 -32*1]
    pmulhrsw             m4, m12, [r3 +32*3]
    pmulhrsw             m1, m12, [cfq-32*1]
    pmulhrsw             m5, m12, [cfq+32*3]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    pmulhrsw             m0, m12, [r3 -32*2]
    pmulhrsw             m4, m12, [r3 +32*2]
    pmulhrsw             m1, m12, [cfq-32*2]
    pmulhrsw             m5, m12, [cfq+32*2]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    pmulhrsw             m0, m12, [r3 -32*3]
    pmulhrsw             m4, m12, [r3 +32*1]
    pmulhrsw             m1, m12, [cfq-32*3]
    pmulhrsw             m5, m12, [cfq+32*1]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    pmulhrsw             m0, m12, [r3 -32*4]
    pmulhrsw             m4, m12, [r3 +32*0]
    pmulhrsw             m1, m12, m6
    pmulhrsw             m5, m12, [cfq+32*0]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    jmp .pass2_end

INV_TXFM_FN 16, 64
    add                 cfq, 32*4
    PROLOGUE              0, 8, 15, 32*48
    jmp                tx1q

.dconly:
    movd                xm3, [o(pw_256)]
    or                  r4d, 32
    jmp m(inv_txfm_add_16x4_8bpc).dconly2

.pass1_dct:
    lea                  r7, [rsp+32*4]
    sub                eobd, 136<<16
    jl .pass1_dct_fast
    add                 cfq, 32
    call .pass1_dct_main
    sub                 cfq, 32
    call .pass1_dct_main
.pass1_end:
    add                 cfq, 64*8+32
    call m(inv_txfm_add_16x32_8bpc).transpose8x8_mem
    sub                 cfq, 64*8
    call m(inv_txfm_add_16x32_8bpc).transpose8x8_mem
    add                 cfq, 64*8-32
    jmp .pass1_end3
.pass1_dct_fast:
    call .pass1_dct_main
.pass1_end2:
    add                 cfq, 64*8
.pass1_end3:
    call m(inv_txfm_add_16x32_8bpc).transpose8x8_mem
    sub                 cfq, 64*8
    call m(inv_txfm_add_16x32_8bpc).transpose8x8_mem
.pass2_dct:
    lea                  r5, [cfq+32* 8]
    mova                 m0, [cfq-32* 2] ;  1
    mova                 m5, [cfq+32* 2] ;  3
    mova                 m1, [r5 -32* 2] ;  5
    mova                 m2, [r5 +32* 2] ;  7
    mova                 m4, [cfq+32*14] ;  9
    mova                 m7, [cfq+32*18] ; 11
    mova                 m3, [cfq+32*22] ; 13
    mova                 m6, [cfq+32*26] ; 15
    punpcklwd            m8, m0, m1  ;  1  5
    punpckhwd            m0, m1
    punpcklwd            m9, m5, m2  ;  3  7
    punpckhwd            m5, m2
    punpcklwd            m2, m4, m3  ;  9 13
    punpckhwd            m4, m3
    punpcklwd            m3, m7, m6  ; 11 15
    punpckhwd            m7, m6
    lea                  r7, [rsp+32*20]
    mova         [cfq-32*2], m0
    mova         [cfq+32*2], m5
    mova         [r5 -32*2], m4
    mova         [r5 +32*2], m7
    test               eobd, eobd
    jl .pass2_dct_fast
    mova                 m7, [cfq-32* 1] ; 17
    mova                 m4, [cfq+32* 3] ; 19
    mova                m10, [r5 -32* 1] ; 21
    mova                m11, [r5 +32* 3] ; 23
    mova                 m5, [cfq+32*15] ; 25
    mova                 m1, [cfq+32*19] ; 27
    mova                m12, [cfq+32*23] ; 29
    mova                 m0, [cfq+32*27] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova         [cfq-32*1], m10
    mova         [cfq+32*3], m11
    mova         [r5 -32*1], m12
    mova         [r5 +32*3], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-32* 2]
    mova                 m9, [cfq+32* 2]
    mova                 m2, [r5 -32* 2]
    mova                 m3, [r5 +32* 2]
    mova                 m6, [cfq-32* 1]
    mova                 m7, [cfq+32* 3]
    mova                 m4, [r5 -32* 1]
    mova                 m5, [r5 +32* 3]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m1, [cfq+32* 0] ;  2
    mova                 m3, [r5 +32* 0] ;  6
    mova                 m5, [cfq+32*16] ; 10
    mova                 m7, [cfq+32*24] ; 14
    mova                 m8, [cfq+32* 1] ; 18
    mova                 m9, [r5 +32* 1] ; 22
    mova                m10, [cfq+32*17] ; 26
    mova                m11, [cfq+32*25] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [r5 -32* 4] ;  4
    mova                 m3, [cfq+32*20] ; 12
    mova                 m5, [r5 -32* 3] ; 20
    mova                 m7, [cfq+32*21] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*0], m3
    mova         [r3 +32*3], m4
    mova         [r3 +32*2], m5
    mova         [r3 +32*1], m6
    mova         [r3 +32*0], m7
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32*12] ;  8
    mova                 m2, [cfq-32* 3] ; 16
    mova                 m3, [cfq+32*13] ; 24
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass2_dct2
.pass2_dct_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m8, [cfq-32* 2]
    mova                 m9, [cfq+32* 2]
    mova                 m2, [r5 -32* 2]
    mova                 m3, [r5 +32* 2]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32* 0] ;  2
    mova                 m2, [r5 -32* 4] ;  4
    mova                 m3, [r5 +32* 0] ;  6
    mova                 m4, [cfq+32*12] ;  8
    mova                 m5, [cfq+32*16] ; 10
    mova                 m6, [cfq+32*20] ; 12
    mova                 m7, [cfq+32*24] ; 14
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16_fast
    vpbroadcastd        m10, [o(pd_4096)]
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m1
    mova         [cfq+32*2], m2
    mova         [cfq+32*1], m3
    mova         [cfq+32*0], m8
    mova         [r3 +32*3], m5
    mova         [r3 +32*2], m6
    mova         [r3 +32*1], m7
    mova         [r3 +32*0], m9
    call m(inv_txfm_add_16x16_8bpc).dct4_fast
.pass2_dct2:
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [r3 -32*4], m4
    mova         [r3 -32*3], m5
    mova         [r3 -32*2], m6
    mova         [r3 -32*1], m7
    sub                  r7, cfq
    mov                  r3, cfq
    add                 cfq, 32*2
    call .pass2_dct_end
    mov                 cfq, r3
    add                  r3, 32*2
    call .pass2_dct_end
    mov                 r6d, 32*31
.pass2_dct_write_loop:
    pmovzxbw             m0, [dstq+dsq*0]
    pmovzxbw             m1, [dstq+dsq*1]
    mova                 m2, [cfq+r6-32*4]
    paddw                m0, m2
    paddw                m1, m2
    packuswb             m0, m1
    vpermq               m0, m0, q3120
    movu         [dstq+dsq*0], xm0
    vextracti128 [dstq+dsq*1], m0, 1
    lea                dstq, [dstq+dsq*2]
    sub                 r6d, 32
    jge .pass2_dct_write_loop
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end
ALIGN function_align
.pass1_dct_main:
    mova                 m1, [cfq-64* 1] ;  1
    mova                 m3, [cfq+64* 1] ;  3
    mova                 m5, [cfq+64* 3] ;  5
    mova                 m7, [cfq+64* 5] ;  7
    mova                 m8, [cfq+64* 7] ;  9
    mova                 m9, [cfq+64* 9] ; 11
    mova                m10, [cfq+64*11] ; 13
    mova                m11, [cfq+64*13] ; 15
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [cfq+64* 0] ;  2
    mova                 m3, [cfq+64* 4] ;  6
    mova                 m5, [cfq+64* 8] ; 10
    mova                 m7, [cfq+64*12] ; 14
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq+64*5], m0
    mova         [cfq+64*4], m1
    mova         [cfq+64*0], m2
    mova         [cfq+64*1], m3
    mova                 m0, [cfq-64* 2] ;  0
    mova                 m1, [cfq+64* 2] ;  4
    mova                 m2, [cfq+64* 6] ;  8
    mova                 m3, [cfq+64*10] ; 12
    jmp m(inv_txfm_add_16x32_8bpc).pass1_dct_main2
ALIGN function_align
.pass2_dct_end:
    IDCT_16X32_PASS2_END 13

.pass1_identity:
    sub                eobd, 256<<16
    jl .pass1_identity_fast
    add                 cfq, 32
    call .pass1_identity_main
    sub                 cfq, 64*2+32
    call .pass1_identity_main
    sub                 cfq, 64*2
    jmp .pass1_end
.pass1_identity_fast:
    call .pass1_identity_main
    sub                 cfq, 64*2
    jmp .pass1_end2
ALIGN function_align
.pass1_identity_main:
    mov                  r3, cfq
    call .pass1_identity_main2
    add                 cfq, 64*2
    sub                  r3, 64*2
.pass1_identity_main2:
    mova                 m0, [cfq-64* 2]
    mova                 m1, [cfq+64* 6]
    mova                 m2, [cfq-64* 1]
    mova                 m3, [cfq+64* 7]
    mova                 m4, [r3 +64* 4]
    mova                 m5, [r3 +64*12]
    mova                 m6, [r3 +64* 5]
    mova                 m7, [r3 +64*13]
    jmp m(inv_txfm_add_16x32_8bpc).pass1_identity_main3

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
    vpbroadcastd        m13, [o(pd_32)]
    sub                eobd, 136<<16
    jl .pass1_dst_fast
    add                 cfq, 32
    call .pass1_dst_main
    sub                 cfq, 32
    sub                  r3, 32*16+4*4
    call .pass1_dst_main
    jmp .pass1_end
.pass1_dst_fast:
    call .pass1_dst_main
    jmp .pass1_end2
ALIGN function_align
.pass1_dst_main:
    mova                 m0, [cfq-64*2]
    mova                 m1, [cfq-64*1]
    mova                 m2, [cfq+64*0]
    mova                 m3, [cfq+64*1]
    mova                 m4, [cfq+64*2]
    mova                 m5, [cfq+64*3]
    mova                 m6, [cfq+64*4]
    mova                 m7, [cfq+64*5]
    call m(inv_txfm_add_16x16_8bpc).dst16x1
    mov                 r7d, 32*28+gprsize
    mova      [rsp+r7+32*3], m1
    mova      [rsp+r7+32*2], m7
.pass1_dst_loop1:
    call m(inv_txfm_add_16x16_8bpc).dst16x1b
    mova      [rsp+r7+32*1], m1
    mova      [rsp+r7+32*0], m7
    sub                 r7d, 32*2
    jg .pass1_dst_loop1
    mova                 m0, [cfq+64* 6]
    mova                 m1, [cfq+64* 7]
    mova                 m2, [cfq+64* 8]
    mova                 m3, [cfq+64* 9]
    mova                 m4, [cfq+64*10]
    mova                 m5, [cfq+64*11]
    mova                 m6, [cfq+64*12]
    mova                 m7, [cfq+64*13]
    add                  r3, 4*4-32*16
    call m(inv_txfm_add_16x16_8bpc).dst16x1
    mov                 r7d, 64*7
    jmp m(inv_txfm_add_16x32_8bpc).pass1_dst_loop2a_start

INV_TXFM_FN 64, 16
    add                 cfq, 32*4
    PROLOGUE              0, 8, 15, 32*48

.pass1_dct:
    mova                 m0, [cfq-32* 3] ;  1
    mova                 m5, [cfq-32* 1] ;  3
    mova                 m1, [cfq+32* 1] ;  5
    mova                 m2, [cfq+32* 3] ;  7
    mova                 m4, [cfq+32* 5] ;  9
    mova                 m7, [cfq+32* 7] ; 11
    mova                 m3, [cfq+32* 9] ; 13
    mova                 m6, [cfq+32*11] ; 15
    punpcklwd            m8, m0, m1  ;  1  5
    punpckhwd            m0, m1
    punpcklwd            m9, m5, m2  ;  3  7
    punpckhwd            m5, m2
    punpcklwd            m2, m4, m3  ;  9 13
    punpckhwd            m4, m3
    punpcklwd            m3, m7, m6  ; 11 15
    punpckhwd            m7, m6
    mova         [cfq-32*3], m0
    mova         [cfq-32*1], m5
    mova         [cfq+32*1], m4
    mova         [cfq+32*3], m7
    lea                 r3d, [eobq+(105<<16)]
    test               eobb, 0x10 ; TX_CLASS_H
    cmovz              eobd, r3d
    lea                  r7, [rsp+32*20]
    cmp                eobd, 256<<16
    jl .pass1_dct_fast
    mova                 m7, [cfq+32*13] ; 17
    mova                 m4, [cfq+32*15] ; 19
    mova                m10, [cfq+32*17] ; 21
    mova                m11, [cfq+32*19] ; 23
    mova                 m5, [cfq+32*21] ; 25
    mova                 m1, [cfq+32*23] ; 27
    mova                m12, [cfq+32*25] ; 29
    mova                 m0, [cfq+32*27] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova        [cfq+32* 5], m10
    mova        [cfq+32* 7], m11
    mova        [cfq+32* 9], m12
    mova        [cfq+32*11], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-32* 3]
    mova                 m9, [cfq-32* 1]
    mova                 m2, [cfq+32* 1]
    mova                 m3, [cfq+32* 3]
    mova                 m6, [cfq+32* 5]
    mova                 m7, [cfq+32* 7]
    mova                 m4, [cfq+32* 9]
    mova                 m5, [cfq+32*11]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m1, [cfq-32* 2] ;  2
    mova                 m3, [cfq+32* 2] ;  6
    mova                 m5, [cfq+32* 6] ; 10
    mova                 m7, [cfq+32*10] ; 14
    mova                 m8, [cfq+32*14] ; 18
    mova                 m9, [cfq+32*18] ; 22
    mova                m10, [cfq+32*22] ; 26
    mova                m11, [cfq+32*26] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [cfq+32* 0] ;  4
    mova                 m3, [cfq+32* 8] ; 12
    mova                 m5, [cfq+32*16] ; 20
    mova                 m7, [cfq+32*24] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq+32*1], m2
    mova         [cfq+32*0], m3
    mova         [r3 +32*3], m4
    mova         [r3 +32*2], m5
    mova         [r3 +32*1], m6
    mova         [r3 +32*0], m7
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32* 4] ;  8
    mova                 m2, [cfq+32*12] ; 16
    mova                 m3, [cfq+32*20] ; 24
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass1_dct2
.pass1_dct_fast:
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m8, [cfq-32* 3]
    mova                 m9, [cfq-32* 1]
    mova                 m2, [cfq+32* 1]
    mova                 m3, [cfq+32* 3]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq-32* 2] ;  2
    mova                 m2, [cfq+32* 0] ;  4
    mova                 m3, [cfq+32* 2] ;  6
    mova                 m4, [cfq+32* 4] ;  8
    mova                 m5, [cfq+32* 6] ; 10
    mova                 m6, [cfq+32* 8] ; 12
    mova                 m7, [cfq+32*10] ; 14
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16_fast
    vpbroadcastd        m10, [o(pd_32)]
    lea                  r3, [cfq+32*8]
    mova         [cfq+32*3], m1
    mova         [cfq+32*2], m2
    mova         [cfq+32*1], m3
    mova         [cfq+32*0], m8
    mova         [r3 +32*3], m5
    mova         [r3 +32*2], m6
    mova         [r3 +32*1], m7
    mova         [r3 +32*0], m9
    call m(inv_txfm_add_16x16_8bpc).dct4_fast
.pass1_dct2:
    mova         [cfq-32*4], m0
    mova         [cfq-32*3], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova         [r3 -32*4], m4
    mova         [r3 -32*3], m5
    mova         [r3 -32*2], m6
    mova         [r3 -32*1], m7
    sub                  r7, cfq
    mov                  r3, cfq
    add                 cfq, 32*2
    call .pass1_dct_end
    mov                 cfq, r3
    add                  r3, 32*2
    call .pass1_dct_end
    mov                 r3d, 32*24
.transpose_loop:
    mova                 m0, [cfq+r3-32*4]
    mova                 m1, [cfq+r3-32*3]
    mova                 m2, [cfq+r3-32*2]
    mova                 m3, [cfq+r3-32*1]
    mova                 m4, [cfq+r3+32*0]
    mova                 m5, [cfq+r3+32*1]
    mova                 m6, [cfq+r3+32*2]
    mova                 m7, [cfq+r3+32*3]
    call m(inv_txfm_add_16x8_8bpc).transpose8x8
    mova      [cfq+r3-32*4], m0
    mova      [cfq+r3-32*3], m1
    mova      [cfq+r3-32*2], m2
    mova      [cfq+r3-32*1], m3
    mova      [cfq+r3+32*0], m4
    mova      [cfq+r3+32*1], m5
    mova      [cfq+r3+32*2], m6
    mova      [cfq+r3+32*3], m7
    sub                 r3d, 32*8
    jge .transpose_loop
    jmp                tx2q
.pass2_dct:
    lea                  r7, [rsp+32*4]
    call .pass2_dct_main
    add                 cfq, 32*8
    call .pass2_dct_main
    mov                 r6d, 32*7
    pxor                m10, m10
.pass2_dct_write_loop:
    mova                 m0, [cfq+r6+32* 4]
    mova                 m4, [cfq+r6+32*12]
    mova                 m1, [cfq+r6-32*12]
    mova                 m5, [cfq+r6-32* 4]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    sub                 r6d, 32
    jge .pass2_dct_write_loop
    sub                 cfq, 32*8
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end
ALIGN function_align
.pass1_dct_end:
    mova                 m0, [cfq   -32* 4] ; dct4  a0
    mova                 m1, [cfq   +32* 4]
    mova                 m2, [r3    +32* 1] ; dct8  b0
    mova                 m3, [r3    +32* 9]
    mova                 m4, [cfq+r7-32* 4] ; dct16 c0
    mova                 m5, [cfq+r7+32* 4]
    mova                 m6, [cfq+r7+32*12] ; dct32 d0
    mova                 m7, [cfq+r7+32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [cfq+r7+32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [cfq+r7+32*36]
    mova         [cfq-16* 8], xm0
    vextracti128 [cfq+16*24], m0, 1
    mova         [r3 +16*19], xm5
    vextracti128 [r3 +16*51], m5, 1
    mova                 m0, [cfq+r7+32* 0] ; dct16 c7
    mova                 m5, [cfq+r7+32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r3 +r7+32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r3 +r7+32*33]
    mova         [r3 +16* 3], xm3
    vextracti128 [r3 +16*35], m3, 1
    mova         [cfq+16* 8], xm7
    vextracti128 [cfq+16*40], m7, 1
    mova                 m3, [r3 +r7+32*25] ; dct32 d8
    mova                 m7, [r3 +r7+32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova         [r3 +16* 2], xm6
    vextracti128 [r3 +16*34], m6, 1
    mova         [cfq+16* 9], xm5
    vextracti128 [cfq+16*41], m5, 1
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova         [cfq-16* 7], xm3
    vextracti128 [cfq+16*25], m3, 1
    mova         [r3 +16*18], xm1
    vextracti128 [r3 +16*50], m1, 1
    mova                 m0, [cfq   -32* 3] ; dct4  a1
    mova                 m1, [cfq   +32* 5]
    mova                 m2, [r3    +32* 0] ; dct8  b1
    mova                 m3, [r3    +32* 8]
    mova                 m4, [cfq+r7-32* 3] ; dct16 c1
    mova                 m5, [cfq+r7+32* 5]
    mova                 m6, [cfq+r7+32*13] ; dct32 d1
    mova                 m7, [cfq+r7+32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [cfq+r7+32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [cfq+r7+32*37]
    mova         [cfq-16* 6], xm0
    vextracti128 [cfq+16*26], m0, 1
    mova         [r3 +16*17], xm5
    vextracti128 [r3 +16*49], m5, 1
    mova                 m0, [cfq+r7+32* 1] ; dct16 c6
    mova                 m5, [cfq+r7+32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r3 +r7+32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r3 +r7+32*40]
    mova         [r3 +16* 1], xm3
    vextracti128 [r3 +16*33], m3, 1
    mova         [cfq+16*10], xm7
    vextracti128 [cfq+16*42], m7, 1
    mova                 m3, [r3 +r7+32*16] ; dct32 d6
    mova                 m7, [r3 +r7+32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova         [cfq-16* 5], xm6
    vextracti128 [cfq+16*27], m6, 1
    mova         [r3 +16*16], xm5
    vextracti128 [r3 +16*48], m5, 1
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova         [r3 +16* 0], xm3
    vextracti128 [r3 +16*32], m3, 1
    mova         [cfq+16*11], xm1
    vextracti128 [cfq+16*43], m1, 1
    ret
ALIGN function_align
.pass2_dct_main:
    mova                 m1, [cfq-32 *3] ;  1
    mova                 m3, [cfq-32 *1] ;  3
    mova                 m5, [cfq+32 *1] ;  5
    mova                 m7, [cfq+32 *3] ;  7
    mova                 m8, [cfq+32*13] ;  9
    mova                 m9, [cfq+32*15] ; 11
    mova                m10, [cfq+32*17] ; 13
    mova                m11, [cfq+32*19] ; 15
    call m(inv_txfm_add_16x16_8bpc).dct16
    mova                 m1, [cfq-32* 2] ;  2
    mova                 m3, [cfq+32* 2] ;  6
    mova                 m5, [cfq+32*14] ; 10
    mova                 m7, [cfq+32*18] ; 14
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova         [cfq+32*3], m0
    mova         [cfq+32*2], m1
    mova         [cfq-32*2], m2
    mova         [cfq-32*1], m3
    mova                 m0, [cfq-32* 4] ;  0
    mova                 m1, [cfq+32* 0] ;  4
    mova                 m2, [cfq+32*12] ;  8
    mova                 m3, [cfq+32*16] ; 12
    mova         [cfq-32*4], m4
    mova         [cfq-32*3], m5
    mova         [cfq+32*1], m6
    mova         [cfq+32*0], m7
    vpbroadcastd        m10, [o(pd_4096)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    mova                m11, [cfq+32* 3]
    mova                m12, [cfq-32* 4]
    mova                 m9, [r7 -32* 4]
    mova                m13, [r7 +32* 4]
    psubd               m10, m0, m11
    paddd                m0, m11
    psubd               m11, m4, m12
    paddd                m4, m12
    psubd               m12, m0, m9  ; out15a
    paddd                m0, m9      ; out0a
    psubd                m9, m4, m13 ; out15b
    paddd                m4, m13     ; out0b
    mova                 m8, [cfq+32* 2]
    mova                m13, [cfq-32* 3]
    REPX      {psrad x, 13}, m0, m4, m12, m9
    packssdw             m0, m4
    mova                 m4, [r7 -32* 3]
    packssdw            m12, m9
    mova                 m9, [r7 +32* 5]
    mova        [cfq+32*19], m0
    mova        [cfq-32* 4], m12
    psubd               m12, m1, m8
    paddd                m8, m1
    paddd                m1, m5, m13
    psubd                m5, m13
    psubd               m13, m8, m4  ; out14a
    paddd                m8, m4      ; out1a
    psubd                m4, m1, m9  ; out14b
    paddd                m1, m9      ; out1b
    mova                 m9, [cfq-32* 2]
    mova                 m0, [cfq+32* 1]
    REPX      {psrad x, 13}, m8, m1, m13, m4
    packssdw             m8, m1
    mova                 m1, [r7 -32* 2]
    packssdw            m13, m4
    mova                 m4, [r7 +32* 6]
    mova        [cfq+32* 3], m8
    mova        [cfq+32*12], m13
    psubd                m8, m2, m9
    paddd                m2, m9
    psubd                m9, m6, m0
    paddd                m6, m0
    psubd                m0, m2, m1  ; out13a
    paddd                m2, m1      ; out2a
    psubd                m1, m6, m4  ; out13b
    paddd                m6, m4      ; out2b
    mova                 m4, [cfq-32* 1]
    mova                m13, [cfq+32* 0]
    REPX      {psrad x, 13}, m2, m6, m0, m1
    packssdw             m2, m6
    mova                 m6, [r7 -32* 1]
    packssdw             m0, m1
    mova                 m1, [r7 +32* 7]
    mova        [cfq+32*18], m2
    mova        [cfq-32* 3], m0
    psubd                m2, m3, m4
    paddd                m3, m4
    paddd                m4, m7, m13
    psubd                m7, m13
    psubd               m13, m3, m6  ; out12a
    paddd                m3, m6      ; out3a
    paddd                m6, m4, m1  ; out3b
    psubd                m4, m1      ; out12b
    mova                 m0, [r7+32* 3]
    mova                 m1, [r7+32*11]
    REPX      {psrad x, 13}, m3, m6, m13, m4
    packssdw             m3, m6
    mova                 m6, [r7+32* 2]
    packssdw            m13, m4
    mova                 m4, [r7+32*10]
    mova        [cfq+32* 2], m3
    mova        [cfq+32*13], m13
    psubd                m3, m2, m0  ; out11a
    paddd                m2, m0      ; out4a
    psubd                m0, m7, m1  ; out11b
    paddd                m7, m1      ; out4b
    REPX      {psrad x, 13}, m2, m7, m3, m0
    packssdw             m2, m7
    mova                 m7, [r7+32* 1]
    packssdw             m3, m0
    mova                 m0, [r7+32* 9]
    mova        [cfq+32*17], m2
    mova        [cfq-32* 2], m3
    psubd                m3, m8, m6  ; out5a
    paddd                m6, m8      ; out10a
    psubd                m2, m9, m4  ; out5b
    paddd                m4, m9      ; out10b
    REPX      {psrad x, 13}, m3, m2, m6, m4
    packssdw             m3, m2
    mova                 m2, [r7+32* 0]
    packssdw             m6, m4
    mova                 m4, [r7+32* 8]
    mova        [cfq+32* 1], m3
    mova        [cfq+32*14], m6
    psubd                m3, m12, m7 ; out9a
    paddd                m7, m12     ; out6a
    paddd                m1, m5, m0  ; out6b
    psubd                m5, m0      ; out9b
    REPX      {psrad x, 13}, m7, m1, m3, m5
    packssdw             m7, m1
    packssdw             m3, m5
    mova        [cfq+32*16], m7
    mova        [cfq-32* 1], m3
    psubd                m0, m10, m2 ; out7a
    paddd                m2, m10     ; out8a
    psubd                m3, m11, m4 ; out7b
    paddd                m4, m11     ; out8b
    REPX      {psrad x, 13}, m0, m3, m2, m4
    packssdw             m0, m3
    packssdw             m2, m4
    mova        [cfq+32* 0], m0
    mova        [cfq+32*15], m2
    ret

.dconly:
    or                  r4d, 16
    jmp m(inv_txfm_add_64x4_8bpc).dconly2

.pass2_identity:
    vpbroadcastd        m12, [o(pw_1024)]
    mov                  r3, cfq
    pxor                m10, m10
.pass2_identity_regular:
    mov                  r6, -32*6
.pass2_identity_regular_loop:
    pmulhrsw             m0, m12, [r3+r6+32* 2]
    pmulhrsw             m4, m12, [r3+r6+32*10]
    pmulhrsw             m1, m12, [r3+r6+32* 3]
    pmulhrsw             m5, m12, [r3+r6+32*11]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    add                  r6, 32*2
    jle .pass2_identity_regular_loop
    add                  r3, 32*16
    add                eobd, 0x80000000
    jnc .pass2_identity_regular
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end

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
    mov                  r7, r3
    call m(inv_txfm_add_32x16_8bpc).pass2_dst_main
    add                 cfq, 32*8
    mov                  r3, r7
    call m(inv_txfm_add_32x16_8bpc).pass2_dst_main
    vpbroadcastd        m12, [o(pw_2048)]
    mov                 r3d, 32*7
    pxor                m10, m10
.pass2_dst_write_loop:
    pmulhrsw             m0, m12, [cfq+r3-32*12]
    pmulhrsw             m4, m12, [cfq+r3-32* 4]
    pmulhrsw             m1, m12, [cfq+r3+32* 4]
    pmulhrsw             m5, m12, [cfq+r3+32*12]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    sub                 r3d, 32
    jge .pass2_dst_write_loop
    sub                 cfq, 32*8
    jmp m(inv_txfm_add_32x16_8bpc).pass2_end

cglobal inv_txfm_add_32x64_8bpc, 4, 7, 0, dst, ds, cf, tx1, eob, tx2
    movifnidn          eobd, eobm
    lea                  r6, [o_base]
    shl                eobd, 16
    jz .dconly
    PROLOGUE              0, 8, 14, 32*48
%if WIN64
    movaps      [rsp+32*48], xm14
%endif
    vpbroadcastd        m14, [o(pw_181x128)]
    add                 cfq, 32*4
    mov                 r3d, 136<<16
    call m(inv_txfm_add_64x32_8bpc).pass1_dct_main
    call m(inv_txfm_add_32x32_8bpc).pass1_dct_main2
    sub                eobd, 136<<16
    jl .pass1_end
    add                 cfq, 32
    mov                 r3d, 172<<16
    call m(inv_txfm_add_64x32_8bpc).pass1_dct_main
    call m(inv_txfm_add_32x32_8bpc).pass1_dct_main2
    sub                 cfq, 32
    mov                 r3d, 64*24+32
    call m(inv_txfm_add_32x32_8bpc).transpose
.pass1_end:
    mov                 r3d, 64*24
    call m(inv_txfm_add_32x32_8bpc).transpose
    add                 cfq, 64*16
    call m(inv_txfm_add_64x32_8bpc).pass2_dct_main
    sub                 cfq, 64*16
    call m(inv_txfm_add_64x32_8bpc).pass2_dct_main
    pxor                 m6, m6
    mov                 r6d, 64*15
    call .write_32x32
    mov                 r6d, 64*15+32
    call .write_32x32
    jmp m(inv_txfm_add_64x32_8bpc).end
.dconly:
    movd                xm3, [o(pw_181x128)]
    pmulhrsw            xm3, [cfq]
    movd                xm2, [o(pw_512)]
    or                  r4d, 64
    pmulhrsw            xm3, xm2
    jmp m(inv_txfm_add_32x4_8bpc).dconly2
ALIGN function_align
.write_32x32:
    movu                 m2, [dstq+dsq*0]
    movu                 m3, [dstq+dsq*1]
    mova                 m4, [cfq+r6-64* 2]
    mova                 m5, [cfq+r6+64*14]
    punpcklbw            m0, m2, m6
    punpckhbw            m2, m6
    punpcklbw            m1, m3, m6
    punpckhbw            m3, m6
    paddw                m0, m4
    paddw                m2, m5
    paddw                m1, m4
    paddw                m3, m5
    packuswb             m0, m2
    packuswb             m1, m3
    movu       [dstq+dsq*0], m0
    movu       [dstq+dsq*1], m1
    lea                dstq, [dstq+dsq*2]
    sub                 r6d, 64
    jge .write_32x32
    ret

cglobal inv_txfm_add_64x32_8bpc, 4, 7, 0, dst, ds, cf, tx1, eob, tx2
    movifnidn          eobd, eobm
    lea                  r6, [o_base]
    shl                eobd, 16
    jz .dconly
    PROLOGUE              0, 8, 14, 32*48
%if WIN64
    movaps      [rsp+32*48], xm14
%endif
    vpbroadcastd        m14, [o(pw_181x128)]
    add                 cfq, 32*4
    mov                 r3d, 136<<16
    call .pass1_dct_main
    call .pass1_dct_main2
    sub                eobd, 136<<16
    jl .pass1_end
    add                 cfq, 32
    mov                 r3d, 172<<16
    call .pass1_dct_main
    call .pass1_dct_main2
    sub                 cfq, 32
    mov                 r3d, 64*24+32
    call m(inv_txfm_add_32x32_8bpc).transpose
.pass1_end:
    mov                 r3d, 64*24
    call m(inv_txfm_add_32x32_8bpc).transpose
    add                 cfq, 64*16
    call .pass2_dct_main
    sub                 cfq, 64*16
    call .pass2_dct_main
    pxor                m10, m10
    mov                 r6d, 64*14
    call .write_64x16
    mov                 r6d, 64*14+32
    call .write_64x16
.end:
%if WIN64
    movaps             xm14, [rsp+32*48]
%endif
.end2:
    mov                  r6, -64*32
    call m(inv_txfm_add_16x16_8bpc).zero_cf
    RET
.dconly:
    movd                xm5, [o(pw_181x128)]
    pmulhrsw            xm5, [cfq]
    movd                xm4, [o(pw_512)]
    or                  r4d, 32
    pmulhrsw            xm5, xm4
    jmp m(inv_txfm_add_64x4_8bpc).dconly3
ALIGN function_align
.write_64x16:
    mova                 m0, [cfq+r6-64* 1]
    mova                 m4, [cfq+r6+64*15]
    mova                 m1, [cfq+r6-64* 2]
    mova                 m5, [cfq+r6+64*14]
    call m(inv_txfm_add_64x4_8bpc).write_64x2
    sub                 r6d, 64*2
    jge .write_64x16
    ret
ALIGN function_align
.pass1_dct_main:
    pmulhrsw             m0, m14, [cfq-64* 1] ;  1
    pmulhrsw             m5, m14, [cfq+64* 1] ;  3
    pmulhrsw             m1, m14, [cfq+64* 3] ;  5
    pmulhrsw             m2, m14, [cfq+64* 5] ;  7
    pmulhrsw             m4, m14, [cfq+64* 7] ;  9
    pmulhrsw             m7, m14, [cfq+64* 9] ; 11
    pmulhrsw             m3, m14, [cfq+64*11] ; 13
    pmulhrsw             m6, m14, [cfq+64*13] ; 15
    call m(inv_txfm_add_32x32_8bpc).dct32_load_lowhalf2
    cmp                eobd, r3d
    jl .pass1_dct_main_fast
    pmulhrsw             m7, m14, [cfq+64*15] ; 17
    pmulhrsw             m4, m14, [cfq+64*17] ; 19
    pmulhrsw            m10, m14, [cfq+64*19] ; 21
    pmulhrsw            m11, m14, [cfq+64*21] ; 23
    pmulhrsw             m5, m14, [cfq+64*23] ; 25
    pmulhrsw             m1, m14, [cfq+64*25] ; 27
    pmulhrsw            m12, m14, [cfq+64*27] ; 29
    pmulhrsw             m0, m14, [cfq+64*29] ; 31
    punpcklwd            m6, m10, m7 ; 21 17
    punpckhwd           m10, m7
    punpcklwd            m7, m11, m4 ; 23 19
    punpckhwd           m11, m4
    punpcklwd            m4, m12, m5 ; 29 25
    punpckhwd           m12, m5
    punpcklwd            m5, m0, m1  ; 31 27
    punpckhwd            m0, m1
    mova        [cfq+64* 7], m10
    mova        [cfq+64* 9], m11
    mova        [cfq+64*11], m12
    mova        [cfq+64*13], m0
    call m(inv_txfm_add_8x32_8bpc).dct32
    mova                 m8, [cfq-64* 1]
    mova                 m9, [cfq+64* 1]
    mova                 m2, [cfq+64* 3]
    mova                 m3, [cfq+64* 5]
    mova                 m6, [cfq+64* 7]
    mova                 m7, [cfq+64* 9]
    mova                 m4, [cfq+64*11]
    mova                 m5, [cfq+64*13]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32
    pmulhrsw             m1, m14, [cfq+64* 0] ;  2
    pmulhrsw             m3, m14, [cfq+64* 4] ;  6
    pmulhrsw             m5, m14, [cfq+64* 8] ; 10
    pmulhrsw             m7, m14, [cfq+64*12] ; 14
    pmulhrsw             m8, m14, [cfq+64*16] ; 18
    pmulhrsw             m9, m14, [cfq+64*20] ; 22
    pmulhrsw            m10, m14, [cfq+64*24] ; 26
    pmulhrsw            m11, m14, [cfq+64*28] ; 30
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16
    pmulhrsw             m1, m14, [cfq+64* 2] ;  4
    pmulhrsw             m3, m14, [cfq+64*10] ; 12
    pmulhrsw             m5, m14, [cfq+64*18] ; 20
    pmulhrsw             m7, m14, [cfq+64*26] ; 28
    call m(inv_txfm_add_16x8_8bpc).dct8
    mova        [cfq+64* 5], m0
    mova        [cfq+64* 4], m1
    mova        [cfq+64* 3], m2
    mova        [cfq+64* 2], m3
    mova        [cfq+64*13], m4
    mova        [cfq+64*12], m5
    mova        [cfq+64*11], m6
    mova        [cfq+64*10], m7
    pmulhrsw             m0, m14, [cfq-64* 2] ;  0
    pmulhrsw             m1, m14, [cfq+64* 6] ;  8
    pmulhrsw             m2, m14, [cfq+64*14] ; 16
    pmulhrsw             m3, m14, [cfq+64*22] ; 24
    vpbroadcastd        m10, [o(pd_32)]
    jmp m(inv_txfm_add_16x4_8bpc).dct4
.pass1_dct_main_fast:
    vpbroadcastd        m10, [o(pd_32)]
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    mova                 m8, [cfq-64* 1]
    mova                 m9, [cfq+64* 1]
    mova                 m2, [cfq+64* 3]
    mova                 m3, [cfq+64* 5]
    add                  r7, 32*16
    call m(inv_txfm_add_8x32_8bpc).dct32_fast
    pmulhrsw             m0, m14, [cfq-64* 2] ;  0
    pmulhrsw             m1, m14, [cfq+64* 0] ;  2
    pmulhrsw             m2, m14, [cfq+64* 2] ;  4
    pmulhrsw             m3, m14, [cfq+64* 4] ;  6
    pmulhrsw             m4, m14, [cfq+64* 6] ;  8
    pmulhrsw             m5, m14, [cfq+64* 8] ; 10
    pmulhrsw             m6, m14, [cfq+64*10] ; 12
    pmulhrsw             m7, m14, [cfq+64*12] ; 14
    sub                  r7, 32*32
    call m(inv_txfm_add_16x16_8bpc).dct16_fast
    mova        [cfq+64* 5], m1
    mova        [cfq+64* 4], m2
    mova        [cfq+64* 3], m3
    mova        [cfq+64* 2], m8
    mova        [cfq+64*13], m5
    mova        [cfq+64*12], m6
    mova        [cfq+64*11], m7
    mova        [cfq+64*10], m9
    jmp m(inv_txfm_add_16x16_8bpc).dct4_fast
.pass1_dct_main2:
    mova        [cfq-64* 2], m0
    mova        [cfq-64* 1], m1
    mova        [cfq+64* 0], m2
    mova        [cfq+64* 1], m3
    mova        [cfq+64* 6], m4
    mova        [cfq+64* 7], m5
    mova        [cfq+64* 8], m6
    mova        [cfq+64* 9], m7
    lea                  r5, [r7+32*2]
    mov                  r3, cfq
    add                 cfq, 64*2
    call .pass1_dct_main2_end
    mov                  r5, r7
    add                  r7, 32*2
    mov                 cfq, r3
    add                  r3, 64*2
.pass1_dct_main2_end:
    mova                 m0, [cfq-64* 2] ; dct4  a0
    mova                 m1, [cfq+64* 6]
    mova                 m2, [r3 +64* 3] ; dct8  b0
    mova                 m3, [r3 +64*11]
    mova                 m4, [r5 -32* 4] ; dct16 c0
    mova                 m5, [r5 +32* 4]
    mova                 m6, [r5 +32*12] ; dct32 d0
    mova                 m7, [r5 +32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [r5 +32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [r5 +32*36]
    mova         [cfq-16*  8], xm0
    vextracti128 [cfq+16* 24], m0, 1
    mova         [r3 +16* 77], xm5
    vextracti128 [r3 +16*109], m5, 1
    mova                 m0, [r5 +32* 0] ; dct16 c7
    mova                 m5, [r5 +32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r7 +32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r7 +32*33]
    mova         [r3 +16* 13], xm3
    vextracti128 [r3 +16* 45], m3, 1
    mova         [cfq+16* 56], xm7
    vextracti128 [cfq+16* 88], m7, 1
    mova                 m3, [r7 +32*25] ; dct32 d8
    mova                 m7, [r7 +32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova         [r3 +16* 12], xm6
    vextracti128 [r3 +16* 44], m6, 1
    mova         [cfq+16* 57], xm5
    vextracti128 [cfq+16* 89], m5, 1
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova         [cfq-16*  7], xm3
    vextracti128 [cfq+16* 25], m3, 1
    mova         [r3 +16* 76], xm1
    vextracti128 [r3 +16*108], m1, 1
    mova                 m0, [cfq-64* 1] ; dct4  a1
    mova                 m1, [cfq+64* 7]
    mova                 m2, [r3 +64* 2] ; dct8  b1
    mova                 m3, [r3 +64*10]
    mova                 m4, [r5 -32* 3] ; dct16 c1
    mova                 m5, [r5 +32* 5]
    mova                 m6, [r5 +32*13] ; dct32 d1
    mova                 m7, [r5 +32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX       {psrad x, 6}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [r5 +32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [r5 +32*37]
    mova         [cfq-16*  4], xm0
    vextracti128 [cfq+16* 28], m0, 1
    mova         [r3 +16* 73], xm5
    vextracti128 [r3 +16*105], m5, 1
    mova                 m0, [r5 +32* 1] ; dct16 c6
    mova                 m5, [r5 +32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX       {psrad x, 6}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r7 +32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r7 +32*40]
    mova         [r3 +16*  9], xm3
    vextracti128 [r3 +16* 41], m3, 1
    mova         [cfq+16* 60], xm7
    vextracti128 [cfq+16* 92], m7, 1
    mova                 m3, [r7 +32*16] ; dct32 d6
    mova                 m7, [r7 +32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX       {psrad x, 6}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova         [cfq-16*  3], xm6
    vextracti128 [cfq+16* 29], m6, 1
    mova         [r3 +16* 72], xm5
    vextracti128 [r3 +16*104], m5, 1
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX       {psrad x, 6}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova         [r3 +16*  8], xm3
    vextracti128 [r3 +16* 40], m3, 1
    mova         [cfq+16* 61], xm1
    vextracti128 [cfq+16* 93], m1, 1
    ret
ALIGN function_align
.pass2_dct_main:
    call m(inv_txfm_add_32x32_8bpc).dct32_load_lowhalf
    test               eobd, eobd
    jl .pass2_dct_fast
    call m(inv_txfm_add_32x32_8bpc).pass2_dct_main2
    vpbroadcastd        m10, [o(pd_2048)]
    call m(inv_txfm_add_16x4_8bpc).dct4
    jmp .pass2_dct2
.pass2_dct_fast:
    vpbroadcastd        m10, [o(pd_2048)]
    call m(inv_txfm_add_32x32_8bpc).dct_main_fast
.pass2_dct2:
    mova        [cfq-32* 4], m0
    mova        [cfq-32* 2], m1
    mova        [cfq+32* 0], m2
    mova        [cfq+32* 2], m3
    mova        [cfq+32*12], m4
    mova        [cfq+32*14], m5
    mova        [cfq+32*16], m6
    mova        [cfq+32*18], m7
    mov                  r3, cfq
    add                 cfq, 64*2
    lea                  r5, [r7+32*2]
    call .pass2_dct_main_end
    mov                 cfq, r3
    add                  r3, 64*2
    mov                  r5, r7
    add                  r7, 32*2
.pass2_dct_main_end:
    mova                 m0, [cfq-32* 4] ; dct4  a0
    mova                 m1, [cfq+32*12]
    mova                 m2, [r3 +32* 6] ; dct8  b0
    mova                 m3, [r3 +32*22]
    mova                 m4, [r5 -32* 4] ; dct16 c0
    mova                 m5, [r5 +32* 4]
    mova                 m6, [r5 +32*12] ; dct32 d0
    mova                 m7, [r5 +32*28]
    psubd                m8, m0, m2  ; dct16 a7
    paddd                m0, m2      ; dct16 a0
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a15
    paddd                m0, m4      ; dct32 a0
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out31a
    paddd                m0, m6      ; out0a
    psubd                m6, m1, m7  ; out31b
    paddd                m1, m7      ; out0b
    REPX      {psrad x, 12}, m0, m1, m5, m6
    packssdw             m0, m1      ; out0
    mova                 m1, [r5 +32*20] ; dct32 d15
    packssdw             m5, m6      ; out31
    mova                 m6, [r5 +32*36]
    mova        [r3 +32*22], m0
    mova        [cfq-32* 3], m5
    mova                 m0, [r5 +32* 0] ; dct16 c7
    mova                 m5, [r5 +32* 8]
    paddd                m7, m3, m1  ; out16a
    psubd                m3, m1      ; out15a
    paddd                m1, m4, m6  ; out16b
    psubd                m4, m6      ; out15b
    REPX      {psrad x, 12}, m3, m4, m7, m1
    packssdw             m3, m4      ; out15
    mova                 m4, [r7 +32*17] ; dct32 d7
    packssdw             m7, m1      ; out16
    mova                 m1, [r7 +32*33]
    mova        [cfq-32* 4], m3
    mova        [r3 +32*23], m7
    mova                 m3, [r7 +32*25] ; dct32 d8
    mova                 m7, [r7 +32*41]
    psubd                m6, m8, m0  ; dct32 a7
    paddd                m8, m0      ; dct32 a8
    psubd                m0, m2, m5
    paddd                m2, m5
    psubd                m5, m6, m4  ; out24a
    paddd                m6, m4      ; out7a
    psubd                m4, m0, m1  ; out24b
    paddd                m0, m1      ; out7b
    REPX      {psrad x, 12}, m6, m0, m5, m4
    packssdw             m6, m0      ; out7
    packssdw             m5, m4      ; out24
    mova        [cfq+32*12], m6
    mova        [r3 +32* 7], m5
    psubd                m1, m8, m3  ; out23a
    paddd                m3, m8      ; out8a
    psubd                m6, m2, m7  ; out23b
    paddd                m2, m7      ; out8b
    REPX      {psrad x, 12}, m3, m2, m1, m6
    packssdw             m3, m2      ; out8
    packssdw             m1, m6      ; out23
    mova        [r3 +32* 6], m3
    mova        [cfq+32*13], m1
    mova                 m0, [cfq-32* 2] ; dct4  a1
    mova                 m1, [cfq+32*14]
    mova                 m2, [r3 +32* 4] ; dct8  b1
    mova                 m3, [r3 +32*20]
    mova                 m4, [r5 -32* 3] ; dct16 c1
    mova                 m5, [r5 +32* 5]
    mova                 m6, [r5 +32*13] ; dct32 d1
    mova                 m7, [r5 +32*29]
    psubd                m8, m0, m2  ; dct16 a6
    paddd                m0, m2      ; dct16 a1
    psubd                m2, m1, m3
    paddd                m1, m3
    psubd                m3, m0, m4  ; dct32 a14
    paddd                m0, m4      ; dct32 a1
    psubd                m4, m1, m5
    paddd                m1, m5
    psubd                m5, m0, m6  ; out30a
    paddd                m0, m6      ; out1a
    psubd                m6, m1, m7  ; out30b
    paddd                m1, m7      ; out1b
    REPX      {psrad x, 12}, m0, m1, m5, m6
    packssdw             m0, m1      ; out1
    mova                 m1, [r5 +32*21] ; dct32 d14
    packssdw             m5, m6      ; out30
    mova                 m6, [r5 +32*37]
    mova        [r3 +32*20], m0
    mova        [cfq-32* 1], m5
    mova                 m0, [r5 +32* 1] ; dct16 c6
    mova                 m5, [r5 +32* 9]
    psubd                m7, m3, m1  ; out17a
    paddd                m3, m1      ; out14a
    psubd                m1, m4, m6  ; out17b
    paddd                m4, m6      ; out14b
    REPX      {psrad x, 12}, m3, m4, m7, m1
    packssdw             m3, m4      ; out14
    mova                 m4, [r7 +32*24] ; dct32 d9
    packssdw             m7, m1      ; out17
    mova                 m1, [r7 +32*40]
    mova        [cfq-32* 2], m3
    mova        [r3 +32*21], m7
    mova                 m3, [r7 +32*16] ; dct32 d6
    mova                 m7, [r7 +32*32]
    psubd                m6, m8, m0  ; dct32 a9
    paddd                m8, m0      ; dct32 a6
    psubd                m0, m2, m5
    paddd                m2, m5
    paddd                m5, m6, m4  ; out22a
    psubd                m6, m4      ; out9a
    paddd                m4, m0, m1  ; out22b
    psubd                m0, m1      ; out9b
    REPX      {psrad x, 12}, m6, m0, m5, m4
    packssdw             m6, m0      ; out9
    packssdw             m5, m4      ; out22
    mova        [r3 +32* 4], m6
    mova        [cfq+32*15], m5
    psubd                m1, m8, m3  ; out25a
    paddd                m3, m8      ; out6a
    psubd                m6, m2, m7  ; out25b
    paddd                m2, m7      ; out6b
    REPX      {psrad x, 12}, m3, m2, m1, m6
    packssdw             m3, m2      ; out6
    packssdw             m1, m6      ; out25
    mova        [cfq+32*14], m3
    mova        [r3 +32* 5], m1
    ret

cglobal inv_txfm_add_64x64_8bpc, 4, 7, 0, dst, ds, cf, tx1, eob, tx2
    movifnidn          eobd, eobm
    lea                  r6, [o_base]
    shl                eobd, 16
    jz .dconly
    PROLOGUE              0, 8, 14, 32*48
    add                 cfq, 32*4
    mov                 r3d, 136<<16
    call m(inv_txfm_add_32x32_8bpc).pass1_dct_main
    call m(inv_txfm_add_64x32_8bpc).pass1_dct_main2
    sub                eobd, 136<<16
    jl .pass1_end
    add                 cfq, 32
    mov                 r3d, 172<<16
    call m(inv_txfm_add_32x32_8bpc).pass1_dct_main
    call m(inv_txfm_add_64x32_8bpc).pass1_dct_main2
    sub                 cfq, 32
    mov                 r3d, 64*24+32
    call m(inv_txfm_add_32x32_8bpc).transpose
.pass1_end:
    mov                 r3d, 64*24
    call m(inv_txfm_add_32x32_8bpc).transpose
    add                 cfq, 64*16
    call m(inv_txfm_add_32x32_8bpc).pass2_dct_main
    sub                 cfq, 64*16
    call m(inv_txfm_add_32x32_8bpc).pass2_dct_main
    pxor                 m8, m8
    mov                 r6d, 64*15
    call .write_64x32
    mov                 r6d, 64*15+32
    call .write_64x32
    jmp m(inv_txfm_add_64x32_8bpc).end2
.dconly:
    or                  r4d, 64
    jmp m(inv_txfm_add_64x4_8bpc).dconly2
ALIGN function_align
.write_64x32:
    mova                 m2, [dstq+dsq*0+32*0]
    mova                 m3, [dstq+dsq*0+32*1]
    mova                 m6, [cfq+r6-64* 2]
    mova                 m7, [cfq+r6+64*14]
    punpcklbw            m0, m2, m8
    punpckhbw            m2, m8
    punpcklbw            m1, m3, m8
    punpckhbw            m3, m8
    punpcklwd            m4, m6, m6
    punpckhwd            m6, m6
    paddw                m0, m4
    paddw                m2, m6
    punpcklwd            m5, m7, m7
    punpckhwd            m7, m7
    paddw                m1, m5
    paddw                m3, m7
    packuswb             m0, m2
    packuswb             m1, m3
    mova                 m2, [dstq+dsq*1+32*0]
    mova                 m3, [dstq+dsq*1+32*1]
    mova  [dstq+dsq*0+32*0], m0
    mova  [dstq+dsq*0+32*1], m1
    punpcklbw            m0, m2, m8
    punpckhbw            m2, m8
    paddw                m0, m4
    paddw                m2, m6
    punpcklbw            m1, m3, m8
    punpckhbw            m3, m8
    paddw                m1, m5
    paddw                m3, m7
    packuswb             m0, m2
    packuswb             m1, m3
    mova  [dstq+dsq*1+32*0], m0
    mova  [dstq+dsq*1+32*1], m1
    lea                dstq, [dstq+dsq*2]
    sub                 r6d, 64
    jge .write_64x32
    ret
