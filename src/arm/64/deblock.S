/*
 * Copyright © 2026, Arm Limited
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "src/arm/asm.S"
#include "util.S"

#define DST_STRIDE (16)

const comparisons, align=4
        .byte 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
        .byte 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
        .byte 0, 0, 0, 0, 0, 0, 0, 0
        .byte 1, 1, 1, 1, 1, 1, 1, 1
endconst

// void setup_thr_rows_sb64_seg_8bpc_neon(
//     pixel (*thr_dst)[16 * 16], const uint8_t *const segmap,
//     const ptrdiff_t seg_stride, const uint16_t (*const mask)[5][4],
//     const pixel thr_lut[2][16],
//     /*const*/ pixel above_thr_lut[2][16], const int h4, const int w4);
function setup_thr_rows_sb64_seg_8bpc_neon, export=1
        movi            v0.4s,   #0
        movi            v1.4s,   #0
        cbz             x5,  1f                             // Skip if above_thr_lut is null.
        sub             x9,  x1,  x2
        ldp             q2,  q3,  [x5]                      // q_lut and side_lut
        ldr             q4,  [x9]                           // seg_ids
        tbl             v0.16b, {v2.16b}, v4.16b
        tbl             v1.16b, {v3.16b}, v4.16b
1:
        b               setup_thr_sb64_seg_8bpc_neon_common
endfunc

.macro setup_thr_sb64_seg_8bpc_neon_common_loop w, t
        cmp             w6,  #2
        b.lt            2f
1:
    .if \w > 8
        ldr             q7,  [x1]
        ldr             q23, [x1, x2]
    .else
        ldr             d7,  [x1]
        ldr             d23, [x1, x2]
    .endif
        sub             w6,  w6,  #2
        add             x1,  x1,  x2, lsl #1
        tbl             v6\t, {v2.16b}, v7\t
        tbl             v7\t, {v3.16b}, v7\t

        ldr             h24, [x3], #40                      // Load mask.

        // umin performs `cur_[q|side]_thr && prev_[q|side]_thr`: if either is zero,
        // the result will be zero, else the arbitrary non-zero lowest value.
        // cmeq will then convert the results into a lanewise bitmask.
        umin            v16\t, v6\t,  v0\t
        umin            v20\t, v7\t,  v1\t
        // Results if the `&&` condition is false.
        orr             v17\t, v6\t,  v0\t
        orr             v21\t, v7\t,  v1\t
        // Bitmask governing whether to shift the results or not computed from
        // this tbl and the following cmtst/and.
        tbl             v24\t, {v24.16b}, v5\t
        // Results if the `&&` condition is true.
        urhadd          v18\t, v6\t,  v0\t
        urhadd          v22\t, v7\t,  v1\t
        cmeq            v16\t, v16\t, #0
        cmeq            v20\t, v20\t, #0

        cmtst           v24\t, v24\t, v4\t

        // Start of the second iteration.
        tbl             v0\t, {v2.16b}, v23\t
        tbl             v1\t, {v3.16b}, v23\t

        // -subpu: -3 or 0, to be used in ushl.
        and             v24\t, v24\t, v25\t

        bsl             v16\t, v17\t, v18\t                 // edge_q_thr
        bsl             v20\t, v21\t, v22\t                 // edge_side_thr

        ldr             h23, [x3], #40                      // Load mask.

        ushl            v16\t, v16\t, v24\t
        ushl            v20\t, v20\t, v24\t

        tbl             v23\t, {v23.16b}, v5\t
        cmgt            v26\t, v20\t, #0

        cmtst           v23\t, v23\t, v4\t

        and             v16\t, v16\t, v26\t

    .if \w > 8
        str             q20, [x0, #256]
        str             q16, [x0]
    .else
        str             d20, [x0, #256]
        str             d16, [x0]
    .endif

        umin            v16\t, v0\t,  v6\t
        umin            v20\t, v1\t,  v7\t
        orr             v17\t, v0\t,  v6\t
        orr             v21\t, v1\t,  v7\t
        and             v23\t, v23\t, v25\t
        urhadd          v18\t, v0\t,  v6\t
        urhadd          v22\t, v1\t,  v7\t
        cmeq            v16\t, v16\t, #0
        cmeq            v20\t, v20\t, #0

        cmp             w6,  #1

        bsl             v16\t, v17\t, v18\t                 // edge_q_thr
        bsl             v20\t, v21\t, v22\t                 // edge_side_thr

        ushl            v16\t, v16\t, v23\t
        ushl            v20\t, v20\t, v23\t

        cmgt            v26\t, v20\t, #0
        and             v16\t, v16\t, v26\t

    .if \w > 8
        str             q20, [x0, #(DST_STRIDE + 256)]
        str             q16, [x0, #DST_STRIDE]
    .else
        str             d20, [x0, #(DST_STRIDE + 256)]
        str             d16, [x0, #DST_STRIDE]
    .endif
        add             x0,  x0,  #(2 * DST_STRIDE)
        b.gt            1b
        b.lt            3f
        // Fallthrough for single row.
2:
    .if \w > 8
        ldr             q7,  [x1]
    .else
        ldr             d7,  [x1]
    .endif
        tbl             v6\t, {v2.16b}, v7\t
        tbl             v7\t, {v3.16b}, v7\t

        ldr             h24, [x3], #40                      // Load mask.

        // umin performs `cur_[q|side]_thr && prev_[q|side]_thr`: if either is zero,
        // the result will be zero, else the arbitrary non-zero lowest value.
        // cmeq will then convert the results into a lanewise bitmask.
        umin            v16\t, v6\t,  v0\t
        umin            v20\t, v7\t,  v1\t
        // Results if the `&&` condition is false.
        orr             v17\t, v6\t,  v0\t
        orr             v21\t, v7\t,  v1\t
        // Bitmask governing whether to shift the results or not computed from
        // this tbl and the following cmtst/and.
        tbl             v24\t, {v24.16b}, v5\t
        // Results if the `&&` condition is true.
        urhadd          v18\t, v6\t,  v0\t
        urhadd          v22\t, v7\t,  v1\t
        cmeq            v16\t, v16\t, #0
        cmeq            v20\t, v20\t, #0

        cmtst           v24\t, v24\t, v4\t

        bsl             v16\t, v17\t, v18\t                 // edge_q_thr
        bsl             v20\t, v21\t, v22\t                 // edge_side_thr

        and             v24\t, v24\t, v25\t

        mov             v0\t,  v6\t
        mov             v1\t,  v7\t

        ushl            v16\t, v16\t, v24\t
        ushl            v20\t, v20\t, v24\t

        cmgt            v26\t, v20\t, #0
        and             v16\t, v16\t, v26\t

    .if \w > 8
        str             q20, [x0, #256]
        str             q16, [x0]
    .else
        str             d20, [x0, #256]
        str             d16, [x0]
    .endif
.endm

function setup_thr_sb64_seg_8bpc_neon_common
        movrel          x9,  comparisons
        ldp             q2,  q3,  [x4]                      // q_lut and side_lut
        add             x3,  x3,  #32
        ldp             q4,  q5,  [x9]

        // -3: the conditional shift to apply using ushl.
        movi            v25.16b, #253
        cmp             w7,  #8
        b.gt            4f

        setup_thr_sb64_seg_8bpc_neon_common_loop 8,   .8b
        b               3f
4:
        setup_thr_sb64_seg_8bpc_neon_common_loop 16,  .16b
3:
        ret
endfunc

// void setup_thr_cols_sb64_seg_8bpc_neon(pixel (*thr_dst)[16 * 16],
//                                        const uint8_t *const segmap,
//                                        const ptrdiff_t seg_stride,
//                                        const uint16_t (*const mask)[5][4],
//                                        const pixel thr_lut[2][16],
//                                        pixel (*left_thr)[16],
//                                        const int w4, const int h4)
function setup_thr_cols_sb64_seg_8bpc_neon, export=1
        add             x9,  x1,  x2
        lsl             x12, x2,  #2
        lsl             x2,  x2,  #1
        sub             sp,  sp,  #256
        // Subsampling layouts:
        // 4:2:0: up to 8x8
        // 4:2:2: up to 8x16
        // 4:4:4: up to 16x16
        // Callers provide (at least) the maximum layout's (for the respective subsampling scheme)
        // amount of (strided) memory in the segmap pointer, and therefore safe loads require:
        // - Width <= 8 must be respected regardless.
        // - Height <= 8 must be respected iff width <= 8 also, as 4:2:0 chroma subsampling
        //   may supply only 8x8 pixels' worth of accessible memory from the segmap pointer.
        cmp             w6,  #8
        cset            w13, ls                             // w13 = width <= 8
        // If width > 8, immediately branch to the w16 loads, without changing the
        // NZCV flags. This ensures that we only branch on height <= 8 iff the width
        // is also <= 8.
        b.gt            L(transpose.w16)
        cmp             w7,  #8
L(transpose.w8):
        // Load all of segmap into registers v16-v31.
        ldr             d18, [x1, x2]
        ld1             {v16.8b}, [x1], x12
        ldr             d19, [x9, x2]
        ld1             {v17.8b}, [x9], x12
        ldr             d22, [x1, x2]
        ld1             {v20.8b}, [x1], x12
        ldr             d23, [x9, x2]
        ld1             {v21.8b}, [x9], x12
        b.le            L(transpose.8)                      // height <= 8

        ldr             d26, [x1, x2]
        ld1             {v24.8b}, [x1], x12
        ldr             d27, [x9, x2]
        ld1             {v25.8b}, [x9], x12
        ldr             d30, [x1, x2]
        ld1             {v28.8b}, [x1]
        ldr             d31, [x9, x2]
        ld1             {v29.8b}, [x9]
        b               L(transpose.8)

L(transpose.w16):
        // Load all of segmap into registers v16-v31.
        ldr             q18, [x1, x2]
        ld1             {v16.16b}, [x1], x12
        ldr             q19, [x9, x2]
        ld1             {v17.16b}, [x9], x12
        ldr             q22, [x1, x2]
        ld1             {v20.16b}, [x1], x12
        ldr             q23, [x9, x2]
        ld1             {v21.16b}, [x9], x12
        ldr             q26, [x1, x2]
        ld1             {v24.16b}, [x1], x12
        ldr             q27, [x9, x2]
        ld1             {v25.16b}, [x9], x12
        ldr             q30, [x1, x2]
        ld1             {v28.16b}, [x1]
        ldr             q31, [x9, x2]
        ld1             {v29.16b}, [x9]

        // Transpose segmap
        // [[ a0 a1 a2 ... a15 ],
        //             ...
        //  [ p0 p1 p2 ... p15]]

        // 8-bit
        // [[ ab0 ab1 ... ab6  ab7  ],
        //  [ ab8 ab9 ... ab14 ab15 ],
        //            ...
        //  [ op0 op1 ... op6  op7  ],
        //  [ op8 op9 ... op14 op15 ]]
L(transpose.8):
        zip1            v0.16b,  v16.16b, v17.16b
        zip1            v2.16b,  v18.16b, v19.16b
        zip1            v4.16b,  v20.16b, v21.16b
        zip1            v6.16b,  v22.16b, v23.16b
        // Skip to the next stage if height <= 8 (and width <= 8), as we've already
        // zipped the eight rows together into the four full-width vector registers.
        b.le            L(transpose.16)
        // Skip zip2 instructions if width <= 8.
        tbnz            w13, #0,  L(transpose.8.w8)

        zip2            v1.16b,  v16.16b, v17.16b
        zip2            v3.16b,  v18.16b, v19.16b
        zip2            v5.16b,  v20.16b, v21.16b
        zip2            v7.16b,  v22.16b, v23.16b
        zip2            v17.16b, v24.16b, v25.16b
        zip2            v19.16b, v26.16b, v27.16b
        zip2            v21.16b, v28.16b, v29.16b
        zip2            v23.16b, v30.16b, v31.16b
L(transpose.8.w8):
        zip1            v16.16b, v24.16b, v25.16b
        zip1            v18.16b, v26.16b, v27.16b
        zip1            v20.16b, v28.16b, v29.16b
        zip1            v22.16b, v30.16b, v31.16b

        // 16-bit
        // [[ abcd0  abcd1  abcd2  abcd3  ],
        //  [ abcd4  abcd5  abcd6  abcd7  ],
        //  [ abcd8  abcd9  abcd10 abcd11 ],
        //  [ abcd12 abcd13 abcd14 abcd15 ],
        //  [ efgh0 ... ],
        //      ...
        //  [ mnop12 mnop13 mnop14 mnop15 ]]
L(transpose.16):
        zip1            v24.8h,  v0.8h,   v2.8h
        zip2            v25.8h,  v0.8h,   v2.8h
        zip1            v28.8h,  v4.8h,   v6.8h
        zip2            v29.8h,  v4.8h,   v6.8h
        // Skip to the next stage if height <= 8.
        b.le            L(transpose.32)
        // Skip top-half handling if width <= 8.
        tbnz            w13, #0,  L(transpose.16.w8)

        zip1            v26.8h,  v1.8h,   v3.8h
        zip2            v27.8h,  v1.8h,   v3.8h
        zip1            v30.8h,  v5.8h,   v7.8h
        zip2            v31.8h,  v5.8h,   v7.8h
        zip1            v2.8h,   v17.8h,  v19.8h
        zip2            v3.8h,   v17.8h,  v19.8h
        zip1            v6.8h,   v21.8h,  v23.8h
        zip2            v7.8h,   v21.8h,  v23.8h
L(transpose.16.w8):
        zip2            v1.8h,   v16.8h,  v18.8h
        zip1            v0.8h,   v16.8h,  v18.8h
        zip2            v5.8h,   v20.8h,  v22.8h
        zip1            v4.8h,   v20.8h,  v22.8h

        // 32-bit
        // [[ abcdefgh0  abcdefgh1  ],
        //  [ abcdefgh2  abcdefgh3  ],
        //  [ abcdefgh4  abcdefgh5  ],
        //  [ abcdefgh6  abcdefgh7  ],
        //  [ abcdefgh8  abcdefgh9  ],
        //  [ abcdefgh10 abcdefgh11 ],
        //  [ abcdefgh12 abcdefgh13 ],
        //  [ abcdefgh14 abcdefgh15 ],
        //   ... and likewise for ijklmnop ...]
L(transpose.32):
        // Skip to unconditional top rows if height <= 8.
        b.le            L(transpose.32.top)
        // Skip top-half handling if width <= 8.
        tbnz            w13, #0,  L(transpose.32.w8)

        zip1            v16.4s,  v26.4s,  v30.4s
        zip2            v18.4s,  v26.4s,  v30.4s
        zip1            v20.4s,  v27.4s,  v31.4s
        zip2            v22.4s,  v27.4s,  v31.4s
        zip1            v17.4s,  v2.4s,   v6.4s
        zip2            v19.4s,  v2.4s,   v6.4s
        zip1            v21.4s,  v3.4s,   v7.4s
        zip2            v23.4s,  v3.4s,   v7.4s
L(transpose.32.w8):
        zip2            v7.4s,   v1.4s,   v5.4s
        zip1            v5.4s,   v1.4s,   v5.4s
        zip2            v3.4s,   v0.4s,   v4.4s
        zip1            v1.4s,   v0.4s,   v4.4s
L(transpose.32.top):
        zip2            v2.4s,   v24.4s,  v28.4s
        zip1            v0.4s,   v24.4s,  v28.4s
        zip2            v6.4s,   v25.4s,  v29.4s
        zip1            v4.4s,   v25.4s,  v29.4s
        // Store the 8 rows directly if height <= 8 and width <= 8.
        b.le            L(transpose.64.h8)
        // Width <= 8, so only perform half of the stores.
        tbnz            w13, #0,  L(transpose.64)

        // 64-bit interleave top and bottom halves whilst storing.
        mov             x1,  sp
        add             x8,  sp,  #128
        st2             {v0.2d,  v1.2d},  [x1], #32
        st2             {v16.2d, v17.2d}, [x8], #32
        st2             {v2.2d,  v3.2d},  [x1], #32
        st2             {v18.2d, v19.2d}, [x8], #32
        st2             {v4.2d,  v5.2d},  [x1], #32
        st2             {v20.2d, v21.2d}, [x8], #32
        st2             {v6.2d,  v7.2d},  [x1]
        st2             {v22.2d, v23.2d}, [x8]
        mov             x2,  #16
        b               L(main)

L(transpose.64):
        // 64-bit interleave top and bottom halves whilst storing.
        mov             x1,  sp
        add             x8,  sp,  #64
        st2             {v0.2d,  v1.2d},  [x1], #32
        st2             {v4.2d,  v5.2d},  [x8], #32
        st2             {v2.2d,  v3.2d},  [x1]
        st2             {v6.2d,  v7.2d},  [x8]
        mov             x2,  #16
        b               L(main)

L(transpose.64.h8):
        stp             q0,  q2, [sp]
        stp             q4,  q6, [sp, #32]
        mov             x2,  #8
L(main):
        ldp             q0,  q1,  [x5]                      // prev_q_thr and prev_side_thr

        mov             x1,  sp
        mov             x15, x30
        bl              setup_thr_sb64_seg_8bpc_neon_common
        // Save cur_q_thr and cur_side_thr of the last row, for the next
        // call.
        stp             q0,  q1,  [x5]
        add             sp,  sp,  #256
        ret             x15
endfunc
