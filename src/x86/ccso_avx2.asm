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

SECTION_RODATA 32

pb_mask: times 32 db -1
         times 32 db 0
pb_left_emu_1: db 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
               db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
pb_left_emu_2: db 2, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
               db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
band_mask: dw 0x0000, 0x0080, 0x00c0, 0x00e0, 0x00f0, 0x00f8, 0x00fc, 0x00fe
band_mul:  dw 0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000

pb_1: times 4 db 1

%macro JMP_TABLE 2-*
 %xdefine %1_table %%table
 %xdefine %%base mangle(private_prefix %+ _%1_avx2)
 %%table:
 %rep %0 - 1
    dd %%base %+ .%2 - %%table
  %rotate 1
 %endrep
%endmacro

JMP_TABLE ccso_prep_444_clf_8bpc, f0, f1, f2, f3, f4, f5, f6

SECTION .text

INIT_YMM avx2
cglobal ccso_prep_444_bo_8bpc, 3, 5, 4, dst, src, ss, mbl2
    mov               mbl2d, mbl2m
    lea                  r4, [band_mask]
    vpbroadcastb         m0, [r4+mbl2q*2+ 0]
    vpbroadcastw         m1, [r4+mbl2q*2+16]
    DEFINE_ARGS dst, src, ss, h
    mov                  hd, 8
.loop_y:
    pand                 m2, m0, [srcq+0*mmsize]
    pand                 m3, m0, [srcq+1*mmsize]
    add                srcq, ssq
    REPX    {pmulhuw x, m1}, m2, m3
    mova    [dstq+0*mmsize], m2
    mova    [dstq+1*mmsize], m3
    add                dstq, 64
    dec                  hd
    jg .loop_y
    RET

cglobal ccso_prep_420_bo_8bpc, 3, 5, 4, dst, src, ss, mbl2
    mov               mbl2d, mbl2m
    lea                  r4, [band_mask]
    vpbroadcastw         m0, [r4+mbl2q*2+ 0]
    vpbroadcastw         m1, [r4+mbl2q*2+16]
    DEFINE_ARGS dst, src, ss, h
    mov                  hd, 4
.loop_y:
    pand                 m2, m0, [srcq+0*mmsize]
    pand                 m3, m0, [srcq+1*mmsize]
    packuswb             m2, m3
    vpermq               m2, m2, q3120
    lea                srcq, [srcq+ssq*2]
    pmulhuw              m2, m1
    mova             [dstq], m2
    add                dstq, 32
    dec                  hd
    jg .loop_y
    RET

cglobal ccso_prep_444_clf_8bpc, 4, 9, 16, dst, src, ss, left, top, bottom, \
                                          mbl2, flt, qstep, edge_clf, w, edges
    mov               mbl2d, mbl2m
    lea                  r7, [band_mask]
    vpbroadcastb         m0, [r7+mbl2q*2+ 0]
    vpbroadcastw         m1, [r7+mbl2q*2+16]
    vpbroadcastw         m2, qstepm             ; value can be 256
    vpbroadcastb         m3, edge_clfm
    pxor                xm4, xm4
    packuswb             m2, m2                 ; clip value to 0..255 range
    psubb                m3, m4, m3             ; 1 -> -1
    vpbroadcastd         m5, [r7+pb_1-band_mask]
    por                  m3, m2
    mov                 r8d, edgesm

    ; { -1, 0 }, { 0, -1 }, { -1, -1 }, { -1, 1 }, { -1, -2 }, { 1, -2 }, { 0, 2 }
    mov                 r6d, fltm
    movsxd               r6, [r7+ccso_prep_444_clf_8bpc_table-band_mask+r6*4]
    lea                  r7, [r7+ccso_prep_444_clf_8bpc_table-band_mask+r6]
    jmp                  r7

    DEFINE_ARGS dst, src, ss, left, top, bottom, h, _, edges, _, w
.f0:
    mov                  hd, 7
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]
    test             edgesb, 4                  ; have_top
    jz .f0_no_top
    movifnidn          topq, topmp
    mova                 m6, [topq+mmsize*0]
    mova                 m7, [topq+mmsize*1]
    jmp .f0_yloop
.f0_no_top:
    mova                 m6, m8
    mova                 m7, m9
.f0_yloop:
    add                srcq, ssq
.f0_yloop_noinc:
    mova                m10, [srcq+mmsize*0]
    mova                m11, [srcq+mmsize*1]
.f0_yloop_noload:
    ; we could call into .f1_main here, but it would be a bit slower
    ; since we would need to re-load bottom (m10-11) every loop iteration.
    ; This custom inlined version uses m14-15 (which are unused here).

    ; cls0 score
    psubusb             m12, m8, m6             ; ctr - edge [left]
    psubusb             m13, m9, m7             ; ctr - edge [right]
    psubusb              m6, m8                 ; edge - ctr [left]
    psubusb              m7, m9                 ; edge - ctr [right]
    REPX   {psubusb  x, m2}, m12, m13
    REPX   {psubusb  x, m3}, m6, m7
    REPX   {pcmpeqb  x, m4}, m12, m13, m6, m7   ; +/-diff <= +/-quant_step
    REPX   {psubb x, m5, x}, m12, m13
    paddb                m6, m12                ; cls0
    paddb                m7, m13
    REPX   {psllw     x, 5}, m6, m7

    ; cls1 score
    psubusb             m12, m8, m10            ; ctr - edge [left]
    psubusb             m13, m9, m11            ; ctr - edge [right]
    psubusb             m14, m10, m8            ; edge - ctr [left]
    psubusb             m15, m11, m9            ; edge - ctr [right]
    REPX   {psubusb  x, m2}, m12, m13
    REPX   {psubusb  x, m3}, m14, m15
    REPX   {pcmpeqb  x, m4}, m12, m13, m14, m15 ; +/-diff <= +/-quant_step
    REPX   {psubb x, m5, x}, m12, m13
    paddb               m14, m12                ; cls1
    paddb               m15, m13
    REPX   {psllw     x, 3}, m14, m15
    por                  m6, m14
    por                  m7, m15

    pand                m12, m8, m0
    pand                m13, m9, m0
    REPX   {pmulhuw  x, m1}, m12, m13           ; band
    por                  m6, m12
    por                  m7, m13

    mova    [dstq+0*mmsize], m6
    mova    [dstq+1*mmsize], m7
    add                dstq, 64

    mova                 m6, m8
    mova                 m7, m9
    mova                 m8, m10
    mova                 m9, m11
    dec                  hd
    jg .f0_yloop
    jl .f0_ret
    test             edgesb, 8                  ; have_bottom
    jz .f0_yloop_noload
    mov                srcq, bottommp
    jmp .f0_yloop_noinc
.f0_ret:
    RET

%if UNIX64
DECLARE_REG_TMP 9, 10
%else
DECLARE_REG_TMP 4, 5
%endif

.f1:
    cmp              edgesd, 0xf                ; have_all_edges
    jne .f1e
    mov                  hd, 8
    movu                m14, [pb_mask+31]       ; -1, 31x0
.f1_yloop:
    movd               xm13, [leftq+1]
    add               leftq, 2
    movu                 m6, [srcq+mmsize*0-1]
    movu                 m7, [srcq+mmsize*1-1]
    vpblendvb            m6, m13, m14
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]
    movu                m10, [srcq+mmsize*0+1]
    movu                m11, [srcq+mmsize*1+1]
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f1_yloop
    RET
.f1e:
%if UNIX64
    PUSH                 r9
    PUSH                r10
%endif
    test             edgesb, 2                  ; have_right
    jnz .f1_post_no_right_init
    mov                 r7d, wm                 ; w
    lea                 t0d, [r7d-1]
    call .f1_no_right_init
.f1_post_no_right_init:
    mov                  hd, 8
.f1e_yloop:
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]

    movu                m10, [srcq+mmsize*0+1]
    movu                m11, [srcq+mmsize*1+1]
    test             edgesb, 2                  ; have_right
    jnz .f1_post_right
    vpbroadcastb         m6, [srcq+r7-1]        ; src[w-1]
    vpblendvb           m10, m6, m10, m14
    vpblendvb           m11, m6, m11, m15
.f1_post_right:
    movu                 m7, [srcq+mmsize*1-1]
    test             edgesb, 1                  ; have_left
    jz .f1_no_left
    movu                 m6, [srcq+mmsize*0-1]
    movd               xm12, [leftq+1]
    movu                m13, [pb_mask+31]
    vpblendvb            m6, m12, m13
    add               leftq, 2
    jmp .f1_post_left
.f1_no_left:
    vpbroadcastb        xm6, xm8
    vinserti128          m6, xm8, 1
    palignr              m6, m8, m6, 15
.f1_post_left:
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f1e_yloop
%if UNIX64
    POP                 r10
    POP                  r9
%endif
    RET
.f1_no_right_init:
    neg                  t0                     ; dx-w
    lea                  t1, [t0+32]            ; 32+dx-w
    add                 t0d, 64                 ; 64+dx-w
    xor                 r6d, r6d
    cmp                 t1d, r6d
    cmovl               t1d, r6d                ; imax(0,32+dx-w)
    mov                 r6d, 32
    cmp                 t0d, r6d
    cmovg               t0d, r6d                ; imin(32,64+dx-w)
    lea                  r6, [pb_mask]
    movu                m14, [r6+t1]            ; pb_mask+max(0,32+dx-w)
    movu                m15, [r6+t0]            ; pb_mask+min(32,64+dx-w)
    ret
.f1_main:
    ; cls0 score
    psubusb             m12, m8, m6             ; ctr - edge [left]
    psubusb             m13, m9, m7             ; ctr - edge [right]
    psubusb              m6, m8                 ; edge - ctr [left]
    psubusb              m7, m9                 ; edge - ctr [right]
    REPX   {psubusb  x, m2}, m12, m13
    REPX   {psubusb  x, m3}, m6, m7
    REPX   {pcmpeqb  x, m4}, m12, m13, m6, m7   ; +/-diff <= +/-quant_step
    REPX   {psubb x, m5, x}, m12, m13
    paddb                m6, m12                ; cls0
    paddb                m7, m13
    REPX   {psllw     x, 5}, m6, m7

    ; cls1 score
    psubusb             m12, m8, m10            ; ctr - edge [left]
    psubusb             m13, m9, m11            ; ctr - edge [right]
    psubusb             m10, m8                 ; edge - ctr [left]
    psubusb             m11, m9                 ; edge - ctr [right]
    REPX   {psubusb  x, m2}, m12, m13
    REPX   {psubusb  x, m3}, m10, m11
    REPX   {pcmpeqb  x, m4}, m12, m13, m10, m11 ; +/-diff <= +/-quant_step
    REPX   {psubb x, m5, x}, m12, m13
    paddb               m10, m12                ; cls1
    paddb               m11, m13
    REPX   {psllw     x, 3}, m10, m11
    por                  m6, m10
    por                  m7, m11

    pand                m12, m8, m0
    pand                m13, m9, m0
    REPX   {pmulhuw  x, m1}, m12, m13           ; band
    por                  m6, m12
    por                  m7, m13

    mova    [dstq+0*mmsize], m6
    mova    [dstq+1*mmsize], m7
    add                dstq, 64
    ret

%macro f24 2
.f%1:
    cmp              edgesd, 0xf                ; have_all_edges
    jne .f%1e
    mov                  hd, 7
    movu                m14, [pb_mask+32-%2]    ; %2*-1, (32-%2)x0
    movifnidn          topq, topmp
    movu                 m6, [topq+mmsize*0-%2]
    movu                 m7, [topq+mmsize*1-%2]
    movu                m10, [srcq+ssq*1+mmsize*0+%2]
    movu                m11, [srcq+ssq*1+mmsize*1+%2]
    sub                srcq, ssq
    jmp .f%1_noload_top
.f%1_yloop:
    movu                m10, [srcq+ssq*2+mmsize*0+%2]
    movu                m11, [srcq+ssq*2+mmsize*1+%2]
.f%1_noload_bottom:
    movd               xm13, [leftq+2-%2]
    add               leftq, 2
    movu                 m6, [srcq+mmsize*0-%2]
    movu                 m7, [srcq+mmsize*1-%2]
    vpblendvb            m6, m13, m14
.f%1_noload_top:
    mova                 m8, [srcq+ssq*1+mmsize*0]
    mova                 m9, [srcq+ssq*1+mmsize*1]
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f%1_yloop
    jl .f%1_ret
    movifnidn       bottomq, bottommp
    movu                m10, [bottomq+mmsize*0+%2]
    movu                m11, [bottomq+mmsize*1+%2]
    jmp .f%1_noload_bottom
.f%1_ret:
    RET
.f%1e:
%if UNIX64
    PUSH                 r9
    PUSH                r10
%endif
    test             edgesb, 2                  ; have_right
    jnz .f%1_post_no_right_init
    mov                 r7d, wm                 ; w
    lea                 t0d, [r7d-%2]
    call .f1_no_right_init
.f%1_post_no_right_init:
    mov                  hd, 7

    ; load top/left
    test             edgesb, 4                  ; have_top
    jz .f%1_tl_no_top
    movifnidn          topq, topmp
    movu                 m6, [topq+mmsize*0-%2]
    movu                 m7, [topq+mmsize*1-%2]
    test             edgesb, 1                  ; have_left
    jnz .f%1_post_top
    pshufb               m6, [pb_left_emu_%2]
    jmp .f%1_post_top
.f%1_tl_no_top:
    movu                 m7, [srcq+mmsize*1-%2]
    test             edgesb, 1                  ; have_left
    jz .f%1_tl_no_edges
    movu                 m6, [srcq+mmsize*0-%2]
    movd                xm8, [leftq+2-%2]
    movu                 m9, [pb_mask+32-%2]    ; %2xm1,(32-%2)x0
    vpblendvb            m6, m8, m9
    jmp .f%1_post_top
.f%1_tl_no_edges:
    mova                 m6, [srcq+mmsize*0]
    vpbroadcastb        xm8, xm6
    vinserti128          m8, xm6, 1
    palignr              m6, m8, 16-%2
.f%1_post_top:
    movu                m10, [srcq+ssq+mmsize*0+%2]
    movu                m11, [srcq+ssq+mmsize*1+%2]
    test             edgesb, 2                  ; have_right
    jnz .f%1e_noload_top
    lea                  r4, [srcq+ssq]
    vpbroadcastb        m12, [r4+r7-1]          ; src[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
    jmp .f%1e_noload_top
.f%1e_yloop:
    movu                m10, [srcq+ssq*2+mmsize*0+%2]
    movu                m11, [srcq+ssq*2+mmsize*1+%2]
    test             edgesb, 2
    jnz .f%1e_noload_bottom
    lea                  r4, [srcq+ssq*2]
    vpbroadcastb        m12, [r4+r7-1]          ; src[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
.f%1e_noload_bottom:
    movu                 m7, [srcq+mmsize*1-%2]
    test             edgesb, 1                  ; have_left
    jz .f%1_noleft
    movu                 m6, [srcq+mmsize*0-%2]
    movd                xm8, [leftq+2-%2]
    movu                 m9, [pb_mask+32-%2]    ; %2x-1,(32-%2)x0
    vpblendvb            m6, m8, m9
    add               leftq, 2
    jmp .f%1_postleft
.f%1_noleft:
    mova                 m6, [srcq+mmsize*0]
    vpbroadcastb        xm8, xm6
    vinserti128          m8, xm6, 1
    palignr              m6, m8, 16-%2
.f%1_postleft:
    add                srcq, ssq
.f%1e_noload_top:
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]
    call .f1_main
    dec                  hd
    jg .f%1e_yloop
    jl .f%1e_ret

    ; load bottom/right
    test             edgesb, 8                  ; have_bottom
    jz .f%1_br_no_bottom
    movifnidn       bottomq, bottommp
    movu                m10, [bottomq+0*mmsize+%2]
    movu                m11, [bottomq+1*mmsize+%2]
    test             edgesb, 2                  ; have_right
    jnz .f%1e_noload_bottom
    vpbroadcastb        m12, [bottomq+r7-1]     ; bottom[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
    jmp .f%1e_noload_bottom
.f%1_br_no_bottom:
    movu                m10, [srcq+ssq+0*mmsize+%2]
    movu                m11, [srcq+ssq+1*mmsize+%2]
    test             edgesb, 2                  ; have_right
    jnz .f%1e_noload_bottom
    lea                  r4, [srcq+ssq]
    vpbroadcastb        m12, [r4+r7-1]          ; src[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
    jmp .f%1e_noload_bottom
.f%1e_ret:
%if UNIX64
    POP                 r10
    POP                  r9
%endif
    RET
%endmacro

    f24 2, 1

.f3:
    cmp              edgesd, 0xf                ; have_all_edges
    jne .f3e
    mov                  hd, 7
    movu                m14, [pb_mask+31]       ; -1, 31x0
    movifnidn          topq, topmp
    movu                 m6, [topq+mmsize*0+1]
    movu                 m7, [topq+mmsize*1+1]
    movd               xm13, [leftq+3]
    movu                m10, [srcq+ssq*1+mmsize*0-1]
    movu                m11, [srcq+ssq*1+mmsize*1-1]
    vpblendvb           m10, m13, m14
    sub                srcq, ssq
    jmp .f3_noload_top
.f3_yloop:
    movd               xm13, [leftq+5]
    add               leftq, 2
    movu                m10, [srcq+ssq*2+mmsize*0-1]
    movu                m11, [srcq+ssq*2+mmsize*1-1]
    vpblendvb           m10, m13, m14
.f3_noload_bottom:
    movu                 m6, [srcq+mmsize*0+1]
    movu                 m7, [srcq+mmsize*1+1]
.f3_noload_top:
    mova                 m8, [srcq+ssq*1+mmsize*0]
    mova                 m9, [srcq+ssq*1+mmsize*1]
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f3_yloop
    jl .f3_ret
    movifnidn       bottomq, bottommp
    movu                m10, [bottomq+mmsize*0-1]
    movu                m11, [bottomq+mmsize*1-1]
    jmp .f3_noload_bottom
.f3_ret:
    RET
.f3e:
%if UNIX64
    PUSH                 r9
    PUSH                r10
%endif
    test             edgesb, 2                  ; have_right
    jnz .f3_post_no_right_init
    mov                 r7d, wm                 ; w
    lea                 t0d, [r7d-1]
    call .f1_no_right_init
.f3_post_no_right_init:
    mov                  hd, 7

    ; load top/left
    test             edgesb, 4                  ; have_top
    jz .f3_tl_no_top
    movifnidn          topq, topmp
    movu                 m6, [topq+mmsize*0+1]
    movu                 m7, [topq+mmsize*1+1]
    test             edgesb, 2                  ; have_right
    jnz .f3_post_top
    vpbroadcastb        m12, [topq+r7-1]        ; top[w-1]
    vpblendvb            m6, m12, m6, m14
    vpblendvb            m7, m12, m7, m15
    jmp .f3_post_top
.f3_tl_no_top:
    movu                 m6, [srcq+mmsize*0+1]
    movu                 m7, [srcq+mmsize*1+1]
    test             edgesb, 2                  ; have_right
    jnz .f3_post_top
    vpbroadcastb        m12, [srcq+r7-1]        ; src[w-1]
    vpblendvb            m6, m12, m6, m14
    vpblendvb            m7, m12, m7, m15
.f3_post_top:
    movu                m10, [srcq+ssq+mmsize*0-1]
    movu                m11, [srcq+ssq+mmsize*1-1]
    test             edgesb, 1                  ; have_left
    jz .f3_firstline_noleft
    movd                xm8, [leftq+3]
    movu                 m9, [pb_mask+31]       ; -1,31x0
    vpblendvb           m10, m8, m9
    jmp .f3e_noload_top
.f3_firstline_noleft:
    pshufb              m10, [pb_left_emu_1]
    jmp .f3e_noload_top
.f3e_yloop:
    movu                m10, [srcq+ssq*2+mmsize*0-1]
    movu                m11, [srcq+ssq*2+mmsize*1-1]
    test             edgesb, 1
    jz .f3_noleft
    movd                xm8, [leftq+5]
    movu                 m9, [pb_mask+31]       ; -1,31x0
    vpblendvb           m10, m8, m9
    add               leftq, 2
    jmp .f3e_noload_bottom
.f3_noleft:
    pshufb              m10, [pb_left_emu_1]
.f3e_noload_bottom:
    movu                 m6, [srcq+mmsize*0+1]
    movu                 m7, [srcq+mmsize*1+1]
    test             edgesb, 2                  ; have_right
    jnz .f3_postright
    vpbroadcastb        m12, [srcq+r7-1]        ; src[w-1]
    vpblendvb            m6, m12, m6, m14
    vpblendvb            m7, m12, m7, m15
.f3_postright:
    add                srcq, ssq
.f3e_noload_top:
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]
    call .f1_main
    dec                  hd
    jg .f3e_yloop
    jl .f3e_ret

    ; load bottom/right
    test             edgesb, 8                  ; have_bottom
    jz .f3_br_no_bottom
    movifnidn       bottomq, bottommp
    movu                m10, [bottomq+0*mmsize-1]
    movu                m11, [bottomq+1*mmsize-1]
    test             edgesb, 1                  ; have_left
    jnz .f3e_noload_bottom
    pshufb              m10, [pb_left_emu_1]
    jmp .f3e_noload_bottom
.f3_br_no_bottom:
    movu                m10, [srcq+ssq+0*mmsize-1]
    movu                m11, [srcq+ssq+1*mmsize-1]
    test             edgesb, 1                  ; have_left
    jz .f3_br_no_edges
    movd               xm12, [leftq+3]
    movu                m13, [pb_mask+31]
    vpblendvb           m10, m12, m13
    jmp .f3e_noload_bottom
.f3_br_no_edges:
    pshufb              m10, [pb_left_emu_1]
    jmp .f3e_noload_bottom
.f3e_ret:
%if UNIX64
    POP                 r10
    POP                  r9
%endif
    RET

    f24 4, 2

.f5:
    cmp              edgesd, 0xf                ; have_all_edges
    jne .f5e
    mov                  hd, 7
    movu                m14, [pb_mask+30]       ; -1, 31x0
    movifnidn          topq, topmp
    movu                m10, [topq+mmsize*0+2]
    movu                m11, [topq+mmsize*1+2]
    movd               xm13, [leftq+2]
    movu                 m6, [srcq+ssq*1+mmsize*0-2]
    movu                 m7, [srcq+ssq*1+mmsize*1-2]
    vpblendvb            m6, m13, m14
    sub                srcq, ssq
    jmp .f5_noload_top
.f5_yloop:
    movd               xm13, [leftq+4]
    add               leftq, 2
    movu                 m6, [srcq+ssq*2+mmsize*0-2]
    movu                 m7, [srcq+ssq*2+mmsize*1-2]
    vpblendvb            m6, m13, m14
.f5_noload_bottom:
    movu                m10, [srcq+mmsize*0+2]
    movu                m11, [srcq+mmsize*1+2]
.f5_noload_top:
    mova                 m8, [srcq+ssq*1+mmsize*0]
    mova                 m9, [srcq+ssq*1+mmsize*1]
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f5_yloop
    jl .f5_ret
    movifnidn       bottomq, bottommp
    movu                 m6, [bottomq+mmsize*0-2]
    movu                 m7, [bottomq+mmsize*1-2]
    jmp .f5_noload_bottom
.f5_ret:
    RET
.f5e:
%if UNIX64
    PUSH                 r9
    PUSH                r10
%endif
    test             edgesb, 2                  ; have_right
    jnz .f5_post_no_right_init
    mov                 r7d, wm                 ; w
    lea                 t0d, [r7d-2]
    call .f1_no_right_init
.f5_post_no_right_init:
    mov                  hd, 7

    ; load top/left
    test             edgesb, 4                  ; have_top
    jz .f5_tl_no_top
    movifnidn          topq, topmp
    movu                m10, [topq+mmsize*0+2]
    movu                m11, [topq+mmsize*1+2]
    test             edgesb, 2                  ; have_right
    jnz .f5_post_top
    vpbroadcastb        m12, [topq+r7-1]        ; top[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
    jmp .f5_post_top
.f5_tl_no_top:
    movu                m10, [srcq+mmsize*0+2]
    movu                m11, [srcq+mmsize*1+2]
    test             edgesb, 2                  ; have_right
    jnz .f5_post_top
    vpbroadcastb        m12, [srcq+r7-1]        ; src[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
.f5_post_top:
    movu                 m6, [srcq+ssq+mmsize*0-2]
    movu                 m7, [srcq+ssq+mmsize*1-2]
    test             edgesb, 1                  ; have_left
    jz .f5_firstline_noleft
    movd                xm8, [leftq+2]
    movu                 m9, [pb_mask+30]       ; -1,31x0
    vpblendvb            m6, m8, m9
    jmp .f5e_noload_top
.f5_firstline_noleft:
    pshufb               m6, [pb_left_emu_2]
    jmp .f5e_noload_top
.f5e_yloop:
    movu                 m6, [srcq+ssq*2+mmsize*0-2]
    movu                 m7, [srcq+ssq*2+mmsize*1-2]
    test             edgesb, 1
    jz .f5_noleft
    movd                xm8, [leftq+4]
    movu                 m9, [pb_mask+30]       ; -1,31x0
    vpblendvb            m6, m8, m9
    add               leftq, 2
    jmp .f5e_noload_bottom
.f5_noleft:
    pshufb               m6, [pb_left_emu_2]
.f5e_noload_bottom:
    movu                m10, [srcq+mmsize*0+2]
    movu                m11, [srcq+mmsize*1+2]
    test             edgesb, 2                  ; have_right
    jnz .f5_postright
.f5_noright:
    vpbroadcastb        m12, [srcq+r7-1]        ; src[w-1]
    vpblendvb           m10, m12, m10, m14
    vpblendvb           m11, m12, m11, m15
.f5_postright:
    add                srcq, ssq
.f5e_noload_top:
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]
    call .f1_main
    dec                  hd
    jg .f5e_yloop
    jl .f5e_ret

    ; load bottom/right
    test             edgesb, 8                  ; have_bottom
    jz .f5_br_no_bottom
    movifnidn       bottomq, bottommp
    movu                 m6, [bottomq+0*mmsize-2]
    movu                 m7, [bottomq+1*mmsize-2]
    test             edgesb, 1                  ; have_left
    jnz .f5e_noload_bottom
.f5_br_no_left:
    pshufb               m6, [pb_left_emu_2]
    jmp .f5e_noload_bottom
.f5_br_no_bottom:
    movu                 m6, [srcq+ssq+0*mmsize-2]
    movu                 m7, [srcq+ssq+1*mmsize-2]
    test             edgesb, 1                  ; have_left
    jz .f5_br_no_edges
    movd               xm12, [leftq+2]
    movu                m13, [pb_mask+30]
    vpblendvb            m6, m12, m13
    jmp .f5e_noload_bottom
.f5_br_no_edges:
    pshufb               m6, [pb_left_emu_2]
    jmp .f5e_noload_bottom
.f5e_ret:
%if UNIX64
    POP                 r10
    POP                  r9
%endif
    RET

.f6:
    cmp              edgesd, 0xf
    jne .f6e
    mov                  hd, 8
    movu                m14, [pb_mask+30]       ; 2xm1,30x0
.f6_yloop:
    movd               xm12, [leftq]
    add               leftq, 2
    movu                m10, [srcq+mmsize*0-2]
    movu                m11, [srcq+mmsize*1-2]
    vpblendvb           m10, m12, m14
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]
    movu                 m6, [srcq+mmsize*0+2]
    movu                 m7, [srcq+mmsize*1+2]
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f6_yloop
    RET
.f6e:
%if UNIX64
    PUSH                 r9
    PUSH                r10
%endif
    test             edgesb, 2                  ; have_right
    jnz .f6_post_no_right_init
    mov                 r7d, wm                 ; w
    lea                 t0d, [r7d-2]
    call .f1_no_right_init
.f6_post_no_right_init:
    mov                  hd, 8
.f6e_yloop:
    mova                 m8, [srcq+mmsize*0]
    mova                 m9, [srcq+mmsize*1]

    movu                 m6, [srcq+mmsize*0+2]
    movu                 m7, [srcq+mmsize*1+2]
    test             edgesb, 2                  ; have_right
    jnz .f6_post_right
.f6_no_right:
    vpbroadcastb        m10, [srcq+r7-1]        ; src[w-1]
    vpblendvb            m6, m10, m6, m14
    vpblendvb            m7, m10, m7, m15
.f6_post_right:
    movu                m11, [srcq+mmsize*1-2]
    test             edgesb, 1                  ; have_left
    jz .f6_no_left
    movu                m10, [srcq+mmsize*0-2]
    movd               xm12, [leftq]
    movu                m13, [pb_mask+30]
    vpblendvb           m10, m12, m13
    add               leftq, 2
    jmp .f6_post_left
.f6_no_left:
    vpbroadcastb       xm10, xm8
    vinserti128         m10, xm8, 1
    palignr             m10, m8, m10, 14
.f6_post_left:
    add                srcq, ssq
    call .f1_main
    dec                  hd
    jg .f6e_yloop
%if UNIX64
    POP                 r10
    POP                  r9
%endif
    RET

%endif ; ARCH_X86_64
