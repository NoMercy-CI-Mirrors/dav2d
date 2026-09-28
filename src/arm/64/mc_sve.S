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

#include "src/arm/asm.S"
#include "mc_common.S"
#include "util.S"

#if HAVE_SVE
ENABLE_SVE

#if HAVE_SVE2
ENABLE_SVE2

// LUT to combine reordering the elements after the SMLALB/T instruction,
// shifting a 32-bit value by 8 and narrowing it to 16 bits.
const narrow_shift_tbl, align=4
        .byte 1, 2, 17, 18, 5, 6, 21, 22, 9, 10, 25, 26, 13, 14, 29, 30
endconst

// void morph_8bpc_sve2(pixel *dst, const ptrdiff_t dst_stride,
//                      const int alpha, const int beta, const int w,
//                      const int h)
function morph_8bpc_sve2, export=1
        dup             v0.8h,  w2                        // alpha
        dup             v18.4s, w3
        cmp             w4,  #8
        b.lt            L(morph_4xh)
        ldrel           q20, x9,  narrow_shift_tbl
        ptrue           p0.h, vl8
        b.eq            L(morph_8xh)

1:      // w >= 16
        mov             w6,  w4                           // width
        mov             x7,  x0                           // dst
2:
        add             x8,  x7,  #8
        ld1b            {z2.h}, p0/z, [x7]
        ld1b            {z3.h}, p0/z, [x8]
        movprfx         z4,  z18
        smlalb          z4.s,  z2.h,  z0.h                // alpha * dst[x] + beta
        movprfx         z5,  z18
        smlalt          z5.s,  z2.h,  z0.h
        movprfx         z6,  z18
        smlalb          z6.s,  z3.h,  z0.h
        movprfx         z7,  z18
        smlalt          z7.s,  z3.h,  z0.h
        sub             w6,  w6,  #16
        tbl             v4.16b, {v4.16b, v5.16b}, v20.16b // narrow and >> 8
        tbl             v6.16b, {v6.16b, v7.16b}, v20.16b
        sqxtun          v4.8b,  v4.8h
        sqxtun          v5.8b,  v6.8h
        stp             d4,  d5, [x7], #16
        cbnz            w6,  2b

        sub             w5,  w5,  #1                      // height--
        add             x0,  x0,  x1                      // dst += dst_stride
        cbnz            w5,  1b
        ret

L(morph_8xh):
        ld1b            {z2.h},  p0/z, [x0]
        ld1b            {z3.h},  p0/z, [x0, x1]
        movprfx         z4,  z18
        smlalb          z4.s,  z2.h,  z0.h                // alpha * dst[x] + beta
        movprfx         z5,  z18
        smlalt          z5.s,  z2.h,  z0.h
        movprfx         z6,  z18
        smlalb          z6.s,  z3.h,  z0.h
        movprfx         z7,  z18
        smlalt          z7.s,  z3.h,  z0.h
        sub             w5,  w5,  #2
        tbl             v4.16b, {v4.16b, v5.16b}, v20.16b // narrow and >> 8
        tbl             v6.16b, {v6.16b, v7.16b}, v20.16b
        sqxtun          v4.8b,  v4.8h
        sqxtun          v6.8b,  v6.8h
        str             d4,  [x0]
        str             d6,  [x0, x1]
        add             x0,  x0,  x1,  lsl #1
        cbnz            w5,  L(morph_8xh)
        ret

L(morph_4xh):
        ptrue           p0.h, vl4
3:
        ld1b            {z2.h},  p0/z, [x0]
        ld1b            {z3.h},  p0/z, [x0, x1]
        mov             v4.16b, v18.16b
        mov             v5.16b, v18.16b
        smlal           v4.4s,  v2.4h, v0.4h              // alpha * dst[x] + beta
        smlal           v5.4s,  v3.4h, v0.4h
        sub             w5,  w5,  #2
        shrn            v4.4h,  v4.4s, #8
        shrn            v5.4h,  v5.4s, #8
        sqxtun          v4.8b,  v4.8h
        sqxtun          v5.8b,  v5.8h
        str             s4,  [x0]
        str             s5,  [x0, x1]
        add             x0,  x0,  x1,  lsl #1
        cbnz            w5,  3b
        ret
endfunc

DISABLE_SVE2
#endif // HAVE_SVE2

.macro opfl_compute_rows_8bpc_large_sve p0_lo0, p0_hi0, p1_lo0, p1_hi0,         \
                                        p0_lo1, p0_hi1, p1_lo1, p1_hi1,         \
                                        tmp0_lo0, tmp0_hi0, tmp1_lo0, tmp1_hi0, \
                                        tmp0_lo1, tmp0_hi1, tmp1_lo1, tmp1_hi1
        add             x17, x10, #8
        ld1b            {z(\p0_lo0)\().h}, p0/z, [x10]
        ld1b            {z(\p0_hi0)\().h}, p0/z, [x17]
        ld1b            {z(\p0_lo1)\().h}, p0/z, [x10, x2]
        ld1b            {z(\p0_hi1)\().h}, p0/z, [x17, x2]
        add             x17, x11, #8
        mul             \tmp0_lo0\().8h, \p0_lo0\().8h, v0.h[0]         // d.i8[0] * p0p (lo line 0)
        mul             \tmp0_hi0\().8h, \p0_hi0\().8h, v0.h[0]         // d.i8[0] * p0p (hi line 0)
        ld1b            {z(\p1_lo0)\().h}, p0/z, [x11]
        ld1b            {z(\p1_hi0)\().h}, p0/z, [x17]
        ld1b            {z(\p1_lo1)\().h}, p0/z, [x11, x4]
        ld1b            {z(\p1_hi1)\().h}, p0/z, [x17, x4]
        mul             \tmp0_lo1\().8h, \p0_lo1\().8h, v0.h[0]         // d.i8[0] * p0p (lo line 1)
        mul             \tmp0_hi1\().8h, \p0_hi1\().8h, v0.h[0]         // d.i8[0] * p0p (hi line 1)
        sub             \tmp1_lo0\().8h, \p0_lo0\().8h, \p1_lo0\().8h   // tmp1 (lo line 0)
        sub             \tmp1_hi0\().8h, \p0_hi0\().8h, \p1_hi0\().8h   // tmp1 (hi line 0)
        mla             \tmp0_lo0\().8h, \p1_lo0\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (lo line 0)
        mla             \tmp0_hi0\().8h, \p1_hi0\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (hi line 0)
        add             x10, x10, x2, lsl #1
        add             x11, x11, x4, lsl #1
        sub             \tmp1_lo1\().8h, \p0_lo1\().8h, \p1_lo1\().8h   // tmp1 (lo line 1)
        sub             \tmp1_hi1\().8h, \p0_hi1\().8h, \p1_hi1\().8h   // tmp1 (hi line 1)
        mla             \tmp0_lo1\().8h, \p1_lo1\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (lo line 1)
        mla             \tmp0_hi1\().8h, \p1_hi1\().8h, v0.h[1]         // d.i8[0] * p0p + d.i8[1] * p1p (hi line 1)
.endm

.macro opfl_compute_next_rows_8bpc_large_sve
        // Compute tmp0 and tmp1 for the next two lines.
        // in:  line 2: [v8 - v21, v5 - v6]   (p0_lo - p0_hi, p1_lo - p1_hi)
        //      line 3: [v23 - v13, v7 - v14]  (p0_lo - p0_hi, p1_lo - p1_hi)
        // out: line 2: tmp0 [v1,  v2],  tmp1 [v8,  v21]
        //      line 3: tmp0 [v20, v22], tmp1 [v23, v13]
        opfl_compute_rows_8bpc_large_sve v8,  v21, v5,  v6,  v23, v13, v7,  v14, \
                                         v1,  v2,  v8,  v21, v20, v22, v23, v13
.endm

// Process a 16-pixel-wide stripe as two adjacent 8x8 subblocks. Compute and
// accumulate two lines at a time until both subblocks are complete, then move
// down to the next pair of subblocks. At the bottom of the block, move 16
// pixels to the right and restart from the top.
.macro opfl_refine_mv_8bpc_large_sve
        uxtw            x5,  w5
        movrel          x8,  shift_large
        sub             sp,  sp,  #224                  // 10 * 128-bit vectors for out accs + 4 spill vectors

        mov             x9,  #0                         // bx = 0
        sub             w16, w6,  #2                    // h - 2
        mul             w14, w7,  w7
2:
        mov             x10, x1                         // p0_ptr
        mov             x11, x3                         // p1_ptr
        // This decides how much to shift y0 after SHSUB has consumed one
        // right shift. It's a shift right by 6 in most cases, unless e2 is 1
        // in which case a shift right by 5 allows to skip the multiplication
        // by (1 + e2). This is true for y = 0, so initialize for this special
        // case, then later overwrite it for the general case.
        mov             w19, #-5

        // Compute tmp0/tmp1 for the first two lines.
        // in:  line 0: [v3 - v4, v5 - v6]    (p0_lo - p0_hi, p1_lo - p1_hi)
        //      line 1: [v9 - v10, v11 - v12] (p0_lo - p0_hi, p1_lo - p1_hi)
        // out: line 0: tmp0 [v1, v2],  tmp1 [v3, v4]
        //      line 1: tmp0 [v7, v8],  tmp1 [v9, v10]
        opfl_compute_rows_8bpc_large_sve v3,  v4,  v5,  v6,  v9,  v10, v11, v12, \
                                         v1,  v2,  v3,  v4,  v7,  v8,  v9,  v10

        mov             x12, #0                          // y = 0
        mov             v24.16b, v1.16b
        mov             v25.16b, v1.16b
        mov             v26.16b, v1.16b
        mov             v28.16b, v2.16b
        mov             v29.16b, v2.16b
        mov             v30.16b, v2.16b
        mov             v27.16b, v7.16b
        mov             v31.16b, v8.16b
        mov             x15, x0

        opfl_refine_mv_large opfl_compute_next_rows_8bpc_large_sve, 16, sve
.endm

.macro opfl_compute_rows_8bpc_small_sve p0_0, p1_0, p0_1, p1_1,     \
                                        tmp0_0, tmp1_0, tmp0_1, tmp1_1
        ld1b            {z(\p0_0)\().h}, p0/z, [x1]
        ld1b            {z(\p1_0)\().h}, p0/z, [x3]
        ld1b            {z(\p0_1)\().h}, p0/z, [x1, x2]
        ld1b            {z(\p1_1)\().h}, p0/z, [x3, x4]

        mul             \tmp0_0\().8h, \p0_0\().8h, v0.h[0]     // d.i8[0] * p0p (line 0)
        mul             \tmp0_1\().8h, \p0_1\().8h, v0.h[0]     // d.i8[0] * p0p (line 1)
        sub             \tmp1_0\().8h, \p0_0\().8h, \p1_0\().8h
        sub             \tmp1_1\().8h, \p0_1\().8h, \p1_1\().8h
        mla             \tmp0_0\().8h, \p1_0\().8h, v0.h[1]     // d.i8[0] * p0p + d.i8[1] * p1p (line 0)
        mla             \tmp0_1\().8h, \p1_1\().8h, v0.h[1]     // d.i8[0] * p0p + d.i8[1] * p1p (line 1)
        add             x1,  x1,  x2, lsl #1                    // p0 += 2 * p0_stride
        add             x3,  x3,  x4, lsl #1                    // p1 += 2 * p1_stride
.endm

.macro opfl_compute_next_rows_8bpc_small_sve
        // Compute tmp0/tmp1 for the next two lines.
        // in:  line 2: [v22, v23] (p0, p1)
        //      line 3: [v21, v3]  (p0, p1)
        // out: line 2: tmp0 [v4], tmp1 [v20]
        //      line 3: tmp0 [v6], tmp1 [v21]
        opfl_compute_rows_8bpc_small_sve v22, v23, v21, v3, \
                                         v4,  v20, v6,  v21
.endm

// Process the 8-pixel-wide block two lines at a time. For bs == 4, the low
// and high halves form two adjacent 4x4 subblocks; for bs == 8, they form one
// 8x8 subblock. After completing the current subblock row, move down to the
// next one until the bottom of the block is reached.
.macro opfl_refine_mv_8bpc_small_sve
        sub             w11, w6,  #2                       // h - 2

        // Compute tmp0/tmp1 for the first two lines.
        // in:  line 0: [v2, v3]  (p0, p1)
        //      line 1: [v8, v9]  (p0, p1)
        // out: line 0: tmp0 [v4], tmp1 [v5]
        //      line 1: tmp0 [v6], tmp1 [v7]
        opfl_compute_rows_8bpc_small_sve v2, v3, v8, v9, \
                                         v4, v5, v6, v7

        mov             w9,  #0                            // y = 0
        ldrel           q8,  x8,  shift_small
        mul             w16, w7,  w7                       // bs * bs

        opfl_refine_mv_small opfl_compute_next_rows_8bpc_small_sve, sve

.endm

// void opfl_refine_mv_8bpc_sve(struct OpflRegressionData *out,
//                              const pixel *p0, const ptrdiff_t p0_stride,
//                              const pixel *p1, const ptrdiff_t p1_stride,
//                              const int w, const int h, const int bs,
//                              const union aliasi16 d)
function opfl_refine_mv_8bpc_sve, export=1
        ldr             h0, [sp]
        stp             d8,  d9,  [sp, #-80]!
        stp             d10, d11, [sp, #16]
        stp             d12, d13, [sp, #32]
        stp             d14, d15, [sp, #48]
        str             x19,      [sp, #64]
        ptrue           p0.b, vl16
        cmp             w5,  #8
        sxtl            v0.8h,   v0.8b
        b.ne            1f

        opfl_refine_mv_8bpc_small_sve
        b               L(end)

1:
        opfl_refine_mv_8bpc_large_sve
L(end):
        ldr             x19,      [sp, #64]
        ldp             d10, d11, [sp, #16]
        ldp             d12, d13, [sp, #32]
        ldp             d14, d15, [sp, #48]
        ldp             d8,  d9,  [sp], #80
        ret
endfunc

DISABLE_SVE
#endif  // HAVE_SVE
