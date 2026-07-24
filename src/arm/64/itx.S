/******************************************************************************
 * Copyright © 2026, Arm Limited
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#include "src/arm/asm.S"
#include "util.S"

// For `is_rect2` cases, scale input by `256 / sqrt(2) = 181. Shift by 7 to
// allow use of the SQRDMULH instruction.
#define RECT2_SCALE (181 << 7)

.macro dot1_4rows_s16 op, acc0, acc1, acc2, acc3, a, h, b0, b1, b2, b3, lane0, lane1
        \op             \acc0\().4s,  \a\h, \b0\().h[\lane0]
        \op             \acc1\().4s,  \a\h, \b1\().h[\lane1]
        \op             \acc2\().4s,  \a\h, \b2\().h[\lane0]
        \op             \acc3\().4s,  \a\h, \b3\().h[\lane1]
.endm

// Add four 4x1 values with a shared replication mode and clip for 8bpc.
// Advances dst by 4 * step. have_repx/have_repy indicate whether the
// generated kernel can encounter the corresponding replication case.
.macro iclip_sum4_8bpc_x4 dst, dst_stride, repx_shift, have_repx, repy_shift, have_repy, step, ptr_tmp, a, b, c, d
  .if \have_repy
        cbz             \repy_shift, 4f
    .if \have_repx
        cbz             \repx_shift, 1f
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  \dst, \ptr_tmp, \dst_stride
        zip1            \a\().8h,  \a\().8h,  \a\().8h
        zip1            \b\().8h,  \b\().8h,  \b\().8h
        zip1            \c\().8h,  \c\().8h,  \c\().8h
        zip1            \d\().8h,  \d\().8h,  \d\().8h
        uaddw           v0.8h,   \a\().8h,  v0.8b
        uaddw           v1.8h,   \a\().8h,  v1.8b
        uaddw           v2.8h,   \b\().8h,  v2.8b
        uaddw           v3.8h,   \b\().8h,  v3.8b
        uaddw           v4.8h,   \c\().8h,  v4.8b
        uaddw           v5.8h,   \c\().8h,  v5.8b
        uaddw           v6.8h,   \d\().8h,  v6.8b
        uaddw           v7.8h,   \d\().8h,  v7.8b
        sqxtun          v0.8b,   v0.8h
        sqxtun          v1.8b,   v1.8h
        sqxtun          v2.8b,   v2.8h
        sqxtun          v3.8b,   v3.8h
        sqxtun          v4.8b,   v4.8h
        sqxtun          v5.8b,   v5.8h
        sqxtun          v6.8b,   v6.8h
        sqxtun          v7.8b,   v7.8h
        store_8_strided d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  \dst, \dst, \dst_stride, 1
        b               99f
1:
    .endif
        load_8_strided  s0,  s1,  s2,  s3,  s4,  s5,  s6,  s7,  \dst, \ptr_tmp, \dst_stride
        uaddw           v0.8h,   \a\().8h,  v0.8b
        uaddw           v1.8h,   \a\().8h,  v1.8b
        uaddw           v2.8h,   \b\().8h,  v2.8b
        uaddw           v3.8h,   \b\().8h,  v3.8b
        uaddw           v4.8h,   \c\().8h,  v4.8b
        uaddw           v5.8h,   \c\().8h,  v5.8b
        uaddw           v6.8h,   \d\().8h,  v6.8b
        uaddw           v7.8h,   \d\().8h,  v7.8b
        sqxtun          v0.8b,   v0.8h
        sqxtun          v1.8b,   v1.8h
        sqxtun          v2.8b,   v2.8h
        sqxtun          v3.8b,   v3.8h
        sqxtun          v4.8b,   v4.8h
        sqxtun          v5.8b,   v5.8h
        sqxtun          v6.8b,   v6.8h
        sqxtun          v7.8b,   v7.8h
        store_8_strided s0,  s1,  s2,  s3,  s4,  s5,  s6,  s7,  \dst, \dst, \dst_stride, 1
        b               99f
4:
  .endif
  .if \have_repx
        cbz             \repx_shift, 1f
        load_4_strided  d0,  d1,  d2,  d3,  \dst, \ptr_tmp, \step
        zip1            \a\().8h,  \a\().8h,  \a\().8h
        zip1            \b\().8h,  \b\().8h,  \b\().8h
        zip1            \c\().8h,  \c\().8h,  \c\().8h
        zip1            \d\().8h,  \d\().8h,  \d\().8h
        uaddw           v0.8h,   \a\().8h,  v0.8b
        uaddw           v1.8h,   \b\().8h,  v1.8b
        uaddw           v2.8h,   \c\().8h,  v2.8b
        uaddw           v3.8h,   \d\().8h,  v3.8b
        sqxtun          v0.8b,   v0.8h
        sqxtun          v1.8b,   v1.8h
        sqxtun          v2.8b,   v2.8h
        sqxtun          v3.8b,   v3.8h
        store_4_strided d0,  d1,  d2,  d3,  \dst, \dst, \step, 1
        b               99f
1:
  .endif
        load_4_strided  s0,  s1,  s2,  s3,  \dst, \ptr_tmp, \step
        uaddw           v0.8h,   \a\().8h,  v0.8b
        uaddw           v1.8h,   \b\().8h,  v1.8b
        uaddw           v2.8h,   \c\().8h,  v2.8b
        uaddw           v3.8h,   \d\().8h,  v3.8b
        sqxtun          v0.8b,   v0.8h
        sqxtun          v1.8b,   v1.8h
        sqxtun          v2.8b,   v2.8h
        sqxtun          v3.8b,   v3.8h
        store_4_strided s0,  s1,  s2,  s3,  \dst, \dst, \step, 1
99:
.endm

.macro itx_row_zero_tail_s16 out_ptr, coeff_ptr, stride, out_stride, howmany
        sub             w12, \stride, \howmany
        cbz             w12, 2f
        mul             w12, w12, \out_stride
        lsr             w12, w12, #3
1:
        stp             xzr, xzr, [\out_ptr], #16
        stp             xzr, xzr, [\out_ptr], #16
        subs            w12, w12, #2
        b.ne            1b
2:
        mul             w12, \stride, \out_stride
        lsr             w12, w12, #3
3:
        stp             xzr, xzr, [\coeff_ptr], #16
        subs            w12, w12, #1
        b.ne            3b
.endm


// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany, x7: mat, x8: flip
function inv_dst4_1d_transpose_8bpc_neon
        lsl             x16, x3,  #1
        neg             w11, w4
        lsl             x17, x1,  #1
        dup             v30.4s,  w11  // -shift
        mov             w15, w6

        ldp             q0,  q1,  [x7]

        mov             w12, #RECT2_SCALE
        dup             v31.8h,  w12
        cmp             w6,  #4
        b.eq            L(dst4_transpose_tail)
L(dst4_transpose_loop8):
        load_4_strided  q4,  q5,  q6,  q7,  x2,  x13, x16, 0
        cbz             w5,  1f
        sqrdmulh        v4.8h,   v4.8h,   v31.8h
        sqrdmulh        v5.8h,   v5.8h,   v31.8h
        sqrdmulh        v6.8h,   v6.8h,   v31.8h
        sqrdmulh        v7.8h,   v7.8h,   v31.8h
1:

        dot1_4rows_s16  smull,  v16, v17, v18, v19, v4,  .4h, v0,  v0,  v1,  v1,  0, 4
        dot1_4rows_s16  smull2, v20, v21, v22, v23, v4,  .8h, v0,  v0,  v1,  v1,  0, 4
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v5,  .4h, v0,  v0,  v1,  v1,  1, 5
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v5,  .8h, v0,  v0,  v1,  v1,  1, 5
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v6,  .4h, v0,  v0,  v1,  v1,  2, 6
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v6,  .8h, v0,  v0,  v1,  v1,  2, 6
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v7,  .4h, v0,  v0,  v1,  v1,  3, 7
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v7,  .8h, v0,  v0,  v1,  v1,  3, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v30

        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v24, v25, v26, v27
        store_4_strided d16, d17, d18, d19, x0,  x13, x17, 0

        transpose_4x4h  v20, v21, v22, v23, v20, v21, v22, v23, v24, v25, v26, v27
        add             x13, x0,  x1,  lsl #3
        store_4_strided d20, d21, d22, d23, x13, x13, x17, 0

        add             x2,  x2,  #16
        add             x0,  x0,  x1,  lsl #4
        subs            w6,  w6,  #8
        b.eq            L(dst4_transpose_done)
        cmp             w6,  #4
        b.ne            L(dst4_transpose_loop8)
L(dst4_transpose_tail):
        load_4_strided  d4,  d5,  d6,  d7,  x2,  x13, x16, 0
        cbz             w5,  1f
        sqrdmulh        v4.4h,   v4.4h,   v31.4h
        sqrdmulh        v5.4h,   v5.4h,   v31.4h
        sqrdmulh        v6.4h,   v6.4h,   v31.4h
        sqrdmulh        v7.4h,   v7.4h,   v31.4h
1:

        dot1_4rows_s16  smull, v16, v17, v18, v19, v4,  .4h, v0,  v0,  v1,  v1,  0, 4
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v5,  .4h, v0,  v0,  v1,  v1,  1, 5
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v6,  .4h, v0,  v0,  v1,  v1,  2, 6
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v7,  .4h, v0,  v0,  v1,  v1,  3, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30

        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v24, v25, v26, v27

        store_4_strided d16, d17, d18, d19, x0,  x13, x17, 0
        add             x2,  x2,  #8
        add             x0,  x0,  x1,  lsl #3
L(dst4_transpose_done):
        sub             x11, x2,  x15, lsl #1
        itx_row_zero_tail_s16 x0, x11, w3, w1, w15
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: repx_shift, x5: repy_shift,
// x6: howmany, x7: mat, x8: unused, x9: shift
function inv_dst4_1d_8bpc_neon
        lsl             x3,  x3,  #1
        neg             w9,  w9
        dup             v31.4s,  w9  // -shift

        mov             w14, #4
        mov             w15, #0
        lsl             w14, w14, w4  // (4 << repx_shift)
        mov             w17, #0
        cmp             w6,  #4
        b.eq            L(dst4_tail)
        sub             w16, w6,  #4
L(dst4_loop8):
        add             x11, x0,  x17
        add             x13, x2,  x15, lsl #1
        add             x12, x11, x14
        load_4_strided  q4,  q5,  q6,  q7,  x13, x13, x3
        ldp             q0,  q1,  [x7]

        dot1_4rows_s16  smull,  v16, v17, v18, v19, v4,  .4h, v0,  v0,  v1,  v1,  0, 4
        dot1_4rows_s16  smull2, v20, v21, v22, v23, v4,  .8h, v0,  v0,  v1,  v1,  0, 4
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v5,  .4h, v0,  v0,  v1,  v1,  1, 5
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v5,  .8h, v0,  v0,  v1,  v1,  1, 5
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v6,  .4h, v0,  v0,  v1,  v1,  2, 6
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v6,  .8h, v0,  v0,  v1,  v1,  2, 6
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v7,  .4h, v0,  v0,  v1,  v1,  3, 7
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v7,  .8h, v0,  v0,  v1,  v1,  3, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v31
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v31

        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x9,  v16, v17, v18, v19
        iclip_sum4_8bpc_x4 x12, x1,  w4,  1, w5,  0, x1,  x9,  v20, v21, v22, v23

        add             w15, w15, #8
        add             w17, w17, w14, lsl #1
        cmp             w15, w16
        b.lt            L(dst4_loop8)
        cmp             w15, w6
        b.eq            L(dst4_done)
L(dst4_tail):
        add             x13, x2,  x15, lsl #1
        add             x11, x0,  x17
        load_4_strided  d4,  d5,  d6,  d7,  x13, x13, x3
        ldp             q0,  q1,  [x7]

        dot1_4rows_s16  smull, v16, v17, v18, v19, v4,  .4h, v0,  v0,  v1,  v1,  0, 4
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v5,  .4h, v0,  v0,  v1,  v1,  1, 5
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v6,  .4h, v0,  v0,  v1,  v1,  2, 6
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v7,  .4h, v0,  v0,  v1,  v1,  3, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v31

        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x9,  v16, v17, v18, v19
L(dst4_done):
        ret
endfunc


.macro scale_inplace_s16_x4 do_scale, c, stride, rows, scale
        cbz             \do_scale, 99f
        mov             x12, \c
        mov             x13, \c
  .rept \rows / 4
        load_4_strided  d0,  d1,  d2,  d3,  x12, x12, \stride, 1
        sqrdmulh        v0.4h,   v0.4h,   \scale\().4h
        sqrdmulh        v1.4h,   v1.4h,   \scale\().4h
        sqrdmulh        v2.4h,   v2.4h,   \scale\().4h
        sqrdmulh        v3.4h,   v3.4h,   \scale\().4h
        store_4_strided d0,  d1,  d2,  d3,  x13, x13, \stride, 1
  .endr
99:
.endm

.macro scale_inplace_s16_x8 do_scale, c, stride, rows, scale
        cbz             \do_scale, 99f
        mov             x12, \c
        mov             x13, \c
  .rept \rows / 4
        load_4_strided  q0,  q1,  q2,  q3,  x12, x12, \stride, 1
        sqrdmulh        v0.8h,   v0.8h,   \scale\().8h
        sqrdmulh        v1.8h,   v1.8h,   \scale\().8h
        sqrdmulh        v2.8h,   v2.8h,   \scale\().8h
        sqrdmulh        v3.8h,   v3.8h,   \scale\().8h
        store_4_strided q0,  q1,  q2,  q3,  x13, x13, \stride, 1
  .endr
99:
.endm

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany, x7: mat, x8: flip
function inv_dst8_1d_transpose_8bpc_neon
        lsl             x10, x3,  #1
        neg             w11, w4
        lsl             x16, x1,  #1
        dup             v30.4s,  w11  // -shift
        mov             w15, w6

        mov             x11, #16
        cmp             w8,  #0
        cneg            x11, x11, ne  // (flip ? -16 : 16)

        mov             w12, #RECT2_SCALE
        dup             v31.8h,  w12
        cmp             w6,  #4
        b.eq            L(dst8_transpose_tail)
L(dst8_transpose_loop8):
        scale_inplace_s16_x8 w5,  x2,  x10, 8,  v31
        add             x17, x7,  x8,  lsl #4
        mov             x9,  #0
L(dst8_row_loop8):
        load_4_strided  q0,  q1,  q2,  q3,  x17, x17, x11, 1

        load_8_strided  q4,  q5,  q6,  q7,  q24, q25, q26, q27, x2,  x13, x10, 0

        dot1_4rows_s16  smull,  v16, v17, v18, v19, v4,  .4h, v0,  v1,  v2,  v3,  0, 0
        dot1_4rows_s16  smull2, v20, v21, v22, v23, v4,  .8h, v0,  v1,  v2,  v3,  0, 0
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v5,  .4h, v0,  v1,  v2,  v3,  1, 1
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v5,  .8h, v0,  v1,  v2,  v3,  1, 1
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v6,  .4h, v0,  v1,  v2,  v3,  2, 2
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v6,  .8h, v0,  v1,  v2,  v3,  2, 2
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v7,  .4h, v0,  v1,  v2,  v3,  3, 3
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v7,  .8h, v0,  v1,  v2,  v3,  3, 3
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v24, .4h, v0,  v1,  v2,  v3,  4, 4
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v24, .8h, v0,  v1,  v2,  v3,  4, 4
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v25, .4h, v0,  v1,  v2,  v3,  5, 5
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v25, .8h, v0,  v1,  v2,  v3,  5, 5
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v26, .4h, v0,  v1,  v2,  v3,  6, 6
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v26, .8h, v0,  v1,  v2,  v3,  6, 6
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v27, .4h, v0,  v1,  v2,  v3,  7, 7
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v27, .8h, v0,  v1,  v2,  v3,  7, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v30

        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v24, v25, v26, v27

        add             x13, x0,  x9,  lsl #1
        store_4_strided d16, d17, d18, d19, x13, x13, x16

        transpose_4x4h  v20, v21, v22, v23, v20, v21, v22, v23, v24, v25, v26, v27

        add             x13, x0,  x1,  lsl #3
        add             x13, x13, x9,  lsl #1
        store_4_strided d20, d21, d22, d23, x13, x13, x16

        add             x9,  x9,  #4
        cmp             x9,  #8
        b.lt            L(dst8_row_loop8)
        add             x2,  x2,  #16
        add             x0,  x0,  x1,  lsl #4
        subs            w6,  w6,  #8
        b.eq            L(dst8_transpose_done)
        cmp             w6,  #4
        b.ne            L(dst8_transpose_loop8)
L(dst8_transpose_tail):
        scale_inplace_s16_x4 w5,  x2,  x10, 8,  v31
        add             x17, x7,  x8,  lsl #4
        mov             x9,  #0
L(dst8_row_tail_loop):
        load_4_strided  q0,  q1,  q2,  q3,  x17, x17, x11, 1

        load_8_strided  d4,  d5,  d6,  d7,  d24, d25, d26, d27, x2,  x13, x10, 0

        dot1_4rows_s16  smull, v16, v17, v18, v19, v4,  .4h, v0,  v1,  v2,  v3,  0, 0
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v5,  .4h, v0,  v1,  v2,  v3,  1, 1
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v6,  .4h, v0,  v1,  v2,  v3,  2, 2
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v7,  .4h, v0,  v1,  v2,  v3,  3, 3
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v24, .4h, v0,  v1,  v2,  v3,  4, 4
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v25, .4h, v0,  v1,  v2,  v3,  5, 5
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v26, .4h, v0,  v1,  v2,  v3,  6, 6
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v27, .4h, v0,  v1,  v2,  v3,  7, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30

        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v24, v25, v26, v27

        add             x13, x0,  x9,  lsl #1
        store_4_strided d16, d17, d18, d19, x13, x13, x16

        add             x9,  x9,  #4
        cmp             x9,  #8
        b.lt            L(dst8_row_tail_loop)
        add             x2,  x2,  #8
        add             x0,  x0,  x1,  lsl #3
L(dst8_transpose_done):
        sub             x11, x2,  x15, lsl #1
        itx_row_zero_tail_s16 x0, x11, w3, w1, w15
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: repx_shift, x5: repy_shift,
// x6: howmany, x7: mat, x8: flip, x9: shift
function inv_dst8_1d_8bpc_neon
        AARCH64_SIGN_LINK_REGISTER
        stp             x29, x30, [sp, #-96]!
        mov             x29, sp
        stp             x19, x20, [x29, #80]
        stp             d8,  d9,  [x29, #16]
        stp             d10, d11, [x29, #32]
        stp             d12, d13, [x29, #48]
        stp             d14, d15, [x29, #64]
        neg             w9,  w9
        lsl             x3,  x3,  #1
        dup             v30.4s,  w9  // -shift
        mov             x20, #16
        cmp             x8,  #0
        cneg            x20, x20, ne  // (flip ? -16 : 16)

        mov             w15, #0
        mov             w16, #4
        mov             w19, #0
        lsl             w16, w16, w4  // (4 << repx_shift)
        cmp             w6,  #4
        b.eq            L(dst8_tail)
L(dst8_loop8):
        add             x11, x0,  x15
        add             x17, x7,  x8,  lsl #4
        add             x12, x11, x16

        mov             x9,  #0
L(dst8_i_loop):
        load_4_strided  q8,  q9,  q10, q11, x17, x17, x20, 1

        add             x13, x2,  x19, lsl #1
        load_8_strided  q0,  q1,  q2,  q3,  q4,  q5,  q6,  q7,  x13, x13, x3

        dot1_4rows_s16  smull,  v16, v17, v18, v19, v0,  .4h, v8,  v9,  v10, v11, 0, 0
        dot1_4rows_s16  smull2, v20, v21, v22, v23, v0,  .8h, v8,  v9,  v10, v11, 0, 0
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v1,  .4h, v8,  v9,  v10, v11, 1, 1
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v1,  .8h, v8,  v9,  v10, v11, 1, 1
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v2,  .4h, v8,  v9,  v10, v11, 2, 2
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v2,  .8h, v8,  v9,  v10, v11, 2, 2
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v3,  .4h, v8,  v9,  v10, v11, 3, 3
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v3,  .8h, v8,  v9,  v10, v11, 3, 3
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v4,  .4h, v8,  v9,  v10, v11, 4, 4
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v4,  .8h, v8,  v9,  v10, v11, 4, 4
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v5,  .4h, v8,  v9,  v10, v11, 5, 5
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v5,  .8h, v8,  v9,  v10, v11, 5, 5
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v6,  .4h, v8,  v9,  v10, v11, 6, 6
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v6,  .8h, v8,  v9,  v10, v11, 6, 6
        dot1_4rows_s16  smlal,  v16, v17, v18, v19, v7,  .4h, v8,  v9,  v10, v11, 7, 7
        dot1_4rows_s16  smlal2, v20, v21, v22, v23, v7,  .8h, v8,  v9,  v10, v11, 7, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v30

        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x14, v16, v17, v18, v19
        iclip_sum4_8bpc_x4 x12, x1,  w4,  1, w5,  0, x1,  x14, v20, v21, v22, v23

        add             x9,  x9,  #4
        cmp             x9,  #8
        b.lt            L(dst8_i_loop)

        add             w19, w19, #8
        add             w15, w15, w16, lsl #1
        add             w14, w19, #4
        cmp             w14, w6
        b.lt            L(dst8_loop8)
        cmp             w19, w6
        b.eq            L(dst8_done)
L(dst8_tail):
        add             x13, x2,  x19, lsl #1
        add             x11, x0,  x15
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x13, x13, x3

        add             x14, x7,  x8,  lsl #4
        load_4_strided  q8,  q9,  q10, q11, x14, x14, x20

        add             x14, x14, x20, lsl #1
        load_4_strided  q12, q13, q14, q15, x14, x14, x20

        dot1_4rows_s16  smull, v16, v17, v18, v19, v0,  .4h, v8,  v9,  v10, v11, 0, 0
        dot1_4rows_s16  smull, v20, v21, v22, v23, v0,  .4h, v12, v13, v14, v15, 0, 0
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v1,  .4h, v8,  v9,  v10, v11, 1, 1
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v1,  .4h, v12, v13, v14, v15, 1, 1
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v2,  .4h, v8,  v9,  v10, v11, 2, 2
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v2,  .4h, v12, v13, v14, v15, 2, 2
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v3,  .4h, v8,  v9,  v10, v11, 3, 3
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v3,  .4h, v12, v13, v14, v15, 3, 3
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v4,  .4h, v8,  v9,  v10, v11, 4, 4
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v4,  .4h, v12, v13, v14, v15, 4, 4
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v5,  .4h, v8,  v9,  v10, v11, 5, 5
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v5,  .4h, v12, v13, v14, v15, 5, 5
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v6,  .4h, v8,  v9,  v10, v11, 6, 6
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v6,  .4h, v12, v13, v14, v15, 6, 6
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v7,  .4h, v8,  v9,  v10, v11, 7, 7
        dot1_4rows_s16  smlal, v20, v21, v22, v23, v7,  .4h, v12, v13, v14, v15, 7, 7

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v30

        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x14, v16, v17, v18, v19
        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x14, v20, v21, v22, v23
L(dst8_done):
        ldp             x19, x20, [x29, #80]
        ldp             d14, d15, [x29, #64]
        ldp             d12, d13, [x29, #48]
        ldp             d10, d11, [x29, #32]
        ldp             d8,  d9,  [x29, #16]
        ldp             x29, x30, [sp], #96
        AARCH64_VALIDATE_LINK_REGISTER
        ret
endfunc


.macro dot16_4rows_s16_body first_op, op, h, acc0, acc1, acc2, acc3
        dot1_4rows_s16  \first_op, \acc0, \acc1, \acc2, \acc3, v4,  \h, v0,  v1,  v2,  v3,  0, 0
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v5,  \h, v0,  v1,  v2,  v3,  1, 1
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v6,  \h, v0,  v1,  v2,  v3,  2, 2
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v7,  \h, v0,  v1,  v2,  v3,  3, 3
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v24, \h, v0,  v1,  v2,  v3,  4, 4
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v25, \h, v0,  v1,  v2,  v3,  5, 5
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v26, \h, v0,  v1,  v2,  v3,  6, 6
        dot1_4rows_s16  \op,       \acc0, \acc1, \acc2, \acc3, v27, \h, v0,  v1,  v2,  v3,  7, 7
.endm

// x13: input base (advanced by 16 rows), stride: byte stride,
// x14: row-0 coefficients, row_step: byte distance between coefficient rows
// returns 4 raw 16-point dot products in v16-v19
.macro dot16_4rows_s16_x4 first_op, stride, row_step
        load_4_strided  q0,  q1,  q2,  q3,  x14, x12, \row_step, 0

        load_8_strided  d4,  d5,  d6,  d7,  d24, d25, d26, d27, x13, x13, \stride, 1
        dot16_4rows_s16_body \first_op, smlal, .4h, v16, v17, v18, v19

        add             x12, x14, #16
        load_4_strided  q0,  q1,  q2,  q3,  x12, x12, \row_step

        load_8_strided  d4,  d5,  d6,  d7,  d24, d25, d26, d27, x13, x13, \stride, 1
        dot16_4rows_s16_body smlal, smlal, .4h, v16, v17, v18, v19
        add             x14, x14, #32
.endm

// x13: input base (advanced by 16 rows), stride: byte stride,
// x14: row-0 coefficients, row_step: byte distance between coefficient rows
// returns low-half dots in v16-v19 and high-half dots in v20-v23
.macro dot16_4rows_s16_x8 first_op_lo, first_op_hi, stride, row_step
        load_4_strided  q0,  q1,  q2,  q3,  x14, x12, \row_step, 0

        load_8_strided  q4,  q5,  q6,  q7,  q24, q25, q26, q27, x13, x13, \stride, 1
        dot16_4rows_s16_body \first_op_lo, smlal,  .4h, v16, v17, v18, v19
        dot16_4rows_s16_body \first_op_hi, smlal2, .8h, v20, v21, v22, v23

        add             x12, x14, #16
        load_4_strided  q0,  q1,  q2,  q3,  x12, x12, \row_step

        load_8_strided  q4,  q5,  q6,  q7,  q24, q25, q26, q27, x13, x13, \stride, 1
        dot16_4rows_s16_body smlal,  smlal,  .4h, v16, v17, v18, v19
        dot16_4rows_s16_body smlal2, smlal2, .8h, v20, v21, v22, v23
        add             x14, x14, #32
.endm

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany, x7: mat, x8: flip
function inv_dst16_1d_transpose_8bpc_neon
        lsl             x16, x3,  #1
        neg             w11, w4
        lsl             x17, x1,  #1
        dup             v30.4s,  w11  // -shift
        mov             w15, w6

        mov             x10, #32
        cmp             w8,  #0
        cneg            x10, x10, ne  // (flip ? -32 : 32)

        mov             w12, #RECT2_SCALE
        dup             v31.8h,  w12
        cmp             w6,  #4
        b.eq            L(dst16_transpose_tail)
L(dst16_transpose_loop8):
        scale_inplace_s16_x8 w5,  x2,  x16, 16, v31
        mov             x9,  #0
        add             x11, x7,  x8,  lsl #5
L(dst16_row_loop8):
        mov             x13, x2
        mov             x14, x11
        add             x11, x11, x10, lsl #2
        dot16_4rows_s16_x8 smull, smull2, x16, x10

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v30

        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v24, v25, v26, v27

        add             x13, x0,  x9,  lsl #1
        store_4_strided d16, d17, d18, d19, x13, x13, x17

        transpose_4x4h  v20, v21, v22, v23, v20, v21, v22, v23, v24, v25, v26, v27

        add             x13, x0,  x1,  lsl #3
        add             x13, x13, x9,  lsl #1
        store_4_strided d20, d21, d22, d23, x13, x13, x17

        add             x9,  x9,  #4
        cmp             x9,  #16
        b.lt            L(dst16_row_loop8)
        add             x2,  x2,  #16
        add             x0,  x0,  x1,  lsl #4
        subs            w6,  w6,  #8
        b.eq            L(dst16_transpose_done)
        cmp             w6,  #4
        b.ne            L(dst16_transpose_loop8)
L(dst16_transpose_tail):
        scale_inplace_s16_x4 w5,  x2,  x16, 16, v31
        mov             x9,  #0
        add             x11, x7,  x8,  lsl #5
L(dst16_row_tail_loop):
        mov             x13, x2
        mov             x14, x11
        add             x11, x11, x10, lsl #2
        dot16_4rows_s16_x4 smull, x16, x10

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30

        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v24, v25, v26, v27

        add             x13, x0,  x9,  lsl #1
        store_4_strided d16, d17, d18, d19, x13, x13, x17

        add             x9,  x9,  #4
        cmp             x9,  #16
        b.lt            L(dst16_row_tail_loop)
        add             x2,  x2,  #8
        add             x0,  x0,  x1,  lsl #3
L(dst16_transpose_done):
        sub             x11, x2,  x15, lsl #1
        itx_row_zero_tail_s16 x0, x11, w3, w1, w15
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: repx_shift, x5: repy_shift,
// x6: howmany, x7: mat, x8: flip, x9: shift
function inv_dst16_1d_8bpc_neon
        neg             w9,  w9
        lsl             x3,  x3,  #1
        dup             v30.4s,  w9  // -shift
        mov             x17, #32
        cmp             x8,  #0
        cneg            x17, x17, ne  // (flip ? -32 : 32)
        mov             w16, #4
        lsl             w16, w16, w4  // (4 << repx_shift)
        cmp             w6,  #4
        b.eq            L(dst16_tail)
L(dst16_loop8):
        mov             x11, x0
        add             x15, x0,  x16
        add             x14, x7,  x8,  lsl #5

        mov             x9,  #0
L(dst16_i_loop):
        load_4_strided  q0,  q1,  q2,  q3,  x14, x12, x17, 0

        mov             x13, x2
        load_8_strided  q4,  q5,  q6,  q7,  q24, q25, q26, q27, x13, x13, x3,  1
        dot16_4rows_s16_body smull,  smlal,  .4h, v16, v17, v18, v19
        dot16_4rows_s16_body smull2, smlal2, .8h, v20, v21, v22, v23

        add             x12, x14, #16
        load_4_strided  q0,  q1,  q2,  q3,  x12, x12, x17

        load_8_strided  q4,  q5,  q6,  q7,  q24, q25, q26, q27, x13, x13, x3
        dot16_4rows_s16_body smlal,  smlal,  .4h, v16, v17, v18, v19
        dot16_4rows_s16_body smlal2, smlal2, .8h, v20, v21, v22, v23

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30
        shift_and_narrow_4x4s v20, v21, v22, v23, v20, v21, v22, v23, v30

        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x13, v16, v17, v18, v19
        iclip_sum4_8bpc_x4 x15, x1,  w4,  1, w5,  0, x1,  x13, v20, v21, v22, v23

        add             x9,  x9,  #4
        add             x14, x14, x17, lsl #2
        cmp             x9,  #16
        b.lt            L(dst16_i_loop)

        add             x0,  x0,  x16, lsl #1
        add             x2,  x2,  #16
        subs            w6,  w6,  #8
        b.eq            L(dst16_done)
        cmp             w6,  #4
        b.ne            L(dst16_loop8)
L(dst16_tail):
        mov             x11, x0

        mov             x9,  #0
        add             x14, x7,  x8,  lsl #5
L(dst16_tail_i_loop):
        load_4_strided  q0,  q1,  q2,  q3,  x14, x12, x17, 0

        mov             x13, x2
        load_8_strided  d4,  d5,  d6,  d7,  d24, d25, d26, d27, x13, x13, x3,  1
        dot16_4rows_s16_body smull, smlal, .4h, v16, v17, v18, v19

        add             x12, x14, #16
        load_4_strided  q0,  q1,  q2,  q3,  x12, x12, x17

        load_8_strided  d4,  d5,  d6,  d7,  d24, d25, d26, d27, x13, x13, x3
        dot16_4rows_s16_body smlal, smlal, .4h, v16, v17, v18, v19

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v30

        iclip_sum4_8bpc_x4 x11, x1,  w4,  1, w5,  0, x1,  x13, v16, v17, v18, v19

        add             x9,  x9,  #4
        add             x14, x14, x17, lsl #2
        cmp             x9,  #16
        b.lt            L(dst16_tail_i_loop)
L(dst16_done):
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
.macro inv_dst_row_wrapper_s16 name, coeffs, flip, target
function \name, export=1
        movrel          x7,  \coeffs
        mov             w8,  #\flip
        b               \target
endfunc
.endm

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
.macro inv_dst_col_wrapper_s16 name, size_shift, coeffs, flip, target
function \name, export=1
        mov             w9,  w6
        lsr             w4,  w4,  #6
        lsr             w5,  w5,  #(\size_shift + 1)
        mov             w6,  w7
        movrel          x7,  \coeffs
        mov             x8,  #\flip
        b               \target
endfunc
.endm

inv_dst_row_wrapper_s16 inv_adst4_1d_row_8bpc_neon, adst4_coeffs_s16, 0, inv_dst4_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_adst4_1d_col_8bpc_neon, 2, adst4_coeffs_s16, 0, inv_dst4_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_flipadst4_1d_row_8bpc_neon, flipadst4_coeffs_s16, 0, inv_dst4_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_flipadst4_1d_col_8bpc_neon, 2, flipadst4_coeffs_s16, 0, inv_dst4_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_adst8_1d_row_8bpc_neon, adst8_coeffs_s16, 0, inv_dst8_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_adst8_1d_col_8bpc_neon, 3, adst8_coeffs_s16, 0, inv_dst8_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_flipadst8_1d_row_8bpc_neon, adst8_coeffs_s16, 7, inv_dst8_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_flipadst8_1d_col_8bpc_neon, 3, adst8_coeffs_s16, 7, inv_dst8_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_ddt8_1d_row_8bpc_neon, ddt8_coeffs_s16, 0, inv_dst8_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_ddt8_1d_col_8bpc_neon, 3, ddt8_coeffs_s16, 0, inv_dst8_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_flipddt8_1d_row_8bpc_neon, ddt8_coeffs_s16, 7, inv_dst8_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_flipddt8_1d_col_8bpc_neon, 3, ddt8_coeffs_s16, 7, inv_dst8_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_adst16_1d_row_8bpc_neon, adst16_coeffs_s16, 0, inv_dst16_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_adst16_1d_col_8bpc_neon, 4, adst16_coeffs_s16, 0, inv_dst16_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_flipadst16_1d_row_8bpc_neon, flipadst16_coeffs_s16, 0, inv_dst16_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_flipadst16_1d_col_8bpc_neon, 4, flipadst16_coeffs_s16, 0, inv_dst16_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_ddt16_1d_row_8bpc_neon, ddt16_coeffs_s16, 0, inv_dst16_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_ddt16_1d_col_8bpc_neon, 4, ddt16_coeffs_s16, 0, inv_dst16_1d_8bpc_neon
inv_dst_row_wrapper_s16 inv_flipddt16_1d_row_8bpc_neon, ddt16_coeffs_s16, 15, inv_dst16_1d_transpose_8bpc_neon
inv_dst_col_wrapper_s16 inv_flipddt16_1d_col_8bpc_neon, 4, ddt16_coeffs_s16, 15, inv_dst16_1d_8bpc_neon

.macro scale_inplace_8x8h base, stride, ptr_tmp, scale
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  \base, \ptr_tmp, \stride
        sqrdmulh        v0.4h,   v0.4h,   \scale\().4h
        sqrdmulh        v1.4h,   v1.4h,   \scale\().4h
        sqrdmulh        v2.4h,   v2.4h,   \scale\().4h
        sqrdmulh        v3.4h,   v3.4h,   \scale\().4h
        sqrdmulh        v4.4h,   v4.4h,   \scale\().4h
        sqrdmulh        v5.4h,   v5.4h,   \scale\().4h
        sqrdmulh        v6.4h,   v6.4h,   \scale\().4h
        sqrdmulh        v7.4h,   v7.4h,   \scale\().4h
        store_8_strided d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  \base, \ptr_tmp, \stride
.endm

// Apply (possibly conditionally scaled) DCT4 to v0.4h-v3.4h, return results in
// v0.4s-v3.4s.
.macro dct4_1d_body_s16 may_scale, scale_reg, scale, cos1, cos2
  .if \may_scale
        cbz             \scale_reg, 1f
        sqrdmulh        v0.4h,   v0.4h,   \scale\().4h
        sqrdmulh        v1.4h,   v1.4h,   \scale\().4h
        sqrdmulh        v2.4h,   v2.4h,   \scale\().4h
        sqrdmulh        v3.4h,   v3.4h,   \scale\().4h
1:
  .endif
        smull           v6.4s,   v1.4h,   \cos1\().4h
        smull           v7.4s,   v1.4h,   \cos2\().4h
        smlal           v6.4s,   v3.4h,   \cos2\().4h
        smlsl           v7.4s,   v3.4h,   \cos1\().4h
        saddl           v16.4s,  v0.4h,   v2.4h
        ssubl           v17.4s,  v0.4h,   v2.4h
        shl             v16.4s,  v16.4s,  #6
        shl             v17.4s,  v17.4s,  #6
        add             v0.4s,   v16.4s,  v6.4s
        add             v1.4s,   v17.4s,  v7.4s
        sub             v2.4s,   v17.4s,  v7.4s
        sub             v3.4s,   v16.4s,  v6.4s
.endm

// Apply (possibly conditionally scaled) DCT8 to v0.4h-v7.4h, return results in
// v0.4s-v7.4s.
.macro dct8_1d_body_s16 may_scale, scale_reg, scale, coeffs
  .if \may_scale
        cbz             \scale_reg, 1f
        sqrdmulh        v0.4h,   v0.4h,   \scale\().4h
        sqrdmulh        v1.4h,   v1.4h,   \scale\().4h
        sqrdmulh        v2.4h,   v2.4h,   \scale\().4h
        sqrdmulh        v3.4h,   v3.4h,   \scale\().4h
        sqrdmulh        v4.4h,   v4.4h,   \scale\().4h
        sqrdmulh        v5.4h,   v5.4h,   \scale\().4h
        sqrdmulh        v6.4h,   v6.4h,   \scale\().4h
        sqrdmulh        v7.4h,   v7.4h,   \scale\().4h
1:
  .endif

        smull           v16.4s,  v1.4h,   \coeffs\().h[4]
        smull           v17.4s,  v1.4h,   \coeffs\().h[5]
        smull           v18.4s,  v1.4h,   \coeffs\().h[6]
        smull           v19.4s,  v1.4h,   \coeffs\().h[7]

        smlal           v16.4s,  v3.4h,   \coeffs\().h[5]
        smlsl           v17.4s,  v3.4h,   \coeffs\().h[7]
        smlsl           v18.4s,  v3.4h,   \coeffs\().h[4]
        smlsl           v19.4s,  v3.4h,   \coeffs\().h[6]

        smlal           v16.4s,  v5.4h,   \coeffs\().h[6]
        smlsl           v17.4s,  v5.4h,   \coeffs\().h[4]
        smlal           v18.4s,  v5.4h,   \coeffs\().h[7]
        smlal           v19.4s,  v5.4h,   \coeffs\().h[5]

        smlal           v16.4s,  v7.4h,   \coeffs\().h[7]
        smlsl           v17.4s,  v7.4h,   \coeffs\().h[6]
        smlal           v18.4s,  v7.4h,   \coeffs\().h[5]
        smlsl           v19.4s,  v7.4h,   \coeffs\().h[4]

        smull           v20.4s,  v2.4h,   \coeffs\().h[0]
        smull           v21.4s,  v2.4h,   \coeffs\().h[1]

        smlal           v20.4s,  v6.4h,   \coeffs\().h[1]
        smlsl           v21.4s,  v6.4h,   \coeffs\().h[0]

        saddl           v22.4s,  v0.4h,   v4.4h
        ssubl           v23.4s,  v0.4h,   v4.4h
        shl             v22.4s,  v22.4s,  #6
        shl             v23.4s,  v23.4s,  #6

        add             v24.4s,  v22.4s,  v20.4s
        add             v25.4s,  v23.4s,  v21.4s
        sub             v26.4s,  v23.4s,  v21.4s
        sub             v27.4s,  v22.4s,  v20.4s

        add             v0.4s,   v24.4s,  v16.4s
        add             v1.4s,   v25.4s,  v17.4s
        add             v2.4s,   v26.4s,  v18.4s
        add             v3.4s,   v27.4s,  v19.4s
        sub             v4.4s,   v27.4s,  v19.4s
        sub             v5.4s,   v26.4s,  v18.4s
        sub             v6.4s,   v25.4s,  v17.4s
        sub             v7.4s,   v24.4s,  v16.4s
.endm

// Apply DCT16 even-half setup to v0.4h-v7.4h. Return half0-1 component results
// in v8.4s-v9.4s, quarter0-3 component results in v16.4s-v19.4s, and eighth0-1
// component results in v20.4s-v21.4s.
.macro dct16_even_s16
        saddl           v8.4s,   v0.4h,   v4.4h
        ssubl           v9.4s,   v0.4h,   v4.4h
        shl             v8.4s,   v8.4s,   #6
        shl             v9.4s,   v9.4s,   #6

        ldrel           q0,  x8,  dct_qtable_s16

        smull           v16.4s,  v1.4h,   v0.h[4]
        smull           v17.4s,  v1.4h,   v0.h[5]
        smull           v18.4s,  v1.4h,   v0.h[6]
        smull           v19.4s,  v1.4h,   v0.h[7]

        smlal           v16.4s,  v3.4h,   v0.h[5]
        smlsl           v17.4s,  v3.4h,   v0.h[7]
        smlsl           v18.4s,  v3.4h,   v0.h[4]
        smlsl           v19.4s,  v3.4h,   v0.h[6]

        smlal           v16.4s,  v5.4h,   v0.h[6]
        smlsl           v17.4s,  v5.4h,   v0.h[4]
        smlal           v18.4s,  v5.4h,   v0.h[7]
        smlal           v19.4s,  v5.4h,   v0.h[5]

        smlal           v16.4s,  v7.4h,   v0.h[7]
        smlsl           v17.4s,  v7.4h,   v0.h[6]
        smlal           v18.4s,  v7.4h,   v0.h[5]
        smlsl           v19.4s,  v7.4h,   v0.h[4]

        smull           v20.4s,  v2.4h,   v0.h[0]
        smull           v21.4s,  v2.4h,   v0.h[1]
        smlal           v20.4s,  v6.4h,   v0.h[1]
        smlsl           v21.4s,  v6.4h,   v0.h[0]
.endm

// Apply DCT16 odd-half setup to v0.4h-v7.4h. Return odd0-3 component results
// in v22.4s-v25.4s, and odd4-7 component results in v12.4s-v15.4s.
.macro dct16_odd_s16
        ldrel           q10, x8,  dct16_odd_qtable_s16

        smull           v22.4s,  v0.4h,   v10.h[0]
        smull           v23.4s,  v0.4h,   v10.h[1]
        smull           v24.4s,  v0.4h,   v10.h[2]
        smull           v25.4s,  v0.4h,   v10.h[3]
        smull           v12.4s,  v0.4h,   v10.h[4]
        smull           v13.4s,  v0.4h,   v10.h[5]
        smull           v14.4s,  v0.4h,   v10.h[6]
        smull           v15.4s,  v0.4h,   v10.h[7]

        smlal           v22.4s,  v1.4h,   v10.h[1]
        smlal           v23.4s,  v1.4h,   v10.h[4]
        smlal           v24.4s,  v1.4h,   v10.h[7]
        smlsl           v25.4s,  v1.4h,   v10.h[5]
        smlsl           v12.4s,  v1.4h,   v10.h[2]
        smlsl           v13.4s,  v1.4h,   v10.h[0]
        smlsl           v14.4s,  v1.4h,   v10.h[3]
        smlsl           v15.4s,  v1.4h,   v10.h[6]

        smlal           v22.4s,  v2.4h,   v10.h[2]
        smlal           v23.4s,  v2.4h,   v10.h[7]
        smlsl           v24.4s,  v2.4h,   v10.h[3]
        smlsl           v25.4s,  v2.4h,   v10.h[1]
        smlsl           v12.4s,  v2.4h,   v10.h[6]
        smlal           v13.4s,  v2.4h,   v10.h[4]
        smlal           v14.4s,  v2.4h,   v10.h[0]
        smlal           v15.4s,  v2.4h,   v10.h[5]

        smlal           v22.4s,  v3.4h,   v10.h[3]
        smlsl           v23.4s,  v3.4h,   v10.h[5]
        smlsl           v24.4s,  v3.4h,   v10.h[1]
        smlal           v25.4s,  v3.4h,   v10.h[7]
        smlal           v12.4s,  v3.4h,   v10.h[0]
        smlal           v13.4s,  v3.4h,   v10.h[6]
        smlsl           v14.4s,  v3.4h,   v10.h[2]
        smlsl           v15.4s,  v3.4h,   v10.h[4]

        smlal           v22.4s,  v4.4h,   v10.h[4]
        smlsl           v23.4s,  v4.4h,   v10.h[2]
        smlsl           v24.4s,  v4.4h,   v10.h[6]
        smlal           v25.4s,  v4.4h,   v10.h[0]
        smlsl           v12.4s,  v4.4h,   v10.h[7]
        smlsl           v13.4s,  v4.4h,   v10.h[1]
        smlal           v14.4s,  v4.4h,   v10.h[5]
        smlal           v15.4s,  v4.4h,   v10.h[3]

        smlal           v22.4s,  v5.4h,   v10.h[5]
        smlsl           v23.4s,  v5.4h,   v10.h[0]
        smlal           v24.4s,  v5.4h,   v10.h[4]
        smlal           v25.4s,  v5.4h,   v10.h[6]
        smlsl           v12.4s,  v5.4h,   v10.h[1]
        smlal           v13.4s,  v5.4h,   v10.h[3]
        smlal           v14.4s,  v5.4h,   v10.h[7]
        smlsl           v15.4s,  v5.4h,   v10.h[2]

        smlal           v22.4s,  v6.4h,   v10.h[6]
        smlsl           v23.4s,  v6.4h,   v10.h[3]
        smlal           v24.4s,  v6.4h,   v10.h[0]
        smlsl           v25.4s,  v6.4h,   v10.h[2]
        smlal           v12.4s,  v6.4h,   v10.h[5]
        smlal           v13.4s,  v6.4h,   v10.h[7]
        smlsl           v14.4s,  v6.4h,   v10.h[4]
        smlal           v15.4s,  v6.4h,   v10.h[1]

        smlal           v22.4s,  v7.4h,   v10.h[7]
        smlsl           v23.4s,  v7.4h,   v10.h[6]
        smlal           v24.4s,  v7.4h,   v10.h[5]
        smlsl           v25.4s,  v7.4h,   v10.h[4]
        smlal           v12.4s,  v7.4h,   v10.h[3]
        smlsl           v13.4s,  v7.4h,   v10.h[2]
        smlal           v14.4s,  v7.4h,   v10.h[1]
        smlsl           v15.4s,  v7.4h,   v10.h[0]
.endm

// Combine one DCT16 even/odd block, narrow and store the results.
.macro dct16_odd_add_s16 dst0, dst1, dst_stride, repx_shift, have_repx, repy_shift, have_repy, step, vshift, even0, even1, even2, even3, odd0, odd1, odd2, odd3
        sub             v26.4s,  \even3\().4s,  \odd3\().4s
        sub             v27.4s,  \even2\().4s,  \odd2\().4s
        sub             v28.4s,  \even1\().4s,  \odd1\().4s
        sub             v29.4s,  \even0\().4s,  \odd0\().4s
        add             \even0\().4s,  \even0\().4s,  \odd0\().4s
        add             \even1\().4s,  \even1\().4s,  \odd1\().4s
        add             \even2\().4s,  \even2\().4s,  \odd2\().4s
        add             \even3\().4s,  \even3\().4s,  \odd3\().4s

        shift_and_narrow_4x4s v16, v17, v18, v19, \even0, \even1, \even2, \even3, \vshift
        iclip_sum4_8bpc_x4 \dst0, \dst_stride, \repx_shift, \have_repx, \repy_shift, \have_repy, \step, x8,  v16, v17, v18, v19

        shift_and_narrow_4x4s v16, v17, v18, v19, v26, v27, v28, v29, \vshift
        iclip_sum4_8bpc_x4 \dst1, \dst_stride, \repx_shift, \have_repx, \repy_shift, \have_repy, \step, x8,  v16, v17, v18, v19
.endm


// Load one row of coefficients and multiply even/odd inputs r0-r15.4h,
// returning even results in dst0.4s and odd results in dst1.4s. The exact
// accumulation here doesn't matter, just use a pair of accumulators to reduce
// latency.
.macro dct32_odd_dot16_s16 dst0, dst1, r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, coeff, t0, t1
        ld1             {\t0\().8h,  \t1\().8h}, [\coeff], #32
        smull           \dst0\().4s,  \r0\().4h,  \t0\().h[0]
        smull           \dst1\().4s,  \r1\().4h,  \t0\().h[1]
        smlal           \dst0\().4s,  \r2\().4h,  \t0\().h[2]
        smlal           \dst1\().4s,  \r3\().4h,  \t0\().h[3]
        smlal           \dst0\().4s,  \r4\().4h,  \t0\().h[4]
        smlal           \dst1\().4s,  \r5\().4h,  \t0\().h[5]
        smlal           \dst0\().4s,  \r6\().4h,  \t0\().h[6]
        smlal           \dst1\().4s,  \r7\().4h,  \t0\().h[7]

        smlal           \dst0\().4s,  \r8\().4h,   \t1\().h[0]
        smlal           \dst1\().4s,  \r9\().4h,   \t1\().h[1]
        smlal           \dst0\().4s,  \r10\().4h,  \t1\().h[2]
        smlal           \dst1\().4s,  \r11\().4h,  \t1\().h[3]
        smlal           \dst0\().4s,  \r12\().4h,  \t1\().h[4]
        smlal           \dst1\().4s,  \r13\().4h,  \t1\().h[5]
        smlal           \dst0\().4s,  \r14\().4h,  \t1\().h[6]
        smlal           \dst1\().4s,  \r15\().4h,  \t1\().h[7]
.endm

// Load and apply four rows of coefficients. Even elements are loaded as
// v0.4h-v7.4h, odd elements are loaded as v8-v15.4h. Sum results are returned
// through dst0-dst3.4s. acc0/acc1 are temporaries.
.macro dct32_odd_dot_block_s16 c, stride, coeffs, dst0, dst1, dst2, dst3, acc0, acc1
        mov             x7,  \c
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x7,  x7,  \stride
        add             x7,  x7,  \stride, lsl #1
        load_8_strided  d8,  d9,  d10, d11, d12, d13, d22, d23, x7,  x7,  \stride

        dct32_odd_dot16_s16 \acc0, \acc1, v0,  v1,  v2,  v3,  v4,  v5,  v6,  v7,  v8,  v9,  v10, v11, v12, v13, v22, v23, \coeffs, v14, v15
        add             \dst0\().4s,  \acc0\().4s,  \acc1\().4s

        dct32_odd_dot16_s16 \acc0, \acc1, v0,  v1,  v2,  v3,  v4,  v5,  v6,  v7,  v8,  v9,  v10, v11, v12, v13, v22, v23, \coeffs, v14, v15
        add             \dst1\().4s,  \acc0\().4s,  \acc1\().4s

        dct32_odd_dot16_s16 \acc0, \acc1, v0,  v1,  v2,  v3,  v4,  v5,  v6,  v7,  v8,  v9,  v10, v11, v12, v13, v22, v23, \coeffs, v14, v15
        add             \dst2\().4s,  \acc0\().4s,  \acc1\().4s

        dct32_odd_dot16_s16 \acc0, \acc1, v0,  v1,  v2,  v3,  v4,  v5,  v6,  v7,  v8,  v9,  v10, v11, v12, v13, v22, v23, \coeffs, v14, v15
        add             \dst3\().4s,  \acc0\().4s,  \acc1\().4s
.endm

.macro dct32_combine_even0_s16 dst0, dst1, dst2, dst3
        add             \dst0\().4s,  v30.4s,  v28.4s
        add             \dst1\().4s,  v31.4s,  v29.4s
        sub             \dst2\().4s,  v31.4s,  v29.4s
        sub             \dst3\().4s,  v30.4s,  v28.4s
        add             \dst0\().4s,  \dst0\().4s,  v24.4s
        add             \dst1\().4s,  \dst1\().4s,  v25.4s
        add             \dst2\().4s,  \dst2\().4s,  v26.4s
        add             \dst3\().4s,  \dst3\().4s,  v27.4s
.endm

.macro dct32_combine_even1_s16 dst0, dst1, dst2, dst3
        sub             \dst0\().4s,  v30.4s,  v28.4s
        sub             \dst1\().4s,  v31.4s,  v29.4s
        add             \dst2\().4s,  v31.4s,  v29.4s
        add             \dst3\().4s,  v30.4s,  v28.4s
        sub             \dst0\().4s,  \dst0\().4s,  v27.4s
        sub             \dst1\().4s,  \dst1\().4s,  v26.4s
        sub             \dst2\().4s,  \dst2\().4s,  v25.4s
        sub             \dst3\().4s,  \dst3\().4s,  v24.4s
.endm

.macro dct32_odd_store_s16 dst0, dst1, step, neg_shift, even0, even1, even2, even3
        sub             v0.4s,   \even0\().4s,  v16.4s
        sub             v1.4s,   \even1\().4s,  v17.4s
        sub             v2.4s,   \even2\().4s,  v18.4s
        sub             v3.4s,   \even3\().4s,  v19.4s
        add             v16.4s,  \even0\().4s,  v16.4s
        add             v17.4s,  \even1\().4s,  v17.4s
        add             v18.4s,  \even2\().4s,  v18.4s
        add             v19.4s,  \even3\().4s,  v19.4s

        dup             v31.4s,  \neg_shift

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        store_4_strided d16, d17, d18, d19, \dst0, \dst0, \step

        shift_and_narrow_4x4s v3,  v2,  v1,  v0,  v3,  v2,  v1,  v0,  v31
        transpose_4x4h  v3,  v2,  v1,  v0,  v3,  v2,  v1,  v0,  v20, v21, v22, v23
        store_4_strided d3,  d2,  d1,  d0,  \dst1, \dst1, \step
.endm

// Compute DCT32 eighth components. Inputs are in v0.4h-v3.4h. Return
// eighth0-eighth3 in v24.4s-v27.4s.
.macro dct32_eighth_s16
        ldrel           d4,  x8,  dct_qtable_s16, 8

        smull           v24.4s,  v0.4h,   v4.h[0]
        smull           v25.4s,  v0.4h,   v4.h[1]
        smull           v26.4s,  v0.4h,   v4.h[2]
        smull           v27.4s,  v0.4h,   v4.h[3]

        smlal           v24.4s,  v1.4h,   v4.h[1]
        smlsl           v25.4s,  v1.4h,   v4.h[3]
        smlsl           v26.4s,  v1.4h,   v4.h[0]
        smlsl           v27.4s,  v1.4h,   v4.h[2]

        smlal           v24.4s,  v2.4h,   v4.h[2]
        smlsl           v25.4s,  v2.4h,   v4.h[0]
        smlal           v26.4s,  v2.4h,   v4.h[3]
        smlal           v27.4s,  v2.4h,   v4.h[1]

        smlal           v24.4s,  v3.4h,   v4.h[3]
        smlsl           v25.4s,  v3.4h,   v4.h[2]
        smlal           v26.4s,  v3.4h,   v4.h[1]
        smlsl           v27.4s,  v3.4h,   v4.h[0]
.endm

// Compute DCT32 sixteenth components. Inputs are in v0.4h/v1.4h. Return
// sixteenth0/sixteenth1 in v28.4s-v29.4s.
.macro dct32_sixteenth_s16
        ldrel           d4,  x8,  dct_qtable_s16

        smull           v28.4s,  v0.4h,   v4.h[0]
        smull           v29.4s,  v0.4h,   v4.h[1]
        smlal           v28.4s,  v1.4h,   v4.h[1]
        smlsl           v29.4s,  v1.4h,   v4.h[0]
.endm


// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
function inv_dct4_1d_row_8bpc_neon, export=1
        lsl             x12, x3,  #1
        cbz             w6,  99f

        mov             w15, #RECT2_SCALE
        dup             v30.4h,  w15
        movi            v4.4h,   #83  // dct_qtable_s16[0]
        movi            v5.4h,   #35  // dct_qtable_s16[1]
        lsl             x15, x1,  #1
        neg             w14, w4
        dup             v31.4s,  w14

        mov             x9,  x2
        mov             x11, x0
        mov             w4,  #0
L(dct4_row_s16_loop):
        load_4_strided  d0,  d1,  d2,  d3,  x9,  x13, x12
        dct4_1d_body_s16 1, w5,  v30, v4,  v5

        shift_and_narrow_4x4s v16, v17, v18, v19, v0,  v1,  v2,  v3,  v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        store_4_strided d16, d17, d18, d19, x11, x11, x15

        add             x9,  x9,  #8
        add             x11, x11, x15, lsl #1
        add             w4,  w4,  #4
        cmp             w4,  w6
        b.lt            L(dct4_row_s16_loop)
99:
        mul             x16, x1,  x6
        add             x16, x0,  x16, lsl #1
        itx_row_zero_tail_s16 x16, x2,  w3,  w1,  w6
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
function inv_dct4_1d_col_8bpc_neon, export=1
        lsr             w4,  w4,  #6
        lsr             w5,  w5,  #3
        mov             w16, #0

        cbz             w7,  99f
        movi            v4.4h,   #83  // dct_qtable_s16[0]
        movi            v5.4h,   #35  // dct_qtable_s16[1]
        neg             w8,  w6
        dup             v31.4s,  w8
        lsl             x10, x3,  #1
L(dct4_col_s16_loop):
        add             x9,  x2,  x16, lsl #1
        load_4_strided  d0,  d1,  d2,  d3,  x9,  x11, x10

        dct4_1d_body_s16 0, wzr, v30, v4,  v5

        lsl             x12, x16, x4
        add             x13, x0,  x12
        shift_and_narrow_4x4s v16, v17, v18, v19, v0,  v1,  v2,  v3,  v31
        iclip_sum4_8bpc_x4 x13, x1,  x4,  1, x5,  0, x1,  x8,  v16, v17, v18, v19

        add             w16, w16, #4
        cmp             w16, w7
        b.lt            L(dct4_col_s16_loop)
99:
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
function inv_dct8_1d_row_8bpc_neon, export=1
        stp             d8,  d9,  [sp, #-16]!
        lsl             x13, x3,  #1
        cbz             w6,  99f

        mov             w15, #RECT2_SCALE
        dup             v30.4h,  w15
        ldrel           q8,  x8,  dct_qtable_s16
        lsl             x15, x1,  #1
        neg             w14, w4
        dup             v31.4s,  w14

        mov             x10, x2
        mov             x12, x0
        mov             w4,  #0
L(dct8_row_s16_loop):
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x14, x13
        dct8_1d_body_s16 1, w5,  v30, v8

        add             x14, x12, #8
        shift_and_narrow_4x4s v16, v17, v18, v19, v0,  v1,  v2,  v3,  v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        store_4_strided d16, d17, d18, d19, x12, x12, x15
        shift_and_narrow_4x4s v16, v17, v18, v19, v4,  v5,  v6,  v7,  v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        store_4_strided d16, d17, d18, d19, x14, x14, x15

        add             x10, x10, #8
        add             x12, x12, x15, lsl #1
        add             w4,  w4,  #4
        cmp             w4,  w6
        b.lt            L(dct8_row_s16_loop)
99:
        mul             x16, x1,  x6
        add             x16, x0,  x16, lsl #1
        itx_row_zero_tail_s16 x16, x2,  w3,  w1,  w6
        ldp             d8,  d9,  [sp], #16
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
function inv_dct8_1d_col_8bpc_neon, export=1
        stp             d8,  d9,  [sp, #-16]!
        lsr             w4,  w4,  #6
        lsr             w5,  w5,  #4
        lsl             x15, x1,  x5
        lsl             x15, x15, #2
        mov             w17, #0

        cbz             w7,  99f
        ldrel           q8,  x8,  dct_qtable_s16
        neg             w8,  w6
        dup             v31.4s,  w8
        lsl             x11, x3,  #1
L(dct8_col_s16_loop):
        add             x10, x2,  x17, lsl #1
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x12, x11

        dct8_1d_body_s16 0, wzr, v30, v8

        lsl             x13, x17, x4
        add             x14, x0,  x13

        add             x16, x14, x15
        shift_and_narrow_4x4s v16, v17, v18, v19, v0,  v1,  v2,  v3,  v31
        iclip_sum4_8bpc_x4 x14, x1,  x4,  1, x5,  0, x1,  x8,  v16, v17, v18, v19
        shift_and_narrow_4x4s v16, v17, v18, v19, v4,  v5,  v6,  v7,  v31
        iclip_sum4_8bpc_x4 x16, x1,  x4,  1, x5,  0, x1,  x8,  v16, v17, v18, v19

        add             w17, w17, #4
        cmp             w17, w7
        b.lt            L(dct8_col_s16_loop)
99:
        ldp             d8,  d9,  [sp], #16
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
function inv_dct16_1d_row_8bpc_neon, export=1
        stp             d8,  d9,  [sp, #-64]!
        stp             d10, d11, [sp, #16]
        stp             d12, d13, [sp, #32]
        stp             d14, d15, [sp, #48]
        cbz             w6,  99f

        mov             w15, #RECT2_SCALE
        dup             v30.4h,  w15
        neg             w14, w4
        dup             v31.4s,  w14

        mov             x9,  x2
        mov             x17, x0
        mov             w4,  #0
        lsl             x16, x1, #1
        lsl             x11, x3, #1
        lsl             x12, x11, #1
L(dct16_row_s16_loop):
        // Load even elements into v0.4h-v7.4h and optionally scale them.
        mov             x10, x9
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x10, x12

        cbz             w5,  1f
        sqrdmulh        v0.4h,   v0.4h,   v30.4h
        sqrdmulh        v1.4h,   v1.4h,   v30.4h
        sqrdmulh        v2.4h,   v2.4h,   v30.4h
        sqrdmulh        v3.4h,   v3.4h,   v30.4h
        sqrdmulh        v4.4h,   v4.4h,   v30.4h
        sqrdmulh        v5.4h,   v5.4h,   v30.4h
        sqrdmulh        v6.4h,   v6.4h,   v30.4h
        sqrdmulh        v7.4h,   v7.4h,   v30.4h
1:
        // dct16_even_s16 returns half0/1 in v8.4s/v9.4s, quarter0-3 in
        // v16.4s-v19.4s, and eighth0/1 in v20.4s/v21.4s.
        dct16_even_s16

        // Load odd elements into v0.4h-v7.4h and optionally scale them.
        add             x10, x9, x11
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x10, x12

        cbz             w5,  1f
        sqrdmulh        v0.4h,   v0.4h,   v30.4h
        sqrdmulh        v1.4h,   v1.4h,   v30.4h
        sqrdmulh        v2.4h,   v2.4h,   v30.4h
        sqrdmulh        v3.4h,   v3.4h,   v30.4h
        sqrdmulh        v4.4h,   v4.4h,   v30.4h
        sqrdmulh        v5.4h,   v5.4h,   v30.4h
        sqrdmulh        v6.4h,   v6.4h,   v30.4h
        sqrdmulh        v7.4h,   v7.4h,   v30.4h
1:
        // dct16_odd_s16 returns odd0-3 in v22.4s-v25.4s and odd4-7 in
        // v12.4s-v15.4s.
        dct16_odd_s16

        add             v0.4s,   v8.4s,   v20.4s
        add             v1.4s,   v9.4s,   v21.4s
        sub             v2.4s,   v9.4s,   v21.4s
        sub             v3.4s,   v8.4s,   v20.4s
        sub             v8.4s,   v3.4s,   v19.4s
        sub             v9.4s,   v2.4s,   v18.4s
        sub             v10.4s,  v1.4s,   v17.4s
        sub             v11.4s,  v0.4s,   v16.4s
        add             v0.4s,   v0.4s,   v16.4s
        add             v1.4s,   v1.4s,   v17.4s
        add             v2.4s,   v2.4s,   v18.4s
        add             v3.4s,   v3.4s,   v19.4s

        add             v16.4s,  v0.4s,    v22.4s
        add             v17.4s,  v1.4s,    v23.4s
        add             v18.4s,  v2.4s,    v24.4s
        add             v19.4s,  v3.4s,    v25.4s
        sub             v20.4s,  v0.4s,    v22.4s
        sub             v21.4s,  v1.4s,    v23.4s
        sub             v22.4s,  v2.4s,    v24.4s
        sub             v23.4s,  v3.4s,    v25.4s

        add             x13, x17, #8
        add             x14, x17, #16
        add             x15, x17, #24

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v0,  v1,  v2,  v3
        store_4_strided d16, d17, d18, d19, x17, x17, x16

        shift_and_narrow_4x4s v23, v22, v21, v20, v23, v22, v21, v20, v31
        transpose_4x4h  v23, v22, v21, v20, v23, v22, v21, v20, v0,  v1,  v2,  v3
        store_4_strided d23, d22, d21, d20, x15, x15, x16

        add             v16.4s,  v8.4s,    v12.4s
        add             v17.4s,  v9.4s,    v13.4s
        add             v18.4s,  v10.4s,   v14.4s
        add             v19.4s,  v11.4s,   v15.4s
        sub             v20.4s,  v8.4s,    v12.4s
        sub             v21.4s,  v9.4s,    v13.4s
        sub             v22.4s,  v10.4s,   v14.4s
        sub             v23.4s,  v11.4s,   v15.4s

        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v0,  v1,  v2,  v3
        store_4_strided d16, d17, d18, d19, x13, x13, x16

        shift_and_narrow_4x4s v23, v22, v21, v20, v23, v22, v21, v20, v31
        transpose_4x4h  v23, v22, v21, v20, v23, v22, v21, v20, v0,  v1,  v2,  v3
        store_4_strided d23, d22, d21, d20, x14, x14, x16
        add             x9,  x9,  #8
        add             x17, x17, x16, lsl #1
        add             w4,  w4,  #4
        cmp             w4,  w6
        b.lt            L(dct16_row_s16_loop)

99:
        mul             x16, x1,  x6
        add             x16, x0,  x16, lsl #1
        itx_row_zero_tail_s16 x16, x2,  w3,  w1,  w6
        ldp             d14, d15, [sp, #48]
        ldp             d12, d13, [sp, #32]
        ldp             d10, d11, [sp, #16]
        ldp             d8,  d9,  [sp], #64
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
function inv_dct16_1d_col_8bpc_neon, export=1
        stp             x19, x20, [sp, #-80]!
        stp             d8,  d9,  [sp, #16]
        stp             d10, d11, [sp, #32]
        stp             d12, d13, [sp, #48]
        stp             d14, d15, [sp, #64]
        mov             x19, x2
        mov             x20, x0
        lsr             w4,  w4,  #6
        lsr             w5,  w5,  #5
        mov             w9,  #0

        cbz             w7,  99f
        neg             w6,  w6
        dup             v31.4s,  w6
L(dct16_col_s16_loop):
        add             x2,  x19, x9,  lsl #1
        lsl             x10, x9,  x4
        add             x0,  x20, x10

        // Load even elements into v0.4h-v7.4h, no scaling.
        mov             x10, x2
        lsl             x12, x3, #2
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x10, x12

        // dct16_even_s16 returns half0/1 in v8.4s/v9.4s, quarter0-3 in
        // v16.4s-v19.4s, and eighth0/1 in v20.4s/v21.4s.
        dct16_even_s16

        // Load odd elements into v0.4h-v7.4h, no scaling.
        add             x10, x2, x3, lsl #1
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x10, x12

        // dct16_odd_s16 returns odd0-3 in v22.4s-v25.4s and odd4-7 in
        // v12.4s-v15.4s.
        dct16_odd_s16

        add             v0.4s,   v8.4s,   v20.4s
        add             v1.4s,   v9.4s,   v21.4s
        sub             v2.4s,   v9.4s,   v21.4s
        sub             v3.4s,   v8.4s,   v20.4s
        sub             v8.4s,   v3.4s,   v19.4s
        sub             v9.4s,   v2.4s,   v18.4s
        sub             v10.4s,  v1.4s,   v17.4s
        sub             v11.4s,  v0.4s,   v16.4s
        add             v0.4s,   v0.4s,   v16.4s
        add             v1.4s,   v1.4s,   v17.4s
        add             v2.4s,   v2.4s,   v18.4s
        add             v3.4s,   v3.4s,   v19.4s

        add             x16, x0, x1, lsl #2
        add             x17, x0, x1, lsl #3
        add             x10, x17,  x1, lsl #2
        dct16_odd_add_s16 x0, x10, x1, x4, 1, x5, 0, x1, v31, v0,  v1,  v2,  v3,  v22, v23, v24, v25
        dct16_odd_add_s16 x16,  x17, x1, x4, 1, x5, 0, x1, v31, v8,  v9,  v10, v11, v12, v13, v14, v15

        add             w9,  w9,  #4
        cmp             w9,  w7
        b.lt            L(dct16_col_s16_loop)

99:
        ldp             d14, d15, [sp, #64]
        ldp             d12, d13, [sp, #48]
        ldp             d10, d11, [sp, #32]
        ldp             d8,  d9,  [sp, #16]
        ldp             x19, x20, [sp], #80
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
function inv_dct32_1d_row_8bpc_neon, export=1
        sub             sp, sp, #400
        str             x29, [sp]
        mov             x29, sp
        stp             x19, x20, [x29, #16]
        stp             d8,  d9,  [x29, #336]
        stp             d10, d11, [x29, #352]
        stp             d12, d13, [x29, #368]
        stp             d14, d15, [x29, #384]

        cbz             w6,  99f
        neg             w17, w4
        mov             x9,  x2
        mov             x19, x0
        mov             w20, #0
        lsl             x16, x1, #1

L(dct32_row_s16_loop):
        // Load odd elements into v0.4h-v7.4h, optionally scale them.
        add             x10, x9, x3, lsl #2
        lsl             x12, x3, #3
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x10, x12

        cbz             w5,  1f
        mov             w13, #RECT2_SCALE
        dup             v16.4h,  w13
        sqrdmulh        v0.4h,   v0.4h,   v16.4h
        sqrdmulh        v1.4h,   v1.4h,   v16.4h
        sqrdmulh        v2.4h,   v2.4h,   v16.4h
        sqrdmulh        v3.4h,   v3.4h,   v16.4h
        sqrdmulh        v4.4h,   v4.4h,   v16.4h
        sqrdmulh        v5.4h,   v5.4h,   v16.4h
        sqrdmulh        v6.4h,   v6.4h,   v16.4h
        sqrdmulh        v7.4h,   v7.4h,   v16.4h
1:
        // dct16_odd_s16 returns odd0-3 in v22.4s-v25.4s and odd4-7 in
        // v12.4s-v15.4s.
        dct16_odd_s16
        stp             q22, q23, [x29, #80]
        stp             q24, q25, [x29, #112]
        stp             q12, q13, [x29, #144]
        stp             q14, q15, [x29, #176]

        // Load eighth elements into v0.4h-v3.4h, optionally scale them.
        add             x10, x9, x3, lsl #3
        lsl             x12, x3, #4
        load_4_strided  d0,  d1,  d2,  d3,  x10, x10, x12

        cbz             w5,  1f
        mov             w13, #RECT2_SCALE
        dup             v16.4h,  w13
        sqrdmulh        v0.4h,   v0.4h,   v16.4h
        sqrdmulh        v1.4h,   v1.4h,   v16.4h
        sqrdmulh        v2.4h,   v2.4h,   v16.4h
        sqrdmulh        v3.4h,   v3.4h,   v16.4h
1:
        // dct32_eighth_s16 returns eighth0-eighth3 in v24.4s-v27.4s.
        dct32_eighth_s16
        stp             q24, q25, [x29, #208]
        stp             q26, q27, [x29, #240]

        // Load sixteenth elements into v0.4h/v1.4h, optionally scale them.
        add             x10, x9, x3, lsl #4
        lsl             x12, x3, #5
        load_2_strided  d0,  d1,  x10, x10, x12

        cbz             w5,  1f
        mov             w13, #RECT2_SCALE
        dup             v16.4h,  w13
        sqrdmulh        v0.4h,   v0.4h,   v16.4h
        sqrdmulh        v1.4h,   v1.4h,   v16.4h
1:
        // dct32_sixteenth_s16 returns sixteenth0/sixteenth1 in v28.4s/v29.4s.
        dct32_sixteenth_s16
        stp             q28, q29, [x29, #272]

        // Load 32nd elements into v0.4h/v1.4h, optionally scale them.
        lsl             x12, x3, #5
        load_2_strided  d0,  d1,  x9, x9, x12

        cbz             w5,  1f
        mov             w13, #RECT2_SCALE
        dup             v16.4h,  w13
        sqrdmulh        v0.4h,   v0.4h,   v16.4h
        sqrdmulh        v1.4h,   v1.4h,   v16.4h
1:
        saddl           v30.4s,  v0.4h,   v1.4h
        ssubl           v31.4s,  v0.4h,   v1.4h
        shl             v30.4s,  v30.4s,  #6
        shl             v31.4s,  v31.4s,  #6
        stp             q30, q31, [x29, #304]

        // Even elements will be loaded multiple times so optionally scale them
        // in-place first.
        cbz             w5,  1f
        add             x10, x9, x3, lsl #1
        lsl             x12, x3, #2
        mov             w14, #RECT2_SCALE
        dup             v16.4h,  w14
        scale_inplace_8x8h x10, x12, x13, v16
        add             x10, x10, x12, lsl #3
        scale_inplace_8x8h x10, x12, x13, v16
1:
        add             x11, x9, x3, lsl #1
        lsl             x12, x3, #2
        movrel          x15, dct32_odd_coeffs_s16

        // block 0
        ldp             q24, q25, [x29, #208]
        ldp             q26, q27, [x29, #240]
        ldp             q28, q29, [x29, #272]
        ldp             q30, q31, [x29, #304]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #80]
        ldp             q2,  q3,  [x29, #112]
        dct32_combine_even0_s16 v20, v21, v22, v23
        add             v20.4s,  v20.4s,  v0.4s
        add             v21.4s,  v21.4s,  v1.4s
        add             v22.4s,  v22.4s,  v2.4s
        add             v23.4s,  v23.4s,  v3.4s
        mov             x13, x19
        add             x14, x19, #56
        dct32_odd_store_s16 x13, x14, x16, w17, v20, v21, v22, v23

        // block 1
        ldp             q24, q25, [x29, #208]
        ldp             q26, q27, [x29, #240]
        ldp             q28, q29, [x29, #272]
        ldp             q30, q31, [x29, #304]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #144]
        ldp             q2,  q3,  [x29, #176]
        dct32_combine_even1_s16 v20, v21, v22, v23
        add             v20.4s,  v20.4s,  v0.4s
        add             v21.4s,  v21.4s,  v1.4s
        add             v22.4s,  v22.4s,  v2.4s
        add             v23.4s,  v23.4s,  v3.4s
        add             x13,     x19,    #8
        add             x14,     x19,    #48
        dct32_odd_store_s16 x13, x14, x16, w17, v20, v21, v22, v23

        // block 2
        ldp             q24, q25, [x29, #208]
        ldp             q26, q27, [x29, #240]
        ldp             q28, q29, [x29, #272]
        ldp             q30, q31, [x29, #304]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #144]
        ldp             q2,  q3,  [x29, #176]
        dct32_combine_even1_s16 v20, v21, v22, v23
        sub             v4.4s,   v23.4s,  v3.4s
        sub             v5.4s,   v22.4s,  v2.4s
        sub             v6.4s,   v21.4s,  v1.4s
        sub             v7.4s,   v20.4s,  v0.4s
        add             x13, x19, #16
        add             x14, x19, #40
        dct32_odd_store_s16 x13, x14, x16, w17, v4,  v5,  v6,  v7

        // block 3
        ldp             q24, q25, [x29, #208]
        ldp             q26, q27, [x29, #240]
        ldp             q28, q29, [x29, #272]
        ldp             q30, q31, [x29, #304]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #80]
        ldp             q2,  q3,  [x29, #112]
        dct32_combine_even0_s16 v20, v21, v22, v23
        sub             v4.4s,   v23.4s,  v3.4s
        sub             v5.4s,   v22.4s,  v2.4s
        sub             v6.4s,   v21.4s,  v1.4s
        sub             v7.4s,   v20.4s,  v0.4s
        add             x13, x19, #24
        add             x14, x19, #32
        dct32_odd_store_s16 x13, x14, x16, w17, v4,  v5,  v6,  v7
        add             x9,  x9,  #8
        add             x19, x19, x16, lsl #2
        add             w20, w20, #4
        cmp             w20, w6
        b.lt            L(dct32_row_s16_loop)
99:
        mul             x16, x1,  x6
        add             x16, x0,  x16, lsl #1
        itx_row_zero_tail_s16 x16, x2,  w3,  w1,  w6
        ldp             d14, d15, [x29, #384]
        ldp             d12, d13, [x29, #368]
        ldp             d10, d11, [x29, #352]
        ldp             d8,  d9,  [x29, #336]
        ldp             x19, x20, [x29, #16]
        ldr             x29, [sp]
        add             sp, sp, #400
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
function inv_dct32_1d_col_8bpc_neon, export=1
        sub             sp, sp, #432
        str             x29, [sp]
        mov             x29, sp
        stp             x27, x28, [x29, #16]
        stp             x19, x20, [x29, #32]
        stp             x23, x24, [x29, #48]
        stp             d8,  d9,  [x29, #368]
        stp             d10, d11, [x29, #384]
        stp             d12, d13, [x29, #400]
        stp             d14, d15, [x29, #416]
        mov             x19, x2
        mov             x20, x0
        mov             x23, x3
        mov             w24, w7
        lsr             w4,  w4,  #6
        lsr             w5,  w5,  #6
        mov             w27, w6
        mov             w28, #0

        cbz             w24, 99f
L(dct32_col_s16_loop):
        add             x2,  x19, x28, lsl #1
        lsl             x10, x28, x4
        add             x0,  x20, x10

        // Load odd elements into v0.4h-v7.4h, no scaling.
        lsl             x12, x23, #3
        add             x10, x2, x23, lsl #2
        load_8_strided  d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  x10, x10, x12

        // dct16_odd_s16 returns odd0-3 in v22.4s-v25.4s and odd4-7 in
        // v12.4s-v15.4s.
        dct16_odd_s16
        stp             q22, q23, [x29, #112]
        stp             q24, q25, [x29, #144]
        stp             q12, q13, [x29, #176]
        stp             q14, q15, [x29, #208]

        // Load eighth elements into v0.4h-v3.4h, no scaling.
        add             x10, x2, x23, lsl #3
        lsl             x12, x23, #4
        load_4_strided  d0,  d1,  d2,  d3,  x10, x10, x12

        // dct32_eighth_s16 returns eighth0-eighth3 in v24.4s-v27.4s.
        dct32_eighth_s16
        stp             q24, q25, [x29, #240]
        stp             q26, q27, [x29, #272]

        // Load sixteenth elements into v0.4h/v1.4h, no scaling.
        add             x10, x2, x23, lsl #4
        lsl             x12, x23, #5
        load_2_strided  d0,  d1,  x10, x10, x12

        // dct32_sixteenth_s16 returns sixteenth0/sixteenth1 in v28.4s/v29.4s.
        dct32_sixteenth_s16
        stp             q28, q29, [x29, #304]

        // Load 32nd elements into v0.4h/v1.4h, no scaling.
        lsl             x12, x23, #5
        load_2_strided  d0,  d1,  x2, x2, x12

        saddl           v30.4s,  v0.4h,   v1.4h
        ssubl           v31.4s,  v0.4h,   v1.4h
        shl             v30.4s,  v30.4s,  #6
        shl             v31.4s,  v31.4s,  #6
        stp             q30, q31, [x29, #336]

        add             x11, x2, x23, lsl #1
        lsl             x12, x23, #2
        movrel          x15, dct32_odd_coeffs_s16
        lsl             x6,  x1, x5
        lsl             x10, x6,  #2
        neg             w9,  w27

        // block 0
        ldp             q24, q25, [x29, #240]
        ldp             q26, q27, [x29, #272]
        ldp             q28, q29, [x29, #304]
        ldp             q30, q31, [x29, #336]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #112]
        ldp             q2,  q3,  [x29, #144]
        dct32_combine_even0_s16 v20, v21, v22, v23
        add             v20.4s,  v20.4s,  v0.4s
        add             v21.4s,  v21.4s,  v1.4s
        add             v22.4s,  v22.4s,  v2.4s
        add             v23.4s,  v23.4s,  v3.4s
        mov             x13, x0
        add             x14, x0, x10, lsl #2
        add             x14, x14,  x10, lsl #1
        add             x14, x14, x10
        dup             v31.4s,  w9
        dct16_odd_add_s16 x13, x14, x1, x4, 1, x5, 1, x6,  v31, v20, v21, v22, v23, v16, v17, v18, v19

        // block 1
        ldp             q24, q25, [x29, #240]
        ldp             q26, q27, [x29, #272]
        ldp             q28, q29, [x29, #304]
        ldp             q30, q31, [x29, #336]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #176]
        ldp             q2,  q3,  [x29, #208]
        dct32_combine_even1_s16 v20, v21, v22, v23
        add             v20.4s,  v20.4s,  v0.4s
        add             v21.4s,  v21.4s,  v1.4s
        add             v22.4s,  v22.4s,  v2.4s
        add             v23.4s,  v23.4s,  v3.4s
        add             x13,     x0,    x10
        add             x14, x0, x10, lsl #2
        add             x14, x14,  x10, lsl #1
        dup             v31.4s,  w9
        dct16_odd_add_s16 x13, x14, x1, x4, 1, x5, 1, x6,  v31, v20, v21, v22, v23, v16, v17, v18, v19

        // block 2
        ldp             q24, q25, [x29, #240]
        ldp             q26, q27, [x29, #272]
        ldp             q28, q29, [x29, #304]
        ldp             q30, q31, [x29, #336]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #176]
        ldp             q2,  q3,  [x29, #208]
        dct32_combine_even1_s16 v20, v21, v22, v23
        sub             v4.4s,   v23.4s,  v3.4s
        sub             v5.4s,   v22.4s,  v2.4s
        sub             v6.4s,   v21.4s,  v1.4s
        sub             v7.4s,   v20.4s,  v0.4s
        add             x13, x0, x10, lsl #1
        add             x14, x13,  x10, lsl #1
        add             x14, x14, x10
        dup             v31.4s,  w9
        dct16_odd_add_s16 x13, x14, x1, x4, 1, x5, 1, x6,  v31, v4,  v5,  v6,  v7,  v16, v17, v18, v19

        // block 3
        ldp             q24, q25, [x29, #240]
        ldp             q26, q27, [x29, #272]
        ldp             q28, q29, [x29, #304]
        ldp             q30, q31, [x29, #336]
        dct32_odd_dot_block_s16 x11, x12, x15, v16, v17, v18, v19, v20, v21
        ldp             q0,  q1,  [x29, #112]
        ldp             q2,  q3,  [x29, #144]
        dct32_combine_even0_s16 v20, v21, v22, v23
        sub             v4.4s,   v23.4s,  v3.4s
        sub             v5.4s,   v22.4s,  v2.4s
        sub             v6.4s,   v21.4s,  v1.4s
        sub             v7.4s,   v20.4s,  v0.4s
        add             x13, x0, x10, lsl #1
        add             x13, x13, x10
        add             x14, x13, x10
        dup             v31.4s,  w9
        dct16_odd_add_s16 x13, x14, x1, x4, 1, x5, 1, x6,  v31, v4,  v5,  v6,  v7,  v16, v17, v18, v19

        add             w28, w28, #4
        cmp             w28, w24
        b.lt            L(dct32_col_s16_loop)
99:
        ldp             d14, d15, [x29, #416]
        ldp             d12, d13, [x29, #400]
        ldp             d10, d11, [x29, #384]
        ldp             d8,  d9,  [x29, #368]
        ldp             x23, x24, [x29, #48]
        ldp             x19, x20, [x29, #32]
        ldp             x27, x28, [x29, #16]
        ldr             x29, [sp]
        add             sp, sp, #432
        ret
endfunc

// The identity row/col families only differ in block size and the
// widen/multiply step, so generate them from common macros to keep the scale
// and noscale paths in sync.
.macro identity_row_block_s16 do_scale, src, src_stride, dst, dst_stride, src_inc=0, dst_inc=0
        load_4_strided  d4,  d5,  d6,  d7,  \src, \src, \src_stride, \src_inc
        cbz             \do_scale, 1f
        sqrdmulh        v4.4h,   v4.4h,   v30.4h
        sqrdmulh        v5.4h,   v5.4h,   v30.4h
        sqrdmulh        v6.4h,   v6.4h,   v30.4h
        sqrdmulh        v7.4h,   v7.4h,   v30.4h
1:
        smull           v16.4s,  v4.4h,   v0.4h
        smull           v17.4s,  v5.4h,   v0.4h
        smull           v18.4s,  v6.4h,   v0.4h
        smull           v19.4s,  v7.4h,   v0.4h
        shift_and_narrow_4x4s v16, v17, v18, v19, v16, v17, v18, v19, v31
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        store_4_strided d16, d17, d18, d19, \dst, \dst, \dst_stride, \dst_inc
.endm

.macro identity_col_block_s16_x4 src0, src1, src2, src3, dst0, dst1, dst2, dst3
        smull           \dst0\().4s,  \src0\().4h,  v29.4h
        smull           \dst1\().4s,  \src1\().4h,  v29.4h
        smull           \dst2\().4s,  \src2\().4h,  v29.4h
        smull           \dst3\().4s,  \src3\().4h,  v29.4h
        shift_and_narrow_4x4s \dst0, \dst1, \dst2, \dst3, \dst0, \dst1, \dst2, \dst3, v31
.endm

function inv_identity4_1d_row_8bpc_neon, export=1
        lsl             x8,  x3,  #1
        neg             w10, w4
        lsl             x9,  x1,  #1
        dup             v31.4s,  w10  // -shift
        movi            v0.4h,   #128  // amount
        mov             w11, #RECT2_SCALE
        mov             x16, x0
        dup             v30.4h,  w11
        mov             x12, #0
L(id4_row_s16_loop):
        add             x14, x2,  x12, lsl #1
        identity_row_block_s16 w5,  x14, x8,  x16, x9,  0, 1
        add             x12, x12, #4
        cmp             w12, w6
        b.lt            L(id4_row_s16_loop)
        itx_row_zero_tail_s16 x16, x2,  w3,  w1,  w6
        ret
endfunc

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
.macro inv_identity_row_s16 name, size, amount
function \name, export=1
        lsl             x8,  x3,  #1
        neg             w10, w4
        lsl             x9,  x1,  #1
        dup             v31.4s,  w10  // -shift
        mov             w11, #\amount
        dup             v0.4h,   w11  // amount
        mov             w11, #RECT2_SCALE
        mov             x12, #0
        dup             v30.4h,  w11
        mov             x16, x0
2:
        add             x14, x2,  x12, lsl #1
        mov             x17, #0
        mov             x10, x14
3:
        add             x11, x16, x17, lsl #1
        identity_row_block_s16 w5,  x10, x8,  x11, x9,  1, 0
        add             x17, x17, #4
        cmp             x17, #\size
        b.lt            3b
        add             x16, x16, x9,  lsl #2
        add             x12, x12, #4
        cmp             w12, w6
        b.lt            2b
        itx_row_zero_tail_s16 x16, x2,  w3,  w1,  w6
        ret
endfunc
.endm

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
.macro inv_identity_col_s16 name, size, size_shift, amount
function \name, export=1
        lsr             w4,  w4,  #6
        lsr             w5,  w5,  #(\size_shift + 1)
        lsl             x8,  x3,  #1
        neg             w10, w6
        dup             v31.4s,  w10  // -shift
        mov             w10, #4
        mov             w12, #0
        lsl             w10, w10, w4  // (4 << repx_shift)
        mov             w17, #\amount
        mov             w13, #0
        dup             v29.4h,  w17  // amount
2:
        add             x14, x2,  x12, lsl #1
        add             x15, x0,  x13
        mov             w11, #0
3:
        load_4_strided  d4,  d5,  d6,  d7,  x14, x14, x8,  1
        identity_col_block_s16_x4 v4,  v5,  v6,  v7,  v16, v17, v18, v19
        iclip_sum4_8bpc_x4 x15, x1,  w4,  1, w5,  0, x1,  x16, v16, v17, v18, v19
        add             w11, w11, #4
        cmp             w11, #\size
        b.lt            3b
        add             w12, w12, #4
        add             w13, w13, w10
        cmp             w12, w7
        b.lt            2b
        ret
endfunc
.endm

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: shift, x5: do_scale,
// x6: howmany
// 4-wide is specialized to avoid the inner loop.
inv_identity_row_s16 inv_identity8_1d_row_8bpc_neon, 8, 181
inv_identity_row_s16 inv_identity16_1d_row_8bpc_neon, 16, 256
inv_identity_row_s16 inv_identity32_1d_row_8bpc_neon, 32, 362

// x0: dst, x1: dst_stride, x2: c, x3: stride, x4: w, x5: h, x6: shift,
// x7: howmany
inv_identity_col_s16 inv_identity4_1d_col_8bpc_neon, 4, 2, 128
inv_identity_col_s16 inv_identity8_1d_col_8bpc_neon, 8, 3, 181
inv_identity_col_s16 inv_identity16_1d_col_8bpc_neon, 16, 4, 256
inv_identity_col_s16 inv_identity32_1d_col_8bpc_neon, 32, 5, 362

.macro residual_add_store4_u8_x4 dst, dst_stride, ptr_tmp, a, b, c, d, inc=0
        load_4_strided  s4,  s5,  s6,  s7,  \dst, \ptr_tmp, \dst_stride, 0
        ushll           v4.8h,   v4.8b,   #0
        ushll           v5.8h,   v5.8b,   #0
        ushll           v6.8h,   v6.8b,   #0
        ushll           v7.8h,   v7.8b,   #0
        sqadd           v\a\().8h, v\a\().8h, v4.8h
        sqadd           v\b\().8h, v\b\().8h, v5.8h
        sqadd           v\c\().8h, v\c\().8h, v6.8h
        sqadd           v\d\().8h, v\d\().8h, v7.8h
        sqxtun          v\a\().8b, v\a\().8h
        sqxtun          v\b\().8b, v\b\().8h
        sqxtun          v\c\().8b, v\c\().8h
        sqxtun          v\d\().8b, v\d\().8h
  .if \inc
        store_4_strided s\a, s\b, s\c, s\d, \dst, \dst, \dst_stride, 1
  .else
        store_4_strided s\a, s\b, s\c, s\d, \dst, \ptr_tmp, \dst_stride, 0
  .endif
.endm

.macro load_idtx_s16_x4 src, src_stride, ptr_tmp, out0, out1, out2, out3, inc=0
  .if \inc
        load_4_strided  d4,  d5,  d6,  d7,  \src, \src, \src_stride, 1
  .else
        load_4_strided  d4,  d5,  d6,  d7,  \src, \ptr_tmp, \src_stride, 0
  .endif
        smull           v\out0\().4s, v4.4h,   v0.4h
        smull           v\out1\().4s, v5.4h,   v0.4h
        smull           v\out2\().4s, v6.4h,   v0.4h
        smull           v\out3\().4s, v7.4h,   v0.4h
        shift_and_narrow_4x4s v\out0, v\out1, v\out2, v\out3, v\out0, v\out1, v\out2, v\out3, v31
.endm

.macro prefix_sum_local_s16 s0, s1, s2, s3
        add             \s1\().4h,  \s0\().4h,  \s1\().4h
        add             \s2\().4h,  \s1\().4h,  \s2\().4h
        add             \s3\().4h,  \s2\().4h,  \s3\().4h
.endm

.macro prefix_sum_accum_s16_to_s32 acc, s0, s1, s2, s3, d0, d1, d2, d3
        saddw           \d0\().4s,  \acc\().4s,  \s0\().4h
        saddw           \d1\().4s,  \d0\().4s,   \s1\().4h
        saddw           \d2\().4s,  \d1\().4s,   \s2\().4h
        saddw           \d3\().4s,  \d2\().4s,   \s3\().4h
        mov             \acc\().16b, \d3\().16b
.endm

.macro inv_wht4_1d_s16 c0, c1, c2, c3, t0, t2, t4
        add             \t0\().4h,  \c0\().4h,  \c1\().4h
        sub             \t2\().4h,  \c2\().4h,  \c3\().4h
        sub             \t4\().4h,  \t0\().4h,  \t2\().4h
        sshr            \t4\().4h,  \t4\().4h,  #1
        sub             \c2\().4h,  \t4\().4h,  \c1\().4h
        sub             \c1\().4h,  \t4\().4h,  \c3\().4h
        sub             \c0\().4h,  \t0\().4h,  \c1\().4h
        add             \c3\().4h,  \t2\().4h,  \c2\().4h
.endm

// x0: dst, x1: dst_stride, x2: c, x3: w, x4: h, x5: shift, x6: txtp
.macro residual_add_idtx_s16 name, amount
function \name, export=1
        lsl             x8,  x3,  #1
        neg             w10, w5
        lsr             w9,  w6,  #8
        mov             w11, #\amount
        dup             v31.4s,  w10  // -shift
        dup             v0.4h,   w11  // amount
        cbz             w9,  L(ridtx_s16_case0_\@)
        tbz             w9,  #1, L(ridtx_s16_case1_\@)

        mov             w12, w3
L(ridtx_s16_case2_x_\@):
        mov             x13, x2
        mov             x14, x0
        movi            v24.16b, #0
        mov             w11, w4
L(ridtx_s16_case2_y_\@):
        load_idtx_s16_x4 x13, x8,  x16, 16, 17, 18, 19, 1
        prefix_sum_accum_s16_to_s32 v24, v16, v17, v18, v19, v20, v21, v22, v23
        sqxtn           v20.4h,  v20.4s
        sqxtn           v21.4h,  v21.4s
        sqxtn           v22.4h,  v22.4s
        sqxtn           v23.4h,  v23.4s
        residual_add_store4_u8_x4 x14, x1,  x16, 20, 21, 22, 23, 1
        subs            w11, w11, #4
        b.ne            L(ridtx_s16_case2_y_\@)
        add             x2,  x2,  #8
        add             x0,  x0,  #4
        subs            w12, w12, #4
        b.ne            L(ridtx_s16_case2_x_\@)
        ret

L(ridtx_s16_case1_\@):
        mov             w12, w4
L(ridtx_s16_case1_y_\@):
        movi            v24.16b, #0
        mov             x13, x2
        mov             x14, x0
        mov             w15, w3
L(ridtx_s16_case1_x_\@):
        load_idtx_s16_x4 x13, x8,  x16, 16, 17, 18, 19
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        prefix_sum_accum_s16_to_s32 v24, v16, v17, v18, v19, v20, v21, v22, v23
        transpose_4x4s  v20, v21, v22, v23, v16, v17, v18, v19
        sqxtn           v20.4h,  v20.4s
        sqxtn           v21.4h,  v21.4s
        sqxtn           v22.4h,  v22.4s
        sqxtn           v23.4h,  v23.4s
        residual_add_store4_u8_x4 x14, x1,  x16, 20, 21, 22, 23
        add             x13, x13, #8
        add             x14, x14, #4
        subs            w15, w15, #4
        b.ne            L(ridtx_s16_case1_x_\@)
        add             x2,  x2,  x8,  lsl #2
        add             x0,  x0,  x1,  lsl #2
        subs            w12, w12, #4
        b.ne            L(ridtx_s16_case1_y_\@)
        ret

L(ridtx_s16_case0_\@):
        mov             w12, w4
L(ridtx_s16_case0_y_\@):
        mov             x13, x2
        mov             x14, x0
        mov             w15, w3
L(ridtx_s16_case0_x_\@):
        load_idtx_s16_x4 x13, x8,  x16, 16, 17, 18, 19
        residual_add_store4_u8_x4 x14, x1,  x16, 16, 17, 18, 19
        add             x13, x13, #8
        add             x14, x14, #4
        subs            w15, w15, #4
        b.ne            L(ridtx_s16_case0_x_\@)
        add             x2,  x2,  x8,  lsl #2
        add             x0,  x0,  x1,  lsl #2
        subs            w12, w12, #4
        b.ne            L(ridtx_s16_case0_y_\@)
        ret
endfunc
.endm

// x0: dst, x1: dst_stride, x2: c, x3: w, x4: h, x5: shift, x6: txtp
residual_add_idtx_s16 residual_add_idtx4_8bpc_neon, 128
residual_add_idtx_s16 residual_add_idtx8_8bpc_neon, 181
residual_add_idtx_s16 residual_add_idtx16_8bpc_neon, 256
residual_add_idtx_s16 residual_add_idtx32_8bpc_neon, 362

.macro shift_and_narrow_4x4s_imm dst0, dst1, dst2, dst3, src0, src1, src2, src3, shift
        sqrshrn         \dst0\().4h, \src0\().4s, #\shift
        sqrshrn         \dst1\().4h, \src1\().4s, #\shift
        sqrshrn         \dst2\().4h, \src2\().4s, #\shift
        sqrshrn         \dst3\().4h, \src3\().4s, #\shift
.endm

.macro txfm4_dct_s16 shift
        movi            v4.4h,   #83  // dct_qtable_s16[0]
        movi            v5.4h,   #35  // dct_qtable_s16[1]
        dct4_1d_body_s16 0, wzr, v30, v4,  v5
        shift_and_narrow_4x4s_imm v16, v17, v18, v19, v0,  v1,  v2,  v3,  \shift
.endm

.macro txfm4_dst_s16 coeffs, shift
        movrel          x8,  \coeffs
        ldp             q4,  q5,  [x8]

        dot1_4rows_s16  smull, v16, v17, v18, v19, v0,  .4h, v4,  v4,  v5,  v5,  0, 4
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v1,  .4h, v4,  v4,  v5,  v5,  1, 5
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v2,  .4h, v4,  v4,  v5,  v5,  2, 6
        dot1_4rows_s16  smlal, v16, v17, v18, v19, v3,  .4h, v4,  v4,  v5,  v5,  3, 7

        shift_and_narrow_4x4s_imm v16, v17, v18, v19, v16, v17, v18, v19, \shift
.endm

.macro txfm4_adst_s16 shift
        txfm4_dst_s16   adst4_coeffs_s16, \shift
.endm

.macro txfm4_flipadst_s16 shift
        txfm4_dst_s16   flipadst4_coeffs_s16, \shift
.endm

.macro txfm4_identity_s16 shift
        sshll           v16.4s,  v0.4h,   #7
        sshll           v17.4s,  v1.4h,   #7
        sshll           v18.4s,  v2.4h,   #7
        sshll           v19.4s,  v3.4h,   #7
        shift_and_narrow_4x4s_imm v16, v17, v18, v19, v16, v17, v18, v19, \shift
.endm

.macro inv_txfm_add_4x4_body first, second
        ldp             d0,  d1,  [x2]
        ldp             d2,  d3,  [x2,  #16]
        stp             xzr, xzr, [x2]
        stp             xzr, xzr, [x2,  #16]

        txfm4_\first\()_s16 7
        transpose_4x4h  v0,  v1,  v2,  v3,  v16, v17, v18, v19, v20, v21, v22, v23

        txfm4_\second\()_s16 10
.endm

// x0: dst, x1: dst_stride, x2: coeff, x3: txtp
.macro inv_txfm_add_4x4_s16 name, first, second
function inv_txfm_add_4x4_\name\()_8bpc_neon, export=1
        inv_txfm_add_4x4_body \first, \second
        residual_add_store4_u8_x4 x0,  x1,  x6,  16, 17, 18, 19
        ret
endfunc
.endm

// x0: dst, x1: dst_stride, x2: coeff, x3: txtp
function inv_txfm_add_4x4_identity_identity_dpcm_8bpc_neon, export=1
        inv_txfm_add_4x4_body identity, identity

        // The residual_add DPCM case 0 is unreachable here, so just need to
        // distinguish between transposed prefix and normal prefix sum.
        tbz             w3,  #9, 1f

        prefix_sum_local_s16 v16, v17, v18, v19
        b               99f

1:
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        prefix_sum_local_s16 v16, v17, v18, v19
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23

99:
        residual_add_store4_u8_x4 x0,  x1,  x6,  16, 17, 18, 19
        ret
endfunc

inv_txfm_add_4x4_s16 dct_dct,           dct,      dct
inv_txfm_add_4x4_s16 dct_identity,      dct,      identity
inv_txfm_add_4x4_s16 dct_adst,          dct,      adst
inv_txfm_add_4x4_s16 dct_flipadst,      dct,      flipadst
inv_txfm_add_4x4_s16 identity_dct,      identity, dct
inv_txfm_add_4x4_s16 identity_identity, identity, identity
inv_txfm_add_4x4_s16 identity_adst,     identity, adst
inv_txfm_add_4x4_s16 identity_flipadst, identity, flipadst
inv_txfm_add_4x4_s16 adst_dct,          adst,     dct
inv_txfm_add_4x4_s16 adst_identity,     adst,     identity
inv_txfm_add_4x4_s16 adst_adst,         adst,     adst
inv_txfm_add_4x4_s16 adst_flipadst,     adst,     flipadst
inv_txfm_add_4x4_s16 flipadst_dct,      flipadst, dct
inv_txfm_add_4x4_s16 flipadst_identity, flipadst, identity
inv_txfm_add_4x4_s16 flipadst_adst,     flipadst, adst
inv_txfm_add_4x4_s16 flipadst_flipadst, flipadst, flipadst

// x0: dst, x1: dst_stride, x2: coeff, x3: txtp
function inv_txfm_add_4x4_wht_wht_8bpc_neon, export=1
        lsr             w5,  w3,  #8
        ldp             d16, d17, [x2]
        ldp             d18, d19, [x2,  #16]
        sshr            v16.4h,  v16.4h,  #3
        sshr            v17.4h,  v17.4h,  #3
        sshr            v18.4h,  v18.4h,  #3
        sshr            v19.4h,  v19.4h,  #3
        stp             xzr, xzr, [x2]
        stp             xzr, xzr, [x2,  #16]

        inv_wht4_1d_s16 v16, v17, v18, v19, v20, v21, v22
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        inv_wht4_1d_s16 v16, v17, v18, v19, v20, v21, v22

        cbz             w5,  L(wht4_s16_store)
        tbz             w5,  #1, L(wht4_s16_case1)

        prefix_sum_local_s16 v16, v17, v18, v19
        b               L(wht4_s16_store)

L(wht4_s16_case1):
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23
        prefix_sum_local_s16 v16, v17, v18, v19
        transpose_4x4h  v16, v17, v18, v19, v16, v17, v18, v19, v20, v21, v22, v23

L(wht4_s16_store):
        residual_add_store4_u8_x4 x0,  x1,  x6,  16, 17, 18, 19
        ret
endfunc

// x0: dst, x1: dst_stride, x2: coeff, x3: shift0, x4: shift1, x5: w,
// x6: h, x7: is_rect2
function itx_dc_only_8bpc_neon, export=1
        add             w8,  w3,  w4
        ldrsh           w10, [x2]      // dc = coeff[0]
        sub             w8,  w8,  #12  // shift = shift0 + shift1 - 12
        mov             w9,  #1
        strh            wzr, [x2]
        sub             w11, w8,  #1
        lsl             w9,  w9,  w11
        add             w9,  w9,  w3
        sub             w9,  w9,  #6  // rnd = (1 << (shift - 1)) + shift0 - 6
        cbz             w7,  1f       // If !is_rect2 skip to 1f.

        mov             w11, #181
        mov             w12, #128
        madd            w10, w10, w11, w12
        asr             w10, w10, #8  // dc = (dc * 181 + 128) >> 8
1:
        add             w10, w10, w9
        asr             w10, w10, w8  // dc = (dc + rnd) >> shift

        // Use fallback if dc does not fit in 8 bits.
        sxtb            w11, w10
        cmp             w10, w11
        b.ne            L(itx_dc_only_fallback)

        dup             v31.16b, w10
        cmp             w5,  #8
        b.eq            L(itx_dc_only_fast_w8)
        b.lt            L(itx_dc_only_fast_w4)

// If dc fits in 8 bits then can use USQADD to add and clip in a single
// instruction.
L(itx_dc_only_fast_w16_y):
        mov             x9,  x0
        add             x11, x0,  x1
        add             x12, x0,  x1,  lsl #1
        add             x13, x11, x1,  lsl #1
        mov             x14, #0
        mov             w10, w5
L(itx_dc_only_fast_w16_x):
        ldr             q0,  [x9,  x14]
        ldr             q1,  [x11, x14]
        ldr             q2,  [x12, x14]
        ldr             q3,  [x13, x14]
        subs            w10, w10, #16
        usqadd          v0.16b,  v31.16b
        usqadd          v1.16b,  v31.16b
        usqadd          v2.16b,  v31.16b
        usqadd          v3.16b,  v31.16b
        str             q0,  [x9,  x14]
        str             q1,  [x11, x14]
        str             q2,  [x12, x14]
        str             q3,  [x13, x14]
        add             x14, x14, #16
        b.ne            L(itx_dc_only_fast_w16_x)

        add             x0,  x0,  x1,  lsl #2
        subs            w6,  w6,  #4
        b.ne            L(itx_dc_only_fast_w16_y)
        ret

L(itx_dc_only_fast_w8):
        load_4_strided  d0,  d1,  d2,  d3,  x0,  x9,  x1
        subs            w6,  w6,  #4
        usqadd          v0.8b,   v31.8b
        usqadd          v1.8b,   v31.8b
        usqadd          v2.8b,   v31.8b
        usqadd          v3.8b,   v31.8b
        store_4_strided d0,  d1,  d2,  d3,  x0,  x0,  x1,  1
        b.ne            L(itx_dc_only_fast_w8)
        ret

L(itx_dc_only_fast_w4):
        load_4_strided  s0,  s1,  s2,  s3,  x0,  x9,  x1
        subs            w6,  w6,  #4
        usqadd          v0.8b,   v31.8b
        usqadd          v1.8b,   v31.8b
        usqadd          v2.8b,   v31.8b
        usqadd          v3.8b,   v31.8b
        store_4_strided s0,  s1,  s2,  s3,  x0,  x0,  x1,  1
        b.ne            L(itx_dc_only_fast_w4)
        ret

// If dc does not fit in 8 bits then need separate addition and clipping steps.
L(itx_dc_only_fallback):
        dup             v31.8h,  w10
        cmp             w5,  #8
        b.eq            L(itx_dc_only_w8)
        b.lt            L(itx_dc_only_w4)

L(itx_dc_only_w16_y):
        mov             x9,  x0
        add             x11, x0,  x1
        add             x12, x0,  x1,  lsl #1
        add             x13, x11, x1,  lsl #1
        mov             x14, #0
        mov             w10, w5
L(itx_dc_only_w16_x):
        ldr             q0,  [x9,  x14]
        ldr             q1,  [x11, x14]
        ldr             q2,  [x12, x14]
        ldr             q3,  [x13, x14]
        subs            w10, w10, #16
        uaddw           v4.8h,   v31.8h,  v0.8b
        uaddw           v5.8h,   v31.8h,  v1.8b
        uaddw           v6.8h,   v31.8h,  v2.8b
        uaddw           v7.8h,   v31.8h,  v3.8b
        uaddw2          v16.8h,  v31.8h,  v0.16b
        uaddw2          v17.8h,  v31.8h,  v1.16b
        uaddw2          v18.8h,  v31.8h,  v2.16b
        uaddw2          v19.8h,  v31.8h,  v3.16b
        sqxtun          v4.8b,   v4.8h
        sqxtun          v5.8b,   v5.8h
        sqxtun          v6.8b,   v6.8h
        sqxtun          v7.8b,   v7.8h
        sqxtun2         v4.16b,  v16.8h
        sqxtun2         v5.16b,  v17.8h
        sqxtun2         v6.16b,  v18.8h
        sqxtun2         v7.16b,  v19.8h
        str             q4,  [x9,  x14]
        str             q5,  [x11, x14]
        str             q6,  [x12, x14]
        str             q7,  [x13, x14]
        add             x14, x14, #16
        b.ne            L(itx_dc_only_w16_x)

        add             x0,  x0,  x1,  lsl #2
        subs            w6,  w6,  #4
        b.ne            L(itx_dc_only_w16_y)
        ret

L(itx_dc_only_w8):
        load_4_strided  d0,  d1,  d2,  d3,  x0,  x9,  x1
        subs            w6,  w6,  #4
        uaddw           v4.8h,   v31.8h,  v0.8b
        uaddw           v5.8h,   v31.8h,  v1.8b
        uaddw           v6.8h,   v31.8h,  v2.8b
        uaddw           v7.8h,   v31.8h,  v3.8b
        sqxtun          v4.8b,   v4.8h
        sqxtun          v5.8b,   v5.8h
        sqxtun          v6.8b,   v6.8h
        sqxtun          v7.8b,   v7.8h
        store_4_strided d4,  d5,  d6,  d7,  x0,  x0,  x1,  1
        b.ne            L(itx_dc_only_w8)
        ret

L(itx_dc_only_w4):
        load_4_strided  s0,  s1,  s2,  s3,  x0,  x9,  x1
        subs            w6,  w6,  #4
        uaddw           v4.8h,   v31.8h,  v0.8b
        uaddw           v5.8h,   v31.8h,  v1.8b
        uaddw           v6.8h,   v31.8h,  v2.8b
        uaddw           v7.8h,   v31.8h,  v3.8b
        sqxtun          v4.8b,   v4.8h
        sqxtun          v5.8b,   v5.8h
        sqxtun          v6.8b,   v6.8h
        sqxtun          v7.8b,   v7.8h
        store_4_strided s4,  s5,  s6,  s7,  x0,  x0,  x1,  1
        b.ne            L(itx_dc_only_w4)
        ret
endfunc

const dct_qtable_s16, align=4
        .short             83,   35,    0,    0
        .short             89,   75,   50,   18
endconst

const dct16_odd_qtable_s16, align=4
        .short             90,   87,   80,   70
        .short             57,   43,   26,    9
endconst

const dct32_odd_coeffs_s16, align=4
        .short             90,   90,   88,   85,   82,   78,   73,   67,   61,   54,   47,   39,   30,   22,   13,    4
        .short             90,   82,   67,   47,   22,   -4,  -30,  -54,  -73,  -85,  -90,  -88,  -78,  -61,  -39,  -13
        .short             88,   67,   30,  -13,  -54,  -82,  -90,  -78,  -47,   -4,   39,   73,   90,   85,   61,   22
        .short             85,   47,  -13,  -67,  -90,  -73,  -22,   39,   82,   88,   54,   -4,  -61,  -90,  -78,  -30
        .short             82,   22,  -54,  -90,  -61,   13,   78,   85,   30,  -47,  -90,  -67,    4,   73,   88,   39
        .short             78,   -4,  -82,  -73,   13,   85,   67,  -22,  -88,  -61,   30,   90,   54,  -39,  -90,  -47
        .short             73,  -30,  -90,  -22,   78,   67,  -39,  -90,  -13,   82,   61,  -47,  -88,   -4,   85,   54
        .short             67,  -54,  -78,   39,   85,  -22,  -90,    4,   90,   13,  -88,  -30,   82,   47,  -73,  -61
        .short             61,  -73,  -47,   82,   30,  -88,  -13,   90,   -4,  -90,   22,   85,  -39,  -78,   54,   67
        .short             54,  -85,   -4,   88,  -47,  -61,   82,   13,  -90,   39,   67,  -78,  -22,   90,  -30,  -73
        .short             47,  -90,   39,   54,  -90,   30,   61,  -88,   22,   67,  -85,   13,   73,  -82,    4,   78
        .short             39,  -88,   73,   -4,  -67,   90,  -47,  -30,   85,  -78,   13,   61,  -90,   54,   22,  -82
        .short             30,  -78,   90,  -61,    4,   54,  -88,   82,  -39,  -22,   73,  -90,   67,  -13,  -47,   85
        .short             22,  -61,   85,  -90,   73,  -39,   -4,   47,  -78,   90,  -82,   54,  -13,  -30,   67,  -88
        .short             13,  -39,   61,  -78,   88,  -90,   85,  -73,   54,  -30,    4,   22,  -47,   67,  -82,   90
        .short              4,  -13,   22,  -30,   39,  -47,   54,  -61,   67,  -73,   78,  -82,   85,  -88,   90,  -90
endconst

const adst4_coeffs_s16, align=4
        .short           18,   50,   75,   89
        .short           50,   89,   18,  -75
        .short           75,   18,  -89,   50
        .short           89,  -75,   50,  -18
endconst

const adst8_coeffs_s16, align=4
        .short           11,   34,   54,   71,   84,   88,   79,   50
        .short           28,   74,   89,   68,   17,  -44,  -83,  -69
        .short           44,   89,   48,  -41,  -89,  -44,   50,   81
        .short           58,   76,  -34,  -86,   10,   88,    6,  -84
        .short           70,   39,  -87,    1,   86,  -44,  -59,   78
        .short           79,  -12,  -66,   87,  -35,  -44,   86,  -62
        .short           86,  -58,   12,   38,  -75,   88,  -74,   40
        .short           89,  -86,   79,  -70,   58,  -44,   29,  -14
endconst

const adst16_coeffs_s16, align=4
        .short            8,   25,   41,   55,   67,   77,   84,   88,   89,   87,   81,   73,   62,   48,   33,   17
        .short           17,   48,   73,   87,   88,   77,   55,   25,   -8,  -41,  -67,  -84,  -89,  -81,  -62,  -33
        .short           25,   67,   88,   81,   48,    0,  -48,  -81,  -88,  -67,  -25,   25,   67,   88,   81,   48
        .short           33,   81,   84,   41,  -25,  -77,  -87,  -48,   17,   73,   88,   55,   -8,  -67,  -89,  -62
        .short           41,   88,   62,  -17,  -81,  -77,   -8,   67,   87,   33,  -48,  -89,  -55,   25,   84,   73
        .short           48,   88,   25,  -67,  -81,    0,   81,   67,  -25,  -88,  -48,   48,   88,   25,  -67,  -81
        .short           55,   81,  -17,  -89,  -25,   77,   62,  -48,  -84,    8,   88,   33,  -73,  -67,   41,   87
        .short           62,   67,  -55,  -73,   48,   77,  -41,  -81,   33,   84,  -25,  -87,   17,   88,   -8,  -89
        .short           67,   48,  -81,  -25,   88,    0,  -88,   25,   81,  -48,  -67,   67,   48,  -81,  -25,   88
        .short           73,   25,  -89,   33,   67,  -77,  -17,   88,  -41,  -62,   81,    8,  -87,   48,   55,  -84
        .short           77,    0,  -77,   77,    0,  -77,   77,    0,  -77,   77,    0,  -77,   77,    0,  -77,   77
        .short           81,  -25,  -48,   88,  -67,    0,   67,  -88,   48,   25,  -81,   81,  -25,  -48,   88,  -67
        .short           84,  -48,   -8,   62,  -88,   77,  -33,  -25,   73,  -89,   67,  -17,  -41,   81,  -87,   55
        .short           87,  -67,   33,    8,  -48,   77,  -89,   81,  -55,   17,   25,  -62,   84,  -88,   73,  -41
        .short           88,  -81,   67,  -48,   25,    0,  -25,   48,  -67,   81,  -88,   88,  -81,   67,  -48,   25
        .short           89,  -88,   87,  -84,   81,  -77,   73,  -67,   62,  -55,   48,  -41,   33,  -25,   17,   -8
endconst

const flipadst4_coeffs_s16, align=4
        .short           89,   75,   50,   18
        .short           75,  -18,  -89,  -50
        .short           50,  -89,   18,   75
        .short           18,  -50,   75,  -89
endconst

const ddt8_coeffs_s16, align=4
        .short            4,    6,   22,   57,   96,  103,   78,   56
        .short            7,   14,   48,   94,   73,  -17,  -79,  -96
        .short           15,   36,   85,   76,  -43,  -80,    7,   98
        .short           33,   77,   88,  -26,  -69,   56,   56,  -77
        .short           65,  100,    0,  -73,   55,   15,  -82,   54
        .short           98,   45,  -86,   34,   20,  -66,   79,  -33
        .short          106,  -57,  -23,   54,  -71,   75,  -56,   19
        .short           80,  -98,   82,  -66,   53,  -41,   26,   -6
endconst

const ddt16_coeffs_s16, align=4
        .short           12,   17,   37,   45,   47,   60,   64,   82,   89,  100,   92,   84,   69,   50,   51,   44
        .short           15,   23,   49,   60,   60,   74,   70,   73,   48,    9,  -35,  -71,  -83,  -79,  -89,  -95
        .short           19,   30,   60,   69,   61,   64,   40,    3,  -53,  -99,  -91,  -46,    2,   47,   73,  124
        .short           23,   38,   69,   73,   49,   28,  -19,  -80,  -96,  -45,   42,   88,   75,   14,  -17, -126
        .short           30,   48,   75,   66,   19,  -31,  -79,  -91,   -5,   84,   71,  -16,  -78,  -60,  -45,  108
        .short           39,   61,   75,   40,  -29,  -87,  -78,   10,   89,   36,  -69,  -67,   18,   67,   89,  -81
        .short           51,   76,   61,   -8,  -77,  -82,   11,   94,   16,  -81,  -22,   79,   50,  -37, -103,   54
        .short           66,   87,   29,  -65,  -83,    4,   92,   18,  -83,    4,   85,  -22,  -85,   -6,   97,  -30
        .short           78,   83,  -18,  -91,  -16,   88,   28,  -84,   12,   73,  -60,  -46,   81,   49,  -83,   16
        .short           88,   59,  -67,  -57,   75,   54,  -85,   -5,   75,  -60,  -17,   84,  -43,  -80,   71,   -6
        .short           94,   19,  -96,   21,   93,  -55,  -41,   80,  -51,  -17,   77,  -68,   -6,   98,  -56,    1
        .short           97,  -30,  -83,   86,    3,  -77,   82,  -17,  -43,   76,  -70,   15,   53,  -99,   44,    3
        .short           93,  -73,  -28,   81,  -92,   29,   39,  -70,   81,  -55,   11,   46,  -81,   90,  -31,   -4
        .short           83,  -99,   40,    8,  -74,   88,  -83,   47,  -14,  -21,   56,  -83,   88,  -71,   22,    5
        .short           68,  -99,   84,  -69,   32,    3,  -37,   55,  -75,   81,  -83,   82,  -69,   48,  -11,   -3
        .short           50,  -76,   83,  -90,   97,  -86,   83,  -68,   67,  -56,   49,  -40,   32,  -19,    5,    2
endconst

const flipadst16_coeffs_s16, align=4
        .short           89,   88,   87,   84,   81,   77,   73,   67,   62,   55,   48,   41,   33,   25,   17,    8
        .short           88,   81,   67,   48,   25,    0,  -25,  -48,  -67,  -81,  -88,  -88,  -81,  -67,  -48,  -25
        .short           87,   67,   33,   -8,  -48,  -77,  -89,  -81,  -55,  -17,   25,   62,   84,   88,   73,   41
        .short           84,   48,   -8,  -62,  -88,  -77,  -33,   25,   73,   89,   67,   17,  -41,  -81,  -87,  -55
        .short           81,   25,  -48,  -88,  -67,    0,   67,   88,   48,  -25,  -81,  -81,  -25,   48,   88,   67
        .short           77,    0,  -77,  -77,    0,   77,   77,    0,  -77,  -77,    0,   77,   77,    0,  -77,  -77
        .short           73,  -25,  -89,  -33,   67,   77,  -17,  -88,  -41,   62,   81,   -8,  -87,  -48,   55,   84
        .short           67,  -48,  -81,   25,   88,    0,  -88,  -25,   81,   48,  -67,  -67,   48,   81,  -25,  -88
        .short           62,  -67,  -55,   73,   48,  -77,  -41,   81,   33,  -84,  -25,   87,   17,  -88,   -8,   89
        .short           55,  -81,  -17,   89,  -25,  -77,   62,   48,  -84,   -8,   88,  -33,  -73,   67,   41,  -87
        .short           48,  -88,   25,   67,  -81,    0,   81,  -67,  -25,   88,  -48,  -48,   88,  -25,  -67,   81
        .short           41,  -88,   62,   17,  -81,   77,   -8,  -67,   87,  -33,  -48,   89,  -55,  -25,   84,  -73
        .short           33,  -81,   84,  -41,  -25,   77,  -87,   48,   17,  -73,   88,  -55,   -8,   67,  -89,   62
        .short           25,  -67,   88,  -81,   48,    0,  -48,   81,  -88,   67,  -25,  -25,   67,  -88,   81,  -48
        .short           17,  -48,   73,  -87,   88,  -77,   55,  -25,   -8,   41,  -67,   84,  -89,   81,  -62,   33
        .short            8,  -25,   41,  -55,   67,  -77,   84,  -88,   89,  -87,   81,  -73,   62,  -48,   33,  -17
endconst

// void cctx_8bpc_neon(coef *const u, coef *const v, const int16_t angle[3],
//                     const size_t sz)
function cctx_8bpc_neon, export=1
        ldr             s6, [x2]
1:
        ldp             q0, q1, [x0], #32
        ldp             q2, q3, [x1], #32

        smull           v16.4s,  v0.4h,   v6.h[1]  // u[i] * cosa
        smull           v17.4s,  v1.4h,   v6.h[1]  // u[i+8] * cosa
        smull           v18.4s,  v0.4h,   v6.h[0]  // u[i] * sina
        smull           v19.4s,  v1.4h,   v6.h[0]  // u[i+8] * sina

        smlsl           v16.4s,  v2.4h,   v6.h[0]  // u[i] * cosa - v[i] * sina
        smlsl           v17.4s,  v3.4h,   v6.h[0]  // u[i+8] * cosa - v[i+8] * sina
        smull2          v20.4s,  v0.8h,   v6.h[1]  // u[i] * cosa
        smull2          v21.4s,  v1.8h,   v6.h[1]  // u[i+8] * cosa
        smlal           v18.4s,  v2.4h,   v6.h[1]  // u[i] * sina + v[i] * cosa
        smlal           v19.4s,  v3.4h,   v6.h[1]  // u[i+8] * sina + v[i+8] * cosa
        smull2          v22.4s,  v0.8h,   v6.h[0]  // u[i] * sina
        smull2          v23.4s,  v1.8h,   v6.h[0]  // u[i+8] * sina

        ssra            v16.4s,  v16.4s,  #31      // Adjust for sqrshrn rounding up
        ssra            v17.4s,  v17.4s,  #31
        smlsl2          v20.4s,  v2.8h,   v6.h[0]  // u[i] * cosa - v[i] * sina
        smlsl2          v21.4s,  v3.8h,   v6.h[0]  // u[i+8] * cosa - v[i+8] * sina
        ssra            v18.4s,  v18.4s,  #31
        ssra            v19.4s,  v19.4s,  #31
        smlal2          v22.4s,  v2.8h,   v6.h[1]  // u[i] * sina + v[i] * cosa
        smlal2          v23.4s,  v3.8h,   v6.h[1]  // u[i+8] * sina + v[i+8] * cosa

        sub             w3,  w3,  #16
        sqrshrn         v16.4h,  v16.4s,  #8
        sqrshrn         v17.4h,  v17.4s,  #8
        ssra            v20.4s,  v20.4s,  #31
        ssra            v21.4s,  v21.4s,  #31
        sqrshrn         v18.4h,  v18.4s,  #8
        sqrshrn         v19.4h,  v19.4s,  #8
        ssra            v22.4s,  v22.4s,  #31
        ssra            v23.4s,  v23.4s,  #31

        sqrshrn2        v16.8h,  v20.4s,  #8
        sqrshrn2        v17.8h,  v21.4s,  #8
        sqrshrn2        v18.8h,  v22.4s,  #8
        sqrshrn2        v19.8h,  v23.4s,  #8

        stp             q16, q17, [x0, #-32]
        stp             q18, q19, [x1, #-32]

        cbnz            w3,  1b
        ret
endfunc
