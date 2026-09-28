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
