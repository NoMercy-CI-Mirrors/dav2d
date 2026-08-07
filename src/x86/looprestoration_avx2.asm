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
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHr4wT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%include "config.asm"
%include "ext/x86/x86inc.asm"

SECTION_RODATA 32

gdf_llm_mul:   dw   128, 32768,    64, 16384,    32,  8192,    16,  4096
               dw     8,  2048,     4,  1024,     2,   512,     1,   256
pw_m511:       times 2 dw -511
gdf_err_inter: dw     5,     5,    10,    10,   675,   675
pw_512:        times 2 dw 512
gdf_err_intra: dw     8,     8,    16,    16,  2304,  2304
pw_4096:       times 2 dw 4096
pw_0x7000:     times 2 dw 0x7000

SECTION .text

%macro GDF_SWAP_PAIR 6 ; a0d, b0d/a0s, a1d/b0s, b1d/a1s, b1s, ~cond
    vpblendvb         %1, %3, %2, %6 ; cond ? b0 : a0
    vpblendvb         %2, %3, %6     ; cond ? a0 : b0
    vpblendvb         %3, %5, %4, %6 ; cond ? b1 : a1
    vpblendvb         %4, %5, %6     ; cond ? a1 : b1
%endmacro

%macro GDF_SUM 6 ; sum_a/a0, sum_b/b0, a1, b1, tmp, alpha
    vpbroadcastd      %5, [rsp+gprsize+GdfStk.alpha%6+0]
    pminsw            %1, %5
    pminsw            %3, %5
    vpbroadcastd      %5, [rsp+gprsize+GdfStk.alpha%6+4]
    pminsw            %2, %5
    pminsw            %4, %5
    vpbroadcastd      %5, [rsp+gprsize+GdfStk.alpha%6m+0]
    pmaxsw            %1, %5
    pmaxsw            %3, %5
    vpbroadcastd      %5, [rsp+gprsize+GdfStk.alpha%6m+4]
    pmaxsw            %2, %5
    pmaxsw            %4, %5
    paddw             %1, %3  ; -a
    paddw             %2, %4  ; -b
    pminsw            %1, m14
    pminsw            %2, m14
    pmaxsw            %1, m15 ; iclip(-a, -511, 512)
    pmaxsw            %2, m15 ; iclip(-b, -511, 512)
%endmacro

%macro GDF_SUM_PART1 1 ; y
    ; { 1, 2 }, { 1, -2 }, { 2, 1 }, { 2, -1 }
    mova             m11,      [GDF_PX(%1+0, 0)] ; m
    psubw             m4, m11, [GDF_PX(%1-2,-1)] ; ttl
    psubw             m6, m11, [GDF_PX(%1-1,-2)] ; tll
    psubw             m9, m11, [GDF_PX(%1+2, 1)] ; bbr
    psubw             m5, m11, [GDF_PX(%1+1, 2)] ; brr
    GDF_SWAP_PAIR     m2, m4, m6, m9, m5, m12    ; ttl, tll, bbr, brr
    psubw             m8, m11, [GDF_PX(%1-2, 1)] ; ttr
    psubw             m3, m11, [GDF_PX(%1-1, 2)] ; trr
    psubw             m0, m11, [GDF_PX(%1+2,-1)] ; bbl
    psubw             m1, m11, [GDF_PX(%1+1,-2)] ; bll
    GDF_SWAP_PAIR     m5, m8, m3, m0, m1, m12    ; ttr, trr, bbl, bll
    GDF_SWAP_PAIR     m1, m2, m5, m6, m3, m13    ; ttl, ttr, bbr, bbl
    GDF_SUM           m1, m2, m5, m6, m3, 7      ; sum_ddr, sum_ddl
    GDF_SWAP_PAIR     m3, m4, m8, m9, m0, m13    ; tll, trr, brr, bll
    GDF_SUM           m3, m4, m8, m9, m0, 8      ; sum_drr, sum_dll
    vpbroadcastd      m8, [paramsq+GdfParams.weight4+0]
    vpbroadcastd      m9, [paramsq+GdfParams.weight4+4]
    vpbroadcastd      m5, [rsp+gprsize+GdfStk.bias+4*0]
    vpbroadcastd      m6, [rsp+gprsize+GdfStk.bias+4*1]
    punpcklwd         m0, m1, m2
    punpckhwd         m1, m2
    pmaddwd           m0, m8
    pmaddwd           m1, m8
    punpcklwd         m2, m3, m4
    punpckhwd         m3, m4
    pmaddwd           m2, m9
    pmaddwd           m3, m9
    psubd             m8, m5, m0 ; idx_vals0 += sum_ddr * weight4[0][0] +
    psubd             m5, m1     ;              sum_ddl * weight4[0][1]
    psubd             m9, m6, m2 ; idx_vals1 += sum_drr * weight4[1][0] +
    psubd             m6, m3     ;              sum_dll * weight4[1][1]
    ; { 1, 1 }, { 1, -1 }
    psubw             m0, m11, [GDF_PX(%1-1,-1)] ; tl
    psubw             m1, m11, [GDF_PX(%1-1, 1)] ; tr
    psubw             m2, m11, [GDF_PX(%1+1, 1)] ; br
    psubw             m4, m11, [GDF_PX(%1+1,-1)] ; bl
    GDF_SWAP_PAIR     m3, m0, m1, m2, m4, m13    ; tl, tr, br, bl
    GDF_SUM           m3, m0, m1, m2, m4, 6      ; sum_dr, sum_dl
    vpbroadcastd      m1, [paramsq+GdfParams.weight3+0]
    vpbroadcastd      m4, [paramsq+GdfParams.weight3+4]
    punpcklwd         m2, m3, m0
    punpckhwd         m3, m0
    pmaddwd           m0, m1, m2
    pmaddwd           m1, m3
    pmaddwd           m2, m4
    pmaddwd           m3, m4
    psubd             m8, m0     ; idx_vals0 += sum_dr * weight3[0][0] +
    psubd             m5, m1     ;              sum_dl * weight3[0][1]
    psubd             m9, m2     ; idx_vals1 += sum_dr * weight3[1][0] +
    psubd             m6, m3     ;              sum_dl * weight3[1][1]
%endmacro

%macro GDF_SUM_PART2 2 ; y, tmp
    ; { 5, 0 }, { 0, 5 }, { 6, 0 }, { 0, 6 }
    psubw             m3, m11, [GDF_PX(%1-5, 0)] ; a5
    psubw             m2, m11, [GDF_PX(%1+0,-5)] ; l5
    psubw             m4, m11, [GDF_PX(%1+5, 0)] ; b5
    psubw             m0, m11, [GDF_PX(%1+0, 5)] ; r5
    GDF_SWAP_PAIR     m1, m3, m2, m4, m0, m12    ; a5, l5, b5, r5
    GDF_SUM           m1, m3, m2, m4, m0, 4      ; sum_v5, sum_h5
    psubw             m4, m11, [GDF_PX(%1-6, 0)] ; a6
    psubw             m7, m11, [GDF_PX(%1+0,-6)] ; l6
    psubw             %2, m11, [GDF_PX(%1+6, 0)] ; b6
    psubw             m0, m11, [GDF_PX(%1+0, 6)] ; r6
    GDF_SWAP_PAIR     m2, m4, m7, %2, m0, m12   ; a6, l6, b6, r6
    GDF_SUM           m2, m4, m7, %2, m0, 5     ; sum_v6, sum_h6
    vpbroadcastd      m7, [paramsq+GdfParams.weight2+4*1]
    vpbroadcastd      %2, [paramsq+GdfParams.weight2+4*3]
    punpcklwd         m0, m1, m2
    punpckhwd         m1, m2
    punpcklwd         m2, m3, m4
    punpckhwd         m3, m4
    pmaddwd           m0, m7
    pmaddwd           m1, m7
    pmaddwd           m2, %2
    pmaddwd           m3, %2
    psubd             m8, m0     ; idx_vals0 += sum_v5 * weight2[0][2] +
    psubd             m5, m1     ;              sum_v6 * weight2[0][3]
    psubd             m9, m2     ; idx_vals1 += sum_h5 * weight2[1][2] +
    psubd             m6, m3     ;              sum_h6 * weight2[1][3]
%endmacro

%macro GDF_SUM_PART3 2 ; y, tmp
    ; { 3, 0 }, { 0, 3 }, { 4, 0 }, { 0, 4 }
    psubw             m4, m11, [GDF_PX(%1-3, 0)] ; a3
    psubw             m0, m11, [GDF_PX(%1+0,-3)] ; l3
    psubw             m1, m11, [GDF_PX(%1+3, 0)] ; b3
    psubw             m2, m11, [GDF_PX(%1+0, 3)] ; r3
    GDF_SWAP_PAIR     %2, m4, m0, m1, m2, m12  ; a3, l3, b3, r3
    GDF_SUM           %2, m4, m0, m1, m2, 2    ; sum_v3, sum_h3
%if %1 ; last idx_vals2 sum, accumulate + pack early to free up m7
    vpbroadcastd      m2, [paramsq+GdfParams.weight1+4*6]
    punpcklwd         m0, %2, m4
    punpckhwd         m1, %2, m4
    pmaddwd           m0, m2
    pmaddwd           m1, m2
    psubd            m10, m0     ; idx_vals2 += sum_v3 * weight1[6][0] +
    psubd             m7, m1     ;              sum_h3 * weight1[6][1]
    packssdw         m10, m7
%endif
    psubw             m1, m11, [GDF_PX(%1-4, 0)] ; a4
    psubw             m0, m11, [GDF_PX(%1+0,-4)] ; l4
    psubw             m7, m11, [GDF_PX(%1+4, 0)] ; b4
    psubw             m2, m11, [GDF_PX(%1+0, 4)] ; r4
    GDF_SWAP_PAIR     m3, m1, m0, m7, m2, m12 ; a4, l4, b4, r4
    GDF_SUM           m3, m1, m0, m7, m2, 3   ; sum_v4, sum_h4
    vpbroadcastd      m0, [paramsq+GdfParams.weight2+4*0]
    vpbroadcastd      m7, [paramsq+GdfParams.weight2+4*2]
    punpcklwd         m2, %2, m3
    punpckhwd         m3, %2, m3
    pmaddwd           m2, m0
    pmaddwd           m3, m0
    punpcklwd         m0, m4, m1
    punpckhwd         m1, m4, m1
    pmaddwd           m0, m7
    pmaddwd           m1, m7
    psubd             m8, m2     ; idx_vals0 += sum_v3 * weight2[0][0] +
    psubd             m5, m3     ;              sum_v4 * weight2[0][1]
%if %1 == 0 ; first idx_vals2 sum, bias added at the end
    vpbroadcastd      m7, [paramsq+GdfParams.weight1+4*6]
    punpcklwd         m3, %2, m4
    punpckhwd         m4, %2, m4
    pmaddwd           m3, m7
    pmaddwd           m4, m7
%endif
    psubd             m9, m0     ; idx_vals1 += sum_h3 * weight2[1][0] +
    psubd             m6, m1     ;              sum_h4 * weight2[1][1]
%endmacro

%macro GDF_SUM_PART4 4 ; y, k, tmp[1-2]
    ; { k, 0 }, { 0, k }
    %assign %%i %2 - 1
    psubw             m2, m11, [GDF_PX(%1-%2,  0)] ; above
    psubw             %3, m11, [GDF_PX(%1+ 0,-%2)] ; left
    psubw             %4, m11, [GDF_PX(%1+%2,  0)] ; below
    psubw             m0, m11, [GDF_PX(%1+ 0, %2)] ; right
    GDF_SWAP_PAIR     m1, m2, %3, %4, m0, m12      ; a, l, b, r
    GDF_SUM           m1, m2, %3, %4, m0, %%i      ; sum_v, sum_h
    vpbroadcastd      %3, [paramsq+GdfParams.weight1+4*(3*%%i+0)]
    vpbroadcastd      %4, [paramsq+GdfParams.weight1+4*(3*%%i+1)]
    punpcklwd         m0, m1, m2
    punpckhwd         m1, m2
    pmaddwd           m2, %3, m0
    pmaddwd           %3, m1
    psubd             m8, m2     ; idx_vals0 += sum_v * weight1[0][0] +
    psubd             m5, %3     ;              sum_h * weight1[0][1]
    vpbroadcastd      %3, [paramsq+GdfParams.weight1+4*(3*%%i+2)]
    pmaddwd           m2, %4, m0
    pmaddwd           %4, m1
    pmaddwd           m0, %3
    pmaddwd           m1, %3
    psubd             m9, m2     ; idx_vals1 += sum_v * weight1[1][0] +
    psubd             m6, %4     ;              sum_h * weight1[1][1]
%if %1
    psubd            m10, m0     ; idx_vals2 += sum_v * weight1[2][0] +
    psubd             m7, m1     ;              sum_h * weight1[2][1]
%else
    paddd             m3, m0
    paddd             m4, m1
%endif
%endmacro

%macro GDF_FINALIZE 3 ; y, idx_val2[1-2]
    vpbroadcastd      m0, [rsp+gprsize+GdfStk.err_scale]
    vpbroadcastd      m1, [pw_0x7000]
    vpbroadcastd      m2, [rsp+gprsize+GdfStk.err_mul]
    packssdw          m8, m5  ; idx_val0
    packssdw          m9, m6  ; idx_val1
    psignw            m5, m0, m8
    pminsw            m8, m1  ; equivalent to clip(v, -scale, scale - 1)
    pmulhrsw          m5, m8  ; (abs(v) * scale + (1 << 14)) >> 15
%if %1 == 0 ; for y1 this was done in GDF_SUM_PART3
    mova              m7, [rsp+gprsize+GdfStk.bias2]
    punpckldq        m10, m7, m7
    punpckhdq         m7, m7
    psubd             %2, m10, %2
    psubd             %3, m7, %3
    packssdw          %2, %3  ; idx_val2
%endif
    psignw            m6, m0, m9
    pminsw            m9, m1
    psignw            m8, m2, m8
    pmulhrsw          m6, m9
    psignw            m0, %2
    pminsw            %2, m1
    pmullw            m5, m8  ; sub_idx0 * scale * 2
    pmulhrsw          m0, %2
    vpbroadcastd      m1, [rsp+gprsize+GdfStk.err_offset]
    psignw            m6, m9  ; sub_idx1
    paddw             m5, m6
    psignw            m0, %2  ; sub_idx2
    pmullw            m5, m2  ; (sub_idx0 * scale * 2 + sub_idx1) * scale * 2
    paddw             m0, m1  ; sub_idx2 + ((scale * scale * 2) + scale) * scale * 2 + scale
    paddw             m0, m5  ; full_idx + offsetof(Dav2dGdfParams, error_lut)
    vextracti128     xm1, m0, 1
%assign %%i 64*%1
%rep 4 ; perform gathering of error values using GPRs
%define %%r (%%i & 8) ? xm1 : xm0
%if %%i & 4
    pextrq           r10, %%r, 1
%else
    movq             r10, %%r
%endif
    movzx            r2d, r10w
    movzx            r2d, byte [paramsq+r2]
    mov  [dstq+wq+%%i+0], r2b
    rorx              r2, r10, 32
    shr             r10d, 16
    movzx           r10d, byte [paramsq+r10]
    mov  [dstq+wq+%%i+1], r10b
    movzx           r10d, r2w
    shr              r2d, 16
    movzx           r10d, byte [paramsq+r10]
    movzx            r2d, byte [paramsq+r2]
    mov  [dstq+wq+%%i+2], r10b
    mov  [dstq+wq+%%i+3], r2b
    %assign %%i %%i + 4
%endrep
%endmacro

struc GdfParams
    .scale:       resw 1
    .bias:        resw 3
    .grad_alpha:  resw 4
    .grad_weight: resw 4
    .alpha:       resw 9*2
    .weight1:     resw 7*2
    .weight2:     resw 2*4
    .weight3:     resw 2*2
    .weight4:     resw 2*2
endstruc

struc GdfStk ; 3536 bytes
    .grad0:      resq 1
    .grad1:      resq 1
    .alpha0:     resd 2
    .alpha1:     resd 2
    .alpha4:     resd 2
    .alpha5:     resd 2
    .alpha2:     resd 2
    .alpha3:     resd 2
    .alpha6:     resd 2
    .alpha7:     resd 2
    .alpha0m:    resd 2
    .alpha1m:    resd 2
    .alpha4m:    resd 2
    .alpha5m:    resd 2
    .alpha2m:    resd 2
    .alpha3m:    resd 2
    .alpha6m:    resd 2
    .alpha7m:    resd 2
    .unused:     resd 1
    .err_scale:  resd 1
    .err_mul:    resd 1
    .err_offset: resd 1
    .w:          resd 1
    .bias:       resd 3
    .grad_buf0:  resw 64*4+8
    .bottom:     resq 1
    .stride:     resq 1
    .grad_buf1:  resw 64*4+8
    .row_buf:    resw (8+64+8)*14
    .alpha8:     resd 2
    .alpha8m:    resd 2
    .bias2:      resw 16
endstruc

%assign GRAD_STRIDE GdfStk.grad_buf1 - GdfStk.grad_buf0
%define TREG(=n) t %+ n
%define GDF_PX(y, x) (TREG(((y) + 6) >> 1) + wq*2 + 160 * ((y) & 1) + 2 * (x) - 112)

DECLARE_REG_TMP 11, 12, 4, 5, 13, 14, 8

INIT_YMM avx2
cglobal gdf_prep_8bpc, 7, 15, 16, 0-GdfStk_size, dst, p, stride, left, top, bottom, params, w, h, edge
    mov               wd, wm
    mov               hd, hm
    mov            edged, edgem
    movzx           r10d, byte [paramsq+GdfParams.scale]
    lea              r11, [pw_m511]
    and             r10d, 8
    movu              m1, [paramsq+GdfParams.alpha]
    movd             xm2, [paramsq+GdfParams.alpha+32]
    pmovsxwd         xm3, [paramsq+GdfParams.scale]
    mova             xm4, [r11+r10*2]
    vpbroadcastd     m15, [r11]
    vpbroadcastd     m14, [r11-pw_m511+pw_512]
    punpcklwd         m0, m1, m1 ; pre-unpack and negate alpha to enable replacing
    punpckhwd         m1, m1     ; vpbroadcastw + psignw with 2x vpbroadcastd
    punpcklwd        xm2, xm2    ; which is faster, especially on Intel CPUs.
    mova [rsp+GdfStk.alpha0], m0
    mova [rsp+GdfStk.alpha2], m1
    movq [rsp+GdfStk.alpha8], xm2
    mova [rsp+GdfStk.bias     -4], xm3
    mova [rsp+GdfStk.err_scale-4], xm4
    pxor             xm3, xm3
    psubw             m0, m3, m0
    psubw             m1, m3, m1
    psubw            xm2, xm3, xm2
    mova [rsp+GdfStk.alpha0m], m0
    mova [rsp+GdfStk.alpha2m], m1
    movq [rsp+GdfStk.alpha8m], xm2
    shl               hd, 6
    lea            edged, [edgeq+hq-(8<<6)] ; combine h and edge to free up a register
    lea               t6, [rsp+wq*2+GdfStk.row_buf+128] ; +128 reduces disp32 encodings
    lea              r10, [rsp+wq*2+GdfStk.grad_buf0]
    add             dstq, wq
    neg               wq
    mov [rsp+GdfStk.bottom], bottomq
    mov [rsp+GdfStk.stride], strideq
    mov [rsp+GdfStk.grad0 ], r10
    add                 r10, GRAD_STRIDE
    mov [rsp+GdfStk.w     ], wd
    mov [rsp+GdfStk.grad1 ], r10
    call .load_p
    call .load_p_lr
    lea               t5, [pq+strideq*2]
    mov               t4, t6
.top:
    test           edgeb, 0x14 ; LR_HAVE_TOP | LR_HAVE_TOP_INTEGRATED
    jz .no_top
    mov               pq, topq
    add               t6, 160*2
    call .load_p
    test           edgeb, 0x10 ; LR_HAVE_TOP_INTEGRATED
    jz .no_top_integrated
    lea               pq, [pq+strideq*2]
    mov               t0, t6
    add               t6, 160*2
    call .load_p
    lea               pq, [pq+strideq*2]
    mov               t1, t6
    add               t6, 160*2
    call .load_p
    call .load_tb_lr
    jmp .top_done
.no_top:
    lea               t0, [t6+160*10]
    lea               t1, [t6+160*12]
    call .extend_top
    add               t6, 160*2
    call .extend_tb
    mova             xm0, [GDF_PX( 2,-8)]
    mova             xm1, [GDF_PX( 2,64)]
    mova [GDF_PX( 6,-8)], xm0
    mova [GDF_PX( 7,-8)], xm0
    mova [GDF_PX( 6,64)], xm1
    mova [GDF_PX( 7,64)], xm1
    jmp .top_done
.no_top_integrated:
    call .load_tb_lr
    lea               t0, [t6+160* 8]
    lea               t1, [t6+160*10]
    call .extend_top
.top_done:
    mov               pq, t5
    mov               t3, t6
    add               t6, 160*2
    call .load_p
    call .load_p_lr
    lea               pq, [pq+strideq*2]
    call .calc_grad
    mov               t2, t3
    mov               t3, t4
    mov               t4, t6
    add               t6, 160*2
    call .load_p
    call .load_p_lr
    lea               pq, [pq+strideq*2]
    mov               t5, t6
    add               t6, 160*2
.main_loop:
    mov              r10, [rsp+GdfStk.grad0]
    test           edgeb, edgeb
    cmovs            r10, [rsp+GdfStk.grad1] ; y & 2 ? grad1 : grad0
    call .calc_grad
    call .load_p
    call .load_p_lr
    lea               pq, [pq+strideq*2]
    call .main
    sub            edged, 2<<6
    jge .main_loop
.bottom:
    mov              r10, [rsp+GdfStk.grad1]
    call .calc_grad
    test           edgeb, 0x20; LR_HAVE_BOTTOM_INTEGRATED
    jz .no_bottom_integrated
    call .load_p
    call .load_tb_lr
    lea               pq, [pq+strideq*2]
    call .main
    mov              r10, [rsp+GdfStk.grad0]
    call .calc_grad
    call .load_p
    lea               pq, [pq+strideq*2]
    call .main
    mov              r10, [rsp+GdfStk.grad1]
    call .calc_grad
    call .load_p
    jmp .end2
.no_bottom_integrated:
    test           edgeb, 0x08; LR_HAVE_BOTTOM
    jz .no_bottom
    mov               pq, [rsp+GdfStk.bottom]
    call .load_p
    call .load_tb_lr
    call .main
    mov              r10, [rsp+GdfStk.grad0]
    call .calc_grad
    call .extend_bottom
    jmp .end
.no_bottom:
    call .extend_bottom
    mova             xm0, [GDF_PX( 5,-8)]
    mova             xm1, [GDF_PX( 5,64)]
    mova [GDF_PX( 6,-8)], xm0
    mova [GDF_PX( 7,-8)], xm0
    mova [GDF_PX( 6,64)], xm1
    mova [GDF_PX( 7,64)], xm1
    call .main
    mov              r10, [rsp+GdfStk.grad0]
    call .calc_grad
    mov               t6, t5
.end:
    call .main
    mov              r10, [rsp+GdfStk.grad1]
    call .calc_grad
    mov               t6, t5
.end2:
    call .main
    RET
.load_p:
    pmovzxbw          m0, [pq+strideq*0+16*0]
    pmovzxbw          m1, [pq+strideq*1+16*0]
    pmovzxbw          m2, [pq+strideq*0+16*1]
    pmovzxbw          m3, [pq+strideq*1+16*1]
    pmovzxbw          m4, [pq+strideq*0+16*2]
    pmovzxbw          m5, [pq+strideq*1+16*2]
    pmovzxbw          m6, [pq+strideq*0+16*3]
    pmovzxbw          m7, [pq+strideq*1+16*3]
    REPX    {psllw x, 2}, m0, m1, m2, m3, m4, m5, m6, m7
    mova [GDF_PX( 6, 0)], m0
    mova [GDF_PX( 7, 0)], m1
    mova [GDF_PX( 6,16)], m2
    mova [GDF_PX( 7,16)], m3
    mova [GDF_PX( 6,32)], m4
    mova [GDF_PX( 7,32)], m5
    mova [GDF_PX( 6,48)], m6
    mova [GDF_PX( 7,48)], m7
    ret
.load_tb_lr:
    test           edgeb, 0x01 ; LR_HAVE_LEFT
    jz .load_p_lr_no_left
    movq             xm0, [pq+strideq*0-8]
    movhps           xm0, [pq+strideq*1-8]
    pmovzxbw          m0, xm0
    psllw             m0, 2
    vextracti128 [GDF_PX( 7,-8)], m0, 1
    jmp .load_p_lr_right
.load_p_lr:
    test           edgeb, 0x01 ; LR_HAVE_LEFT
    jz .load_p_lr_no_left
    pmovzxbw          m0, [leftq]
    add            leftq, 16
    psllw             m0, 2
    vextracti128 [GDF_PX( 7,-8)], m0, 1
    jmp .load_p_lr_right
.load_p_lr_no_left:
    vpbroadcastw     xm0, xm0
    vpbroadcastw     xm1, xm1
    mova [GDF_PX( 7,-8)], xm1
.load_p_lr_right:
    mova [GDF_PX( 6,-8)], xm0
    test           edgeb, 0x02 ; LR_HAVE_RIGHT
    jz .load_p_lr_no_right
    movq             xm0, [pq+strideq*0+64]
    movhps           xm0, [pq+strideq*1+64]
    pmovzxbw          m0, xm0
    psllw             m0, 2
    mova         [GDF_PX( 6,64)], xm0
    vextracti128 [GDF_PX( 7,64)], m0, 1
    ret
.load_p_lr_no_right:
    vpbroadcastw     xm0, [t6+160*0-114] ; w-1
    vpbroadcastw     xm1, [t6+160*1-114]
    mova  [t6+160*0-112], xm0
    mova  [t6+160*1-112], xm1
    ret
.extend_top:
    mova              m0, [GDF_PX( 6, 0)]
    mova              m1, [GDF_PX( 6,16)]
    mova              m2, [GDF_PX( 6,32)]
    mova              m3, [GDF_PX( 6,48)]
    mova [GDF_PX(-6, 0)], m0
    mova [GDF_PX(-5, 0)], m0
    mova [GDF_PX(-4, 0)], m0
    mova [GDF_PX(-3, 0)], m0
    mova [GDF_PX(-6,16)], m1
    mova [GDF_PX(-5,16)], m1
    mova [GDF_PX(-4,16)], m1
    mova [GDF_PX(-3,16)], m1
    mova [GDF_PX(-6,32)], m2
    mova [GDF_PX(-5,32)], m2
    mova [GDF_PX(-4,32)], m2
    mova [GDF_PX(-3,32)], m2
    mova [GDF_PX(-6,48)], m3
    mova [GDF_PX(-5,48)], m3
    mova [GDF_PX(-4,48)], m3
    mova [GDF_PX(-3,48)], m3
    ret
.extend_bottom:
    mova              m0, [GDF_PX( 5, 0)]
    mova              m1, [GDF_PX( 5,16)]
    mova              m2, [GDF_PX( 5,32)]
    mova              m3, [GDF_PX( 5,48)]
.extend_tb:
    mova [GDF_PX( 6, 0)], m0
    mova [GDF_PX( 7, 0)], m0
    mova [GDF_PX( 6,16)], m1
    mova [GDF_PX( 7,16)], m1
    mova [GDF_PX( 6,32)], m2
    mova [GDF_PX( 7,32)], m2
    mova [GDF_PX( 6,48)], m3
    mova [GDF_PX( 7,48)], m3
    ret
ALIGN function_align
.calc_grad:
    ; x = 0 (d0/d1/d2/d3 packed in one xmm register)
    vpbroadcastd     xm4, [GDF_PX( 1,-1)]     ; a0' / b
    vpbroadcastd     xm5, [GDF_PX( 2,-1)]     ; c0  / b'
    movq             xm0, [GDF_PX( 1,-2)]     ; a1  c1  / a2' c3'
    movq             xm3, [GDF_PX( 2,-2)]     ; a1' c1' / a3  c2
    punpckldq        xm1, xm0, xm5            ; a1  c0
    punpcklqdq       xm2, xm4, xm0            ; a0' __  a2' c3'
    pinsrd           xm0, [GDF_PX( 0,-1)], 0  ; a0  c1
    shufps           xm1, xm3, q0101          ; c0  a1  c2  a3
    vpblendd         xm2, xm3, 0x02           ; a0' c1' a2' c3'
    movhps           xm0, [GDF_PX( 0,-2)]     ; a0  c1  a2  c3
    pinsrd           xm3, [GDF_PX( 3,-1)], 1  ; a1' c0'
    movq             xm6, [GDF_PX( 3,-2)]     ; a3' c2'
    shufps           xm3, xm6, q0101          ; c0' a1' c2' a3'
    paddw            xm4, xm4                 ; b  * 2
    paddw            xm5, xm5                 ; b' * 2
    paddw            xm0, xm1                 ; a  + c
    paddw            xm2, xm3                 ; a' + c'
    psubw            xm0, xm4
    psubw            xm2, xm5
    pabsw            xm0, xm0
    pabsw            xm2, xm2
    paddw            xm0, xm2                 ; g0  g1  g2  g3
    mova [r10+wq*2+128*4], xm0
.calc_grad_loop: ; x = 1..64
    movu              m4, [GDF_PX( 1, 1)]     ; a0' / b
    movu              m5, [GDF_PX( 2, 1)]     ; c0  / b'
    paddw             m0, m5, [GDF_PX( 0, 1)] ; a0  + c0
    paddw             m9, m4, [GDF_PX( 3, 1)] ; a0' + c0'
    mova              m7, [GDF_PX( 1, 0)]     ; a1  / a2'
    movu              m6, [GDF_PX( 1, 2)]     ; c1  / c3'
    paddw             m4, m4                  ; b   * 2
    paddw             m5, m5                  ; b'  * 2
    mova              m3, [GDF_PX( 2, 0)]     ; a1' / a3
    movu              m2, [GDF_PX( 2, 2)]     ; c1' / c2
    paddw             m1, m7, m6              ; a1  + c1
    paddw             m8, m3, m2              ; a1' + c1'
    paddw             m2, [GDF_PX( 0, 0)]     ; a2  + c2
    paddw             m7, [GDF_PX( 3, 2)]     ; a2' + c2'
    paddw             m3, [GDF_PX( 0, 2)]     ; a3  + c3
    paddw             m6, [GDF_PX( 3, 0)]     ; a3' + c3'
    REPX   {psubw x, m4}, m0, m1, m2, m3
    REPX   {psubw x, m5}, m9, m8, m7, m6
    REPX   {pabsw x, x }, m0, m9, m1, m8, m2, m7, m3, m6
    paddw             m0, m9
    paddw             m1, m8
    paddw             m2, m7
    paddw             m3, m6
    mova [r10+wq*2+128*0], m0
    mova [r10+wq*2+128*1], m1
    mova [r10+wq*2+128*2], m2
    mova [r10+wq*2+128*3], m3
    add               wq, 16
    jl .calc_grad_loop
    movsxd            wq, [rsp+gprsize+GdfStk.w]
    ret
ALIGN function_align
.main:
    mov              r10, [rsp+gprsize+GdfStk.grad0]
    movu              m0, [r10+wq*2+GRAD_STRIDE*0+128*0-4]
    paddw             m0, [r10+wq*2+GRAD_STRIDE*1+128*0-4]
    movu              m1, [r10+wq*2+GRAD_STRIDE*0+128*1-4]
    paddw             m1, [r10+wq*2+GRAD_STRIDE*1+128*1-4]
    movu              m2, [r10+wq*2+GRAD_STRIDE*0+128*2-4]
    paddw             m2, [r10+wq*2+GRAD_STRIDE*1+128*2-4]
    movu              m3, [r10+wq*2+GRAD_STRIDE*0+128*3-4]
    paddw             m3, [r10+wq*2+GRAD_STRIDE*1+128*3-4]
    js .main2 ; SF is set on every loop iteration except the first
    mova             xm4, [r10+wq*2+GRAD_STRIDE*0+128*4]
    paddw            xm4, [r10+wq*2+GRAD_STRIDE*1+128*4]
    pshufd           xm5, xm4, q2301
    punpckhqdq       xm6, xm4, xm4
    punpckhqdq       xm7, xm5, xm5
    vpblendd          m0, m4, 0x01
    vpblendd          m1, m5, 0x01
    vpblendd          m2, m6, 0x01
    vpblendd          m3, m7, 0x01
.main2:
    paddw             m0, [r10+wq*2+GRAD_STRIDE*0+128*0]
    paddw             m1, [r10+wq*2+GRAD_STRIDE*0+128*1]
    paddw             m0, [r10+wq*2+GRAD_STRIDE*1+128*0]
    paddw             m1, [r10+wq*2+GRAD_STRIDE*1+128*1]
    paddw             m2, [r10+wq*2+GRAD_STRIDE*0+128*2]
    paddw             m3, [r10+wq*2+GRAD_STRIDE*0+128*3]
    paddw             m2, [r10+wq*2+GRAD_STRIDE*1+128*2]
    paddw             m3, [r10+wq*2+GRAD_STRIDE*1+128*3]
    vpbroadcastd      m7, [pw_4096]
    vpbroadcastd      m4, [paramsq+GdfParams.grad_alpha+0]
    vpbroadcastd      m5, [paramsq+GdfParams.grad_alpha+4]
    REPX {pmaddwd x, m7}, m0, m1, m2, m3
    vpbroadcastd      m6, [paramsq+GdfParams.grad_weight+0]
    vpbroadcastd      m7, [paramsq+GdfParams.grad_weight+4]
    pcmpgtd          m12, m0, m1   ; ~cls1
    pcmpgtd          m13, m2, m3   ; ~cls2
    psrld             m0, 16
    psrld             m2, 16
    pblendw           m1, m0, 0x55 ; {grad_sums0, grad_sums1} >> 4
    pblendw           m3, m2, 0x55 ; {grad_sums2, grad_sums3} >> 4
    vpbroadcastd      m0, [rsp+gprsize+GdfStk.bias+4*2]
    pminsw            m1, m4
    pminsw            m3, m5
    pmaddwd           m1, m6       ; bias0 + bias1
    pmaddwd           m3, m7       ; bias2 + bias3
    paddd             m0, m1
    paddd             m0, m3       ; bias
    mova [rsp+gprsize+GdfStk.bias2], m0
    GDF_SUM_PART1      0
    GDF_SUM_PART2      0, m10
    GDF_SUM_PART3      0, m10
    GDF_SUM_PART4      0, 1, m7, m10
    GDF_SUM_PART4      0, 2, m7, m10
    GDF_FINALIZE       0, m3, m4
    GDF_SUM_PART1      1 ; different order for y1 avoids register spills
    GDF_SUM_PART4      1, 1, m3, m4
    GDF_SUM_PART4      1, 2, m3, m4
    GDF_SUM_PART3      1, m13
    GDF_SUM_PART2      1, m13
    GDF_FINALIZE       1, m10, m7
    add               wq, 16
    jl .main
    movsxd            wq, [rsp+gprsize+GdfStk.w]
    mov          strideq, [rsp+gprsize+GdfStk.stride]
    mov              r10, t0
    mov               t0, t1
    mov               t1, t2
    mov               t2, t3
    mov               t3, t4
    mov               t4, t5
    mov               t5, t6
    mov               t6, r10
    add             dstq, 64*2
    ret

%macro GDF_ADD 2 ; err_off, p
    mova              m0, [errq+%1]
    mova              m3, %2
    pabsb             m2, m0
    punpcklbw         m1, m2, m2 ; abs(err) << 8. lower bits will be shifted out
    punpckhbw         m2, m2     ; so a dedicated zero register isn't required
    pmulhrsw          m1, m5
    pmulhrsw          m2, m5
    packuswb          m1, m2     ; (abs(diff) + rnd) >> shift
    psubusb           m2, m3, m1
    paddusb           m1, m3
    vpblendvb         m1, m2, m0 ; apply_sign()
    vblendvps         m1, m3, m4 ; ll_mask
    mova              %2, m1
%endmacro

cglobal gdf_add_8bpc, 4, 7, 7, p, ps, err, llm, w, h, scale
    vpbroadcastw      m5, scalem
    mova              m6, [gdf_llm_mul]
    mov               hd, hm
    movifnidn         wd, wm
    lea             llmq, [llmq+hq*2]
    neg               hq
    psllw             m5, 3
    lea               r6, [psq*3]
.loop:
    vpbroadcastw      m4, [llmq+hq*2]
    pmullw            m4, m6
    GDF_ADD         32*0, [pq+psq*0+32*0]
    GDF_ADD         32*2, [pq+psq*1+32*0]
    add             errq, 32*8
    GDF_ADD        -32*4, [pq+psq*2+32*0]
    GDF_ADD        -32*2, [pq+r6   +32*0]
    cmp               wd, 32
    jle .loop_end
    pslld             m4, 16
    GDF_ADD        -32*7, [pq+psq*0+32*1]
    GDF_ADD        -32*5, [pq+psq*1+32*1]
    GDF_ADD        -32*3, [pq+psq*2+32*1]
    GDF_ADD        -32*1, [pq+r6   +32*1]
.loop_end:
    lea               pq, [pq+psq*4]
    add               hq, 4
    jl .loop
    RET
