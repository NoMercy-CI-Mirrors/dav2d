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

%if ARCH_X86_64

SECTION_RODATA 16

mh_rev_words:  db 14, 15, 12, 13, 10, 11,  8,  9,  6,  7,  4,  5,  2,  3,  0,  1
mh_smpl_msk: times 32 db -1
             times 32 db 0

pd_9:       dd 9
pd_11:      dd 11

cextern div_recip
cextern div_scale_sh_coefw
cextern div_scale_sh_bias
cextern div_scale_sh_offset
cextern cfl_mh_calc_alphas_8bpc_avx2.acc_shift

SECTION .text

INIT_YMM avx2
cglobal cfl_mh_calc_alphas_16bpc, 4, 14, 15, a, src, tse, ss, refw, refh, mat, \
                                             imat, flags, n, top, bdmax
 DECLARE_REG_TMP 13, 14
    mov                 bdmaxd, r9m
    mov                  refwd, refwm
    mov                  refhd, refhm
    mov                 flagsd, flagsm
    mov                  imatq, imatmp
    mov                   matq, matmp
    push                   r14
    shr                 bdmaxd, 11
    lea                     nd, [refwq+refhq]
    lea                    r12, [mh_smpl_msk]
%define base r12-mh_smpl_msk
    movd                  xm13, [base+pd_9+bdmaxq*4]
    pxor                    m0, m0
    pxor                    m1, m1
    pxor                    m2, m2
    test                flagsb, 0x4             ; has_t
    jz .left

;.top:
    mov                     t0, ssq
    neg                     t0
    lea                   topq, [srcq+t0]
    test                flagsb, 0x10            ; is_top_sb_edge
    cmovnz                topq, tseq
    xor                    t0d, t0d
    xor                    t1d, t1d
    test                flagsb, 0x8             ; has_l
    setnz                  t0b
    setz                   t1b
    sub                     t1, t0
    lea                   topq, [topq+t1*2]
    lea                    t0d, [refwq*2]
    lea                   topq, [topq+refwq*2]
    lea                  imatq, [imatq+refwq*2]
    mov                    t1d, 32
    and                    t0d, 30
    neg                  refwq
    sub                    t1d, t0d
    xor                    t0d, t0d

.top.loop:
    cmp                  refwd, -15
    cmovae                  t0, t1
    movu                   m14, [base+mh_smpl_msk+t0]
    pand                    m3, m14, [topq+refwq*2]
    pand                    m4, m14, [imatq+  0+refwq*2]
    pand                    m5, m14, [imatq+772+refwq*2]
    REPX       {pmaddwd x, m3}, m4, m5
    paddw                   m0, m3
    paddd                   m1, m4
    paddd                   m2, m5
    add                  refwq, 16
    jl .top.loop
    vextracti128           xm3, m0, 1
    vextracti128           xm4, m1, 1
    vextracti128           xm5, m2, 1
    paddw                  xm0, xm3
    paddd                  xm1, xm4
    paddd                  xm2, xm5

 INIT_XMM avx2
 DEFINE_ARGS a, src, _, ss, _, refh, mat, imat, flags, n, _, bdmax
 DECLARE_REG_TMP 2, 4, 8, 10
    test                flagsb, 0x8             ; has_l
    jz .skip_left
.left:
    xor                    t0d, t0d
    test                flagsb, 0x4
    cmovz                   t0, ssq
    lea                    t1d, [refhq*2]
    lea                  imatq, [imatq+refhq*2]
    add                   srcq, t0
    mov                    t0d, 16
    and                    t1d, 14
    neg                  refhq
    sub                    t0d, t1d
    xor                    t1d, t1d

.left.loop:
    mov                    t2d, -8
    cmp                    t2d, refhd
    cmovb                  t2d, refhd
    lea                    t3d, [t2+8]
    movd                    m3, [srcq-2]
.left.loop.load_chroma:
    add                   srcq, ssq
    inc                    t2d
    jz .left.loop.main
    palignr                 m3, [srcq-16], 14
    jmp .left.loop.load_chroma
.left.loop.main:
    pshufb                  m3, [base+mh_rev_words+t3*2]
    cmp                  refhd, -7
    cmovae                  t1, t0
    movu                   m14, [base+mh_smpl_msk+t1]
    pand                    m4, m14, [imatq+  0+refhq*2]
    pand                    m5, m14, [imatq+772+refhq*2]
    REPX       {pmaddwd x, m3}, m4, m5
    paddw                   m0, m3
    paddd                   m1, m4
    paddd                   m2, m5
    add                  refhq, 8
    jl .left.loop

.skip_left:
    pxor                   m10, m10
    punpcklwd               m3, m0, m10
    punpckhwd               m0, m10
    paddd                   m0, m3
    pslld                   m0, m13
    lea                    t3d, [bdmaxq*4-2]
    neg                    t3d
    pop                    r14
    jmp mangle(private_prefix %+ _cfl_mh_calc_alphas_8bpc_avx2).acc_shift

%endif ; ARCH_X86_64
