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

pw_div_mult: dw    0, 1024, 16384, 963, 8192, 910, 5461, 862
             dw 4096,  819,  3276, 780, 2730, 744, 2340, 712
             dw 2048,  682,  1820, 655, 1638, 630, 1489, 606
             dw 1365,  585,  1260, 564, 1170, 546, 1092, 528

pw_mv_invalid: dw 0x2000, 0
pw_8: times 2 dw 8
pw_m2047: times 2 dw -2047

SECTION .text

%define m(x) mangle(private_prefix %+ _ %+ x %+ SUFFIX)

INIT_YMM avx2
cglobal tip_projection, 4, 10, 10, 32 * 4, rp, stride, col_start8, col_end8, \
                                           h8, tmvp_sample_step, tip_delta
    mova                     m2, [pw_div_mult+0*32]
    mova                     m3, [pw_div_mult+1*32]
    vpbroadcastd             m6, tip_deltam
    pmaddwd                  m0, m2, m6
    pmaddwd                  m1, m3, m6
    vpbroadcastb            xm8, xm6
    pslld                    m6, 16
    REPX        {pmaddwd x, m6}, m2, m3
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
    RET
.load_row_ss2:
    ; why no gatherdq? because it's 3x as slow :(
    mova                     m4, [r6+32*0+r7*4]     ; mv.x/y = rp_proj_ptr->mv[pos]
    vpblendd                 m4, [r6+32*1+r7*4-4], 10101010b
    movzx                   r8d, byte [r6+32*4+r7+0]
    movzx                   r9d, byte [r6+32*4+r7+2]
    vpbroadcastd            xm0, [rsp+gprsize+r8*4]
    vpbroadcastd            xm1, [rsp+gprsize+r9*4]
    movzx                   r8d, byte [r6+32*4+r7+8]
    movzx                   r9d, byte [r6+32*4+r7+10]
    vpbroadcastd            xm2, [rsp+gprsize+r8*4]
    vpbroadcastd            xm3, [rsp+gprsize+r9*4]
    vpblendd                xm0, xm2, 1100b
    vpblendd                xm1, xm3, 1100b
    movzx                   r8d, byte [r6+32*4+r7+4]
    movzx                   r9d, byte [r6+32*4+r7+6]
    vpbroadcastd             m2, [rsp+gprsize+r8*4]
    vpbroadcastd             m3, [rsp+gprsize+r9*4]
    vpblendd                 m0, m2, 110000b
    vpblendd                 m1, m3, 110000b
    movzx                   r8d, byte [r6+32*4+r7+12]
    movzx                   r9d, byte [r6+32*4+r7+14]
    vpbroadcastd             m2, [rsp+gprsize+r8*4]
    vpbroadcastd             m3, [rsp+gprsize+r9*4]
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
