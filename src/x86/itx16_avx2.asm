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

adst4_mat:      dd  18,  50,  75,  89;  89,  75,  50,  18
flipadst4_mat:  dd  89,  75,  50,  18, -18,  50,  75, -89

pw_4096:        times 2 dw 4096
dconly_add:     dw 0x7c00, 0x7c00, 0x7000, 0x7000 ; 10bpc, 12bpc
pixel_max:      dw 0x03ff, 0x03ff, 0x0fff, 0x0fff
coef_min:       dd 0xfffe0000, 0xfff80000
coef_max:       dd 0x0001ffff, 0x0007ffff
pd_4:           dd 4
pd_17:          dd 17
pd_64:          dd 64
pd_128:         dd 128
pd_512:         dd 512

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
