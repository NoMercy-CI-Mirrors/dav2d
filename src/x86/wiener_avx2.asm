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

pw_maskm1: dw 0x0001, 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040,
           dw 0x0080, 0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000
pw_mask0:  dw 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080,
           dw 0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000
pw_mask1:  dw 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080, 0x0100,
           dw 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000, 0x8000

pd_ror1d: dd 7, 0, 1, 2, 3, 4, 5, 6

pd_mask: dd 0x01010101, 0x02020202, 0x04040404, 0x08080808
         dd 0x10101010, 0x20202020, 0x40404040, 0x80808080

pb_uv_chroma_shuf: db  4,  3,  4,  3,  2,  0,  2,  0
                   db  5,  1,  5,  1,  1,  5,  1,  5
                   times 8 db  0,  2
pb_uv_luma_shuf:   db 13, 10, 13, 10,  9,  5,  9,  5
                   db 15,  7, 15,  7,  6, 14,  6, 14
                   times 4 db  4,  8
                   times 4 db 11, 12

; for calculating feature sums at the left edge of the row
pb_left2_mid:
pb_left2_mid_lo: times 4 db 4*1+1, -1, 4*1+2, -1
pb_left2_mid_hi: times 4 db 4*2+1, -1, 4*2+2, -1
pb_left2_diag0:
pb_left2_diag0_lo: db 4*0+1, -1, 4*0+2, -1 ; | vert
                   db 4*0+2, -1, 4*0+3, -1 ; / anti-diag
                   db 4*0+0, -1, 4*0+1, -1 ; \ diag
                   db -1, -1, -1, -1
pb_left2_diag0_hi: db 4*1+1, -1, 4*1+2, -1
                   db 4*1+2, -1, 4*1+3, -1
                   db 4*1+0, -1, 4*1+1, -1
                   db -1, -1, -1, -1
pb_left2_diag1:
pb_left2_diag1_lo: db 4*2+1, -1, 4*2+2, -1
                   db 4*2+0, -1, 4*2+1, -1
                   db 4*2+2, -1, 4*2+3, -1
                   db -1, -1, -1, -1
pb_left2_diag1_hi: db 4*3+1, -1, 4*3+2, -1
                   db 4*3+0, -1, 4*3+1, -1
                   db 4*3+2, -1, 4*3+3, -1
                   db -1, -1, -1, -1

pb_user_filter_shuf: db 14, 15,  6,  7, 12, 10,  2,  0
                     db  8,  4,  3,  1,  9,  5, 13, 11
pb_pt_filter_shuf:   db 11, 11,  6,  7, 10,  2,  0, 12
                     db  8,  4,  3,  1,  9,  5, -1, -1
center_tap_shuf: db  0,  1,  0,  1,  8,  9,  8,  9
                 db  4,  5,  4,  5, 12, 13, 12, 13

pb_shuf_4x01_4x45: times 4 db  0,  1
                   times 4 db  4,  5
pb_shuf_4x23_4x67: times 4 db  2,  3
                   times 4 db  6,  7
pb_shuf_4x89_4xCD: times 4 db  8,  9
                   times 4 db 12, 13
pb_shuf_4xAB_4xEF: times 4 db 10, 11
                   times 4 db 14, 15
pb_rev_bw: db  1,  0,  3,  2,  5,  4,  7,  6,  9,  8, 11, 10, 13, 12, 15, 14

pb_pt_ll_filt: times 8 db 0
               times 2 db 0, 0, 0, 64

pw_2176_1: dw 2176, 1

pb_1:    times 4 db 1
pb_3:    times 4 db 3
pb_128:  times 4 db 128
pw_1:    times 2 dw 1
pw_24:   times 2 dw 24
pw_64:   times 2 dw 64
pw_128:  times 2 dw 128
pw_255:  times 2 dw 255
pw_256:  times 2 dw 256
pw_2176: times 2 dw 2176
pw_3072: times 2 dw 3072
pw_3074: times 2 dw 3074
pw_3273: times 2 dw 3273
pw_3739: times 2 dw 3739
pw_4096: times 2 dw 4096
pd_255:  dd 255
pd_3072: dd 3072
pd_8192: dd 8192

%macro JMP_TABLE 2-*
 %xdefine %1_jmptable %%table
 %xdefine %%base m(%1)
 %xdefine %%base mangle(private_prefix %+ _%1_avx2)
 %%table:
 %rep %0 - 1
    dd %%base %+ .%2 - %%table
  %rotate 1
 %endrep
%endmacro

JMP_TABLE wiener_uv_luma_420_8bpc, ds_flt0, ds_flt1, ds_flt2

%define m(x) mangle(private_prefix %+ _ %+ x %+ SUFFIX)
%define BUF_STRIDE 128
%define buf_addr(x, y) \
    (y < 0 ? topq + BUF_STRIDE * (4 + y) : \
             (y >= 4 ? botq + (y - 4) * BUF_STRIDE : \
                       midq + y * BUF_STRIDE)) + x
%define Stk(off) (rsp + call_depth*gprsize + UserMultiFilterStk. %+ off)

SECTION .text

struc UserMultiFilterStk
    .row_bufs:        resb 12*BUF_STRIDE
    .scratch:         resb 32*27

    .filters:         resb 16*16
    .center_tap:      resw 2*16

    .vert_qval:       resd 16
    .diag_qval:       resw 32
    .skip_qval:       resw 16

    .s_row_buf:       resw 32

    .vert_offset:     resd 1
    .diag_offset:     resw 4
                      resw 2
    .slope:           resw 6
    .idx0_changeover: resw 2

    ; features sum above
    .f_a_vert:        resw 64
    .f_a_antidiag:    resw 64
    .f_a_diag:        resw 64
    ; features sum left
    .f_l:             resw 8
    ; features sum above left
    .f_al:            resw 8

    .error_lut:       resb 3*48

    .lpf_bottom:      resq 1
    .lpf:             resq 1

    .class_lut:       resq 1
    .noskip_mask:     resq 1
    .p:               resq 1
    .top:             resq 1
    .mid:             resq 1
    .bot:             resq 1
    .bw:              resd 1

    .size:            resb 1
endstruc

struc WienerQValApproxData
    .error_lut:       resb 3*64
    .offsets:         resd 3
    .slopes:          resw 3
    .idx0_changeover: resw 1
endstruc

struc WienerParams
    .filters:     resq 1

    ; Only used when choosing from multiple filters
    .class_lut:   resq 1
    .noskip_mask: resq 1
    .qval_approx: resq 1
endstruc

INIT_YMM avx2
%macro accum_skips_row 3
    pxor              %1, m8 ; ~noskip_mask
    pand              %2, %1, m0
    pand              %3, %1, m1
    pand              %1, m2
    pcmpeqw           %2, m0
    pcmpeqw           %3, m1
    pcmpeqw           %1, m2

    paddw             %1, %2
    psllw             %3, 2
    paddw             %1, %3
%endmacro

%macro start_pair 7 ; dst_lo, dst_hi, in0, in1, mul_lo, mul_hi, tmp
    movu              %2, %3
    movu              %7, %4
    punpcklbw         %1, %2, %7
    punpckhbw         %2, %7
    pmaddubsw         %1, %5
    pmaddubsw         %2, %6
%endmacro

%macro accum_pair 9 ; dst_lo, dst_hi, in0, in1, mul_lo, mul_hi, tmp0-2
    movu              %7, %3
    movu              %8, %4
    punpcklbw         %9, %7, %8
    punpckhbw         %7, %8
    pmaddubsw         %9, %5
    pmaddubsw         %7, %6
    paddw             %1, %9
    paddw             %2, %7
%endmacro

; NOTES:
; * This implementation splits the backup for the weiner filter across cache
;   lines for each iteration to prevent loads crossing cache boundries. The
;   first cache line has pixel cols [-4, 36) and the second cache line
;   has [28, 68).
; * The skip portion of the filter selection process is computed for the entire
;   and then saved.

%assign call_depth 0
cglobal wiener_multi_8bpc, 10, 14, 16, \
                           0 - ((UserMultiFilterStk.size + 31) & ~31), \
                           p, stride, left, top, mid, bot, ll_mask, bw, bh, \
                           edge, tmp0, tmp1
    shr              bwd, 2
    shr              bhd, 2

    ; edge |= ((edge & 3) == 3) << 6;
    mov            tmp0d, edged
    not            tmp0d
    mov            tmp1d, edged
    or             edged, 64
    test           tmp0b, 3
    cmovne         edged, tmp1d

    mov        [Stk(bw)], bwd
    mov         [Stk(p)], pq

    ; Reorder filters and backup
DEFINE_ARGS p, stride, left, lpf, lpf_bot, params, ll_mask, bw, bh, edge, \
            filters, cnt
    mov         filtersq, [paramsq + WienerParams.filters]
    vbroadcasti128   m15, [pb_user_filter_shuf]
    pxor             m14, m14
    vpbroadcastd     m13, [pb_128]
    vpbroadcastd     m12, [pw_2176]
    vbroadcasti128   m11, [center_tap_shuf]

    mov             cntd, 16
.filter_init_loop:
    ; TODO: accumulate filter values outside of asm
    ; 0 | 1
    ; 2 | 3
    movu              m2, [filtersq + 8*cntq + 0]
    movu              m3, [filtersq + 8*cntq + 32]
    ; 4 | 5
    ; 6 | 7
    movu              m4, [filtersq + 8*cntq + 64]
    movu              m5, [filtersq + 8*cntq + 96]

    ; 0 2 | 1 3
    punpcklqdq        m0, m2, m3
    punpckhqdq        m1, m2, m3
    paddb             m0, m1

    pshufb            m2, m15
    pshufb            m3, m15
    mova [Stk(filters) + 8*cntq +  0], m2
    mova [Stk(filters) + 8*cntq + 32], m3

    ; 4 6 | 5 7
    punpcklqdq        m2, m4, m5
    punpckhqdq        m3, m4, m5
    paddb             m2, m3

    pshufb            m4, m15
    pshufb            m5, m15
    mova [Stk(filters) + 8*cntq + 64], m4
    mova [Stk(filters) + 8*cntq + 96], m5

    paddb             m0, m13
    paddb             m2, m13
    psadbw            m0, m14
    psadbw            m2, m14
    ; 0 2 4 6 | 1 3 5 7
    shufps            m0, m2, q2020
    ; 0 2 1 3 | 4 6 5 7
    vpermq            m0, m0, q3120

    ; 0 0 1 1 2 2 3 3 | 4 4 5 5 6 6 7 7
    pshufb            m0, m11
    paddw             m0, m0
    psubw             m0, m12, m0
    mova [Stk(center_tap) + 2*cntq], m0

    sub             cntd, 16
    jge .filter_init_loop

DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, bx, \
            class_lut, tmp0, tmp1
    call .setup_common
    mov               pq, [Stk(p)]
    mov              bwd, [Stk(bw)]

    lea             topq, [Stk(row_bufs) + 8]
    lea             midq, [Stk(row_bufs) + BUF_STRIDE*4 + 8]
    lea             botq, [Stk(row_bufs) + BUF_STRIDE*8 + 8]
.row_loop:
    call .setup_new_row

    xor              bxd, bxd
.col_loop:
    call .calc_features

    mov       class_lutq, [Stk(class_lut)]

    vextracti128     xm1, m0, 1
%macro get_user_filter_offset 0
    mov            tmp0d, tmp1d
    shr            tmp1q, 32
    movzx          tmp0d, byte [class_lutq+tmp0q]
    movzx          tmp1d, byte [class_lutq+tmp1q]
    shl            tmp0d, 2
    shl            tmp1d, 2
%endmacro
    ; f0/f1
    movq           tmp1q, xm0
    get_user_filter_offset
    mova            xm10, [Stk(filters) + tmp0q*4]
    mova            xm13, [Stk(filters) + tmp1q*4]
    movd             xm8, [Stk(center_tap) + tmp0q]
    pinsrd           xm8, [Stk(center_tap) + tmp1q], 1

    ; f4/f5
    movq           tmp1q, xm1
    get_user_filter_offset
    vinserti128      m10, [Stk(filters) + tmp0q*4], 1
    vinserti128      m13, [Stk(filters) + tmp1q*4], 1
    movd             xm9, [Stk(center_tap) + tmp0q]
    pinsrd           xm9, [Stk(center_tap) + tmp1q], 1

    ; f2/f3
    pextrq         tmp1q, xm0, 1
    get_user_filter_offset
    mova            xm14, [Stk(filters) + tmp0q*4]
    mova            xm15, [Stk(filters) + tmp1q*4]
    pinsrd           xm8, [Stk(center_tap) + tmp0q], 2
    pinsrd           xm8, [Stk(center_tap) + tmp1q], 3

    ; f6/f7
    pextrq         tmp1q, xm1, 1
    get_user_filter_offset
    vinserti128      m14, [Stk(filters) + tmp0q*4], 1
    vinserti128      m15, [Stk(filters) + tmp1q*4], 1
    pinsrd           xm9, [Stk(center_tap) + tmp0q], 2
    pinsrd           xm9, [Stk(center_tap) + tmp1q], 3
    vinserti128       m8, xm9, 1

    ; Transpose
    ; Note: The indexes in the comments do not match the filter value pattern
    ;       since they were shuffled beforehand
    ; f0   f1   f0   f1   | f4   f5   f4   f5
    ; 0123 0123 4567 4567 | 0123 0123 4567 4567
    punpckldq        m11, m10, m13
    ; f2   f3   f2   f3   | f6   f7   f6   f7
    ; 0123 0123 4567 4567 | 0123 0123 4567 4567
    punpckldq        m12, m14, m15

    ; f0 f1 f0 f1 f0 f1 f0 f1 | f4 f5 f4 f5 f4 f5 f4 f5
    ; 89 89 AB AB CD CD EF EF | 89 89 AB AB CD CD EF EF
    punpckhwd        m10, m13
    ; f2 f3 f2 f3 f2 f3 f2 f3 | f6 f7 f6 f7 f6 f7 f6 f7
    ; 89 89 AB AB CD CD EF EF | 89 89 AB AB CD CD EF EF
    punpckhwd        m14, m15
    ; f0 f1 f2 f3 f0 f1 f2 f3 | f4 f5 f6 f7 f4 f5 f6 f7
    punpckldq        m15, m10, m14
    punpckhdq        m10, m14

    ; TODO: Mask the stored values or mess with the indices or just use
    ;       branch prediction to skip this most of the time.
    ; Create an empty filter for lossless blocks
    vpbroadcastb      m7, [ll_maskq]
    mova              m6, [pd_mask]
    vpbroadcastd      m5, [pw_128]
    pand              m7, m6
    pcmpeqd           m7, m6
    vblendvps         m8, m5, m7
    pshufd            m6, m7, q1010
    pshufd            m5, m7, q3232
    pandn            m11, m6, m11
    pandn            m12, m5, m12
    packssdw          m7, m7
    pandn            m15, m7, m15
    pandn            m10, m7, m10

    mova [Stk(scratch) + 32*24], m15
    mova [Stk(scratch) + 32*25], m10
    mova [Stk(scratch) + 32*26], m8

    ; Pattern of filter values:
    ;    -4 -3 -2 -1  0  1  2  3  4
    ;    ┌──┬──┬──┬──┬──┬──┬──┬──┬──┐
    ; -4 │  │  │  │  │ C│  │  │  │  │
    ; -3 │  │ E│  │  │ A│  │  │ F│  │
    ; -2 │  │  │  │ 6│ 2│ 7│  │  │  │
    ; -1 │  │  │ 8│ 4│ 0│ 5│ 9│  │  │
    ;  0 │ D│ B│ 3│ 1│ X│ 1│ 3│ B│ D│
    ;  1 │  │  │ 9│ 5│ 0│ 4│ 8│  │  │
    ;  2 │  │  │  │ 7│ 2│ 6│  │  │  │
    ;  3 │  │ F│  │  │ A│  │  │ E│  │
    ;  4 │  │  │  │  │ C│  │  │  │  │
    ;    └──┴──┴──┴──┴──┴──┴──┴──┴──┘

    ; Max of each filter value (right) and range (left) for preventing overflow.
    ; The min value is irrelevant for avoiding overflows for useful patterns.
    ;
    ;     -4 -3 -2 -1  0  1  2  3  4        -4 -3 -2 -1  0  1  2  3  4
    ;    ┌──┬──┬──┬──┬──┬──┬──┬──┬──┐      ┌──┬──┬──┬──┬──┬──┬──┬──┬──┐
    ; -4 │  │  │  │  │ 7│  │  │  │  │   -4 │  │  │  │  │15│  │  │  │  │
    ; -3 │  │ 7│  │  │ 7│  │  │ 7│  │   -3 │  │15│  │  │15│  │  │15│  │
    ; -2 │  │  │  │ 7│17│ 7│  │  │  │   -2 │  │  │  │15│31│15│  │  │  │
    ; -1 │  │  │ 7│15│39│15│ 7│  │  │   -1 │  │  │15│31│63│31│15│  │  │
    ;  0 │ 7│ 7│17│39│  │39│17│ 7│ 7│    0 │15│15│31│63│  │63│31│15│15│
    ;  1 │  │  │ 7│15│39│15│ 7│  │  │    1 │  │  │15│31│63│31│15│  │  │
    ;  2 │  │  │  │ 7│17│ 7│  │  │  │    2 │  │  │  │15│31│15│  │  │  │
    ;  3 │  │ 7│  │  │ 7│  │  │ 7│  │    3 │  │15│  │  │15│  │  │15│  │
    ;  4 │  │  │  │  │ 7│  │  │  │  │    4 │  │  │  │  │15│  │  │  │  │
    ;    └──┴──┴──┴──┴──┴──┴──┴──┴──┘      └──┴──┴──┴──┴──┴──┴──┴──┴──┘

    ; Accumulate in seperate groups using the pattern below:
    ;     -4 -3 -2 -1  0  1  2  3  4
    ;    ┌──┬──┬──┬──┬──┬──┬──┬──┬──┐
    ; -4 │  │  │  │  │ A│  │  │  │  │
    ; -3 │  │ A│  │  │ A│  │  │ A│  │
    ; -2 │  │  │  │ A│ A│ A│  │  │  │
    ; -1 │  │  │ C│ C│ A│ D│ D│  │  │
    ;  0 │ C│ C│ C│ C│ X│ D│ D│ C│ C│
    ;  1 │  │  │ C│ C│ B│ D│ D│  │  │
    ;  2 │  │  │  │ A│ B│ A│  │  │  │
    ;  3 │  │ A│  │  │ B│  │  │ A│  │
    ;  4 │  │  │  │  │ B│  │  │  │  │
    ;    └──┴──┴──┴──┴──┴──┴──┴──┴──┘
    ; Groups A/B unpack loaded values and then run maddubsw.
    ; Groups C/D runs maddubsw on horz adjacent pairs of values together.
    ; Group X is the center tap.

    ; duplicate pairs of filters
    vbroadcasti128   m15, [pb_shuf_4x01_4x45]
    pshufb           m14, m11, m15
    pshufb           m15, m12, m15

    ; Group A
    ; Filters: E, F
    start_pair m0, m1, [buf_addr(-3,-3)], [buf_addr( 3, -3)], m14, m15, m8
    start_pair m2, m3, [buf_addr(-3,-2)], [buf_addr( 3, -2)], m14, m15, m8
    start_pair m4, m5, [buf_addr(-3,-1)], [buf_addr( 3, -1)], m14, m15, m8
    start_pair m6, m7, [buf_addr(-3, 0)], [buf_addr( 3,  0)], m14, m15, m8

    accum_pair m0, m1, [buf_addr( 3, 3)], [buf_addr(-3, 3)], m14, m15, \
               m8, m9, m10
    accum_pair m2, m3, [buf_addr( 3, 4)], [buf_addr(-3, 4)], m14, m15, \
               m8, m9, m10
    accum_pair m4, m5, [buf_addr( 3, 5)], [buf_addr(-3, 5)], m14, m15, \
               m8, m9, m10
    accum_pair m6, m7, [buf_addr( 3, 6)], [buf_addr(-3, 6)], m14, m15, \
               m8, m9, m10

    vbroadcasti128   m10, [pb_shuf_4x23_4x67]
    pshufb           m14, m11, m10
    pshufb           m15, m12, m10

    ; Filters: 6, 7
    call .filters67

    vbroadcasti128    m8, [pb_shuf_4x89_4xCD]
    vbroadcasti128    m9, [pb_shuf_4xAB_4xEF]

    ; Filters: C,A,0,2
    ; duplicate pairs of filters
    pshufb           m13, m12, m8
    pshufb           m15, m12, m9
    pshufb           m12, m11, m8
    pshufb           m14, m11, m9

    movu              m8, [buf_addr(0,-4)]
    movu              m9, [buf_addr(0,-3)]
    punpcklbw        m10, m8, m9
    punpckhbw         m8, m9
    pmaddubsw        m10, m12
    pmaddubsw         m8, m13
    paddw             m0, m10
    paddw             m1, m8
    movu              m8, [buf_addr(0,-2)]
    punpcklbw        m10, m9, m8
    punpckhbw         m9, m8
    pmaddubsw        m10, m12
    pmaddubsw         m9, m13
    paddw             m2, m10
    paddw             m3, m9
    movu              m9, [buf_addr(0,-1)]
    punpcklbw        m10, m8, m9
    punpckhbw         m8, m9
    pmaddubsw        m11, m10, m14
    pmaddubsw        m10, m12
    paddw             m0, m11
    paddw             m4, m10
    pmaddubsw        m11, m8, m15
    pmaddubsw         m8, m13
    paddw             m1, m11
    paddw             m5, m8
    movu              m8, [buf_addr(0, 0)]
    mova [Stk(scratch) + 32*16], m0
    mova [Stk(scratch) + 32*17], m1
    punpcklbw        m10, m9, m8
    punpckhbw         m9, m8
    pmaddubsw        m11, m10, m14
    pmaddubsw        m10, m12
    paddw             m2, m11
    paddw             m6, m10
    pmaddubsw        m11, m9, m15
    pmaddubsw         m9, m13
    paddw             m3, m11
    paddw             m7, m9

    movu              m9, [buf_addr(0, 1)]
    mova [Stk(scratch) + 32*18], m2
    mova [Stk(scratch) + 32*19], m3
    punpcklbw        m11, m8, m9
    punpckhbw         m8, m9
    pmaddubsw        m11, m14
    pmaddubsw         m8, m15
    paddw             m4, m11
    paddw             m5, m8
    movu              m8, [buf_addr(0, 2)]
    mova [Stk(scratch) + 32*20], m4
    mova [Stk(scratch) + 32*21], m5
    punpcklbw        m10, m9, m8
    punpckhbw        m11, m9, m8
    pmaddubsw        m10, m14
    pmaddubsw        m11, m15
    paddw             m6, m10
    paddw             m7, m11
    mova [Stk(scratch) + 32*22], m6
    mova [Stk(scratch) + 32*23], m7

    ; Group B
    punpcklbw         m0, m8, m9
    punpckhbw         m1, m8, m9
    pmaddubsw         m0, m14
    pmaddubsw         m1, m15
    movu              m9, [buf_addr(0, 3)]
    punpcklbw         m2, m9, m8
    punpckhbw         m3, m9, m8
    pmaddubsw         m2, m14
    pmaddubsw         m3, m15

    movu              m8, [buf_addr(0, 4)]
    punpcklbw         m4, m8, m9
    punpckhbw         m5, m8, m9
    pmaddubsw         m9, m4, m12
    pmaddubsw         m4, m14
    paddw             m0, m9
    pmaddubsw         m9, m5, m13
    pmaddubsw         m5, m15
    paddw             m1, m9
    movu              m9, [buf_addr(0, 5)]
    punpcklbw         m6, m9, m8
    punpckhbw         m7, m9, m8
    pmaddubsw         m8, m6, m12
    pmaddubsw         m6, m14
    paddw             m2, m8
    pmaddubsw         m8, m7, m13
    pmaddubsw         m7, m15
    paddw             m3, m8

    movu              m8, [buf_addr(0, 6)]
    punpcklbw        m10, m8, m9
    punpckhbw         m9, m8, m9
    pmaddubsw        m10, m12
    pmaddubsw         m9, m13
    paddw             m4, m10
    paddw             m5, m9

    movu              m9, [buf_addr(0, 7)]
    punpcklbw        m10, m9, m8
    punpckhbw         m8, m9, m8
    pmaddubsw        m10, m12
    pmaddubsw         m8, m13
    paddw             m6, m10
    paddw             m7, m8

    mova [Stk(scratch) + 32*8], m0
    mova [Stk(scratch) + 32*9], m1
    mova [Stk(scratch) + 32*10], m2
    mova [Stk(scratch) + 32*11], m3
    mova [Stk(scratch) + 32*12], m4
    mova [Stk(scratch) + 32*13], m5
    mova [Stk(scratch) + 32*14], m6
    mova [Stk(scratch) + 32*15], m7

    ; Group C
    mova m13, [Stk(scratch) + 32*24]
    mova m15, [Stk(scratch) + 32*25]
    ; duplicate multipliers
    ; f0 f1 f2 f3 | f4 f5 f6 f7
    punpcklwd  m12, m13, m13
    punpckhwd  m13, m13
    punpcklwd  m14, m15, m15
    punpckhwd  m15, m15

%macro group_cd_inner 8 ; dst1, dst2, dst3, dst4, f[8,4], f[3,1], f[9,5],
                         ; offset
    ; Filters: 3,1 / 8,4 / 9,5
    movu              %1, [buf_addr(%8,-1)]
    movu              %2, [buf_addr(%8, 0)]
    movu              %3, [buf_addr(%8, 1)]
    pmaddubsw         %1, %5
    pmaddubsw         m8, %2, %6
    pmaddubsw         %2, %5
    pmaddubsw         m9, %3, %7
    paddw             %1, m8
    pmaddubsw         m8, %3, %6
    pmaddubsw         %3, %5
    paddw             %1, m9

    movu              %4, [buf_addr(%8, 2)]
    pmaddubsw         m9, %4, %7
    paddw             %2, m8
    pmaddubsw         m8, %4, %6
    paddw             %2, m9
    pmaddubsw         %4, %5
    paddw             %3, m8

    movu              m8, [buf_addr(%8, 3)]
    pmaddubsw         m9, m8, %6
    pmaddubsw         m8, %7
    paddw             %4, m9
    paddw             %3, m8
    movu              m9, [buf_addr(%8, 4)]
    pmaddubsw         m9, %7
    paddw             %4, m9
%endmacro

%macro group_c_outer 6 ; dst1, dst2, dst3, dst4, f[d,b], x
    ; Filters: D,B
    movu              m8, [buf_addr(%6, 0)]
    movu              m9, [buf_addr(%6, 1)]
    pmaddubsw         m8, %5
    pmaddubsw         m9, %5
    paddw             %1, m8
    paddw             %2, m9
    movu              m8, [buf_addr(%6, 2)]
    movu              m9, [buf_addr(%6, 3)]
    pmaddubsw         m8, %5
    pmaddubsw         m9, %5
    paddw             %3, m8
    paddw             %4, m9
%endmacro

    group_cd_inner m0, m1, m2, m3, m12, m13, m14, -2
    group_cd_inner m4, m5, m6, m7, m12, m13, m14, -1
    group_c_outer  m0, m1, m2, m3, m15, -4
    group_c_outer  m4, m5, m6, m7, m15, -3

    vbroadcasti128   m11, [pb_rev_bw]
    REPX {pshufb x, m11}, m15, m14, m13, m12

    group_c_outer  m0, m1, m2, m3, m15, 3
    group_c_outer  m4, m5, m6, m7, m15, 4

    mova [Stk(scratch) + 32*0], m0
    mova [Stk(scratch) + 32*1], m1
    mova [Stk(scratch) + 32*2], m2
    mova [Stk(scratch) + 32*3], m3
    mova [Stk(scratch) + 32*4], m4
    mova [Stk(scratch) + 32*5], m5
    mova [Stk(scratch) + 32*6], m6
    mova [Stk(scratch) + 32*7], m7

    ; Group D
    group_cd_inner m0, m1, m2, m3, m14, m13, m12, 1
    group_cd_inner m4, m5, m6, m7, m14, m13, m12, 2

%macro accum_groups 4 ; y, in0/out, in1, ones
    punpckhwd         m8, %2, %3
    punpcklwd         %2, %3

    mova             m10, [Stk(scratch) + 32*(%1)]
    mova             m11, [Stk(scratch) + 32*(%1+4)]
    punpckhwd         %3, m10, m11
    punpcklwd        m10, m11

    punpckhwd         m9, %2, m10
    punpcklwd         %2, m10
    REPX {pmaddwd x, %4}, %2, m9
    punpckhwd        m10, m8, %3
    punpcklwd         m8, %3
    REPX {pmaddwd x, %4}, m10, m8

    mova             m11, [Stk(scratch) + 32*(8+2*%1)]
    mova             m12, [Stk(scratch) + 32*(16+2*%1)]
    punpckhwd         %3, m11, m12
    punpcklwd        m11, m12
    REPX {pmaddwd x, %4}, m11, %3
    paddd             %2, m11
    paddd             m9, %3

    mova             m11, [Stk(scratch) + 32*(8+2*%1+1)]
    mova             m12, [Stk(scratch) + 32*(16+2*%1+1)]
    punpckhwd         %3, m11, m12
    punpcklwd        m11, m12
    REPX {pmaddwd x, %4}, m11, %3
    paddd             m8, m11
    paddd            m10, %3

    movu             %3, [buf_addr(0,%1)]
    pxor            m12, m12
    punpckhbw       m11, %3, m12
    punpcklbw        %3, m12
    pmulhw          m15, %3, m13
    pmullw           %3, m13
    punpckhwd       m12, %3, m15
    punpcklwd        %3, m15
    paddd            %2, %3
    paddd            m9, m12

    pmulhw          m15, m11, m14
    pmullw          m11, m14
    punpckhwd       m12, m11, m15
    punpcklwd       m11, m15
    paddd            m8, m11
    paddd           m10, m12

%if %1 == 0
    ; hardcode this to first rows input reg
    vpbroadcastd     m4, [pw_256]
%endif
    packssdw         %2, m9
    packssdw         m8, m10
    REPX {pmulhrsw x, m4}, %2, m8

    packuswb         %2, m8
%endmacro

    lea            tmp0q, [strideq*3]
    mova             m13, [Stk(scratch) + 32*26]
    punpckhwd        m14, m13, m13
    punpcklwd        m13, m13

    vpbroadcastd     m15, [pw_1]
    accum_groups 0, m0, m4, m15
    mova  [pq+strideq*0], m0

    vpbroadcastd     m0, [pw_1]
    accum_groups 1, m1, m5, m0
    mova  [pq+strideq*1], m1

    accum_groups 2, m2, m6, m0
    mova  [pq+strideq*2], m2

    accum_groups 3, m3, m7, m0
    mova      [pq+tmp0q], m3

    inc         ll_maskq
    add              bxd, 8
    add               pq, 32
    add             topq, 64
    add             midq, 64
    add             botq, 64
    sub              bwd, 8
    jg .col_loop

    add         ll_maskq, 7
    and         ll_maskq, ~1
    mov               pq, [Stk(p)]
    lea               pq, [pq+strideq*4]
    mov             botq, [Stk(top)]
    mov             topq, [Stk(mid)]
    mov             midq, [Stk(bot)]
    mov              bwd, [Stk(bw)]
    dec              bhd
    jg .row_loop

    RET
%assign call_depth 1
.filters67:
    accum_pair m0, m1, [buf_addr(-1,-2)], [buf_addr( 1,-2)], m14, m15, \
               m8, m9, m10
    accum_pair m2, m3, [buf_addr(-1,-1)], [buf_addr( 1,-1)], m14, m15, \
               m8, m9, m10
    accum_pair m4, m5, [buf_addr(-1, 0)], [buf_addr( 1, 0)], m14, m15, \
               m8, m9, m10
    accum_pair m6, m7, [buf_addr(-1, 1)], [buf_addr( 1, 1)], m14, m15, \
               m8, m9, m10

    accum_pair m0, m1, [buf_addr( 1, 2)], [buf_addr(-1, 2)], m14, m15, \
               m8, m9, m10
    accum_pair m2, m3, [buf_addr( 1, 3)], [buf_addr(-1, 3)], m14, m15, \
               m8, m9, m10
    accum_pair m4, m5, [buf_addr( 1, 4)], [buf_addr(-1, 4)], m14, m15, \
               m8, m9, m10
    accum_pair m6, m7, [buf_addr( 1, 5)], [buf_addr(-1, 5)], m14, m15, \
               m8, m9, m10
    ret

%assign call_depth 1
.setup_new_row:
DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, stride3, \
            buf_stride, tmp, noskip_mask
    mov       [Stk(top)], topq
    mov       [Stk(mid)], midq
    mov       [Stk(bot)], botq
    mov         [Stk(p)], pq
    lea         stride3q, [strideq*3]

    ; Backup the new bottom 4 pixels
    cmp              bhd, 1
    je .final_rows
    lea               pq, [pq + 4*strideq]
    call .bak_new_rows
    jmp .bot_bak_done
.final_rows:
    test           edgeb, 32 ; have_bottom_integrated
    jnz .have_bottom_integrated
    test           edgeb, 8  ; have_bottom
    jz .no_bottom
    mov               pq, [Stk(lpf_bottom)]
    mov      buf_strideq, -BUF_STRIDE
    mov         stride3q, -BUF_STRIDE*3
    add               pq, strideq
    add             botq, BUF_STRIDE*3
    neg          strideq
    call .bak_sb_edge
    neg          strideq
    jmp .bot_bak_done
.have_bottom_integrated:
    lea               pq, [pq+strideq*4]
    call .bak_edge_tile
    jmp .bot_bak_done
.no_bottom:
    add             midq, BUF_STRIDE*3
    call .bak_no_h_edge
    mov             midq, [Stk(mid)]
.bot_bak_done:
    mov             botq, [Stk(bot)]
    mov               pq, [Stk(p)]

    ; Compute skip features
    mov     noskip_maskq, [Stk(noskip_mask)]

    mova              m3, [Stk(s_row_buf) + 32] ; skip: current row
    ; TODO: combine with backup branch with the same condition
    cmp              bhd, 1
    je .final_rows_skip

    ; Compute skip features entire next row
    pcmpeqw           m8, m8
    mova              m0, [pw_maskm1]
    mova              m1, [pw_mask0]
    mova              m2, [pw_mask1]
    vpbroadcastw      m5, [noskip_maskq]
    add     noskip_maskq, 2
    mov [Stk(noskip_mask)], noskip_maskq
    accum_skips_row m5, m6, m7
    mova  [Stk(s_row_buf) + 32], m5
    jmp .skip_have_bot
.final_rows_skip:
    mova              m5, m3
.skip_have_bot:
    mova              m4, [Stk(s_row_buf)]      ; skip: previous row
    mova [Stk(s_row_buf)], m3

    psllw             m3, 2
    paddw             m3, m4

    paddw             m3, m5
    pabsw             m3, m3

    vbroadcasti128    m9, [Stk(vert_offset)]
    vbroadcasti128   m15, [Stk(slope)]
    pshufd            m7, m9, q0000  ; vert offset
    pshufd            m8, m9, q1111  ; diag offset 1
    pshufd            m9, m9, q2222  ; diag offset 2
    pshufd           m10, m15, q3333 ; idx0 changeover point
    pshufd           m11, m15, q0000
    pshufd           m14, m15, q1111
    pshufd           m15, m15, q2222

    pcmpgtw          m10, m3
    psllw            m10, 9
    mova [Stk(skip_qval)], m10

    ; qval_approx->slope * s
    pmullw           m12, m11, m3
    pmulhw           m11, m3
    pmullw           m14, m3
    pmullw           m15, m3
    punpckhwd        m13, m12, m11
    punpcklwd        m12, m11
    ; qval_approx->slope * s + qval_approx->offset
    paddw            m14, m8
    paddw            m15, m9
    paddd            m13, m7
    paddd            m12, m7

    vpbroadcastd     m10, [pw_4096]

    ; shift the low byte high, so that garbage lut results can be shifted down
    psllw             m0, m3, 8

    ; generate lookup indices for each 16 bytes of shufb
    pcmpeqw           m6, m6
    paddw             m6, m10
    psubw             m1, m0, m10
    pcmpgtw           m5, m0, m6    ; s < 16
    psubw             m2, m1, m10
    pcmpgtw           m6, m1, m6    ; s < 32
    por               m0, m5
    por               m1, m6

%macro lookup_error 1 ; dir
    vbroadcasti128    m7, [Stk(error_lut)+48*%1+0]
    vbroadcasti128    m8, [Stk(error_lut)+48*%1+16]
    vbroadcasti128    m9, [Stk(error_lut)+48*%1+32]
    pshufb            m7, m0
    pshufb            m8, m1
    pshufb            m9, m2
    por               m7, m8
    por               m7, m9
%endmacro

    ; qval_approx->slope * s + qval_approx->offset + qval_approx->error_lut[s]
    lookup_error 1
    psraw             m7, 8
    paddw            m14, m7

    lookup_error 2
    psraw             m7, 8
    paddw            m15, m7

    lookup_error 0
    psraw             m8, m7, 16 ; sign
    psraw             m7, 8
    punpckhwd         m9, m7, m8
    punpcklwd         m7, m8
    paddd            m12, m7
    paddd            m13, m9

    vperm2i128       m11, m12, m13, 0x20
    vperm2i128       m12, m13, 0x31

    mova [Stk(diag_qval)], m14
    mova [Stk(diag_qval) + 32], m15
    mova [Stk(vert_qval)], m11
    mova [Stk(vert_qval) + 32], m12

    ; Initialize the buffered left most skip values for the row
    movd             xm0, [buf_addr(-2, 2)]
    pinsrd           xm0, [buf_addr(-2, 3)], 1
    pinsrd           xm0, [buf_addr(-2, 4)], 2
    pinsrd           xm0, [buf_addr(-2, 5)], 3
    movd             xm1, [buf_addr(-2, 0)]
    pinsrd           xm1, [buf_addr(-2, 1)], 1
    ; 0 1 2 3
    shufps           xm1, xm0, q1010
    ; 2 3 4 5 0 1 2 3
    vinserti128       m0, xm1, 1

    vbroadcasti128    m1, [pb_left2_mid_lo]
    vbroadcasti128    m2, [pb_left2_mid_hi]
    REPX {pshufb x, m0, x}, m1, m2
    REPX {paddw x, x}, m1, m2

    vbroadcasti128    m3, [pb_left2_diag0_lo]
    vbroadcasti128    m4, [pb_left2_diag1_lo]
    REPX {pshufb x, m0, x}, m3, m4
    paddw             m3, m4

    vbroadcasti128    m5, [pb_left2_diag0_hi]
    vbroadcasti128    m6, [pb_left2_diag1_hi]
    REPX {pshufb x, m0, x}, m5, m6
    paddw             m5, m6

    psubw             m1, m3
    psubw             m2, m5
    REPX {pabsw x, x}, m1, m2

    paddw             m1, m2
    mova             xm2, [Stk(f_al)]

    vextracti128     xm0, m1, 1
    mova     [Stk(f_al)], xm1
    paddw            xm0, xm1
    paddw            xm0, xm2
    mova      [Stk(f_l)], xm0
    ret

%assign call_depth 1
.calc_features:
DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, bx
%macro sum_dirs 2 ; unpckl/hbw, feature cache offset
    movu              m0, [buf_addr( 0, 5)]
    movu              m1, [buf_addr( 1, 5)]
    movu              m2, [buf_addr( 2, 5)]
    REPX {%1 x, m15}, m0, m1, m2

    movu              m3, [buf_addr( 0, 4)]
    movu              m4, [buf_addr( 1, 4)]
    movu              m5, [buf_addr( 2, 4)]
    REPX {%1 x, m15}, m3, m4, m5

    movu              m6, [buf_addr( 0, 3)]
    movu              m7, [buf_addr( 1, 3)]
    movu              m8, [buf_addr( 2, 3)]
    REPX {%1 x, m15}, m6, m7, m8

    paddw            m12, m4, m4
    paddw             m0, m8
    paddw             m1, m7
    paddw             m2, m6
    REPX {psubw x, m12}, m0, m1, m2
    REPX {pabsw x, x}, m0, m1, m2

    movu              m9, [buf_addr( 0, 2)]
    movu             m10, [buf_addr( 1, 2)]
    movu             m11, [buf_addr( 2, 2)]
    REPX {%1 x, m15}, m9, m10, m11

    paddw            m12, m7, m7
    paddw             m3, m11
    paddw             m4, m10
    paddw             m5, m9
    REPX {psubw x, m12}, m3, m4, m5
    REPX {pabsw x, x}, m3, m4, m5

    mova             m12, [Stk(f_a_antidiag)+bxq*8+%2]
    paddw             m0, m3
    mova              m3, [Stk(f_a_vert)+bxq*8+%2]
    paddw             m1, m4
    mova              m4, [Stk(f_a_diag)+bxq*8+%2]
    paddw             m2, m5

    mova [Stk(f_a_antidiag)+bxq*8+%2], m0
    mova [Stk(f_a_vert)+bxq*8+%2], m1
    mova [Stk(f_a_diag)+bxq*8+%2], m2

    paddw             m0, m12
    paddw             m1, m3
    paddw             m2, m4

    movu              m3, [buf_addr( 0, 1)]
    movu              m4, [buf_addr( 1, 1)]
    movu              m5, [buf_addr( 2, 1)]
    REPX {%1 x, m15}, m3, m4, m5

    paddw            m12, m10, m10
    paddw             m6, m5
    paddw             m7, m4
    paddw             m8, m3
    REPX {psubw x, m12}, m6, m7, m8
    REPX {pabsw x, x}, m6, m7, m8

    paddw             m0, m6
    paddw             m1, m7
    paddw             m2, m8

    movu              m6, [buf_addr( 0, 0)]
    movu              m7, [buf_addr( 1, 0)]
    movu              m8, [buf_addr( 2, 0)]
    REPX {%1 x, m15}, m6, m7, m8

    paddw            m12, m4, m4
    paddw             m9, m8
    paddw            m10, m7
    paddw            m11, m6
    REPX {psubw x, m12}, m9, m10, m11
    REPX {pabsw x, x}, m9, m10, m11

    paddw             m0, m9
    paddw             m1, m10
    paddw             m2, m11
%endmacro

    pxor             m15, m15
    sum_dirs punpckhbw, 32
    mova [Stk(scratch) + 32*0], m0
    mova [Stk(scratch) + 32*1], m1
    mova [Stk(scratch) + 32*2], m2
    sum_dirs punpcklbw, 0
    mova m3, [Stk(scratch) + 32*0]
    mova m4, [Stk(scratch) + 32*1]
    mova m5, [Stk(scratch) + 32*2]

    mova             m11, [pd_ror1d]
    movd            xm13, [Stk(f_l)]
    movd            xm12, [Stk(f_l) + 4]
    movd            xm14, [Stk(f_l) + 8]

    ; input:
    ;    -2 -1
    ;     0  1  2  3  4  5  6  7 | 16 17 18 19 20 21 22 23
    ;     8  9 10 11 12 13 14 15 | 24 25 26 27 28 29 30 31

    ;     2  3  6  7 10 11 14 15 | 18 19 22 23 26 27 30 31
    shufps            m6, m0, m3, q3131
    ;     0  1  4  5  8  9 12 13 | 16 17 20 21 24 25 28 29
    shufps            m0, m3, q2020
    ;    30 31  2  3  6  7 10 11 | 14 15 18 19 22 23 26 27
    vpermd            m9, m11, m6
    movd [Stk(f_l) + 4], xm9
    ;    -2 -1  2  3  6  7 10 11 | 14 15 18 19 22 23 26 27
    vpblendd          m9, m12, 1
    shufps            m7, m1, m4, q3131
    shufps            m1, m4, q2020
    vpermd           m10, m11, m7
    movd [Stk(f_l)], xm10
    vpblendd         m10, m13, 1
    shufps            m8, m2, m5, q3131
    shufps            m2, m5, q2020
    vpermd           m11, m8
    movd [Stk(f_l) + 8], xm11
    vpblendd         m11, m14, 1

    ;    -2 -1  2  3  6  7 10 11 | 14 15 18 19 22 23 26 27
    ;     0  1  4  5  8  9 12 13 | 16 17 20 21 24 25 28 29
    ; +   2  3  6  7 10 11 14 15 | 18 19 22 23 26 27 30 31
    paddw             m0, m6
    paddw             m1, m7
    paddw             m2, m8
    paddw             m0, m9
    paddw             m1, m10
    paddw             m2, m11

    vpbroadcastd     m14, [pw_3739]
    pmaddwd           m1, m14
    vpbroadcastd     m14, [pw_3273]
    pmaddwd           m0, m14
    vpbroadcastd     m14, [pw_3074]
    pmaddwd           m2, m14

    vpbroadcastd     m14, [pd_255]
    vpbroadcastd     m13, [pd_8192]
    mova              m4, [Stk(vert_qval) + 4*bxq]
    pmovzxwd          m3, [Stk(diag_qval) + 2*bxq]
    pmovzxwd          m5, [Stk(diag_qval) + 2*bxq + 32]

    ; 255 * qval, avoiding mulld
    pslld             m6, m4, 8
    psubd             m4, m6, m4
    pmaddwd           m3, m14
    pmaddwd           m5, m14
    pslld            m14, 14

    ; f + 255 * qval
    paddd             m1, m4
    paddd             m0, m3
    paddd             m2, m5

    REPX {pmaxsd x, m15}, m1, m0, m2 ; imax(0, f + 255 * qval)
    REPX {paddd x, m13}, m1, m0, m2  ; sub_idx = imax(0, f + 255 * qval) + 8192
    REPX {pminsd x, m14}, m1, m0, m2 ; imin(sub_idx, 255 << 14)
    REPX {psrad x, 19}, m1, m0, m2   ; imin(sub_idx, 255 << 14) >> 14 >> 5

    pslld             m1, 6
    pslld             m0, 3

    pmovsxwd          m3, [Stk(skip_qval) + 2*bxq]
    por               m1, m2
    psubd             m0, m3
    por               m0, m1
    ret

%assign call_depth 1
.setup_common:
DEFINE_ARGS p, stride, left, lpf, lpf_bot, params, ll_mask, bw, h, edge, \
            stride3, qval_approx, noskip_mask
    mov     qval_approxq, [paramsq + WienerParams.qval_approx]
    mov     noskip_maskq, [paramsq + WienerParams.class_lut]
    mov [Stk(class_lut)], noskip_maskq
    mov     noskip_maskq, [paramsq + WienerParams.noskip_mask]

    ; Copy QVal approximate data to the stack
    movu              m0, [qval_approxq + WienerQValApproxData.error_lut]
    movu             xm1, [qval_approxq + WienerQValApproxData.error_lut + 32]
    vinserti128       m1, [qval_approxq + WienerQValApproxData.error_lut + 64], 1
    movu              m2, [qval_approxq + WienerQValApproxData.error_lut + 80]
    movu              m3, [qval_approxq + WienerQValApproxData.error_lut + 128]
    movu             xm4, [qval_approxq + WienerQValApproxData.error_lut + 160]
    mova [Stk(error_lut)], m0
    mova [Stk(error_lut)+32], m1
    mova [Stk(error_lut)+64], m2
    mova [Stk(error_lut)+96], m3
    mova [Stk(error_lut)+128], xm4

    ; Convert to dwords for broadcasting
    movd             xm0, [qval_approxq + WienerQValApproxData.offsets]
    movq             xm1, [qval_approxq + WienerQValApproxData.offsets+4]
    movq             xm2, [qval_approxq + WienerQValApproxData.slopes]
    pshuflw          xm1, xm1, q2200 ; 32 -> 16-bits and duplicate
    punpcklwd        xm2, xm2
    movd [Stk(vert_offset)], xm0
    movq [Stk(diag_offset)], xm1
    mova    [Stk(slope)], xm2

    ; Setup the skip mask sum
    pcmpeqw           m8, m8
    mova              m0, [pw_maskm1]
    mova              m1, [pw_mask0]
    mova              m2, [pw_mask1]
    vpbroadcastw      m3, [noskip_maskq]
    add     noskip_maskq, 2
    mov [Stk(noskip_mask)], noskip_maskq
    accum_skips_row m3, m4, m5
    mova [Stk(s_row_buf)], m3
    mova [Stk(s_row_buf) + 32], m3

    DEFINE_ARGS p, stride, left, lpf, lpf_bot, params, ll_mask, bw, h, edge, \
                stride3, buf_stride, tmp
    ; TODO: try to avoid saving lpf/lpf_bottom
    mov [Stk(lpf_bottom)], lpf_botq
    mov        [Stk(lpf)], lpfq

    ; backup the initial 8 rows. 4 middle rows and 4 top rows.
    ; TODO: Move earlier because this might trigger store forwarding stalls
    DEFINE_ARGS p, stride, left, lpf, mid, bot, ll_mask, bw, h, edge, stride3, \
                buf_stride, tmp
    lea         stride3q, [strideq*3]
    lea             botq, [Stk(row_bufs) + BUF_STRIDE*4 + 8]
    call .bak_new_rows
    lea             midq, [Stk(row_bufs) + BUF_STRIDE*4 + 8]
    lea             botq, [Stk(row_bufs) + 8]
    test           edgeb, 16 ; have_top_integrated
    jnz .have_top_integrated
    test           edgeb, 4  ; have_top
    jz .no_top
    mov               pq, [Stk(lpf)]
    mov      buf_strided, BUF_STRIDE
    mov         stride3d, BUF_STRIDE*3
    call .bak_sb_edge
    jmp .end_top
.have_top_integrated:
    mov   [Stk(scratch)], pq
    mov               pq, [Stk(lpf)]
    call .bak_edge_tile
    jmp .end_top
.no_top:
    call .bak_no_h_edge
.end_top:

    DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, h, edge, \
                stride3, bx

    lea             topq, [Stk(row_bufs) + 8]
    lea             midq, [Stk(row_bufs) + BUF_STRIDE*4 + 8]

    ; Buffer the above left features for the first row
    movd             xm0, [buf_addr(-2,-2)]
    pinsrd           xm0, [buf_addr(-2,-1)], 1
    pinsrd           xm0, [buf_addr(-2, 0)], 2
    pinsrd           xm0, [buf_addr(-2, 1)], 3
    vinserti128       m0, xm0, 1

    mova              m1, [pb_left2_mid]
    pshufb            m1, m0, m1
    paddw             m1, m1

    mova              m3, [pb_left2_diag0]
    mova              m4, [pb_left2_diag1]
    REPX {pshufb x, m0, x}, m3, m4
    paddw             m3, m4

    psubw             m1, m3
    pabsw             m1, m1

    vextracti128     xm2, m1, 1
    paddw            xm1, xm2
    mova     [Stk(f_al)], xm1

    ; initialize above features sum cache
    xor              bxd, bxd
.f_a_loop:
    call .f_a_0to8_16to24
    add             topq, 8
    add             midq, 8
    add              bxd, 4
    sub              bwd, 4
    jl .end_f_a_loop
    call .f_a_0to8_16to24
    add             topq, 56
    add             midq, 56
    add              bxd, 4
    sub              bwd, 4
    jg .f_a_loop
.end_f_a_loop:
    ret
%assign call_depth 2
.f_a_0to8_16to24:
    pxor             m15, m15
    movu              m0, [buf_addr( 0, 1)]
    movu              m1, [buf_addr( 1, 1)]
    movu              m2, [buf_addr( 2, 1)]
    REPX {punpcklbw x, m15}, m0, m1, m2

    movu              m3, [buf_addr( 0, 0)]
    movu              m4, [buf_addr( 1, 0)]
    movu              m5, [buf_addr( 2, 0)]
    REPX {punpcklbw x, m15}, m3, m4, m5

    movu              m6, [buf_addr( 0, -1)]
    movu              m7, [buf_addr( 1, -1)]
    movu              m8, [buf_addr( 2, -1)]
    REPX {punpcklbw x, m15}, m6, m7, m8

    paddw            m12, m4, m4
    paddw             m0, m8
    paddw             m1, m7
    paddw             m2, m6
    REPX {psubw x, m12}, m0, m1, m2
    REPX {pabsw x, x}, m0, m1, m2

    movu              m9, [buf_addr( 0, -2)]
    movu             m10, [buf_addr( 1, -2)]
    movu             m11, [buf_addr( 2, -2)]
    REPX {punpcklbw x, m15}, m9, m10, m11

    paddw            m12, m7, m7
    paddw             m3, m11
    paddw             m4, m10
    paddw             m5, m9
    REPX {psubw x, m12}, m3, m4, m5
    REPX {pabsw x, x}, m3, m4, m5

    paddw             m0, m3
    paddw             m1, m4
    paddw             m2, m5

    mova [Stk(f_a_antidiag)+bxq*8], m0
    mova [Stk(f_a_vert)+bxq*8], m1
    mova [Stk(f_a_diag)+bxq*8], m2
    ret

%assign call_depth 2
; TODO: Reduce the size of the edge backup code
.bak_new_rows:
DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, stride3, \
            buf_stride, tmp
    lea         stride3q, [strideq*3]
    mova              m0, [pq]
    mova              m1, [pq+strideq]
    mova              m2, [pq+strideq*2]
    mova              m3, [pq+stride3q]
    test           edgeb, 64 ; have left and right
    jz .no_right_or_left

    movq             xm4, [leftq+0]
    movq             xm5, [leftq+8]
    movq             xm6, [leftq+16]
    movq             xm7, [leftq+24]
    add            leftq, 32
.have_right:
    ;  3  0  1  2
    REPX {vpermq x, x, q2103}, m0, m1, m2, m3

    ; -1  0  1  2
    vpblendd          m4, m0, m4, 3
    vpblendd          m5, m1, m5, 3
    vpblendd          m6, m2, m6, 3
    vpblendd          m7, m3, m7, 3

    mova [botq + BUF_STRIDE*0 - 8], m4
    mova [botq + BUF_STRIDE*1 - 8], m5
    mova [botq + BUF_STRIDE*2 - 8], m6
    mova [botq + BUF_STRIDE*3 - 8], m7

    mova              m4, [pq+32]
    mova              m5, [pq+strideq+32]
    mova              m6, [pq+strideq*2+32]
    mova              m7, [pq+stride3q+32]

    ;  7  4  5  6
    REPX {vpermq x, x, q2103}, m4, m5, m6, m7

    ;  3  4  5  6
    vpblendd          m0, m4, m0, 3
    vpblendd          m1, m5, m1, 3
    vpblendd          m2, m6, m2, 3
    vpblendd          m3, m7, m3, 3

    mova [botq + BUF_STRIDE*0 + 32 - 8], xm0
    mova [botq + BUF_STRIDE*1 + 32 - 8], xm1
    mova [botq + BUF_STRIDE*2 + 32 - 8], xm2
    mova [botq + BUF_STRIDE*3 + 32 - 8], xm3

    mova [botq + BUF_STRIDE*0 + 64 - 8], m0
    mova [botq + BUF_STRIDE*1 + 64 - 8], m1
    mova [botq + BUF_STRIDE*2 + 64 - 8], m2
    mova [botq + BUF_STRIDE*3 + 64 - 8], m3

    ;  7  8
    pinsrq           xm4, [pq+64], 1
    pinsrq           xm5, [pq+strideq+64], 1
    pinsrq           xm6, [pq+strideq*2+64], 1
    pinsrq           xm7, [pq+stride3q+64], 1

    mova [botq + BUF_STRIDE*0 + 96 - 8], xm4
    mova [botq + BUF_STRIDE*1 + 96 - 8], xm5
    mova [botq + BUF_STRIDE*2 + 96 - 8], xm6
    mova [botq + BUF_STRIDE*3 + 96 - 8], xm7
    ret
.no_right_or_left:
    test           edgeb, 1 ; have_left
    jz .no_left
    movq             xm4, [leftq]
    movq             xm5, [leftq+8]
    movq             xm6, [leftq+16]
    movq             xm7, [leftq+24]
    add            leftq, 32
    jmp .store_left
.no_left:
    pxor             xm8, xm8
    pshufb           xm4, xm0, xm8
    pshufb           xm5, xm1, xm8
    pshufb           xm6, xm2, xm8
    pshufb           xm7, xm3, xm8
.store_left:
    test           edgeb, 2 ; have_right
    jnz .have_right

    movu [botq + BUF_STRIDE*0], m0
    movu [botq + BUF_STRIDE*1], m1
    movu [botq + BUF_STRIDE*2], m2
    movu [botq + BUF_STRIDE*3], m3

    movq [botq + BUF_STRIDE*0 - 8], xm4
    movq [botq + BUF_STRIDE*1 - 8], xm5
    movq [botq + BUF_STRIDE*2 - 8], xm6
    movq [botq + BUF_STRIDE*3 - 8], xm7
    cmp              bwd, 8
    jle .bak_half

    REPX {vpermq x, x, q2103}, m0, m1, m2, m3
    movq [botq + BUF_STRIDE*0 + 56], xm0
    movq [botq + BUF_STRIDE*1 + 56], xm1
    movq [botq + BUF_STRIDE*2 + 56], xm2
    movq [botq + BUF_STRIDE*3 + 56], xm3

    mova              m0, [pq+32]
    mova              m1, [pq+strideq+32]
    mova              m2, [pq+strideq*2+32]
    mova              m3, [pq+stride3q+32]

    movu [botq + BUF_STRIDE*0 + 64], m0
    movd [botq + BUF_STRIDE*0 + 32], xm0
    movu [botq + BUF_STRIDE*1 + 64], m1
    movd [botq + BUF_STRIDE*1 + 32], xm1
    movu [botq + BUF_STRIDE*2 + 64], m2
    movd [botq + BUF_STRIDE*2 + 32], xm2
    movu [botq + BUF_STRIDE*3 + 64], m3
    movd [botq + BUF_STRIDE*3 + 32], xm3

.bak_half:
    movd             xm4, [pb_3]
    lea               pq, [pq + 4*bwq - 4]
    movd             xm0, [pq]
    movd             xm1, [pq + strideq]
    movd             xm2, [pq + strideq*2]
    movd             xm3, [pq + stride3q]
    REPX {pshufb x, xm4}, xm0, xm1, xm2, xm3
    lea             tmpq, [botq + 4*bwq]
    cmp              bwd, 8
    jle .w32
    add             tmpq, 32
.w32:
    movd [tmpq + BUF_STRIDE*0], xm0
    movd [tmpq + BUF_STRIDE*1], xm1
    movd [tmpq + BUF_STRIDE*2], xm2
    movd [tmpq + BUF_STRIDE*3], xm3
    ret

.bak_sb_edge:
DEFINE_ARGS lpf, stride, left, top, mid, bot, ll_mask, bw, bh, edge, stride3, \
            buf_stride, tmp
    mova              m0, [lpfq]
    mova              m1, [lpfq + strideq]
    test           edgeb, 1 ; have_left
    jz .no_left_sb
    movq             xm2, [lpfq - 8]
    movq             xm3, [lpfq + strideq - 8]
    jmp .store_left_sb
.no_left_sb:
    pxor             xm8, xm8
    pshufb           xm2, xm0, xm8
    pshufb           xm3, xm1, xm8
.store_left_sb:
    movu [botq + buf_strideq*0], m0
    movu [botq + buf_strideq*1], m0
    movu [botq + buf_strideq*2], m0
    movu [botq + stride3q], m1
    movq [botq + buf_strideq*0 - 8], xm2
    movq [botq + buf_strideq*1 - 8], xm2
    movq [botq + buf_strideq*2 - 8], xm2
    movq [botq + stride3q - 8], xm3
    cmp              bwd, 8
    jle .no_right_sb

    REPX {vpermq x, x, q2103}, m0, m1
    movq [botq + buf_strideq*0 + 56], xm0
    movq [botq + buf_strideq*1 + 56], xm0
    movq [botq + buf_strideq*2 + 56], xm0
    movq [botq + stride3q + 56], xm1

    mova              m0, [lpfq+32]
    mova              m1, [lpfq+strideq+32]
    movu [botq + buf_strideq*0 + 64], m0
    movu [botq + buf_strideq*1 + 64], m0
    movu [botq + buf_strideq*2 + 64], m0
    movu [botq + stride3q + 64], m1
    movd [botq + buf_strideq*0 + 32], xm0
    movd [botq + buf_strideq*1 + 32], xm0
    movd [botq + buf_strideq*2 + 32], xm0
    movd [botq + stride3q + 32], xm1

    test           edgeb, 2 ; have_right
    jz .no_right_sb
    movd             xm0, [lpfq+64]
    movd             xm1, [lpfq+strideq+64]
    movd [botq + buf_strideq*0 + 96], xm0
    movd [botq + buf_strideq*1 + 96], xm0
    movd [botq + buf_strideq*2 + 96], xm0
    movd [botq + stride3q + 96], xm1
    ret
.no_right_sb:
    movd             xm4, [pb_3]
    lea             lpfq, [lpfq + 4*bwq - 4]
    movd             xm0, [lpfq]
    movd             xm1, [lpfq + strideq]
    REPX {pshufb x, xm4}, xm0, xm1
    lea             botq, [botq + 4*bwq]
    cmp              bwd, 8
    jle .w32_sb
    add             botq, 32
.w32_sb:
    movd [botq + buf_strideq*0], xm0
    movd [botq + buf_strideq*1], xm0
    movd [botq + buf_strideq*2], xm0
    movd [botq + stride3q], xm1
    ret

.bak_no_h_edge:
DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, stride3, \
            buf_stride, bx
    sub             midq, 8
    sub             botq, 8
    mov              bxd, bwd
.copy_buf_loop:
    mova              m0, [midq]
    mova [botq+BUF_STRIDE*0], m0
    mova [botq+BUF_STRIDE*1], m0
    mova [botq+BUF_STRIDE*2], m0
    mova [botq+BUF_STRIDE*3], m0
    mova             xm0, [midq+32]
    add             midq, 64
    mova [botq+BUF_STRIDE*0+32], xm0
    mova [botq+BUF_STRIDE*1+32], xm0
    mova [botq+BUF_STRIDE*2+32], xm0
    mova [botq+BUF_STRIDE*3+32], xm0
    add             botq, 64
    sub              bxd, 8
    jg .copy_buf_loop
    ret

.bak_edge_tile:
DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, stride3, \
            buf_stride, tmp
    mova              m0, [pq]
    mova              m1, [pq+strideq]
    mova              m2, [pq+strideq*2]
    mova              m3, [pq+stride3q]
    test           edgeb, 64 ; have left and right
    jz .no_right_or_left_tile

    movq             xm4, [pq-8]
    movq             xm5, [pq+strideq-8]
    movq             xm6, [pq+strideq*2-8]
    movq             xm7, [pq+stride3q-8]
    jmp .have_right
.no_right_or_left_tile:
    test           edgeb, 1 ; have_left
    jz .no_left
    movq             xm4, [pq-8]
    movq             xm5, [pq+strideq-8]
    movq             xm6, [pq+strideq*2-8]
    movq             xm7, [pq+stride3q-8]
    jmp .store_left

%assign call_depth 0
cglobal wiener_pretrained_8bpc, 10, 15, 16, \
                           0 - ((UserMultiFilterStk.size + 31) & ~31), \
                           p, stride, left, top, mid, bot, ll_mask, bw, bh, \
                           edge, tmp0, tmp1
    shr              bwd, 2
    shr              bhd, 2

    ; edge |= ((edge & 3) == 3) << 6;
    mov            tmp0d, edged
    not            tmp0d
    mov            tmp1d, edged
    or             edged, 64
    test           tmp0b, 3
    cmovne         edged, tmp1d

    mov        [Stk(bw)], bwd
    mov         [Stk(p)], pq

DEFINE_ARGS p, stride, left, lpf, lpf_bot, params, ll_mask, bw, bh, edge, \
            cnt, _12, _13, _14, filters
    mov         filtersq, [paramsq + WienerParams.filters]

DEFINE_ARGS p, stride, left, top, mid, bot, ll_mask, bw, bh, edge, bx, \
            class_lut, tmp0, tmp1, filters
    call m(wiener_multi_8bpc).setup_common
    mov               pq, [Stk(p)]
    mov              bwd, [Stk(bw)]

    lea             topq, [Stk(row_bufs) + 8]
    lea             midq, [Stk(row_bufs) + BUF_STRIDE*4 + 8]
    lea             botq, [Stk(row_bufs) + BUF_STRIDE*8 + 8]
.row_loop:
    call m(wiener_multi_8bpc).setup_new_row

    xor              bxd, bxd
.col_loop:
    call m(wiener_multi_8bpc).calc_features

    mov       class_lutq, [Stk(class_lut)]

    vbroadcasti128    m7, [pb_pt_filter_shuf]

%macro get_pretrained_filter_offsets 0
    mov            tmp0d, tmp1d
    shr            tmp1q, 32
    movzx          tmp0d, byte [class_lutq+tmp0q]
    movzx          tmp1d, byte [class_lutq+tmp1q]
    imul           tmp0d, 13
    imul           tmp1d, 13
%endmacro
    vextracti128     xm1, m0, 1
    ; f0/f1
    movq           tmp1q, xm0
    get_pretrained_filter_offsets
    movu            xm10, [filtersq + tmp0q]
    movu            xm13, [filtersq + tmp1q]

    ; f4/f5
    movq           tmp1q, xm1
    get_pretrained_filter_offsets
    vinserti128      m10, [filtersq + tmp0q], 1
    vinserti128      m13, [filtersq + tmp1q], 1
    pshufb           m10, m7
    pshufb           m13, m7

    ; f2/f3
    pextrq         tmp1q, xm0, 1
    get_pretrained_filter_offsets
    movu            xm14, [filtersq + tmp0q]
    movu            xm15, [filtersq + tmp1q]

    ; f6/f7
    pextrq         tmp1q, xm1, 1
    get_pretrained_filter_offsets
    vinserti128      m14, [filtersq + tmp0q], 1
    vinserti128      m15, [filtersq + tmp1q], 1
    pshufb           m14, m7
    pshufb           m15, m7

    ; Transpose
    ; Note: The indexes in the comments do not match the filter value pattern
    ;       since they were shuffled beforehand
    ; f0   f1   f0   f1   | f4   f5   f4   f5
    ; 0123 0123 4567 4567 | 0123 0123 4567 4567
    punpckldq        m11, m10, m13
    ; f2   f3   f2   f3   | f6   f7   f6   f7
    ; 0123 0123 4567 4567 | 0123 0123 4567 4567
    punpckldq        m12, m14, m15

    ; f0 f1 f0 f1 f0 f1 f0 f1 | f4 f5 f4 f5 f4 f5 f4 f5
    ; 89 89 AB AB CD CD EF EF | 89 89 AB AB CD CD EF EF
    punpckhwd        m10, m13
    ; f2 f3 f2 f3 f2 f3 f2 f3 | f6 f7 f6 f7 f6 f7 f6 f7
    ; 89 89 AB AB CD CD EF EF | 89 89 AB AB CD CD EF EF
    punpckhwd        m14, m15
    ; f0 f1 f2 f3 f0 f1 f2 f3 | f4 f5 f6 f7 f4 f5 f6 f7
    punpckldq        m15, m10, m14
    punpckhdq        m10, m14

    ; TODO: Mask the stored values or mess with the indices or just use
    ;       branch prediction to skip this most of the time.
    ; Create an empty filter for lossless blocks
    vpbroadcastb      m7, [ll_maskq]
    mova              m6, [pd_mask]
    vbroadcasti128    m4, [pb_pt_ll_filt]
    pand              m7, m6
    pcmpeqd           m7, m6
    pshufd            m6, m7, q1010
    pshufd            m5, m7, q3232
    vblendvps        m11, m4, m6
    vblendvps        m12, m4, m5
    packssdw          m7, m7
    pandn            m15, m7, m15
    pandn            m10, m7, m10

    mova [Stk(scratch) + 32*24], m15
    mova [Stk(scratch) + 32*25], m10

    ; Pattern of filter values:
    ;     -3 -2 -1  0  1  2  3
    ;    ┌──┬──┬──┬──┬──┬──┬──┐
    ; -3 │  │  │  │ A│  │  │  │
    ; -2 │  │  │ 6│ 2│ 7│  │  │
    ; -1 │  │ 8│ 4│ 0│ 5│ 9│  │
    ;  0 │ B│ 3│ 1│ X│ 1│ 3│ B│
    ;  1 │  │ 9│ 5│ 0│ 4│ 8│  │
    ;  2 │  │  │ 7│ 2│ 6│  │  │
    ;  3 │  │  │  │ A│  │  │  │
    ;    └──┴──┴──┴──┴──┴──┴──┘
    ; Initial accumulation happens in 16 bits in 4 seperate groups to avoid
    ; overflows. To find a pattern that works, you have to go through all of
    ; the pretrained filters.
    ; The groups use the pattern below:
    ;     -3 -2 -1  0  1  2  3
    ;    ┌──┬──┬──┬──┬──┬──┬──┐
    ; -3 │  │  │  │ A│  │  │  │
    ; -2 │  │  │ A│ A│ A│  │  │
    ; -1 │  │ C│ C│ A│ D│ D│  │
    ;  0 │ A│ C│ C│AB│ D│ D│ A│
    ;  1 │  │ C│ C│ B│ D│ D│  │
    ;  2 │  │  │ A│ B│ A│  │  │
    ;  3 │  │  │  │ B│  │  │  │
    ;    └──┴──┴──┴──┴──┴──┴──┘
    ; Groups A/B unpack loaded values and then run maddubsw. This includes
    ;   half of the center tap value for each (see AB).
    ; Groups C/D runs maddubsw on horz adjacent pairs of values together.
    ;  is the center tap.

    ; Group A
    ; Filters: B

    ; duplicate pairs of filters
    vbroadcasti128   m15, [pb_shuf_4x01_4x45]
    pshufb           m14, m11, m15
    pshufb           m15, m12, m15

    start_pair m0, m1, [buf_addr(-3, 0)], [buf_addr( 3, 0)], m14, m15, m8
    start_pair m2, m3, [buf_addr(-3, 1)], [buf_addr( 3, 1)], m14, m15, m8
    start_pair m4, m5, [buf_addr(-3, 2)], [buf_addr( 3, 2)], m14, m15, m8
    start_pair m6, m7, [buf_addr(-3, 3)], [buf_addr( 3, 3)], m14, m15, m8

    ; Offset to prevent overflowing
    vpbroadcastd     m10, [pw_3072]
    REPX {psubw x, m10}, m0, m1, m2, m3, m4, m5, m6, m7

    ; Filters: 6, 7
    vbroadcasti128   m10, [pb_shuf_4x23_4x67]
    pshufb           m14, m11, m10
    pshufb           m15, m12, m10

    call m(wiener_multi_8bpc).filters67

    vbroadcasti128    m8, [pb_shuf_4x89_4xCD]
    vbroadcasti128    m9, [pb_shuf_4xAB_4xEF]

    ; Filters: A, 2, 0, X
    ; duplicate pairs of filters
    pshufb           m13, m12, m8
    pshufb           m15, m12, m9
    pshufb           m12, m11, m8
    pshufb           m14, m11, m9

    movu              m8, [buf_addr(0,-3)]
    movu              m9, [buf_addr(0,-2)]
    punpcklbw        m10, m8, m9
    punpckhbw         m8, m9
    pmaddubsw        m10, m12
    pmaddubsw         m8, m13
    paddw             m0, m10
    paddw             m1, m8
    movu              m8, [buf_addr(0,-1)]
    punpcklbw        m10, m9, m8
    punpckhbw         m9, m8
    pmaddubsw        m10, m12
    pmaddubsw         m9, m13
    paddw             m2, m10
    paddw             m3, m9
    movu              m9, [buf_addr(0, 0)]
    punpcklbw        m10, m8, m9
    punpckhbw         m8, m9
    pmaddubsw        m11, m10, m14
    pmaddubsw        m10, m12
    paddw             m0, m11
    paddw             m4, m10
    pmaddubsw        m11, m8, m15
    pmaddubsw         m8, m13
    paddw             m1, m11
    paddw             m5, m8
    movu              m8, [buf_addr(0, 1)]
    mova [Stk(scratch) + 32*16], m0
    mova [Stk(scratch) + 32*17], m1
    punpcklbw         m0, m9, m8
    pmaddubsw        m10, m0, m14
    punpckhbw         m1, m9, m8
    pmaddubsw        m11, m0, m12
    paddw             m2, m10
    paddw             m6, m11
    pmaddubsw        m10, m1, m15
    pmaddubsw        m11, m1, m13
    paddw             m3, m10
    paddw             m7, m11

    movu              m9, [buf_addr(0, 2)]
    mova [Stk(scratch) + 32*18], m2
    mova [Stk(scratch) + 32*19], m3
    punpcklbw         m2, m8, m9
    punpckhbw         m3, m8, m9
    pmaddubsw        m10, m2, m14
    pmaddubsw        m11, m3, m15
    paddw             m4, m10
    paddw             m5, m11
    movu              m8, [buf_addr(0, 3)]
    mova [Stk(scratch) + 32*20], m4
    mova [Stk(scratch) + 32*21], m5
    punpcklbw         m4, m9, m8
    punpckhbw         m5, m9, m8
    pmaddubsw        m10, m4, m14
    pmaddubsw        m11, m5, m15
    paddw             m6, m10
    paddw             m7, m11

    vbroadcasti128   m10, [pb_rev_bw]
    mova [Stk(scratch) + 32*22], m6
    mova [Stk(scratch) + 32*23], m7
    REPX {pshufb x, m10}, m14, m15, m12, m13

    ; Group B
    pmaddubsw         m0, m14
    pmaddubsw         m1, m15
    pmaddubsw         m2, m14
    pmaddubsw         m3, m15
    pmaddubsw         m9, m4, m12
    pmaddubsw        m10, m5, m13
    pmaddubsw         m4, m14
    pmaddubsw         m5, m15
    paddw             m0, m9
    paddw             m1, m10

    movu              m9, [buf_addr(0, 4)]
    punpcklbw         m6, m8, m9
    punpckhbw         m7, m8, m9
    pmaddubsw         m8, m6, m12
    pmaddubsw         m6, m14
    paddw             m2, m8
    pmaddubsw         m8, m7, m13
    pmaddubsw         m7, m15
    paddw             m3, m8

    movu              m8, [buf_addr(0, 5)]
    punpcklbw        m10, m9, m8
    punpckhbw         m9, m8
    pmaddubsw        m10, m12
    pmaddubsw         m9, m13
    paddw             m4, m10
    paddw             m5, m9

    movu              m9, [buf_addr(0, 6)]
    punpcklbw        m10, m8, m9
    punpckhbw         m8, m9
    pmaddubsw        m10, m12
    pmaddubsw         m8, m13
    paddw             m6, m10
    paddw             m7, m8

    mova [Stk(scratch) + 32*8], m0
    mova [Stk(scratch) + 32*9], m1
    mova [Stk(scratch) + 32*10], m2
    mova [Stk(scratch) + 32*11], m3
    mova [Stk(scratch) + 32*12], m4
    mova [Stk(scratch) + 32*13], m5
    mova [Stk(scratch) + 32*14], m6
    mova [Stk(scratch) + 32*15], m7

    ; Group C
    mova m13, [Stk(scratch) + 32*24]
    mova m15, [Stk(scratch) + 32*25]
    ; duplicate multipliers
    ; f0 f1 f2 f3 | f4 f5 f6 f7
    punpcklwd  m12, m13, m13
    punpckhwd  m13, m13
    punpcklwd  m14, m15, m15

    group_cd_inner m0, m1, m2, m3, m12, m13, m14, -2
    group_cd_inner m4, m5, m6, m7, m12, m13, m14, -1

    vbroadcasti128   m11, [pb_rev_bw]
    REPX {pshufb x, m11}, m15, m14, m13, m12

    mova [Stk(scratch) + 32*0], m0
    mova [Stk(scratch) + 32*1], m1
    mova [Stk(scratch) + 32*2], m2
    mova [Stk(scratch) + 32*3], m3
    mova [Stk(scratch) + 32*4], m4
    mova [Stk(scratch) + 32*5], m5
    mova [Stk(scratch) + 32*6], m6
    mova [Stk(scratch) + 32*7], m7

    ; Group D
    group_cd_inner m0, m1, m2, m3, m14, m13, m12, 1
    group_cd_inner m4, m5, m6, m7, m14, m13, m12, 2

%macro accum_groups_pt 4 ; y, in0/out, in1, ones
    punpckhwd         m8, %2, %3
    punpcklwd         %2, %3

    mova             m10, [Stk(scratch) + 32*(%1)]
    mova             m11, [Stk(scratch) + 32*(%1+4)]
    punpckhwd         %3, m10, m11
    punpcklwd        m10, m11

    punpckhwd         m9, %2, m10
    punpcklwd         %2, m10
    REPX {pmaddwd x, %4}, %2, m9
    punpckhwd        m10, m8, %3
    punpcklwd         m8, %3
    REPX {pmaddwd x, %4}, m10, m8

    mova             m11, [Stk(scratch) + 32*(8+2*%1)]
    mova             m12, [Stk(scratch) + 32*(16+2*%1)]
    punpckhwd         %3, m11, m12
    punpcklwd        m11, m12
    REPX {pmaddwd x, %4}, m11, %3
    paddd             %2, m11
    paddd             m9, %3

    mova             m11, [Stk(scratch) + 32*(8+2*%1+1)]
    mova             m12, [Stk(scratch) + 32*(16+2*%1+1)]
    punpckhwd         %3, m11, m12
    punpcklwd        m11, m12
    REPX {pmaddwd x, %4}, m11, %3
    paddd             m8, m11
    paddd            m10, %3

%if %1 == 0
    ; hardcode this to first rows input reg
    vpbroadcastd     m4, [pw_256]
%endif
    packssdw         %2, m9
    packssdw         m8, m10
    REPX {pmulhrsw x, m4}, %2, m8
    REPX {paddw x, m14}, %2, m8

    packuswb         %2, m8
%endmacro

    lea            tmp0q, [strideq*3]

    vpbroadcastd     m13, [pw_1]
    vpbroadcastd     m14, [pw_24]
    accum_groups_pt 0, m0, m4, m13
    mova  [pq+strideq*0], m0

    accum_groups_pt 1, m1, m5, m13
    mova  [pq+strideq*1], m1

    accum_groups_pt 2, m2, m6, m13
    mova  [pq+strideq*2], m2

    accum_groups_pt 3, m3, m7, m13
    mova      [pq+tmp0q], m3

    inc         ll_maskq
    add              bxd, 8
    add               pq, 32
    add             topq, 64
    add             midq, 64
    add             botq, 64
    sub              bwd, 8
    jg .col_loop

    add         ll_maskq, 7
    and         ll_maskq, ~1
    mov               pq, [Stk(p)]
    lea               pq, [pq+strideq*4]
    mov             botq, [Stk(top)]
    mov             topq, [Stk(mid)]
    mov             midq, [Stk(bot)]
    mov              bwd, [Stk(bw)]
    dec              bhd
    jg .row_loop

    RET

struc WienerUVChromaStk
    .row_buf: resb 96*5 + 32
    .bot:     resq 1
    .w:       resd 1
endstruc

%define Stk(off) (rsp + call_depth*gprsize + WienerUVChromaStk. %+ off)
%define TREG(=n) t %+ n
%define BUF_PX(x, y) (TREG((y) + 2) + x)
DECLARE_REG_TMP 11, 12, 4, 3, 6

cglobal wiener_uv_chroma_8bpc, 8, 15, 16, \
                               0 - ((WienerUVChromaStk_size + 31) & ~31), \
                               p, stride, left, top, bot, luma, filter, \
                               ll_mask, w, h, edge, _, _, tmp, w_bak
%assign call_depth 0
    movifnidn         wd, wm
    movifnidn         hd, hm
    movifnidn      edged, edgem
    mov       [Stk(bot)], botq

    mov         [Stk(w)], wd
    add               wd, 31
    and               wd, ~31
    neg               wq
    mov           w_bakq, wq
    ; combine h and edge to free up a register
    shl               hd, 6
    lea            edged, [edgeq+hq-(4<<6)]

    DEFINE_ARGS p, stride, left, top, bot, luma, filter, ll_mask, w, src, \
                edge, _, _, tmp, w_bak

    vbroadcasti128    m0, [filterq]
    pslldq           xm3, xm0, 2
    vpbroadcastd     xm5, [pb_128]
    pxor             xm4, xm4
    paddb            xm3, xm5
    psadbw           xm3, xm4
    paddw            xm3, xm3
    movd             xm2, [pw_2176_1]
    psubw            xm2, xm3
    vpbroadcastd     m10, xm2 ; center tap and 1

    pshufb            m0, [pb_uv_chroma_shuf]
    mova  [Stk(row_buf)], m0
    vpbroadcastd     m11, [Stk(row_buf) + 0]
    vpbroadcastd     m12, [Stk(row_buf) + 4]
    vpbroadcastd     m13, [Stk(row_buf) + 8]
    vpbroadcastd     m14, [Stk(row_buf) + 12]
    vpbroadcastd     m15, [Stk(row_buf) + 16]
    vpbroadcastd      m9, [pw_4096] ; offset to prevent overflows

    mov             srcq, pq
    lea               t4, [Stk(row_buf) + 96*2 + 32]
    call .load_p
    call .load_p_lr
    mov               t2, t4
.top:
    test           edgeb, 0x14 ; LR_HAVE_TOP | LR_HAVE_TOP_INTEGRATED
    jz .no_top
    lea               t4, [Stk(row_buf) + 32]
    mov             srcq, topq
    call .load_p
    add             srcq, strideq
    mov               t0, t4
    add               t4, 96
    call .load_p
    call .load_tb_lr
    mov               t1, t4
    add               t4, 96*2
    mov             srcq, pq
    jmp .top_done
.no_top:
    lea               t0, [Stk(row_buf) + 32]
    lea               t1, [Stk(row_buf) + 96 + 32]
    mova              m0, [BUF_PX( 0, 0)]
    mova              m1, [BUF_PX(32, 0)]
    mova  [BUF_PX(0,-2)], m0
    mova [BUF_PX(32,-2)], m1
    mova  [BUF_PX(0,-1)], m0
    mova [BUF_PX(32,-1)], m1
    mov             tmpd, [BUF_PX(-4, 0)]
    mov  [BUF_PX(-4,-1)], tmpd
    mov             tmpd, [BUF_PX(64, 0)]
    mov  [BUF_PX(64,-1)], tmpd
    add               t4, 96
.top_done:
    add             srcq, strideq
    call .load_p
    call .load_p_lr
    add             srcq, strideq
    mov               t3, t4
    add               t4, 96
.main_loop:
    call .load_p
    call .load_p_lr
    add             srcq, strideq
    call .main
    call .load_p
    call .load_p_lr
    add             srcq, strideq
    call .main
    ; advance ll_mask every 4 rows
    rorx            tmpd, edged, 4
    and             tmpd, 2<<2
    add         ll_maskq, tmpq

    sub            edged, 2<<6
    jge .main_loop
.bottom:
    test           edgeb, 0x20 ; LR_HAVE_BOTTOM_INTEGRATED
    jz .no_bottom_integrated
    jmp .end
.no_bottom_integrated:
    test           edgeb, 0x08 ; LR_HAVE_BOTTOM
    jz .no_bottom
    mov             srcq, [Stk(bot)]
.end:
    call .load_p
    call .load_tb_lr
    add             srcq, strideq
    call .main
    call .load_p
.end2:
    call .main
    RET
.no_bottom:
    mov               t4, t3
    call .main
    mov               t4, t3
    jmp .end2
    RET
%assign call_depth 1
.load_p:
    mova              m0, [srcq+0]
    mova              m1, [srcq+32]
    mova  [BUF_PX(0, 2)], m0
    mova  [BUF_PX(32,2)], m1
    ret
.load_tb_lr:
    test           edgeb, 0x01 ; LR_HAVE_LEFT
    jz .load_p_lr_no_left
    mov             tmpd, [srcq-4]
    mov   [BUF_PX(-4,2)], tmpd
    jmp .load_p_lr_right
.load_p_lr:
    test           edgeb, 0x01 ; LR_HAVE_LEFT
    jz .load_p_lr_no_left
    movzx           tmpd, word [leftq]
    add            leftq, 2
    mov   [BUF_PX(-2,2)], tmpw
    jmp .load_p_lr_right
.load_p_lr_no_left:
    vpbroadcastb     xm0, xm0
    movd  [BUF_PX(-4,2)], xm0
.load_p_lr_right:
    test           edgeb, 0x02 ; LR_HAVE_RIGHT
    jz .load_p_lr_no_right
    mov             tmpd, [srcq+64]
    mov   [BUF_PX(64,2)], tmpd
    ret
.load_p_lr_no_right:
    mov             tmpd, [Stk(w)]
    vpbroadcastb     xm0, [srcq+tmpq-1]
    movd [BUF_PX(0,2)+tmpq], xm0
    ret
.main:
    ; Min (right), max (mid), range (left) for preventing overflow.
    ;     -2  -1   0   1   2       -2  -1   0   1   2       -2  -1   0   1   2
    ;    ┌───┬───┬───┬───┬───┐    ┌───┬───┬───┬───┬───┐    ┌───┬───┬───┬───┬───┐
    ; -2 │   │   │-16│   │   │ -2 │   │   │ 15│   │   │ -2 │   │   │ 31│   │   │
    ; -1 │   │-14│-24│-14│   │ -1 │   │ 17│ 39│ 17│   │ -1 │   │ 31│ 63│ 31│   │
    ; -0 │-16│-24│   │-24│-16│ -0 │ 15│ 39│   │ 39│ 15│ -0 │ 31│ 63│   │ 63│ 31│
    ;  1 │   │-14│-24│-14│   │  1 │   │ 17│ 39│ 17│   │  1 │   │ 31│ 63│ 31│   │
    ;  2 │   │   │-16│   │   │  2 │   │   │ 15│   │   │  2 │   │   │ 31│   │   │
    ;    └───┴───┴───┴───┴───┘    └───┴───┴───┴───┴───┘    └───┴───┴───┴───┴───┘
    ; Accumulate in two groups (A and B) before accumulating to 32 bits:
    ;     -2  -1   0   1   2
    ;    ┌───┬───┬───┬───┬───┐
    ; -2 │   │   │ A2│   │   │
    ; -1 │   │ A0│ A0│ A2│   │
    ; -0 │ A1│ A1│   │ B0│ B0│
    ;  1 │   │ B2│ B1│ B1│   │
    ;  2 │   │   │ B2│   │   │
    ;    └───┴───┴───┴───┴───┘
    ; A0 + A1 and B0 + B1 are accumulated as horz adjacent pairs before
    ; unpacking even and odd pairs and adding to A2 and B2 respectively.

    ; A0
    movu              m0, [BUF_PX(-1, -1)]
    mova              m1, [BUF_PX( 0, -1)]
    ; m0:  0,  2,  4,  6,  8, 10, 12, 14 | 16, 18, 20, 22, 24, 26, 28,
    ; m1:  1,  3,  5,  7,  9, 11, 13, 15 |
    REPX {pmaddubsw x, m12}, m0, m1
    REPX {psubw x, m9}, m0, m1
    ; A1
    movu              m2, [BUF_PX(-2, 0)]
    movu              m3, [BUF_PX(-1, 0)]
    REPX {pmaddubsw x, m13}, m2, m3
    paddw             m0, m2
    paddw             m1, m3
    punpckhwd         m4, m0, m1
    punpcklwd         m0, m1
    ; m0: 0,  1,  2,  3,  4,  5,  6,  7 | 16, 17, 18, 19, 20, 21, 22, 23
    ; m1: 8,  9, 10, 11, 12, 13, 14, 15 | 24, 25, 26, 27, 28, 29, 30, 31
    SWAP 4, 1
    ; A2
    mova              m3, [BUF_PX(0, -2)]
    movu              m4, [BUF_PX(1, -1)]
    punpcklbw         m2, m3, m4
    punpckhbw         m3, m4
    REPX {pmaddubsw x, m11}, m2, m3
    paddw             m0, m2
    paddw             m1, m3

    ; B0
    movu              m2, [BUF_PX(1, 0)]
    movu              m3, [BUF_PX(2, 0)]
    REPX {pmaddubsw x, m14}, m2, m3
    REPX {psubw x, m9}, m2, m3
    ; B1
    mova              m4, [BUF_PX(0, 1)]
    movu              m5, [BUF_PX(1, 1)]
    REPX {pmaddubsw x, m15}, m4, m5
    paddw             m2, m4
    paddw             m3, m5
    punpckhwd         m4, m2, m3
    punpcklwd         m2, m3
    SWAP 4, 3
    ; B2
    mova              m5, [BUF_PX( 0, 2)]
    movu              m6, [BUF_PX(-1, 1)]
    punpcklbw         m4, m5, m6
    punpckhbw         m5, m6
    REPX {pmaddubsw x, m11}, m4, m5
    paddw             m2, m4
    paddw             m3, m5

    ; Accumulate to 32 bits
    punpckhwd         m4, m0, m2
    punpcklwd         m0, m2
    punpckhwd         m2, m1, m3
    punpcklwd         m1, m3
    pcmpeqb           m8, m8
    REPX {pmaddwd x, m8}, m4, m0, m2, m1
    ; m0:  0,  1,  2,  3 | 16, 17, 18, 19
    ; m1:  4,  5,  6,  7 | 20, 21, 22, 23
    ; m2:  8,  9, 10, 11 | 24, 25, 26, 27
    ; m3: 12, 13, 14, 15 | 16, 17, 18, 19
    SWAP 3, 2, 1, 4

    ; Add luma and center tap
    mova              m8, [BUF_PX(0, 0)]
    pxor              m4, m4
    punpcklbw         m5, m8, m4
    mova             xm6, [lumaq+ 0]
    vinserti128       m6, [lumaq+32], 1
    mova             xm7, [lumaq+16]
    vinserti128       m7, [lumaq+48], 1
    punpcklwd         m4, m5, m6
    punpckhwd         m5, m6
    REPX {pmaddwd x, m10}, m4, m5
    psubd             m4, m0
    psubd             m5, m1
    pxor              m6, m6
    punpckhbw         m6, m8, m6
    punpckhwd         m1, m6, m7
    punpcklwd         m6, m7
    REPX {pmaddwd x, m10}, m6, m1
    psubd             m6, m2
    psubd             m7, m1, m3
    vpbroadcastd      m0, [pw_256]
    packssdw          m4, m5
    packssdw          m6, m7
    REPX {pmulhrsw x, m0}, m4, m6
    ; Undo offset applied to prevent overflows
    vpbroadcastd      m0, [pw_64]
    REPX {paddw x, m0}, m4, m6
    packuswb          m4, m6

    vpbroadcastb      m0, [ll_maskq]
    mova              m1, [pd_mask]
    pand              m0, m1
    pcmpeqd           m0, m1
    vblendvps         m4, m8, m0
    mova            [pq], m4

    inc         ll_maskq
    add            lumaq, 64
    REPX {add x, 32}, pq, t0, t1, t2, t3, t4
    add               wd, 32
    jl .main
    mov               wq, w_bakq
    dec         ll_maskq
    and         ll_maskq, ~1
    ; undo column increment and advance by a row
    add               pq, wq
    add               pq, strideq
    mov             tmpq, t0
    lea               t0, [t1 + wq]
    lea               t1, [t2 + wq]
    lea               t2, [t3 + wq]
    lea               t3, [t4 + wq]
    lea               t4, [tmpq + wq]
    lea            lumaq, [lumaq + 2 * wq + 128]
    ret

struc WienerUVLumaStk
    .row_buf: resb 96*5 + 32
    .bot:     resq 1
    .w:       resd 1
endstruc

%define Stk(off) (rsp + call_depth*gprsize + WienerUVLumaStk. %+ off)

DECLARE_REG_TMP 9, 11, 5, 4, 6

cglobal wiener_uv_luma_420_8bpc, 8, 15, 16, \
                                 0 - ((WienerUVLumaStk_size + 31) & ~31), \
                                 dst, luma, stride, left, top, bot, filter, \
                                 w, h, ds_flt, edge, _, tmp, bak
%assign call_depth 0
    movifnidn         wd, wm
    movifnidn         hd, hm
    movifnidn    ds_fltd, ds_fltm
    movifnidn      edged, edgem
    mov       [Stk(bot)], botq

    ; load the last few chroma values and the luma filter values
    vbroadcasti128    m0, [filterq+2]
    pinsrd           xm1, xm0, [pb_128], 0 ; 4x128, filters 0-3
    punpckhqdq       xm2, xm0, xm0         ; filters 4-11
    paddb            xm1, xm2
    pxor             xm3, xm3
    psadbw           xm1, xm3
    vpbroadcastb      m9, xm1
    psrlw             m9, 8

    pshufb            m0, [pb_uv_luma_shuf]
    vpbroadcastd     m10, xm0
    mova  [Stk(row_buf)], xm0
    vpbroadcastd     m11, [Stk(row_buf) + 4]
    vpbroadcastd     m12, [Stk(row_buf) + 8]
    vpbroadcastd     m13, [Stk(row_buf) + 12]
    vpermq           m14, m0, q2222
    vpermq           m15, m0, q3333

    lea             tmpq, [wiener_uv_luma_420_8bpc_jmptable]
    movsxd       ds_fltq, [tmpq+ds_fltq*4]
    add          ds_fltq, tmpq
    ; combine h and edge to free up a register
    shl               hd, 6
    lea            edged, [edgeq+hq-(3<<6)]
    DEFINE_ARGS dst, luma, stride, left, top, bot, filter, w, w_bak, ds_flt, \
                edge, _, tmp, bak
    mov         [Stk(w)], wd
    add               wd, 31
    and               wd, ~31
    neg               wq
    mov           w_bakq, wq
    lea               t4, [Stk(row_buf) + 96*2 + 32]
    jmp ds_fltq

%assign call_depth 1
.main:
    ;     -2  -1   0   1   2
    ;    ┌───┬───┬───┬───┬───┐
    ; -2 │   │   │ B0│   │   │
    ; -1 │   │ A0│ A0│ B0│   │
    ; -0 │ A1│ A1│ X │ A2│ A2│
    ;  1 │   │ B1│ A3│ A3│   │
    ;  2 │   │   │ B1│   │   │
    ;    └───┴───┴───┴───┴───┘
    ; A0, A1, X (center tap), A3, A4 are accumulated as horz adjacent pairs
    ; before unpacking even and odd pairs and adding to B0 + B1.
    ; Unlike the other wiener filters, we don't need to worry about overflowing
    ; 16-bit integers.

    ; A0
    movu              m0, [BUF_PX(-1, -1)]
    mova              m1, [BUF_PX( 0, -1)]
    REPX {pmaddubsw x, m11}, m0, m1
    ; A1
    movu              m4, [BUF_PX(-2, 0)]
    movu              m5, [BUF_PX(-1, 0)]
    REPX {pmaddubsw x, m12}, m4, m5
    paddw             m0, m4
    paddw             m1, m5
    ; B0
    mova              m3, [BUF_PX(0, -2)]
    movu              m4, [BUF_PX(1, -1)]
    punpcklbw         m2, m3, m4
    punpckhbw         m3, m4
    REPX {pmaddubsw x, m10}, m2, m3
    ; A2
    movu              m4, [BUF_PX(1, 0)]
    movu              m5, [BUF_PX(2, 0)]
    pmaddubsw         m6, m4, m13
    pmaddubsw         m5, m13
    paddw             m0, m6
    paddw             m1, m5
    ; X (center tap)
    ; reuse (1, 0) load
    mova              m5, [BUF_PX(0, 0)]
    REPX {pmaddubsw x, m9}, m4, m5
    psubw             m1, m4
    psubw             m0, m5
    ; A3
    mova              m4, [BUF_PX(0, 1)]
    movu              m5, [BUF_PX(1, 1)]
    REPX {pmaddubsw x, m14}, m4, m5
    paddw             m0, m4
    paddw             m1, m5
    ; B1
    movu              m5, [BUF_PX(-1, 1)]
    mova              m6, [BUF_PX( 0, 2)]
    punpcklbw         m4, m5, m6
    punpckhbw         m5, m6
    REPX {pmaddubsw x, m15}, m4, m5
    paddw             m2, m4
    paddw             m3, m5

    punpckhwd         m4, m0, m1
    punpcklwd         m0, m1
    paddw             m4, m3
    paddw             m0, m2
    vperm2i128        m1, m0, m4, 0x31
    vinserti128       m0, xm4, 1
    mova          [dstq], m0
    mova     [dstq + 32], m1

    REPX {add x, 32}, t0, t1, t2, t3, t4
    add             dstq, 64
    add               wd, 32
    jl .main
    mov               wq, w_bakq
    mov             tmpq, t0
    lea               t0, [t1 + wq]
    lea               t1, [t2 + wq]
    lea               t2, [t3 + wq]
    lea               t3, [t4 + wq]
    lea               t4, [tmpq + wq]
    lea             dstq, [dstq + 2*wq + 128]
    ret

%macro WIENER_UV_LUMA 1 ; ds_flt
%assign call_depth 0
.ds_flt%1:
%if %1 == 0
    vpbroadcastd      m8, [pb_1]
%else
    vpbroadcastd      m8, [pw_255]
%endif
    call %%load_p
    call %%load_p_lr
    mov               t2, t4
%%top:
    test           edgeb, 0x14 ; LR_HAVE_TOP | LR_HAVE_TOP_INTEGRATED
    jz %%no_top
    mov             bakq, lumaq
    test           edgeb, 0x10 ; LR_HAVE_TOP_INTEGRATED
    jz %%no_top_integrated
    lea               t4, [Stk(row_buf) + 32]
    lea            lumaq, [topq + strideq*2]
    call %%load_p
    lea            lumaq, [lumaq + strideq*2]
    mov               t0, t4
    add               t4, 96
    call %%load_p
    call %%load_tb_lr
    mov               t1, t4
    jmp %%top_done0
%%no_top_integrated:
    lea               t0, [Stk(row_buf) + 32]
    lea            lumaq, [topq]
    sub               t4, 96
    call %%load_p
    mov               t1, t4
%if %1 == 0
    REPX {psraw x, 1}, m3, m4, m5, m6
    packuswb          m3, m4
    packuswb          m5, m6
    REPX {vpermq x, x, q3120}, m3, m5
    mova  [BUF_PX(0,-2)], m3
    mova [BUF_PX(32,-2)], m5
%elif %1 == 1
    packuswb          m3, m4
    packuswb          m5, m6
    REPX {vpermq x, x, q3120}, m3, m5
    mova  [BUF_PX(0,-2)], m3
    mova [BUF_PX(32,-2)], m5
%else ; %1 == 2
    mova  [BUF_PX(0,-2)], m0
    mova [BUF_PX(32,-2)], m1
%endif
    call %%load_tb_lr
    jmp %%top_done0
%%no_top:
    lea               t0, [Stk(row_buf) + 32]
    lea               t1, [Stk(row_buf) + 96 + 32]
    mova              m0, [BUF_PX( 0, 0)]
    mova              m1, [BUF_PX(32, 0)]
    mova  [BUF_PX(0,-2)], m0
    mova [BUF_PX(32,-2)], m1
    mova  [BUF_PX(0,-1)], m0
    mova [BUF_PX(32,-1)], m1
    mov             tmpd, [BUF_PX(-4, 0)]
    mov  [BUF_PX(-4,-1)], tmpd
    mov             tmpd, [BUF_PX(64, 0)]
    mov  [BUF_PX(64,-1)], tmpd
    add               t4, 96
    jmp %%top_done1
%%top_done0:
    add               t4, 96*2
    mov            lumaq, bakq
%%top_done1:
    lea            lumaq, [lumaq + strideq*2]
    call %%load_p
    call %%load_p_lr
    mov               t3, t4
    add               t4, 96
%%main_loop:
    lea            lumaq, [lumaq + strideq*2]
    call %%load_p
    call %%load_p_lr
    call .main
    sub            edged, 1<<6
    jge %%main_loop
%%bottom:
    test           edgeb, 0x20; LR_HAVE_BOTTOM_INTEGRATED
    jz %%no_bottom_integrated
    lea            lumaq, [lumaq + strideq*2]
    call %%load_p
    call %%load_tb_lr
    call .main
    lea            lumaq, [lumaq + strideq*2]
    call %%load_p
    jmp %%end
%%no_bottom_integrated:
    test            edgeb, 0x08; LR_HAVE_BOTTOM
    jz %%no_bottom
    mov             lumaq, [Stk(bot)]
    call %%load_p
    call %%load_tb_lr
    call .main
    add             lumaq, strideq
%if %1 == 0
    pmaddubsw         m0, [lumaq], m8
    pmaddubsw         m1, [lumaq+32], m8
    REPX {psraw x, 1}, m0, m1
    packuswb          m0, m1
    vpermq            m0, m0, q3120
    mova   [BUF_PX(0,2)], m0
    pmaddubsw         m0, [lumaq+64], m8
    pmaddubsw         m1, [lumaq+96], m8
    REPX {psraw x, 1}, m0, m1
    packuswb          m0, m1
    vpermq            m0, m0, q3120
    mova  [BUF_PX(32,2)], m0
%else ; %1 == 1 || %1 == 2
    call .load_p_ds_flt2
%endif
    jmp %%end
%%no_bottom:
    mov                      t4, t3
    call .main
    mov                      t4, t3
%%end:
    call .main
    RET
%assign call_depth 1
%%load_p:
%if %1 == 0
    pmaddubsw         m3, [lumaq], m8
    pmaddubsw         m0, [lumaq+strideq], m8
    pmaddubsw         m4, [lumaq+32], m8
    pmaddubsw         m1, [lumaq+32+strideq], m8
    paddw             m0, m3
    paddw             m1, m4
    REPX {psrlw x, 2}, m0, m1
    packuswb          m0, m1
    vpermq            m0, m0, q3120
    mova   [BUF_PX(0,2)], m0
    pmaddubsw         m5, [lumaq+64], m8
    pmaddubsw         m1, [lumaq+64+strideq], m8
    pmaddubsw         m6, [lumaq+96], m8
    pmaddubsw         m2, [lumaq+96+strideq], m8
    paddw             m1, m5
    paddw             m2, m6
    REPX {psrlw x, 2}, m1, m2
    packuswb          m1, m2
    vpermq            m1, m1, q3120
    mova  [BUF_PX(32,2)], m1
%elif %1 == 1
    pxor              m7, m7
    pand              m3, m8, [lumaq]
    pand              m0, m8, [lumaq+strideq]
    pand              m4, m8, [lumaq+32]
    pand              m1, m8, [lumaq+32+strideq]
    paddw             m0, m3
    paddw             m1, m4
    REPX {psrlw x, 1}, m0, m1
    packuswb          m0, m1
    vpermq            m0, m0, q3120
    mova   [BUF_PX(0,2)], m0
    pand              m5, m8, [lumaq+64]
    pand              m1, m8, [lumaq+64+strideq]
    pand              m6, m8, [lumaq+96]
    pand              m2, m8, [lumaq+96+strideq]
    paddw             m1, m5
    paddw             m2, m6
    REPX {psrlw x, 1}, m1, m2
    packuswb          m1, m2
    vpermq            m1, m1, q3120
    mova   [BUF_PX(32,2)], m1
%else ; %1 == 2
.load_p_ds_flt2:
    pand              m0, m8, [lumaq]
    pand              m1, m8, [lumaq+32]
    packuswb          m0, m1
    vpermq            m0, m0, q3120
    mova   [BUF_PX(0,2)], m0
    pand              m1, m8, [lumaq+64]
    pand              m2, m8, [lumaq+96]
    packuswb          m1, m2
    vpermq            m1, m1, q3120
    mova  [BUF_PX(32,2)], m1
%endif
    ret

%%load_tb_lr:
    test           edgeb, 0x01 ; LR_HAVE_LEFT
    jz %%load_p_lr_no_left
%if %1 == 0
    movq             xm0, [lumaq-8]
    movq             xm1, [lumaq+strideq-8]
    REPX {pmaddubsw x, xm8}, xm0, xm1
%elif %1 == 1
    movq             xm0, [lumaq-8]
    movq             xm1, [lumaq+strideq-8]
    REPX {pand x, xm8}, xm0, xm1
%else ; %1 == 2
    movq             xm0, [lumaq-8]
%endif
    jmp %%store_left

%%load_p_lr_no_left:
    vpbroadcastb     xm0, xm0
    movd  [BUF_PX(-4,2)], xm0
    jmp %%load_p_lr_right
%%load_p_lr:
    test           edgeb, 0x01 ; LR_HAVE_LEFT
    jz %%load_p_lr_no_left
%if %1 == 0
    pmaddubsw        xm0, [leftq], xm8
    add            leftq, 16
    pshufd           xm1, xm0, q3232
%%store_left:
    paddw            xm0, xm1
    psrlw            xm0, 2
%elif %1 == 1
    pand             xm0, [leftq], xm8
    add            leftq, 16
    pshufd           xm1, xm0, q3232
%%store_left:
    paddw            xm0, xm1
    psrlw            xm0, 1
%else ; %1 == 2
    movq             xm0, [leftq]
    add            leftq, 16
%%store_left:
    pand             xm0, xm8
%endif
    packuswb         xm0, xm0
    movd  [BUF_PX(-4,2)], xm0

%%load_p_lr_right:
    test           edgeb, 0x02 ; LR_HAVE_RIGHT
    jz .load_p_lr_no_right
%if %1 == 0
    pmaddubsw        xm0, [lumaq+128], xm8
    pmaddubsw        xm1, [lumaq+strideq+128], xm8
    paddw            xm0, xm1
    psrlw            xm0, 2
%elif %1 == 1
    pand             xm0, [lumaq+128], xm8
    pand             xm1, [lumaq+strideq+128], xm8
    paddw            xm0, xm1
    psraw            xm0, 1
%else ; %1 == 2
    pand             xm0, [lumaq+128], xm8
%endif
    packuswb         xm0, xm0
    movd  [BUF_PX(64,2)], xm0
    ret
%endmacro
WIENER_UV_LUMA 0
WIENER_UV_LUMA 1
WIENER_UV_LUMA 2
.load_p_lr_no_right:
    mov             tmpd, [Stk(w)]
    vpbroadcastb     xm0, [BUF_PX(0,2)+tmpq-1]
    movd [BUF_PX(0,2)+tmpq], xm0
    ret
