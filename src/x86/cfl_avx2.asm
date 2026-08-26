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

pb_0to15:      db  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
w4Llshuf:      db  0, -1,  1, -1,  3, -1,  5, -1,  8, -1,  9, -1, 11, -1, 13, -1
w8Llshuf:      db  0, -1,  1, -1,  3, -1,  5, -1,  7, -1,  9, -1, 11, -1, 13, -1
Llshuf:        db  0, -1,  2, -1,  4, -1,  6, -1,  8, -1, 10, -1, 12, -1, 14, -1
Llshuf_edgel:  db  0, -1,  1, -1,  4, -1,  5, -1,  8, -1,  9, -1, 12, -1, 13, -1
t64f0smplCshuf:db  0, -1,  1, -1,  4, -1,  5, -1,  8, -1,  9, -1, 12, -1, 13, -1
t64f1smplCshuf:db  0, -1,  8, -1,  4, -1, 12, -1,  1, -1,  9, -1,  5, -1, 13, -1
dcCshuf: times 4 db 0, -1
         times 4 db 8, -1
l_smpl_msk0: times 4 dd 0
l_smpl_msk1: dd -1, -1, -1, -1
l_smpl_msk2: dd  0, -1,  0, -1
l_smpl_msk4: dd  0,  0, -1,  0
l_smpl_msk8: dd -1,  0,  0,  0
t_smpl_msk1: dw -1, -1, -1, -1, -1, -1, -1, -1
t_smpl_msk2: dw  0, -1,  0, -1,  0, -1,  0, -1
t_smpl_msk4: dw  0,  0, -1,  0,  0,  0, -1,  0
t_smpl_msk8: dw  0,  0,  0,  0, -1,  0,  0,  0
; w64 t_smpl_msk4
; for f0-lum;    0,  0,  0,  0, -1, -1, -1, -1 ; 4 4 4 4 6 6 6 6
; for f0-chr;    0,  0, -1, -1,  0,  0, -1, -1 ; 0 0 2 2 4 4 6 6
; for f1/2  ;    0,  0,  0,  0, -1, -1, -1, -1 ; 0 4 0 4 2 6 2 6
; w64 t_smpl_msk8
; for f0    ;   -1, -1, -1, -1,  0,  0,  0,  0 ; 4 4 4 4 6 6 6 6
; for f0-chr;    0,  0,  0,  0, -1, -1,  0,  0 ; 0 0 2 2 4 4 6 6
; for f1/2  ;    0, -1,  0, -1,  0,  0,  0,  0 ; 0 4 0 4 2 6 2 6
mh_lshuf1:   db  0,  2,  4,  6
mh_lshuf2:   db  0,  1,  2,  3,  4,  5,  6,  7
mh_smpl_msk: times 32 db -1
             times 32 db 0 ; smallest possible refw/h is 2

pb_left_flt1:    db 0, 1, 2, 1
pb_left_flt2:    db 0, 1, 4, 1
pb_flt0: times 2 db 2, 2
pb_flt1: times 2 db 2, 1
pb_flt2: times 2 db 4, 1
         times 2 db 6, 1
pw_128:  times 2 dw 128
pw_1024: times 2 dw 1024
pd_18:           dd 18
pd_29:           dd 29
pd_126:          dd 126
pd_511:          dd 511

%macro JMP_TABLE 1-*
    %xdefine %1_table (%%table - 2*4)
    %xdefine %%base mangle(private_prefix %+ _%1)
    %%table:
    %rep %0 - 1
        dd %%base %+ .%2 - (%%table - 2*4)
        %rotate 1
    %endrep
%endmacro

%macro JMP_TABLE2 3-* ; fn, name, min_log2, labels
    %assign %%min_log2 %3
    %xdefine %1_%2_table (%%table - %%min_log2*4)
    %xdefine %%base mangle(private_prefix %+ _%1)
    %%table:
    %rep %0 - 3
        dd %%base %+ .%4 - (%%table - %%min_log2*4)
        %rotate 1
    %endrep
%endmacro

JMP_TABLE cfl_implicit_420_8bpc_avx2, \
    top.f0.w4,      top.f0.w8,      top.f0.w16,      top.f0.w32,       top.f0.w64,      \
    top.f1.w4,      top.f1.w8,      top.f1.w16,      top.f1.w32,       top.f1.w64,      \
    top.f2.w4,      top.f2.w8,      top.f2.w16,      top.f2.w32,       top.f2.w64,      \
    blk.f0.w4,      blk.f0.w8,      blk.f0.w16,      blk.f0.w32.prep,  blk.f0.w32.prep, \
    blk.f1.w4.prep, blk.f1.w8.prep, blk.f1.w16,      blk.f1.w32.prep0, blk.f1.w32.prep0,\
    blk.f2.w4.prep, blk.f2.w8.prep, blk.f2.w16.prep, blk.f2.w32.prep,  blk.f2.w64.prep, \
    pred_uv.w4,     pred_uv.w8,     pred_uv.w16,     pred_uv.w32,      pred_uv.w32

JMP_TABLE cfl_explicit_420_8bpc_avx2, \
    top.f0.w4,      top.f0.w8,      top.f0.w16,      top.f0.w32,       top.f0.w64,      \
    top.f1.w4,      top.f1.w8,      top.f1.w16,      top.f1.w32,       top.f1.w64,      \
    top.f2.w4,      top.f2.w8,      top.f2.w16,      top.f2.w32,       top.f2.w64,      \
    blk.f0.w4,      blk.f0.w8,      blk.f0.w16,      blk.f0.w32.prep,  blk.f0.w32.prep, \
    blk.f1.w4.prep, blk.f1.w8.prep, blk.f1.w16,      blk.f1.w32.prep0, blk.f1.w32.prep0,\
    blk.f2.w4.prep, blk.f2.w8.prep, blk.f2.w16.prep, blk.f2.w32.prep,  blk.f2.w64.prep, \
    pred_uv.w4,     pred_uv.w8,     pred_uv.w16,     pred_uv.w32,      pred_uv.w32

JMP_TABLE2 cfl_mh_gen_y_420_uniform_8bpc_avx2, top, 1, \
    top.8, top.8, top.8, top.17, top.33, top.64
JMP_TABLE2 cfl_mh_gen_y_420_uniform_8bpc_avx2, blk, 2, \
    blk.w4, blk.w8, blk.w16, blk.w32

JMP_TABLE2 cfl_mh_gen_y_420_vstrip_8bpc_avx2, top, 1, \
    top.4, top.4, top.8, top.17, top.33, top.64
JMP_TABLE2 cfl_mh_gen_y_420_vstrip_8bpc_avx2, blk, 2, \
    blk.w4, blk.w8, blk.w16, blk.w32

JMP_TABLE2 cfl_mh_gen_y_420_gauss_8bpc_avx2, top, 1, \
    top.4, top.4, top.8, top.17, top.33, top.64
JMP_TABLE2 cfl_mh_gen_y_420_gauss_8bpc_avx2, blk, 2, \
    blk.w4, blk.w8, blk.w16, blk.w32

cextern div_recip

SECTION .text

%macro F0 0 ; w*
    REPX    {pmaddubsw x, m14}, m3, m4
    paddw                   m3, m4
    jmp .pred
%endmacro

%macro F1 0 ; w4/8
    pshufb                  m5, m3, m11             ; l0
    pshufb                  m6, m4, m11             ; l1
    REPX    {pmaddubsw x, m14}, m3, m4              ; c/r 01
    paddw                   m5, m6
    paddw                   m3, m4
    paddw                   m3, m5
    jmp .pred
%endmacro

%macro F2 0 ; w4/8
    pshufb                  m5, m3, m11             ; l
    pmaddubsw               m3, m14                 ; c/r
    REPX          {pand x, m7}, m4, m6              ; t/b
    paddw                   m4, m5
    paddw                   m4, m6
    paddw                   m3, m4
    jmp .pred
%endmacro

INIT_YMM avx2
%macro CFL_420 1 ; cfl_type
cglobal cfl_%1_420_8bpc, 4, 15, 16, ptrs, strides, wpad, hpad, w, h, flags, \
                                    tbl, flt, cstride, ntop, nleft
 DECLARE_REG_TMP 7, 12, 13, 14
    movifnidn               wd, wm
    movifnidn               hd, hm
    mov                 flagsd, flagsm
    mov               cstrideq, [stridesq+8]
    mov               stridesq, [stridesq+0]
    pcmpeqd                m15, m15
%ifidn %1, explicit
    test                flagsb, 0x8             ; have_left
    jz .no_left
%else
    xor                    t2d, t2d
    mov                    t3d, 3
    xor                  ntopd, ntopd
    xor                 nleftd, nleftd
    test                flagsb, 0x4             ; has_top
    jz .implicit_prep.no_top
    mov                    t0d, wd
    test                flagsb, 0x8             ; has_left
    jz .implicit_prep.no_left
    mov                    t1d, hd
    lea                    t0d, [t0d*2]
    cmp                    t0d, t1d             ; h > w * 2
    cmovb                ntopd, t2d
    cmovb               nleftd, t3d
    jb .left
    lea                    t1d, [t1d*4]
    cmp                    t1d, t0d             ; w > h * 2
    cmovb                ntopd, t3d
    cmovb               nleftd, t2d
    jb .left
    mov                  ntopd, 2
    mov                 nleftd, 2
    jmp .left
.implicit_prep.no_top:
    xor                    t0d, t0d
    test                flagsb, 0x8             ; has_left
    jz .no_edge
    mov                 nleftd, t3d
    dec                    t3d
    cmp                     hd, 4
    cmove               nleftd, t3d
    jmp .left
.implicit_prep.no_left:
    xor                    t1d, t1d
    mov                  ntopd, t3d
    dec                    t3d
    cmp                     wd, 4
    cmove                ntopd, t3d
    jmp .no_left
%endif

.left:
%ifidn %1, implicit
    sub                    rsp, 8
    mov                [rsp+4], ntopd
    mov                [rsp+0], nleftd
%endif
 INIT_XMM avx2
    mov                   fltd, flagsd
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, step, flt, cstride, \
             row0, row1, row2, row3, row
 DECLARE_REG_TMP 12, 13, 11, 10
%ifidn %1, explicit
    mov                  row0q, [ptrsq+24]
%endif
    lea                   rowq, [ystrideq*2]
    xor                    t0d, t0d
    cmp                    h0d, 64
    sete                   t0b
    shlx                  rowq, rowq, t0
    shl                  hpadd, 2
    setnz                  t1b
    mov                     hd, h0d
%ifidn %1, explicit
    sub                     hd, hpadd
    sub                     hb, t1b
    shrx                    hd, hd, t0d
    push                    hq
%else
%define nleftd t2d
    pxor                   m11, m11
    shrx                    hd, hd, t0d
    shrx                   t3d, hpadd, t0d
    mov                    t0d, hd
    sub                     hb, t1b
    sub                     hd, t3d
    mov                  row0q, [ptrsq+24]
    xor                    t1d, t1d
    shrx                 stepd, t0d, nleftd
    test                nleftd, nleftd
    cmovz                stepd, t1d
    jz .left.skip_smpl_msk_load
    lea                     t0, [l_smpl_msk1]
    tzcnt                  t1d, stepd
    lea                    t1d, [t1*4]
    mova                   m11, [t0+t1*4]
.left.skip_smpl_msk_load:
    sub                    rsp, 0x84
    mov             [rsp+0x80], hd
%endif
    lea                  row1q, [row0q+rowq*1]
    lea                  row2q, [row0q+rowq*2]
    lea                  row3q, [rowq*3]
    add                  row3q, row0q
    and                   fltd, 0x3             ; filter_type
    cmp                   fltd, 1
    jb .left.luma.f0
    je .left.luma.f1

;.left.luma.f2:
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, step, flt, cstride, \
             ysrc, ystride3, _, _, _
    vpbroadcastd          ym14, [pb_left_flt2]
    cmp                    h0d, 64
    je .left.luma.f2.h64
    lea              ystride3q, [ystrideq*3]
    movd                    m0, [ysrcq+ystrideq*0-4]
    movd                    m1, [ysrcq+ystrideq*1-2]
    movd                    m2, [ysrcq+ystrideq*2-4]
    movd                    m3, [ysrcq+ystride3q -2]
    lea                  ysrcq, [ysrcq+ystrideq*4-4]
    movd                    m4, [ysrcq+ystrideq*0  ]
    movd                    m5, [ysrcq+ystrideq*1+2]
    movd                    m6, [ysrcq+ystrideq*2  ]
    movd                    m9, [ysrcq+ystride3q +2]
    lea                  ysrcq, [ysrcq+ystrideq*4  ]
    psrlw                  m13, m15, 8
    pblendw                 m8, m0, m1, 0x1
    punpcklwd               m1, m3
    punpcklwd               m3, m5
    punpcklwd               m5, m9
    punpckldq               m0, m2
    punpckldq               m4, m6
    punpckldq               m8, m1
    punpckldq               m3, m5
    punpcklqdq              m0, m4 ; l+c+r
    punpcklqdq              m8, m3 ; t+b
    pmaddubsw               m0, m14
    pand                    m8, m13
    paddw                   m0, m8
%ifidn %1, implicit
    cmp                  stepd, 8
    je .left.luma.f2.skip_sampling
    pand                   m10, m0, m11
%endif
    sub                     hd, 4
%ifidn %1, explicit
    jz .left.chroma
%else
    jz .left.chroma.h4
    movu            [rsp+0x70], m10
%endif
    xor                    t0d, t0d
%ifidn %1, implicit
    mov                    t1d, 4
    jmp .left.luma.f2.loop
.left.luma.f2.skip_sampling:
    sub                     hd, 4
    mov                    t1d, 2
    mov                    t0d, t1d
%endif
.left.luma.f2.loop:
    movd                    m1, [ysrcq+ystrideq*0  ]
    movd                    m2, [ysrcq+ystrideq*1+2]
    movd                    m3, [ysrcq+ystrideq*2  ]
    movd                    m4, [ysrcq+ystride3q +2]
    lea                  ysrcq, [ysrcq+ystrideq*4  ]
    movd                    m5, [ysrcq+ystrideq*0  ]
    movd                    m6, [ysrcq+ystrideq*1+2]
    movd                    m7, [ysrcq+ystrideq*2  ]
    movd                    m8, [ysrcq+ystride3q +2]
    lea                  ysrcq, [ysrcq+ystrideq*4  ]
    punpcklwd               m9, m2
    punpcklwd               m2, m4
    punpcklwd               m4, m6
    punpcklwd               m6, m8
    punpckldq               m1, m3
    punpckldq               m5, m7
    punpckldq               m9, m2
    punpckldq               m4, m6
    punpcklqdq              m1, m5
    punpcklqdq              m9, m4
    pmaddubsw               m1, m14
    pand                    m5, m9, m13
    paddw                   m1, m5
%ifidn %1, implicit
    pand                    m2, m1, m11
    sub                     t0, t1
    test                   t0d, t1d
    jnz .left.luma.f2.acc_even
%else
    xor                    t0d, 1
    jz .left.luma.f2.acc_even
%endif
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
%ifidn %1, implicit
    movu       [rsp+0x70+t0*4], m2
    jmp .left.luma.f2.acc
%endif
.left.luma.f2.acc_even:
%ifidn %1, implicit
    ; When step is 8, we only sample from odd loop iters
    cmp                  stepd, 8
    je .left.luma.f2.acc
    movu       [rsp+0x70+t0*4], m2
.left.luma.f2.acc:
%endif
    paddw                   m0, m1
    mova                    m9, m8
    sub                     hd, 4
    ja .left.luma.f2.loop
    jz .left.chroma
%ifidn %1, explicit
    test                   t0b, 1
    jz .left.luma.f2.pad_odd
%else
    sub                     t0, t1
    test                   t0d, t1d
    jz .left.luma.f2.pad_odd
%endif
    pshufd                  m1, m1, q3333
    pshuflw                 m2, m1, q2301
    pshufhw                 m2, m2, q2301
%ifidn %1, implicit
    pand                    m3, m1, m11
    cmp                  stepd, 8
    jb .left.luma.f2.pad
    sub                     t0, 2
%endif
    jmp .left.luma.f2.pad
.left.luma.f2.pad_odd:
    pshufd                  m2, m1, q3333
    pshuflw                 m1, m2, q2301
    pshufhw                 m1, m1, q2301
%ifidn %1, implicit
    pand                    m3, m2, m11
%endif
.left.luma.f2.pad:
    cmp                  hpadd, 8
%ifidn %1, implicit
    jb .left.luma.f2.pad1.hpad4
    je .left.luma.f2.pad1.hpad8
%endif
.left.luma.f2.pad1:
    paddw                   m0, m1
%ifidn %1, explicit
    jb .left.chroma
%else
    movu       [rsp+0x70+t0*4], m3
    sub                     t0, 4
.left.luma.f2.pad1.hpad8:
%endif
    paddw                   m0, m2
%ifidn %1, explicit
    je .left.chroma
%else
    cmp                  stepd, 8
    je .left.luma.f2.pad1.hpad4
    movu       [rsp+0x70+t0*4], m3
    sub                     t0, 4
.left.luma.f2.pad1.hpad4:
%endif
    paddw                   m0, m1
%ifidn %1, implicit
    movu       [rsp+0x70+t0*4], m3
%endif
    jmp .left.chroma
.left.luma.f2.h64:
%ifidn %1, explicit
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, ystride3, flt, cstride, \
             row0, row1, row2, row3, row
    push                   h0q
%else
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, step, ystride3, cstride, \
             row0, row1, row2, row3, row
    sub                    rsp, 8
    mov                [rsp+0], wpadd
    mov                [rsp+4], h0d
%endif
 DECLARE_REG_TMP 5, 2
    lea              ystride3q, [ystrideq*3]
    psrlw                  m13, m15, 8
%ifidn %1, implicit
    SWAP                   m15, m11
%endif
    movd                    m0, [row0q+ystrideq*0-4]
    movd                    m1, [row0q+ystrideq*1-2]
    movd                   m10, [row0q+ystride3q -2] ; top1
    movd                    m3, [row1q+ystrideq*1-2]
    movd                   m11, [row1q+ystride3q -2] ; top2
    movd                    m5, [row2q+ystrideq*1-2]
    movd                   m12, [row2q+ystride3q -2] ; top3
    movd                    m7, [row3q+ystrideq*1-2]
    movd                    m2, [row1q+ystrideq*0-4]
    movd                    m4, [row2q+ystrideq*0-4]
    movd                    m6, [row3q+ystrideq*0-4]
    pblendw                 m8, m0, m1, 0x1 ; t0/b0
    punpcklwd              m10, m3          ; t1/b1
    punpcklwd              m11, m5          ; t2/b2
    punpcklwd              m12, m7          ; t3/b3
    punpckldq               m0, m2
    punpckldq               m4, m6
    punpckldq               m8, m10
    punpckldq              m11, m12
    punpcklqdq              m0, m4          ; l/c/r
    punpcklqdq              m8, m11         ; t/b
    pmaddubsw               m0, m14
    pand                    m8, m13
    paddw                   m0, m8
%ifidn %1, explicit
    xor                    t0d, t0d
%else
    cmp                  stepd, 8
    je .left.luma.f2.h64.skip_sampling
    pand                    m1, m0, m15
    movu            [rsp+0x78], m1
    mov                    t1d, 4
    xor                    t0d, t0d
    jmp .left.luma.f2.h64.sampling_done
.left.luma.f2.h64.skip_sampling:
    mov                    t1d, 2
    mov                    t0d, t1d
.left.luma.f2.h64.sampling_done:
%endif
    sub                     hd, 4
.left.luma.f2.h64.loop:
    movd                    m2, [row3q+ystride3q -2]
    lea                  row0q, [row0q+rowq*4]
    lea                  row1q, [row1q+rowq*4]
    lea                  row2q, [row2q+rowq*4]
    lea                  row3q, [row3q+rowq*4]
    movd                    m9, [row0q+ystrideq*1-2]
    movd                    m4, [row0q+ystride3q -2]
    movd                   m10, [row1q+ystrideq*1-2]
    movd                    m1, [row0q+ystrideq*0-4]
    movd                    m3, [row1q+ystrideq*0-4]
    sub                     hd, 2
    jb .left.luma.f2.h64.pad_half
    movd                    m6, [row1q+ystride3q -2]
    movd                   m11, [row2q+ystrideq*1-2]
    movd                    m8, [row2q+ystride3q -2]
    movd                   m12, [row3q+ystrideq*1-2]
    movd                    m5, [row2q+ystrideq*0-4]
    movd                    m7, [row3q+ystrideq*0-4]
    punpcklwd               m2, m9
    punpcklwd               m4, m10
    punpcklwd               m6, m11
    punpcklwd               m8, m12
    punpckldq               m1, m3
    punpckldq               m5, m7
    punpckldq               m2, m4
    punpckldq               m6, m8
    punpcklqdq              m1, m5
    punpcklqdq              m2, m6
    pmaddubsw               m1, m14
    pand                    m2, m13
    paddw                   m1, m2
%ifidn %1, implicit
    pand                    m2, m1, m15
    sub                     t0, t1
    test                   t0d, t1d
    jnz .left.luma.f2.h64.loop.acc_even
%else
    xor                    t0d, 1
    jz .left.luma.f2.h64.loop.acc_even
%endif
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
%ifidn %1, implicit
    movu       [rsp+0x78+t0*4], m2
    jmp .left.luma.f2.h64.loop.acc
%endif
.left.luma.f2.h64.loop.acc_even:
%ifidn %1, implicit
    cmp                  stepd, 8
    je .left.luma.f2.h64.loop.acc
    movu       [rsp+0x78+t0*4], m2
.left.luma.f2.h64.loop.acc:
%endif
    paddw                   m0, m1
    sub                     hd, 2
    ja .left.luma.f2.h64.loop
%ifidn %1, implicit
    mov                    r12, t0
    mov                    t3d, 4
    test                   t0d, 2       ; step=4 or step=8 and even loop iter
    cmovz                  t1d, t3d
    sub                    r12, t1
    mov                    h0d, [rsp+4]
    mov                  wpadd, [rsp]
    add                    rsp, 8
    SWAP                   m11, m15
    pcmpeqd                m15, m15
    test                    hd, hd
%else
    pop                    h0q
%endif
    jz .left.chroma
    movd                    m1, [row3q+ystrideq*2-4]
    movd                    m2, [row3q+ystride3q -2]
    pmaddubsw               m1, m14
    punpcklwd               m2, m12
    pand                    m2, m13
    paddw                   m1, m2
    pshufd                  m2, m1, q0000
%ifidn %1, implicit
    pand                    m3, m2, m11
%endif
    pshuflw                 m1, m2, q2301
    pshufhw                 m1, m1, q2301
    cmp                  hpadd, 16
%ifidn %1, implicit
    jb .left.luma.f2.pad1.hpad4
    je .left.luma.f2.pad1.hpad8
%endif
    jmp .left.luma.f2.pad1
.left.luma.f2.h64.pad_half:
    movd                    m6, [row1q+ystride3q -2]
    movd                    m5, [row1q+ystrideq*2-4]
    punpcklwd               m2, m9  ; b0/t0
    punpcklwd               m4, m10 ; b1/t1
    punpcklwd               m6, m10 ; b23/t23
    punpckldq               m1, m3
    punpckldq               m5, m5
    punpckldq               m2, m4
    punpckldq               m6, m6
    punpcklqdq              m1, m5
    punpcklqdq              m2, m6
    pmaddubsw               m1, m14
    pand                    m2, m13
    paddw                   m1, m2
%ifidn %1, implicit
    pand                    m3, m1, m11
    sub                     t0, t1
    test                   t0d, t1d
%else
    test                   t0b, 1
%endif
    jnz .left.luma.f2.h64.pad_half.even
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
%ifidn %1, implicit
    mov                    t2d, t0d
    movu       [rsp+0x78+t0*4], m3
    sub                     t0, 4
    test                   t2d, t1d
%endif
.left.luma.f2.h64.pad_half.even:
    paddw                   m0, m1
    jz .left.luma.f2.h64.pad_half.end
    mova                    m2, m1
    pshufhw                 m1, m1, q2301
%ifidn %1, implicit
    cmp                  stepd, 8
    je .left.luma.f2.h64.pad_half.even.skip_sampling
    movu       [rsp+0x78+t0*4], m3
    sub                     t0, 4
%endif
    jmp .left.luma.f2.h64.pad_half.end
.left.luma.f2.h64.pad_half.even.skip_sampling:
    sub                     t0, 2
    jmp .left.luma.f2.h64.pad_half.end
.left.luma.f2.h64.pad_half.end:
    pshufhw                 m2, m1, q2301
%ifidn %1, implicit
    mov                    r12, t0
    mov                    r13, t1
    mov                    h0d, [rsp+4]
    mov                  wpadd, [rsp]
    add                    rsp, 8
    pcmpeqd                m15, m15
%else
    pop                    h0q
%endif
    cmp                  hpadd, 4
    je .left.chroma
    punpckhqdq              m1, m1 ;  odd iter: shuffled
    punpckhqdq              m2, m2 ; even iter: original
%ifidn %1, implicit
    pand                    m3, m1, m11
%endif
    cmp                  hpadd, 20
%ifidn %1, implicit
    jb .left.luma.f2.pad1.hpad4
    je .left.luma.f2.pad1.hpad8
%endif
    jmp .left.luma.f2.pad1

.left.luma.f1:
    vpbroadcastd          ym14, [pb_left_flt1]
    movd                    m0, [row0q+ystrideq*0-4]
    movd                    m1, [row1q+ystrideq*0-4]
    movd                    m2, [row2q+ystrideq*0-4]
    movd                    m3, [row3q+ystrideq*0-4]
    movd                    m4, [row0q+ystrideq*1-4]
    movd                    m5, [row1q+ystrideq*1-4]
    movd                    m6, [row2q+ystrideq*1-4]
    movd                    m7, [row3q+ystrideq*1-4]
    punpckldq               m0, m1
    punpckldq               m2, m3
    punpckldq               m4, m5
    punpckldq               m6, m7
    punpcklqdq              m0, m2
    punpcklqdq              m4, m6
    REPX    {pmaddubsw x, m14}, m0, m4
    ; todo might be a better way, alt them every odd loop iter (as f2 does)
    ; so instead of 3+1 and 1+3 do 6+2 and 2+6
    pshuflw                 m0, m0, q2301
    pshufhw                 m0, m0, q2301
    paddw                   m0, m4
%ifidn %1, implicit
    cmp                  stepd, 8
    je .left.luma.f1.skip_sampling
    pand                   m10, m0, m11
%endif
    sub                     hd, 4
%ifidn %1, explicit
    jz .left.chroma
%else
    jz .left.chroma.h4
    movu            [rsp+0x70], m10
    sub                    rsp, 8
    mov                [rsp+0], wpadd
    mov                [rsp+4], h0d
    mov                    t1d, 4
    xor                    t0d, t0d
    jmp .left.luma.f1.loop
.left.luma.f1.skip_sampling:
    sub                    rsp, 8
    sub                     hd, 4
    mov                [rsp+0], wpadd
    mov                [rsp+4], h0d
    mov                    t1d, 2
    mov                    t0d, t1d
%endif
.left.luma.f1.loop:
    lea                  row0q, [row0q+rowq*4]
    lea                  row1q, [row1q+rowq*4]
    lea                  row2q, [row2q+rowq*4]
    lea                  row3q, [row3q+rowq*4]
    movd                    m1, [row0q+ystrideq*0-4]
    movd                    m2, [row1q+ystrideq*0-4]
    movd                    m3, [row0q+ystrideq*1-4]
    movd                    m4, [row1q+ystrideq*1-4]
    sub                     hd, 2
    jb .left.luma.f1.pad64_half
    movd                    m5, [row2q+ystrideq*0-4]
    movd                    m6, [row3q+ystrideq*0-4]
    movd                    m7, [row2q+ystrideq*1-4]
    movd                    m8, [row3q+ystrideq*1-4]
    punpckldq               m1, m2
    punpckldq               m3, m4
    punpckldq               m5, m6
    punpckldq               m7, m8
    punpcklqdq              m1, m5
    punpcklqdq              m3, m7
    REPX    {pmaddubsw x, m14}, m1, m3
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
    paddw                   m1, m3
    paddw                   m0, m1
%ifidn %1, implicit
    sub                     t0, t1
    test                   t0d, 2
    jnz .left.luma.f1.loop.skip_sampling
    pand                    m2, m1, m11
    movu       [rsp+0x78+t0*4], m2
.left.luma.f1.loop.skip_sampling:
%endif
    sub                     hd, 2
    ja .left.luma.f1.loop
%ifidn %1, explicit
    jz .left.chroma
    cmp                    h0d, 64
%else
    jz .left.chroma.reload
    cmp          dword [rsp+4], 64
%endif
    je .left.luma.f1.pad64
    pshufd                  m1, m1, q3333
%ifidn %1, implicit
    pand                    m2, m1, m11
    sub                     t0, t1
    xor                    t2d, t2d
    test                   t0d, 2
    cmovz                   t1, t2
    sub                     t0, t1
%endif
    cmp                  hpadd, 8
    jmp .left.luma.pad
.left.luma.f1.pad64:
    lea                     t2, [ystrideq*3]
    movd                    m1, [row3q+ystrideq*2-4]
    movd                    m2, [row3q+t2-4]
    shufps                  m1, m2, q0000
    pmaddubsw               m1, m14
    pshuflw                 m2, m1, q2301
    pshufhw                 m2, m2, q2301
%ifidn %1, implicit
    pshufd                  m1, m1, q1032
%endif
    paddw                   m1, m2
%ifidn %1, implicit
    pand                    m2, m1, m11
    mov                    t3d, 4
    test                   t0d, 2
    cmovz                  t1d, t3d
    sub                     t0, t1
%endif
    cmp                  hpadd, 16
    jmp .left.luma.pad
.left.luma.f1.pad64_half:
    lea                     t3, [ystrideq*3]
    movd                    m5, [row1q+ystrideq*2-4]
    movd                    m6, [row1q+t3-4]
    punpckldq               m1, m2
    punpckldq               m3, m4
%ifidn %1, explicit
    shufps                  m5, m6, q0000
    punpcklqdq              m1, m3
    REPX    {pmaddubsw x, m14}, m1, m5
    pshuflw                 m6, m5, q2301
    pshufhw                 m6, m6, q2301
    pshufd                  m5, m5, q1032
    REPX         {paddw m0, x}, m1, m6
%else
    punpckldq               m5, m5
    punpckldq               m6, m6
    punpcklqdq              m1, m5
    punpcklqdq              m3, m6
    REPX    {pmaddubsw x, m14}, m1, m3
    pshuflw                 m1, m1, q2301
    pshufhw                 m3, m3, q2301
    paddw                   m1, m3
    paddw                   m0, m1
    sub                     t0, t1
    test                   t0d, 2
    jnz .left.luma.f1.pad64_half.skip_sampling
    pand                    m2, m1, m11
    movu       [rsp+0x78+t0*4], m2
    sub                     t0, 4
    jmp .left.luma.f1.pad64_half.samping_done
.left.luma.f1.pad64_half.skip_sampling:
    sub                     t0, 2
.left.luma.f1.pad64_half.samping_done:
%endif
    cmp                  hpadd, 4
%ifidn %1, explicit
    je .left.chroma
    paddw                   m1, m5, m6
%else
    je .left.chroma.reload
%endif
%ifidn %1, implicit
    punpckhqdq              m1, m1
    pand                    m2, m1, m11
%endif
    cmp                  hpadd, 20
    jmp .left.luma.pad

.left.luma.f0:
    vpbroadcastd          ym14, [pb_flt0]
    movd                    m0, [row0q+ystrideq*0-2]
    movd                    m1, [row0q+ystrideq*1-2]
    movd                    m2, [row1q+ystrideq*0-2]
    movd                    m3, [row1q+ystrideq*1-2]
    movd                    m4, [row2q+ystrideq*0-2]
    movd                    m5, [row2q+ystrideq*1-2]
    movd                    m6, [row3q+ystrideq*0-2]
    movd                    m7, [row3q+ystrideq*1-2]
    punpcklwd               m0, m1
    punpcklwd               m2, m3
    punpcklwd               m4, m5
    punpcklwd               m6, m7
    punpckldq               m0, m2
    punpckldq               m4, m6
    punpcklqdq              m0, m4
    pmaddubsw               m0, m14
%ifidn %1, implicit
    cmp                  stepd, 8
    je .left.luma.f0.skip_sampling
    pand                   m10, m0, m11
%endif
    sub                     hd, 4
%ifidn %1, explicit
    jz .left.chroma
%else
    jz .left.chroma.h4
    movu            [rsp+0x70], m10
    sub                    rsp, 8
    mov                [rsp+0], wpadd
    mov                [rsp+4], h0d
    mov                    t1d, 4
    xor                    t0d, t0d
    jmp .left.luma.f0.loop
.left.luma.f0.skip_sampling:
    sub                    rsp, 8
    sub                     hd, 4
    mov                [rsp+0], wpadd
    mov                [rsp+4], h0d
    mov                    t1d, 2
    mov                    t0d, t1d
%endif
.left.luma.f0.loop:
    lea                  row0q, [row0q+rowq*4]
    lea                  row1q, [row1q+rowq*4]
    lea                  row2q, [row2q+rowq*4]
    lea                  row3q, [row3q+rowq*4]
    movd                    m1, [row0q+ystrideq*0-2]
    movd                    m2, [row0q+ystrideq*1-2]
    movd                    m3, [row1q+ystrideq*0-2]
    movd                    m4, [row1q+ystrideq*1-2]
    sub                     hd, 2
    jb .left.luma.f0.pad64_half
    movd                    m5, [row2q+ystrideq*0-2]
    movd                    m6, [row2q+ystrideq*1-2]
    movd                    m7, [row3q+ystrideq*0-2]
    movd                    m8, [row3q+ystrideq*1-2]
    punpcklwd               m1, m2
    punpcklwd               m3, m4
    punpcklwd               m5, m6
    punpcklwd               m7, m8
    punpckldq               m1, m3
    punpckldq               m5, m7
    punpcklqdq              m1, m5
    pmaddubsw               m1, m14
%ifidn %1, implicit
    sub                     t0, t1
    test                   t0d, 2       ; step=4 or (step=8 and even loop iter)
    jnz .left.luma.f0.loop.skip_sampling
    pand                    m2, m1, m11
    movu       [rsp+0x78+t0*4], m2
.left.luma.f0.loop.skip_sampling:
%endif
    paddw                   m0, m1
    sub                     hd, 2
    ja .left.luma.f0.loop
%ifidn %1, explicit
    jz .left.chroma
    cmp                    h0d, 64
%else
    jz .left.chroma.reload
    cmp          dword [rsp+4], 64
%endif
    je .left.luma.f0.pad64
    pshufd                  m1, m1, q3333
%ifidn %1, implicit
    pand                    m2, m1, m11
    mov                    t3d, 4
    test                   t0d, 2
    cmovz                  t1d, t3d
    sub                     t0, t1
%endif
    cmp                  hpadd, 8
    jmp .left.luma.pad
.left.luma.f0.pad64:
    lea                     t2, [ystrideq*3]
    movd                    m1, [row3q+ystrideq*2-2]
    movd                    m2, [row3q+t2-2]
    punpcklwd               m1, m2
    pshufd                  m1, m1, q0000
    pmaddubsw               m1, m14
%ifidn %1, implicit
    pand                    m2, m1, m11
    mov                    t3d, 4
    test                   t0d, 2
    cmovz                  t1d, t3d
    sub                     t0, t1
%endif
    cmp                  hpadd, 16
    jmp .left.luma.pad
.left.luma.f0.pad64_half:
    lea                     t3, [ystrideq*3]
    movd                    m5, [row1q+ystrideq*2-2]
    movd                    m6, [row1q+t3-2]
    punpcklwd               m1, m2
    punpcklwd               m3, m4
    punpcklwd               m5, m6
    punpckldq               m1, m3
    punpckldq               m5, m5
    punpcklqdq              m1, m5
    pmaddubsw               m1, m14
%ifidn %1, implicit
    sub                     t0, t1
    test                   t0d, 2       ; step=4 or (step=8 and even loop iter)
    jnz .left.luma.f0.pad64_half.skip_sampling
    pand                    m2, m1, m11
    movu       [rsp+0x78+t0*4], m2
    sub                     t0, 4
    jmp .left.luma.f0.pad64_half.sampling_done
.left.luma.f0.pad64_half.skip_sampling:
    sub                     t0, 2
.left.luma.f0.pad64_half.sampling_done:
%endif
    paddw                   m0, m1
    pshufd                  m1, m1, q3333
    cmp                  hpadd, 4
%ifidn %1, explicit
    je .left.chroma
%else
    je .left.chroma.reload
    pand                    m2, m1, m11
%endif
    cmp                  hpadd, 20
.left.luma.pad:
%ifidn %1, implicit
    jb .left.luma.pad4
    je .left.luma.pad8
%endif
    paddw                   m0, m1
%ifidn %1, explicit
    jb .left.chroma
%else
    movu       [rsp+0x78+t0*4], m2
    sub                     t0, 4
.left.luma.pad8:
%endif
    paddw                   m0, m1
%ifidn %1, explicit
    je .left.chroma
%else
    cmp                  stepd, 8
    je .left.luma.pad4
    movu       [rsp+0x78+t0*4], m2
    sub                     t0, 4
.left.luma.pad4:
%endif
    paddw                   m0, m1
%ifidn %1, implicit
    movu       [rsp+0x78+t0*4], m2
    jmp .left.chroma.reload
%endif

%ifidn %1, implicit
.left.chroma.h4:
    mov                   r13d, 4 ; hd
    jmp .left.chroma2
.left.chroma.reload:
    mov                    h0d, [rsp+4]
    mov                  wpadd, [rsp+0]
    add                    rsp, 8
%endif
.left.chroma:
%ifidn %1, explicit
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, _, _, _, cstride, \
             usrc, vsrc, _, h, row
 DECLARE_REG_TMP 6, 7, 8, 12, 14
    mov                  usrcq, [ptrsq+32]
    mov                  vsrcq, [ptrsq+40]
    pop                     hq
    cmp                    h0d, 64
    sete                   t0b
    shlx                  rowq, cstrideq, t0
    movzx                  t0d, byte [usrcq+rowq*0-1]
    movzx                  t1d, byte [vsrcq+rowq*0-1]
    movzx                  t2d, byte [usrcq+rowq*1-1]
    movzx                  t3d, byte [vsrcq+rowq*1-1]
    lea                  usrcq, [usrcq+rowq*2-1]
    lea                  vsrcq, [vsrcq+rowq*2-1]
    add                    t0d, t2d
    add                    t1d, t3d
    movzx                  t2d, byte [usrcq+rowq*0]
    movzx                  t3d, byte [vsrcq+rowq*0]
    add                    t0d, t2d
    add                    t1d, t3d
    movzx                  t2d, byte [usrcq+rowq*1]
    movzx                  t3d, byte [vsrcq+rowq*1]
    add                    t0d, t2d
    add                    t1d, t3d
    sub                     hd, 4
    jz .top
.left.chroma.loop:
    lea                  usrcq, [usrcq+rowq*2]
    lea                  vsrcq, [vsrcq+rowq*2]
    movzx                  t2d, byte [usrcq+rowq*0]
    movzx                  t3d, byte [vsrcq+rowq*0]
    add                    t0d, t2d
    add                    t1d, t3d
    movzx                  t2d, byte [usrcq+rowq*1]
    movzx                  t3d, byte [vsrcq+rowq*1]
    add                    t0d, t2d
    add                    t1d, t3d
    sub                     hd, 2
    jb .left.chroma.pad.h64_half
    lea                  usrcq, [usrcq+rowq*2]
    lea                  vsrcq, [vsrcq+rowq*2]
    movzx                  t2d, byte [usrcq+rowq*0]
    movzx                  t3d, byte [vsrcq+rowq*0]
    add                    t0d, t2d
    add                    t1d, t3d
    movzx                  t2d, byte [usrcq+rowq*1]
    movzx                  t3d, byte [vsrcq+rowq*1]
    add                    t0d, t2d
    add                    t1d, t3d
    sub                     hd, 2
    ja .left.chroma.loop
    jz .top
    cmp                    h0d, 64
    je .left.chroma.pad.h64
    mov                    t4d, hpadd
.left.chroma.pad:
    imul                   t2d, t4d
    imul                   t3d, t4d
    add                    t0d, t2d
    add                    t1d, t3d
    jmp .top
.left.chroma.pad.h64:
    add                  usrcq, rowq
    add                  vsrcq, rowq
    mov                    t4d, hpadd
    shr                    t4d, 1
    movzx                  t2d, byte [usrcq+cstrideq]
    movzx                  t3d, byte [vsrcq+cstrideq]
    jmp .left.chroma.pad
.left.chroma.pad.h64_half:
    add                  usrcq, rowq
    add                  vsrcq, rowq
    movzx                  t2d, byte [usrcq+cstrideq]
    movzx                  t3d, byte [vsrcq+cstrideq]
    mov                    t4d, hpadd
    sub                    t4d, 4
    shr                    t4d, 1
    lea                    t0d, [t0+t2*2]
    lea                    t1d, [t1+t3*2]
    jnz .left.chroma.pad
    jmp .top
%else ; implicit
 INIT_XMM avx2
 DEFINE_ARGS ptrs, ystride, wpad, hpad, _, h0, _, step, _, cstride, \
             usrc, vsrc, _, h, row
 DECLARE_REG_TMP 4, 6
    movu                   m10, [rsp+0x70]
    mov                     hd, [rsp+0x80]
.left.chroma2:
%if UNIX64
    push                    r4 ; wq
%assign %%stksz gprsize
%else
%assign %%stksz 0
%endif
    mov                  usrcq, [ptrsq+32]
    mov                  vsrcq, [ptrsq+40]
    cmp                    h0d, 32
    seta                   t0b
    shlx                  rowq, cstrideq, t0
    movd                    m1, [usrcq+rowq*0-1]
    movd                    m3, [usrcq+rowq*1-1]
    movd                    m2, [vsrcq+rowq*0-1]
    movd                    m4, [vsrcq+rowq*1-1]
    lea                  usrcq, [usrcq+rowq*2-1]
    lea                  vsrcq, [vsrcq+rowq*2-1]
    movd                    m5, [usrcq+rowq*0]
    movd                    m7, [usrcq+rowq*1]
    movd                    m6, [vsrcq+rowq*0]
    movd                    m8, [vsrcq+rowq*1]
    psrlw                  m15, 8
    packssdw               m14, m11, m11
    punpcklwd               m1, m3
    punpcklwd               m2, m4
    punpcklwd               m5, m7
    punpcklwd               m6, m8
    punpckldq               m1, m5
    punpckldq               m2, m6
    punpcklqdq              m1, m2
    pand                    m1, m15
    cmp                  stepd, 8
    je .left.chroma.skip_sampling
    phaddw                 m10, m10
    psrlw                  m10, 3               ; sum_x
    pmaddwd                m12, m10, m10        ; sum_xx
    pmaddwd                m13, m10, m1         ; sum_xy
    pand                   m11, m1, m14         ; sum_y
    mov                     t1, 0x60
    jmp .left.chroma.sampling_done
.left.chroma.skip_sampling:
    pxor                   m10, m10
    pxor                   m12, m12
    pxor                   m11, m11
    pxor                   m13, m13
    mov                     t1, 0x70
.left.chroma.sampling_done:
    xor                    t0d, t0d
    sub                     hd, 4
    jz .top
.left.chroma.loop:
    lea                  usrcq, [usrcq+rowq*2]
    lea                  vsrcq, [vsrcq+rowq*2]
    movd                    m2, [usrcq+rowq*0]
    movd                    m4, [usrcq+rowq*1]
    movd                    m3, [vsrcq+rowq*0]
    movd                    m5, [vsrcq+rowq*1]
    sub                     hd, 2
    jb .left.chroma.pad.h64_half
    lea                  usrcq, [usrcq+rowq*2]
    lea                  vsrcq, [vsrcq+rowq*2]
    movd                    m6, [usrcq+rowq*0]
    movd                    m8, [usrcq+rowq*1]
    movd                    m7, [vsrcq+rowq*0]
    movd                    m9, [vsrcq+rowq*1]
    punpcklwd               m2, m4
    punpcklwd               m3, m5
    punpcklwd               m6, m8
    punpcklwd               m7, m9
    punpckldq               m2, m6
    punpckldq               m3, m7
    punpcklqdq              m2, m3
    pand                    m2, m15
    cmp                  stepd, 8
    jb .left.chroma.loop.sampling
    xor                    t0d, 1
    jz .left.chroma.loop.skip_sampling
.left.chroma.loop.sampling:
    movu                    m6, [rsp+%%stksz+t1]
    sub                     t1, 16
    phaddw                  m6, m6
    psrlw                   m6, 3
    pmaddwd                 m8, m6, m6
    pmaddwd                 m9, m6, m2
    pand                    m7, m2, m14
    paddw                  m10, m6
    paddw                  m11, m7
    paddd                  m12, m8
    paddd                  m13, m9
.left.chroma.loop.skip_sampling:
    paddw                   m1, m2
    sub                     hd, 2
    ja .left.chroma.loop
    jz .top
    cmp                    h0d, 64
    je .left.chroma.pad.h64
    movu                    m6, [rsp+%%stksz+t1]
    pshuflw                 m2, m2, q3333
    pshufhw                 m2, m2, q3333
    phaddw                  m6, m6
    psrlw                   m6, 3
    pmaddwd                 m8, m6, m6
    pmaddwd                 m9, m6, m2
    pand                    m7, m2, m14
    mov                    t0d, hpadd
.left.chroma.pad:
    cmp                    t0d, 8
    jb .left.chroma.pad4
    je .left.chroma.pad8
    paddw                   m1, m2
    paddw                  m10, m6
    paddw                  m11, m7
    paddd                  m12, m8
    paddd                  m13, m9
.left.chroma.pad8:
    paddw                   m1, m2
    cmp                  stepd, 8
    je .left.chroma.pad4
    paddw                  m10, m6
    paddw                  m11, m7
    paddd                  m12, m8
    paddd                  m13, m9
.left.chroma.pad4:
    paddw                   m1, m2
    paddw                  m10, m6
    paddw                  m11, m7
    paddd                  m12, m8
    paddd                  m13, m9
    jmp .top
.left.chroma.pad.h64:
    add                  usrcq, rowq
    add                  vsrcq, rowq
    movu                    m6, [rsp+%%stksz+t1]
    movd                    m2, [usrcq+cstrideq]
    movd                    m3, [vsrcq+cstrideq]
    phaddw                  m6, m6
    punpcklqdq              m2, m3
    pshufb                  m2, [dcCshuf]
    psrlw                   m6, 3
    pmaddwd                 m8, m6, m6
    pmaddwd                 m9, m6, m2
    pand                    m7, m2, m14
    mov                    t0d, hpadd
    shr                    t0d, 1
    jmp .left.chroma.pad
.left.chroma.pad.h64_half:
    add                  usrcq, rowq
    add                  vsrcq, rowq
    movd                    m7, [usrcq+cstrideq]
    movd                    m8, [vsrcq+cstrideq]
    punpcklwd               m2, m4
    punpcklwd               m3, m5
    punpcklwd               m7, m7
    punpcklwd               m8, m8
    punpckldq               m2, m7
    punpckldq               m3, m8
    punpcklqdq              m2, m3
    pand                    m2, m15
    paddw                   m1, m2
    test                   t0d, 1
    jnz .left.chroma.pad.h64_half.skip_sampling
    movu                    m6, [rsp+%%stksz+t1]
    sub                     t1, 16
    phaddw                  m6, m6
    psrlw                   m6, 3
    pmaddwd                 m8, m6, m6
    pmaddwd                 m9, m6, m2
    pand                    m7, m2, m14
    paddw                  m10, m6
    paddw                  m11, m7
    paddd                  m12, m8
    paddd                  m13, m9
.left.chroma.pad.h64_half.skip_sampling:
    mov                    t0d, hpadd
    sub                    t0d, 4
    shr                    t0d, 1
    jz .top
    movu                    m6, [rsp+%%stksz+t1]
    phaddw                  m6, m6
    psrlw                   m6, 3
    pshufd                  m2, m2, q3311
    pmaddwd                 m8, m6, m6
    pmaddwd                 m9, m6, m2
    pand                    m7, m2, m14
    jmp .left.chroma.pad
%endif

 INIT_YMM avx2
.no_left:
    lea                  hpadd, [hpadq*4]
    pxor                   xm0, xm0
    pxor                   xm1, xm1
%ifidn %1, implicit
    REPX           {pxor x, x}, xm10, xm11, xm12, xm13
%assign %%stksz %%stksz+0x80
%define stk_ntop  [rsp+%%stksz+8]
%define stk_nleft [rsp+%%stksz+4]
%define stk_hpad  [rsp+%%stksz-4]
    sub                    rsp, 3*4+%%stksz ; ntop, nleft, h
    mov               stk_ntop, r10d
    mov              stk_nleft, r11d
    mov               stk_hpad, hpadd
    mov                    r3d, r10d
%endif
    jmp .top.no_left

.top:
 DEFINE_ARGS ptrs, ystride, wpad, step, w, h, flags, tbl, flt, cstride, \
             ytop0, ytop1, utop, vtop, ytopa
%ifidn %1, explicit
    movd                   xm1, t0d
    movd                   xm2, t1d
    punpcklqdq             xm1, xm2
%else
%if UNIX64
%define wm        [rsp]
%define mem_flags [rsp+%%stksz+3*4+7*gprsize]  ; 6gpr+ret
%else ; WIN64
%define wm        [rsp+%%stksz+3*4+10*16+0x20+10*gprsize] ; 10xmm+redzone+alignment+8gpr+ret
%define mem_flags [rsp+%%stksz+3*4+10*16+0x20+12*gprsize] ; 10xmm+redzone+alignment+8gpr+ret+w_arg+h_arg
%endif
%define hpadm  stk_hpad
%define flagsm mem_flags
%define nleftm stk_nleft
%define ntopm  stk_ntop
%define hpadd stepd
%define ntopd stepd
    mov                     wd, wm
    pcmpeqw                m15, m15
%endif
 DECLARE_REG_TMP 14, 13, 12, 6
    mov                 flagsd, flagsm
%ifidn %1, implicit
    mov                  hpadm, hpadd
    mov                  ntopd, ntopm
%endif
.top.no_left:
%ifidn %1, implicit
    movu            [rsp+0x00], xm10
    movu            [rsp+0x10], xm11
    movu            [rsp+0x20], xm12
    movu            [rsp+0x30], xm13
    mov                    t0d, 32
    xor                    t1d, t1d
    cmp                     wd, t0d
    cmovb                  t0d, wd
    test                 ntopd, ntopd
    cmovz                  t0d, t1d
    shrx                 stepd, t0d, ntopd
    jz .top.skip_smpl_msk_load
    lea                     t0, [t_smpl_msk1]
    tzcnt                  t1d, stepd
    lea                    t1d, [t1*4]
    vbroadcasti128         m11, [t0+t1*4]
.top.skip_smpl_msk_load:
%endif
    lea                   tblq, [cfl_%1_420_8bpc_avx2_table]
%define base tblq-cfl_%1_420_8bpc_avx2_table
    mov                   fltd, flagsd
    and                   fltd, 0x3             ; filter_type
    vpbroadcastd           m14, [base+pb_flt0+fltq*4]
    lea                   fltd, [fltq*5]
    lea                   fltq, [fltq*4+tblq]
    vbroadcasti128          m8, [base+pb_0to15]
    mova                    m7, m8
    mova                   xm6, xm8
    shl                  wpadd, 2
    jz .top.no_pad
    ; gen right edge extend
    mov                    t0d, wpadd
    mov                    t1d, wpadd
    and                    t0d, 15
    and                    t1d, 7
    neg                     t0
    neg                     t1
    lea                    t0d, [16+t0-1]
    lea                    t1d, [16+t1*2-2]
    lea                    t2d, [t1+1]
    shl                    t2d, 8
    or                     t1d, t2d
    movd                   xm5, t0d
    movd                   xm9, t1d
    vpbroadcastb            m5, xm5
    vpbroadcastw            m9, xm9
    pminub                  m8, m5
    pminub                  m7, m9
.top.no_pad:
    test                flagsb, 0x4             ; have_top
    jz .no_top
    mov                 ytop0q, [ptrsq+0]
    mov                  utopq, [ptrsq+8]
    mov                  vtopq, [ptrsq+16]
    xor                 ytopaq, ytopaq
    xor                 ytop1q, ytop1q
    test                flagsb, 0x10            ; is_top_sb_edge
    cmovz               ytopaq, ystrideq
    cmovz               ytop1q, ystrideq
    neg                 ytopaq
    add                 ytop1q, ytop0q
    add                 ytopaq, ytop0q
    tzcnt                  t3d, wd
    movsxd                  t3, [fltq+t3*4]
    add                     t3, tblq
    jmp                     t3

 INIT_XMM avx2
.top.f0.w4:
    movd                    m5, [utopq]
    movq                    m2, [ytop0q]
    movq                    m4, [ytop1q]
    pinsrd                  m5, [vtopq], 2
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m5, m15
    paddw                   m2, m4
%ifidn %1, implicit
    test                 stepd, stepd
    jz .acc_dc.skip_top_sampling_wle8
.top.w4.sampling:
    psrlw                   m4, m2, 3
    pxor                    m7, m7
    pshufd                  m5, m5, q2020
    punpcklqdq              m4, m4              ; x
    punpcklbw               m5, m7              ; y
    pmaddwd                 m6, m4, m4          ; xx
    pmaddwd                 m7, m4, m5          ; xy
    paddw                  m10, m4
    paddw                  m11, m5, [rsp+0x10]
    paddd                  m12, m6
    paddd                  m13, m7
%endif
    jmp .acc_dc
.top.f0.w8:
    movq                    m5, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    movhps                  m5, [vtopq]
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m5, m15
    paddw                   m2, m4
%ifidn %1, explicit
    psrlq                   m5, m3, 32
    paddw                   m3, m5
%else
    test                 stepd, stepd
    jz .acc_dc.skip_top_sampling_wle8
.top.w8.sampling:
    psrlw                   m4, m2, 3
    pxor                    m7, m7
    punpckhbw               m6, m5, m7          ; u
    punpcklbw               m5, m7              ; v
    REPX         {pand x, m11}, m4, m6, m5      ; x y0 y1
    pmaddwd                 m7, m4, m4          ; xx
    pmaddwd                 m9, m4, m6          ; xy1
    pmaddwd                 m8, m4, m5          ; xy0
    psrldq                 m11, m4, 8
    psrldq                 m15, m7, 8
    phaddw                  m5, m6
    phaddd                  m8, m9
    paddw                   m4, m11
    paddd                   m7, m15
    paddw                  m11, m5, [rsp+0x10]
    paddd                  m13, m8
    paddw                  m10, m4
    paddd                  m12, m7
    pcmpeqw                m15, m15
%endif
    jmp .acc_dc
.top.f0.w16:
 INIT_YMM avx2
    movu                   xm5, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    vinserti128             m5, [vtopq], 1
    vpblendd                m7, m6, 0xf
    REPX    {pmaddubsw x, m14}, m2, m4
    pshufb                  m5, m8
    pmaddubsw               m3, m5, m15
    paddw                   m4, m2
    pshufb                  m4, m7
    psrldq                  m9, m3, 8
    vextracti128           xm6, m4, 1
    paddw                   m3, m9
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm4, xm6
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
%else
    test                 stepd, stepd
    jz .acc_dc.skip_top_sampling
.top.w16.sampling:
    pxor                    m9, m9
    punpckhbw               m7, m5, m9          ; u|v high
    punpcklbw               m5, m9              ; u|v low
    REPX        {pand x, xm11}, xm6, xm4
    REPX         {pand x, m11}, m7, m5
    psrlq                  xm6, 16
    psrlq                   m7, 16
    por                    xm4, xm6
    por                     m5, m7
    psrlw                  xm4, 3
    vinserti128             m6, m4, xm4, 1
    pmaddwd                xm7, xm4, xm4        ; xx
    pmaddwd                 m6, m5              ; xy0|xy1
    psrldq                 xm9, xm4, 8
    psrldq                xm11, xm7, 8
    vextracti128          xm13, m5, 1
    vextracti128          xm15, m6, 1
    paddw                  xm4, xm9
    paddd                  xm7, xm11
    phaddw                 xm5, xm13
    phaddd                 xm6, xm15
    paddw                 xm10, xm4, [rsp+0x00]
    paddd                 xm12, xm7, [rsp+0x20]
    paddw                 xm11, xm5, [rsp+0x10]
    paddd                 xm13, xm6, [rsp+0x30]
    pcmpeqw               xm15, xm15
%endif
    jmp .acc_dc
.top.f0.w32:
    movu                  xm13, [utopq+ 0]
    movu                   xm5, [utopq+16]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    movu                   m10, [ytop0q+32]
    movu                   m12, [ytop1q+32]
    vinserti128            m13, [vtopq+ 0], 1
    vinserti128             m5, [vtopq+16], 1
    REPX    {pmaddubsw x, m14}, m2, m4, m10, m12
    cmp                  wpadd, 4
    jnb .top.f0.w32.pad
.top.f0.w32.acc:
    pmaddubsw               m3, m13, m15
    pmaddubsw               m7, m5, m15
    paddw                   m4, m2
    paddw                  m10, m12
    paddw                   m3, m7
    paddw                   m2, m4, m10
    psrldq                  m7, m3, 8
    vextracti128          xm12, m2, 1
    paddw                   m3, m7
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm12
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
%else
.top.w32.sampling:
; m2=Ldc m3=Cdc m4=L0 m5=C1 m10=L1 m11=smplmsk m13=C0 m14=flt m15=-1
; free: m6 m7 m9 m12
    psllq                  m12, m11, 16
    psllq                  m10, 16
    psllq                   m5, 8
    por                    m11, m12
    packsswb               m12, m12
    pblendw                 m4, m10, 0x88 | 0x20    ; samples loc for steps 4|8
    pblendvb               m13, m5, m12
    pxor                    m9, m9
    punpcklbw               m5, m13, m9
    punpckhbw              m13, m9
    psrlw                   m4, 3
    REPX         {pand x, m11}, m4, m5, m13
    psrlq                   m6, m4, 32
    psrlq                   m7, m5, 32
    psrlq                   m9, m13, 32
    por                     m4, m6
    por                     m5, m7
    por                     m9, m13
    pshufd                  m4, m4, q3120
    shufps                  m5, m9, q2020
    vpermq                  m4, m4, q2020
    pmaddwd                xm6, xm4, xm4
    pmaddwd                 m7, m4, m5
    psrldq                 xm9, xm4, 8
    vextracti128          xm10, m5, 1
    psrldq                xm11, xm6, 8
    vextracti128          xm12, m7, 1
    paddw                  xm4, xm9
    phaddw                 xm5, xm10
    paddd                  xm6, xm11
    phaddd                 xm7, xm12
    paddw                 xm10, xm4, [rsp+0x00]
    paddw                 xm11, xm5, [rsp+0x10]
    paddd                 xm12, xm6, [rsp+0x20]
    paddd                 xm13, xm7, [rsp+0x30]
%endif
    jmp .acc_dc
.top.f0.w32.pad:
    pshufb                  m5, m8
    jne .top.f0.w32.pad_gt4
    vpblendd                m7, m6, 0x0f
    REPX        {pshufb x, m7}, m10, m12
    jmp .top.f0.w32.acc
.top.f0.w32.pad_gt4:
    pshufb                 xm3, xm10, xm9
    pshufb                 xm6, xm12, xm9
    REPX        {pshufb x, xm7}, xm10, xm12
    vinserti128            m10, xm3, 1
    vinserti128            m12, xm6, 1
    jmp .top.f0.w32.acc
.top.f0.w64:
    ; todo how much slower is it to have a single path?
    test                 wpadd, wpadd
    jnz .top.f0.w64.pad
    mova                    m2, [ytop0q]
    mova                    m3, [ytop1q]
    movu                    m4, [ytop0q+30]
    movu                    m5, [ytop1q+30]
    mova                    m6, [ytop0q+64]
    mova                    m8, [ytop1q+64]
    movu                   m12, [ytop0q+94]
    movu                   m13, [ytop1q+94]
    REPX    {pmaddubsw x, m14}, m2, m3, m4, m5, m6, m8, m12, m13
    mova                   xm7, [utopq+ 0]
    mova                   xm9, [utopq+32]
    vinserti128             m7, [vtopq+ 0], 1
    vinserti128             m9, [vtopq+32], 1
    paddw                   m2, m3
    paddw                   m4, m5
    paddw                   m6, m8
    paddw                  m12, m13
    movu                   xm3, [utopq+15]
    movu                   xm5, [utopq+47]
    vinserti128             m3, [vtopq+15], 1
    vinserti128             m5, [vtopq+47], 1
%ifidn %1, explicit
    paddw                   m2, m6
    paddw                  m12, m4
    pblendw                m12, m2, 0x55
%else
    vbroadcasti128          m8, [t64f0smplCshuf]
    pblendw                 m2, m4, 0xaa
    pblendw                 m6, m12, 0xaa
    paddw                  m12, m2, m6
    psllq                   m6, 32
    vpblendd                m2, m6, 0xaa
    psrlw                   m2, 3
    ; we need 4 12 20 28 36 44 52 60 or 8 24 40 56
    ;  0 16 32 48  4 20 36 52   8 24 40 56 12 28 44 60
    ;              4  4  4  4   8  8  8  8  4  4  4  4
%endif
    vextracti128           xm6, m12, 1
    psrlw                  m13, m15, 8
    pblendvb                m7, m3, m7, m13
    pblendvb                m9, m5, m9, m13
    pmaddubsw               m3, m7, m15
    pmaddubsw               m5, m9, m15
%ifidn %1, implicit
    pshufhw                m13, m11, q2200
    pshuflw                m11, m13, q2200
    punpckhdq              m13, m13
    pxor                    m4, m4
    vpblendd               m13, m4, 0x03
    REPX        {pshufb x, m8}, m7, m9      ;  0 16  4 20  8 24 12 28
%endif                                      ; 32 48 36 52 40 56 44 60
    paddw                   m3, m5
    psrldq                  m5, m3, 8
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
%ifidn %1, explicit
    paddw                  xm2, xm6, xm12
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
%else
    pand                    m2, m13
    REPX         {pand x, m11}, m7, m9
    psrldq                  m4, m2, 8
    psllq                   m5, m7, 32
    psllq                   m8, m9, 32
    por                     m4, m2
    por                     m5, m7
    por                     m8, m9
    vpermq                  m4, m4, q2020   ;  4 20 36 52 12 28 44 60 or .. .. .. ..  8 24 40 56
    shufps                  m5, m8, q3131   ;  4 20 12 28 36 52 44 60 or .. ..  8 24 .. .. 40 56
    pshufd                  m5, m5, q3120
    paddw                  xm2, xm6, xm12
    pmaddwd                xm6, xm4, xm4
    pmaddwd                 m7, m4, m5
    psrldq                 xm8, xm4, 8
    psrldq                 xm9, xm6, 8
    vextracti128          xm11, m5, 1
    vextracti128          xm12, m7, 1
    paddw                  xm4, xm8
    paddd                  xm6, xm9
    phaddw                 xm5, xm11
    phaddd                 xm7, xm12
    paddw                 xm10, xm4
    paddw                 xm11, xm5, [rsp+0x10]
    paddd                 xm12, xm6, [rsp+0x20]
    paddd                 xm13, xm7, [rsp+0x30]
%endif
    jmp .acc_dc
.top.f0.w64.pad:
%ifidn %1, implicit
    sub                    rsp, 0x20
    movu                 [rsp], m11
%endif
    mova                   xm3, [utopq+ 0]
    movu                  xm12, [utopq+15]
    mova                    m2, [ytop0q]
    mova                    m4, [ytop1q]
    movu                    m6, [ytop0q+30]
    movu                   m10, [ytop1q+30]
    vinserti128             m3, [vtopq+ 0], 1
    vinserti128            m12, [vtopq+15], 1
    psrlw                  m13, m15, 8
    REPX    {pmaddubsw x, m14}, m2, m4, m6, m10
    vpblendvb              m12, m3, m13
    paddw                   m4, m2
    paddw                   m6, m10
    pmaddubsw               m3, m12, m15
    pblendw                 m4, m6, 0xaa
    mova                   xm2, [ytop0q+64]
    mova                  xm10, [ytop0q+96]
    mova                  xm13, [ytop0q+80]
    mova                   xm6, [ytop0q+112]
    mova                  xm11, [utopq+32]
    mova                  xm15, [utopq+48]
    vinserti128             m2, [ytop1q+64], 1
    vinserti128            m10, [ytop1q+96], 1
    vinserti128            m13, [ytop1q+80], 1
    vinserti128             m6, [ytop1q+112], 1
    vinserti128            m11, [vtopq+32], 1
    vinserti128            m15, [vtopq+48], 1
    REPX    {pmaddubsw x, m14}, m2, m10, m13, m6
    pshufb                 m15, m8
    pshufb                  m6, m7
    cmp                  wpadd, 8
    jb .top.f0.w64.acc
    pshufb                  m6, m10, m9
    pshufb                 m10, m7
    cmp                  wpadd, 16
    jb .top.f0.w64.acc
    pshufb                 m15, m11, m5
    pshufb                 m11, m8
    pshufb                  m6, m13, m9
    pshufb                 m10, m13, m9
    pshufb                 m13, m7
    cmp                  wpadd, 24
    jb .top.f0.w64.acc
    pshufb                  m6, m2, m9
    pshufb                 m10, m2, m9
    pshufb                 m13, m2, m9
    pshufb                  m2, m7
.top.f0.w64.acc:
    pcmpeqw                 m9, m9
    psllw                   m5, m9, 8
    psllw                  m15, 8
    vpblendvb              m11, m15, m5
    pmaddubsw               m7, m11, m9
    paddw                   m3, m7
%ifidn %1, explicit
    paddw                   m2, m10
    paddw                   m6, m13
    pslld                   m6, 16
    pblendw                 m6, m2, 0x55
%else
    vbroadcasti128          m5, [t64f0smplCshuf]
    REPX         {pslld x, 16}, m10, m6
    pblendw                 m2, m10, 0xaa
    pblendw                 m6, m13, 0x55
    vperm2i128             m10, m2, m6, 0x31
    vperm2i128              m6, m2, m6, 0x20
    paddw                   m6, m10
%endif
    paddw                   m2, m4, m6
    vextracti128           xm7, m2, 1
    psrldq                  m9, m3, 8
    paddw                   m3, m9
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm7
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
%else
    ; todo jmp to top.f0.w64.sampling
    psllq                   m6, 32
    vpblendd                m4, m6, 0xaa
    psrlw                   m4, 3
    pshufhw                m13, [rsp], q2200
    pshuflw                m15, m13, q2200
    punpckhdq              m13, m13
    pxor                   m10, m10
    vpblendd               m13, m10, 0x03
    REPX        {pshufb x, m5}, m12, m11
    pand                    m4, m13
    REPX         {pand x, m15}, m12, m11
    psrldq                  m6, m4, 8
    psllq                   m5, m12, 32
    psllq                   m9, m11, 32
    por                     m4, m6
    por                     m5, m12
    por                     m9, m11
    vpermq                  m4, m4, q2020
    shufps                  m5, m9, q3131
    pshufd                  m5, m5, q3120
    pmaddwd                xm6, xm4, xm4
    pmaddwd                 m7, m4, m5
    psrldq                 xm9, xm4, 8
    psrldq                xm10, xm6, 8
    vextracti128          xm11, m5, 1
    vextracti128          xm13, m7, 1
    paddw                  xm4, xm9
    paddd                  xm6, xm10
    phaddw                 xm5, xm11
    phaddd                 xm7, xm13
    add                    rsp, 0x20
    paddw                 xm10, xm4, [rsp+0x00]
    paddw                 xm11, xm5, [rsp+0x10]
    paddd                 xm12, xm6, [rsp+0x20]
    paddd                 xm13, xm7, [rsp+0x30]
%endif
    pcmpeqw               xm15, xm15
    jmp .acc_dc

 INIT_XMM avx2
.top.f1.w4:
    movq                    m2, [ytop0q]
    movhps                  m2, [ytop1q]
    movd                    m5, [utopq]
    pinsrd                  m5, [vtopq], 2
    pshufb                  m4, m2, [base+w4Llshuf]
    pmaddubsw               m2, m14
    pmaddubsw               m3, m5, m15
    paddw                   m2, m4
%ifidn %1, explicit
    jmp .acc_dc
%else
    test                 stepd, stepd
    jz .acc_dc.skip_top_sampling_wle8
    pxor                    m6, m6
    psrldq                  m4, m2, 8
    paddw                   m2, m4
    vpblendd                m2, m6, 0xc
    jmp .top.w4.sampling
%endif
.top.f1.w8:
    mova                    m3, [base+w8Llshuf]
    movq                    m5, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    movhps                  m5, [vtopq]
    pshufb                  m6, m2, m3
    pshufb                  m7, m4, m3
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m5, m15
    paddw                   m6, m7
    paddw                   m2, m4
    paddw                   m2, m6
%ifidn %1, explicit
    psrlq                   m9, m3, 32
    paddw                   m3, m9
    jmp .acc_dc
%else
    test                 stepd, stepd
    jnz .top.w8.sampling
    jmp .acc_dc.skip_top_sampling_wle8
%endif
 INIT_YMM avx2
.top.f1.w16:
    vbroadcasti128          m6, [base+w8Llshuf]
    movu                   xm5, [utopq]
    movu                   xm2, [ytop0q+ 0]
    movu                   xm4, [ytop0q+16]
    vinserti128             m2, [ytop1q+ 0], 1
    vinserti128             m4, [ytop1q+16], 1
    vinserti128             m5, [vtopq], 1
    psrlw                  m13, m15, 8
    pshufb                  m3, m2, m6      ; low left
    pshufb                  m5, m8
    palignr                 m6, m4, m2, 15  ; high left
    REPX    {pmaddubsw x, m14}, m2, m4
    paddw                   m2, m3
    pmaddubsw               m3, m5, m15
    pand                    m6, m13
    paddw                   m4, m6
    pshufb                  m4, m7
%ifidn %1, implicit
    vperm2i128              m6, m2, m4, 0x31
    vperm2i128              m2, m4, 0x20
    paddw                   m4, m2, m6
%else
    paddw                   m4, m2
%endif
    vextracti128           xm6, m4, 1
    psrldq                  m7, m3, 8
    paddw                   m3, m7
    vpermq                  m3, m3, q2020
    paddw                  xm2, xm4, xm6
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
%else
    test                 stepd, stepd
    jnz .top.w16.sampling
    jmp .acc_dc.skip_top_sampling
%endif
.top.f1.w32:
    vbroadcasti128         m13, [base+w8Llshuf]
    mova                   xm4, [ytop0q+ 0]
    mova                   xm6, [ytop0q+16]
    mova                  xm10, [ytop0q+32]
    mova                  xm12, [ytop0q+48]
    vinserti128             m4, [ytop1q+ 0], 1
    vinserti128             m6, [ytop1q+16], 1
    vinserti128            m10, [ytop1q+32], 1
    vinserti128            m12, [ytop1q+48], 1
    psrlw                   m5, m15, 8
%ifidn %1, implicit
    SWAP                   m15, m11
%endif
    pshufb                 m13, m4, m13             ; l0
    palignr                 m2, m6, m4, 15          ; l1
    palignr                m11, m10, m6, 15         ; l2
    palignr                 m3, m12, m10, 15        ; l3
    REPX    {pmaddubsw x, m14}, m4, m6, m10, m12
    REPX          {pand x, m5}, m2, m11, m3
    paddw                   m4, m13
    movu                   xm5, [utopq+16]
    movu                  xm13, [utopq+ 0]
    vinserti128             m5, [vtopq+16], 1
    vinserti128            m13, [vtopq+ 0], 1
    paddw                   m6, m2
    paddw                  m10, m11
    paddw                  m12, m3
    test                 wpadd, wpadd
    jnz .top.f1.w32.pad
.top.f1.w32.acc:
%ifidn %1, explicit
    paddw                   m4, m6
    paddw                  m10, m12
%else
    vperm2i128              m7, m4, m6, 0x31
    vperm2i128              m4, m6, 0x20
    vperm2i128              m9, m10, m12, 0x31
    vperm2i128             m10, m12, 0x20
    paddw                   m4, m7                  ; L0
    paddw                  m10, m9                  ; L1
%endif
    paddw                   m2, m4, m10
    vextracti128           xm6, m2, 1
%ifidn %1, implicit
    SWAP                   m12, m15
    pcmpeqd                m15, m15
%endif
    pmaddubsw               m3, m5, m15
    pmaddubsw               m9, m13, m15
%ifidn %1, implicit
    SWAP                   m15, m12
%endif
    paddw                   m3, m9
    psrldq                  m9, m3, 8
    paddw                   m3, m9
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm6
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
%else
    SWAP                   m11, m15
    pcmpeqd               xm15, xm15
    jmp .top.w32.sampling
%endif
.top.f1.w32.pad:
    pshufb                  m5, m8
    pshufb                 m12, m7
    cmp                  wpadd, 8
    jb .top.f1.w32.acc
    vinserti128             m9, xm9, 1
    pshufb                 m12, m10, m9
    pshufb                 m10, m7
    jmp .top.f1.w32.acc
.top.f1.w64:
%ifidn %1, implicit
    psrldq                 m13, m11, 8
    punpcklwd              m11, m13
    sub                    rsp, 0x40
    movu                 [rsp], m11
%endif
    ; todo how much slower is it to have a single path?
    test                 wpadd, wpadd
    jnz .top.f1.w64pad
    mova                   xm2, [ytop0q+0x00]
    mova                   xm3, [ytop0q+0x10]
    mova                   xm4, [ytop0q+0x20]
    mova                   xm5, [ytop0q+0x30]
    mova                  xm11, [utopq+ 0]
    movu                  xm12, [utopq+15]
    vinserti128             m2, [ytop1q+0x00], 1
    vinserti128             m3, [ytop1q+0x10], 1
    vinserti128             m4, [ytop1q+0x20], 1
    vinserti128             m5, [ytop1q+0x30], 1
    vinserti128            m11, [vtopq+ 0], 1
    vinserti128            m12, [vtopq+15], 1
    psrlw                  m13, m15, 8
    pslldq                  m6, m2, 15
    palignr                 m6, m2, m6, 15
    palignr                 m7, m3, m2, 13
    palignr                 m8, m4, m3, 15
    palignr                 m9, m5, m4, 13
    pslld                   m3, 16
    pslld                  m10, m5, 16
    pblendw                 m2, m3, 0xaa
    pblendw                 m4, m10, 0xaa
    pblendw                 m6, m7, 0xaa
    pblendw                 m8, m9, 0xaa
    mova                   xm3, [ytop0q+0x40]
    mova                   xm7, [ytop0q+0x50]
    mova                   xm9, [ytop0q+0x60]
    mova                  xm10, [ytop0q+0x70]
    vinserti128             m3, [ytop1q+0x40], 1
    vinserti128             m7, [ytop1q+0x50], 1
    vinserti128             m9, [ytop1q+0x60], 1
    vinserti128            m10, [ytop1q+0x70], 1
    pblendvb               m11, m12, m11, m13
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw              m15, m11, m15
    REPX         {pand x, m13}, m6, m8
    paddw                   m2, m6
    paddw                   m4, m8
%ifidn %1, explicit
    paddw                   m2, m4
%else
    vperm2i128             m12, m2, m4, 0x31
    vperm2i128              m2, m4, 0x20
    paddw                   m2, m12
%endif
    mova                  xm12, [utopq+32]
    vinserti128            m12, [vtopq+32], 1
    palignr                 m4, m3, m5, 15
    palignr                 m5, m7, m3, 13
    palignr                 m6, m9, m7, 15
    palignr                 m8, m10, m9, 13
    REPX         {pslld x, 16}, m7, m10
    pblendw                 m4, m5, 0xaa
    pblendw                 m6, m8, 0xaa
    pblendw                 m3, m7, 0xaa
    pblendw                 m9, m10, 0xaa
%ifidn %1, implicit
    vbroadcasti128          m5, [base+t64f1smplCshuf]
%endif
    movu                  xm10, [utopq+47]
    vinserti128            m10, [vtopq+47], 1
    REPX    {pmaddubsw x, m14}, m3, m9
    REPX         {pand x, m13}, m4, m6
    pblendvb               m12, m10, m12, m13
    pcmpeqw                m13, m13
    pmaddubsw              m13, m12, m13
%ifidn %1, explicit
    paddw                   m4, m6
    paddw                   m3, m9
    paddw                   m2, m4
    paddw                   m2, m3
%else
    paddw                   m3, m4
    paddw                   m6, m9
    vperm2i128              m4, m3, m6, 0x31
    vperm2i128              m3, m6, 0x20
    pshufd                  m9, [rsp], q2200
    add                    rsp, 0x40
    REPX        {pshufb x, m5}, m11, m12      ; 00 08 04 12 16 24 20 28 / 32 40 36 44 48 56 52 60
    punpckldq              m10, m11, m12      ; 00 08 32 40 04 12 36 44
    punpckhdq              m11, m12           ; 16 24 48 56 20 28 52 60
    paddw                   m3, m4
    psllq                   m4, m3, 32
    vpblendd                m4, m2, 0x55
    psrlw                   m4, 3
    paddw                   m2, m3
    ; we need 4 12 20 28 36 44 52 60 or 8 24 40 56
    ; 08 00 40 32 12 04 44 36  24 16 56 48 28 20 60 52
    ;  8     8     4  4  4  4   8     8     4  4  4  4
%endif
    vextracti128           xm6, m2, 1
    paddw                  m15, m13
    psrldq                  m3, m15, 8
    paddw                   m3, m15
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm6
%ifidn %1, explicit
    psrlq                  xm9, xm3, 32
    paddw                  xm3, xm9
%else
    REPX          {pand x, m9}, m4, m10, m11
    psrldq                  m6, m4, 8
    psrldq                 m12, m10, 8
    psrldq                 m13, m11, 8
    por                     m4, m6
    por                    m10, m12
    por                    m11, m13
    vpermq                  m4, m4, q2020
    punpcklqdq              m5, m10, m11
    pmaddwd                xm6, xm4, xm4
    pmaddwd                 m7, m4, m5
    psrldq                 xm8, xm4, 8
    psrldq                 xm9, xm6, 8
    vextracti128          xm10, m5, 1
    vextracti128          xm11, m7, 1
    paddw                  xm4, xm8
    paddd                  xm6, xm9
    phaddw                 xm5, xm10
    phaddd                 xm7, xm11
    paddw                 xm10, xm4, [rsp+0x00]
    paddw                 xm11, xm5, [rsp+0x10]
    paddd                 xm12, xm6, [rsp+0x20]
    paddd                 xm13, xm7, [rsp+0x30]
%endif
    pcmpeqw               xm15, xm15
    jmp .acc_dc
.top.f1.w64pad:
%ifidn %1, explicit
    sub                    rsp, 0x40
%endif
    movu            [rsp+0x20], m5
    mova                   xm2, [ytop0q+0x00]
    mova                   xm3, [ytop0q+0x10]
    mova                   xm4, [ytop0q+0x20]
    mova                   xm5, [ytop0q+0x30]
    vinserti128             m2, [ytop1q+0x00], 1
    vinserti128             m3, [ytop1q+0x10], 1
    vinserti128             m4, [ytop1q+0x20], 1
    vinserti128             m5, [ytop1q+0x30], 1
    psrlw                  m13, m15, 8
    pslldq                 m10, m2, 15
    palignr                m10, m2, m10, 15
    palignr                m11, m3, m2, 13
    palignr                m12, m4, m3, 15
    palignr                 m6, m5, m4, 13
    pblendw                m10, m11, 0xaa
    pblendw                m12, m6, 0xaa
    pslld                   m3, 16
    pslld                   m6, m5, 16
    pblendw                 m2, m3, 0xaa
    pblendw                 m4, m6, 0xaa
    mova                  xm11, [utopq+ 0]
    movu                   xm6, [utopq+15]
    vinserti128            m11, [vtopq+ 0], 1
    vinserti128             m6, [vtopq+15], 1
    REPX    {pmaddubsw x, m14}, m2, m4
    REPX         {pand x, m13}, m10, m12
    paddw                   m2, m10
    paddw                   m4, m12
%ifidn %1, explicit
    paddw                  m10, m2, m4
%else
    vperm2i128             m10, m2, m4, 0x31
    vperm2i128              m2, m4, 0x20
    paddw                  m10, m2                      ; L0
%endif
    pblendvb               m11, m6, m11, m13            ; C0
    pmaddubsw               m3, m11, m15
    mova                  xm12, [ytop0q+0x40]
    mova                   xm4, [ytop0q+0x50]
    mova                  xm13, [ytop0q+0x60]
    mova                   xm6, [ytop0q+0x70]
    vinserti128            m12, [ytop1q+0x40], 1
    vinserti128             m4, [ytop1q+0x50], 1
    vinserti128            m13, [ytop1q+0x60], 1
    vinserti128             m6, [ytop1q+0x70], 1
    palignr                 m2, m12, m5, 15
    palignr                m14, m4, m12, 15
    palignr                 m5, m13, m4, 15
    palignr                m15, m6, m13, 15
    REPX        {pshufb x, m7}, m6, m15
    cmp                  wpadd, 8
    jb .top.f1.w64pad.acc_luma
    pshufb                  m6, m13, m9
    pshufb                 m15, m5, m9
    REPX        {pshufb x, m7}, m13, m5
    cmp                  wpadd, 16
    jb .top.f1.w64pad.acc_luma
    REPX   {pshufb x,  m4, m9}, m6, m13
    REPX   {pshufb x, m14, m9}, m15, m5
    REPX        {pshufb x, m7}, m4, m14
    cmp                  wpadd, 24
    jb .top.f1.w64pad.acc_luma
    REPX   {pshufb x, m12, m9}, m6, m13, m4
    REPX   {pshufb x,  m2, m9}, m15, m5, m14
    REPX        {pshufb x, m7}, m12, m2
.top.f1.w64pad.acc_luma:
; m0m1=left m2=yacc m3=uvacc m4m5m6=y m7 m8=pad
; m9 m10=y m11=uv m12=y m13 m14=weights m15=uv
    REPX         {pslld x, 16}, m14, m15, m4, m6
    pblendw                 m2, m14, 0xaa
    pblendw                 m5, m15, 0xaa
    vpbroadcastd           m14, [base+pb_flt1]
    pcmpeqw                m15, m15
    pblendw                m12, m4, 0xaa
    pblendw                m13, m6, 0xaa
    mova                   xm4, [utopq+32]
    mova                   xm6, [utopq+48]
    vinserti128             m4, [vtopq+32], 1
    vinserti128             m6, [vtopq+48], 1
    psrlw                   m7, m15, 8
    REPX    {pmaddubsw x, m14}, m12, m13
    REPX          {pand x, m7}, m2, m5
    paddw                  m12, m2
    paddw                  m13, m5
%ifidn %1, explicit
    paddw                  m12, m13
    paddw                   m2, m12, m10
%else
    vperm2i128              m5, m12, m13, 0x31
    vperm2i128             m12, m13, 0x20
    vbroadcasti128         m13, [base+t64f1smplCshuf]
    paddw                  m12, m5                      ; L1
    paddw                   m2, m10, m12
    psllq                  m12, 32
    vpblendd               m10, m12, 0xaa
%endif
    pshufb                  m6, m8
    vextracti128           xm9, m2, 1
    cmp                  wpadd, 16
    jb .top.f1.w64pad.acc_chroma
    pshufb                  m6, m4, [rsp+0x20]
    pshufb                  m4, m8
.top.f1.w64pad.acc_chroma:
    psllw                   m6, 8
    pblendvb                m4, m6, m4, m7              ; C1
    pmaddubsw               m7, m4, m15
%ifidn %1, implicit
    REPX       {pshufb x, m13}, m11, m4
    punpckldq               m5, m11, m4
    punpckhdq              m11, m4
    pshufd                  m6, [rsp], q2200
    psrlw                  m10, 3
%endif
    add                    rsp, 0x40
    paddw                   m3, m7
    psrldq                  m7, m3, 8
    paddw                   m3, m7
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm9
%ifidn %1, explicit
    psrlq                  xm7, xm3, 32
    paddw                  xm3, xm7
%else
    REPX          {pand x, m6}, m10, m5, m11
    psrldq                  m4, m10, 8
    psrldq                  m9, m5, 8
    psrldq                  m6, m11, 8
    por                     m4, m10
    por                     m5, m9
    por                     m6, m11
    vpermq                  m4, m4, q2020
    punpcklqdq              m5, m6
    pmaddwd                xm6, xm4, xm4
    pmaddwd                 m7, m4, m5
    psrldq                 xm9, xm4, 8
    psrldq                xm10, xm6, 8
    vextracti128          xm11, m5, 1
    vextracti128          xm12, m7, 1
    paddw                  xm4, xm9
    paddd                  xm6, xm10
    phaddw                 xm5, xm11
    phaddd                 xm7, xm12
    paddw                 xm10, xm4, [rsp+0x00]
    paddw                 xm11, xm5, [rsp+0x10]
    paddd                 xm12, xm6, [rsp+0x20]
    paddd                 xm13, xm7, [rsp+0x30]
%endif
    jmp .acc_dc

 INIT_XMM avx2
.top.f2.w4:
    movq                    m4, [ytopaq]
    movq                    m6, [ytop1q]
    movq                    m2, [ytop0q]
    movd                    m5, [utopq]
    pinsrd                  m5, [vtopq], 2
    psrlw                   m9, m15, 8
    pshufb                  m7, m2, [base+w4Llshuf]
    REPX          {pand x, m9}, m4, m6
    pmaddubsw               m2, m14
    pmaddubsw               m3, m5, m15
    paddw                   m4, m7
    paddw                   m4, m6
    paddw                   m2, m4
%ifidn %1, explicit
    jmp .acc_dc
%else
    test                 stepd, stepd
    jz .acc_dc.skip_top_sampling_wle8
    jmp .top.w4.sampling
%endif
.top.f2.w8:
    movq                    m5, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytopaq]
    movu                    m7, [ytop1q]
    movhps                  m5, [vtopq]
    psrlw                   m9, m15, 8
    pshufb                  m6, m2, [base+w8Llshuf]
    REPX          {pand x, m9}, m4, m7
    pmaddubsw               m2, m14
    pmaddubsw               m3, m5, m15
    paddw                   m4, m6
    paddw                   m4, m7
    paddw                   m2, m4
%ifidn %1, explicit
    psrlq                   m5, m3, 32
    paddw                   m3, m5
    jmp .acc_dc
%else
    test                 stepd, stepd
    jnz .top.w8.sampling
    jmp .acc_dc.skip_top_sampling_wle8
%endif
.top.f2.w16:
 INIT_YMM avx2
    movu                    m4, [ytopaq]
    movu                    m9, [ytop1q]
    vbroadcasti128          m2, [ytop0q+ 0]
    vbroadcasti128         m12, [ytop0q+16]
    movu                   xm5, [utopq]
    vinserti128             m5, [vtopq], 1
    vpblendd                m7, m6, 0xf
    psrlw                  m13, m15, 8
    REPX         {pand x, m13}, m4, m9
    paddw                   m4, m9
    pshufb                 xm6, xm2, [base+w8Llshuf]; l low
    palignr                m10, m12, m2, 15     ; l high
    vpblendd                m2, m12, 0xf0
    vpblendd                m6, m10, 0xf0
    pshufb                  m5, m8              ; wpad chroma
    pmaddubsw               m2, m14
    pmaddubsw               m3, m5, m15
    pand                    m6, m13
    paddw                   m4, m6              ; t+b+l
    paddw                   m4, m2              ; c+r+t+b+l
    pshufb                  m4, m7              ; wpad luma
    vextracti128           xm6, m4, 1
    psrldq                  m9, m3, 8
    paddw                   m3, m9
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm4, xm6
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
%else
    test                 stepd, stepd
    jnz .top.w16.sampling
    jmp .acc_dc.skip_top_sampling
%endif
.top.f2.w32:
    psrlw                  m13, m15, 8
%ifidn %1, implicit
    SWAP                   m15, m11             ; sampling mask
%endif
    mova                   xm3, [ytop0q+16]
    mova                  xm10, [ytop0q+32]
    mova                   xm2, [ytop0q+48]
    mova                   xm4, [ytopaq+32]
    mova                   xm6, [ytopaq+48]
    movu                   xm5, [utopq+16]
    vinserti128             m4, [ytop1q+32], 1
    vinserti128             m6, [ytop1q+48], 1
    vinserti128             m5, [vtopq+16], 1
    palignr               xm11, xm10, xm3, 15
    palignr               xm12, xm2, xm10, 15
    REPX   {pmaddubsw x, xm14}, xm10, xm2
    REPX        {pand x,  m13}, m4, m6
    REPX        {pand x, xm13}, xm11, xm12
    paddw                   m4, m11
    paddw                   m6, m12
    paddw                  m10, m4
    paddw                   m2, m6
    mova                   xm4, [ytop0q]
    movu                    m6, [ytopaq]
    movu                   m12, [ytop1q]
    test                 wpadd, wpadd
    jnz .top.f2.w32.pad
.top.f2.w32.acc:
%ifidn %1, explicit
    paddw                  m10, m2
%else
    vperm2i128              m7, m10, m2, 0x20
    vperm2i128             m10, m2, 0x31
    paddw                  m10, m7              ; L1
%endif
    pshufb                 xm7, xm4, [base+w8Llshuf]
    palignr                xm9, xm3, xm4, 15
    REPX   {pmaddubsw x, xm14}, xm4, xm3        ; c+r 0a/0b
    REPX        {pand x,  m13}, m6, m12         ; t/b 0
    REPX        {pand x, xm13}, xm7, xm9        ; l 0a/0b
    movu                  xm13, [utopq]
    vinserti128            m13, [vtopq], 1
    paddw                   m6, m12             ; t+b 0|1
    paddw                  xm4, xm7
    paddw                  xm3, xm9
    vinserti128             m4, xm3, 1
    paddw                   m4, m6              ; L0
    paddw                   m2, m10, m4
    vextracti128           xm6, m2, 1
%ifidn %1, implicit
    SWAP                    m3, m15
    pcmpeqd                m15, m15
%endif
    pmaddubsw               m9, m5, m15
    pmaddubsw              m12, m13, m15
%ifidn %1, implicit
    SWAP                    m3, m15
%endif
    paddw                   m9, m12
    psrldq                  m3, m9, 8
    paddw                   m3, m9
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm6
%ifidn %1, explicit
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
%else
    SWAP                   m11, m15
    pcmpeqd               xm15, xm15
    jmp .top.w32.sampling
%endif
.top.f2.w32.pad:
    pshufb                  m2, m7
    pshufb                  m5, m8
    cmp                  wpadd, 8
    jb .top.f2.w32.acc
    pshufb                  m2, m10, m9
    pshufb                 m10, m7
    jmp .top.f2.w32.acc
.top.f2.w64:
    mova                   xm2, [ytop0q+0x30]
    mova                   xm3, [ytop0q+0x40]
    mova                   xm4, [ytop0q+0x50]
    mova                   xm5, [ytop0q+0x60]
    mova                   xm6, [ytop0q+0x70]
%ifidn %1, implicit
    psrldq                 m13, m11, 8
    punpcklwd              m11, m13
    sub                    rsp, 0x40
    movu                 [rsp], m11
%endif
    psrlw                  m15, 8
    palignr               xm10, xm3, xm2, 15
    palignr               xm11, xm4, xm3, 15
    palignr               xm12, xm5, xm4, 15
    palignr               xm13, xm6, xm5, 15
    REPX   {pmaddubsw x, xm14}, xm3, xm4, xm5, xm6
    REPX        {pand x, xm15}, xm10, xm11, xm12, xm13
    paddw                  xm3, xm10
    paddw                  xm4, xm11
    paddw                  xm5, xm12
    paddw                  xm6, xm13
    mova                  xm10, [ytopaq+0x40]
    mova                  xm11, [ytopaq+0x50]
    mova                  xm12, [ytopaq+0x60]
    mova                  xm13, [ytopaq+0x70]
    vinserti128            m10, [ytop1q+0x40], 1
    vinserti128            m11, [ytop1q+0x50], 1
    vinserti128            m12, [ytop1q+0x60], 1
    vinserti128            m13, [ytop1q+0x70], 1
    REPX         {pand x, m15}, m10, m11, m12, m13
    paddw                   m3, m10
    paddw                   m4, m11
    paddw                   m5, m12
    paddw                   m6, m13
    mova                  xm10, [utopq+32]
    mova                  xm11, [utopq+48]
    vinserti128            m10, [vtopq+32], 1
    vinserti128            m11, [vtopq+48], 1
    test                 wpadd, wpadd
    jnz .top.f2.w64.pad
.top.f2.w64.acc:
    REPX         {pslld x, 16}, m4, m6
    pblendw                 m3, m4, 0xaa            ; EF
    pblendw                 m5, m6, 0xaa            ; GH
    psllw                  m11, 8
    pblendvb               m10, m11, m10, m15
%ifidn %1, implicit
    vperm2i128              m4, m3, m5, 0x20        ; EF GH l+c+r+t
    vperm2i128              m6, m3, m5, 0x31        ; EF GH b
    movu            [rsp+0x20], m10
%endif
    paddw                   m3, m5
    pcmpeqw                m15, m15
    pmaddubsw              m10, m15
    psrlw                  m15, 8
%ifidn %1, implicit
    paddw                   m4, m6
    SWAP                    m9, m4
%endif
    mova                   xm4, [ytop0q+0x00]
    mova                   xm5, [ytop0q+0x10]
    mova                   xm6, [ytop0q+0x20]
; m2=lD m3=ldc m4=lA m5=lB m6=lC m8=pad m9=lEFGH m10=cdc m14=flt m15=0xffff0000
; m7 m11 m12 m13
    pslldq                xm11, xm4, 15
    palignr               xm11, xm4, xm11, 15
    palignr               xm12, xm5, xm4, 13
    palignr               xm13, xm6, xm5, 15
    palignr                xm7, xm2, xm6, 13
    REPX        {pslld x, 16}, xm5, xm2
    pblendw               xm11, xm12, 0xaa              ; AB l
    pblendw               xm13, xm7, 0xaa               ; CD l
    pblendw                xm4, xm5, 0xaa
    pblendw                xm6, xm2, 0xaa
    REPX   {pmaddubsw x, xm14}, xm4, xm6                ; AB CD c+r
    REPX        {pand x, xm15}, xm11, xm13
%ifidn %1, implicit
    SWAP                    m5, m9
%endif
    mova                   xm9, [ytopaq+0x00]
    movu                  xm12, [ytopaq+0x0e]
    mova                   xm7, [ytop1q+0x00]
    movu                   xm2, [ytop1q+0x0e]
    vinserti128             m9, [ytopaq+0x20], 1
    vinserti128            m12, [ytopaq+0x2e], 1
    vinserti128             m7, [ytop1q+0x20], 1
    vinserti128             m2, [ytop1q+0x2e], 1
    paddw                  xm4, xm11
    paddw                  xm6, xm13
%ifidn %1, explicit
    paddw                  xm4, xm6
%else
    vinserti128             m4, xm6, 1          ; AB CD l+c+r
%endif
    mova                  xm13, [utopq+ 0]
    movu                   xm6, [utopq+15]
    vinserti128            m13, [vtopq+ 0], 1
    vinserti128             m6, [vtopq+15], 1
%ifidn %1, explicit
    paddw                   m3, m4
%endif
    pblendw                 m9, m12, 0xaa
    pblendw                 m7, m2, 0xaa
%ifidn %1, implicit
    vbroadcasti128          m2, [t64f1smplCshuf]
    movu                   m12, [rsp+0x20]
%endif
    REPX         {pand x, m15}, m9, m7
    paddw                   m9, m7              ; AB CD t+b
%ifidn %1, explicit
    paddw                   m9, m3
%else
    SWAP                    m9, m4
    paddw                   m4, m9
    paddw                   m9, m3, m4
    psllq                   m5, 32
%endif
    pblendvb               m13, m6, m13, m15
    pcmpeqw                m15, m15
    pmaddubsw               m3, m13, m15
    vextracti128          xm11, m9, 1
    paddw                  m10, m3
    psrldq                  m6, m10, 8
    paddw                   m6, m10
    vpermq                  m3, m6, q3220
%ifidn %1, implicit
    ; chroma prep start                     ;  .  8  4  4  .  8  4  4
    pshufb                 m13, m2          ;  0  8  4 12 16 24 20 28
    pshufb                 m12, m2          ; 32 40 36 44 48 56 52 60
    punpckldq              m10, m13, m12    ;  0  8 32 40  4 12 36 44
    punpckhdq              m13, m12         ; 16 24 48 56 20 28 52 60
    ; chroma prep end
    SWAP                    m4, m5
    vpblendd                m4, m5, 0x55    ; A0B0E0F0A4B4E4F4 C0D0G0H0C4D4G4H4
    pshufd                  m5, [rsp], q2200;  0  8 32 40  4 12 36 44  16 24 48 56 20 28 52 60
    add                    rsp, 0x40        ;              x  x  x  x               x  x  x  x
    psrlw                   m4, 3           ;     x     x                  x     x
%endif                                      ; we need 4 12 20 28 36 44 52 60 or 8 24 40 56
    paddw                  xm2, xm9, xm11
%ifidn %1, explicit
    psrlq                  xm7, xm3, 32
    paddw                  xm3, xm7
%else
    REPX          {pand x, m5}, m4, m10, m13    ; x, y0 y1
    psrldq                  m5, m4, 8
    psrldq                  m7, m10, 8
    psrldq                  m9, m13, 8
    por                     m4, m5
    por                     m7, m10
    por                     m9, m13
    vpermq                  m4, m4, q2020
    punpcklqdq              m7, m9
    pmaddwd                xm5, xm4, xm4        ; xx
    pmaddwd                 m6, m4, m7          ; xy0 xy1
    psrldq                 xm9, xm4, 8
    vextracti128          xm10, m7, 1
    psrldq                xm12, xm5, 8
    vextracti128          xm13, m6, 1
    paddw                  xm4, xm9
    phaddw                 xm7, xm10
    paddd                  xm5, xm12
    phaddd                 xm6, xm13
    paddw                 xm10, xm4, [rsp+0x00]
    paddw                 xm11, xm7, [rsp+0x10]
    paddd                 xm12, xm5, [rsp+0x20]
    paddd                 xm13, xm6, [rsp+0x30]
%endif
    pcmpeqw               xm15, xm15
    jmp .acc_dc
.top.f2.w64.pad:
    pshufb                  m6, m7
    pshufb                 m11, m8
    cmp                  wpadd, 8
    jb .top.f2.w64.acc
    pshufb                  m6, m5, m9
    pshufb                  m5, m7
    cmp                  wpadd, 16
    jb .top.f2.w64.acc
    REPX    {pshufb x, m4, m9}, m5, m6
    pshufb                  m4, m7
    pshufb                 m10, m8
    psrldq                 m11, m10, 15
    pxor                   m12, m12
    pshufb                 m11, m12
    cmp                  wpadd, 24
    jb .top.f2.w64.acc
    REPX    {pshufb x, m3, m9}, m4, m5, m6
    pshufb                  m3, m7
    jmp .top.f2.w64.acc

 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, flags, tbl, flt, cstride
.no_edge:
%ifidn %1, implicit
    movd                  xm12, r10d
    movd                  xm13, r11d
    lea                   tblq, [cfl_%1_420_8bpc_avx2_table]
    mov                   fltd, flagsd
    and                   fltd, 0x3             ; filter_type
    vpbroadcastd           m14, [base+pb_flt0+fltq*4]
    lea                  hpadd, [hpadq*4]
    lea                   fltd, [fltq*5]
    lea                   fltq, [fltq*4+tblq]
    vbroadcasti128          m8, [base+pb_0to15]
    mova                    m7, m8
    mova                   xm6, xm8
    shl                  wpadd, 2
    jz .no_edge.no_pad
    ; gen right edge extend
    mov                    t0d, wpadd
    and                    t0d, 15
    neg                     t0
    lea                    t0d, [16+t0-1]
    movd                   xm5, t0d
    vpbroadcastb            m5, xm5
    pminub                  m8, m5
.no_edge.no_pad:
%endif
    pxor                  xm15, xm15
    vpbroadcastd            m0, [base+pw_1024]
    vpbroadcastd            m1, [base+pw_128]
%ifidn %1, explicit
    jmp .extract_alphas
%else
    vpbroadcastw           m12, xm12
    vpbroadcastw           m13, xm13
    jmp .pred_uv
%endif
 INIT_XMM avx2
.no_top:
    test                flagsb, 8           ; have_left
    jz .no_edge
    pxor                    m2, m2
    pxor                    m3, m3
%ifidn %1, implicit
    jmp .acc_dc.skip_top_sampling_wle8
.acc_dc.skip_top_sampling:
    movu                  xm10, [rsp+0x00]
    movu                  xm12, [rsp+0x20]
    movu                  xm13, [rsp+0x30]
.acc_dc.skip_top_sampling_wle8:
    movu                  xm11, [rsp+0x10]
%endif
.acc_dc:
 DECLARE_REG_TMP 10, 11, 12
%ifidn %1, implicit
%define flagsm mem_flags
%endif
    mov                 flagsd, flagsm
    psrlw                   m7, m15, 15
    paddw                   m0, m2          ; 0xFF*64
    psubw                   m1, m3
    cmp                     wd, hd
    cmovnb                 t0d, wd
    cmovb                  t0d, hd
    psrldq                  m2, m0, 8
    paddw                   m0, m2          ; 0xFF*128 = 0x7F80
%ifidn %1, implicit
    psrlq                   m3, m1, 32
    paddw                   m1, m3
%endif
    pmaddwd                 m0, m7          ; 0xFF*256 = 0xFF00
    pmaddwd                 m1, m7
    psrlq                   m3, m0, 32
    paddd                   m0, m3          ; 0xFF*512 = 0x1FE00
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, flags, tbl, flt, cstride
 DECLARE_REG_TMP 10, 11, 12, 13
    xor                    t0d, t0d
    xor                    t1d, t1d
    test                flagsb, 0x4         ; have_top
    cmovnz                 t0d, wd
    test                flagsb, 0x8         ; have_left
    cmovnz                 t1d, hd
    mov                    t2d, t0d
    or                     t2d, t1d
    jp .div_dc.non_pow2_scale
    mov                    t3d, 32
    cmp                    t2d, 64
    cmove                  t2d, t3d
    test                   t0d, t1d
    setnz                  t0b
    setz                   t3b
    tzcnt                  t1d, t2d
    shrx                   t2d, t2d, t3d
    add                    t1d, t0d
    movd                    m2, t2d
    movd                    m3, t1d
    pshufd                  m4, m2, q0000
    paddd                   m0, m2
    paddd                   m1, m4
    psrld                   m0, m3
    psrld                   m1, m3
    jmp .div_dc.end
.div_dc.non_pow2_scale:
    mov                    t2d, 5
    cmp                     wd, hd
    cmovnb                 t0d, wd          ; bigger dim
    cmovnb                 t1d, hd          ; smaller dim (rem)
    cmovb                  t0d, hd
    cmovb                  t1d, wd
    tzcnt                  t0d, t0d         ; shift (rng=2-5)
    cmp                    t0d, t2d
    cmovnb                 t0d, t2d
    mov                    t2d, 7
    sub                    t2d, t0d
    shlx                   t1d, t1d, t2d    ; rem << (7 - shift)
    ; Shifting div_recip by t2-1 allows us to use pmulhrsw,
    ; because the rounding shift ranges from 11 to 14 and is
    ; given by sh = log2(npx) + 9.
    ; t2 is 7-log2(npx), and we must scale our coeff by
    ; pmulhrsw_sh - sh (15-[11;14]=[1;4]) to use the instruction:
    ; = 15-(log2(npx)+9) = 15-9-log2(npx)
    ; = 6-log2(npx) = 7-log2(npx)-1
    ; /!\ But the DC can be up to 1FF00h and pmulhrsw operates
    ; on signed words, so subtract 8000h and handle high word
    ; separately:
    lea                    t3d, [t2-1]
    lea                     t0, [div_recip]
    shlx                   t3d, [t0+t1*2], t3d
    shlx                   t2d, [t0+t1*2], t2d
    psllw                   m2, m7, 15
    pcmpeqw                 m7, m0
    movd                    m3, t3d
    movd                    m5, t2d
    psubw                   m0, m2
    psrld                   m7, 16
    pshufd                  m4, m3, q0000
    pand                    m5, m7
    pmulhrsw                m0, m3
    pmulhrsw                m1, m4
    paddw                   m3, m5
    paddw                   m0, m3
.div_dc.end:
    vpbroadcastw          ymm0, m0
    pshufb                  m1, [base+dcCshuf]
    vinserti128           ymm1, m1, 1
%ifidn %1, implicit
    psrld                   m7, m15, 16
%endif
    pxor                   m15, m15

%ifidn %1, implicit
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, ntop, tbl, flt, cstride, nleft
%define hpadm  stk_hpad
%define nleftm stk_nleft
%define ntopm  stk_ntop
    mov                  ntopd, ntopm
    mov                 nleftd, nleftm
    phaddw                 m10, m11
    phaddd                 m12, m13
    psrld                   m4, m10, 16
    paddw                  m10, m4
    pand                   m10, m7
    pshufd                  m2, m10, q0000
    pmaddwd                 m2, m10
    mov                    t1d, 3
    test                 ntopd, nleftd
    cmovnz                 t0d, t1d         ; t0 = nleft
    or                     t0d, ntopd
    movd                    m3, t0d
    psrld                   m2, m3
    psubd                  m12, m2
    pcmpeqd                m11, m12, m15
    pabsd                  m13, m12
    vpbroadcastd            m7, [base+pd_511]
    vpbroadcastd           m11, [base+pd_18]
    cvtdq2ps                m2, m13
    psrld                   m2, 23
    psrld                  m10, m7, 2       ; pd_127
    psrld                   m9, m7, 8       ; pd_1
    psrld                   m6, m7, 6       ; pd_7
    psubd                   m2, m10         ; sh
    vpsllvd                 m3, m9, m2      ; 1 << sh
    psubd                   m4, m13, m3     ; e_d
    vpblendd               m13, m4, 0x1
    pcmpgtd                 m5, m2, m6
    psrld                   m3, 8           ; 1 << (sh - 8)
    psubd                   m4, m2, m6      ; sh - 7
    psubd                   m6, m2          ; 7 - sh
    paddd                   m3, m13         ; e_d + 1 << (sh - 8)
    vpsllvd                m13, m6          ; f sh <= 7
    vpsrlvd                 m3, m4          ; f sh > 7
    pand                    m3, m5
    pandn                   m5, m13
    por                     m3, m5          ; f
    lea                     t0, [div_recip]
    movd                   t1d, m3
    pmovzxwd                m4, [t0+t1*2]
    pshufd                  m4, m4, q0000
    pmulld                  m4, m3          ; div_recip[f_d] * f_n
    pslld                   m9, 3           ; pd_8
    pshufd                  m3, m2, q0000
    psubd                   m3, m2          ; sa
    paddd                   m3, m9          ; s0 = sd - sn - 8 + 16
    pcmpgtd                 m5, m11, m3
    pcmpgtd                 m6, m15, m3
    vpsrlvd                 m4, m3
    pand                    m4, m5
    pand                    m3, m6, m7
    pandn                   m6, m4
    por                     m3, m6
    pminud                  m3, m7
    psignd                  m3, m12
    psrldq                 m12, m3, 8
    psrldq                 m13, m3, 12
    mov                  hpadd, hpadm
    add                    rsp, %%stksz+3*4
%endif
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, au, tbl, flt, cstride, av
%ifidn %1, explicit
.extract_alphas:
%define flagsd aud
    mov                    avd, flagsd
    and                    aud, 0xf800          ; alpha u
;   jz .pred_v ; todo see whether u/v paths are worth it
    and                    avd, 0xf8000000      ; alpha v
;   jz .pred_u
    sar                    auw, 6
    sar                    avd, 22
    movd                   m12, aud
    movd                   m13, avd
%endif
 INIT_YMM avx2
    vpbroadcastw           m12, xm12
    vpbroadcastw           m13, xm13

.pred_uv:
 DEFINE_ARGS ystride3, ystride, wpad, hpad, w, h, cstride3, tbl, flt, cstride, \
             ysrc, udst, vdst, _, _
 DECLARE_REG_TMP 0, 14, 13, 8, 7
    mov                  ysrcq, [r0+24]
    mov                  udstq, [r0+32]
    mov                  vdstq, [r0+40]
    sub                     hd, hpadd
    lea              cstride3q, [cstrideq*3]
    tzcnt                  t0d, wd
    movsxd                  t2, [tblq+120+t0*4]             ; pred_uv
    movsxd                  t3, [fltq+60+t0*4]              ; luma filter
    add                     t2, tblq
    add                     t3, tblq
    SWAP                   m11, m8
    pcmpgtw                 m8, m15, m12
    pcmpgtw                 m9, m15, m13
    pabsw                  m12, m12
    pabsw                  m13, m13
    vpermq                 m10, m1, q1111
    vpermq                  m1, m1, q0000
    jmp                     t2

.pred_uv.w4:
    lea              ystride3q, [ystrideq*3]
.pred_uv.w4.loop:
    call                    t3
    vextracti128           xm3, m2, 1
    movd    [udstq+cstrideq*0], xm2
    pextrd  [udstq+cstrideq*1], xm2, 1
    pextrd  [vdstq+cstrideq*0], xm2, 2
    pextrd  [vdstq+cstrideq*1], xm2, 3
    movd    [udstq+cstrideq*2], xm3
    pextrd  [udstq+cstride3q ], xm3, 1
    pextrd  [vdstq+cstrideq*2], xm3, 2
    pextrd  [vdstq+cstride3q ], xm3, 3
    lea                  ysrcq, [ysrcq+ystrideq*4]
    lea                  udstq, [udstq+cstrideq*4]
    lea                  vdstq, [vdstq+cstrideq*4]
    sub                     hd, 4
    jg .pred_uv.w4.loop
    test                 hpadd, hpadd
    jz .ret
    pshufd                 xm3, xm3, q3231
.pred_uv.w4.hpad:
    movd    [udstq+cstrideq*0], xm3
    pextrd  [vdstq+cstrideq*0], xm3, 1
    movd    [udstq+cstrideq*1], xm3
    pextrd  [vdstq+cstrideq*1], xm3, 1
    movd    [udstq+cstrideq*2], xm3
    pextrd  [vdstq+cstrideq*2], xm3, 1
    movd    [udstq+cstride3q ], xm3
    pextrd  [vdstq+cstride3q ], xm3, 1
    lea                  udstq, [udstq+cstrideq*4]
    lea                  vdstq, [vdstq+cstrideq*4]
    sub                  hpadd, 4
    jg .pred_uv.w4.hpad
    jmp .ret
.pred_uv.w8:
    lea              ystride3q, [ystrideq*3]
.pred_uv.w8.loop:
    call                    t3
    vextracti128           xm3, m2, 1
    movq    [udstq+cstrideq*0], xm2
    movhps  [vdstq+cstrideq*0], xm2
    movq    [udstq+cstrideq*1], xm3
    movhps  [vdstq+cstrideq*1], xm3
    lea                  ysrcq, [ysrcq+ystrideq*4]
    lea                  udstq, [udstq+cstrideq*2]
    lea                  vdstq, [vdstq+cstrideq*2]
    sub                     hd, 2
    jg .pred_uv.w8.loop
    test                 hpadd, hpadd
    jz .ret
.pred_uv.w8.hpad:
    movq    [udstq+cstrideq*0], xm3
    movhps  [vdstq+cstrideq*0], xm3
    movq    [udstq+cstrideq*1], xm3
    movhps  [vdstq+cstrideq*1], xm3
    movq    [udstq+cstrideq*2], xm3
    movhps  [vdstq+cstrideq*2], xm3
    movq    [udstq+cstride3q ], xm3
    movhps  [vdstq+cstride3q ], xm3
    lea                  udstq, [udstq+cstrideq*4]
    lea                  vdstq, [vdstq+cstrideq*4]
    sub                  hpadd, 4
    jg .pred_uv.w8.hpad
    jmp .ret
.pred_uv.w16:
    call                    t3
    vpermq                  m2, m2, q3120
    pshufb                  m2, m11
    movu               [udstq], xm2
    vextracti128       [vdstq], m2, 1
    lea                  ysrcq, [ysrcq+ystrideq*2]
    add                  udstq, cstrideq
    add                  vdstq, cstrideq
    dec                     hd
    jg .pred_uv.w16
    test                 hpadd, hpadd
    jz .ret
.pred_uv.w16.hpad:
    movu         [udstq+cstrideq*0], xm2
    vextracti128 [vdstq+cstrideq*0], m2, 1
    movu         [udstq+cstrideq*1], xm2
    vextracti128 [vdstq+cstrideq*1], m2, 1
    movu         [udstq+cstrideq*2], xm2
    vextracti128 [vdstq+cstrideq*2], m2, 1
    movu         [udstq+cstride3q ], xm2
    vextracti128 [vdstq+cstride3q ], m2, 1
    lea                  udstq, [udstq+cstrideq*4]
    lea                  vdstq, [vdstq+cstrideq*4]
    sub                  hpadd, 4
    jg .pred_uv.w16.hpad
    jmp .ret
.pred_uv.w32.wpad:
    pshufb                  m2, m11
    movu         [udstq+t0-16], xm2
    vextracti128 [vdstq+t0-16], m2, 1
    mov                     t3, t4
    cmp                  wpadd, 15
    jb .pred_uv.w32.next_row
    psrldq                  m2, 15
    pxor                    m7, m7
    pshufb                  m2, m7
    movu            [udstq+t0], xm2
    vextracti128    [vdstq+t0], m2, 1
    jmp .pred_uv.w32.next_row
.pred_uv.w32:
    xor                    t1d, t1d
    xor                    t2d, t2d
    xor                    t0d, t0d
    test                 wpadd, wpadd
    setnz                  t1b
    add                  wpadd, t1d
    mov                     t1, ysrcq
    sub                     wd, wpadd
;   mova                   m11, m8
.pred_uv.w32.loop:
    call                    t3
    vpermq                  m2, m2, q3120
    add                  ysrcq, 32
    add                    t0d, 16
    cmp                    t0d, wd
    ja .pred_uv.w32.wpad
    movu         [udstq+t0-16], xm2
    vextracti128 [vdstq+t0-16], m2, 1
    jb .pred_uv.w32.loop
.pred_uv.w32.next_row:
    lea                     t1, [t1+ystrideq*2]
    add                  udstq, cstrideq
    add                  vdstq, cstrideq
    mov                  ysrcq, t1
    xor                    t0d, t0d
    dec                     hd
    jg .pred_uv.w32.loop
    test                 hpadd, hpadd
    jz .ret
    mov                     t0, cstrideq
    neg                     t0
    movu                    m0, [udstq+t0]
    movu                    m1, [vdstq+t0]
    movu                    m2, [udstq+t0+32]
    movu                    m3, [vdstq+t0+32]
.pred_uv.w32.hpad:
    movu    [udstq+cstrideq*0], m0
    movu    [vdstq+cstrideq*0], m1
    movu    [udstq+cstrideq*1], m0
    movu    [vdstq+cstrideq*1], m1
    movu    [udstq+cstrideq*2], m0
    movu    [vdstq+cstrideq*2], m1
    movu    [udstq+cstride3q ], m0
    movu    [vdstq+cstride3q ], m1
    cmp                     wd, 35
    jb .pred_uv.w32.hpad.loop
    movu [udstq+cstrideq*0+32], m2
    movu [vdstq+cstrideq*0+32], m3
    movu [udstq+cstrideq*1+32], m2
    movu [vdstq+cstrideq*1+32], m3
    movu [udstq+cstrideq*2+32], m2
    movu [vdstq+cstrideq*2+32], m3
    movu [udstq+cstride3q +32], m2
    movu [vdstq+cstride3q +32], m3
.pred_uv.w32.hpad.loop:
    lea                  udstq, [udstq+cstrideq*4]
    lea                  vdstq, [vdstq+cstrideq*4]
    sub                  hpadd, 4
    jg .pred_uv.w32.hpad
.ret:
    RET

.blk.f0.w4:
    movq                   xm3, [ysrcq+ystrideq*0]
    movq                   xm4, [ysrcq+ystrideq*1]
    movhps                 xm3, [ysrcq+ystrideq*2]
    movhps                 xm4, [ysrcq+ystride3q ]
    lea                  ysrcq, [ysrcq+ystrideq*4]
    vinserti128             m3, [ysrcq+ystrideq*0], 1
    vpbroadcastq            m5, [ysrcq+ystrideq*2]
    vinserti128             m4, [ysrcq+ystrideq*1], 1
    vpbroadcastq            m6, [ysrcq+ystride3q ]
    vpblendd                m3, m5, 0xc0
    vpblendd                m4, m6, 0xc0
    F0
.blk.f0.w8:
    movu                   xm3, [ysrcq+ystrideq*0]
    movu                   xm4, [ysrcq+ystrideq*1]
    vinserti128             m3, [ysrcq+ystrideq*2], 1
    vinserti128             m4, [ysrcq+ystride3q ], 1
    F0
.blk.f0.w32.prep:
    lea                     t4, [.blk.f0.w16]
    mov                     t3, t4
.blk.f0.w16:
    movu                    m3, [ysrcq+ystrideq*0]
    movu                    m4, [ysrcq+ystrideq*1]
    F0

.blk.f1.w4.prep:
    vbroadcasti128         m11, [base+w4Llshuf]
    lea                     t3, [.blk.f1.w4]
.blk.f1.w4:
    movq                   xm3, [ysrcq+ystrideq*0]
    movq                   xm4, [ysrcq+ystrideq*1]
    movhps                 xm3, [ysrcq+ystrideq*2]
    movhps                 xm4, [ysrcq+ystride3q ]
    lea                  ysrcq, [ysrcq+ystrideq*4]
    vinserti128             m3, [ysrcq+ystrideq*0], 1
    vpbroadcastq            m5, [ysrcq+ystrideq*2]
    vinserti128             m4, [ysrcq+ystrideq*1], 1
    vpbroadcastq            m6, [ysrcq+ystride3q ]
    vpblendd                m3, m5, 0xc0
    vpblendd                m4, m6, 0xc0
    F1
.blk.f1.w8.prep:
    vbroadcasti128         m11, [base+w8Llshuf]
    lea                     t3, [.blk.f1.w8]
.blk.f1.w8:
    movu                   xm3, [ysrcq+ystrideq*0]
    movu                   xm4, [ysrcq+ystrideq*1]
    vinserti128             m3, [ysrcq+ystrideq*2], 1
    vinserti128             m4, [ysrcq+ystride3q ], 1
    F1
.blk.f1.w16:
    vbroadcasti128          m3, [ysrcq+ystrideq*0+ 0]
    vbroadcasti128          m5, [ysrcq+ystrideq*0+16]
    vbroadcasti128          m6, [ysrcq+ystrideq*1+ 0]
    vbroadcasti128          m7, [ysrcq+ystrideq*1+16]
    pshufb                 xm2, xm3, xm15
    palignr                 m4, m5, m3, 15      ; l0 high
    palignr                xm2, xm3, xm2, 15    ; l0 low
    vpblendd                m3, m5, 0xf0        ; c0/r0
    vpblendd                m2, m4, 0xf0        ; l0
    pshufb                 xm4, xm6, xm15
    palignr                 m5, m7, m6, 15      ; l1 high
    palignr                xm4, xm6, xm4, 15    ; l1 low
    vpblendd                m6, m7, 0xf0        ; c1/r1
    vpblendd                m4, m5, 0xf0        ; l1
    REPX    {pmaddubsw x, m14}, m3, m6
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    REPX          {pand x, m7}, m2, m4
    paddw                   m2, m4
    paddw                   m3, m6
    paddw                   m3, m2
    jmp .pred
.blk.f1.w32.prep0:
    movd                   xm2, [ysrcq+ystrideq*0]
    movd                   xm3, [ysrcq+ystrideq*1]
    mov                     t4, t3
    lea                     t3, [.blk.f1.w32.prep1]
    punpcklbw             xm15, xm3, xm2
    pslldq                xm15, 14
    jmp .blk.f1.w32
.blk.f1.w32.prep1:
    mov                     t3, t4
.blk.f1.w32:
    vbroadcasti128          m3, [ysrcq+ystrideq*0+ 0]
    vbroadcasti128          m6, [ysrcq+ystrideq*1+ 0]
    vbroadcasti128          m5, [ysrcq+ystrideq*0+16]
    vbroadcasti128          m7, [ysrcq+ystrideq*1+16]
    palignr                xm2, xm3, xm15, 15   ; l0 low
    palignr                 m4, m5, m3, 15      ; l0 high
    vpblendd                m3, m5, 0xf0        ; c0/r0
    vpblendd                m2, m4, 0xf0        ; l0
    psllw                 xm15, 8
    palignr                xm4, xm6, xm15, 15   ; l1 low
    punpckhbw             xm15, xm7, xm5
    palignr                 m5, m7, m6, 15      ; l1 high
    vpblendd                m6, m7, 0xf0        ; c1/r1
    vpblendd                m4, m5, 0xf0        ; l1
    REPX    {pmaddubsw x, m14}, m3, m6
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    REPX          {pand x, m7}, m2, m4
    paddw                   m2, m4
    paddw                   m3, m6
    paddw                   m3, m2
    jmp .pred

.blk.f2.w4.prep:
    vbroadcasti128         m11, [base+w4Llshuf]
    lea                     t3, [.blk.f2.w4.start]
    xor                    t4d, t4d
.blk.f2.w4.h32:
    movq                  xm15, [ysrcq+ystrideq*0]
    jmp .blk.f2.w4
.blk.f2.w4.start:
    add                    t4d, 0x20000000
    jc .blk.f2.w4.h32
.blk.f2.w4:
    lea                     t2, [ysrcq+ystrideq*4]
    vpbroadcastq            m6, [ysrcq+ystride3q ]
    vpbroadcastq            m2, [t2   +ystrideq*1]
    movq                   xm3, [ysrcq+ystrideq*0]
    vinserti128             m2, [ysrcq+ystrideq*1], 0
    movhps                 xm3, [ysrcq+ystrideq*2]
    vpbroadcastq            m5, [t2   +ystrideq*2]
    vinserti128             m3, [t2   +ystrideq*0], 1
    mov                  ysrcq, t2
    vpblendd                m6, m15, 0x3      ;-1 3 3 3
    vpbroadcastq           m15, [t2   +ystride3q ]
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    vpblendd                m4, m2, m6, 0xc   ; 1 3 5 5
    punpcklqdq              m6, m2            ;-1 1 3 5 ; t
    vpblendd                m3, m5, 0xc0                ; c/r
    vpblendd                m4, m15, 0xc0               ; b
    F2
.blk.f2.w8.prep:
    vbroadcasti128         m11, [base+w8Llshuf]
    lea                     t3, [.blk.f2.w8.start]
    xor                    t4d, t4d
.blk.f2.w8.h32:
    movu                  xm15, [ysrcq+ystrideq*0]
    jmp .blk.f2.w8
.blk.f2.w8.start:
    add                    t4d, 0x10000000
    jc .blk.f2.w8.h32
.blk.f2.w8:
    mova                   xm6, xm15
    movu                   xm3, [ysrcq+ystrideq*0]
    vbroadcasti128          m4, [ysrcq+ystrideq*1]
    vbroadcasti128         m15, [ysrcq+ystride3q ]
    vinserti128             m3, [ysrcq+ystrideq*2], 1
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    vpblendd                m6, m4, 0xf0    ; t
    vpblendd                m4, m15, 0xf0   ; b
    F2
.blk.f2.w16.prep:
    lea                     t3, [.blk.f2.w16.start]
    xor                    t4d, t4d
.blk.f2.w16.h32:
    movu                   m15, [ysrcq+ystrideq*0]
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    pand                   m15, m7
    jmp .blk.f2.w16
.blk.f2.w16.start:
    add                    t4d, 0x08000000
    jc .blk.f2.w16.h32
.blk.f2.w16:
    vbroadcasti128          m3, [ysrcq+ystrideq*0+ 0]
    vbroadcasti128          m2, [ysrcq+ystrideq*0+16]
    movu                    m6, [ysrcq+ystrideq*1]      ; b
    pslldq                 xm5, xm3, 15
    palignr                 m4, m2, m3, 15
    palignr                xm5, xm3, xm5, 15
    vpblendd                m3, m2, 0xf0                ; c/r
    vpblendd                m5, m4, 0xf0                ; l
    pmaddubsw               m3, m14
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    REPX          {pand x, m7}, m6, m5
    paddw                  m15, m6
    paddw                   m5, m15
    paddw                   m3, m5
    mova                   m15, m6                      ; t
    jmp .pred
.blk.f2.w32.prep:
    lea                     t3, [.blk.f2.w32.right]
    lea                     t4, [.blk.f2.w32.left]
    jmp .blk.f2.w32.prep0
.blk.f2.w64.prep:
    lea                     t3, [.blk.f2.w32.right]
    lea                     t4, [.blk.f2.w64.left2]
.blk.f2.w32.prep0:
%if UNIX64
    mov                [rsp-4], hd
%else
 %define hm [rsp+0x120]
    sub                     hm, hpadd
%endif
    movd                  xm15, [ysrcq+ystrideq*0]
    pslldq                xm15, 15
    xor                    t2d, t2d
    jmp .blk.f2.w32
.blk.f2.w32.left:
    movd                  xm15, [ysrcq+ystrideq*0]
    pslldq                xm15, 15
%if UNIX64
    mov                    t3d, [rsp-4]
%else
    mov                    t3d, hm
%endif
    sub                    t3d, hd
    xor                    t2d, t2d
    cmp                    t3d, 32
    cmovne                  t2, ystrideq
    neg                     t2
    lea                     t3, [.blk.f2.w32.right]
    lea                     t4, [.blk.f2.w32.left]
    jmp .blk.f2.w32
.blk.f2.w64.left1:
    movd                  xm15, [ysrcq+ystrideq*0]
    pslldq                xm15, 15
%if UNIX64
    mov                    t3d, [rsp-4]
%else
    mov                    t3d, hm
%endif
    sub                    t3d, hd
    xor                    t2d, t2d
    cmp                    t3d, 32
    cmovne                  t2, ystrideq
    neg                     t2
    lea                     t3, [.blk.f2.w32.right]
    lea                     t4, [.blk.f2.w64.left2]
    jmp .blk.f2.w32
.blk.f2.w64.left2:
    movd                  xm15, [ysrcq+ystrideq*0]
    pslldq                xm15, 15
    lea                     t3, [.blk.f2.w32.right]
    lea                     t4, [.blk.f2.w64.left1]
    jmp .blk.f2.w32
.blk.f2.w32.right:
    mov                     t3, t4
.blk.f2.w32:
    vbroadcasti128          m3, [ysrcq+ystrideq*0+ 0]
    vbroadcasti128          m2, [ysrcq+ystrideq*0+16]
    movu                    m6, [ysrcq+ystrideq*1]      ; b
    palignr                 m4, m2, m3, 15
    palignr                xm5, xm3, xm15, 15           ; l low
    mova                  xm15, xm2
    vpblendd                m3, m2, 0xf0                ; c/r
    vpblendd                m5, m4, 0xf0                ; l
    movu                    m2, [ysrcq+t2]              ; t
    pmaddubsw               m3, m14
    pcmpeqw                 m7, m7
    psrlw                   m7, 8
    REPX          {pand x, m7}, m6, m5, m2
    paddw                   m6, m5
    paddw                   m6, m2
    paddw                   m3, m6

.pred:
    pxor                    m7, m7
    psubw                   m3, m0
    pcmpgtw                 m5, m7, m3
    pabsw                   m3, m3
    psllw                   m3, 4
    pmulhrsw                m2, m3, m12
    pmulhrsw                m3, m13
    pxor                    m4, m5, m8
    pxor                    m5, m9
    psubw                   m6, m7, m2
    psubw                   m7, m3
    pand                    m6, m4
    pand                    m7, m5
    pandn                   m2, m4, m2
    pandn                   m3, m5, m3
    por                     m2, m6
    por                     m3, m7
    paddw                   m2, m1
    paddw                   m3, m10
    packuswb                m2, m3
    ret
%endmacro

CFL_420 explicit
CFL_420 implicit

cglobal cfl_mh_gen_y_420_uniform_8bpc, 4, 15, 16, dst, src, tse, ss, \
                                                  needed_top, needed_left, \
                                                  w, h, flags, \
                                                  nleft, ntop, tbl
 DECLARE_REG_TMP 9, 14, 10, 12
    mov                 flagsd, flagsm
    mov                     hd, hm
    movifnidn      needed_topd, needed_topm
    movifnidn     needed_leftd, needed_leftm
    mov                    t0d, flagsd
    shl                     hd, 5
    lea                     hd, [hq-(1<<5)+flagsq]
    shr                 flagsd, 2
    and                    t0d, flagsd          ; (has_l & dir_l) | (has_t & dir_t)
    mov                    t1d, flagsd
    mov                    t2d, flagsd
    mov                    t3d, t0d
    REPX          {and x, 0x2}, t1d, t0d        ; has_l / has_l & dir_l
    REPX          {and x, 0x1}, t2d, t3d        ; has_t / has_t & dir_t
    add                    t0d, t1d             ; nleft
    sub                   srcq, nleftq
    add                    t2d, t3d             ; ntop
 DECLARE_REG_TMP 13, 14, 8, 12
    lea                   tblq, [cfl_mh_gen_y_420_uniform_8bpc_avx2_top_table]
%define base tblq-cfl_mh_gen_y_420_uniform_8bpc_avx2_top_table
    vpbroadcastd           m14, [base+pb_flt0]
    jz .left.no_top
    sub                   tseq, nleftq
    test                    hb, 0xb             ; flags
    setz                   t3b                  ; !has_l && dir_c
    lea                   tseq, [tseq+t3*2]
    test                flagsb, 0x4             ; is_top_sb_edge
    jnz .tse
    lea                   srcq, [srcq+t3*2]
    cmp            needed_topd, 16
    setge                  t3b
    shr                    t1d, 1
    mov                    r8d, needed_topd
    and                    t1d, t3d             ; if (needed_top >= 16)
    sub                    r8d, t1d             ;   needed_top -= has_l
    mov                    t0d, 31
    lzcnt                  t1d, r8d
    tzcnt                  t2d, r8d
    sub                    t0d, t1d
    cmp                    t0d, t2d
    setne                  t1b
    add                    t0d, t1d
    shlx                    t3, ssq, ntopq
    sub                   srcq, t3
    movsxd                  t0, [tblq+t0*4]
    add                     t0, tblq
    jmp                     t0

.tse:
    xor                    t0d, t0d
.tse.loop:
    movu                    m0, [tseq+t0*2+ 0]
    movu                    m1, [tseq+t0*2+32]
    REPX    {pmaddubsw x, m14}, m0, m1
    REPX          {psrlw x, 2}, m0, m1
    packuswb                m0, m1
    vpermq                  m0, m0, q3120
    mova          [dstq+t0+ 0], m0
    test                 ntopb, 2
    jz .tse.loop.skip_2nd_row
    mova          [dstq+t0+64], m0
.tse.loop.skip_2nd_row:
    add                    t0d, 32
    cmp                    t0d, needed_topd
    jl .tse.loop
    mov                    t1d, 32
    shlx                   t1d, t1d, ntopd
    add                   dstq, t1
    jmp .left

.top.8:
    movu                   xm0, [srcq+ssq*0]
    movu                   xm1, [srcq+ssq*1]
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    paddw                  xm0, xm1
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    movq                [dstq], xm0
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.8
    jmp .left
.top.17:
    movu                    m0, [srcq+ssq*0]
    movu                    m1, [srcq+ssq*1]
    cmp            needed_topd, 17
    jne .top.17.skip_last
    movd                   xm2, [srcq+ssq*0+32]
    movd                   xm3, [srcq+ssq*1+32]
    REPX   {pmaddubsw x, xm14}, xm2, xm3
    paddw                  xm2, xm3
    psrlw                  xm2, 3
.top.17.skip_last:
    REPX    {pmaddubsw x, m14}, m0, m1
    paddw                   m0, m1
    psrlw                   m0, 3
    packuswb                m0, m0
    vpermq                  m0, m0, q3220
    mova             [dstq+ 0], m0
    movd             [dstq+16], xm2
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.17
    jmp .left
.top.33:
    movu                    m0, [srcq+ssq*0+ 0]
    movu                    m1, [srcq+ssq*1+ 0]
    movu                    m2, [srcq+ssq*0+32]
    movu                    m3, [srcq+ssq*1+32]
    cmp            needed_topd, 33
    jne .top.33.skip
    movd                   xm4, [srcq+ssq*0+64]
    movd                   xm5, [srcq+ssq*1+64]
    REPX   {pmaddubsw x, xm14}, xm4, xm5
.top.33.skip:
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3
    paddw                   m0, m1
    paddw                   m2, m3
    paddw                  xm4, xm5
    REPX          {psrlw x, 3}, m0, m2
    psrlw                  xm4, 3
    packuswb                m0, m2
    vpermq                  m0, m0, q3120
    mova                [dstq], m0
    movd             [dstq+32], xm4
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.33
    jmp .left
.top.64:
    movu                    m0, [srcq+ssq*0+0x00]
    movu                    m1, [srcq+ssq*1+0x00]
    movu                    m2, [srcq+ssq*0+0x20]
    movu                    m3, [srcq+ssq*1+0x20]
    movu                    m4, [srcq+ssq*0+0x40]
    movu                    m5, [srcq+ssq*1+0x40]
    movu                    m6, [srcq+ssq*0+0x60]
    movu                    m7, [srcq+ssq*1+0x60]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3, m4, m5, m6, m7
    paddw                   m0, m1
    paddw                   m2, m3
    paddw                   m4, m5
    paddw                   m6, m7
    REPX          {psrlw x, 3}, m0, m2, m4, m6
    packuswb                m0, m2
    packuswb                m4, m6
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.64

 DEFINE_ARGS dst, src, srcl, ss, ss3, needed_left, w, h, ystart, nleft, dstl, tbl
.left:
    lea                   ss3q, [ssq*3]
    shr                 nleftd, 1
    jz .blk.skip_left
.left2:
    xor                ystartd, ystartd
    test                    hb, 0x7             ; flags
 DEFINE_ARGS dst, src, srcl, ss, ss3, needed_left, w, h, ystart, nleft, dstl, tbl
    cmovz              ystartq, ssq             ; !has_t && dir_c
    lea                  srclq, [srcq+ystartq*2]
    movu                   xm8, [base+mh_lshuf1-4+nleftq*4]
    lea                  dstlq, [dstq+32*32]
.left.loop:
    movd                   xm0, [srclq+ssq*0]
    vpbroadcastd           xm2, [srclq+ssq*2]
    movd                   xm1, [srclq+ssq*1]
    vpbroadcastd           xm3, [srclq+ss3q ]
    lea                  srclq, [srclq+ssq*4]
    vpbroadcastd           xm4, [srclq+ssq*0]
    vpbroadcastd           xm6, [srclq+ssq*2]
    vpbroadcastd           xm5, [srclq+ssq*1]
    vpbroadcastd           xm7, [srclq+ss3q ]
    lea                  srclq, [srclq+ssq*4]
    vpblendd               xm0, xm2, 0x2
    vpblendd               xm1, xm3, 0x2
    vpblendd               xm4, xm6, 0x8
    vpblendd               xm5, xm7, 0x8
    vpblendd               xm0, xm4, 0xc
    vpblendd               xm1, xm5, 0xc
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    paddw                  xm0, xm1
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    pshufb                 xm0, xm8
    movq               [dstlq], xm0
    lea                  dstlq, [dstlq+nleftq*4]
    sub           needed_leftd, 4
    jg .left.loop
    lea                   srcq, [srcq+nleftq*2]

.blk:
    lea                   tblq, [base+cfl_mh_gen_y_420_uniform_8bpc_avx2_blk_table]
    tzcnt                   wd, wm
    movsxd                  t0, [tblq+wq*4]
    add                     t0, tblq
    jmp                     t0
.blk.skip_left:
    xor                    t0d, t0d
    test                    hb, 0x13            ; flags
    setz                   t0b
    neg                     t0                  ; restore src ptr post top
    lea                   srcq, [srcq+t0*2]     ; src -= (!itse && dir_c) * 2
    jmp .blk
.left.no_top:
    lea                   ss3q, [ssq*3]
    shr                 nleftd, 1
    jz .blk
    jmp .left2

.blk.w4:
    movq                   xm0, [srcq+ssq*0]
    movq                   xm1, [srcq+ssq*1]
    movhps                 xm0, [srcq+ssq*2]
    movhps                 xm1, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    movq                   xm2, [srcq+ssq*0]
    movq                   xm3, [srcq+ssq*1]
    movhps                 xm2, [srcq+ssq*2]
    movhps                 xm3, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    REPX   {pmaddubsw x, xm14}, xm0, xm1, xm2, xm3
    paddw                  xm0, xm1
    paddw                  xm2, xm3
    REPX          {psrlw x, 3}, xm0, xm2
    packuswb               xm0, xm2
    mova                [dstq], xm0
    add                   dstq, 16
    sub                     hd, 4 << 5
    jge .blk.w4
    jmp .ret
.blk.w8:
    movu                   xm0, [srcq+ssq*0]
    movu                   xm1, [srcq+ssq*1]
    movu                   xm2, [srcq+ssq*2]
    movu                   xm3, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    vinserti128             m0, [srcq+ssq*0], 1
    vinserti128             m1, [srcq+ssq*1], 1
    vinserti128             m2, [srcq+ssq*2], 1
    vinserti128             m3, [srcq+ss3q ], 1
    lea                   srcq, [srcq+ssq*4]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3
    paddw                   m0, m1
    paddw                   m2, m3
    REPX          {psrlw x, 3}, m0, m2
    packuswb                m0, m2
    mova                [dstq], m0
    add                   dstq, 32
    sub                     hd, 4 << 5
    jge .blk.w8
    jmp .ret
.blk.w16:
    movu                    m0, [srcq+ssq*0]
    movu                    m1, [srcq+ssq*1]
    movu                    m2, [srcq+ssq*2]
    movu                    m3, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    movu                    m4, [srcq+ssq*0]
    movu                    m5, [srcq+ssq*1]
    movu                    m6, [srcq+ssq*2]
    movu                    m7, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3, m4, m5, m6, m7
    paddw                   m0, m1
    paddw                   m2, m3
    paddw                   m4, m5
    paddw                   m6, m7
    REPX          {psrlw x, 3}, m0, m2, m4, m6
    packuswb                m0, m2
    packuswb                m4, m6
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    add                   dstq, 64
    sub                     hd, 4 << 5
    jge .blk.w16
    jmp .ret
.blk.w32:
    movu                    m0, [srcq+ssq*0+ 0]
    movu                    m1, [srcq+ssq*1+ 0]
    movu                    m2, [srcq+ssq*0+32]
    movu                    m3, [srcq+ssq*1+32]
    movu                    m4, [srcq+ssq*2+ 0]
    movu                    m5, [srcq+ss3q + 0]
    movu                    m6, [srcq+ssq*2+32]
    movu                    m7, [srcq+ss3q +32]
    lea                   srcq, [srcq+ssq*4]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3, m4, m5, m6, m7
    paddw                   m0, m1
    paddw                   m2, m3
    paddw                   m4, m5
    paddw                   m6, m7
    REPX          {psrlw x, 3}, m0, m2, m4, m6
    packuswb                m0, m2
    packuswb                m4, m6
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    add                   dstq, 64
    sub                     hd, 2 << 5
    jge .blk.w32
    jmp .ret

.ret:
    RET

cglobal cfl_mh_gen_y_420_vstrip_8bpc, 4, 15, 16, dst, src, tse, ss, \
                                                 needed_top, needed_left, \
                                                 w, h, flags, \
                                                 nleft, ntop, tbl
 DECLARE_REG_TMP 9, 14, 10, 12, 13
    mov                 flagsd, flagsm
    mov                     hd, hm
    movifnidn      needed_topd, needed_topm
    movifnidn     needed_leftd, needed_leftm
    xor                    t4d, t4d
    test                flagsb, 0xb
    mov                    t0d, flagsd
    setnz                  t4b                  ; has_l || !dir_c
    shl                     hd, 5
    lea                     hd, [hq-(1<<5)+flagsq]
    shr                 flagsd, 2
    and                    t0d, flagsd          ; (has_l & dir_l) | (has_t & dir_t)
    mov                    t1d, flagsd
    mov                    t2d, flagsd
    mov                    t3d, t0d
    REPX          {and x, 0x2}, t1d, t0d        ; has_l / has_l & dir_l
    REPX          {and x, 0x1}, t2d, t3d        ; has_t / has_t & dir_t
    add                    t0d, t1d             ; nleft
    sub                   srcq, nleftq
    lea                   tblq, [cfl_mh_gen_y_420_vstrip_8bpc_avx2_top_table]
%define base tblq-cfl_mh_gen_y_420_vstrip_8bpc_avx2_top_table
    vpbroadcastd           m14, [base+pb_flt1]
    add                    t2d, t3d             ; ntop
    jz .left.no_top
    cmp                 nleftd, 2
    setne                  t3b                  ; nleft != 1
    and                    t3d, t4d             ; nleft != 1 && (has_l || !dir_c)
    movd                  xm15, t3d
    vbroadcasti128         m13, [base+Llshuf]
    por                    m15, m13
    sub                   tseq, nleftq
    xor                    t4d, 1               ; !has_l && dir_l
    lea                   tseq, [tseq+t4*2]
    test                flagsb, 0x4             ; is_top_sb_edge
    jnz .tse
    lea                   srcq, [srcq+t4*2]
 DECLARE_REG_TMP 13, 14, 8, 12
    mov                    r8d, needed_topd
    cmp            needed_topd, 16
    setge                  t3b
    shr                    t1d, 1
    and                    t3d, t1d             ; if (needed_top >= 16)
    sub                    r8d, t3d             ;   needed_top -= has_l
    mov                    t0d, 31
    lzcnt                  t1d, r8d             ; needed_top
    tzcnt                  t2d, r8d
    sub                    t0d, t1d
    cmp                    t0d, t2d
    setne                  t1b
    add                    t0d, t1d
    shlx                    t3, ssq, ntopq
    sub                   srcq, t3
    movsxd                  t0, [tblq+t0*4]
    add                     t0, tblq
    jmp                     t0

.tse:
    xor                    t0d, t0d
    pcmpeqd               xm13, xm13
    pslldq                xm13, 1
    jmp .tse.start_loop
.tse.loop:
    pand                  xm15, xm13
.tse.start_loop:
    movu                   xm0, [tseq+t0*2+ 0]
    movu                   xm1, [tseq+t0*2+16]
    movu                   xm2, [tseq+t0*2+-1]
    pcmpeqw                xm4, xm4
    psrlw                  xm4, 8
    palignr                xm3, xm1, xm0, 15
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    pshufb                 xm2, xm15
    pand                   xm3, xm4
    paddw                  xm0, xm2
    paddw                  xm1, xm3
    REPX          {psrlw x, 2}, xm0, xm1
    packuswb               xm0, xm1
    mova          [dstq+t0+ 0], xm0
    mova          [dstq+t0+64], xm0
    add                    t0d, 16
    cmp                    t0d, needed_topd
    jl .tse.loop
    mov                    t1d, 32
    shlx                   t1d, t1d, ntopd
    add                   dstq, t1
    jmp .left

.top.4:
    movq                   xm0, [srcq+ssq*0]
    movq                   xm1, [srcq+ssq*1]
    movq                   xm2, [srcq+ssq*0-1]
    movq                   xm3, [srcq+ssq*1-1]
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    REPX      {pshufb x, xm15}, xm2, xm3
    paddw                  xm2, xm3
    paddw                  xm0, xm1
    paddw                  xm0, xm2
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    movd                [dstq], xm0
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.4
    jmp .left
.top.8:
    movu                   xm0, [srcq+ssq*0]
    movu                   xm1, [srcq+ssq*1]
    movu                   xm2, [srcq+ssq*0-1]
    movu                   xm3, [srcq+ssq*1-1]
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    REPX      {pshufb x, xm15}, xm2, xm3
    paddw                  xm0, xm1
    paddw                  xm2, xm3
    paddw                  xm0, xm2
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    movq                [dstq], xm0
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.8
    jmp .left
.top.17:
    movu                    m0, [srcq+ssq*0]
    movu                    m1, [srcq+ssq*1]
    movu                    m2, [srcq+ssq*0-1]
    movu                    m3, [srcq+ssq*1-1]
    cmp            needed_topd, 17
    jne .top.17.skip_last
    movd                   xm4, [srcq+ssq*0+31]
    movd                   xm5, [srcq+ssq*1+31]
    pcmpeqw                xm8, xm8
    psrlw                  xm8, 8
    psrld                  xm6, xm4, 8
    psrld                  xm7, xm5, 8
    REPX   {pmaddubsw x, xm14}, xm6, xm7
    REPX         {pand x, xm8}, xm4, xm5
    paddw                  xm4, xm5
    paddw                  xm6, xm7
    paddw                  xm4, xm6
    psrlw                  xm4, 3
.top.17.skip_last:
    REPX    {pmaddubsw x, m14}, m0, m1
    REPX       {pshufb x, m15}, m2, m3
    paddw                   m2, m3
    paddw                   m0, m1
    paddw                   m0, m2
    psrlw                   m0, 3
    packuswb                m0, m0
    vpermq                  m0, m0, q3220
    mova             [dstq+ 0], xm0
    movd             [dstq+16], xm4
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.17
    jmp .left
.top.33:
    pcmpeqw                m13, m13
    psrlw                  m13, 8
.top.33.loop:
    movu                    m0, [srcq+ssq*0+ 0]
    movu                    m2, [srcq+ssq*1+ 0]
    movu                    m1, [srcq+ssq*0+32]
    movu                    m3, [srcq+ssq*1+32]
    movu                    m8, [srcq+ssq*0+-1]
    movu                    m9, [srcq+ssq*1+-1]
    movu                   m10, [srcq+ssq*0+31]
    movu                   m11, [srcq+ssq*1+31]
    cmp            needed_topd, 33
    jne .top.33.skip_last
    movd                   xm4, [srcq+ssq*0+63]
    movd                   xm5, [srcq+ssq*1+63]
    psrld                  xm6, xm4, 8
    psrld                  xm7, xm5, 8
    REPX   {pmaddubsw x, xm14}, xm6, xm7
    REPX        {pand x, xm13}, xm4, xm5
    paddw                  xm4, xm5
    paddw                  xm6, xm7
    paddw                  xm4, xm6
    psrlw                  xm4, 3
.top.33.skip_last:
    REPX    {pmaddubsw x, m14}, m0, m2, m1, m3
    REPX       {pshufb x, m15}, m8, m9
    REPX         {pand x, m13}, m10, m11
    paddw                   m8, m9
    paddw                  m10, m11
    paddw                   m0, m2
    paddw                   m1, m3
    paddw                   m0, m8
    paddw                   m1, m10
    REPX          {psrlw x, 3}, m0, m1
    packuswb                m0, m1
    vpermq                  m0, m0, q3120
    mova             [dstq+ 0], m0
    movd             [dstq+32], xm4
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.33.loop
    jmp .left
.top.64:
    pcmpeqw                m13, m13
    psrlw                  m13, 8
.top.64.loop:
    movu                    m0, [srcq+ssq*0+0x00]
    movu                    m1, [srcq+ssq*1+0x00]
    movu                    m2, [srcq+ssq*0+0x20]
    movu                    m3, [srcq+ssq*1+0x20]
    movu                    m4, [srcq+ssq*0+0x40]
    movu                    m5, [srcq+ssq*1+0x40]
    movu                    m6, [srcq+ssq*0+0x60]
    movu                    m7, [srcq+ssq*1+0x60]
    movu                    m8, [srcq+ssq*0+  -1]
    movu                    m9, [srcq+ssq*1+  -1]
    movu                   m10, [srcq+ssq*0+0x1f]
    movu                   m11, [srcq+ssq*1+0x1f]
    movu                   m12, [srcq+ssq*0+0x3f]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3
    REPX       {pshufb x, m15}, m8, m9
    REPX         {pand x, m13}, m10, m11
    paddw                   m8, m9
    paddw                  m10, m11
    paddw                   m0, m1
    paddw                   m2, m3
    movu                    m1, [srcq+ssq*1+0x3f]
    movu                    m3, [srcq+ssq*0+0x5f]
    movu                    m9, [srcq+ssq*1+0x5f]
    paddw                   m0, m8
    paddw                   m2, m10
    REPX    {pmaddubsw x, m14}, m4, m5, m6, m7
    REPX         {pand x, m13}, m12, m1, m3, m9
    paddw                   m1, m12
    paddw                   m3, m9
    paddw                   m4, m5
    paddw                   m6, m7
    paddw                   m4, m1
    paddw                   m6, m3
    REPX          {psrlw x, 3}, m0, m2, m4, m6
    packuswb                m0, m2
    packuswb                m4, m6
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.64.loop

 DEFINE_ARGS dst, src, srcl, ss, ss3, needed_left, w, h, ystart, nleft, dstl, tbl
.left:
    lea                   ss3q, [ssq*3]
    shr                 nleftd, 1
    jz .blk.skip_left
.left2:
    movu                   xm8, [base+Llshuf_edgel]
    movu                  xm10, [base+mh_lshuf1-4+nleftq*4]
    xor                ystartd, ystartd
    xor                    t0d, t0d
    test                    hb, 0x7             ; flags
    cmovz              ystartq, ssq             ; !has_t && dir_c
    cmp                 nleftd, 1
    sete                   t0b
    lea                  srclq, [srcq+ystartq*2]
    sub                  srclq, t0
    shl                    t0d, 3
    movd                   xm9, t0d
    lea                  dstlq, [dstq+32*32]
.left.loop:
    movd                   xm0, [srclq+ssq*0]
    vpbroadcastd           xm2, [srclq+ssq*2]
    movd                   xm1, [srclq+ssq*1]
    vpbroadcastd           xm3, [srclq+ss3q ]
    lea                  srclq, [srclq+ssq*4]
    vpbroadcastd           xm4, [srclq+ssq*0]
    vpbroadcastd           xm6, [srclq+ssq*2]
    vpbroadcastd           xm5, [srclq+ssq*1]
    vpbroadcastd           xm7, [srclq+ss3q ]
    lea                  srclq, [srclq+ssq*4]
    vpblendd               xm0, xm2, 0x2
    vpblendd               xm1, xm3, 0x2
    vpblendd               xm4, xm6, 0x8
    vpblendd               xm5, xm7, 0x8
    vpblendd               xm0, xm4, 0xc
    vpblendd               xm1, xm5, 0xc
    pshufb                 xm2, xm0, xm8
    pshufb                 xm3, xm1, xm8
    REPX        {psrld x, xm9}, xm0, xm1
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    paddw                  xm2, xm3
    paddw                  xm0, xm1
    paddw                  xm0, xm2
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    pshufb                 xm0, xm10
    movq               [dstlq], xm0
    lea                  dstlq, [dstlq+nleftq*4]
    sub           needed_leftd, 4
    jg .left.loop
    lea                   srcq, [srcq+nleftq*2]

.blk:
    test                nleftd, nleftd
    setz                   t0b
    movd                  xm15, t0d
    lea                   tblq, [base+cfl_mh_gen_y_420_vstrip_8bpc_avx2_blk_table]
%define base tblq-cfl_mh_gen_y_420_vstrip_8bpc_avx2_blk_table
    tzcnt                   wd, wm
    movsxd                  t0, [tblq+wq*4]
    add                     t0, tblq
    jmp                     t0
.blk.skip_left:
    xor                    t0d, t0d
    test                    hb, 0x13            ; flags
    setz                   t0b
    neg                     t0                  ; restore src ptr post top
    lea                   srcq, [srcq+t0*2]     ; src -= (!itse && dir_c) * 2
    xor                    t0d, t0d
    jmp .blk
.left.no_top:
    lea                   ss3q, [ssq*3]
    shr                 nleftd, 1
    jz .blk
    jmp .left2

.blk.w4:
    punpcklqdq            xm15, xm15
    paddb                 xm15, [base+Llshuf]
    vinserti128            m15, xm15, 1
.blk.w4.loop:
    movu                   xm2, [srcq+ssq*0-1]
    movu                   xm6, [srcq+ssq*2-1]
    movu                   xm3, [srcq+ssq*1-1]
    movu                   xm7, [srcq+ss3q -1]
    lea                   srcq, [srcq+ssq*4]
    vinserti128             m2, [srcq+ssq*0-1], 1
    vinserti128             m6, [srcq+ssq*2-1], 1
    vinserti128             m3, [srcq+ssq*1-1], 1
    vinserti128             m7, [srcq+ss3q -1], 1
    lea                   srcq, [srcq+ssq*4]
    psrldq                  m0, m2, 1
    psrldq                  m4, m6, 1
    psrldq                  m1, m3, 1
    psrldq                  m5, m7, 1
    punpcklqdq              m0, m4
    punpcklqdq              m1, m5
    punpcklqdq              m2, m6
    punpcklqdq              m3, m7
    REPX    {pmaddubsw x, m14}, m0, m1
    REPX       {pshufb x, m15}, m2, m3
    paddw                   m2, m3
    paddw                   m0, m1
    paddw                   m0, m2
    psrlw                   m0, 3
    vextracti128           xm1, m0, 1
    packuswb               xm0, xm1
    mova                [dstq], xm0
    add                   dstq, 16
    sub                     hd, 4 << 5
    jge .blk.w4.loop
    jmp .ret
.blk.w8:
    por                   xm15, [base+Llshuf]
    vinserti128            m15, xm15, 1
.blk.w8.loop:
    movu                   xm0, [srcq+ssq*0]
    movu                   xm1, [srcq+ssq*1]
    movu                   xm2, [srcq+ssq*2]
    movu                   xm3, [srcq+ss3q ]
    movu                   xm4, [srcq+ssq*0-1]
    movu                   xm5, [srcq+ssq*1-1]
    movu                   xm6, [srcq+ssq*2-1]
    movu                   xm7, [srcq+ss3q -1]
    lea                   srcq, [srcq+ssq*4]
    vinserti128             m0, [srcq+ssq*0], 1
    vinserti128             m1, [srcq+ssq*1], 1
    vinserti128             m2, [srcq+ssq*2], 1
    vinserti128             m3, [srcq+ss3q ], 1
    vinserti128             m4, [srcq+ssq*0-1], 1
    vinserti128             m5, [srcq+ssq*1-1], 1
    vinserti128             m6, [srcq+ssq*2-1], 1
    vinserti128             m7, [srcq+ss3q -1], 1
    lea                   srcq, [srcq+ssq*4]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3
    REPX       {pshufb x, m15}, m4, m5, m6, m7
    paddw                   m4, m5
    paddw                   m6, m7
    paddw                   m0, m1
    paddw                   m2, m3
    paddw                   m0, m4
    paddw                   m2, m6
    REPX          {psrlw x, 3}, m0, m2
    packuswb                m0, m2
    mova                [dstq], m0
    add                   dstq, 32
    sub                     hd, 4 << 5
    jge .blk.w8.loop
    jmp .ret
.blk.w16:
    vbroadcasti128         m12, [base+Llshuf]
    por                    m15, m12
.blk.w16.loop:
    movu                    m0, [srcq+ssq*0]
    movu                    m2, [srcq+ssq*1]
    movu                    m1, [srcq+ssq*2]
    movu                    m3, [srcq+ss3q ]
    movu                    m8, [srcq+ssq*0+-1]
    movu                    m9, [srcq+ssq*1+-1]
    movu                   m12, [srcq+ssq*2+-1]
    movu                   m13, [srcq+ss3q +-1]
    lea                   srcq, [srcq+ssq*4]
    movu                    m4, [srcq+ssq*0]
    movu                    m6, [srcq+ssq*1]
    movu                    m5, [srcq+ssq*2]
    movu                    m7, [srcq+ss3q ]
    movu                   m10, [srcq+ssq*0+-1]
    movu                   m11, [srcq+ssq*1+-1]
    REPX    {pmaddubsw x, m14}, m0, m2, m1, m3
    REPX       {pshufb x, m15}, m8, m9
    paddw                   m8, m9
    REPX       {pshufb x, m15}, m12, m13
    paddw                  m12, m13
    paddw                   m0, m2
    paddw                   m1, m3
    paddw                   m0, m8
    paddw                   m1, m12
    movu                   m12, [srcq+ssq*2+-1]
    movu                   m13, [srcq+ss3q +-1]
    lea                   srcq, [srcq+ssq*4]
    REPX    {pmaddubsw x, m14}, m4, m6, m5, m7
    REPX       {pshufb x, m15}, m10, m11, m12, m13
    paddw                  m10, m11
    paddw                  m12, m13
    paddw                   m4, m6
    paddw                   m5, m7
    paddw                   m4, m10
    paddw                   m5, m12
    REPX          {psrlw x, 3}, m0, m1, m4, m5
    packuswb                m0, m1
    packuswb                m4, m5
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    add                   dstq, 64
    sub                     hd, 4 << 5
    jge .blk.w16.loop
    jmp .ret
.blk.w32:
    vbroadcasti128         m12, [base+Llshuf]
    por                    m15, m12
    pcmpeqw                m13, m13
    psrlw                  m13, 8
.blk.w32.loop:
    movu                    m0, [srcq+ssq*0+ 0]
    movu                    m2, [srcq+ssq*1+ 0]
    movu                    m1, [srcq+ssq*0+32]
    movu                    m3, [srcq+ssq*1+32]
    movu                    m8, [srcq+ssq*0+-1]
    movu                    m9, [srcq+ssq*1+-1]
    movu                   m10, [srcq+ssq*0+31]
    movu                   m11, [srcq+ssq*1+31]
    movu                    m4, [srcq+ssq*2+ 0]
    movu                    m6, [srcq+ss3q + 0]
    movu                    m5, [srcq+ssq*2+32]
    movu                    m7, [srcq+ss3q +32]
    REPX    {pmaddubsw x, m14}, m0, m2, m1, m3
    REPX       {pshufb x, m15}, m8, m9
    REPX         {pand x, m13}, m10, m11
    paddw                   m0, m2
    paddw                   m1, m3
    paddw                   m8, m9
    paddw                  m10, m11
    paddw                   m0, m8
    paddw                   m1, m10
    movu                   m10, [srcq+ssq*2+-1]
    movu                   m11, [srcq+ss3q +-1]
    movu                    m2, [srcq+ssq*2+31]
    movu                    m3, [srcq+ss3q +31]
    lea                   srcq, [srcq+ssq*4]
    REPX    {pmaddubsw x, m14}, m4, m6, m5, m7
    REPX       {pshufb x, m15}, m10, m11
    REPX         {pand x, m13}, m2, m3
    paddw                   m4, m6
    paddw                   m5, m7
    paddw                  m10, m11
    paddw                   m2, m3
    paddw                   m4, m10
    paddw                   m5, m2
    REPX          {psrlw x, 3}, m0, m1, m4, m5
    packuswb                m0, m1
    packuswb                m4, m5
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    add                   dstq, 64
    sub                     hd, 2 << 5
    jge .blk.w32.loop
    jmp .ret

.ret:
    RET

cglobal cfl_mh_gen_y_420_gauss_8bpc, 4, 15, 16, dst, src, tse, ss, \
                                                needed_top, needed_left, \
                                                w, h, flags, \
                                                nleft, ntop, tbl, ts
 DECLARE_REG_TMP 9, 14, 10, 12, 13
    mov                 flagsd, flagsm
    mov                     hd, hm
    movifnidn      needed_topd, needed_topm
    movifnidn     needed_leftd, needed_leftm
    mov                 flagsd, flagsm
    xor                    t4d, t4d
    test                flagsb, 0xb
    mov                    t0d, flagsd
    setnz                  t4b                  ; has_l || !dir_c
    shl                     hd, 5
    lea                     hd, [hq-(1<<5)+flagsq]
    shr                 flagsd, 2
    and                    t0d, flagsd          ; (has_l & dir_l) | (has_t & dir_t)
    mov                    t1d, flagsd
    mov                    t2d, flagsd
    mov                    t3d, t0d
    REPX          {and x, 0x2}, t1d, t0d        ; has_l / has_l & dir_l
    REPX          {and x, 0x1}, t2d, t3d        ; has_t / has_t & dir_t
    add                    t0d, t1d             ; nleft
    sub                   srcq, nleftq
    add                    t2d, t3d             ; ntop
    lea                   tblq, [cfl_mh_gen_y_420_gauss_8bpc_avx2_top_table]
%define base0 tblq-cfl_mh_gen_y_420_gauss_8bpc_avx2_top_table
    pcmpeqw                m13, m13
    psrlw                  m13, 8
    jz .left.no_top
    cmp                 nleftd, 2
    setne                  t3b                  ; nleft != 1
    and                    t3d, t4d             ; nleft != 1 && (has_l || !dir_c)
    movd                  xm15, t3d
    vbroadcasti128         m12, [base0+Llshuf]
    por                    m15, m12
    sub                   tseq, nleftq
    xor                    t4d, 1               ; !has_l && dir_c
    lea                   tseq, [tseq+t4*2]
    test                flagsb, 0x4             ; is_top_sb_edge
    jnz .tse
    vpbroadcastd           m14, [base0+pb_flt2]
    lea                   srcq, [srcq+t4*2]
    mov                    r8d, needed_topd
    cmp            needed_topd, 16
    setge                  t3b
    shr                    t1d, 1
    and                    t3d, t1d             ; if (needed_top >= 16)
    sub                    r8d, t3d             ;   needed_top -= has_l
 DECLARE_REG_TMP 13, 14, 8, 6
    mov                    t0d, 31
    lzcnt                  t1d, r8d
    tzcnt                  t2d, r8d
    sub                    t0d, t1d
    cmp                    t0d, t2d
    setne                  t1b
    add                    t0d, t1d
    shlx                    t3, ssq, ntopq
    mov                    tsq, ssq
    xor                    t2d, t2d
    neg                    tsq
    sub                   srcq, t3
    cmp                  ntopd, 1
    cmove                   t2, tsq
 DEFINE_ARGS dst, src, tse, ss, needed_top, needed_left, w, h, top, nleft, ntop, tbl, ts
    lea                   topq, [srcq+t2]
    movsxd                  t0, [tblq+t0*4]
    add                     t0, tblq
    jmp                     t0

.tse:
    vpbroadcastd           m14, [base0+pb_flt2+4]
    xor                    t0d, t0d
    pcmpeqd               xm12, xm12
    pslldq                xm12, 1
    jmp .tse.start_loop
.tse.loop:
    pand                  xm15, xm12
.tse.start_loop:
    movu                   xm0, [tseq+t0*2+ 0]
    movu                   xm1, [tseq+t0*2+16]
    movu                   xm2, [tseq+t0*2+-1]
    palignr                xm3, xm1, xm0, 15
    REPX   {pmaddubsw x, xm14}, xm0, xm1
    pshufb                 xm2, xm15
    pand                   xm3, xm13
    paddw                  xm0, xm2
    paddw                  xm1, xm3
    REPX          {psrlw x, 3}, xm0, xm1
    packuswb               xm0, xm1
    mova          [dstq+t0+ 0], xm0
    mova          [dstq+t0+64], xm0
    add                    t0d, 16
    cmp                    t0d, needed_topd
    jl .tse.loop
    mov                    t1d, 32
    xor                    t0d, t0d
    shlx                   t1d, t1d, ntopd
    add                   dstq, t1
    test                    hb, 0xb             ; flags
    setz                   t0b
    neg                     t0                  ; restore top ptr post top
    vpbroadcastd           m14, [base0+pb_flt2]
    lea                   topq, [tseq+t0*2]     ; top -= (!has_l && dir_c) * 2
    jmp .left

.top.4:
    movq                   xm2, [topq]
    pand                   xm2, xm13
.top.4.loop:
    movq                   xm0, [srcq+ssq*0]
    movq                   xm1, [srcq+ssq*0-1]
    movq                   xm3, [srcq+ssq*1]
    pmaddubsw              xm0, xm14
    pshufb                 xm1, xm15
    pand                   xm3, xm13
    paddw                  xm2, xm3
    paddw                  xm2, xm1
    paddw                  xm0, xm2
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    movd                [dstq], xm0
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    mova                   xm2, xm3
    dec                  ntopd
    jg .top.4.loop
    lea                   topq, [srcq+tsq]
    jmp .left
.top.8:
    pand                   xm2, xm13, [topq]
.top.8.loop:
    movu                   xm0, [srcq+ssq*0]
    movu                   xm1, [srcq+ssq*0-1]
    pand                   xm3, xm13, [srcq+ssq*1]
    pmaddubsw              xm0, xm14
    pshufb                 xm1, xm15
    paddw                  xm2, xm3
    paddw                  xm2, xm1
    paddw                  xm0, xm2
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    movq                [dstq], xm0
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    mova                   xm2, xm3
    dec                  ntopd
    jg .top.8.loop
    lea                   topq, [srcq+tsq]
    jmp .left
.top.17:
    pand                    m2, m13, [topq]
.top.17.loop:
    movu                    m0, [srcq+ssq*0]
    movu                    m1, [srcq+ssq*0-1]
    pand                    m3, m13, [srcq+ssq*1]
    cmp            needed_topd, 17
    jne .top.17.skip_last
    movd                   xm5, [srcq+ssq*0+31]
    pand                   xm6, xm13, [srcq+ssq*1+32]
    pand                   xm7, xm13, [topq+32]
    psrld                  xm4, xm5, 8
    pmaddubsw              xm4, xm14
    pand                   xm5, xm13
    paddw                  xm5, xm6
    paddw                  xm4, xm7
    paddw                  xm4, xm5
    psrlw                  xm4, 3
.top.17.skip_last:
    pmaddubsw               m0, m14
    pshufb                  m1, m15
    paddw                   m2, m3
    paddw                   m2, m1
    paddw                   m0, m2
    psrlw                   m0, 3
    packuswb                m0, m0
    vpermq                  m0, m0, q3220
    mova             [dstq+ 0], xm0
    movd             [dstq+16], xm4
    lea                   topq, [srcq+ssq*1]
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    mova                    m2, m3
    dec                  ntopd
    jg .top.17.loop
    jmp .left
.top.33:
    pand                    m2, m13, [topq+ 0]
    pand                    m3, m13, [topq+32]
.top.33.loop:
    movu                    m0, [srcq+ssq*0+ 0]
    movu                    m1, [srcq+ssq*0+32]
    pand                    m4, m13, [srcq+ssq*1+ 0]
    pand                    m5, m13, [srcq+ssq*1+32]
    movu                    m8, [srcq+ssq*0+-1]
    pand                    m9, m13, [srcq+ssq*0+31]
    cmp            needed_topd, 33
    movd                  xm10, [srcq+ssq*0+63]
    pand                  xm11, xm13, [srcq+ssq*1+64]
    pand                  xm12, xm13, [topq+64]
    psrld                  xm6, xm10, 8
    pmaddubsw              xm6, xm14
    pand                  xm10, xm13
    paddw                  xm6, xm10
    paddw                 xm11, xm12
    paddw                  xm6, xm11
    psrlw                  xm6, 3
    jne .top.33.skip_last
.top.33.skip_last:
    REPX    {pmaddubsw x, m14}, m0, m1
    pshufb                  m8, m15
    paddw                   m2, m4
    paddw                   m3, m5
    paddw                   m0, m8
    paddw                   m1, m9
    paddw                   m0, m2
    paddw                   m1, m3
    REPX          {psrlw x, 3}, m0, m1
    packuswb                m0, m1
    vpermq                  m0, m0, q3120
    mova             [dstq+ 0], m0
    movd             [dstq+32], xm6
    mova                    m2, m4
    mova                    m3, m5
    lea                   topq, [srcq+ssq*1]
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.33.loop
    jmp .left
.top.64:
    pand                    m4, m13, [topq+0x00]
    pand                    m5, m13, [topq+0x20]
    pand                    m6, m13, [topq+0x40]
    pand                    m7, m13, [topq+0x60]
.top.64.loop:
    movu                    m0, [srcq+ssq*0+0x00]
    movu                    m1, [srcq+ssq*0+0x20]
    movu                    m2, [srcq+ssq*0+0x40]
    movu                    m3, [srcq+ssq*0+0x60]
    movu                    m8, [srcq+ssq*0+  -1]
    pand                    m9, m13, [srcq+ssq*0+0x1f]
    pand                   m10, m13, [srcq+ssq*0+0x3f]
    pand                   m11, m13, [srcq+ssq*0+0x5f]
    REPX    {pmaddubsw x, m14}, m0, m1, m2, m3
    pshufb                  m8, m15
    paddw                   m0, m4
    paddw                   m1, m5
    paddw                   m2, m6
    paddw                   m3, m7
    paddw                   m0, m8
    paddw                   m1, m9
    paddw                   m2, m10
    paddw                   m3, m11
    pand                    m4, m13, [srcq+ssq*1+0x00]
    pand                    m5, m13, [srcq+ssq*1+0x20]
    pand                    m6, m13, [srcq+ssq*1+0x40]
    pand                    m7, m13, [srcq+ssq*1+0x60]
    paddw                   m0, m4
    paddw                   m1, m5
    paddw                   m2, m6
    paddw                   m3, m7
    REPX          {psrlw x, 3}, m0, m1, m2, m3
    packuswb                m0, m1
    packuswb                m2, m3
    REPX  {vpermq x, x, q3120}, m0, m2
    mova             [dstq+ 0], m0
    mova             [dstq+32], m2
    movd             [dstq+64], xm8
    lea                   topq, [srcq+ssq*1]
    lea                   srcq, [srcq+ssq*2]
    add                   dstq, 64
    dec                  ntopd
    jg .top.64.loop

 DEFINE_ARGS dst, src, srcl, ss, ss3, needed_left, w, h, top, nleft, dstl, tbl, ystart
.left:
    lea                   ss3q, [ssq*3]
    shr                 nleftd, 1
    jz .blk.skip_left
.left2:
    movu                  xm10, [base0+mh_lshuf1-4+nleftq*4]
    xor                ystartd, ystartd
    xor                    t0d, t0d
    test                    hb, 0x7             ; flags
    cmovz              ystartq, ssq             ; !has_t && dir_c
    cmovz                 topq, srcq
    cmp                 nleftd, 1
    sete                   t0b
    lea                  srclq, [srcq+ystartq*2]
    lea                   topq, [topq+ystartq*1]
    sub                  srclq, t0
    shl                    t0d, 3
    movd                   xm9, t0d
    lea                  dstlq, [dstq+32*32]
    vpbroadcastd           xm8, [topq]
    pand                   xm8, xm13
.left.loop:
    movd                   xm0, [srclq+ssq*0]
    vpbroadcastd           xm2, [srclq+ssq*2]
    movd                   xm1, [srclq+ssq*1]
    vpbroadcastd           xm3, [srclq+ss3q ]
    lea                  srclq, [srclq+ssq*4]
    vpbroadcastd           xm4, [srclq+ssq*0]
    vpbroadcastd           xm6, [srclq+ssq*2]
    vpbroadcastd           xm5, [srclq+ssq*1]
    vpbroadcastd           xm7, [srclq+ss3q ]
    lea                  srclq, [srclq+ssq*4]
    vpblendd               xm0, xm2, 0x2
    vpblendd               xm1, xm3, 0x2
    vpblendd               xm4, xm6, 0x8
    vpblendd               xm5, xm7, 0x8
    vpblendd               xm0, xm4, 0xc
    vpblendd               xm1, xm5, 0xc
    pshufb                 xm2, xm0, [base0+Llshuf_edgel]
    REPX        {psrld x, xm9}, xm0, xm1
    pmaddubsw              xm0, xm14
    REPX        {pand x, xm13}, xm2, xm1
    palignr                xm8, xm1, xm8, 12
    paddw                  xm0, xm2
    paddw                  xm8, xm1
    paddw                  xm0, xm8
    psrlw                  xm0, 3
    packuswb               xm0, xm0
    pshufb                 xm0, xm10
    movq               [dstlq], xm0
    mova                   xm8, xm1
    lea                  dstlq, [dstlq+nleftq*4]
    sub           needed_leftd, 4
    jg .left.loop
    sub                   topq, ystartq
    lea                   srcq, [srcq+nleftq*2]
    lea                   topq, [topq+nleftq*2]

.blk:
    test                nleftd, nleftd
    setz                   t0b
    movd                  xm15, t0d
    lea                   tblq, [base0+cfl_mh_gen_y_420_gauss_8bpc_avx2_blk_table]
%define base1 tblq-cfl_mh_gen_y_420_gauss_8bpc_avx2_blk_table
    tzcnt                   wd, wm
    movsxd                  t0, [tblq+wq*4]
    add                     t0, tblq
    jmp                     t0
.blk.skip_left:
    xor                    t0d, t0d
    test                    hb, 0x13            ; flags
    setz                   t0b
    neg                     t0                  ; restore ptrs post top
    lea                   srcq, [srcq+t0*2]     ; src -= (!has_l && dir_c) * 2
    lea                   topq, [topq+t0*2]     ; top -= (!has_l && dir_c) * 2
    xor                    t0d, t0d
    jmp .blk
.left.no_top:
    vpbroadcastd           m14, [base0+pb_flt2]
    mov                   topq, srcq
    lea                   ss3q, [ssq*3]
    shr                 nleftd, 1
    jz .blk
    jmp .left2

.blk.w4:
    punpcklqdq            xm15, xm15
    paddb                 xm15, [base1+Llshuf]
    vinserti128            m15, xm15, 1
    vpbroadcastq           xm8, [topq]              ; t0
.blk.w4.loop:
    movu                   xm2, [srcq+ssq*0-1]
    movu                   xm6, [srcq+ssq*2-1]
    movq                   xm1, [srcq+ssq*1]        ; b0/t1
    vpbroadcastq            m9, [srcq+ss3q ]        ; b1/t2
    lea                   srcq, [srcq+ssq*4]
    vinserti128             m2, [srcq+ssq*0-1], 1   ; l0 l2
    vinserti128             m6, [srcq+ssq*2-1], 1   ; l1 l3
    vinserti128             m1, [srcq+ssq*1], 1     ; b0/t1 b2/t3
    vpbroadcastq            m5, [srcq+ss3q ]        ; ../.. b3/t4
    lea                   srcq, [srcq+ssq*4]
    vpblendd                m8, m9, 0x30            ; t0 t2
    psrldq                  m0, m2, 1               ; m0 m2
    psrldq                  m4, m6, 1               ; m1 m3
    vpblendd                m9, m5, 0x30            ; b1/t2 b3/t4
    punpcklqdq              m0, m4                  ; m01 m23
    punpcklqdq              m1, m9                  ; b01/t12 b23/t34
    punpcklqdq              m2, m6                  ; l01 l23
    punpcklqdq              m8, m1                  ; t01 t23
    pmaddubsw               m0, m14
    REPX         {pand x, m13}, m1, m8
    pshufb                  m2, m15
    paddw                   m1, m8
    paddw                   m0, m2
    paddw                   m0, m1
    psrlw                   m0, 3
    vextracti128           xm1, m0, 1
    packuswb               xm0, xm1
    mova                [dstq], xm0
    mova                   xm8, xm5
    add                   dstq, 16
    sub                     hd, 4 << 5
    jge .blk.w4.loop
    jmp .ret
.blk.w8:
    por                   xm15, [base1+Llshuf]
    vinserti128            m15, xm15, 1
    movu                   xm8, [topq]
.blk.w8.loop:
    movu                   xm0, [srcq+ssq*0]
    movu                   xm2, [srcq+ssq*2]
    movu                   xm4, [srcq+ssq*0-1]
    movu                   xm6, [srcq+ssq*2-1]
    vbroadcasti128          m1, [srcq+ssq*1]
    vbroadcasti128          m3, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    vbroadcasti128          m9, [srcq+ssq*0]
    vbroadcasti128         m10, [srcq+ssq*2]
    vbroadcasti128         m11, [srcq+ssq*0-1]
    vbroadcasti128         m12, [srcq+ssq*2-1]
    vbroadcasti128          m5, [srcq+ssq*1]
    vbroadcasti128          m7, [srcq+ss3q ]
    lea                   srcq, [srcq+ssq*4]
    vpblendd                m0, m9, 0xf0
    vpblendd                m2, m10, 0xf0
    vpblendd                m4, m11, 0xf0
    vpblendd                m6, m12, 0xf0
    REPX    {pmaddubsw x, m14}, m0, m2
    REPX       {pshufb x, m15}, m4, m6
    vpblendd                m8, m3, 0xf0            ; t0 t2
    vpblendd                m1, m5, 0xf0            ; b0/t1 b2/t3
    vpblendd                m3, m7, 0xf0            ; b1/t2 b3/t4
    REPX         {pand x, m13}, m8, m1, m3
    paddw                   m0, m4
    paddw                   m2, m6
    paddw                   m0, m8
    paddw                   m2, m1
    paddw                   m0, m1
    paddw                   m2, m3
    REPX          {psrlw x, 3}, m0, m2
    packuswb                m0, m2
    mova                [dstq], m0
    mova                   xm8, xm7
    add                   dstq, 32
    sub                     hd, 4 << 5
    jge .blk.w8.loop
    jmp .ret
.blk.w16:
    vbroadcasti128          m8, [base1+Llshuf]
    por                    m15, m8
    pand                   m12, m13, [topq]
.blk.w16.loop:
    movu                    m0, [srcq+ssq*0]
    movu                    m1, [srcq+ssq*2]
    pand                    m2, m13, [srcq+ssq*1]
    pand                    m3, m13, [srcq+ss3q ]
    movu                    m8, [srcq+ssq*0+-1]
    movu                    m9, [srcq+ssq*2+-1]
    lea                   srcq, [srcq+ssq*4]
    movu                    m4, [srcq+ssq*0]
    movu                    m5, [srcq+ssq*2]
    pand                    m6, m13, [srcq+ssq*1]
    pand                    m7, m13, [srcq+ss3q ]
    movu                   m10, [srcq+ssq*0+-1]
    movu                   m11, [srcq+ssq*2+-1]
    REPX    {pmaddubsw x, m14}, m0, m1, m4, m5
    REPX       {pshufb x, m15}, m8, m9, m10, m11
    paddw                   m0, m12
    paddw                   m1, m2
    paddw                   m4, m3
    paddw                   m5, m6
    paddw                   m0, m2
    paddw                   m1, m3
    paddw                   m4, m6
    paddw                   m5, m7
    paddw                   m0, m8
    paddw                   m1, m9
    paddw                   m4, m10
    paddw                   m5, m11
    REPX          {psrlw x, 3}, m0, m1, m4, m5
    packuswb                m0, m1
    packuswb                m4, m5
    REPX  {vpermq x, x, q3120}, m0, m4
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    mova                   m12, m7
    lea                   srcq, [srcq+ssq*4]
    add                   dstq, 64
    sub                     hd, 4 << 5
    jge .blk.w16.loop
    jmp .ret
.blk.w32:
    vbroadcasti128          m8, [base1+Llshuf]
    por                    m15, m8
    pand                    m2, m13, [topq+ 0]
    pand                    m3, m13, [topq+32]
.blk.w32.loop:
    movu                    m0, [srcq+ssq*0+ 0]
    movu                    m1, [srcq+ssq*0+32]
    movu                    m4, [srcq+ssq*2+ 0]
    movu                    m5, [srcq+ssq*2+32]
    movu                    m8,      [srcq+ssq*0+-1]
    pand                    m9, m13, [srcq+ssq*0+31]
    movu                   m10,      [srcq+ssq*2+-1]
    pand                   m11, m13, [srcq+ssq*2+31]
    pand                    m6, m13, [srcq+ssq*1+ 0]
    pand                    m7, m13, [srcq+ssq*1+32]
    pand                   m12, m13, [srcq+ss3q + 0]
    REPX    {pmaddubsw x, m14}, m0, m1, m4, m5
    REPX       {pshufb x, m15}, m8, m10
    paddw                   m0, m2
    paddw                   m1, m3
    pand                    m3, m13, [srcq+ss3q +32]
    lea                   srcq, [srcq+ssq*4]
    paddw                   m4, m6
    paddw                   m5, m7
    paddw                   m8, m6
    paddw                   m9, m7
    paddw                  m10, m12
    paddw                  m11, m3
    paddw                   m0, m8
    paddw                   m1, m9
    paddw                   m4, m10
    paddw                   m5, m11
    REPX          {psrlw x, 3}, m0, m1, m4, m5
    packuswb                m0, m1
    packuswb                m4, m5
    REPX  {vpermq x, x, q3120}, m0, m4
    mova                    m2, m12
    mova             [dstq+ 0], m0
    mova             [dstq+32], m4
    add                   dstq, 64
    sub                     hd, 2 << 5
    jge .blk.w32.loop
    jmp .ret

.ret:
    RET

cglobal cfl_mh_gen_mat_8bpc, 4, 15, 16, mat, imat, y0, refw, refh, flags, \
                                        ntop, start, n, y1, left, dir_off
 DECLARE_REG_TMP 12, 13, 6, 7, 3
    movifnidn           flagsd, flagsm
    mov                  refwd, refwm           ; zero upper halves
    mov                  refhd, refhm
    lea                    r14, [pw_128]
%define base r14-pw_128
    pxor                   m10, m10
    pxor                   m12, m12
    vpbroadcastd           m11, [base+pw_128]
    mov                  ntopd, flagsd
    and                  ntopd, 0x5
    mov                    t0d, ntopd
    shr                  ntopd, 2
    and                    t0d, ntopd
    add                  ntopd, t0d
    shl                  ntopd, 6
    lea                  leftq, [y0q+ntopq+32*32]
    lea                     nd, [refwq+refhq]
    xor                 startd, startd
    test                flagsb, 0x4             ; has_t
    jz .left

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
    add                    y0q, refwq
    add                  imatq, refwq
    and                 startd, t0d             ; !has_l && dir_t
    add                    y0q, startq
    mov                    t2d, 32
    and                    t1d, 31
    xor                    t0d, t0d
    sub                    t2d, t1d
    lea                    y1q, [y0q+dir_offq]
    neg                  refwq
    mov                     t1, refwq

.top.loop:
    cmp                  refwd, -31
    cmovae                 t0d, t2d
    movu                   m14, [base+mh_smpl_msk+t0]
    pand                    m1, m14, [y1q+refwq]
    pand                    m0, m14, [y0q+refwq]
    punpcklbw               m4, m1, m10
    punpckhbw               m5, m1, m10
    psllw                   m8, m4, 7
    psllw                   m9, m5, 7
    pmulhrsw                m4, m8
    pmulhrsw                m5, m9
    movu         [imatq+refwq], m0
    punpcklbw               m2, m0, m10
    punpckhbw               m3, m0, m10
    pmaddwd                 m6, m2, m2
    pmaddwd                 m7, m3, m3
    packuswb                m1, m4, m5
    movu     [imatq+386+refwq], m1
    pmaddwd                 m8, m2, m4
    pmaddwd                 m9, m3, m5
    pmaddwd                 m0, m4, m4
    pmaddwd                 m1, m5, m5
    paddd                   m6, m7
    paddd                   m8, m9
    paddd                   m0, m1
    punpcklwd               m7, m4, m10
    punpckhwd               m4, m10
    punpcklwd               m9, m5, m10
    punpckhwd               m5, m10
    punpcklwd               m1, m2, m10
    punpckhwd               m2, m10
    punpcklwd              m15, m3, m10
    punpckhwd               m3, m10
    paddd                   m4, m7
    paddd                   m5, m9
    paddd                   m2, m1
    paddd                   m3, m15
    paddd                   m4, m5
    paddd                   m2, m3
    REPX          {pslld x, 7}, m4, m2
    vperm2i128              m7, m6, m0, 0x31
    vinserti128             m6, xm0, 1
    vperm2i128              m9, m8, m4, 0x31
    vinserti128             m8, xm4, 1
    vextracti128           xm3, m2, 1
    paddd                   m6, m7
    paddd                   m8, m9
    paddd                  xm2, xm3
    punpckhqdq              m7, m6, m6
    punpckhqdq              m9, m8, m8
    punpckhqdq             xm3, xm2, xm2
    paddd                   m6, m7
    paddd                   m8, m9
    paddd                  xm2, xm3
    punpckldq               m6, m8
    psrlq                  xm3, xm2, 32
    punpckhqdq              m7, m6, m6
    paddd                   m6, m7
    paddd                  xm2, xm3
    punpcklqdq              m6, m2
    paddd                  m12, m6
    add                  refwq, 32
    jl .top.loop
    test                flagsb, 0x8             ; has_l
    jz .shift
    test                flagsb, 0x1             ; dir_t
    jz .left2
;.extra_tl:
    movzx                  t0d, byte [y1q+t1]
    movzx                  t1d, byte [leftq]
    inc                  imatq
    mov              [imatq-1], t0b
    mov                    t2d, t0d
    rorx                   t3d, t0d, 25
    imul                   t1d, t1d
    imul                   t0d, t0d
    add                    t1d, 0x80
    shr                    t1d, 8
    mov            [imatq+385], t1b
    rorx                   t4d, t1d, 25
    imul                   t2d, t1d
    imul                   t1d, t1d
    movd                   xm0, t0d
    movd                   xm1, t2d
    movd                   xm3, t1d
    movd                   xm4, t4d
    movd                   xm2, t3d
    punpckldq              xm0, xm1
    punpckldq              xm3, xm4
    punpcklqdq             xm0, xm2
    vinserti128             m0, xm3, 1
    paddd                  m12, m0
    dec                  refhd
    jmp .left.dir_t

 DEFINE_ARGS mat, imat, _, _, refh, flags, _, start, n, _, l, _
.left:
    test                flagsb, 0x1
    jnz .left.dir_t
.left2:
    test                flagsd, 0x3
    jz .left.dir_c

;.left.dir_l:
    test                flagsb, 0x4             ; has_t
    setz                startb
    lea                     lq, [lq+refhq*2]
    add                  imatq, refhq
    lea                    t1d, [refhq*2]
    lea                     lq, [lq+startq*2]
    neg                  refhq
    mov                    t2d, 32
    and                    t1d, 30
    xor                    t0d, t0d
    sub                    t2d, t1d
    pcmpeqw                m10, m10
    psrlw                  m10, 8
.left.dir_l.loop:
    cmp                  refhd, -15
    cmovae                 t0d, t2d
    movu                   m14, [base+mh_smpl_msk+t0]
    pand                    m0, m14, [lq+refhq*2]
    psrlw                   m1, m0, 8
    pand                    m0, m10
    psllw                   m3, m1, 7
    pmaddwd                 m2, m0, m0
    pmulhrsw                m1, m3
    packuswb                m5, m0, m0
    vpermq                  m5, m5, q2020
    movu         [imatq+refhq], xm5
    pmaddwd                 m3, m0, m1
    pmaddwd                 m4, m1, m1
    packuswb                m6, m1, m1
    vpermq                  m6, m6, q2020
    pxor                    m5, m5
    movu     [imatq+386+refhq], xm6
    punpcklwd              m13, m1, m5
    punpckhwd               m1, m5
    punpcklwd              m15, m0, m5
    punpckhwd               m0, m5
    paddd                   m1, m13
    paddd                   m0, m15
    REPX          {pslld x, 7}, m1, m0
    vperm2i128              m7, m2, m4, 0x31
    vinserti128             m2, xm4, 1
    vperm2i128              m8, m3, m1, 0x31
    vinserti128             m3, xm1, 1
    vextracti128           xm9, m0, 1
    paddd                   m2, m7
    paddd                   m3, m8
    paddd                  xm0, xm9
    punpckhqdq              m7, m2, m2
    punpckhqdq              m8, m3, m3
    punpckhqdq             xm9, xm0, xm0
    paddd                   m2, m7
    paddd                   m3, m8
    paddd                  xm0, xm9
    punpckldq               m2, m3
    psrlq                  xm9, xm0, 32
    punpckhqdq              m3, m2, m2
    paddd                   m2, m3
    paddd                  xm0, xm9
    punpcklqdq              m2, m0
    paddd                  m12, m2
    add                  refhq, 16
    jl .left.dir_l.loop
    jmp .shift

.left.dir_t:
    mov                    t0d, refhd
    add                     lq, refhq
    add                  imatq, refhq
    mov                    t2d, 32
    and                    t0d, 31
    xor                    t1d, t1d
    sub                    t2d, t0d
    neg                  refhq
.left.dir_t.loop:
    cmp                  refhq, -31
    cmovae                 t1d, t2d
    movu                   m14, [base+mh_smpl_msk+t1]
    pand                    m1, m14, [lq+refhq+1]
    pand                    m0, m14, [lq+refhq]
    pxor                   m10, m10
    punpcklbw               m4, m1, m10
    punpckhbw               m5, m1, m10
    psllw                   m8, m4, 7
    psllw                   m9, m5, 7
    pmulhrsw                m4, m8
    pmulhrsw                m5, m9
    movu     [imatq+  0+refhq], m0
    punpcklbw               m2, m0, m10
    punpckhbw               m3, m0, m10
    pmaddwd                 m6, m2, m2
    pmaddwd                 m7, m3, m3
    packuswb                m1, m4, m5
    movu     [imatq+386+refhq], m1
    pmaddwd                 m8, m2, m4
    pmaddwd                 m9, m3, m5
    pmaddwd                 m0, m4, m4
    pmaddwd                 m1, m5, m5
    paddd                   m6, m7
    paddd                   m8, m9
    paddd                   m0, m1
    punpcklwd               m7, m4, m10
    punpckhwd               m4, m10
    punpcklwd               m9, m5, m10
    punpckhwd               m5, m10
    punpcklwd               m1, m2, m10
    punpckhwd               m2, m10
    punpcklwd              m15, m3, m10
    punpckhwd               m3, m10
    paddd                   m4, m7
    paddd                   m5, m9
    paddd                   m2, m1
    paddd                   m3, m15
    paddd                   m4, m5
    paddd                   m2, m3
    REPX          {pslld x, 7}, m4, m2
    vperm2i128              m7, m6, m0, 0x31
    vinserti128             m6, xm0, 1
    vperm2i128              m9, m8, m4, 0x31
    vinserti128             m8, xm4, 1
    vextracti128           xm3, m2, 1
    paddd                   m6, m7
    paddd                   m8, m9
    paddd                  xm2, xm3
    punpckhqdq              m7, m6, m6
    punpckhqdq              m9, m8, m8
    punpckhqdq             xm3, xm2, xm2
    paddd                   m6, m7
    paddd                   m8, m9
    paddd                  xm2, xm3
    punpckldq               m6, m8
    psrlq                  xm3, xm2, 32
    punpckhqdq              m7, m6, m6
    paddd                   m6, m7
    paddd                  xm2, xm3
    punpcklqdq              m6, m2
    paddd                  m12, m6
    add                  refhq, 32
    jl .left.dir_t.loop
    jmp .shift

.left.dir_c:
    mov                    t0d, refhd
    add                     lq, refhq
    add                  imatq, refhq
    mov                    t2d, 32
    and                    t0d, 31
    xor                    t1d, t1d
    sub                    t2d, t0d
    neg                  refhq
.left.dir_c.loop:
    cmp                  refhq, -31
    cmovae                 t1d, t2d
    movu                   m14, [base+mh_smpl_msk+t1]
    pand                    m0, m14, [lq+refhq]
    movu     [imatq+  0+refhq], m0
    punpcklbw               m2, m0, m10
    punpckhbw               m3, m0, m10
    psllw                   m6, m2, 7
    psllw                   m7, m3, 7
    pmaddwd                 m4, m2, m2
    pmaddwd                 m5, m3, m3
    pmulhrsw                m6, m2
    pmulhrsw                m7, m3
    pmaddwd                 m0, m2, m6
    pmaddwd                 m1, m3, m7
    pmaddwd                 m8, m6, m6
    pmaddwd                 m9, m7, m7
    packuswb               m15, m6, m7
    movu     [imatq+386+refhq], m15
    paddd                   m4, m5
    paddd                   m0, m1
    paddd                   m8, m9
    punpcklwd               m5, m6, m10
    punpckhwd               m6, m10
    punpcklwd               m1, m7, m10
    punpckhwd               m7, m10
    punpcklwd               m9, m2, m10
    punpckhwd               m2, m10
    punpcklwd              m15, m3, m10
    punpckhwd               m3, m10
    paddd                   m6, m5
    paddd                   m7, m1
    paddd                   m2, m9
    paddd                   m3, m15
    paddd                   m6, m7
    paddd                   m2, m3
    REPX          {pslld x, 7}, m6, m2
    vperm2i128              m5, m4, m8, 0x31
    vinserti128             m4, xm8, 1
    vperm2i128              m1, m0, m6, 0x31
    vinserti128             m0, xm6, 1
    vextracti128           xm3, m2, 1
    paddd                   m4, m5
    paddd                   m0, m1
    paddd                  xm2, xm3
    punpckhqdq              m5, m4, m4
    punpckhqdq              m1, m0, m0
    punpckhqdq             xm3, xm2, xm2
    paddd                   m4, m5
    paddd                   m0, m1
    paddd                  xm2, xm3
    punpckldq               m4, m0
    psrlq                  xm3, xm2, 32
    punpckhqdq              m0, m4, m4
    paddd                   m4, m0
    paddd                  xm2, xm3
    punpcklqdq              m4, m2
    paddd                  m12, m4
    add                  refhq, 32
    jl .left.dir_c.loop

.shift:
    vextracti128           xm0, m12, 1
    mov                    t1d, -1
    lzcnt                  t0d, nd
    xor                    t0d, 31              ; nl2
    bzhi                   t1d, t1d, t0d
    mov                    t3d, 6
    test                    nd, t1d
    setnz                  t1b                  ; !!(n & ((1 << nl2) - 1))
    shl                     nd, 14
    pinsrd                 xm0, nd, 2
    sub                    t3d, t0d
    sub                    t3d, t1d             ; mat_sh
    jl .rshift
;.lshift:
    movd                   xm1, t3d
    pslld                  xm0, xm1
    pslld                 xm12, xm1
    jmp .end
.rshift:
    neg                    t3d
    movd                   xm1, t3d
    psrld                  xm0, xm1
    psrld                 xm12, xm1
.end:
    mov                    t1d, 2
    movd                   xm2, t1d
    punpcklqdq             xm3, xm2, xm2
    paddd                 xm12, xm2
    paddd                  xm0, xm3
    psrlq                  xm4, xm12, 32
    pslldq                 xm1, xm0, 4
    psrldq                 xm5, xm12, 8
    vpblendd               xm1, xm4, 0x1
    vpblendd               xm0, xm5, 0x1
    mova             [matq+ 0], xm12
    mova             [matq+16], xm1
    mova             [matq+32], xm0
    RET

cglobal cfl_mh_pred_c_8bpc, 4, 13, 16, dst, ds, src, w, h, a, _, a2, _
 DECLARE_REG_TMP 9, 10, 11, 12
    movifnidn               aq, amp
    movifnidn               hd, hm
    lea                     r8, [pd_126]
%define base r8-pd_126
    call .prep_a0_a1
    call .calc_a2v2
    movd                  xm15, a2d
    vpbroadcastd            m9, [base+pd_126]
    vpbroadcastd           m10, [base+pd_29]
    vpbroadcastd           m15, xm15
    cmp                     wd, 8
    je .w8
    jg .w16

.w4:
    pmovzxbd                m0, [srcq]
    mova                    m1, m0
    call .pred
    packuswb                m0, m0
    vextracti128           xm1, m0, 1
    movd          [dstq+dsq*0], xm0
    movd          [dstq+dsq*1], xm1
    add                   srcq, 8
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .w4
    jmp .ret

.w8:
    pmovzxbd                m0, [srcq]
    mova                    m1, m0
    call .pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq                [dstq], xm0
    add                   srcq, 8
    add                   dstq, dsq
    dec                     hd
    jg .w8
    jmp .ret

.w16:
    mov                     wd, wd
    add                   dstq, wq
    neg                     wq
.w16.yloop:
    sub                   srcq, wq
    mov                     t0, wq
.w16.xloop:
    pmovzxbd                m0, [srcq+t0]
    mova                    m1, m0
    call .pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq             [dstq+t0], xm0
    add                     t0, 8
    jl .w16.xloop
    add                   dstq, dsq
    dec                     hd
    jg .w16.yloop
.ret:
    RET

.pred:
    pcmpeqd                 m7, m7
    psrld                   m7, 31              ; pd_1
    pslld                   m8, m7, 4           ; pd_16
    psllw                   m3, m1, 7
    pmulhrsw                m1, m3
    por                     m2, m0, m7
    por                     m3, m1, m7
    REPX       {cvtdq2ps x, x}, m2, m3
    REPX         {psrld x, 23}, m2, m3
    REPX         {psubd x, m9}, m2, m3
    paddd                   m2, m11
    paddd                   m3, m12
    REPX      {psubusw x, m10}, m2, m3          ; drop
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
    psubd                   m2, m8, m2          ; adj
    psubd                   m3, m8, m3
    pabsd                   m4, m0
    pabsd                   m5, m1
    psrld                   m8, 4
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
    paddd                   m0, m15
    packssdw                m0, m0
    ret

.prep_a0_a1:
    vpbroadcastd           m13, [aq+0]
    vpbroadcastd           m14, [aq+4]
    pcmpeqd                m10, m10
    psrld                   m9, m10, 31         ; pd_1
    psrld                  m10, 25              ; pd_127
    pabsd                  m11, m13
    pabsd                  m12, m14
    REPX          {pabsd x, x}, m11, m12
    REPX           {por x, m9}, m11, m12
    REPX       {cvtdq2ps x, x}, m11, m12
    REPX         {psrld x, 23}, m11, m12
    REPX        {psubd x, m10}, m11, m12
    REPX         {paddd x, m9}, m11, m12
    ret

.calc_a2v2:
    mov                    a2d, [aq+8]
    mov                    t1d, 11              ; 31+1+8-29
    xor                    t0d, t0d
    sub                    t0d, a2d
    cmovs                  t0d, a2d
    lzcnt                  t0d, t0d
    xor                    t2d, t2d
    sub                    t1d, t0d
    cmovb                  t1d, t2d             ; drop
    mov                    t0d, t1d
    shr                    t1d, 1               ; ash
    sub                    t0d, t1d             ; bsh
    mov                    t3d, 0x80
    sarx                   a2d, a2d, t1d
    shrx                   t3d, t3d, t0d
    imul                   a2d, t3d
    lea                    t2d, [t0+t1-16]
    neg                    t2d                  ; adj
    jg .calc_a2v2.shift
    ret
.calc_a2v2.shift:
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

cglobal cfl_mh_pred_t_8bpc, 4, 13, 16, dst, ds, src, w, h, a, flags, a2, _
 DECLARE_REG_TMP 9, 10, 11, 12
    mov                 flagsd, flagsm
    movifnidn               aq, amp
    movifnidn               hd, hm
    lea                     r8, [pd_126]
%define base r8-pd_126
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).prep_a0_a1
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).calc_a2v2
    movd                  xm15, a2d
    vpbroadcastd            m9, [base+pd_126]
    vpbroadcastd           m10, [base+pd_29]
    vpbroadcastd           m15, xm15
    mov                     t1, -64
    xor                    t2d, t2d
    test                flagsb, 0x4
    cmovz                   t1, t2
    setnz                  t2b
    test                flagsb, 0x8
    setnz                  t0b
    and                    t0d, t2d
    add                     t1, t0
    mov                    t2d, wd
    neg                     t2
    cmp                     wd, 8
    je .w8
    jg .w16

.w4:
    pmovzxbd               xm0, [srcq+t1]
    pmovzxbd                m1, [srcq]
    mov                     t1, t2
    vinserti128             m0, xm1, 1
    jmp .w4.loop.start
.w4.loop:
    pmovzxbd                m0, [srcq+t1]
    pmovzxbd                m1, [srcq]
.w4.loop.start:
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    packuswb                m0, m0
    vextracti128           xm1, m0, 1
    movd          [dstq+dsq*0], xm0
    movd          [dstq+dsq*1], xm1
    add                   srcq, 8
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .w4
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).ret

.w8:
    pmovzxbd                m0, [srcq+t1]
    pmovzxbd                m1, [srcq]
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq                [dstq], xm0
    add                   srcq, 8
    add                   dstq, dsq
    mov                     t1, t2
    dec                     hd
    jg .w8
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).ret

.w16:
    mov                     wd, wd
    add                   dstq, wq
    neg                     wq
.w16.yloop:
    sub                   srcq, wq
    add                     t1, srcq
    mov                     t0, wq
.w16.xloop:
    pmovzxbd                m0, [t1+t0]
    pmovzxbd                m1, [srcq+t0]
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq             [dstq+t0], xm0
    add                     t0, 8
    jl .w16.xloop
    add                   dstq, dsq
    mov                     t1, t2
    dec                     hd
    jg .w16.yloop
    jmp mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).ret

cglobal cfl_mh_pred_l_8bpc, 4, 14, 16, dst, ds, src, w, h, a, flags, a2, _, l
 DECLARE_REG_TMP 10, 11, 12, 13
    mov                 flagsd, flagsm
    movifnidn               aq, amp
    movifnidn               hd, hm
    lea                     r8, [pd_126]
%define base r8-pd_126
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).prep_a0_a1
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).calc_a2v2
    movd                  xm15, a2d
    vpbroadcastd            m9, [base+pd_126]
    vpbroadcastd           m10, [base+pd_29]
    vpbroadcastd           m15, xm15
    test                flagsb, 0x8
    jz .no_left
    lea                     lq, [srcq+32*32+1]
    cmp                     wd, 8
    je .w8
    jg .w16

.w4:
    pmovzxbd               xm2, [lq]
    punpckhqdq             xm3, xm2, xm2
    vinserti128             m2, xm3, 1
    pmovzxbd                m0, [srcq-1]
    pmovzxbd                m1, [srcq]
    vpblendd                m0, m2, 0x11
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    packuswb                m0, m0
    vextracti128           xm1, m0, 1
    movd          [dstq+dsq*0], xm0
    movd          [dstq+dsq*1], xm1
    add                     lq, 4
    add                   srcq, 8
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .w4
    jmp .ret

.w8:
    movd                   xm2, [lq]
    pmovzxbd               xm2, xm2
    pmovzxbd                m0, [srcq-1]
    pmovzxbd                m1, [srcq]
    vpblendd                m0, m2, 0x1
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq                [dstq], xm0
    add                     lq, 2
    add                   srcq, 8
    add                   dstq, dsq
    dec                     hd
    jg .w8
    jmp .ret

.w16:
    mov                     wd, wd
    add                   dstq, wq
    neg                     wq
.w16.yloop:
    sub                   srcq, wq
    add                     t1, srcq
    mov                     t0, wq
    movd                   xm2, [lq]
    pmovzxbd               xm2, xm2
    pmovzxbd                m0, [srcq+t0-1]
    pmovzxbd                m1, [srcq+t0]
    vpblendd                m0, m2, 0x1
    jmp .w16.xloop.start
.w16.xloop:
    pmovzxbd                m0, [srcq+t0-1]
    pmovzxbd                m1, [srcq+t0]
.w16.xloop.start:
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq             [dstq+t0], xm0
    add                     t0, 8
    jl .w16.xloop
    add                     lq, 2
    add                   dstq, dsq
    dec                     hd
    jg .w16.yloop
.ret:
    RET

.no_left:
    cmp                     wd, 8
    je .no_left.w8
    jg .no_left.w16

.no_left.w4:
    vbroadcasti128          m2, [base+pb_0to15]
    pmovzxbd                m0, [srcq-1]
    pmovzxbd                m1, [srcq]
    pshufd                  m2, m2, q3211
    pshufb                  m0, m2
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    packuswb                m0, m0
    vextracti128           xm1, m0, 1
    movd          [dstq+dsq*0], xm0
    movd          [dstq+dsq*1], xm1
    add                     lq, 4
    add                   srcq, 8
    lea                   dstq, [dstq+dsq*2]
    sub                     hd, 2
    jg .no_left.w4
    jmp .ret

.no_left.w8:
    vbroadcasti128          m2, [base+pb_0to15]
    pmovzxbd                m0, [srcq-1]
    pmovzxbd                m1, [srcq]
    pshufd                 xm3, xm2, q3211
    vpblendd                m2, m3, 0x1
    pshufb                  m0, m2
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq                [dstq], xm0
    add                     lq, 2
    add                   srcq, 8
    add                   dstq, dsq
    dec                     hd
    jg .no_left.w8
    jmp .ret

.no_left.w16:
    mov                     wd, wd
    add                   dstq, wq
    neg                     wq
.no_left.w16.yloop:
    vbroadcasti128          m2, [base+pb_0to15]
    sub                   srcq, wq
    add                     t1, srcq
    mov                     t0, wq
    pmovzxbd                m0, [srcq+t0-1]
    pmovzxbd                m1, [srcq+t0]
    pshufd                 xm3, xm2, q3211
    vpblendd                m2, m3, 0x1
    pshufb                  m0, m2
    jmp .no_left.w16.xloop.start
.no_left.w16.xloop:
    pmovzxbd                m0, [srcq+t0-1]
    pmovzxbd                m1, [srcq+t0]
.no_left.w16.xloop.start:
    call mangle(private_prefix %+ _cfl_mh_pred_c_8bpc_avx2).pred
    vpermq                  m0, m0, q3220
    packuswb               xm0, xm0
    movq             [dstq+t0], xm0
    add                     t0, 8
    jl .no_left.w16.xloop
    add                   dstq, dsq
    dec                     hd
    jg .no_left.w16.yloop
    jmp .ret

%endif ; ARCH_X86_64
