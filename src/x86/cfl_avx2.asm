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

pb_0to15: db  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
lshuf4:   db  0, -1,  1, -1,  3, -1,  5, -1,  8, -1,  9, -1, 11, -1, 13, -1
lshuf8:   db  0, -1,  1, -1,  3, -1,  5, -1,  7, -1,  9, -1, 11, -1, 13, -1
dc_shuf: times 4 db 0, -1
         times 4 db 8, -1
pb_left_flt1:    db 0, 1, 2, 1
pb_left_flt2:    db 0, 1, 4, 1
pb_flt0: times 2 db 2, 2
pb_flt1: times 2 db 2, 1
pb_flt2: times 2 db 4, 1
pw_128:  times 2 dw 128
pd_1024:         dd 1024

%macro JMP_TABLE 3-*
    %xdefine %1_%2_table (%%table - 2*4)
    %xdefine %%base mangle(private_prefix %+ _%1_%2)
    %%table:
    %rep %0 - 2
        dd %%base %+ .%3 - (%%table - 2*4)
        %rotate 1
    %endrep
%endmacro

JMP_TABLE cfl_explicit_420_8bpc, avx2, \
    top.f0.w4,      top.f0.w8,      top.f0.w16,      top.f0.w32,       top.f0.w64,      \
    top.f1.w4,      top.f1.w8,      top.f1.w16,      top.f1.w32,       top.f1.w64,      \
    top.f2.w4,      top.f2.w8,      top.f2.w16,      top.f2.w32,       top.f2.w64,      \
    blk.f0.w4,      blk.f0.w8,      blk.f0.w16,      blk.f0.w32.prep,  blk.f0.w32.prep, \
    blk.f1.w4.prep, blk.f1.w8.prep, blk.f1.w16,      blk.f1.w32.prep0, blk.f1.w32.prep0,\
    blk.f2.w4.prep, blk.f2.w8.prep, blk.f2.w16.prep, blk.f2.w32.prep,  blk.f2.w64.prep, \
    pred_uv.w4,     pred_uv.w8,     pred_uv.w16,     pred_uv.w32,      pred_uv.w32

cextern div_recip

SECTION .text

INIT_YMM avx2
cglobal cfl_explicit_420_8bpc, 4, 15, 16, ptrs, strides, wpad, hpad, w, h, \
                                          flags, tbl, flt, cstride
    movifnidn               wd, wm
    movifnidn               hd, hm
    mov                 flagsd, flagsm
    mov               cstrideq, [stridesq+8]
    mov               stridesq, [stridesq+0]
    pcmpeqd                m15, m15
    test                flagsb, 0x8             ; have_left
    jz .no_left

;.left:
 INIT_XMM avx2
    mov                   fltd, flagsd
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, _, flt, cstride, \
             row0, row1, row2, row3, row
 DECLARE_REG_TMP 7, 13, 14
    mov                  row0q, [ptrsq+24]
    lea                   rowq, [ystrideq*2]
    xor                    t0d, t0d
    cmp                    h0d, 64
    sete                   t0b
    shlx                  rowq, rowq, t0
    shl                  hpadd, 2
    setnz                  t1b
    mov                     hd, h0d
    sub                     hd, hpadd
    sub                     hb, t1b
    shrx                    hd, hd, t0d
    push                    hq
    lea                  row1q, [row0q+rowq*1]
    lea                  row2q, [row0q+rowq*2]
    lea                  row3q, [rowq*3]
    add                  row3q, row0q
    and                   fltd, 0x3             ; filter_type
    cmp                   fltd, 1
    jb .left.luma.f0
    je .left.luma.f1
 ; t0=_, t1=row3, t2=row
;.left.luma.f2:
    vpbroadcastd          ym14, [pb_left_flt2]
    cmp                    h0d, 64
    je .left.luma.f2.h64
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, _, flt, cstride, \
             ysrc, ystride3, _, _, _
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
    sub                     hd, 4
    jz .left.chroma
    xor                    t0d, t0d
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
    xor                    t0d, 1
    jz .left.luma.f2.acc
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
.left.luma.f2.acc:
    REPX         {paddw m0, x}, m5, m1
    mova                    m9, m8
    sub                     hd, 4
    ja .left.luma.f2.loop
    jz .left.chroma
    paddw                   m1, m5
    test                   t0d, 1
    jz .left.luma.f2.pad_odd
    pshufd                  m1, m1, q3333
    pshuflw                 m2, m1, q2301
    pshufhw                 m2, m2, q2301
    jmp .left.luma.f2.pad
.left.luma.f2.pad_odd:
    pshufd                  m2, m1, q3333
    pshuflw                 m1, m2, q2301
    pshufhw                 m1, m1, q2301
.left.luma.f2.pad:
    cmp                  hpadd, 8
.left.luma.f2.pad1:
    paddw                   m0, m1
    jb .left.chroma
    paddw                   m0, m2
    je .left.chroma
    paddw                   m0, m1
    jmp .left.chroma
.left.luma.f2.h64:
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, h, ystride3, flt, cstride, \
             row0, row1, row2, row3, row
    push                   h0q
 DECLARE_REG_TMP 5
    lea              ystride3q, [ystrideq*3]
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
    psrlw                  m13, m15, 8
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
    sub                     hd, 4
    xor                    t0d, t0d
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
    xor                    t0d, 1
    jz .left.luma.f2.h64.acc
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
.left.luma.f2.h64.acc:
    REPX         {paddw m0, x}, m2, m1
    sub                     hd, 2
    ja .left.luma.f2.h64.loop
    pop                    h0q
    jz .left.chroma
    movd                    m1, [row3q+ystrideq*2-4]
    movd                    m2, [row3q+ystride3q -2]
    pmaddubsw               m1, m14
    punpcklwd               m2, m12
    pand                    m2, m13
    paddw                   m1, m2
    pshufd                  m2, m1, q0000
    pshuflw                 m1, m2, q2301
    pshufhw                 m1, m1, q2301
    cmp                  hpadd, 16
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
    test                   t0d, 1
    jnz .left.luma.f2.h64.pad_half.even
    pshuflw                 m1, m1, q2301
    pshufhw                 m1, m1, q2301
.left.luma.f2.h64.pad_half.even:
    paddw                   m0, m1
    jz .left.luma.f2.h64.pad_half.odd
    mova                    m2, m1
    pshufhw                 m1, m1, q2301
    jmp .left.luma.f2.h64.pad_half.even1
.left.luma.f2.h64.pad_half.odd:
    pshufhw                 m2, m1, q2301
.left.luma.f2.h64.pad_half.even1:
    pop                    h0q
    cmp                  hpadd, 4
    je .left.chroma
    punpckhqdq              m1, m1
    punpckhqdq              m2, m2
    cmp                  hpadd, 20
    jmp .left.luma.f2.pad1
.left.luma.f1:
    vpbroadcastd          ym14, [pb_left_flt1]
    movd                    m0, [row0q+ystrideq*0-4]
    movd                    m1, [row0q+ystrideq*1-4]
    movd                    m2, [row1q+ystrideq*0-4]
    movd                    m3, [row1q+ystrideq*1-4]
    movd                    m4, [row2q+ystrideq*0-4]
    movd                    m5, [row2q+ystrideq*1-4]
    movd                    m6, [row3q+ystrideq*0-4]
    movd                    m7, [row3q+ystrideq*1-4]
    punpckldq               m0, m1
    punpckldq               m2, m3
    punpckldq               m4, m5
    punpckldq               m6, m7
    punpcklqdq              m0, m2
    punpcklqdq              m4, m6
    REPX    {pmaddubsw x, m14}, m0, m4
    ; xxx might be a better way, alt them for each loop iter
    ; so instead of 3+1 and 1+3 do 6+2 and 2+6
    pshuflw                 m4, m4, q2301
    pshufhw                 m4, m4, q2301
    paddw                   m0, m4
    sub                     hd, 4
    jz .left.chroma
.left.luma.f1.loop:
    lea                  row0q, [row0q+rowq*4]
    lea                  row1q, [row1q+rowq*4]
    lea                  row2q, [row2q+rowq*4]
    lea                  row3q, [row3q+rowq*4]
    movd                    m1, [row0q+ystrideq*0-4]
    movd                    m2, [row0q+ystrideq*1-4]
    movd                    m3, [row1q+ystrideq*0-4]
    movd                    m4, [row1q+ystrideq*1-4]
    sub                     hd, 2
    jb .left.luma.f1.pad64_half
    movd                    m5, [row2q+ystrideq*0-4]
    movd                    m6, [row2q+ystrideq*1-4]
    movd                    m7, [row3q+ystrideq*0-4]
    movd                    m8, [row3q+ystrideq*1-4]
    punpckldq               m1, m2
    punpckldq               m3, m4
    punpckldq               m5, m6
    punpckldq               m7, m8
    punpcklqdq              m1, m3
    punpcklqdq              m5, m7
    REPX    {pmaddubsw x, m14}, m1, m5
    pshuflw                 m5, m5, q2301
    pshufhw                 m5, m5, q2301
    REPX         {paddw m0, x}, m1, m5
    sub                     hd, 2
    ja .left.luma.f1.loop
    jz .left.chroma
    cmp                    h0d, 64
    je .left.luma.f1.pad64
    punpckhqdq              m1, m5, m5
    pshuflw                 m2, m1, q2301
    pshufhw                 m2, m2, q2301
    paddw                   m1, m2
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
    paddw                   m1, m2
    cmp                  hpadd, 16
    jmp .left.luma.pad
.left.luma.f1.pad64_half:
    lea                     t2, [ystrideq*3]
    movd                    m5, [row1q+ystrideq*2-4]
    movd                    m6, [row1q+t2-4]
    punpckldq               m1, m2
    punpckldq               m3, m4
    shufps                  m5, m6, q0000
    punpcklqdq              m1, m3
    REPX    {pmaddubsw x, m14}, m1, m5
    pshuflw                 m6, m5, q2301
    pshufhw                 m6, m6, q2301
    REPX         {paddw m0, x}, m1, m6
    paddw                   m1, m5, m6
    cmp                  hpadd, 4
    je .left.chroma
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
    sub                     hd, 4
    jz .left.chroma
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
    paddw                   m0, m1
    sub                     hd, 2
    ja .left.luma.f0.loop
    jz .left.chroma
    cmp                    h0d, 64
    je .left.luma.f0.pad64
    pshufd                  m1, m1, q3333
    cmp                  hpadd, 8
    jmp .left.luma.pad
.left.luma.f0.pad64:
    lea                     t2, [ystrideq*3]
    movd                    m1, [row3q+ystrideq*2-2]
    movd                    m2, [row3q+t2-2]
    punpcklwd               m1, m2
    pshufd                  m1, m1, q0000
    pmaddubsw               m1, m14
.left.luma.f0.pad64cmp:
    cmp                  hpadd, 16
    jmp .left.luma.pad
.left.luma.f0.pad64_half:
    lea                     t2, [ystrideq*3]
    movd                    m5, [row1q+ystrideq*2-2]
    movd                    m6, [row1q+t2-2]
    punpcklwd               m1, m2
    punpcklwd               m3, m4
    punpcklwd               m5, m6
    punpckldq               m1, m3
    punpckldq               m5, m5
    punpcklqdq              m1, m5
    pmaddubsw               m1, m14
    paddw                   m0, m1
    pshufd                  m1, m1, q3333
    cmp                  hpadd, 4
    je .left.chroma
    cmp                  hpadd, 20
.left.luma.pad:
    paddw                   m0, m1
    jb .left.chroma
    paddw                   m0, m1
    je .left.chroma
    paddw                   m0, m1
.left.chroma:
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h0, _, _, _, cstride, \
             usrc, vsrc, _, h, row
 DECLARE_REG_TMP 6, 7, 8, 12, 14
    mov                  usrcq, [ptrsq+32]
    mov                  vsrcq, [ptrsq+40]
    pop                     hq
    cmp                    h0d, 64
    sete                   t0b
    mov                   rowq, cstrideq
    shlx                  rowq, rowq, t0
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
    jb .left.chroma.pad64_half
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
    je .left.chroma.pad64
    mov                    t4d, hpadd
.left.chroma.pad:
    imul                   t2d, t4d
    imul                   t3d, t4d
    add                    t0d, t2d
    add                    t1d, t3d
    jmp .top
.left.chroma.pad64:
    add                  usrcq, rowq
    add                  vsrcq, rowq
    mov                    t4d, hpadd
    shr                    t4d, 1
    movzx                  t2d, byte [usrcq+cstrideq]
    movzx                  t3d, byte [vsrcq+cstrideq]
    jmp .left.chroma.pad
.left.chroma.pad64_half:
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

 INIT_YMM avx2
.no_left:
    lea                  hpadd, [hpadq*4]
    pxor                    m0, m0
    pxor                   xm1, xm1
    jmp .top_no_left
.top:
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, flags, tbl, flt, cstride, \
             ytop0, ytop1, utop, vtop, ytopa
    movd                   xm1, t0d
    movd                   xm2, t1d
    mov                 flagsd, flagsm
    punpcklqdq             xm1, xm2
 DECLARE_REG_TMP 14, 13, 12, 6
.top_no_left:
    lea                   tblq, [cfl_explicit_420_8bpc_avx2_table]
%define base tblq-cfl_explicit_420_8bpc_avx2_table
    mov                   fltd, flagsd
    and                   fltd, 0x3             ; filter_type
    vpbroadcastd           m14, [base+pb_flt0+fltq*4]
    lea                   fltd, [fltq*5]
    lea                   fltq, [fltq*4+tblq]
    vbroadcasti128          m8, [base+pb_0to15]
    mova                    m7, m8
    mova                   xm3, xm8
    shl                  wpadd, 2
    jz .top_no_pad
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
    ; xxx rework regs? (just for readability)
    movd                  xm13, t0d
    movd                   xm9, t1d
    vpbroadcastb           m13, xm13
    vpbroadcastw            m9, xm9
    pminub                  m8, m13
    pminub                  m7, m9
.top_no_pad:
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
    movd                    m3, [utopq]
    movq                    m2, [ytop0q]
    movq                    m4, [ytop1q]
    movhps                  m3, [vtopq]
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m15
    paddw                   m2, m4
    jmp .acc_dc
.top.f0.w8:
    movq                    m3, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    movhps                  m3, [vtopq]
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m15
    paddw                   m2, m4
    psrlq                   m5, m3, 32
    paddw                   m3, m5
    jmp .acc_dc
 INIT_YMM avx2
.top.f0.w16:
    vinserti128             m7, xm3, 0
    movu                   xm3, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    vinserti128             m3, [vtopq], 1
    REPX    {pmaddubsw x, m14}, m2, m4
    pshufb                  m3, m8
    pmaddubsw               m3, m15
    paddw                   m2, m4
    pshufb                  m2, m7
    psrldq                  m5, m3, 8
    vextracti128           xm4, m2, 1
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm4
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f0.w32:
    mova                   xm6, [ytop0q+32]
    mova                  xm10, [ytop0q+48]
    movu                   xm5, [utopq+16]
    movu                   xm3, [utopq+ 0]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    vinserti128             m6, [ytop1q+32], 1
    vinserti128            m10, [ytop1q+48], 1
    vinserti128             m5, [vtopq+16], 1
    vinserti128             m3, [vtopq+ 0], 1
    REPX    {pmaddubsw x, m14}, m2, m4, m6, m10
    test                 wpadd, wpadd
    jnz .top.f0.w32.pad
.top.f0.w32.acc:
    REPX    {pmaddubsw x, m15}, m5, m3
    paddw                   m2, m4
    paddw                   m6, m10
    paddw                   m3, m5
    paddw                   m2, m6
    psrldq                  m5, m3, 8
    vextracti128           xm4, m2, 1
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm4 ; 32
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f0.w32.pad:
    pshufb                  m5, m8
    pshufb                 m10, m7
    cmp                  wpadd, 8
    jb .top.f0.w32.acc
    vinserti128             m9, xm9, 1
    pshufb                 m10, m6, m9
    pshufb                  m6, m7
    jmp .top.f0.w32.acc
.top.f0.w64:
    test                 wpadd, wpadd
    jnz .top.f0.w64.pad
    mova                    m2, [ytop0q]
    mova                    m3, [ytop1q]
    mova                    m4, [ytop0q+32]
    mova                    m5, [ytop1q+32]
    movu                    m6, [ytop0q+62]
    movu                   m10, [ytop1q+62]
    movu                   m11, [ytop0q+94]
    movu                   m12, [ytop1q+94]
    mova                  xm13, [utopq]
    vinserti128            m13, [vtopq], 1
    REPX    {pmaddubsw x, m14}, m2, m3, m4, m5, m6, m10, m11, m12
    paddw                   m2, m3
    paddw                   m4, m5
    paddw                   m6, m10
    mova                   xm3, [utopq+16]
    mova                   xm5, [utopq+32]
    mova                  xm10, [utopq+48]
    vinserti128             m3, [vtopq+16], 1
    vinserti128             m5, [vtopq+32], 1
    vinserti128            m10, [vtopq+48], 1
    paddw                  m11, m12
    paddw                   m2, m4
    paddw                   m6, m11
    pblendw                 m2, m6, 0xaa
    vextracti128           xm4, m2, 1
    psrlw                  m11, m15, 8
    REPX    {pmaddubsw x, m11}, m13, m3, m5, m10
    paddw                  xm2, xm4
    paddw                   m3, m13
    paddw                   m5, m10
    paddw                   m3, m5
    psrldq                  m5, m3, 8
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f0.w64.pad:
    mova                   xm3, [utopq+ 0]
    mova                   xm5, [utopq+16]
    mova                  xm11, [utopq+32]
    mova                    m2, [ytop0q]
    mova                    m4, [ytop1q]
    movu                    m6, [ytop0q+30]
    movu                   m10, [ytop1q+30]
    vinserti128             m3, [vtopq+ 0], 1
    vinserti128             m5, [vtopq+16], 1
    vinserti128            m11, [vtopq+32], 1
    psrlw                  m12, m15, 8
    REPX    {pmaddubsw x, m14}, m2, m4, m6, m10
    REPX    {pmaddubsw x, m12}, m3, m5
    paddw                   m2, m4
    paddw                   m6, m10
    paddw                   m3, m5
    pblendw                 m2, m6, 0xaa
    mova                   xm4, [ytop0q+64]
    mova                  xm10, [ytop0q+80]
    mova                   xm5, [ytop0q+96]
    mova                   xm6, [ytop0q+112]
    mova                  xm12, [utopq+48]
    vinserti128             m4, [ytop1q+64], 1
    vinserti128            m10, [ytop1q+80], 1
    vinserti128             m5, [ytop1q+96], 1
    vinserti128             m6, [ytop1q+112], 1
    vinserti128            m12, [vtopq+48], 1
    REPX    {pmaddubsw x, m14}, m4, m10, m5, m6
    pshufb                 m12, m8
    pshufb                  m6, m7
    cmp                  wpadd, 8
    jb .top.f0.w64.acc
    vinserti128             m9, xm9, 1
    pshufb                  m6, m5, m9
    pshufb                  m5, m7
    cmp                  wpadd, 16
    jb .top.f0.w64.acc
    pshufb                 m12, m11, m13
    pshufb                 m11, m8
    pshufb                  m6, m10, m9
    pshufb                  m5, m10, m9
    pshufb                 m10, m7
    cmp                  wpadd, 24
    jb .top.f0.w64.acc
    pshufb                  m6, m4, m9
    pshufb                  m5, m4, m9
    pshufb                 m10, m4, m9
    pshufb                  m4, m7
.top.f0.w64.acc:
    psrlw                  m13, m15, 8
    REPX    {pmaddubsw x, m13}, m11, m12
    paddw                  m11, m12
    paddw                   m5, m6
    paddw                   m4, m10
    pslldq                  m5, 2
    paddw                   m3, m11
    pblendw                 m4, m5, 0xaa
    psrldq                  m5, m3, 8
    paddw                   m2, m4
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    psrlq                  xm5, xm3, 32
    vextracti128           xm4, m2, 1
    paddw                  xm3, xm5
    paddw                  xm2, xm4
    jmp .acc_dc

 INIT_XMM avx2
.top.f1.w4:
    movq                    m2, [ytop0q]
    movhps                  m2, [ytop1q]
    movd                    m3, [utopq]
    movhps                  m3, [vtopq]
    pshufb                  m4, m2, [base+lshuf4]
    pmaddubsw               m2, m14
    pmaddubsw               m3, m15
    paddw                   m2, m4
    jmp .acc_dc
.top.f1.w8:
    mova                   m12, [base+lshuf8]
    movq                    m3, [utopq]
    movu                    m2, [ytop0q]
    movu                    m4, [ytop1q]
    movhps                  m3, [vtopq]
    pshufb                  m6, m2, m12
    pshufb                  m7, m4, m12
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m15
    paddw                   m6, m7
    paddw                   m2, m4
    psrlq                   m5, m3, 32
    paddw                   m2, m6
    paddw                   m3, m5
    jmp .acc_dc
 INIT_YMM avx2
.top.f1.w16:
    vbroadcasti128         m12, [base+lshuf8]
    movu                   xm3, [utopq]
    movu                   xm2, [ytop0q+ 0]
    movu                   xm4, [ytop0q+16]
    vinserti128             m2, [ytop1q+ 0], 1
    vinserti128             m4, [ytop1q+16], 1
    vinserti128             m3, [vtopq], 1
    psrlw                  m13, m15, 8
    pshufb                  m5, m2, m12     ; low left
    pshufb                  m3, m8
    palignr                 m6, m4, m2, 15  ; high left
    REPX    {pmaddubsw x, m14}, m2, m4
    pmaddubsw               m3, m15
    pand                    m6, m13
    paddw                   m2, m5
    paddw                   m4, m6
    pshufb                  m4, m7
    paddw                   m2, m4
    vextracti128           xm4, m2, 1
    psrldq                  m5, m3, 8
    paddw                   m3, m5
    vpermq                  m3, m3, q2020
    paddw                  xm2, xm4
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f1.w32:
    vbroadcasti128         m13, [base+lshuf8]
    mova                   xm2, [ytop0q+ 0]
    mova                   xm3, [ytop0q+16]
    mova                   xm4, [ytop0q+32]
    mova                   xm6, [ytop0q+48]
    movu                   xm5, [utopq+16]
    vinserti128             m2, [ytop1q+ 0], 1
    vinserti128             m3, [ytop1q+16], 1
    vinserti128             m4, [ytop1q+32], 1
    vinserti128             m6, [ytop1q+48], 1
    vinserti128             m5, [vtopq+16], 1
    pshufb                 m10, m2, m13
    palignr                m11, m3, m2, 15
    palignr                m12, m4, m3, 15
    palignr                m13, m6, m4, 15
    REPX    {pmaddubsw x, m14}, m2, m3, m4, m6
    paddw                   m2, m10
    psrlw                  m10, m15, 8
    REPX         {pand x, m10}, m11, m12, m13
    paddw                   m2, m3
    movu                   xm3, [utopq+ 0]
    vinserti128             m3, [vtopq+ 0], 1
    paddw                   m2, m11
    paddw                   m4, m12
    paddw                   m6, m13
    test                 wpadd, wpadd
    jnz .top.f1.w32.pad
.top.f1.w32.acc:
    REPX    {pmaddubsw x, m15}, m5, m3
    paddw                   m4, m6
    paddw                   m2, m4
    paddw                   m3, m5
    psrldq                  m5, m3, 8
    vextracti128           xm4, m2, 1
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm4
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f1.w32.pad:
    pshufb                  m5, m8
    pshufb                  m6, m7
    cmp                  wpadd, 8
    jb .top.f1.w32.acc
    vinserti128             m9, xm9, 1
    pshufb                  m6, m4, m9
    pshufb                  m4, m7
    jmp .top.f1.w32.acc
.top.f1.w64:
    test                 wpadd, wpadd
    jnz .top.f1.w64pad
    mova                   xm2, [ytop0q+0x00]
    mova                   xm3, [ytop0q+0x10]
    mova                   xm4, [ytop0q+0x20]
    mova                   xm5, [ytop0q+0x30]
    mova                  xm12, [utopq+ 0]
    mova                  xm13, [utopq+16]
    vinserti128             m2, [ytop1q+0x00], 1
    vinserti128             m3, [ytop1q+0x10], 1
    vinserti128             m4, [ytop1q+0x20], 1
    vinserti128             m5, [ytop1q+0x30], 1
    vinserti128            m12, [vtopq+ 0], 1
    vinserti128            m13, [vtopq+16], 1
    pxor                   m11, m11
    psrlw                  m15, 8
    pshufb                  m6, m2, m11
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
    REPX    {pmaddubsw x, m14}, m2, m4
    REPX    {pmaddubsw x, m15}, m12, m13
    REPX         {pand x, m15}, m6, m8
    paddw                   m2, m4
    paddw                  m12, m13
    paddw                   m6, m8
    paddw                   m2, m6
    mova                  xm13, [utopq+32]
    vinserti128            m13, [vtopq+32], 1
    palignr                 m4, m3, m5, 15
    palignr                 m6, m7, m3, 13
    palignr                 m8, m9, m7, 15
    palignr                m11, m10, m9, 13
    REPX         {pslld x, 16}, m7, m10
    pblendw                 m4, m6, 0xaa
    pblendw                 m8, m11, 0xaa
    mova                  xm11, [utopq+48]
    vinserti128            m11, [vtopq+48], 1
    pblendw                 m3, m7, 0xaa
    pblendw                 m9, m10, 0xaa
    REPX    {pmaddubsw x, m14}, m3, m9
    REPX    {pmaddubsw x, m15}, m13, m11
    REPX         {pand x, m15}, m4, m8
    paddw                   m4, m8
    paddw                   m3, m9
    paddw                  m12, m13
    paddw                  m12, m11
    paddw                   m2, m4
    paddw                   m2, m3
    vextracti128           xm4, m2, 1
    psrldq                  m3, m12, 8
    paddw                   m3, m12
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm4
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    pcmpeqw               xm15, xm15
    jmp .acc_dc
.top.f1.w64pad:
    mova                   xm2, [ytop0q+0x00]
    mova                   xm3, [ytop0q+0x10]
    mova                   xm4, [ytop0q+0x20]
    mova                   xm5, [ytop0q+0x30]
    vinserti128             m2, [ytop1q+0x00], 1
    vinserti128             m3, [ytop1q+0x10], 1
    vinserti128             m4, [ytop1q+0x20], 1
    vinserti128             m5, [ytop1q+0x30], 1
    pxor                    m6, m6
    psrlw                  m15, 8
    pshufb                 m10, m2, m6
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
    mova                   xm3, [utopq+ 0]
    mova                   xm6, [utopq+16]
    vinserti128             m3, [vtopq+ 0], 1
    vinserti128             m6, [vtopq+16], 1
    REPX    {pmaddubsw x, m14}, m2, m4
    REPX         {pand x, m15}, m10, m12
    paddw                  m10, m12
    paddw                   m2, m4
    paddw                   m2, m10
    REPX    {pmaddubsw x, m15}, m3, m6
    paddw                   m3, m6
    mova                  xm12, [ytop0q+0x40]
    mova                   xm4, [ytop0q+0x50]
    mova                  xm10, [ytop0q+0x60]
    mova                   xm6, [ytop0q+0x70]
    vinserti128            m12, [ytop1q+0x40], 1
    vinserti128             m4, [ytop1q+0x50], 1
    vinserti128            m10, [ytop1q+0x60], 1
    vinserti128             m6, [ytop1q+0x70], 1
    palignr                 m5, m12, m5, 15
    palignr                m15, m4, m12, 15
    palignr                m11, m10, m4, 15
    palignr                m14, m6, m10, 15
    REPX        {pshufb x, m7}, m6, m14
    cmp                  wpadd, 8
    jb .top.f1.w64pad.acc_luma
    vinserti128             m9, xm9, 1
    pshufb                  m6, m10, m9
    pshufb                 m14, m11, m9
    REPX        {pshufb x, m7}, m10, m11
    cmp                  wpadd, 16
    jb .top.f1.w64pad.acc_luma
    REPX   {pshufb x,  m4, m9}, m6, m10
    REPX   {pshufb x, m15, m9}, m14, m11
    REPX        {pshufb x, m7}, m4, m15
    cmp                  wpadd, 24
    jb .top.f1.w64pad.acc_luma
    REPX   {pshufb x, m12, m9}, m6, m10, m4
    REPX   {pshufb x,  m5, m9}, m14, m11, m15
    REPX        {pshufb x, m7}, m12, m5
.top.f1.w64pad.acc_luma:
; todo see if we can do luma+chroma by getting rid of
; m9/m13: might be faster done together while needing
; a few more ops to broadcast last of non terminal
; lane
; m0m1=left m2=yacc m3=uvacc m4m5m6=y m7 m8=pad
; m9 m10=y m11=uv m12=y m13 m14=weights m15=uv
    REPX         {pslld x, 16}, m15, m14, m4, m6
    pblendw                 m5, m15, 0xaa
    pblendw                m11, m14, 0xaa
    vpbroadcastd           m14, [base+pb_flt1]
    pblendw                m12, m4, 0xaa
    pblendw                m10, m6, 0xaa
    mova                   xm4, [utopq+32]
    mova                   xm6, [utopq+48]
    vinserti128             m4, [vtopq+32], 1
    vinserti128             m6, [vtopq+48], 1
    pcmpeqw                m15, m15
    psrlw                   m7, m15, 8
    REPX    {pmaddubsw x, m14}, m12, m10
    REPX          {pand x, m7}, m5, m11
    paddw                   m5, m11
    paddw                   m2, m5
    paddw                  m12, m10
    paddw                   m2, m12
    pshufb                  m6, m8
    vextracti128           xm9, m2, 1
    cmp                  wpadd, 16
    jb .top.f1.w64pad.acc_chroma
    pshufb                  m6, m4, m13
    pshufb                  m4, m8
.top.f1.w64pad.acc_chroma:
    REPX     {pmaddubsw x, m7}, m6, m4
    paddw                   m4, m6
    paddw                   m3, m4
    psrldq                  m5, m3, 8
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    paddw                  xm2, xm9
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc

 INIT_XMM avx2
.top.f2.w4:
    movq                    m4, [ytopaq]
    movq                    m6, [ytop1q]
    movq                    m2, [ytop0q]
    movd                    m3, [utopq]
    movhps                  m3, [vtopq]
    psrlw                  m13, m15, 8
    pshufb                  m5, m2, [base+lshuf4]
    REPX         {pand x, m13}, m4, m6
    pmaddubsw               m2, m14
    pmaddubsw               m3, m15
    paddw                   m4, m5
    paddw                   m4, m6
    paddw                   m2, m4
    jmp .acc_dc
.top.f2.w8:
    movu                    m4, [ytopaq]
    movu                    m6, [ytop1q]
    movu                    m2, [ytop0q]
    movq                    m3, [utopq]
    movhps                  m3, [vtopq]
    psrlw                  m13, m15, 8
    pshufb                  m5, m2, [base+lshuf8]
    REPX         {pand x, m13}, m4, m6
    pmaddubsw               m2, m14
    pmaddubsw               m3, m15
    paddw                   m4, m5
    paddw                   m4, m6
    paddw                   m2, m4
    psrlq                   m5, m3, 32
    paddw                   m3, m5
    jmp .acc_dc
.top.f2.w16:
 INIT_YMM avx2
    movu                    m4, [ytopaq]
    movu                    m6, [ytop1q]
    movu                   xm2, [ytop0q+ 0]
    movu                  xm12, [ytop0q+16]
    movu                   xm3, [utopq]
    vinserti128             m3, [vtopq], 1
    psrlw                  m13, m15, 8
    REPX         {pand x, m13}, m4, m6
    paddw                   m4, m6
    vextracti128           xm6, m4, 1
    pshufb                 xm5, xm2, [base+lshuf8]  ; l low
    ; xxx change to m8 once pad shuf is in m11
    palignr               xm11, xm12, xm2, 15       ; l high
    pshufb                  m3, m8                  ; wpad c
    REPX   {pmaddubsw x, xm14}, xm2, xm12
    pmaddubsw               m3, m15
    REPX        {pand x, xm13}, xm5, xm11
    paddw                  xm4, xm5
    paddw                  xm6, xm11
    paddw                  xm2, xm4
    paddw                 xm12, xm6
    pshufb                xm12, xm7                 ; wpad l
    paddw                  xm2, xm12
    psrldq                  m5, m3, 8
    paddw                   m3, m5
    vpermq                  m3, m3, q3220
    psrlq                  xm5, xm3, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f2.w32:
    mova                   xm3, [ytop0q+16]
    mova                   xm4, [ytop0q+32]
    mova                   xm5, [ytop0q+48]
    mova                   xm6, [ytopaq+32]
    mova                  xm10, [ytopaq+48]
    movu                   xm2, [utopq+16]
    vinserti128             m6, [ytop1q+32], 1
    vinserti128            m10, [ytop1q+48], 1
    vinserti128             m2, [vtopq+16], 1
    psrlw                  m13, m15, 8
    palignr               xm11, xm4, xm3, 15
    palignr               xm12, xm5, xm4, 15
    REPX   {pmaddubsw x, xm14}, xm4, xm5
    REPX        {pand x,  m13}, m6, m10
    REPX        {pand x, xm13}, xm11, xm12
    paddw                   m6, m11
    paddw                  m10, m12
    paddw                   m4, m6
    paddw                   m5, m10
    mova                  xm10, [ytop0q]
    movu                   m11, [ytopaq]
    movu                   m12, [ytop1q]
    test                 wpadd, wpadd
    jnz .top.f2.w32.pad
.top.f2.w32.acc:
    paddw                   m4, m5
    pshufb                 xm6, xm10, [base+lshuf8]
    palignr                xm5, xm3, xm10, 15
    REPX   {pmaddubsw x, xm14}, xm10, xm3
    REPX        {pand x,  m13}, m11, m12
    REPX        {pand x, xm13}, xm6, xm5
    paddw                  m11, m12
    movu                  xm12, [utopq]
    vinserti128            m12, [vtopq], 1
    paddw                   m4, m11
    vextracti128          xm11, m4, 1
    REPX    {pmaddubsw x, m15}, m2, m12
    paddw                  xm6, xm5
    paddw                  xm3, xm10
    paddw                  xm4, xm6
    paddw                  xm3, xm11
    paddw                   m2, m12
    psrldq                  m5, m2, 8
    paddw                   m5, m2
    vpermq                  m5, m5, q3220
    paddw                  xm2, xm3, xm4
    psrlq                  xm3, xm5, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f2.w32.pad:
    pshufb                  m5, m7
    pshufb                  m2, m8
    cmp                  wpadd, 8
    jb .top.f2.w32.acc
    vinserti128             m9, xm9, 1
    pshufb                  m5, m4, m9
    pshufb                  m4, m7
    jmp .top.f2.w32.acc
.top.f2.w64:
    ; xxx can be sped up by having a nopad path
    mova                   xm2, [ytop0q+0x30]
    mova                   xm3, [ytop0q+0x40]
    mova                   xm4, [ytop0q+0x50]
    mova                   xm5, [ytop0q+0x60]
    mova                   xm6, [ytop0q+0x70]
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
    REPX         {pslld x, 16}, m3, m4
    pblendw                 m3, m5, 0x55
    pblendw                 m4, m6, 0x55
    paddw                   m3, m4
    REPX    {pmaddubsw x, m15}, m10, m11
    paddw                  m10, m11
    mova                   xm4, [ytop0q+0x00]
    mova                   xm5, [ytop0q+0x10]
    mova                   xm6, [ytop0q+0x20]
    mova                   xm9, [ytopaq+0x00]
    vinserti128             m9, [ytop1q+0x00], 1
    pshufb                xm11, xm4, [base+lshuf8]
    palignr               xm12, xm5, xm4, 13
    palignr               xm13, xm6, xm5, 15
    palignr                xm7, xm2, xm6, 13
    pblendw               xm11, xm12, 0xaa
    pblendw               xm13, xm7, 0xaa
    REPX         {pslld x, 16}, xm5, xm2
    pblendw                xm4, xm5, 0xaa
    pblendw                xm6, xm2, 0xaa
    REPX   {pmaddubsw x, xm14}, xm4, xm6
    REPX        {pand x, xm15}, xm11, xm13
    movu                  xm12, [ytopaq+0x0e]
    mova                   xm7, [ytopaq+0x20]
    movu                   xm5, [ytopaq+0x2e]
    vinserti128            m12, [ytop1q+0x0e], 1
    vinserti128             m7, [ytop1q+0x20], 1
    vinserti128             m5, [ytop1q+0x2e], 1
    paddw                 xm11, xm13
    paddw                  xm4, xm6
    mova                  xm13, [utopq+ 0]
    mova                   xm6, [utopq+16]
    vinserti128            m13, [vtopq+ 0], 1
    vinserti128             m6, [vtopq+16], 1
    paddw                  xm4, xm11
    paddw                   m3, m4
    pblendw                 m9, m12, 0xaa
    pblendw                 m7, m5, 0xaa
    REPX         {pand x, m15}, m9, m7
    paddw                   m9, m7
    paddw                   m3, m9
    vextracti128           xm2, m3, 1
    REPX    {pmaddubsw x, m15}, m13, m6
    paddw                  m13, m6
    paddw                  m10, m13
    psrldq                  m5, m10, 8
    paddw                   m5, m10
    vpermq                  m5, m5, q3220
    paddw                  xm2, xm3
    pcmpeqw               xm15, xm15
    psrlq                  xm3, xm5, 32
    paddw                  xm3, xm5
    jmp .acc_dc
.top.f2.w64.pad:
    pshufb                  m6, m7
    pshufb                 m11, m8
    cmp                  wpadd, 8
    jb .top.f2.w64.acc
    vinserti128             m9, xm9, 1
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

.no_edge:
    vpbroadcastd            m0, [base+pd_1024]
    vpbroadcastd            m1, [base+pw_128]
    pxor                   m15, m15
    jmp .extract_alphas
.no_top:
    test                flagsb, 8           ; have_left
    jz .no_edge
    pxor                    m2, m2
    pxor                   xm3, xm3
.acc_dc:
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, flags, tbl, flt, cstride
 DECLARE_REG_TMP 10, 11, 12
    mov                 flagsd, flagsm
    psrlw                 xm15, 15
    paddw                  xm0, xm2         ; 0xFF*64
    psubw                  xm1, xm3
    cmp                     wd, hd
    cmovnb                 t0d, wd
    cmovb                  t0d, hd
    psrldq                 xm3, xm0, 8
    paddw                  xm0, xm3         ; 0xFF*128 = 0x7F80
    pmaddwd                xm0, xm15        ; 0xFF*256 = 0xFF00
    pmaddwd                xm1, xm15
    psrlq                  xm3, xm0, 32
    paddd                  xm0, xm3         ; 0xFF*512 = 0x1FE00
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
    jp .non_pow2_scale
    mov                    t3d, 32
    cmp                    t2d, 64
    cmove                  t2d, t3d
    test                   t0d, t1d
    setnz                  t0b
    setz                   t3b
    tzcnt                  t1d, t2d
    add                    t1d, t0d
    shrx                   t2d, t2d, t3d
    movd                   xm2, t2d
    movd                   xm3, t1d
    pshufd                 xm4, xm2, q0000
    paddd                  xm0, xm2
    paddd                  xm1, xm4
    psrld                  xm0, xm3
    psrld                  xm1, xm3
    jmp .extract_alphas
.non_pow2_scale:
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
    psllw                  xm2, xm15, 15
    pcmpeqw               xm15, xm0
    movd                   xm3, t3d
    movd                   xm5, t2d
    psubw                  xm0, xm2
    psrld                 xm15, 16
    pshufd                 xm4, xm3, q0000
    pand                   xm5, xm15
    pmulhrsw               xm0, xm3
    pmulhrsw               xm1, xm4
    paddw                  xm3, xm5
    paddw                  xm0, xm3

.extract_alphas:
    vpbroadcastw            m0, xm0
    pshufb                 xm1, [base+dc_shuf]
    vinserti128             m1, xm1, 1
    mov                   r10d, flagsd ; av
 DEFINE_ARGS ptrs, ystride, wpad, hpad, w, h, au, tbl, flt, cstride, av
    and                    aud, 0xf800          ; alpha u
;   jz .pred_v ; todo see whether u/v paths are worth it
    and                    avd, 0xf8000000      ; alpha v
;   jz .pred_u
    sar                    auw, 6
    sar                    avd, 22
    movd                  xm12, aud
    movd                  xm13, avd
    pxor                   m15, m15
    vpbroadcastw           m12, xm12
    vpbroadcastw           m13, xm13

;.pred_uv:
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
    SWAP                   m11, m8 ; todo change top so this is in m11
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
%macro F0 0
    REPX    {pmaddubsw x, m14}, m3, m4
    paddw                   m3, m4
    jmp .pred
%endmacro
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
    vbroadcasti128         m11, [base+lshuf4]
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
%macro F1 0
    pshufb                  m5, m3, m11
    pshufb                  m6, m4, m11
    REPX    {pmaddubsw x, m14}, m3, m4
    paddw                   m5, m6
    paddw                   m3, m4
    paddw                   m3, m5
    jmp .pred
%endmacro
    F1
.blk.f1.w8.prep:
    vbroadcasti128         m11, [base+lshuf8]
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
    vbroadcasti128         m11, [base+lshuf4]
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
%macro F2 0
    pshufb                  m5, m3, m11                 ; l
    pmaddubsw               m3, m14
    REPX          {pand x, m7}, m4, m6
    paddw                   m4, m5
    paddw                   m4, m6
    paddw                   m3, m4
    jmp .pred
%endmacro
    F2
.blk.f2.w8.prep:
    vbroadcasti128         m11, [base+lshuf8]
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
    pxor                   xm7, xm7
    vbroadcasti128          m3, [ysrcq+ystrideq*0+ 0]
    vbroadcasti128          m2, [ysrcq+ystrideq*0+16]
    movu                    m6, [ysrcq+ystrideq*1]      ; b
    pshufb                 xm5, xm3, xm7
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
    xor                     t2, t2
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
    xor                     t2, t2
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
    xor                     t2, t2
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
    pxor                   xm7, xm7
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

%endif ; ARCH_X86_64
