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

pd_div_mult: dd    0, 16384, 8192, 5461, 4096, 3276, 2730, 2340
             dd 2048,  1820, 1638, 1489, 1365, 1260, 1170, 1092
             dd 1024,   963,  910,  862,  819,  780,  744,  712
             dd  682,   655,  630,  606,  585,  564,  546,  528

msk_A: times 2 db  0, -1, -1, -1
       times 2 db  8, -1, -1, -1
       times 2 db  4, -1, -1, -1
       times 2 db 12, -1, -1, -1
msk_B: times 2 db  2, -1, -1, -1
       times 2 db 10, -1, -1, -1
       times 2 db  6, -1, -1, -1
       times 2 db 14, -1, -1, -1
msk_C: db 0, 0, 2, 2, 4, 4, 6, 6, 8, 8, 10, 10, 12, 12, 14, 14

pw_div: dw 16384, 8192, 85 << 6, 4096
pb_0to7: db 0, 1, 2, 3, 4, 5, 6, 7
pb_3b5d7f9x: db 3, 11, 5, 13, 7, 15, 9, -1
pb_082a4c6e: db 0, 8, 2, 10, 4, 12, 6, 14
pb_06012345: db 0, 6, 0, 1, 2, 3, 4, 5
pb_23456717: db 2, 3, 4, 5, 6, 7, 1, 7
pb_04060123: db 0, 4, 0, 6, 0, 1, 2, 3
pb_7x0_m1: times 7 db 0
           db -1

pd_32768: dd 32768
pw_m32768: times 2 dw -32768
pw_mv_invalid: dw 0x2000, 0
pb_2: times 4 db 2
pb_2_3: times 2 db 2, 3
pb_6_7: times 2 db 6, 7
pw_8: times 2 dw 8
pw_m2047: times 2 dw -2047
pd_8: dd 8
pd_16: dd 16

; the -1 is a magical value required to detect sum_n=0
pw_neg_idiv_plus_32768: dw -1, -32768, 0, 10923, 16384, 19661

pb_shr: times 2 db 0
pb_shl: db 1, 2, 3, 4, 5, 6, 7, 7

SECTION .text

%define m(x) mangle(private_prefix %+ _ %+ x %+ SUFFIX)

INIT_YMM avx2
cglobal tip_projection, 4, 10, 10, 32 * 4, rp, stride, col_start8, col_end8, \
                                           h8, tmvp_sample_step, tip_delta
    vpbroadcastd             m6, tip_deltam
    vpbroadcastb            xm8, xm6
    pmaddwd                  m0, m6, [pd_div_mult+0*32]
    pmaddwd                  m1, m6, [pd_div_mult+1*32]
    pmaddwd                  m2, m6, [pd_div_mult+2*32]
    pmaddwd                  m3, m6, [pd_div_mult+3*32]
    mova             [rsp+0*32], m0
    mova             [rsp+1*32], m1
    mova             [rsp+2*32], m2
    mova             [rsp+3*32], m3
    vpbroadcastd             m7, [pw_8]
    vpbroadcastd             m9, [pw_mv_invalid]
    vpbroadcastd             m6, [pw_m2047]
    movifnidn               h8d, h8m
    lea                 strideq, [strideq*5]
    cmp dword tmvp_sample_stepm, 1
    je .sample_step_1
    mov                     r6m, r11
    mov                      r8, rsp
    DEFINE_ARGS rp, stride, x, col_end8, hb, h
    ; fall-through to .sample_step_2. Here, we are sure that sbsz8 is 16 or 32,
    ; and therefore that col/row_start8 are at least 16-aligned
.ss2_xloop:
    mov                     r6d, xd
    mov                     r7d, xd
    and                     r6d, ~31
    and                     r7d, 31
    lea                      r6, [r6*5]
    add                      r6, rpq

    mov                      hd, hbd
.ss2_yloop:
    call .load_row_ss2
    pmulld                   m0, m2                 ; mv.x/y *= div_mult[den] * num
    pmulld                   m1, m3
    psrad                    m2, 31                 ; mv.x/y < 0
    psrad                    m3, 31
    paddd                    m0, m2                 ; -= mv.x/y < 0
    paddd                    m1, m3
    REPX        {psrad   x, 10}, m0, m1             ; mv.x/y >>= 10
    packssdw                 m0, m1                 ; this clamps to +(2048<<4)-1
    paddsw                   m0, m7                 ; mv.x/y += 8
    psraw                    m0, 4                  ; mv.x/y >>= 4
    pmaxsw                   m0, m6                 ; clamp to -2047
    pcmpeqd                  m4, m9                 ; mv.y == INVALID_MV
    vpblendvb                m0, m9, m4             ; if in_mv.y == INVALID_MV:
                                                    ;     out_mv.y = INVALID_MV
    ; write garbage in odd entries. this is OK since they're unused, and will
    ; later be filled by fill_gap_proj()
    mova         [r6+32*0+r7*4], m0                 ; rp_proj_ptr->mv[pos] =
                                                    ;     dav2d_mv_projection()
    psrldq                   m0, 4
    mova         [r6+32*1+r7*4], m0
    mova           [r6+32*4+r7], xm8                ; rp_proj_ptr->ref[pos] =
                                                    ;     tip_delta
    lea                      r6, [r6+strideq*2]
    sub                      hd, 2
    jg .ss2_yloop
    add                      xd, 16
    cmp                      xd, col_end8d
    jl .ss2_xloop
    mov                     r11, r6m
    RET
.load_row_ss2:
    ; why no gatherdq? because it's 3x as slow :(
    mova                     m4, [r6+32*0+r7*4]     ; mv.x/y = rp_proj_ptr->mv[pos]
    vpblendd                 m4, [r6+32*1+r7*4-4], 10101010b
    movzx                   r9d, byte [r6+32*4+r7+0]
    movzx                  r11d, byte [r6+32*4+r7+2]
    vpbroadcastd            xm0, [r8+r9*4]
    vpbroadcastd            xm1, [r8+r11*4]
    movzx                   r9d, byte [r6+32*4+r7+8]
    movzx                  r11d, byte [r6+32*4+r7+10]
    vpbroadcastd            xm2, [r8+r9*4]
    vpbroadcastd            xm3, [r8+r11*4]
    vpblendd                xm0, xm2, 1100b
    vpblendd                xm1, xm3, 1100b
    movzx                   r9d, byte [r6+32*4+r7+4]
    movzx                  r11d, byte [r6+32*4+r7+6]
    vpbroadcastd             m2, [r8+r9*4]
    vpbroadcastd             m3, [r8+r11*4]
    vpblendd                 m0, m2, 110000b
    vpblendd                 m1, m3, 110000b
    movzx                   r9d, byte [r6+32*4+r7+12]
    movzx                  r11d, byte [r6+32*4+r7+14]
    vpbroadcastd             m2, [r8+r9*4]
    vpbroadcastd             m3, [r8+r11*4]
    vpblendd                 m0, m2, 11000000b
    vpblendd                 m1, m3, 11000000b
    psraw                    m3, m4, 15
    punpcklwd                m2, m4, m3
    punpckhwd                m3, m4, m3
    ret
.sample_step_1:
    ; col/row_start8 are 8-aligned
.ss1_xloop:
    mov                     r6d, xd
    mov                     r7d, xd
    and                     r6d, ~31
    and                     r7d, 31
    lea                      r6, [r6*5]
    add                      r6, rpq

    mov                      hd, hbd
.ss1_yloop:
    ; why no gatherdq? because it's 3x as slow :(
    mova                     m4, [r6+32*0+r7*4]     ; mv.x/y = rp_proj_ptr->mv[pos]
    movzx                   r8d, byte [r6+32*4+r7+0]
    movzx                   r9d, byte [r6+32*4+r7+2]
    vpbroadcastd            xm0, [rsp+r8*4]
    vpbroadcastd            xm1, [rsp+r9*4]
    movzx                   r8d, byte [r6+32*4+r7+1]
    movzx                   r9d, byte [r6+32*4+r7+3]
    vpbroadcastd            xm2, [rsp+r8*4]
    vpbroadcastd            xm3, [rsp+r9*4]
    vpblendd                xm0, xm2, 1100b
    vpblendd                xm1, xm3, 1100b
    movzx                   r8d, byte [r6+32*4+r7+4]
    movzx                   r9d, byte [r6+32*4+r7+6]
    vpbroadcastd             m2, [rsp+r8*4]
    vpbroadcastd             m3, [rsp+r9*4]
    vpblendd                 m0, m2, 110000b
    vpblendd                 m1, m3, 110000b
    movzx                   r8d, byte [r6+32*4+r7+5]
    movzx                   r9d, byte [r6+32*4+r7+7]
    vpbroadcastd             m2, [rsp+r8*4]
    vpbroadcastd             m3, [rsp+r9*4]
    vpblendd                 m0, m2, 11000000b
    vpblendd                 m1, m3, 11000000b
    psraw                    m3, m4, 15
    punpcklwd                m2, m4, m3
    punpckhwd                m3, m4, m3
    pmulld                   m0, m2                 ; mv.x/y *= div_mult[den] * den
    pmulld                   m1, m3
    psrad                    m2, 31                 ; mv.x/y < 0
    psrad                    m3, 31
    paddd                    m0, m2                 ; -= mv.x/y < 0
    paddd                    m1, m3
    REPX        {psrad   x, 10}, m0, m1             ; mv.x/y >>= 10
    packssdw                 m0, m1                 ; this clamps to +(2048<<4)-1
    paddsw                   m0, m7                 ; mv.x/y += 8
    psraw                    m0, 4                  ; mv.x/y >>= 4
    pmaxsw                   m0, m6                 ; clamp to -2047
    pcmpeqd                  m4, m9                 ; mv.y == INVALID_MV
    vpblendvb                m0, m9, m4             ; if in_mv.y == INVALID_MV:
                                                    ;     out_mv.y = INVALID_MV
    mova         [r6+32*0+r7*4], m0                 ; rp_proj_ptr->mv[pos] =
                                                    ;     dav2d_mv_projection()
    movq           [r6+32*4+r7], xm8                ; rp_proj_ptr->ref[pos] =
                                                    ;     tip_delta
    add                      r6, strideq
    dec                      hd
    jg .ss1_yloop
    add                      xd, 8
    cmp                      xd, col_end8d
    jl .ss1_xloop
    RET

INIT_YMM avx2
cglobal tip_fill_holes, 4, 9, 14, rp, stride, col_start8, col_end8, \
                                  h8, tmvp_sample_step
    vpbroadcastd             m6, [pw_mv_invalid]
    movd                    xm8, col_end8d
    vpbroadcastd             m8, xm8
    movifnidn               h8d, h8m
    lea                 strideq, [strideq*5]
    cmp dword tmvp_sample_stepm, 1
    je .sample_step_1
    pmovzxbd                 m0, [pb_082a4c6e]
    vpbroadcastd             m1, [pd_16]
    psubd                    m8, m0
    psubd                    m9, m8, m1
    pmovzxbd                m11, [pb_06012345]
    pmovzxbd                m12, [pb_23456717]
    pmovzxbd                 m7, [pb_04060123]
    DEFINE_ARGS rp, stride, x, col_end8, h8, y
    ; fall-through to .sample_step_2. Here, we are sure that sbsz8 is 16 or 32,
    ; and therefore that col/row_start8 are at least 16-aligned. We can also
    ; guarantee that mfmv_sbsz8=16.
.ss2_xloop:
    movd                   xm10, xd
    vpbroadcastd            m10, xm10
    mov                     r6d, xd
    mov                     r7d, xd
    and                     r6d, ~31
    and                     r7d, 31
    lea                      r6, [r6*5]
    add                      r6, rpq
    pcmpgtd                 m13, m8, m10
    pcmpgtd                 m10, m9, m10            ; x+[0..30] < col_end8
    xor                      yd, yd

    ; deal with situation where we are unaligned or overhang
    ; in that case, do single-lane
    test                     xd, 31
    jnz .ss2_half
    lea                     r8d, [col_end8d-16]
    sub                     r8d, xd
    jle .ss2_half

.ss2_yloop:
    ; FIXME ideally, we can prevent this load by re-using the load from the
    ; previous loop iteration
    mova                     m0, [r6+mmsize*0+r7*4]
    mova                     m1, [r6+mmsize*2+r7*4]
    vpblendd                 m0, [r6+mmsize*1+r7*4-4], 10101010b
    vpblendd                 m1, [r6+mmsize*3+r7*4-4], 10101010b
    vpblendvb                m0, m6, m0, m13
    vpblendvb                m1, m6, m1, m10

    vpermd                   m2, m11, m0            ; right-shift-by-one
    vpermd                   m3, m11, m1
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if right_mv == invalid:
    vpblendvb                m1, m3, m5             ;     right_mv = cur_mv

    vpermd                   m2, m7, m0             ; right-shift-by-two
    vpermd                   m3, m7, m1
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if right2_mv == invalid:
    vpblendvb                m1, m3, m5             ;     right2_mv = cur_mv

    pshufd                   m2, m0, q2200          ; right-shift-by-four
    pshufd                   m3, m1, q2200
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if right4_mv == invalid:
    vpblendvb                m1, m3, m5             ;     right4_mv = cur_mv

    test                     yd, 15
    jz .skip_top_ss2
    mova                     m2, [r8+mmsize*0+r7*4]
    mova                     m3, [r8+mmsize*2+r7*4]
    vpblendd                 m2, [r8+mmsize*1+r7*4-4], 10101010b
    vpblendd                 m3, [r8+mmsize*3+r7*4-4], 10101010b
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    pcmpeqd                  m5, m3, m6
    vpblendvb                m2, m0, m4             ; if top_mv == invalid:
    vpblendvb                m3, m1, m5             ;     top_mv = cur_mv
    mova     [r8+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
    mova     [r8+mmsize*2+r7*4], m3                 ;     out_mv
    REPX          {psrlq x, 32}, m2, m3
    mova     [r8+mmsize*1+r7*4], m2
    mova     [r8+mmsize*3+r7*4], m3
.skip_top_ss2:
    mov                      r8, r6                 ; top pointer for next iter
    lea                      r6, [r6+strideq*2]
    add                      yd, 2
    test                     yd, 15
    jz .skip_bottom_ss2
    mova                     m2, [r6+mmsize*0+r7*4]
    mova                     m3, [r6+mmsize*2+r7*4]
    vpblendd                 m2, [r6+mmsize*1+r7*4-4], 10101010b
    vpblendd                 m3, [r6+mmsize*3+r7*4-4], 10101010b
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    pcmpeqd                  m5, m3, m6
    vpblendvb                m2, m0, m4             ; if bottom_mv == invalid:
    vpblendvb                m3, m1, m5             ;     bottom_mv = cur_mv
    mova     [r6+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
    mova     [r6+mmsize*2+r7*4], m3                 ;     out_mv
    REPX          {psrlq x, 32}, m2, m3
    mova     [r6+mmsize*1+r7*4], m2
    mova     [r6+mmsize*3+r7*4], m3
.skip_bottom_ss2:
    vpermd                   m2, m12, m0            ; left-shift-by-one-mv
    vpermd                   m3, m12, m1
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if left_mv == invalid:
    vpblendvb                m1, m3, m5             ;     left_mv = cur_mv
    ; it may be possible to prevent this store in some situations, since we
    ; will re-store it ("top") in the next iteration, unless we're crossing
    ; a mfmv_sbsz8 boundary
    mova     [r8+mmsize*0+r7*4], m0                 ; rp_proj_ptr->mv[pos] =
    mova     [r8+mmsize*2+r7*4], m1                 ;     out_mv
    REPX          {psrlq x, 32}, m0, m1
    mova     [r8+mmsize*1+r7*4], m0
    mova     [r8+mmsize*3+r7*4], m1
    cmp                      yd, h8d
    jl .ss2_yloop
    add                      xd, mmsize
    cmp                      xd, col_end8d
    jl .ss2_xloop
    RET

.ss2_half:
.ss2_yloop_half:
    ; FIXME ideally, we can prevent this load by re-using the load from the
    ; previous loop iteration
    mova                     m0, [r6+mmsize*0+r7*4]
    vpblendd                 m0, [r6+mmsize*1+r7*4-4], 10101010b
    vpblendvb                m0, m6, m0, m13

    vpermd                   m2, m11, m0            ; right-shift-by-one
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if right_mv == invalid:
                                                    ;     right_mv = cur_mv
    vpermd                   m2, m7, m0             ; right-shift-by-two
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if right2_mv == invalid:
                                                    ;     right2_mv = cur_mv
    pshufd                   m2, m0, q2200          ; right-shift-by-four
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if right4_mv == invalid:
                                                    ;     right4_mv = cur_mv
    test                     yd, 15
    jz .skip_top_ss2_half
    mova                     m2, [r8+mmsize*0+r7*4]
    vpblendd                 m2, [r8+mmsize*1+r7*4-4], 10101010b
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    vpblendvb                m2, m0, m4             ; if top_mv == invalid:
                                                    ;     top_mv = cur_mv
    mova     [r8+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
                                                    ;     out_mv
    psrlq                    m2, 32
    mova     [r8+mmsize*1+r7*4], m2
.skip_top_ss2_half:
    mov                      r8, r6                 ; top pointer for next iter
    lea                      r6, [r6+strideq*2]
    add                      yd, 2
    test                     yd, 15
    jz .skip_bottom_ss2_half
    mova                     m2, [r6+mmsize*0+r7*4]
    vpblendd                 m2, [r6+mmsize*1+r7*4-4], 10101010b
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    vpblendvb                m2, m0, m4             ; if bottom_mv == invalid:
                                                    ;     bottom_mv = cur_mv
    mova     [r6+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
                                                    ;     out_mv
    psrlq                    m2, 32
    mova     [r6+mmsize*1+r7*4], m2
.skip_bottom_ss2_half:
    vpermd                   m2, m12, m0            ; left-shift-by-one-mv
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if left_mv == invalid:
                                                    ;     left_mv = cur_mv
    ; it may be possible to prevent this store in some situations, since we
    ; will re-store it ("top") in the next iteration, unless we're crossing
    ; a mfmv_sbsz8 boundary
    mova     [r8+mmsize*0+r7*4], m0                 ; rp_proj_ptr->mv[pos] =
                                                    ;     out_mv
    psrlq                    m0, 32
    mova     [r8+mmsize*1+r7*4], m0
    cmp                      yd, h8d
    jl .ss2_yloop_half
    add                      xd, mmsize/2
    cmp                      xd, col_end8d
    jl .ss2_xloop
    RET

.sample_step_1:
    pmovzxbd                 m0, [pb_0to7]
    vpbroadcastd             m1, [pd_8]
    psubd                    m8, m0
    psubd                    m9, m8, m1
    pmovzxbd                m11, [pb_shr]
    pmovzxbd                m12, [pb_shl]
    ; col/row_start8 are 8-aligned. mfmv_sbsz8=8.
.ss1_xloop:
    movd                   xm10, xd
    vpbroadcastd            m10, xm10
    mov                     r6d, xd
    mov                     r7d, xd
    and                     r6d, ~31
    and                     r7d, 31
    lea                      r6, [r6*5]
    add                      r6, rpq
    pcmpgtd                 m13, m8, m10
    pcmpgtd                 m10, m9, m10            ; x+[0..15] < col_end8
    xor                      yd, yd

    ; deal with situation where we are unaligned or overhang
    ; in that case, do single-lane
    ; FIXME this could - instead of single-lane - do single instructions
    ; instead of pairs
    test                     xd, 15
    jnz .ss1_half
    lea                     r8d, [col_end8d-8]
    sub                     r8d, xd
    jle .ss1_half

.ss1_yloop:
    ; FIXME ideally, we can prevent this load by re-using the load from the
    ; previous loop iteration
    vpblendvb                m0, m6, [r6+mmsize*0+r7*4], m13
    vpblendvb                m1, m6, [r6+mmsize*1+r7*4], m10

    vpermd                   m2, m11, m0            ; right-shift-by-one
    vpermd                   m3, m11, m1
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if right_mv == invalid:
    vpblendvb                m1, m3, m5             ;     right_mv = cur_mv

    vpermq                   m2, m0, q2100          ; right-shift-by-two
    vpermq                   m3, m1, q2100
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if right2_mv == invalid:
    vpblendvb                m1, m3, m5             ;     right2_mv = cur_mv

    vinserti128              m2, m0, xm0, 1         ; right-shift-by-four
    vinserti128              m3, m1, xm1, 1
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if right4_mv == invalid:
    vpblendvb                m1, m3, m5             ;     right4_mv = cur_mv

    test                     yd, 7
    jz .skip_top_ss1
    mova                     m2, [r8+mmsize*0+r7*4]
    mova                     m3, [r8+mmsize*1+r7*4]
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    pcmpeqd                  m5, m3, m6
    vpblendvb                m2, m0, m4             ; if top_mv == invalid:
    vpblendvb                m3, m1, m5             ;     top_mv = cur_mv
    mova     [r8+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
    mova     [r8+mmsize*1+r7*4], m3                 ;     out_mv
.skip_top_ss1:
    mov                      r8, r6                 ; top pointer for next iter
    add                      r6, strideq
    inc                      yd
    test                     yd, 7
    jz .skip_bottom_ss1
    mova                     m2, [r6+mmsize*0+r7*4]
    mova                     m3, [r6+mmsize*1+r7*4]
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    pcmpeqd                  m5, m3, m6
    vpblendvb                m2, m0, m4             ; if bottom_mv == invalid:
    vpblendvb                m3, m1, m5             ;     bottom_mv = cur_mv
    mova     [r6+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
    mova     [r6+mmsize*1+r7*4], m3                 ;     out_mv
.skip_bottom_ss1:
    vpermd                   m2, m12, m0            ; left-shift-by-one-mv
    vpermd                   m3, m12, m1
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    pcmpeqd                  m5, m1, m6
    vpblendvb                m0, m2, m4             ; if left_mv == invalid:
    vpblendvb                m1, m3, m5             ;     left_mv = cur_mv
    ; it may be possible to prevent this store in some situations, since we
    ; will re-store it ("top") in the next iteration, unless we're crossing
    ; a mfmv_sbsz8 boundary
    mova     [r8+mmsize*0+r7*4], m0                 ; rp_proj_ptr->mv[pos] =
    mova     [r8+mmsize*1+r7*4], m1                 ;     out_mv
    cmp                      yd, h8d
    jl .ss1_yloop
    add                      xd, mmsize/2
    cmp                      xd, col_end8d
    jl .ss1_xloop
    RET
.ss1_half:
.ss1_yloop_half:
    ; FIXME ideally, we can prevent this load by re-using the load from the
    ; previous loop iteration
    vpblendvb                m0, m6, [r6+mmsize*0+r7*4], m13

    vpermd                   m2, m11, m0            ; right-shift-by-one
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if right_mv == invalid:
                                                    ;     right_mv = cur_mv
    vpermq                   m2, m0, q2100          ; right-shift-by-two
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if right2_mv == invalid:
                                                    ;     right2_mv = cur_mv
    vinserti128              m2, m0, xm0, 1         ; right-shift-by-four
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if right4_mv == invalid:
                                                    ;     right4_mv = cur_mv
    test                     yd, 7
    jz .skip_top_ss1_half
    mova                     m2, [r8+mmsize*0+r7*4]
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    vpblendvb                m2, m0, m4             ; if top_mv == invalid:
                                                    ;     top_mv = cur_mv
    mova     [r8+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
                                                    ;     out_mv
.skip_top_ss1_half:
    mov                      r8, r6                 ; top pointer for next iter
    add                      r6, strideq
    inc                      yd
    test                     yd, 7
    jz .skip_bottom_ss1_half
    mova                     m2, [r6+mmsize*0+r7*4]
    pcmpeqd                  m4, m2, m6             ; is mv invalid
    vpblendvb                m2, m0, m4             ; if bottom_mv == invalid:
                                                    ;     bottom_mv = cur_mv
    mova     [r6+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] =
                                                    ;     out_mv
.skip_bottom_ss1_half:
    vpermd                   m2, m12, m0            ; left-shift-by-one-mv
    pcmpeqd                  m4, m0, m6             ; is mv invalid
    vpblendvb                m0, m2, m4             ; if left_mv == invalid:
                                                    ;     left_mv = cur_mv
    ; it may be possible to prevent this store in some situations, since we
    ; will re-store it ("top") in the next iteration, unless we're crossing
    ; a mfmv_sbsz8 boundary
    mova     [r8+mmsize*0+r7*4], m0                 ; rp_proj_ptr->mv[pos] =
                                                    ;     out_mv
    cmp                      yd, h8d
    jl .ss1_yloop_half
    add                      xd, mmsize/4
    cmp                      xd, col_end8d
    jl .ss1_xloop
    RET

cglobal tip_smoothen, 4, 9, 16, rp, stride, col_start8, col_end8, \
                                h8, tmvp_sample_step
    pxor                     m6, m6
    pcmpeqd                 m15, m15
    vpbroadcastd             m7, [pd_32768]
    vbroadcasti128           m8, [pw_neg_idiv_plus_32768]
    vpbroadcastd             m9, [pw_mv_invalid]
    movifnidn               h8d, h8m
    lea                 strideq, [strideq*5]
    cmp dword tmvp_sample_stepm, 1
    je .sample_step_1
    DEFINE_ARGS rp, stride, x, col_end8, h8, y
    ; fall-through to .sample_step_2. Here, we are sure that sbsz8 is 16 or 32,
    ; and therefore that col/row_start8 are at least 16-aligned
    pmovzxbd                 m0, [pb_06012345]
    pmovzxbd                 m1, [pb_23456717]
.ss2_xloop:
    mov                     r6d, xd
    mov                     r7d, xd
    and                     r6d, ~31
    and                     r7d, 31
    lea                      r6, [r6*5]
    add                      r6, rpq
    movd                    xm3, xd
    movd                    xm4, col_end8d
    vpmovzxbd                m2, [pb_082a4c6e]
    vpbroadcastd             m3, xm3
    vpbroadcastd             m4, xm4
    paddd                    m3, m2
    pcmpgtd                 m13, m4, m3

    xor                      yd, yd
    mova                     m4, [r6+mmsize*0+r7*4]
    vpblendd                 m4, [r6+mmsize*1+r7*4-4], 10101010b
    vpblendvb                m4, m9, m4, m13        ; mv.x/y = rp_proj_ptr->mv[pos]
.ss2_yloop:
    vpermd                   m2, m0, m4
    vpermd                   m3, m1, m4
    vpblendd                 m2, m9, 00000001b
    vpblendd                 m3, m9, 10000000b
    pcmpeqd                 m10, m2, m9
    pcmpeqd                 m11, m3, m9
    pcmpeqd                 m12, m4, m9
    vpblendvb                m2, m6, m10
    vpblendvb                m3, m6, m11
    paddb                   m10, m11
    vpblendvb               m11, m4, m6, m12
    paddw                    m2, m3
    paddb                    m3, m10, m12           ; # invalid mvs in sum_mv
    paddw                    m2, m11                ; sum_x/y
    test                     yd, 15
    jz .skip_top_ss2
    psubb                    m3, m15
    pcmpeqd                 m10, m14, m9            ; is top_mv invalid
    vpblendvb               m14, m6, m10
    paddb                    m3, m10
    paddw                    m2, m14
.skip_top_ss2:
    add                      yd, 2
    mov                      r8, r6
    lea                      r6, [r6+strideq*2]
    cmp                      yd, h8d
    jge .skip_bottom_ss2
    mova                    m14, m4
    mova                     m4, [r6+mmsize*0+r7*4]
    vpblendd                 m4, [r6+mmsize*1+r7*4-4], 10101010b
    vpblendvb                m4, m9, m4, m13        ; mv.x/y = rp_proj_ptr->mv[pos]
    test                     yd, 15
    jz .skip_bottom_ss2
    psubb                    m3, m15
    pcmpeqd                 m10, m4, m9
    vpblendvb               m11, m4, m6, m10
    paddb                    m3, m10
    paddw                    m2, m11
.skip_bottom_ss2:
    vpbroadcastd            m12, [pb_6_7]
    paddb                    m3, m3
    paddb                    m3, m12, m3            ; sum_n -> pshufb indices
    vpbroadcastd            m12, [pw_m32768]
    pshufb                   m3, m8, m3
    pcmpeqd                  m5, m3, m15            ; sum_n == 0
    pabsw                   m11, m2
    punpcklwd               m10, m3, m12            ; interleave idiv[..] & -32768
    punpckhwd                m3, m12
    punpcklwd               m12, m11, m11           ; sum_x/y
    punpckhwd               m11, m11, m11
    pmaddwd                 m10, m12
    pmaddwd                 m11, m3
    REPX       {psubd x, m7, x}, m10, m11
    REPX          {psrad x, 16}, m10, m11
    packssdw                m10, m11
    psignw                   m2, m10, m2
    vpblendvb                m2, m9, m5             ; if sum_n == 0:
                                                    ;     out_mv.y = INVALID_MV
    mova     [r8+mmsize*0+r7*4], m2                 ; rp_proj_ptr->mv[pos] = mv_line
    psrlq                    m2, 32
    mova     [r8+mmsize*1+r7*4], m2
    cmp                      yd, h8d
    jl .ss2_yloop
    add                      xd, 16
    cmp                      xd, col_end8d
    jl .ss2_xloop
    RET
.sample_step_1:
    ; col/row_start8 are 8-aligned
    pmovzxbd                 m0, [pb_shr]
    pmovzxbd                 m1, [pb_shl]
.ss1_xloop:
    mov                     r6d, xd
    mov                     r7d, xd
    and                     r6d, ~31
    and                     r7d, 31
    lea                      r6, [r6*5]
    add                      r6, rpq
    movd                    xm3, xd
    movd                    xm4, col_end8d
    vpmovzxbd                m2, [pb_0to7]
    vpbroadcastd             m3, xm3
    vpbroadcastd             m4, xm4
    paddd                    m3, m2
    pcmpgtd                 m13, m4, m3

    xor                      yd, yd
    vpblendvb                m4, m9, [r6+r7*4], m13 ; mv.x/y = rp_proj_ptr->mv[pos]
.ss1_yloop:
    vpermd                   m2, m0, m4
    vpermd                   m3, m1, m4
    vpblendd                 m2, m9, 00000001b
    vpblendd                 m3, m9, 10000000b
    pcmpeqd                 m10, m2, m9
    pcmpeqd                 m11, m3, m9
    pcmpeqd                 m12, m4, m9
    vpblendvb                m2, m6, m10
    vpblendvb                m3, m6, m11
    paddb                   m10, m11
    vpblendvb               m11, m4, m6, m12
    paddw                    m2, m3
    paddb                    m3, m10, m12           ; # invalid mvs in sum_mv
    paddw                    m2, m11                ; sum_x/y
    test                     yd, 7
    jz .skip_top_ss1
    psubb                    m3, m15
    pcmpeqd                 m10, m14, m9            ; is top_mv invalid
    vpblendvb               m14, m6, m10
    paddb                    m3, m10
    paddw                    m2, m14
.skip_top_ss1:
    inc                      yd
    mov                      r8, r6
    add                      r6, strideq
    cmp                      yd, h8d
    je .skip_bottom_ss1
    mova                    m14, m4
    vpblendvb                m4, m9, [r6+r7*4], m13 ; mv.x/y = rp_proj_ptr->mv[pos]
    test                     yd, 7
    jz .skip_bottom_ss1
    psubb                    m3, m15
    pcmpeqd                 m10, m4, m9
    vpblendvb               m11, m4, m6, m10
    paddb                    m3, m10
    paddw                    m2, m11
.skip_bottom_ss1:
    vpbroadcastd            m12, [pb_6_7]
    paddb                    m3, m3
    paddb                    m3, m12, m3            ; sum_n -> pshufb indices
    vpbroadcastd            m12, [pw_m32768]
    pshufb                   m3, m8, m3
    pcmpeqd                  m5, m3, m15            ; sum_n == 0
    pabsw                   m11, m2
    punpcklwd               m10, m3, m12            ; interleave idiv[..] & -32768
    punpckhwd                m3, m12
    punpcklwd               m12, m11, m11           ; sum_x/y
    punpckhwd               m11, m11, m11
    pmaddwd                 m10, m12
    pmaddwd                 m11, m3
    REPX       {psubd x, m7, x}, m10, m11
    REPX          {psrad x, 16}, m10, m11
    packssdw                m10, m11
    psignw                   m2, m10, m2
    vpblendvb                m2, m9, m5             ; if sum_n == 0:
                                                    ;     out_mv.y = INVALID_MV
    mova              [r8+r7*4], m2                 ; rp_proj_ptr->mv[pos] = mv_line
    cmp                      yd, h8d
    jl .ss1_yloop
    add                      xd, 8
    cmp                      xd, col_end8d
    jl .ss1_xloop
    RET

INIT_YMM avx2
cglobal fill_gap_proj, 4, 12, 16, 4 * mmsize, \
                                  rp, stride, col_start8, col_end8, h8
    lea                      r8, [pd_div_mult]
    vpbroadcastd             m7, [pw_8]
    vpbroadcastd             m9, [pw_mv_invalid]
    vpbroadcastd            m10, [pw_m2047]
    movifnidn               h8d, h8m
    lea                 strideq, [strideq*5]
    DEFINE_ARGS rp, stride, x, col_end8, h8, y
.xloop:
    ; sample_step is always 2. Therefore, we are sure that sbsz8 is 16 or 32,
    ; and so col/row_start8 are at least 16-aligned
    movd                    xm8, xd
    movd                    xm6, col_end8d
    pmovzxbd                 m5, [pb_3b5d7f9x]
    pmovsxbd                 m4, [pb_7x0_m1]
    mov                     r6d, xd
    mov                     r7d, xd
    vpbroadcastd             m8, xm8
    vpbroadcastd             m6, xm6
    and                     r6d, ~31
    and                     r7d, 31
    paddd                    m8, m5
    lea                      r6, [r6*5]
    pcmpgtd                  m8, m6
    add                      r6, rpq
    por                      m8, m4

    xor                      yd, yd
    call m(tip_projection).load_row_ss2
    pmaddwd                  m0, m2
    pmaddwd                  m1, m3
    pmovzxbd                 m6, [pb_23456717]
    vpermq                   m2, m0, q0132
    pcmpeqd                 m14, m4, m9             ; is mv invalid
    vpermd                   m6, m14
    por                      m6, m8
.yloop:
    mova         [rsp+0*mmsize], m14
    vbroadcasti128           m5, [r6+32*4+r7]
    pshufb                  m12, m5, [msk_A]
    pshufb                  m13, m5, [msk_B]
    pshufb                  xm5, [msk_C]

    ; top/right projection
    pmulld                   m0, m1, m12            ; mv.x/y * div_mult[den] * num
    pmulld                   m3, m2, m13
    mova           [r6+32*4+r7], xm5                ; rp_proj_ptr->ref[pos] = ..
    psrad                    m1, 31
    psrad                    m2, 31
    paddd                    m1, m0
    paddd                    m2, m3
    REPX          {psrad x, 10}, m1, m2
    packssdw                 m1, m2
    paddsw                   m1, m7
    psraw                    m1, 4
    pmaxsw                   m1, m10                ; tmv2_projection(top/right)

    ; average top/left & top/right projection into top/right output
    ; if left_mv == invalid: center_mv = invalid
    ; else if right_mv == invalid: center_mv = left_mv
    ; else: center_mv = signed_average(left_mv, right_mv)
    vpblendvb                m0, m1, m4, m6
    vpblendvb                m0, m9, m14
    paddw                    m0, m4
    psraw                    m2, m0, 15
    pavgw                    m0, m2

    ; write out interleaved version of top/left & top/right
    pslldq                  m14, m0, 4
    psrldq                  m15, m4, 4
    vpblendd                m14, m4, m14, 10101010b
    vpblendd                m15, m0, 10101010b
    mova         [r6+32*0+r7*4], m14
    mova         [r6+32*1+r7*4], m15

    add                      yd, 2
    cmp                      yd, h8d
    jg .ybreak
    lea                     r10, [r6+strideq]
    mova          [r10+32*4+r7], xm5                ; rp_proj_ptr->ref[pos] = ..
    je .skip_bottom

    ; bottom & bottom/right pixels
    lea                      r6, [r6+strideq*2]
    mova         [rsp+3*mmsize], m4
    pandn                    m1, m6, m1             ; zero invalid mvs
    paddw                    m5, m1, m4             ; sum_x/y = center + right
    call m(tip_projection).load_row_ss2
    pmaddwd                  m0, m2
    pmaddwd                  m1, m3
    pmovzxbd                 m2, [pb_23456717]
    pcmpeqd                  m3, m4, m9             ; is mv invalid
    vpermd                   m2, m3
    por                     m11, m2, m8
    vpermq                   m2, m0, q0132
    mova         [rsp+1*mmsize], m1
    mova         [rsp+2*mmsize], m2
    test                     yd, 15
    jz .skip_bottom
    mova                    m15, [rsp+3*mmsize]

    ; bottom/left projection
    pmulld                  m14, m0, m12
    pmulld                   m2, m1, m13
    psrad                    m0, 31
    psrad                    m1, 31
    paddd                    m0, m14
    paddd                    m1, m2
    REPX          {psrad x, 10}, m0, m1
    packssdw                 m0, m1
    paddsw                   m0, m7
    psraw                    m0, 4
    pmaxsw                   m0, m10                ; tmv2_projection(bottom/left)

    ; average top/left & bottom/left projection into bottom/left output
    mova                    m14, [rsp+0*mmsize]
    vpblendvb                m1, m0, m15, m3
    vpblendvb                m1, m9, m14
    paddw                   m15, m1
    psraw                    m1, m15, 15
    pavgw                   m15, m1

    ; add bottom/left projection to bottom/right aggregator
    pandn                    m0, m3, m0             ; zero invalid mvs
    paddw                    m5, m0                 ; sum_x/y
    paddb                    m6, m3
    vpbroadcastd             m0, [pb_2]
    paddb                    m6, m0

    ; bottom/right projection
    mova                     m0, [rsp+1*mmsize]
    mova                     m1, [rsp+2*mmsize]
    pmulld                  m12, m0
    pmulld                  m13, m1
    psrad                    m0, 31
    psrad                    m1, 31
    paddd                    m0, m12
    paddd                    m1, m13
    REPX          {psrad x, 10}, m0, m1
    packssdw                 m0, m1
    paddsw                   m0, m7
    psraw                    m0, 4
    pmaxsw                   m0, m10                ; tmv2_projection(bottom/right)

    ; add bottom/right projection to bottom/right aggregator
    pandn                    m0, m11, m0            ; zero invalid mvs
    paddw                    m5, m0                 ; sum_x/y
    paddb                    m6, m11

    ; generate bottom/right output mv
    paddw                    m5, m5
    vpbroadcastd             m0, [pb_2_3]
    vpbroadcastq             m2, [pw_div]
    paddb                    m6, m6
    paddb                    m6, m0, m6
    pabsw                    m0, m5
    pshufb                   m6, m2, m6
    pmulhrsw                 m0, m6
    psignw                   m0, m5

    ; if top/left mv is invalid: output bottom/right mv = invalid
    vpblendvb                m0, m9, m14

    ; interleave bottom/left & bottom/right output mv & write-out
    pslldq                  m14, m0, 4
    psrldq                   m1, m15, 4
    vpblendd                m14, m15, m14, 10101010b
    vpblendd                m15, m1, m0, 10101010b
.skip_bottom:
    mova        [r10+32*0+r7*4], m14
    mova        [r10+32*1+r7*4], m15
    mova                    m14, m3
    mova                     m6, m11
    mova                     m1, [rsp+1*mmsize]
    mova                     m2, [rsp+2*mmsize]
    cmp                      yd, h8d
    jl .yloop
.ybreak:
    add                      xd, 16
    cmp                      xd, col_end8d
    jl .xloop
    RET
