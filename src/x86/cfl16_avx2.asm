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
bdmax: times 16 dw 0x3ff
       times 16 dw 0xfff

pd_9:       dd 9
pd_11:      dd 11

cextern pb_0to15
cextern pd_16
cextern pd_281

cextern div_recip
cextern div_scale_sh_coefw
cextern div_scale_sh_bias
cextern div_scale_sh_offset

cextern cfl_mh_gen_mat_8bpc_avx2.shift
cextern cfl_mh_calc_alphas_8bpc_avx2.acc_shift
cextern cfl_mh_pred_c_8bpc_avx2.prep_a0_a1

SECTION .text

INIT_YMM avx2
cglobal cfl_mh_gen_mat_16bpc, 4, 15, 0, mat, imat, y0, refw, refh, flags, bd, \
                                        ntop, n, start, y1, left, dir_off
 WIN64_SPILL_XMM 12, 15
 DECLARE_REG_TMP 10, 13
    lzcnt                  bdd, bdm
    movifnidn           flagsd, flagsm
    mov                  refhd, refhm
    mov                  refwd, refwd           ; zero upper halves
    lea                    r14, $$
%define base r14-$$
    pxor                    m7, m7
    pxor                   m11, m11
    lea                    t1d, [bdq-17]
    xor                    bdd, 31
    movd                   xm8, t1d
    movd                   xm9, bdd
    mov                  ntopd, flagsd
    and                  ntopd, 0x5
    mov                    t0d, ntopd
    shr                  ntopd, 2
    and                    t0d, ntopd
    add                  ntopd, t0d
    shl                  ntopd, 7
    lea                  leftq, [y0q+ntopq+32*32*2]
    lea                     nd, [refwq+refhq]
    xor                 startd, startd
    test                flagsb, 0x4             ; has_t
    jz .left

 DECLARE_REG_TMP 7, 13, 9, 3, 12
;.top:
    mov                    t0d, 64
    xor               dir_offd, dir_offd        ; dir_c offset
    test                flagsb, 0x2
    setnz             dir_offb                  ; dir_l offset
    test                flagsb, 0x1
    cmovnz            dir_offd, t0d             ; dir_t offset
    setnz               startb
    test                flagsb, 0x8
    setz                   t0b
    mov                    t1d, refwd
    lea                    y0q, [y0q+refwq*2]
    lea                  imatq, [imatq+refwq*2]
    and                 startd, t0d             ; !has_l && dir_t
    lea                    y0q, [y0q+startq*2]
    mov                    t2d, 16
    and                    t1d, 15
    xor                    t0d, t0d
    sub                    t2d, t1d
    lea                    y1q, [y0q+dir_offq*2]
    neg                  refwq
    mov                     t1, refwq

.top.loop:
    cmp                  refwd, -15
    cmovae                 t0d, t2d
    movu                   m10, [base+mh_smpl_msk+t0*2]
    pand                    m1, m10, [y1q+refwq*2]
    pand                    m0, m10, [y0q+refwq*2]
    call .main
    add                  refwq, 16
    jl .top.loop
    test                flagsb, 0x8             ; has_l
    jz .shift
    test                flagsb, 0x1             ; dir_t
    jz .left2
;.extra_tl:
    movzx                  t0d, word [y1q+t1*2]
    movzx                  t1d, word [leftq]
    mov                    t4d, 1
    add                  imatq, 2
    mov              [imatq-2], t0w
    mov                    t2d, t0d
    shlx                   t3d, t0d, bdd
    shlx                   t4d, t4d, bdd
    movd                   xm2, t3d
    lea                    t3d, [bdq+1]
    imul                   t1d, t1d
    imul                   t0d, t0d
    add                    t1d, t4d
    shrx                   t1d, t1d, t3d
    mov            [imatq+770], t1w
    shlx                   t4d, t1d, bdd
    imul                   t2d, t1d
    imul                   t1d, t1d
    movd                   xm0, t0d
    movd                   xm1, t2d
    movd                   xm3, t1d
    movd                   xm4, t4d
    punpckldq              xm0, xm1
    punpckldq              xm3, xm4
    punpcklqdq             xm0, xm2
    vinserti128             m0, xm3, 1
    paddd                  m11, m0
    dec                  refhd
    jmp .left.dir_t

 DEFINE_ARGS mat, imat, _, nref, refh, flags, bd, _, n, start, _, l, _
.main:
    psllw                   m3, m1, xm8
    pmulhrsw                m1, m3
.main.dir_c:
    punpcklwd               m3, m1, m7
    punpckhwd               m5, m1, m7
    punpcklwd               m2, m0, m7
    punpckhwd               m4, m0, m7
    paddd                   m3, m5
    paddd                   m2, m4
    REPX        {pslld x, xm9}, m3, m2
    movu   [imatq+  0+nrefq*2], m0
    movu   [imatq+772+nrefq*2], m1
.main.dir_l:
    pmaddwd                 m4, m0, m0
    pmaddwd                 m6, m1, m1
    pmaddwd                 m5, m0, m1
    vperm2i128              m0, m4, m6, 0x31
    vinserti128             m4, xm6, 1
    vperm2i128              m1, m5, m3, 0x31
    vinserti128             m5, xm3, 1
    vextracti128           xm6, m2, 1
    paddd                   m0, m4
    paddd                   m1, m5
    paddd                  xm2, xm6
    punpckhqdq              m4, m0, m0
    punpckhqdq              m5, m1, m1
    punpckhqdq             xm6, xm2, xm2
    paddd                   m0, m4
    paddd                   m1, m5
    paddd                  xm2, xm6
    punpckldq               m0, m1
    psrlq                  xm6, xm2, 32
    punpckhqdq              m1, m0, m0
    paddd                   m0, m1
    paddd                  xm2, xm6
    punpcklqdq              m0, m2
    paddd                  m11, m0
    ret

 DECLARE_REG_TMP 2, 7, 10, 11
.left:
    test                flagsb, 0x1
    jnz .left.dir_t
.left2:
    test                flagsd, 0x3
    jz .left.dir_c

;.left.dir_l:
    test                flagsb, 0x4             ; has_t
    setz                startb
    lea                     lq, [lq+refhq*4]
    lea                  imatq, [imatq+refhq*2]
    lea                    t1d, [refhq*2]
    lea                     lq, [lq+startq*4]
    mov                  nrefd, refhd
    neg                  nrefq
    mov                    t2d, 16
    and                    t1d, 14
    xor                    t0d, t0d
    sub                    t2d, t1d
    pcmpeqd                 m7, m7
    psrld                   m7, 16
.left.dir_l.loop:
    cmp                  nrefd, -7
    cmovae                 t0d, t2d
    movu                   m10, [base+mh_smpl_msk+t0*2]
    pand                    m0, m10, [lq+nrefq*4]
    psrld                   m1, m0, 16
    pand                    m0, m7
    psllw                   m3, m1, xm8
    pmulhrsw                m1, m3
    packusdw                m5, m0, m1
    vpermq                  m5, m5, q3120
    pslld                   m3, m1, xm9
    pslld                   m2, m0, xm9
    movu         [imatq+  0+nrefq*2], xm5
    vextracti128 [imatq+772+nrefq*2], m5, 1
    call .main.dir_l
    add                  nrefq, 8
    jl .left.dir_l.loop
    jmp .shift

.left.dir_t:
    mov                    t0d, refhd
    mov                  nrefd, refhd
    lea                     lq, [lq+refhq*2]
    lea                  imatq, [imatq+refhq*2]
    mov                    t2d, 16
    and                    t0d, 15
    xor                    t1d, t1d
    sub                    t2d, t0d
    neg                  nrefq
.left.dir_t.loop:
    cmp                  nrefq, -15
    cmovae                 t1d, t2d
    movu                   m10, [base+mh_smpl_msk+t1*2]
    pand                    m1, m10, [lq+nrefq*2+2]
    pand                    m0, m10, [lq+nrefq*2]
    call .main
    add                  nrefq, 16
    jl .left.dir_t.loop
    jmp .shift

.left.dir_c:
    mov                    t0d, refhd
    mov                  nrefd, refhd
    lea                     lq, [lq+refhq*2]
    lea                  imatq, [imatq+refhq*2]
    mov                    t2d, 16
    and                    t0d, 15
    xor                    t1d, t1d
    sub                    t2d, t0d
    neg                  nrefq
.left.dir_c.loop:
    cmp                  nrefq, -15
    cmovae                 t1d, t2d
    movu                   m10, [base+mh_smpl_msk+t1*2]
    pand                    m0, m10, [lq+nrefq*2]
    psllw                   m1, m0, xm8
    pmulhrsw                m1, m0
    call .main.dir_c
    add                  nrefq, 16
    jl .left.dir_c.loop

.shift:
 DECLARE_REG_TMP _, 2, 6, 7, 3
    lea                    t3d, [bdq*2]
    lea                    t1d, [bdq-6]
    mov                    t4d, t3d
    neg                     t3
    mov                    t2d, 1
    lea                    t3d, [t3+20]
    shlx                   t2d, t2d, t1d
    jmp mangle(private_prefix %+ _cfl_mh_gen_mat_8bpc_avx2).shift

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

INIT_YMM avx2
cglobal cfl_mh_pred_c_16bpc, 4, 13, 16, dst, ds, src, w, h, a, _, bd, a2, _
 DECLARE_REG_TMP 10, 11, 12, 6
    mov                    bdd, bdm
    movifnidn               aq, amp
    movifnidn               hd, hm
    lea                     r9, [$$]
%define base r9-$$
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).prep_a0_a1
    call .calc_a2v2
    mov                    t0d, 14
    sub                    t0d, bdd
    lea                    bdd, [bdq*8-9*8]
    movd                   xm8, a2d
    movd                  xm15, t0d
    vpbroadcastd            m9, [base+pd_281]
    vpbroadcastd           m10, [base+pd_16]
    vpbroadcastd            m8, xm8
    sub                    rsp, 32
    movu                 [rsp], m8
    cmp                     wd, 8
    je .w8
    jg .w16

.w4:
    pmovzxwd                m0, [srcq]
    mova                    m1, m0
    call .pred
    vextracti128           xm1, m0, 1
    movq          [dstq+dsq*0], xm0
    movq          [dstq+dsq*1], xm1
    add                   srcq, 16
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .w4
    jmp .ret

.w8:
    pmovzxwd                m0, [srcq]
    mova                    m1, m0
    call .pred
    vpermq                  m0, m0, q3220
    movu                [dstq], xm0
    add                   srcq, 16
    add                   dstq, dsq
    dec                     hd
    jg .w8
    jmp .ret

.w16:
    mov                     wd, wd
    mov                    t1d, wd
    lea                   dstq, [dstq+wq*2]
    neg                     wq
.w16.yloop:
    lea                   srcq, [srcq+t1*2]
    mov                     t0, wq
.w16.xloop:
    pmovzxwd                m0, [srcq+t0*2]
    mova                    m1, m0
    call .pred
    vpermq                  m0, m0, q3220
    movu           [dstq+t0*2], xm0
    add                     t0, 8
    jl .w16.xloop
    add                   dstq, dsq
    dec                     hd
    jg .w16.yloop
.ret:
    add                    rsp, 32
    RET

.pred:
    psllw                   m3, m1, xm15
    pmulhrsw                m1, m3
    cvtdq2ps                m2, m0
    cvtdq2ps                m3, m1
    REPX         {psrld x, 23}, m2, m3
    paddw                   m2, m11
    paddw                   m3, m12
    REPX       {psubusw x, m9}, m2, m3          ; drop
    psrld                   m4, m2, 1           ; ash
    psrld                   m5, m3, 1
    psubd                   m6, m2, m4          ; bsh
    psubd                   m7, m3, m5
    vpsrlvd                 m0, m6
    vpsrlvd                 m1, m7
    vpsravd                 m4, m13, m4
    vpsravd                 m5, m14, m5
    pmulld                  m0, m4
    pmulld                  m1, m5
    psubd                   m2, m10, m2          ; adj
    psubd                   m3, m10, m3
    pabsd                   m4, m0
    pabsd                   m5, m1
    psrld                   m8, m10, 4
    psubd                   m6, m2, m8
    psubd                   m7, m3, m8
    vpsllvd                 m6, m8, m6
    vpsllvd                 m7, m8, m7
    paddd                   m4, m6
    paddd                   m5, m7
    vpsrlvd                 m4, m2
    vpsrlvd                 m5, m3
    psignd                  m0, m4, m0
    psignd                  m1, m5, m1
    paddd                   m0, m1
    paddd                   m0, [rsp+gprsize]
    packusdw                m0, m0
    pminuw                  m0, [base+bdmax+bdq*2]
    ret

.calc_a2v2:
    mov                    a2d, [aq+8]
    inc                    bdd
    tzcnt                  bdd, bdd
    lea                    t1d, [32+bdq-29]
    xor                    t0d, t0d
    sub                    t0d, a2d
    cmovs                  t0d, a2d
    lzcnt                  t0d, t0d
    xor                    t2d, t2d
    sub                    t1d, t0d
    cmovb                  t1d, t2d             ; drop
    mov                    t0d, t1d
    neg                    t1d
    dec                    bdd
    shr                    t0d, 1
    lea                    t3d, [t1+bdq]
    lea                    t2d, [t1+16]         ; adj
    add                    t3d, t0d
    sarx                   a2d, a2d, t0d
    shlx                   a2d, a2d, t3d
    mov                    t1d, 1
    lea                    t0d, [t2-1]
    shlx                   t1d, t1d, t0d
    cmp                    a2d, 0
    jl .neg_a2v2
    add                    a2d, t1d
    shrx                   a2d, a2d, t2d        ; a2v2
    ret
.neg_a2v2:
    neg                    a2d
    add                    a2d, t1d
    shrx                   a2d, a2d, t2d
    neg                    a2d
    ret

cglobal cfl_mh_pred_t_16bpc, 4, 13, 16, dst, ds, src, w, h, a, flags, bd, a2, _
 DECLARE_REG_TMP 10, 11, 12
    mov                    bdd, bdm
    movifnidn               aq, amp
    movifnidn               hd, hm
    lea                     r9, [$$]
%define base r9-$$
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).prep_a0_a1
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).calc_a2v2
    mov                 flagsd, flagsm
    mov                    t0d, 14
    sub                    t0d, bdd
    lea                    bdd, [bdq*8-9*8]
    movd                   xm8, a2d
    movd                  xm15, t0d
    vpbroadcastd            m9, [base+pd_281]
    vpbroadcastd           m10, [base+pd_16]
    vpbroadcastd            m8, xm8
    sub                    rsp, 32
    movu                 [rsp], m8
    mov                     t1, -64             ; CFL_MH_TOP_STRIDE
    xor                    t2d, t2d
    test                flagsb, 0x4             ; has_t
    cmovz                   t1, t2
    setnz                  t2b
    test                flagsb, 0x8             ; has_l
    setnz                  t0b
    and                    t0d, t2d
    add                     t1, t0
    mov                    t2d, wd
    neg                     t2
    cmp                     wd, 8
    je .w8
    jg .w16

.w4:
    pmovzxwd               xm0, [srcq+t1*2]
    pmovzxwd                m1, [srcq]
    mov                     t1, t2
    vinserti128             m0, xm1, 1
    jmp .w4.loop.start
.w4.loop:
    pmovzxwd                m0, [srcq+t1*2]
    pmovzxwd                m1, [srcq]
.w4.loop.start:
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vextracti128           xm1, m0, 1
    movq          [dstq+dsq*0], xm0
    movq          [dstq+dsq*1], xm1
    add                   srcq, 16
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .w4
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.w8:
    pmovzxwd                m0, [srcq+t1*2]
    pmovzxwd                m1, [srcq]
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vpermq                  m0, m0, q3220
    movu                [dstq], xm0
    add                   srcq, 16
    add                   dstq, dsq
    mov                     t1, t2
    dec                     hd
    jg .w8
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.w16:
    mov                     wd, wd
    lea                   srcq, [srcq+wq*2]
    lea                   dstq, [dstq+wq*2]
    lea                     t2, [t2*2]
    lea                     t1, [srcq+t1*2]
.w16.yloop:
    mov                     t0, t2
.w16.xloop:
    pmovzxwd                m0, [t1+t0]
    pmovzxwd                m1, [srcq+t0]
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vpermq                  m0, m0, q3220
    movu             [dstq+t0], xm0
    add                     t0, 16
    jl .w16.xloop
    mov                     t1, srcq
    lea                   srcq, [srcq+wq*2]
    add                   dstq, dsq
    dec                     hd
    jg .w16.yloop
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

cglobal cfl_mh_pred_l_16bpc, 4, 13, 16, dst, ds, src, w, h, a, flags, bd, a2, _, l
 DECLARE_REG_TMP 11, 12
    mov                    bdd, bdm
    movifnidn               aq, amp
    movifnidn               hd, hm
    lea                     r9, [$$]
%define base r9-$$
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).prep_a0_a1
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).calc_a2v2
    mov                 flagsd, flagsm
    mov                    t0d, 14
    sub                    t0d, bdd
    lea                    bdd, [bdq*8-9*8]
    movd                   xm8, a2d
    movd                  xm15, t0d
    vpbroadcastd            m9, [base+pd_281]
    vpbroadcastd           m10, [base+pd_16]
    vpbroadcastd            m8, xm8
    sub                    rsp, 32
    movu                 [rsp], m8
    test                flagsb, 0x8
    jz .no_left
    lea                     lq, [srcq+32*32*2+2]
    cmp                     wd, 8
    je .w8
    jg .w16

.w4:
    pmovzxwd               xm2, [lq]
    punpckhqdq             xm3, xm2, xm2
    vinserti128             m2, xm3, 1
    pmovzxwd                m0, [srcq-2]
    pmovzxwd                m1, [srcq]
    vpblendd                m0, m2, 0x11
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vextracti128           xm1, m0, 1
    movq          [dstq+dsq*0], xm0
    movq          [dstq+dsq*1], xm1
    add                     lq, 8
    add                   srcq, 16
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .w4
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.w8:
    movd                   xm2, [lq]
    pmovzxwd               xm2, xm2
    pmovzxwd                m0, [srcq-2]
    pmovzxwd                m1, [srcq]
    vpblendd                m0, m2, 0x1
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vpermq                  m0, m0, q3220
    movu                [dstq], xm0
    add                     lq, 4
    add                   srcq, 16
    add                   dstq, dsq
    dec                     hd
    jg .w8
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.w16:
    mov                     wd, wd
    mov                    t1d, wd
    lea                   dstq, [dstq+wq*2]
    neg                     wq
.w16.yloop:
    lea                   srcq, [srcq+t1*2]
    mov                     t0, wq
    movd                   xm2, [lq]
    pmovzxwd               xm2, xm2
    pmovzxwd                m0, [srcq+t0*2-2]
    pmovzxwd                m1, [srcq+t0*2]
    vpblendd                m0, m2, 0x1
    jmp .w16.xloop.start
.w16.xloop:
    pmovzxwd                m0, [srcq+t0*2-2]
    pmovzxwd                m1, [srcq+t0*2]
.w16.xloop.start:
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vpermq                  m0, m0, q3220
    movu           [dstq+t0*2], xm0
    add                     t0, 8
    jl .w16.xloop
    add                     lq, 4
    add                   dstq, dsq
    dec                     hd
    jg .w16.yloop
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.no_left:
    cmp                     wd, 8
    je .no_left.w8
    jg .no_left.w16

.no_left.w4:
    vbroadcasti128          m2, [base+pb_0to15]
    pmovzxwd                m0, [srcq-2]
    pmovzxwd                m1, [srcq]
    pshufd                  m2, m2, q3211
    pshufb                  m0, m2
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vextracti128           xm1, m0, 1
    movq          [dstq+dsq*0], xm0
    movq          [dstq+dsq*1], xm1
    add                   srcq, 16
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .no_left.w4
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.no_left.w8:
    vbroadcasti128          m2, [base+pb_0to15]
    pmovzxwd                m0, [srcq-2]
    pmovzxwd                m1, [srcq]
    pshufd                 xm3, xm2, q3211
    vpblendd                m2, m3, 0x1
    pshufb                  m0, m2
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vpermq                  m0, m0, q3220
    movu                [dstq], xm0
    add                   srcq, 16
    add                   dstq, dsq
    dec                     hd
    jg .no_left.w8
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

.no_left.w16:
    mov                     wd, wd
    mov                    t1d, wd
    lea                   dstq, [dstq+wq*2]
    neg                     wq
.no_left.w16.yloop:
    vbroadcasti128          m2, [base+pb_0to15]
    lea                   srcq, [srcq+t1*2]
    mov                     t0, wq
    pmovzxwd                m0, [srcq+t0*2-2]
    pmovzxwd                m1, [srcq+t0*2]
    pshufd                 xm3, xm2, q3211
    vpblendd                m2, m3, 0x1
    pshufb                  m0, m2
    jmp .no_left.w16.xloop.start
.no_left.w16.xloop:
    pmovzxwd                m0, [srcq+t0*2-2]
    pmovzxwd                m1, [srcq+t0*2]
.no_left.w16.xloop.start:
    call mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).pred
    vpermq                  m0, m0, q3220
    movu           [dstq+t0*2], xm0
    add                     t0, 8
    jl .no_left.w16.xloop
    add                   dstq, dsq
    dec                     hd
    jg .no_left.w16.yloop
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_16bpc_avx2).ret

%endif ; ARCH_X86_64
