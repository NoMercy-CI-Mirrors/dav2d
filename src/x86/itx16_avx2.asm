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
pd_17:          dd 17
pd_33:          dd 33
pd_64:          dd 64
pd_128:         dd 128
pd_181:         dd 181
pd_512:         dd 512
pd_1024:        dd 1024

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
ITX_JMP_TABLE  8,  4
ITX_JMP_TABLE  8,  8

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
.dct8:
    WRAP_XMM IDCT8_1D
    vinserti128          m2, m0, xm2, 1
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
