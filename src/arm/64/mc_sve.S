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

// Replace the shift right by 7 with a shift right by 6 when e1 = 1, allowing
// to skip the multiplication by (e1 + 1).
const shift_large
        .word -6, -7, -7, -7, -7, -7, -7, -7
        .word -7, -7, -7, -7, -7, -7, -7, -6
endconst

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
        // This decides how much to shift y0 when computing the vertical
        // gradient. It's a shift right by 7 in most cases, unless e2 is 1 in
        // which case a shift right by 6 allows to skip the multiplication by
        // (1 + e2). This is true for y = 0, so initialize for this special
        // case, then later overwrite it for the general case.
        mov             w19, #-6

        // Compute tmp0/tmp1 for the first two lines.
        // in:  line 0: [v3 - v4, v5 - v6]    (p0_lo - p0_hi, p1_lo - p1_hi)
        //      line 1: [v9 - v10, v11 - v12] (p0_lo - p0_hi, p1_lo - p1_hi)
        // out: line 0: tmp0 [v1, v2],  tmp1 [v3, v4]
        //      line 1: tmp0 [v7, v8],  tmp1 [v9, v10]
        add             x15, x10, #8
        add             x17, x11, #8
        ld1b            {z3.h},  p0/z, [x10]
        ld1b            {z4.h},  p0/z, [x15]
        ld1b            {z5.h},  p0/z, [x11]
        ld1b            {z6.h},  p0/z, [x17]
        mul             v1.8h,   v3.8h,   v0.h[0]        // d.i8[0] * p0p (lo line 0)
        mul             v2.8h,   v4.8h,   v0.h[0]        // d.i8[0] * p0p (hi line 0)
        mov             x12, #0                          // y = 0
        ld1b            {z9.h},  p0/z, [x10, x2]
        ld1b            {z10.h}, p0/z, [x15, x2]
        ld1b            {z11.h}, p0/z, [x11, x4]
        ld1b            {z12.h}, p0/z, [x17, x4]
        mla             v1.8h,   v5.8h,   v0.h[1]        // d.i8[0] * p0p + d.i8[1] * p1p (lo line 0)
        mla             v2.8h,   v6.8h,   v0.h[1]        // d.i8[0] * p0p + d.i8[1] * p1p (hi line 0)
        sub             v3.8h,   v3.8h,   v5.8h          // tmp1 (lo line 0)
        sub             v4.8h,   v4.8h,   v6.8h          // tmp1 (hi line 0)
        mul             v7.8h,   v9.8h,   v0.h[0]        // d.i8[0] * p0p (lo line 1)
        mul             v8.8h,   v10.8h,  v0.h[0]        // d.i8[0] * p0p (hi line 1)
        add             x10, x10, x2, lsl #1
        add             x11, x11, x4, lsl #1
        mov             v24.16b, v1.16b
        mov             v25.16b, v1.16b
        mov             v26.16b, v1.16b
        sub             v9.8h,   v9.8h,   v11.8h         // tmp1 (lo line 1)
        sub             v10.8h,  v10.8h,  v12.8h         // tmp1 (hi line 1)
        mla             v7.8h,   v11.8h,  v0.h[1]        // d.i8[0] * p0p + d.i8[1] * p1p (lo line 1)
        mla             v8.8h,   v12.8h,  v0.h[1]        // d.i8[0] * p0p + d.i8[1] * p1p (hi line 1)

        mov             v28.16b, v2.16b
        mov             v29.16b, v2.16b
        mov             v30.16b, v2.16b
        mov             v27.16b, v7.16b
        mov             v31.16b, v8.16b
        mov             x15, x0

3:
        movi            v11.2d,  #0

        stp             q11, q11, [sp]                  // su2_0, su2_1
        stp             q11, q11, [sp, #32]             // suv_0, suv_1
        stp             q11, q11, [sp, #64]             // sv2_0, sv2_1
        mov             w13, w12                        // py = y
        stp             q11, q11, [sp, #96]             // suw_0, suw_1
        stp             q11, q11, [sp, #128]            // svw_0, svw_1

4:
        // Compute the horizontal gradient for the two current lines.
        // in: line 0: [v27, v31], line 1: [v26, v30]
        // out: line 0: [v20, v19], line 1: [v22, v14]
        ldp             q12, q16, [x8]                  // shift_lo
        ldp             q13, q11, [x8, #32]             // shift_hi
        dup             v22.8h,  v27.h[0]               // min_x (line 0)
        dup             v23.8h,  v31.h[7]               // max_x (line 0)
        dup             v20.8h,  v26.h[0]               // min_x (line 1)
        dup             v21.8h,  v30.h[7]               // max_x (line 1)
        ext             v17.16b, v22.16b, v27.16b, #12  // p0_lo (line 0)
        ext             v18.16b, v22.16b, v27.16b, #14  // p1_lo (line 0)
        ext             v1.16b,  v20.16b, v26.16b, #12  // p0_lo (line 1)
        ext             v2.16b,  v20.16b, v26.16b, #14  // p1_lo (line 1)
        ext             v22.16b, v27.16b, v31.16b, #2   // p2_lo (line 0)
        ext             v5.16b,  v27.16b, v31.16b, #4   // p3_lo (line 0)

        sub             v22.8h,  v22.8h,  v18.8h        // p2 - p1 (lo line 0)
        sub             v17.8h,  v5.8h,   v17.8h        // p3 - p0 (lo line 0)
        ext             v20.16b, v26.16b, v30.16b, #2   // p2_lo (line 1)
        ext             v5.16b,  v26.16b, v30.16b, #4   // p3_lo (line 1)
        ext             v14.16b, v31.16b, v23.16b, #2   // p2_hi (line 0)
        ext             v15.16b, v31.16b, v23.16b, #4   // p3_hi (line 0)
        sub             v20.8h,  v20.8h,  v2.8h         // p2 - p1 (lo line 1)
        sub             v5.8h,   v5.8h,   v1.8h         // p3 - p0 (lo line 1)
        ext             v7.16b,  v27.16b, v31.16b, #12  // p0_hi (line 0)
        ext             v23.16b, v27.16b, v31.16b, #14  // p1_hi (line 0)

        ext             v19.16b, v30.16b, v21.16b, #2   // p2_hi (line 1)
        mul             z22.h,   z22.h,   #42           // (p2 - p1) * 42 (lo line 0)
        mul             z17.h,   z17.h,   #5            // (p3 - p0) * 5  (lo line 0)
        ext             v8.16b,  v26.16b, v30.16b, #14  // p1_hi (line 1)
        ext             v6.16b,  v30.16b, v21.16b, #4   // p3_hi (line 1)
        ext             v21.16b, v26.16b, v30.16b, #12  // p0_hi (line 1)
        mul             z20.h,   z20.h,   #42           // (p2 - p1) * 42 (lo line 1)
        mul             z5.h,    z5.h,    #5            // (p3 - p0) * 5  (lo line 1)
        sub             v14.8h,  v14.8h,  v23.8h        // p2 - p1 (hi line 0)
        sub             v19.8h,  v19.8h,  v8.8h         // p2 - p1 (hi line 1)
        sub             v6.8h,   v6.8h,   v21.8h        // p3 - p0 (hi line 1)
        sub             v15.8h,  v15.8h,  v7.8h         // p3 - p0 (hi line 0)
        ssubl           v1.4s,   v22.4h,  v17.4h        // x0 (lo line 0) lo
        ssubl2          v2.4s,   v22.8h,  v17.8h        // x0 (lo line 0) hi
        ssubl           v21.4s,  v20.4h,  v5.4h         // x0 (lo line 1) lo
        ssubl2          v23.4s,  v20.8h,  v5.8h         // x0 (lo line 1) hi
        mul             z14.h,   z14.h,   #42           // (p2 - p1) * 42 (hi line 0)
        mul             z15.h,   z15.h,   #5            // (p3 - p0) * 5  (hi line 0)
        ssra            v1.4s,   v1.4s,   #31           // Adjust for SRSHL rounding up (lo line 0)
        ssra            v2.4s,   v2.4s,   #31
        ssra            v21.4s,  v21.4s,  #31           // Adjust for SRSHL rounding up (lo line 1)
        ssra            v23.4s,  v23.4s,  #31
        mul             z19.h,   z19.h,   #42           // (p2 - p1) * 42 (hi line 1)
        mul             z6.h,    z6.h,    #5            // (p3 - p0) * 5  (hi line 1)
        srshl           v1.4s,   v1.4s,   v12.4s        // x0 (lo line 0) lo
        srshl           v2.4s,   v2.4s,   v16.4s        // x0 (lo line 0) hi
        srshl           v21.4s,  v21.4s,  v12.4s        // x0 (lo line 1) lo
        srshl           v23.4s,  v23.4s,  v16.4s        // x0 (lo line 1) hi
        uzp1            v22.8h,  v1.8h,   v2.8h         // x0 (lo line 0)
        uzp1            v20.8h,  v21.8h,  v23.8h        // x0 (lo line 1)
        ssubl           v1.4s,   v14.4h,  v15.4h        // x0 (hi line 0) lo
        ssubl2          v2.4s,   v14.8h,  v15.8h        // x0 (hi line 0) hi
        ssubl           v21.4s,  v19.4h,  v6.4h         // x0 (hi line 1) lo
        ssubl2          v23.4s,  v19.8h,  v6.8h         // x0 (hi line 1) hi
        ssra            v1.4s,   v1.4s,   #31           // Adjust for SRSHL rounding up (hi line 0)
        ssra            v2.4s,   v2.4s,   #31
        ssra            v21.4s,  v21.4s,  #31           // Adjust for SRSHL rounding up (hi line 1)
        ssra            v23.4s,  v23.4s,  #31
        srshl           v1.4s,   v1.4s,   v13.4s        // x0 (hi line 0) lo
        srshl           v2.4s,   v2.4s,   v11.4s        // x0 (hi line 0) hi
        srshl           v21.4s,  v21.4s,  v13.4s        // x0 (hi line 1) lo
        srshl           v23.4s,  v23.4s,  v11.4s        // x0 (hi line 1) hi
        ldp             q11, q16, [sp]                  // su2_0, su2_1
        uzp1            v14.8h,  v1.8h,   v2.8h         // x0 (hi line 0)
        uzp1            v19.8h,  v21.8h,  v23.8h        // x0 (hi line 1)

        // Start accumulating the results that don't need the vertical gradient
        // (su2 and suw).
        sdot            z11.d,  z20.h,  z20.h           // su2_0
        sdot            z16.d,  z19.h,  z19.h           // su2_1
        ldp             q17, q18, [sp, #96]             // suw_0, suw_1

        sdot            z11.d,  z22.h,  z22.h           // su2_0
        sdot            z16.d,  z14.h,  z14.h           // su2_1
        cmp             w13, w16                        // py < h - 2
        sdot            z17.d,  z20.h,  z3.h            // suw_0
        sdot            z18.d,  z19.h,  z4.h            // suw_1
        stp             q20, q19, [sp, #160]
        stp             q11, q16, [sp]                  // su2_0, su2_1
        sdot            z17.d,  z22.h,  z9.h            // suw_0
        sdot            z18.d,  z14.h,  z10.h           // suw_1
        stp             q17, q18, [sp, #96]             // suw_0, suw_1
        stp             q22, q14, [sp, #192]

        // If needed, compute tmp0/tmp1 for the next two lines (otherwise
        // reuse the last line), then compute the vertical gradients for the
        // current two lines.
        b.lt            5f

        // We reached the end of the block, compute the vertical gradient
        // reusing the last line as needed. The result for the very last line
        // is right-shifted by 6 to account for e2 = 1.

        // Compute the vertical gradient for the low halves of the current two lines.
        // in:  line 0: [v24, v28], line 1: [v25, v29], line 2: [v26, v30],
        //      line 3: [v27, v31], line 4: [v27, v31], line 5: [v27, v31]
        // out: line 0: [v5,  -],  line 1: [v19, -]
        sub             v5.8h,   v27.8h,  v25.8h        // q2 - q1 (lo line 0)
        sub             v24.8h,  v27.8h,  v24.8h        // q3 - q0 (lo line 0)
        sub             v19.8h,  v27.8h,  v26.8h        // q2 - q1 (lo line 1)
        sub             v25.8h,  v27.8h,  v25.8h        // q3 - q0 (lo line 1)
        mul             z5.h,    z5.h,    #42           // (q2 - q1) * 42 (lo line 0)
        mul             z24.h,   z24.h,   #5            // (q3 - q0) * 5  (lo line 0)
        mul             z19.h,   z19.h,   #42           // (q2 - q1) * 42 (lo line 1)
        mul             z25.h,   z25.h,   #5            // (q3 - q0) * 5  (lo line 1)
        ssubl           v1.4s,   v5.4h,   v24.4h        // y0 (lo line 0) lo
        ssubl2          v2.4s,   v5.8h,   v24.8h        // y0 (lo line 0) hi
        ssubl           v6.4s,   v19.4h,  v25.4h        // y0 (lo line 1) lo
        ssubl2          v7.4s,   v19.8h,  v25.8h        // y0 (lo line 1) hi
        ssra            v1.4s,   v1.4s,   #31           // Adjust for SRSHR rounding up (lo line 0)
        ssra            v6.4s,   v6.4s,   #31           // Adjust for SRSHR rounding up (lo line 1)
        ssra            v2.4s,   v2.4s,   #31
        ssra            v7.4s,   v7.4s,   #31
        rshrn           v5.4h,   v1.4s,   #7            // y0 (lo line 0)
        rshrn           v19.4h,  v6.4s,   #6            // y0 (lo line 1)
        // Compute the vertical gradient for the high halves of the current two lines.
        // in:  line 0: [-, v28], line 1: [-, v29], line 2: [-, v30],
        //      line 3: [-, v31], line 4: [-, v31], line 5: [-, v31]
        // out: line 0: [-,  v14], line 1: [-,  v15]
        sub             v14.8h,  v31.8h,  v29.8h        // q2 - q1 (hi line 0)
        sub             v28.8h,  v31.8h,  v28.8h        // q3 - q0 (hi line 0)
        rshrn2          v5.8h,   v2.4s,   #7            // y0 (lo line 0)
        rshrn2          v19.8h,  v7.4s,   #6            // y0 (lo line 1)
        sub             v15.8h,  v31.8h,  v30.8h        // q2 - q1 (hi line 1)
        sub             v29.8h,  v31.8h,  v29.8h        // q3 - q0 (hi line 1)
        mul             z14.h,   z14.h,   #42           // (q2 - q1) * 42 (hi line 0)
        mul             z28.h,   z28.h,   #5            // (q3 - q0) * 5  (hi line 0)
        mul             z15.h,   z15.h,   #42           // (q2 - q1) * 42 (hi line 1)
        mul             z29.h,   z29.h,   #5            // (q3 - q0) * 5  (hi line 1)
        ssubl           v1.4s,   v14.4h,  v28.4h        // y0 (hi line 0) lo
        ssubl2          v2.4s,   v14.8h,  v28.8h        // y0 (hi line 0) hi
        ssubl           v6.4s,   v15.4h,  v29.4h        // y0 (hi line 1) lo
        ssubl2          v7.4s,   v15.8h,  v29.8h        // y0 (hi line 1) hi
        ssra            v1.4s,   v1.4s,   #31           // Adjust for SRSHR rounding up (hi line 0)
        ssra            v2.4s,   v2.4s,   #31
        ssra            v6.4s,   v6.4s,   #31           // Adjust for SRSHR rounding up (hi line 1)
        ssra            v7.4s,   v7.4s,   #31
        rshrn           v14.4h,  v1.4s,   #7            // y0 (hi line 0)
        rshrn           v15.4h,  v6.4s,   #6            // y0 (hi line 1)
        rshrn2          v14.8h,  v2.4s,   #7            // y0 (hi line 0)
        rshrn2          v15.8h,  v7.4s,   #6            // y0 (hi line 1)
        b               6f

5:
        // Compute tmp0 and tmp1 for the next two lines.
        // in:  line 2: [v8 - v21, v5 - v6]   (p0_lo - p0_hi, p1_lo - p1_hi)
        //      line 3: [v23 - v13, v7 - v14]  (p0_lo - p0_hi, p1_lo - p1_hi)
        // out: line 2: tmp0 [v1,  v2],  tmp1 [v8,  v21]
        //      line 3: tmp0 [v20, v22], tmp1 [v23, v13]
        add             x17, x10, #8
        ld1b            {z8.h},  p0/z, [x10]
        ld1b            {z21.h}, p0/z, [x17]
        ld1b            {z23.h}, p0/z, [x10, x2]
        ld1b            {z13.h}, p0/z, [x17, x2]
        add             x17, x11, #8
        ld1b            {z5.h},  p0/z, [x11]
        ld1b            {z6.h},  p0/z, [x17]
        ld1b            {z7.h},  p0/z, [x11, x4]
        ld1b            {z14.h}, p0/z, [x17, x4]
        add             x10, x10, x2, lsl #1
        add             x11, x11, x4, lsl #1
        mul             v1.8h,   v8.8h,   v0.h[0]       // d.i8[0] * p0p (lo line 2)
        mul             v2.8h,   v21.8h,  v0.h[0]       // d.i8[0] * p0p (hi line 2)
        mul             v20.8h,  v23.8h,  v0.h[0]       // d.i8[0] * p0p (lo line 3)
        mul             v22.8h,  v13.8h,  v0.h[0]       // d.i8[0] * p0p (hi line 3)
        mla             v1.8h,   v5.8h,   v0.h[1]       // d.i8[0] * p0p + d.i8[1] * p1p (lo line 2)
        mla             v2.8h,   v6.8h,   v0.h[1]       // d.i8[0] * p0p + d.i8[1] * p1p (hi line 2)
        mla             v20.8h,  v7.8h,   v0.h[1]       // d.i8[0] * p0p + d.i8[1] * p1p (lo line 3)
        mla             v22.8h,  v14.8h,  v0.h[1]       // d.i8[0] * p0p + d.i8[1] * p1p (hi line 3)
        sub             v8.8h,   v8.8h,   v5.8h         // tmp1 (lo line 2)
        sub             v21.8h,  v21.8h,  v6.8h         // tmp1 (hi line 2)
        sub             v23.8h,  v23.8h,  v7.8h         // tmp1 (lo line 3)
        sub             v13.8h,  v13.8h,  v14.8h        // tmp1 (hi line 3)
        dup             v17.4s,  w19

        // Compute the vertical gradient for the low halves of the current two lines.
        // in:  line 0: [v24, -], line 1: [v25, -], line 2: [v26, -],
        //      line 3: [v27, -], line 4: [v1,  -], line 5: [v20, -]
        // out: line 0: [v5,  -],  line 1: [v19, -]
        sub             v5.8h,   v27.8h,  v25.8h        // q2 - q1 (lo line 0)
        sub             v24.8h,  v1.8h,   v24.8h        // q3 - q0 (lo line 0)
        sub             v19.8h,  v1.8h,   v26.8h        // q2 - q1 (lo line 1)
        sub             v25.8h,  v20.8h,  v25.8h        // q3 - q0 (lo line 1)
        mul             z5.h,    z5.h,    #42           // (q2 - q1) * 42 (lo line 0)
        mul             z24.h,   z24.h,   #5            // (q3 - q0) * 5  (lo line 0)
        mul             z19.h,   z19.h,   #42           // (q2 - q1) * 42 (lo line 1)
        mul             z25.h,   z25.h,   #5            // (q3 - q0) * 5  (lo line 1)
        ssubl           v6.4s,   v5.4h,   v24.4h        // y0 (lo line 0) lo
        ssubl2          v7.4s,   v5.8h,   v24.8h        // y0 (lo line 0) hi
        ssubl           v12.4s,  v19.4h,  v25.4h        // y0 (lo line 1) lo
        ssubl2          v18.4s,  v19.8h,  v25.8h        // y0 (lo line 1) hi
        ssra            v6.4s,   v6.4s,   #31           // Adjust for SRSHL rounding up (lo line 0)
        ssra            v7.4s,   v7.4s,   #31
        ssra            v12.4s,  v12.4s,  #31           // Adjust for SRSHR rounding up (lo line 1)
        ssra            v18.4s,  v18.4s,  #31
        mov             v24.16b, v26.16b
        mov             v25.16b, v27.16b
        srshl           v6.4s,   v6.4s,   v17.4s        // y0 (lo line 0) lo
        srshl           v7.4s,   v7.4s,   v17.4s        // y0 (lo line 0) hi
        rshrn           v19.4h,  v12.4s,  #7            // y0 (lo line 1)
        // For all lines after y = 0 use the regular shift value.
        mov             v26.16b, v1.16b
        uzp1            v5.8h,   v6.8h,   v7.8h         // y0 (lo line 0)
        rshrn2          v19.8h,  v18.4s,  #7            // y0 (lo line 1)
        // Compute the vertical gradient for the high halves of the current two lines.
        // in:  line 0: [-, v28], line 1: [-, v29], line 2: [-, v30],
        //      line 3: [-, v31], line 4: [-,  v2], line 5: [-, v22]
        // out: line 0: [-,  v14], line 1: [-,  v15]
        sub             v14.8h,  v31.8h,  v29.8h        // q2 - q1 (hi line 0)
        sub             v28.8h,  v2.8h,   v28.8h        // q3 - q0 (hi line 0)
        mov             v27.16b, v20.16b
        sub             v15.8h,  v2.8h,   v30.8h        // q2 - q1 (hi line 1)
        sub             v29.8h,  v22.8h,  v29.8h        // q3 - q0 (hi line 1)
        mul             z14.h,   z14.h,   #42           // (q2 - q1) * 42 (hi line 0)
        mul             z28.h,   z28.h,   #5            // (q3 - q0) * 5  (hi line 0)
        mul             z15.h,   z15.h,   #42           // (q2 - q1) * 42 (hi line 1)
        mul             z29.h,   z29.h,   #5            // (q3 - q0) * 5  (hi line 1)
        ssubl           v6.4s,   v14.4h,  v28.4h        // y0 (hi line 0) lo
        ssubl2          v7.4s,   v14.8h,  v28.8h        // y0 (hi line 0) hi
        ssubl           v12.4s,  v15.4h,  v29.4h        // y0 (hi line 1) lo
        ssubl2          v18.4s,  v15.8h,  v29.8h        // y0 (hi line 1) hi
        mov             v28.16b, v30.16b
        ssra            v6.4s,   v6.4s,   #31           // Adjust for SRSHL rounding up (hi line 0)
        ssra            v7.4s,   v7.4s,   #31
        ssra            v12.4s,  v12.4s,  #31           // Adjust for SRSHR rounding up (hi line 1)
        ssra            v18.4s,  v18.4s,  #31
        mov             v29.16b, v31.16b
        srshl           v6.4s,   v6.4s,   v17.4s        // y0 (hi line 0) lo
        srshl           v7.4s,   v7.4s,   v17.4s        // y0 (hi line 0) hi
        rshrn           v15.4h,  v12.4s,  #7            // y0 (hi line 1)
        mov             w19, #-7
        uzp1            v14.8h,  v6.8h,   v7.8h         // y0 (hi line 0)
        rshrn2          v15.8h,  v18.4s,  #7
        mov             v30.16b, v2.16b
        mov             v31.16b, v22.16b
6:

        // v0_lo = v5, v0_hi = v14, v1_lo = v19, v1_hi = v15
        // u0_lo = v1, u0_hi = v2,  u1_lo = v6,  u1_hi = v7
        // w0_lo = v3, w0_hi = v4,  w1_lo = v9,  w1_hi = v10
        // Do the rest of the accumulating (sv2, suv, svw).
        ldp             q1,  q2,  [sp, #160]            // horiz_gradient_low
        ldp             q6,  q7,  [sp, #192]            // horiz_gradient_high
        add             w13, w13, #2                    // py += 2
        add             w17, w12, w7                    // py_end = y + bs

        ldp             q12, q22, [sp, #32]             // suv_0, suv_1
        ldp             q16, q17, [sp, #64]             // sv2_0, sv2_1
        ldp             q18, q20, [sp, #128]            // svw_0, svw_1

        sdot            z12.d,  z1.h,  z5.h             // suv_0
        sdot            z22.d,  z2.h,  z14.h            // suv_1
        sdot            z16.d,  z5.h,  z5.h             // sv2_0
        sdot            z17.d,  z14.h, z14.h            // sv2_1
        sdot            z18.d,  z5.h,  z3.h             // svw_0
        sdot            z20.d,  z14.h, z4.h             // svw_1

        sdot            z12.d,  z6.h,  z19.h            // suv_0
        sdot            z22.d,  z7.h,  z15.h            // suv_1
        sdot            z16.d,  z19.h, z19.h            // sv2_0
        sdot            z17.d,  z15.h, z15.h            // sv2_1
        sdot            z18.d,  z19.h, z9.h             // svw_0
        sdot            z20.d,  z15.h, z10.h            // svw_1

        cmp             w13, w17                        // py < py_end

        stp             q12, q22, [sp, #32]
        stp             q16, q17, [sp, #64]
        stp             q18, q20, [sp, #128]

        mov             v3.16b,  v8.16b
        mov             v4.16b,  v21.16b
        mov             v9.16b,  v23.16b
        mov             v10.16b, v13.16b

        b.ne            4b

        // Accumulate and store to `out`.
        dup             v20.2d,  x14
        add             w12, w12, w7                    // y += bs
        ldp             q21, q11, [sp]                  // su2_0, su2_1
        ldp             q12, q13, [sp, #32]             // suv_0, suv_1
        ldp             q14, q15, [sp, #64]             // sv2_0, sv2_1
        ldp             q16, q17, [sp, #96]             // suw_0, suw_1
        ldp             q18, q19, [sp, #128]            // svw_0, svw_1
        cmp             w12, w6                         // y < h

        addp            d18,     v18.2d                 // svw_0
        addp            d19,     v19.2d                 // svw_1
        uzp1            v21.4s,  v21.4s,  v12.4s        // su2_0, suv_0
        uzp1            v14.4s,  v14.4s,  v16.4s        // sv2_0, suw_0
        uzp1            v11.4s,  v11.4s,  v13.4s        // su2_1, suv_1
        uzp1            v15.4s,  v15.4s,  v17.4s        // sv2_1, suw_1
        str             s18, [x15, #16]                 // out[0].svw
        str             s19, [x15, #36]                 // out[1].svw
        addp            v21.4s,  v21.4s,  v14.4s        // su2_0, suv_0, sv2_0, suw_0
        addp            v11.4s,  v11.4s,  v15.4s        // su2_1, suv_1, sv2_1, suw_1
        add             v21.4s,  v21.4s,  v20.4s        // add bs * bs to su2_0 and sv2_0
        add             v11.4s,  v11.4s,  v20.4s        // add bs * bs to su2_1 and sv2_1
        mov             x13, #20
        lsr             x17, x5,  #3
        str             q21, [x15]                      // out[0].{su2, suv, sv2, suw}
        str             q11, [x15, #20]                 // out[1].{su2, suv, sv2, suw}

        madd            x15, x17, x13, x15              // out += width >> 3 (20 bytes per struct)
        b.ne            3b

        add             w9,  w9,  #16                   // bx += 16
        add             x1,  x1,  #16
        cmp             w9,  w5                         // bx < w
        add             x0,  x0,  #40                   // 2 * out
        add             x3,  x3,  #16
        b.ne            2b

        add             sp,  sp,  #224
.endm

// Replace the shift right by 7 with a shift right by 6 when e1 = 1, allowing
// to skip the multiplication by (e1 + 1).
const shift_small
        .word -6, -7, -7, -7, -7, -7, -7, -6
endconst

// Process the 8-pixel-wide block two lines at a time. For bs == 4, the low
// and high halves form two adjacent 4x4 subblocks; for bs == 8, they form one
// 8x8 subblock. After completing the current subblock row, move down to the
// next one until the bottom of the block is reached.
.macro opfl_refine_mv_8bpc_small_sve
        // Compute tmp0/tmp1 for the first two lines.
        // in:  line 0: [v2, v3]  (p0, p1)
        //      line 1: [v8, v9]  (p0, p1)
        // out: line 0: tmp0 [v4], tmp1 [v5]
        //      line 1: tmp0 [v6], tmp1 [v7]
        ld1b            {z2.h}, p0/z, [x1]
        ld1b            {z3.h}, p0/z, [x3]
        add             x1,  x1,  x2
        add             x3,  x3,  x4
        ld1b            {z8.h}, p0/z, [x1]
        ld1b            {z9.h}, p0/z, [x3]
        sub             w11, w6,  #2                       // h - 2
        mul             v4.8h,   v2.8h,   v0.h[0]          // d.i8[0] * p0p (line 0)
        mul             v6.8h,   v8.8h,   v0.h[0]          // d.i8[0] * p0p (line 1)
        movrel          x8,  shift_small
        ldp             q15, q16, [x8]
        add             x1,  x1,  x2
        add             x3,  x3,  x4
        sub             v5.8h,   v2.8h,   v3.8h            // tmp1 (line 0)
        sub             v7.8h,   v8.8h,   v9.8h            // tmp1 (line 1)
        mla             v4.8h,   v3.8h,   v0.h[1]          // d.i8[0] * p0p + d.i8[1] * p1p (line 0)
        mla             v6.8h,   v9.8h,   v0.h[1]          // d.i8[0] * p0p + d.i8[1] * p1p (line 1)
        mov             w9,  #0                            // y = 0
        mul             w16, w7,  w7                       // bs * bs

        mov             v28.16b, v4.16b
        mov             v29.16b, v4.16b
        mov             v30.16b, v4.16b
        mov             v31.16b, v6.16b
        // This decides how much to shift y0 when computing the vertical
        // gradient. It's a shift right by 7 in most cases, unless e2 is 1 in
        // which case a shift right by 6 allows to skip the multiplication by
        // (1 + e2). This is true for y = 0, so initialize for this special
        // case, then later overwrite it for the general case.
        mov             w12, #-6
2:
        mov             w10, w9                            // py = y
        movi            v10.2d,  #0                        // su2_0, su2_1
        movi            v11.2d,  #0                        // suv_0, suv_1
        movi            v12.2d,  #0                        // sv2_0, sv2_1
        movi            v13.2d,  #0                        // suw_0, suw_1
        movi            v14.2d,  #0                        // svw_0, svw_1
        add             w17, w9,  w7                       // py_end = y + bs
3:
        // Compute the horizontal gradient for the current two lines.
        // in:  line 0: [v30], line 1: [v31]
        // out: line 0: [v2], line 1: [v25]
        dup             v20.8h,  v30.h[0]                 // min_x (line 0)
        dup             v21.8h,  v30.h[7]                 // max_x (line 0)
        ext             v2.16b,  v30.16b, v21.16b, #2     // p2 (line 0)
        ext             v1.16b,  v20.16b, v30.16b, #14    // p1 (line 0)
        ext             v22.16b, v20.16b, v30.16b, #12    // p0 (line 0)
        ext             v3.16b,  v30.16b, v21.16b, #4     // p3 (line 0)
        dup             v20.8h,  v31.h[0]                 // min_x (line 1)
        dup             v21.8h,  v31.h[7]                 // max_x (line 1)

        sub             v2.8h,   v2.8h,   v1.8h           // p2 - p1 (line 0)
        sub             v3.8h,   v3.8h,   v22.8h          // p3 - p0 (line 0)
        ext             v23.16b, v20.16b, v31.16b, #12    // p0 (line 1)
        ext             v26.16b, v31.16b, v21.16b, #4     // p3 (line 1)
        mul             z2.h,    z2.h,    #42             // (p2 - p1) * 42 (line 0)
        ext             v24.16b, v20.16b, v31.16b, #14    // p1 (line 1)
        ext             v25.16b, v31.16b, v21.16b, #2     // p2 (line 1)
        mul             z3.h,    z3.h,    #5              // (p3 - p0) * 5  (line 0)
        sub             v25.8h,  v25.8h,  v24.8h          // p2 - p1 (line 1)
        sub             v26.8h,  v26.8h,  v23.8h          // p3 - p0 (line 1)
        mul             z25.h,   z25.h,   #42             // (p2 - p1) * 42 (line 1)
        mul             z26.h,   z26.h,   #5              // (p3 - p0) * 5  (line 1)
        ssubl           v1.4s,   v2.4h,   v3.4h           // y0 (line 0) lo
        ssubl2          v22.4s,  v2.8h,   v3.8h           // y0 (line 0) hi
        ssubl           v4.4s,   v25.4h,  v26.4h          // y0 (line 1) lo
        ssubl2          v6.4s,   v25.8h,  v26.8h          // y0 (line 1) hi
        ssra            v1.4s,   v1.4s,   #31             // Adjust for SRSHL rounding up (line 0)
        ssra            v22.4s,  v22.4s,  #31
        ssra            v4.4s,   v4.4s,   #31             // Adjust for SRSHL rounding up (line 1)
        ssra            v6.4s,   v6.4s,   #31
        srshl           v1.4s,   v1.4s,   v15.4s          // x0 (line 0) lo
        srshl           v22.4s,  v22.4s,  v16.4s          // x0 (line 0) hi
        srshl           v4.4s,   v4.4s,   v15.4s          // x0 (line 1) lo
        srshl           v6.4s,   v6.4s,   v16.4s          // x0 (line 1) hi
        uzp1            v2.8h,   v1.8h,   v22.8h          // x0 (line 0)
        uzp1            v25.8h,  v4.8h,   v6.8h           // x0 (line 1)

        cmp             w10, w11                          // py < h - 2
        // Start accumulating the results that don't need the vertical gradient
        // (su2 and suw).
        sdot            z10.d,  z25.h, z25.h              // su2_0, su2_1
        sdot            z13.d,  z25.h, z7.h               // suw_0, suw_1
        sdot            z10.d,  z2.h,  z2.h               // su2_0, su2_1
        sdot            z13.d,  z2.h,  z5.h               // suw_0, suw_1

        b.lt            4f

        // We reached the end of the block, compute the vertical gradient
        // reusing the last line as needed. The result for the very last line
        // is right-shifted by 6 to account for e2 = 1.

        // Compute the vertical gradient for both rows.
        // in:  line 0: [v28], line 1: [v29], line 2: [v30]
        //      line 3: [v31], line 4: [v31], line 5: [v31]
        // out: line 0: [v24], line 1: [v26]
        sub             v24.8h,  v31.8h,  v29.8h             // q2 - q1 (line 0)
        sub             v1.8h,   v31.8h,  v28.8h             // q3 - q0 (line 0)
        sub             v22.8h,  v31.8h,  v30.8h             // q2 - q1 (line 1)
        sub             v23.8h,  v31.8h,  v29.8h             // q3 - q0 (line 1)
        mul             z24.h,   z24.h,   #42                // (q2 - q1) * 42 (line 0)
        mul             z1.h,    z1.h,    #5                 // (q3 - q0) * 5  (line 0)
        mul             z22.h,   z22.h,   #42                // (q2 - q1) * 42 (line 1)
        mul             z23.h,   z23.h,   #5                 // (q3 - q0) * 5  (line 1)
        ssubl           v20.4s,  v24.4h,  v1.4h              // y0 (line 0) lo
        ssubl2          v21.4s,  v24.8h,  v1.8h              // y0 (line 0) hi
        ssubl           v3.4s,   v22.4h,  v23.4h             // y0 (line 1) lo
        ssubl2          v4.4s,   v22.8h,  v23.8h             // y0 (line 1) hi
        ssra            v20.4s,  v20.4s,  #31                // Adjust for SRSHR rounding up (line 0)
        ssra            v21.4s,  v21.4s,  #31
        ssra            v3.4s,   v3.4s,   #31                // Adjust for SRSHR rounding up (line 1)
        ssra            v4.4s,   v4.4s,   #31
        rshrn           v24.4h,  v20.4s,  #7                 // y0 (line 0)
        rshrn           v26.4h,  v3.4s,   #6                 // y0 (line 1)
        rshrn2          v24.8h,  v21.4s,  #7
        rshrn2          v26.8h,  v4.4s,   #6
        // No need to move anything, it's the last iteration.
        b               5f

4:      // Compute tmp0/tmp1 for the next two lines.
        // in:  line 2: [v22, v23] (p0, p1)
        //      line 3: [v21, v3]  (p0, p1)
        // out: line 2: tmp0 [v4], tmp1 [v20]
        //      line 3: tmp0 [v6], tmp1 [v21]
        ld1b            {z22.h}, p0/z, [x1]
        ld1b            {z23.h}, p0/z, [x3]
        add             x1,  x1,  x2
        add             x3,  x3,  x4
        ld1b            {z21.h}, p0/z, [x1]
        ld1b            {z3.h}, p0/z, [x3]
        mul             v4.8h,   v22.8h,  v0.h[0]            // d.i8[0] * p0p (line 2)
        mul             v6.8h,   v21.8h,  v0.h[0]            // d.i8[0] * p0p (line 3)
        add             x1,  x1,  x2
        add             x3,  x3,  x4
        sub             v20.8h,  v22.8h,  v23.8h             // tmp1 (line 2)
        sub             v21.8h,  v21.8h,  v3.8h              // tmp1 (line 3)
        mla             v4.8h,   v23.8h,  v0.h[1]            // d.i8[0] * p0p + d.i8[1] * p1p (line 2)
        mla             v6.8h,   v3.8h,   v0.h[1]            // d.i8[0] * p0p + d.i8[1] * p1p (line 3)
        // Compute vertical gradient for the current two lines.
        // in:  line 0: [v28], line 1: [v29], line 2: [v30],
        //      line 3: [v31], line 4: [v4],  line 5: [v6]
        // out: line 0: [v24], line 1: [v26]
        dup             v27.4s,  w12
        sub             v1.8h,   v4.8h,   v28.8h             // q3 - q0 (line 0)
        sub             v24.8h,  v31.8h,  v29.8h             // q2 - q1 (line 0)
        sub             v22.8h,  v4.8h,   v30.8h             // q2 - q1 (line 1)
        sub             v23.8h,  v6.8h,   v29.8h             // q3 - q0 (line 1)
        // For all lines after y = 0 use the regular shift value.
        mov             w12, #-7
        mul             z24.h,   z24.h,   #42                // (q2 - q1) * 42 (line 0)
        mul             z1.h,    z1.h,    #5                 // (q3 - q0) * 5  (line 0)
        mul             z22.h,   z22.h,   #42                // (q2 - q1) * 42 (line 1)
        mul             z23.h,   z23.h,   #5                 // (q3 - q0) * 5  (line 1)
        ssubl           v3.4s,   v24.4h,  v1.4h              // y0 (line 0) lo
        ssubl2          v24.4s,  v24.8h,  v1.8h              // y0 (line 0) hi
        ssubl           v26.4s,  v22.4h,  v23.4h             // y0 (line 1) lo
        ssubl2          v29.4s,  v22.8h,  v23.8h             // y0 (line 1) hi
        ssra            v3.4s,   v3.4s,   #31                // Adjust for SRSHL rounding up (line 0)
        ssra            v24.4s,  v24.4s,  #31
        ssra            v26.4s,  v26.4s,  #31                // Adjust for SRSHR rounding up (line 1)
        ssra            v29.4s,  v29.4s,  #31
        srshl           v3.4s,   v3.4s,   v27.4s             // y0 (line 0) lo
        srshl           v24.4s,  v24.4s,  v27.4s             // y0 (line 0) hi
        rshrn           v26.4h,  v26.4s,  #7                 // y0 (line 1)
        mov             v28.16b, v30.16b
        uzp1            v24.8h,  v3.8h,   v24.8h             // y0 (line 0)
        rshrn2          v26.8h,  v29.4s,  #7                 // y0 (line 1)
        mov             v29.16b, v31.16b
        mov             v30.16b, v4.16b
        mov             v31.16b, v6.16b
5:
        // v0 = v24, v1 = v26, u0 = v2, u1 = v25, w0 = v5, w1 = v7
        // Do the rest of the accumulating (sv2, suv, svw).
        sdot            z14.d,  z24.h, z5.h                  // svw_0, svw_1
        add             w10, w10, #2                         // py += 2
        sdot            z14.d,  z26.h, z7.h                  // svw_0, svw_1
        sdot            z11.d,  z2.h,  z24.h                 // suv_0, suv_1
        sdot            z12.d,  z24.h, z24.h                 // sv2_0, sv2_1
        mov             v5.16b,  v20.16b
        mov             v7.16b,  v21.16b
        sdot            z11.d,  z25.h, z26.h                 // suv_0, suv_1
        sdot            z12.d,  z26.h, z26.h                 // sv2_0, sv2_1

        cmp             w10, w17                             // py < py_end
        b.ne            3b

        // Accumulate and store to `out`.
        cmp             w7,  #4                              // bs
        dup             v20.2d, x16                          // [0, bs * bs, 0, bs * bs]
        b.ne            6f

        // bs == 4
        trn1            v10.4s,  v10.4s,  v11.4s             // su2_0, suv_0, su2_1, suv_1
        trn1            v12.4s,  v12.4s,  v13.4s             // sv2_0, suw_0, sv2_1, suw_1
        add             x15, x0,  #16
        zip1            v17.2d,  v10.2d,  v12.2d             // su2_0, suv_0, sv2_0, suw_0
        zip2            v18.2d,  v10.2d,  v12.2d             // su2_1, suv_1, sv2_1, suw_1
        st1             {v14.s}[0], [x15]                    // out[0].svw
        add             v17.4s,  v17.4s,  v20.4s             // add bs * bs to su2_0 and sv2_0
        add             x15, x0,  #36
        str             q17, [x0]                            // out[0].{su2, suv, sv2, suw}
        add             v18.4s,  v18.4s,  v20.4s             // add bs * bs to su2_1 and sv2_1
        st1             {v14.s}[2], [x15]                    // out[1].svw
        str             q18, [x0, #20]                       // out[1].{su2, suv, sv2, suw}
        add             x0,  x0,  #40                        // out += 2
        b               7f

6:      // bs == 8
        addp            d14,     v14.2d                      // svw
        uzp1            v10.4s,  v10.4s,  v11.4s             // su2, suv
        uzp1            v12.4s,  v12.4s,  v13.4s             // sv2, suw
        addp            v10.4s,  v10.4s,  v12.4s             // su2, suv, sv2, suw
        add             v10.4s,  v10.4s,  v20.4s             // add bs * bs to su2 and sv2
        str             s14, [x0, #16]                       // out->svw
        str             q10, [x0]                            // out->{su2, suv, sv2, suw}
        add             x0,  x0,  #20                        // out++
7:
        add             w9,  w9,  w7                         // y += bs
        cmp             w9,  w6                              // y < h
        b.ne            2b

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
