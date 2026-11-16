/*
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
 */

.macro opfl_compute_rows_16bpc_large p0_lo0, p0_hi0, p1_lo0, p1_hi0,         \
                                     p0_lo1, p0_hi1, p1_lo1, p1_hi1,         \
                                     tmp0_lo0, tmp0_hi0, tmp1_lo0, tmp1_hi0, \
                                     tmp0_lo1, tmp0_hi1, tmp1_lo1, tmp1_hi1
        ldp             q(\p0_lo0), q(\p0_hi0), [x10]
        ldp             q(\p1_lo0), q(\p1_hi0), [x11]
        add             x10, x10, x2
        add             x11, x11, x4
        ldp             q(\p0_lo1), q(\p0_hi1), [x10]
        ldp             q(\p1_lo1), q(\p1_hi1), [x11]
        add             x10, x10, x2
        add             x11, x11, x4

        mul             \tmp0_lo0\().8h, \p0_lo0\().8h, v0.h[0]         // d.i8[0] * p0p (lo line 0)
        mul             \tmp0_hi0\().8h, \p0_hi0\().8h, v0.h[0]         // d.i8[0] * p0p (hi line 0)
        sub             \tmp1_lo0\().8h, \p0_lo0\().8h, \p1_lo0\().8h   // tmp1 (lo line 0)
        sub             \tmp1_hi0\().8h, \p0_hi0\().8h, \p1_hi0\().8h   // tmp1 (hi line 0)
        mul             \tmp0_lo1\().8h, \p0_lo1\().8h, v0.h[0]         // d.i8[0] * p0p (lo line 1)
        mul             \tmp0_hi1\().8h, \p0_hi1\().8h, v0.h[0]         // d.i8[0] * p0p (hi line 1)
        sub             \tmp1_lo1\().8h, \p0_lo1\().8h, \p1_lo1\().8h   // tmp1 (lo line 1)
        sub             \tmp1_hi1\().8h, \p0_hi1\().8h, \p1_hi1\().8h   // tmp1 (hi line 1)
        mla             \tmp0_lo0\().8h, \p1_lo0\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (lo line 0)
        mla             \tmp0_hi0\().8h, \p1_hi0\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (hi line 0)
        ssra            \tmp1_lo0\().8h, \tmp1_lo0\().8h, #15           // Adjust for SRSHL rounding up (lo line 0)
        ssra            \tmp1_hi0\().8h, \tmp1_hi0\().8h, #15           // Adjust for SRSHL rounding up (hi line 0)
        mla             \tmp0_lo1\().8h, \p1_lo1\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (lo line 1)
        mla             \tmp0_hi1\().8h, \p1_hi1\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (hi line 1)

        dup             v18.8h,  w20
        ssra            \tmp1_lo1\().8h, \tmp1_lo1\().8h, #15
        ssra            \tmp1_hi1\().8h, \tmp1_hi1\().8h, #15
        ssra            \tmp0_lo0\().8h, \tmp0_lo0\().8h, #15
        ssra            \tmp0_hi0\().8h, \tmp0_hi0\().8h, #15
        ssra            \tmp0_lo1\().8h, \tmp0_lo1\().8h, #15
        ssra            \tmp0_hi1\().8h, \tmp0_hi1\().8h, #15

        srshl           \tmp1_lo0\().8h, \tmp1_lo0\().8h, v18.8h        // tmp1 (lo line 0)
        srshl           \tmp1_hi0\().8h, \tmp1_hi0\().8h, v18.8h        // tmp1 (hi line 0)
        srshl           \tmp1_lo1\().8h, \tmp1_lo1\().8h, v18.8h        // tmp1 (lo line 1)
        srshl           \tmp1_hi1\().8h, \tmp1_hi1\().8h, v18.8h        // tmp1 (hi line 1)
        srshl           \tmp0_lo0\().8h, \tmp0_lo0\().8h, v18.8h        // tmp0 (lo line 0)
        srshl           \tmp0_hi0\().8h, \tmp0_hi0\().8h, v18.8h        // tmp0 (hi line 0)
        srshl           \tmp0_lo1\().8h, \tmp0_lo1\().8h, v18.8h        // tmp0 (lo line 1)
        srshl           \tmp0_hi1\().8h, \tmp0_hi1\().8h, v18.8h        // tmp0 (hi line 1)
.endm

.macro opfl_compute_rows_16bpc_small p0_0, p1_0, p0_1, p1_1,       \
                                     tmp0_0, tmp1_0, tmp0_1, tmp1_1
        ldr             q(\p0_0), [x1]
        ldr             q(\p1_0), [x3]
        ldr             q(\p0_1), [x1, x2]
        ldr             q(\p1_1), [x3, x4]

        // The 16-bit mul/mla/sub are range-safe because d.i8 is only +/-1 or +/-2.
        mul             \tmp0_0\().8h, \p0_0\().8h,  v0.h[0]       // d.i8[0] * p0p
        mul             \tmp0_1\().8h, \p0_1\().8h,  v0.h[0]       // d.i8[0] * p0p
        sub             \tmp1_0\().8h, \p0_0\().8h,  \p1_0\().8h
        sub             \tmp1_1\().8h, \p0_1\().8h,  \p1_1\().8h
        mla             \tmp0_0\().8h, \p1_0\().8h,  v0.h[1]       // d.i8[0] * p0p + d.i8[1] * p1p
        mla             \tmp0_1\().8h, \p1_1\().8h,  v0.h[1]       // d.i8[0] * p0p + d.i8[1] * p1p

        dup             v22.8h,  w13                               // -bd_min8
        ssra            \tmp1_0\().8h, \tmp1_0\().8h, #15          // Adjust for SRSHL rounding up
        ssra            \tmp1_1\().8h, \tmp1_1\().8h, #15
        ssra            \tmp0_0\().8h, \tmp0_0\().8h, #15
        ssra            \tmp0_1\().8h, \tmp0_1\().8h, #15
        srshl           \tmp1_0\().8h, \tmp1_0\().8h, v22.8h
        srshl           \tmp1_1\().8h, \tmp1_1\().8h, v22.8h
        srshl           \tmp0_0\().8h, \tmp0_0\().8h, v22.8h
        srshl           \tmp0_1\().8h, \tmp0_1\().8h, v22.8h
        add             x1,  x1,  x2, lsl #1
        add             x3,  x3,  x4, lsl #1
.endm

.macro opfl_compute_next_rows_16bpc_large
        // Compute tmp0 and tmp1 for the next two lines.
        // in:  line 2: [v5 - v6,   v14 - v15] (p0_lo - p0_hi, p1_lo - p1_hi)
        //      line 3: [v12 - v13, v17 - v18] (p0_lo - p0_hi, p1_lo - p1_hi)
        // out: line 2: tmp0 [v1,  v2],  tmp1 [v8,  v21]
        //      line 3: tmp0 [v20, v22], tmp1 [v23, v13]
        opfl_compute_rows_16bpc_large v5,  v6,  v14, v15, v12, v13, v17, v18, \
                                      v1,  v2,  v8,  v21, v20, v22, v23, v13
.endm

.macro opfl_compute_next_rows_16bpc_small
        // Compute tmp0/tmp1 for the next two lines.
        // in:  line 2: [v22, v23] (p0, p1)
        //      line 3: [v21, v3]  (p0, p1)
        // out: line 2: tmp0 [v4], tmp1 [v20]
        //      line 3: tmp0 [v6], tmp1 [v21]
        opfl_compute_rows_16bpc_small v22, v23, v21, v3, \
                                      v4,  v20, v6,  v21
.endm

// Process a 16-pixel-wide stripe as two adjacent 8x8 subblocks. Compute and
// accumulate two lines at a time until both subblocks are complete, then move
// down to the next pair of subblocks. At the bottom of the block, move 16
// pixels to the right and restart from the top.
.macro opfl_refine_mv_16bpc_large opfl_refine_mv_large, isa
        clz             w20, w13
        uxtw            x5,  w5
        movrel          x8,  shift_large
        sub             sp,  sp,  #224                  // 10 * 128-bit vectors for out accs + 4 spill vectors

        mov             x9,  #0
        sub             w16, w6,  #2                    // h - 2
        mul             w14, w7,  w7
        sub             w20, w20, #24                   // -bd_min8 = clz(bitdepth_max) - 24
2:
        mov             x10, x1
        mov             x11, x3
        mov             x15, x0

        // Compute tmp0/tmp1 for the first two lines.
        // in:  line 0: [v3 - v4,   v5 - v6]   (p0_lo - p0_hi, p1_lo - p1_hi)
        //      line 1: [v9 - v10, v11 - v12]  (p0_lo - p0_hi, p1_lo - p1_hi)
        // out: line 0: tmp0 [v24, v28], tmp1 [v3, v4]
        //      line 1: tmp0 [v27, v31], tmp1 [v9, v10]
        opfl_compute_rows_16bpc_large v3,  v4,  v5,  v6,  v9,  v10, v11, v12, \
                                      v24, v28, v3,  v4,  v27, v31, v9,  v10

        mov             v25.16b, v24.16b
        mov             v26.16b, v24.16b
        mov             v29.16b, v28.16b
        mov             v30.16b, v28.16b

        mov             x12, #0                         // y = 0
        \opfl_refine_mv_large opfl_compute_next_rows_16bpc_large, 32, \isa
.endm

// Process the 8-pixel-wide block two lines at a time. For bs == 4, the low
// and high halves form two adjacent 4x4 subblocks; for bs == 8, they form one
// 8x8 subblock. After completing the current subblock row, move down to the
// next one until the bottom of the block is reached.
.macro opfl_refine_mv_16bpc_small opfl_refine_mv_small, isa
        clz             w13, w13
        sub             w11, w6,  #2                    // h - 2
        sub             w13, w13, #24                   // -bd_min8 = clz(bitdepth_max) - 24

        // Compute tmp0/tmp1 for the first two lines.
        // in:  line 0: [v2, v3]  (p0, p1)
        //      line 1: [v8, v9]  (p0, p1)
        // out: line 0: tmp0 [v4], tmp1 [v5]
        //      line 1: tmp0 [v6], tmp1 [v7]
        opfl_compute_rows_16bpc_small v2,  v3,  v8,  v9, \
                                      v4,  v5,  v6,  v7

        mov             w9,  #0
        ldrel           q8,  x8,  shift_small
        mul             w16, w7,  w7                    // bs * bs

        \opfl_refine_mv_small opfl_compute_next_rows_16bpc_small, \isa
.endm
