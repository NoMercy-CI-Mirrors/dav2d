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

pw_warp_off_w16: times 2 dw 1, 1
                 times 2 dw 3, 1
                 times 2 dw 1, 5
                 times 2 dw 3, 5
pw_warp_off_w32: times 2 dw 1, 1
                 times 2 dw 3, 1
                 times 2 dw 1, 3
                 times 2 dw 3, 3
pw_warp_off_w64: times 2 dw 1, 1
                 times 2 dw 3, 1
                 times 2 dw 9, 1
                 times 2 dw 11, 1
gmv_t8b_shuf: db 2, 3, 10, 11, 4, 5, 4, 5, 12, 13, 6, 7, 6, 7, 14, 15
gmv_t2_shuf:  db 0, 1, 0, 1, 8, 9, 2, 3, 2, 3, 10, 11, 4, 5, 4, 5
gmv_t8a_shuf: db 0, 1, 0, 1, 8, 9, 2, 3
gmv_t4b_shuf: db 12, 13, 6, 7, 6, 7, 14, 15
pb_triple_mask: db 0, 1, 2, 3, 4, 5, 0, 1
                db 2, 3, 4, 5, 0, 1, 2, 3
                db 4, 5, 0, 1, 2, 3, 4, 5
                db 0, 1, 2, 3, 4, 5, 0, 1
                db 2, 3, 4, 5, 0, 1, 2, 3
                db 4, 5, 0, 1, 2, 3, 4, 5
t2_shuf: db 0, 1, 2, 3, 8, 10, 4, 5, 6, 7, 12, 14
         times 4 db -1
t4_shufA: db 8, 10, 12, 14
          ; this is actually "shufC"
          db 4, 5, 0, 1, 2, 3, 6, 7
          ; and thus is "shufA" again
          db 0, 2, 4, 6
t4_shufB: db 4, 5, 6, 7, 0, 1, 8, 9, 10, 11, 2, 3, 12, 13, 14, 15
pd_65536_0_0_65536: dd 65536, 0, 0, 65536
pw_warp_off_w8: times 2 dw 1, 1
                times 2 dw 1, 3
pw_warp_off_w16top: times 2 dw -3, 1
                    times 2 dw -1, 1
pw_warp_off_w16bot: times 2 dw 1, -1
                    times 2 dw 3, -1

pb_128: times 4 db 128
pw_6: times 2 dw 6
pw_257: times 2 dw 0x101
pw_m128: times 2 dw -128
pd_4: dd 4
pd_131: dd 131
pd_1024: dd 1024
pd_0xffff: dd 0xffff
pd_0x20000: dd 0x20000
pd_0x40000: dd 0x40000

%macro JMP_TABLE 2-*
    %xdefine %%prefix mangle(private_prefix %+ _%1)
    %1_table:
    %xdefine %%base %1_table
    %rep %0 - 1
        dd %%prefix %+ .%2 - %%base
        %rotate 1
    %endrep
%endmacro

JMP_TABLE splat_mv_avx2, t1, t1, t2, t4, t8, t16, t32
JMP_TABLE splat_warpmv_avx2, gmv_t1, gmv_t2, gmv_t4, gmv_t8, gmv_t16, gmv_t16, \
                             t1, t2, t4, t8, t16, t16
JMP_TABLE splat_comp_wedgemv_avx2, t1, t2, t4, t8

SECTION .text

%if ARCH_X86_64
INIT_YMM avx2
cglobal splat_mv, 5, 8, 3, sdst, ssrc, tdst, tstride, tsrc, bw4, bh4
    test         tdstq, tdstq
    jz .spatial

    ; temporal loop
    vpbroadcastq    m0, [tsrcq]
    lea             r6, [splat_mv_avx2_table]
    tzcnt          r7d, bw4m
    movsxd          r7, [r6+r7*4]
    add             r7, r6
    mov           bh4d, bh4m
    lea       tstrideq, [tstrideq*3]
    inc           bh4d
    shr           bh4d, 1
    jmp             r7

.t1:
    movd    [tdstq+ 0], xm0
    pextrw  [tdstq+ 4], xm0, 2
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t1
    jmp .spatial

.t2:
    pshuflw        xm1, xm0, q1021
    pshuflw        xm0, xm0, q0210
.t2_loop:
    movq    [tdstq+ 0], xm0
    movd    [tdstq+ 8], xm1
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t2_loop
    jmp .spatial

.t4:
    pshufb         xm0, [pb_triple_mask]
    psrldq         xm1, xm0, 4
.t4_loop:
    movu    [tdstq+ 0], xm0
    movq    [tdstq+16], xm1
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t4_loop
    jmp .spatial

.t8:
    pshufb         xm1, xm0, [pb_triple_mask+8]
    pshufb          m0, [pb_triple_mask]
.t8_loop:
    movu    [tdstq+ 0], m0
    mova    [tdstq+32], xm1
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t8_loop
    jmp .spatial

.t16:
    pshufb          m1, m0, [pb_triple_mask+8]
    pshufb          m2, m0, [pb_triple_mask+16]
    pshufb          m0, [pb_triple_mask]
.t16_loop:
    mova    [tdstq+ 0], m0
    mova    [tdstq+32], m1
    mova    [tdstq+64], m2
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t16_loop
    jmp .spatial

.t32:
    pshufb          m1, m0, [pb_triple_mask+8]
    pshufb          m2, m0, [pb_triple_mask+16]
    pshufb          m0, [pb_triple_mask]
.t32_loop:
    mova   [tdstq+  0], m0
    mova   [tdstq+ 32], m1
    mova   [tdstq+ 64], m2
    mova   [tdstq+ 96], m0
    mova   [tdstq+128], m1
    mova   [tdstq+160], m2
    lea         tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t32_loop
    ; fall-through

.spatial:
    mova            m0, [ssrcq]
    mov           bh4d, bh4m
    cmp     dword bw4m, 2
    jg .s3
    je .s2
    ; fall-through
.s1:
    mova  [sdstq+64*0], m0
    add          sdstq, 128*64
    dec           bh4d
    jg .s1
    RET
.s2:
    mova  [sdstq+64*0], m0
    mova  [sdstq+64*1], m0
    add          sdstq, 128*64
    dec           bh4d
    jg .s2
    RET
.s3:
    ; fall-through
    rorx          bw4d, bw4m, 26
    add          sdstq, bw4q
    neg           bw4q
    dec           bh4d
    jz .last_line
.s3_loop:
    mova  [sdstq-64*3], m0
    mova  [sdstq-64*2], m0
    mova  [sdstq-64*1], m0
    add          sdstq, 128*64
    dec           bh4d
    jg .s3_loop
    ; fall-through
.last_line:
    mova [sdstq+bw4q+64*0], m0
    mova [sdstq+bw4q+64*1], m0
    mova [sdstq+bw4q+64*2], m0
    mova [sdstq+bw4q+64*3], m0
    add           bw4q, 64*4
    jl .last_line
    RET

struc refmvs_block
    .mv:  resd 4
    .ref: resb 2
    .bs:  resb 1
    .mf:  resb 1
    .bx4: resw 1
    .by4: resw 1
    .lmv: resd 4
    .mat: resd 6
endstruc

%if WIN64
DECLARE_REG_TMP 5
%else
DECLARE_REG_TMP 8
%endif

INIT_YMM avx2
cglobal splat_warpmv, 5, 8, 3, sdst, ssrc, tdst, tstride, tsrc, bw4, bh4, mat
    test byte [ssrcq+refmvs_block.mf], 2
    jz .gmv

    test         tdstq, tdstq
    jz .spatial_only
    ; fall-through to spatial+temporal warp matrix code

    tzcnt          t0d, bw4m
    mov           bh4d, bh4m
%if WIN64
    PUSH            r8
    %assign regs_used regs_used+1
    ALLOC_STACK mmsize*4, 16
%else
    ALLOC_STACK 0-mmsize*4, 16
%endif
    mova            m0, [ssrcq+ 0]
    mova            m1, [ssrcq+32]
    vpbroadcastw    m2, [tsrcq+4]       ; t_src.ref
    pxor          xm13, xm13
    punpcklbw       m2, m13

    vbroadcasti128  m5, [pd_65536_0_0_65536]
    vbroadcasti128  m4, [ssrcq+refmvs_block.mat+8]  ; mat[2-5]
    vpbroadcastd    m3, [ssrcq+refmvs_block.bx4]    ; bx4, by4 as words
                                                    ; range is 0..0x3fff-w/h
    psubd           m4, m5                          ; m2-0x10000,m3,m4,m5-0x10000
                                                    ; range is -0x7fc0,+0x7fc0
    vpbroadcastq    m5, [ssrcq+refmvs_block.mat]    ; mat[0-1]
    packssdw        m4, m4                          ; dword->word (and duplicate)
    vpbroadcastd    m6, [pd_1024]
    psrad           m5, 2                           ; mat[0-1] >> 2

    lea             r7, [splat_warpmv_avx2_table]
    movsxd          t0, [r7+t0*4+5*4]
    add             r7, t0
    lea       tstrideq, [tstrideq*3]
    shr           bh4d, 1
    jmp             r7

%macro WARP_LOOP_START 1 ; size
.t%1_loop:
    psrad           m7, m3, 31
    psrad           m8, m4, 31                      ; -(mvx/yi < 0)
    REPX {paddd x, m6}, m7, m8                      ; 1024 - (mvx/yi < 0)
    paddd           m7, m3
    paddd           m8, m4
    REPX {psrad  x, 11}, m7, m8                     ; warpmv
    REPX {pminsd x, m14}, m7, m8
    REPX {pmaxsd x, m13}, m7, m8
    mova [rsp+0*mmsize], m7
    mova [rsp+1*mmsize], m8
    pabsd           m9, m7
    pabsd          m10, m8
    packssdw        m7, m8                          ; v [words]
    vpbroadcastd    m8, [pd_131]
    cvtdq2ps       m11, m9
    cvtdq2ps       m12, m10
    REPX {psrld   x, 23}, m11, m12                  ; extract exponent bits
    REPX {psubusw x, m8}, m11, m12                  ; nbits=imax(log2(absv)-4, 0)
    vpbroadcastd    m8, [pw_6]
    vpsrlvd         m9, m11
    vpsrlvd        m10, m12                         ; absv >> nbits [dwords]
    packssdw       m11, m12                         ; nbits [words]
    packssdw        m9, m10                         ; absv >> nbits [words]
    pcmpgtw        m10, m11, m8
    pxor            m8, m8
    psllw          m11, 4                           ; 16*nbits
    pcmpeqd        m10, m8                          ; nbits <= 6 for x+y comps
    paddw           m9, m11
    psignw          m9, m7

    pcmpeqw         m7, m7
    pblendvb        m8, m15, m9, m10                ; interleave -0x80 if invalid
    pblendvb        m7, m7, m2, m10                 ; set ref to -1 if invalid
    packsswb        m8, m7                          ; word->byte, and interleave refs
%endmacro

INIT_XMM avx2
.t1:
    lea             t0, [tstrideq*3]
    vpbroadcastd   m14, [pd_0xffff]
    psubd          m13, m14
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w8]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m5, [pd_0x40000]
    pmaddwd         m5, m4
    paddd           m4, m3, m5
    paddd           m5, m5
    WARP_LOOP_START  1
    punpcklwd       m7, m8, m8

INIT_YMM avx2
    movq           xm9, [rsp+0*8]
    vpblendd        m0, m9, 00000011b
    movd     [tdstq+0], xm7
    pextrw   [tdstq+4], xm8, 4
    mova [sdstq+0*32+0*128*64], m0
    mova [sdstq+1*32+0*128*64], m1
    mova [sdstq+2*32+0*128*64], m0
    mova [sdstq+3*32+0*128*64], m1
    mova [sdstq+0*32+1*128*64], m0
    mova [sdstq+1*32+1*128*64], m1
    mova [sdstq+2*32+1*128*64], m0
    mova [sdstq+3*32+1*128*64], m1
    cmp           bh4d, 1
    je .t_end
    movq           xm9, [rsp+1*8]
    vpblendd        m0, m9, 00000011b
    pextrd [tdstq+tstrideq*2+0], xm7, 1
    pextrw [tdstq+tstrideq*2+4], xm8, 5
    mova [sdstq+0*32+2*128*64], m0
    mova [sdstq+1*32+2*128*64], m1
    mova [sdstq+2*32+2*128*64], m0
    mova [sdstq+3*32+2*128*64], m1
    mova [sdstq+0*32+3*128*64], m0
    mova [sdstq+1*32+3*128*64], m1
    mova [sdstq+2*32+3*128*64], m0
    mova [sdstq+3*32+3*128*64], m1
    cmp           bh4d, 2
    je .t_end
    mova           xm9, [rsp+2*8]
    vpblendd        m0, m9, 00000011b
    pextrd [tdstq+tstrideq*4+0], xm7, 2
    pextrw [tdstq+tstrideq*4+4], xm8, 6
    pextrd [tdstq+t0*2+0], xm7, 3
    pextrw [tdstq+t0*2+4], xm8, 7
    mova [sdstq+0*32+4*128*64], m0
    mova [sdstq+1*32+4*128*64], m1
    mova [sdstq+2*32+4*128*64], m0
    mova [sdstq+3*32+4*128*64], m1
    mova [sdstq+0*32+5*128*64], m0
    mova [sdstq+1*32+5*128*64], m1
    mova [sdstq+2*32+5*128*64], m0
    mova [sdstq+3*32+5*128*64], m1
    punpckhqdq     xm9, xm9
    vpblendd        m0, m9, 00000011b
    mova [sdstq+0*32+6*128*64], m0
    mova [sdstq+1*32+6*128*64], m1
    mova [sdstq+2*32+6*128*64], m0
    mova [sdstq+3*32+6*128*64], m1
    mova [sdstq+0*32+7*128*64], m0
    mova [sdstq+1*32+7*128*64], m1
    mova [sdstq+2*32+7*128*64], m0
    mova [sdstq+3*32+7*128*64], m1
    paddd           m3, m5
    paddd           m4, m5
    add          sdstq, 8*128*64
    lea          tdstq, [tdstq+tstrideq*8]
    sub           bh4d, 4
    jg .t1_loop
    jmp .t_end

.t2:
    lea             t0, [tstrideq*3]
    vpbroadcastd   m14, [pd_0xffff]
    psubd          m13, m14
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w16]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m5, [pd_0x20000]
    pmaddwd         m5, m4
    paddd           m4, m3, m5
    pslld           m5, 2
    WARP_LOOP_START  2
    vbroadcasti128 m11, [gmv_t2_shuf]
    pshufb          m7, m8, m11

    movq           xm9, [rsp+0*8]
    movq          xm10, [rsp+1*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    movq     [tdstq+0], xm7
    pextrd   [tdstq+8], xm7, 2
    mova [sdstq+2*32+0*128*64], m9
    mova [sdstq+3*32+0*128*64], m1
    mova [sdstq+4*32+0*128*64], m10
    mova [sdstq+5*32+0*128*64], m1
    mova [sdstq+6*32+0*128*64], m10
    mova [sdstq+7*32+0*128*64], m1
    mova [sdstq+2*32+1*128*64], m9
    mova [sdstq+3*32+1*128*64], m1
    mova [sdstq+4*32+1*128*64], m10
    mova [sdstq+5*32+1*128*64], m1
    mova [sdstq+6*32+1*128*64], m10
    mova [sdstq+7*32+1*128*64], m1
    add          sdstq, 2*128*64
    cmp           bh4d, 1
    je .t2_break
    movq           xm9, [rsp+4*8]
    movq          xm10, [rsp+5*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    psrldq          m8, 4
    pshufb          m8, m11
    movq   [tdstq+tstrideq*2+0], xm8
    pextrd [tdstq+tstrideq*2+8], xm8, 2
    mova [sdstq+2*32+0*128*64], m9
    mova [sdstq+3*32+0*128*64], m1
    mova [sdstq+4*32+0*128*64], m10
    mova [sdstq+5*32+0*128*64], m1
    mova [sdstq+6*32+0*128*64], m10
    mova [sdstq+7*32+0*128*64], m1
    mova [sdstq+2*32+1*128*64], m9
    mova [sdstq+3*32+1*128*64], m1
    mova [sdstq+4*32+1*128*64], m10
    mova [sdstq+5*32+1*128*64], m1
    mova [sdstq+6*32+1*128*64], m10
    mova [sdstq+7*32+1*128*64], m1
    add          sdstq, 2*128*64
    cmp           bh4d, 2
    je .t2_break
    movq           xm9, [rsp+2*8]
    movq          xm10, [rsp+3*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    vextracti128   xm7, m7, 1
    vextracti128   xm8, m8, 1
    movq   [tdstq+tstrideq*4+0], xm7
    pextrd [tdstq+tstrideq*4+8], xm7, 2
    movq   [tdstq+t0*2+0], xm8
    pextrd [tdstq+t0*2+8], xm8, 2
    mova [sdstq+2*32+0*128*64], m9
    mova [sdstq+3*32+0*128*64], m1
    mova [sdstq+4*32+0*128*64], m10
    mova [sdstq+5*32+0*128*64], m1
    mova [sdstq+6*32+0*128*64], m10
    mova [sdstq+7*32+0*128*64], m1
    mova [sdstq+2*32+1*128*64], m9
    mova [sdstq+3*32+1*128*64], m1
    mova [sdstq+4*32+1*128*64], m10
    mova [sdstq+5*32+1*128*64], m1
    mova [sdstq+6*32+1*128*64], m10
    mova [sdstq+7*32+1*128*64], m1
    movq           xm9, [rsp+6*8]
    movq          xm10, [rsp+7*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    mova [sdstq+2*32+2*128*64], m9
    mova [sdstq+3*32+2*128*64], m1
    mova [sdstq+4*32+2*128*64], m10
    mova [sdstq+5*32+2*128*64], m1
    mova [sdstq+6*32+2*128*64], m10
    mova [sdstq+7*32+2*128*64], m1
    mova [sdstq+2*32+3*128*64], m9
    mova [sdstq+3*32+3*128*64], m1
    mova [sdstq+4*32+3*128*64], m10
    mova [sdstq+5*32+3*128*64], m1
    mova [sdstq+6*32+3*128*64], m10
    mova [sdstq+7*32+3*128*64], m1
    paddd           m3, m5
    paddd           m4, m5
    add          sdstq, 4*128*64
    lea          tdstq, [tdstq+tstrideq*8]
    sub           bh4d, 4
    jg .t2_loop
.t2_break:
    ; the last line needs to write out everything
    mova [sdstq+0*32-1*128*64], m9
    mova [sdstq+1*32-1*128*64], m1
    jmp .t_end

.t4:
    vpbroadcastd   m14, [pd_0xffff]
    psubd          m13, m14
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w32]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m7, [pd_4]
    pslld           m5, m7, 16
    pmaddwd         m7, m4
    pmaddwd         m5, m4
    paddd           m4, m3, m7
    WARP_LOOP_START  4
    vbroadcasti128  m9, [gmv_t2_shuf]
    vpbroadcastq   m10, [gmv_t4b_shuf]
    pshufb          m7, m8, m9
    pshufb          m8, m10

    movq           xm9, [rsp+4*8]
    movq          xm10, [rsp+5*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    movu    [tdstq+ 0], xm7
    movq    [tdstq+16], xm8
    mova [sdstq+10*32+0*128*64], m9
    mova [sdstq+11*32+0*128*64], m1
    mova [sdstq+12*32+0*128*64], m10
    mova [sdstq+13*32+0*128*64], m1
    mova [sdstq+14*32+0*128*64], m10
    mova [sdstq+15*32+0*128*64], m1
    mova [sdstq+10*32+1*128*64], m9
    mova [sdstq+11*32+1*128*64], m1
    mova [sdstq+12*32+1*128*64], m10
    mova [sdstq+13*32+1*128*64], m1
    mova [sdstq+14*32+1*128*64], m10
    mova [sdstq+15*32+1*128*64], m1
    add          sdstq, 2*128*64
    cmp           bh4d, 1
    je .t4_break
    movq           xm9, [rsp+6*8]
    movq          xm10, [rsp+7*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    vextracti128 [tdstq+tstrideq*2+8], m8, 1
    vextracti128 [tdstq+tstrideq*2+0], m7, 1
    mova [sdstq+10*32+0*128*64], m9
    mova [sdstq+11*32+0*128*64], m1
    mova [sdstq+12*32+0*128*64], m10
    mova [sdstq+13*32+0*128*64], m1
    mova [sdstq+14*32+0*128*64], m10
    mova [sdstq+15*32+0*128*64], m1
    mova [sdstq+10*32+1*128*64], m9
    mova [sdstq+11*32+1*128*64], m1
    mova [sdstq+12*32+1*128*64], m10
    mova [sdstq+13*32+1*128*64], m1
    mova [sdstq+14*32+1*128*64], m10
    mova [sdstq+15*32+1*128*64], m1
    paddd           m3, m5
    paddd           m4, m5
    add          sdstq, 2*128*64
    lea          tdstq, [tdstq+tstrideq*4]
    sub           bh4d, 2
    jg .t4_loop
    ; the last line needs to write out everything
    movq          xm10, [rsp+2*8]
    movq          xm11, [rsp+3*8]
.t4_lastline:
    mova [sdstq+8*32-1*128*64], m9
    mova [sdstq+9*32-1*128*64], m1
    lea          sdstq, [sdstq-1*128*64+4*32]
    call .t_bottom_chunk
    jmp .t_end
.t4_break:
    movq          xm10, [rsp+0*8]
    movq          xm11, [rsp+1*8]
    jmp .t4_lastline
.t_bottom_chunk:
    vpblendd       m10, m0, m10, 00000011b
    vpblendd       m11, m0, m11, 00000011b
    mova  [sdstq-4*32], m10
    mova  [sdstq-3*32], m1
    mova  [sdstq-2*32], m10
    mova  [sdstq-1*32], m1
    mova  [sdstq+0*32], m11
    mova  [sdstq+1*32], m1
    mova  [sdstq+2*32], m11
    mova  [sdstq+3*32], m1
    ret

.t8:
    vpbroadcastd   m14, [pd_0xffff]
    psubd          m13, m14
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w64]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m7, [pd_4]
    pslld           m5, m7, 15
    pmaddwd         m7, m4
    pmaddwd         m5, m4
    paddd           m4, m3, m7
    WARP_LOOP_START  8
    vbroadcasti128 m10, [gmv_t8a_shuf]
    mova            m9, [gmv_t8b_shuf]
    pshufb          m7, m8, m10
    pshufb          m8, m9

    movq           xm9, [rsp+6*8]
    movq          xm10, [rsp+7*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    movq         [tdstq+ 0], xm7
    vextracti128 [tdstq+32], m7, 1
    movu         [tdstq+ 8], m8
    mova [sdstq+26*32+0*128*64], m9
    mova [sdstq+27*32+0*128*64], m1
    mova [sdstq+28*32+0*128*64], m10
    mova [sdstq+29*32+0*128*64], m1
    mova [sdstq+30*32+0*128*64], m10
    mova [sdstq+31*32+0*128*64], m1
    mova [sdstq+26*32+1*128*64], m9
    mova [sdstq+27*32+1*128*64], m1
    mova [sdstq+28*32+1*128*64], m10
    mova [sdstq+29*32+1*128*64], m1
    mova [sdstq+30*32+1*128*64], m10
    mova [sdstq+31*32+1*128*64], m1
    paddd           m3, m5
    paddd           m4, m5
    add          sdstq, 2*128*64
    lea          tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t8_loop
    ; the last line needs to write out everything
    mova [sdstq+24*32-1*128*64], m9
    mova [sdstq+25*32-1*128*64], m1

    lea          sdstq, [sdstq+4*32-1*128*64]
    movq          xm10, [rsp+0*8]
    movq          xm11, [rsp+1*8]
    call .t_bottom_chunk
    add          sdstq, 8*32
    movq          xm10, [rsp+4*8]
    movq          xm11, [rsp+5*8]
    call .t_bottom_chunk
    add          sdstq, 8*32
    movq          xm10, [rsp+2*8]
    movq          xm11, [rsp+3*8]
    call .t_bottom_chunk
    jmp .t_end

.t16: ; also used for .t32
%if WIN64
    mov            r7d, r5m
    lea             r7, [r7*3]
%else
    lea            r7d, [bw4q*3]
%endif
    vpbroadcastd   m14, [pd_0xffff]
    psubd          m13, m14
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w64]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m7, [pd_4]
    pslld           m8, m7, 15
    pmaddwd         m7, m4
    pmaddwd         m8, m4
    pslld           m5, m7, 2
    mova [rsp+2*mmsize], m8
    dec           bh4d
    jz .t16_lastline
    rorx           t0d, r5m, 26
    add          sdstq, t0
.t16_yloop:
    paddd           m4, m3, m7
    mova [rsp+3*mmsize], m3
    xor            t0d, t0d
    WARP_LOOP_START 16
    vbroadcasti128 m10, [gmv_t8a_shuf]
    mova            m9, [gmv_t8b_shuf]
    pshufb          m7, m8, m10
    pshufb          m8, m9

    movq         [tdstq+t0+ 0], xm7
    vextracti128 [tdstq+t0+32], m7, 1
    movu         [tdstq+t0+ 8], m8
    paddd           m3, m5
    paddd           m4, m5
    add            t0d, 48
    cmp            t0d, r7d
    jl .t16_loop
    movq           xm9, [rsp+6*8]
    movq          xm10, [rsp+7*8]
    vpblendd        m9, m0, m9, 00000011b
    vpblendd       m10, m0, m10, 00000011b
    mova [sdstq-6*32+0*128*64], m9
    mova [sdstq-5*32+0*128*64], m1
    mova [sdstq-4*32+0*128*64], m10
    mova [sdstq-3*32+0*128*64], m1
    mova [sdstq-2*32+0*128*64], m10
    mova [sdstq-1*32+0*128*64], m1
    mova [sdstq-6*32+1*128*64], m9
    mova [sdstq-5*32+1*128*64], m1
    mova [sdstq-4*32+1*128*64], m10
    mova [sdstq-3*32+1*128*64], m1
    mova [sdstq-2*32+1*128*64], m10
    mova [sdstq-1*32+1*128*64], m1
    mova            m3, [rsp+3*mmsize]
    paddd           m3, [rsp+2*mmsize]
    psrad           m7, m5, 2
    add          sdstq, 2*128*64
    lea          tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t16_yloop
    rorx           t0d, r5m, 26
    sub          sdstq, t0
.t16_lastline:
    paddd           m4, m3, m7
    lea          sdstq, [sdstq+1*128*64+4*32]
    xor            t0d, t0d
    WARP_LOOP_START 16last
    movq          xm10, [rsp+0*8]
    movq          xm11, [rsp+1*8]
    call .t_bottom_chunk
    add          sdstq, 8*32
    movq          xm10, [rsp+4*8]
    movq          xm11, [rsp+5*8]
    call .t_bottom_chunk
    add          sdstq, 8*32
    movq          xm10, [rsp+2*8]
    movq          xm11, [rsp+3*8]
    call .t_bottom_chunk
    add          sdstq, 8*32
    movq          xm10, [rsp+6*8]
    movq          xm11, [rsp+7*8]
    call .t_bottom_chunk
    add          sdstq, 8*32
    vbroadcasti128  m7, [gmv_t8a_shuf]
    mova            m9, [gmv_t8b_shuf]
    pshufb          m7, m8, m7
    pshufb          m8, m9
    movq         [tdstq+t0+ 0], xm7
    vextracti128 [tdstq+t0+32], m7, 1
    movu         [tdstq+t0+ 8], m8
    paddd           m3, m5
    paddd           m4, m5
    add            t0d, 48
    cmp            t0d, r7d
    jl .t16last_loop
    lea          sdstq, [sdstq-8*32-128*64]
    mova  [sdstq-2*32], m10
    mova  [sdstq-1*32], m1
    mova  [sdstq+0*32], m11
    mova  [sdstq+1*32], m1
    mova  [sdstq+2*32], m11
    mova  [sdstq+3*32], m1
.t_end:
    RET
%if WIN64
    %assign stack_offset stack_offset-gprsize
    %assign regs_used regs_used-1
%endif

.spatial_only:
    mova            m0, [ssrcq+ 0]
    mova            m1, [ssrcq+32]
    mova           xm4, [pd_65536_0_0_65536]
    mova           xm3, [ssrcq+refmvs_block.mat+8]  ; mat[2-5]
    vpbroadcastd   xm2, [ssrcq+refmvs_block.bx4]    ; bx4, by4 as words
                                                    ; range is 0..0x3fff-w/h
    psubd          xm3, xm4                         ; m2-0x10000,m3,m4,m5-0x10000
                                                    ; range is -0x7fc0,+0x7fc0
    vpbroadcastq   xm4, [ssrcq+refmvs_block.mat]    ; mat[0-1]
    packssdw       xm3, xm3                         ; dword->word (and duplicate)
    vpbroadcastd   xm5, [pd_1024]
    psrad          xm4, 2                           ; mat[0-1] >> 2
    mov           bh4d, bh4m
    cmp     dword bw4m, 2
    jg .s3
    ; fall-through
.s2:
    ; it's in theory possible to unroll using the higher land also, but this
    ; just leads to duplicate write-out code without any additional perf gains
    WIN64_SPILL_XMM  8
    paddw          xm2, [pw_warp_off_w8]            ; bx4 + 1, by4 + 1/3
                                                    ; range is 1-0x3fff [14bits]
    vpbroadcastd   xm6, [pd_0xffff]
    vpbroadcastd   xm7, [pd_0x40000]
    pmaddwd        xm2, xm3
    paddd          xm2, xm4
    pmaddwd        xm3, xm7
    pxor           xm7, xm7
    psubd          xm7, xm6                         ; -0xffff
.s2_loop:
    psrad          xm4, xm2, 31                     ; -(mvx/yi < 0)
    paddd          xm4, xm5                         ; 1024 - (mvx/yi < 0)
    paddd          xm4, xm2                         ; mvx/yi + 1024 - (mvx/yi < 0)
    psrad          xm4, 11                          ; warpmv (unclipped)
    pmaxsd         xm4, xm7
    pminsd         xm4, xm6                         ; warpmv (clipped)
    vpblendd        m0, m4, 00000011b
    mova [sdstq+32*0+0*64*128], m0
    mova [sdstq+32*1+0*64*128], m1
    mova [sdstq+32*2+0*64*128], m0
    mova [sdstq+32*3+0*64*128], m1
    mova [sdstq+32*0+1*64*128], m0
    mova [sdstq+32*1+1*64*128], m1
    mova [sdstq+32*2+1*64*128], m0
    mova [sdstq+32*3+1*64*128], m1
    cmp           bh4d, 2
    je .s2_break
    punpckhqdq     xm4, xm4
    vpblendd        m0, m4, 00000011b
    mova [sdstq+32*0+2*64*128], m0
    mova [sdstq+32*1+2*64*128], m1
    mova [sdstq+32*2+2*64*128], m0
    mova [sdstq+32*3+2*64*128], m1
    mova [sdstq+32*0+3*64*128], m0
    mova [sdstq+32*1+3*64*128], m1
    mova [sdstq+32*2+3*64*128], m0
    mova [sdstq+32*3+3*64*128], m1
    paddd          xm2, xm3
    add          sdstq, 128*64*4
    sub           bh4d, 4
    jg .s2_loop
.s2_break:
    WIN64_RESTORE_XMM
    RET

.s3:
    WIN64_SPILL_XMM 11
    vpbroadcastd   xm9, bh4m
    paddw          xm8, xm2, [pw_warp_off_w16bot]   ; bx4 + 1/3, by4 - 1
    pslld          xm9, 16
    vpbroadcastd   xm6, [pd_0xffff]
    vpbroadcastd   xm7, [pd_4]
    paddw          xm8, xm9
    pmaddwd        xm8, xm3
    paddd          xm8, xm4
    pmaddwd        xm9, xm3, xm7
    pxor           xm7, xm7
    psubd          xm7, xm6                         ; -0xffff
    sub           bh4d, 2
    jz .last_line
    paddw          xm2, [pw_warp_off_w16top]        ; bx4 - 3/1, by4 + 1
                                                    ; range is 1-0x3fff [14bits]
%if WIN64
    vpbroadcastd  xm10, bw4m
%else
    movd          xm10, bw4d
    vpbroadcastd  xm10, xm10
%endif
    paddw          xm2, xm10
    pmaddwd        xm2, xm3
    paddd          xm2, xm4
    vpbroadcastd   xm4, [pd_0x20000]
    pmaddwd        xm3, xm4
    rorx          bw4d, bw4m, 26
    add          sdstq, bw4q
    neg           bw4q
.s3_loop:
    psrad          xm4, xm2, 31                     ; -(mvx/yi < 0)
    paddd          xm4, xm5                         ; 1024 - (mvx/yi < 0)
    paddd          xm4, xm2                         ; mvx/yi + 1024 - (mvx/yi < 0)
    psrad          xm4, 11                          ; warpmv (unclipped)
    pmaxsd         xm4, xm7
    pminsd         xm4, xm6                         ; warpmv (clipped)
    vpblendd        m0, m4, 00000011b
    mova  [sdstq-32*6+128*64*0], m0
    mova  [sdstq-32*5+128*64*0], m1
    mova  [sdstq-32*6+128*64*1], m0
    mova  [sdstq-32*5+128*64*1], m1
    punpckhqdq     xm4, xm4
    vpblendd        m0, m4, 00000011b
    mova  [sdstq-32*4+128*64*0], m0
    mova  [sdstq-32*3+128*64*0], m1
    mova  [sdstq-32*2+128*64*0], m0
    mova  [sdstq-32*1+128*64*0], m1
    mova  [sdstq-32*4+128*64*1], m0
    mova  [sdstq-32*3+128*64*1], m1
    mova  [sdstq-32*2+128*64*1], m0
    mova  [sdstq-32*1+128*64*1], m1
    paddd          xm2, xm3
    add          sdstq, 128*64*2
    sub           bh4d, 2
    jg .s3_loop
    jmp .last_line_loop
.last_line:
    rorx          bw4d, bw4m, 26
    add          sdstq, bw4q
    neg           bw4q
.last_line_loop:
    psrad          xm4, xm8, 31                     ; -(mvx/yi < 0)
    paddd          xm4, xm5                         ; 1024 - (mvx/yi < 0)
    paddd          xm4, xm8                         ; mvx/yi + 1024 - (mvx/yi < 0)
    psrad          xm4, 11                          ; warpmv (unclipped)
    pmaxsd         xm4, xm7
    pminsd         xm4, xm6                         ; warpmv (clipped)
    vpblendd        m0, m4, 00000011b
    mova [sdstq+bw4q+0*32+128*64], m0
    mova [sdstq+bw4q+1*32+128*64], m1
    mova [sdstq+bw4q+2*32+128*64], m0
    mova [sdstq+bw4q+3*32+128*64], m1
    punpckhqdq     xm4, xm4
    vpblendd        m4, m0, m4, 00000011b
    mova [sdstq+bw4q+4*32+128*64], m4
    mova [sdstq+bw4q+5*32+128*64], m1
    mova [sdstq+bw4q+6*32+128*64], m4
    mova [sdstq+bw4q+7*32+128*64], m1
    paddd          xm8, xm9
    add           bw4q, 64*4
    jl .last_line_loop
    mova  [sdstq-32*6], m0
    mova  [sdstq-32*5], m1
    mova  [sdstq-32*4], m4
    mova  [sdstq-32*3], m1
    mova  [sdstq-32*2], m4
    mova  [sdstq-32*1], m1
    WIN64_RESTORE_XMM
    RET

.gmv:
    ; for global motion, only temporal MVs are warp-adjusted
    test         tdstq, tdstq
    jz mangle(private_prefix %+ _splat_mv_avx2).spatial

    ; temporal loop
%if WIN64
    WIN64_SPILL_XMM 16
    %define GMV_END .gmv_end
%else
    %define GMV_END mangle(private_prefix %+ _splat_mv_avx2).spatial
%endif
    movifnidn     matq, matmp
    vpbroadcastd    m0, [pd_131]
    vpbroadcastw    m1, [tsrcq+4]       ; t_src.ref
    pxor          xm13, xm13
    punpcklbw       m1, m13

    vbroadcasti128  m5, [pd_65536_0_0_65536]
    vbroadcasti128  m4, [matq+8]                    ; mat[2-5]
    vpbroadcastd    m3, [ssrcq+refmvs_block.bx4]    ; bx4, by4 as words
                                                    ; range is 0..0x3fff-w/h
    psubd           m4, m5                          ; m2-0x10000,m3,m4,m5-0x10000
                                                    ; range is -0x7fc0,+0x7fc0
    vpbroadcastq    m5, [matq]                      ; mat[0-1]
    packssdw        m4, m4                          ; dword->word (and duplicate)
    vpbroadcastd    m6, [pd_1024]
    psrad           m5, 2                           ; mat[0-1] >> 2

    lea             r6, [splat_warpmv_avx2_table]
    tzcnt          r7d, bw4m
    movsxd          r7, [r6+r7*4-4]
    add             r7, r6
    mov           bh4d, bh4m
    lea       tstrideq, [tstrideq*3]
    shr           bh4d, 1
    jmp             r7

%macro WARPGMV_LOOP_START 1-4 1, 1, 1 ; size, have_min1 [in m2], have_zero [in m13]
                                      ; have other constants [in m14-15]
.gmv_t%1_loop:
    psrad           m7, m3, 31
    psrad           m8, m4, 31                      ; -(mvx/yi < 0)
    REPX {paddd x, m6}, m7, m8                      ; 1024 - (mvx/yi < 0)
    paddd           m7, m3
    paddd           m8, m4
    REPX {psrad x, 11}, m7, m8                     ; warpmv
    ; any clipped mv is INVALID_TRAJ so we can skip clipping
    pabsd           m9, m7
    pabsd          m10, m8
    cvtdq2ps       m11, m9
    cvtdq2ps       m12, m10
    REPX {psrld   x, 23}, m11, m12                  ; extract exponent bits
    REPX {psubusw x, m0}, m11, m12                  ; nbits=imax(log2(absv)-4, 0)
    vpsrlvd         m9, m11
    vpsrlvd        m10, m12                         ; absv >> nbits [dwords]
    packssdw       m11, m12                         ; nbits [words]
%if %3 == 0
    pxor           m12, m12
%endif
    packssdw        m9, m10                         ; absv >> nbits [words]
%if %4 == 0
    vpbroadcastd   m10, [pw_6]
%endif
    packssdw        m7, m8                          ; v [words]
%if %4
    pcmpgtw        m10, m11, m14
%else
    vpbroadcastd    m8, [pw_m128]
    pcmpgtw        m10, m11, m10
%endif
    psllw          m11, 4                           ; 16*nbits
%if %3
    pcmpeqd        m10, m13                         ; nbits <= 6 for x+y comps
%else
    pcmpeqd        m10, m12                         ; nbits <= 6 for x+y comps
%endif
    paddw           m9, m11
%if %2 == 0
    pcmpeqw        m11, m11
%endif
    psignw          m9, m7

%if %4
    pblendvb        m8, m15, m9, m10                ; interleave -0x80 if invalid
%else
    pblendvb        m8, m9, m10                     ; interleave -0x80 if invalid
%endif
%if %2
    pblendvb        m7, m2, m1, m10                 ; set ref to -1 if invalid
%else
    pblendvb        m7, m11, m1, m10                ; set ref to -1 if invalid
%endif
    packsswb        m8, m7                          ; word->byte, and interleave refs
%endmacro

INIT_XMM avx2
.gmv_t1:
    lea             t0, [tstrideq*3]
    vpbroadcastd   m14, [pw_6]
    vpbroadcastd   m15, [pw_m128]
    pcmpeqw         m2, m2
    paddw           m3, [pw_warp_off_w8]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m5, [pd_0x40000]
    pmaddwd         m5, m4
    paddd           m4, m3, m5
    paddd           m5, m5
    WARPGMV_LOOP_START 1
    punpcklwd       m7, m8, m8
    movd     [tdstq+0], m7
    pextrw   [tdstq+4], m8, 4
    cmp           bh4d, 1
    je GMV_END
    pextrd [tdstq+tstrideq*2+0], m7, 1
    pextrw [tdstq+tstrideq*2+4], m8, 5
    cmp           bh4d, 2
    je GMV_END
    pextrd [tdstq+tstrideq*4+0], m7, 2
    pextrw [tdstq+tstrideq*4+4], m8, 6
    pextrd [tdstq+t0*2+0], m7, 3
    pextrw [tdstq+t0*2+4], m8, 7
    paddd           m3, m5
    paddd           m4, m5
    lea          tdstq, [tdstq+tstrideq*8]
    sub           bh4d, 4
    jg .gmv_t1_loop
    jmp GMV_END

INIT_YMM avx2
.gmv_t2:
    lea             t0, [tstrideq*3]
    vpbroadcastd   m14, [pw_6]
    vpbroadcastd   m15, [pw_m128]
    vbroadcasti128  m2, [gmv_t2_shuf]
    paddw           m3, [pw_warp_off_w16]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m5, [pd_0x20000]
    pmaddwd         m5, m4
    paddd           m4, m3, m5
    pslld           m5, 2
    WARPGMV_LOOP_START 2, 0
    pshufb          m7, m8, m2
    movq     [tdstq+0], xm7
    pextrd   [tdstq+8], xm7, 2
    cmp           bh4d, 1
    je GMV_END
    psrldq          m8, 4
    pshufb          m8, m2
    movq   [tdstq+tstrideq*2+0], xm8
    pextrd [tdstq+tstrideq*2+8], xm8, 2
    cmp           bh4d, 2
    je GMV_END
    vextracti128   xm7, m7, 1
    vextracti128   xm8, m8, 1
    movq   [tdstq+tstrideq*4+0], xm7
    pextrd [tdstq+tstrideq*4+8], xm7, 2
    movq   [tdstq+t0*2+0], xm8
    pextrd [tdstq+t0*2+8], xm8, 2
    paddd           m3, m5
    paddd           m4, m5
    lea          tdstq, [tdstq+tstrideq*8]
    sub           bh4d, 4
    jg .gmv_t2_loop
    jmp GMV_END

.gmv_t4:
    vbroadcasti128  m2, [gmv_t2_shuf]
    vpbroadcastq   m13, [gmv_t4b_shuf]
    vpbroadcastd   m14, [pw_6]
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w32]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m7, [pd_4]
    pslld           m5, m7, 16
    pmaddwd         m7, m4
    pmaddwd         m5, m4
    paddd           m4, m3, m7
    WARPGMV_LOOP_START 4, 0, 0
    pshufb          m7, m8, m2
    pshufb          m8, m13
    movu    [tdstq+ 0], xm7
    movq    [tdstq+16], xm8
    cmp           bh4d, 1
    je GMV_END
    vextracti128 [tdstq+tstrideq*2+8], m8, 1
    vextracti128 [tdstq+tstrideq*2+0], m7, 1
    paddd           m3, m5
    paddd           m4, m5
    lea          tdstq, [tdstq+tstrideq*4]
    sub           bh4d, 2
    jg .gmv_t4_loop
    jmp GMV_END

.gmv_t8:
    vbroadcasti128  m2, [gmv_t8a_shuf]
    mova           m13, [gmv_t8b_shuf]
    vpbroadcastd   m14, [pw_6]
    vpbroadcastd   m15, [pw_m128]
    paddw           m3, [pw_warp_off_w64]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m7, [pd_4]
    pslld           m5, m7, 15
    pmaddwd         m7, m4
    pmaddwd         m5, m4
    paddd           m4, m3, m7
    WARPGMV_LOOP_START 8, 0, 0
    pshufb          m7, m8, m2
    pshufb          m8, m13
    movq         [tdstq+ 0], xm7
    vextracti128 [tdstq+32], m7, 1
    movu         [tdstq+ 8], m8
    paddd           m3, m5
    paddd           m4, m5
    lea          tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .gmv_t8_loop
    jmp GMV_END

.gmv_t16: ; also use for .gmv_t32
%if WIN64
    mov            r7d, bw4m
    lea             r7, [r7*3]
%else
    lea            r7d, [bw4d*3]
%endif
    vbroadcasti128  m2, [gmv_t8a_shuf]
    mova           m13, [gmv_t8b_shuf]
    paddw           m3, [pw_warp_off_w64]
    pmaddwd         m3, m4
    paddd           m3, m5
    vpbroadcastd    m7, [pd_4]
    pslld          m14, m7, 15
    pmaddwd         m7, m4
    pmaddwd        m14, m4
    pslld           m5, m7, 2
.gmv_t16_yloop:
    paddd           m4, m3, m7
    mova           m15, m3
    xor            t0d, t0d
    WARPGMV_LOOP_START 16, 0, 0, 0
    pshufb          m7, m8, m2
    pshufb          m8, m13
    movq         [tdstq+t0+ 0], xm7
    vextracti128 [tdstq+t0+32], m7, 1
    movu         [tdstq+t0+ 8], m8
    paddd           m3, m5
    paddd           m4, m5
    add            t0d, 48
    cmp            t0d, r7d
    jl .gmv_t16_loop
    paddd           m3, m15, m14
    psrad           m7, m5, 2
    lea          tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .gmv_t16_yloop
%if WIN64
.gmv_end:
    WIN64_RESTORE_XMM
%endif
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

INIT_YMM avx2
cglobal splat_comp_wedgemv, 5, 8, 3, sdst, ssrc, tdst, tstride, tsrc, bw4, bh4, wedge, wswap
    test         tdstq, tdstq
    jz mangle(private_prefix %+ _splat_mv_avx2).spatial

    ; temporal loop
    vpbroadcastd    m0, [tsrcq]
    vpbroadcastd    m1, [pb_128]
    vpbroadcastd    m2, wswapm
    vpbroadcastd    m3, [pd_0xffff]
    vpbroadcastw    m4, [tsrcq+4]
    pxor            m5, m5
    punpcklbw       m4, m4, m5          ; t_src.ref in 2 words
    pshuflw         m5, m4, q2301
    pshufhw         m5, m5, q2301       ; t_src.ref[1,0]
    lea             r6, [splat_comp_wedgemv_avx2_table]
    tzcnt          r7d, bw4m
    movsxd          r7, [r6+r7*4-4]
    add             r7, r6
    mov           bh4d, bh4m
    lea       tstrideq, [tstrideq*3]
    shr           bh4d, 1
    jmp             r7

%macro COMP_WEDGEMV_LOOP_START 1-2 1 ; len, shuffle_end
.t%1:
    mov         wedgeq, wedgemp
    WIN64_SPILL_XMM 12
%if mmsize == 16
    mova            m9, [t4_shufA]
    mova           m10, [t4_shufB]
%else
    vbroadcasti128  m9, [t4_shufA]
    vbroadcasti128 m10, [t4_shufB]
%endif
    psrldq         m11, m9, 4
.t%1_loop:
    pmovzxbd        m6, [wedgeq]        ; d [range: 0-2]
    pxor            m6, m2              ; d^wswap [range: 0-3]
    pslld           m6, 4
    vpsllvd         m6, m3, m6          ; if d^wswap==0:  2x-1,14x0
                                        ; if d^w_swap==1: 2x0,2x-1,12x0
                                        ; else:           16x0
    vpblendvb       m6, m0, m1, m6      ; t_src.mv w/ invalidated wedge-MVs

    pcmpeqw         m7, m6, m1          ; whether mv0 or mv1 are invalid
    pshuflw         m8, m6, q2301       ; t_src.mv[1,0]
    pshufhw         m8, m8, q2301       ; t_src.mv[1,0]
    vpblendvb       m6, m6, m8, m7      ; if both mvs are valid:    mv0, mv1
                                        ; if mv0=invalid&mv1=valid: mv1 [2x]
                                        ; if mv0=valid&mv1=invalid: mv0 [2x]
                                        ; if both mvs are invalid:  invalid_mv [2x]
    vpblendvb       m7, m4, m5, m7      ; if both mvs are valid:    ref0, ref1
                                        ; if mv0=invalid&mv1=valid: ref1 [2x]
                                        ; if mv0=valid&mv1=invalid: ref0 [2x]
    pcmpeqd         m8, m6, m1          ; whether mv0 and mv1 are invalid
    por             m7, m8              ; if both mvs are valid:    ref0, ref1
                                        ; if mv0=invalid&mv1=valid: ref1 [2x]
                                        ; if mv0=valid&mv1=invalid: ref0 [2x]
                                        ; if both mvs are invalid:  -1
%if %2
    pshufb          m7, m9              ; ref2,ref3,8x?,ref0,ref1
    palignr         m8, m6, m7, 12      ; [0..3]ref0-1,[4..15]mv0-2
    palignr         m6, m7, m6, 12      ; [0..3]mv3,[4..7]ref2-3
    pshufb          m8, m10
    pshufb          m6, m11
%else
    packsswb        m7, m7
%endif
%endmacro

    INIT_XMM avx2
    COMP_WEDGEMV_LOOP_START 1, 0
    movd    [tdstq+ 0], m6
    pextrw  [tdstq+ 4], m7, 0
    dec           bh4d
    jz .t1_break
    pextrd  [tdstq+tstrideq*2+ 0], m6, 1
    pextrw  [tdstq+tstrideq*2+ 4], m7, 1
    dec           bh4d
    jz .t1_break
    lea          tdstq, [tdstq+tstrideq*4]
    pextrd  [tdstq+ 0], m6, 2
    pextrw  [tdstq+ 4], m7, 2
    pextrd  [tdstq+tstrideq*2+ 0], m6, 3
    pextrw  [tdstq+tstrideq*2+ 4], m7, 3
    add         wedgeq, 4
    lea          tdstq, [tdstq+tstrideq*4]
    sub           bh4d, 2
    jg .t1_loop
.t1_break:
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

    INIT_YMM avx2
    COMP_WEDGEMV_LOOP_START 2
    movq    [tdstq+ 0], xm8
    pextrd  [tdstq+ 8], xm8, 2
    dec           bh4d
    jz .t2_break
    pextrd  [tdstq+tstrideq*2+ 0], xm8, 3
    movq    [tdstq+tstrideq*2+ 4], xm6
    dec           bh4d
    jz .t2_break
    lea          tdstq, [tdstq+tstrideq*4]
    vextracti128   xm8, m8, 1
    vextracti128   xm7, m6, 1
    movq    [tdstq+ 0], xm8
    pextrd  [tdstq+ 8], xm8, 2
    pextrd  [tdstq+tstrideq*2+ 0], xm8, 3
    movq    [tdstq+tstrideq*2+ 4], xm7
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*4]
    sub           bh4d, 2
    jg .t2_loop
.t2_break:
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

    COMP_WEDGEMV_LOOP_START 4
    movu    [tdstq+ 0], xm8
    movq    [tdstq+16], xm6
    dec           bh4d
    jz .t4_break
    vextracti128   xm7, m6, 1
    vextracti128 [tdstq+tstrideq*2+ 0], m8, 1
    movq         [tdstq+tstrideq*2+16], xm7
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*4]
    dec           bh4d
    jg .t4_loop
.t4_break:
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial

    COMP_WEDGEMV_LOOP_START 8
    vextracti128   xm7, m6, 1
    movu         [tdstq+ 0], xm8
    movq         [tdstq+16], xm6
    vextracti128 [tdstq+24], m8, 1
    movq         [tdstq+40], xm7
    add         wedgeq, 8
    lea          tdstq, [tdstq+tstrideq*2]
    dec           bh4d
    jg .t8_loop
    WIN64_RESTORE_XMM
    jmp mangle(private_prefix %+ _splat_mv_avx2).spatial
%endif ; ARCH_X86_64
