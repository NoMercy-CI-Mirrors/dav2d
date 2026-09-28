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

// After SHSUB has consumed one right shift, replace the shift right by 6
// with a shift right by 5 when e1 = 1, allowing to skip the multiplication
// by (e1 + 1).
const shift_large, align=4
        .short -5, -6, -6, -6, -6, -6, -6, -6, -6, -6, -6, -6, -6, -6, -6, -5
endconst

const shift_small, align=4
        .short -5, -6, -6, -6, -6, -6, -6, -5
endconst

.macro opfl_refine_mv_large compute_next_rows, src_inc, isa
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
.ifc \isa, neon
        movi            v16.8h,  #42
        movi            v11.8h,  #5
.endif
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
.ifc \isa, sve
        mul             z22.h,   z22.h,   #42           // (p2 - p1) * 42 (lo line 0)
        mul             z17.h,   z17.h,   #5            // (p3 - p0) * 5  (lo line 0)
.else
        mul             v22.8h,  v22.8h,  v16.8h        // (p2 - p1) * 42 (lo line 0)
        mul             v17.8h,  v17.8h,  v11.8h        // (p3 - p0) * 5  (lo line 0)
.endif
        ext             v8.16b,  v26.16b, v30.16b, #14  // p1_hi (line 1)
        ext             v6.16b,  v30.16b, v21.16b, #4   // p3_hi (line 1)
        ext             v21.16b, v26.16b, v30.16b, #12  // p0_hi (line 1)
.ifc \isa, sve
        mul             z20.h,   z20.h,   #42           // (p2 - p1) * 42 (lo line 1)
        mul             z5.h,    z5.h,    #5            // (p3 - p0) * 5  (lo line 1)
.else
        mul             v20.8h,  v20.8h,  v16.8h        // (p2 - p1) * 42 (lo line 1)
        mul             v5.8h,   v5.8h,   v11.8h        // (p3 - p0) * 5  (lo line 1)
.endif
        sub             v14.8h,  v14.8h,  v23.8h        // p2 - p1 (hi line 0)
        sub             v19.8h,  v19.8h,  v8.8h         // p2 - p1 (hi line 1)
        sub             v6.8h,   v6.8h,   v21.8h        // p3 - p0 (hi line 1)
        sub             v15.8h,  v15.8h,  v7.8h         // p3 - p0 (hi line 0)
.ifc \isa, sve
        mul             z14.h,   z14.h,   #42           // (p2 - p1) * 42 (hi line 0)
        mul             z15.h,   z15.h,   #5            // (p3 - p0) * 5  (hi line 0)
.else
        mul             v14.8h,  v14.8h,  v16.8h        // (p2 - p1) * 42 (hi line 0)
        mul             v15.8h,  v15.8h,  v11.8h        // (p3 - p0) * 5  (hi line 0)
.endif
        ldp             q12, q13, [x8]                  // shift
.ifc \isa, sve
        mul             z19.h,   z19.h,   #42           // (p2 - p1) * 42 (hi line 1)
        mul             z6.h,    z6.h,    #5            // (p3 - p0) * 5  (hi line 1)
.else
        mul             v19.8h,  v19.8h,  v16.8h        // (p2 - p1) * 42 (hi line 1)
        mul             v6.8h,   v6.8h,   v11.8h        // (p3 - p0) * 5  (hi line 1)
.endif
        // Form x0 = (p2 - p1) * 42 - (p3 - p0) * 5 without widening:
        // SHSUB computes floor(x0 / 2), avoiding the potentially 17-bit
        // subtraction and consuming one bit of the final right shift.
        //
        // The *42 term is always even, so x0 has the same parity as the *5
        // term. For negative odd x0, SHSUB's rounding already accounts for
        // the -(x0 < 0) correction; only negative even x0 needs an extra -1.
        // Move the parity bit to the sign bit, use BIC to retain a sign only
        // for negative even x0, then use SSRA to apply that correction.
        shsub           v22.8h,  v22.8h,  v17.8h        // x0 / 2 (lo line 0)
        shsub           v20.8h,  v20.8h,  v5.8h         // x0 / 2 (lo line 1)
        shsub           v14.8h,  v14.8h,  v15.8h        // x0 / 2 (hi line 0)
        shsub           v19.8h,  v19.8h,  v6.8h         // x0 / 2 (hi line 1)
        shl             v17.8h,  v17.8h,  #15           // Move x0 parity to sign bit (lo line 0)
        shl             v5.8h,   v5.8h,   #15           // Move x0 parity to sign bit (lo line 1)
        shl             v15.8h,  v15.8h,  #15           // Move x0 parity to sign bit (hi line 0)
        shl             v6.8h,   v6.8h,   #15           // Move x0 parity to sign bit (hi line 1)
        bic             v17.16b, v22.16b, v17.16b       // Sign set if x0 < 0 and even (lo line 0)
        bic             v5.16b,  v20.16b, v5.16b        // Sign set if x0 < 0 and even (lo line 1)
        bic             v15.16b, v14.16b, v15.16b       // Sign set if x0 < 0 and even (hi line 0)
        bic             v6.16b,  v19.16b, v6.16b        // Sign set if x0 < 0 and even (hi line 1)
        ssra            v22.8h,  v17.8h,  #15           // Adjust for SRSHL rounding up (lo line 0)
        ssra            v20.8h,  v5.8h,   #15           // Adjust for SRSHL rounding up (lo line 1)
        ssra            v14.8h,  v15.8h,  #15           // Adjust for SRSHL rounding up (hi line 0)
        ssra            v19.8h,  v6.8h,   #15           // Adjust for SRSHL rounding up (hi line 1)
        srshl           v22.8h,  v22.8h,  v12.8h        // x0 (lo line 0)
        srshl           v20.8h,  v20.8h,  v12.8h        // x0 (lo line 1)
        srshl           v14.8h,  v14.8h,  v13.8h        // x0 (hi line 0)
        srshl           v19.8h,  v19.8h,  v13.8h        // x0 (hi line 1)
        ldp             q11, q16, [sp]                  // su2_0, su2_1

        // Start accumulating the results that don't need the vertical gradient
        // (su2 and suw).
.ifc \isa, sve
        sdot            z11.d,   z20.h,   z20.h         // su2_0
        sdot            z16.d,   z19.h,   z19.h         // su2_1
        ldp             q17, q18, [sp, #96]             // suw_0, suw_1

        sdot            z11.d,   z22.h,   z22.h         // su2_0
        sdot            z16.d,   z14.h,   z14.h         // su2_1
        cmp             w13, w16                        // py < h - 2
        sdot            z17.d,   z20.h,   z3.h          // suw_0
        sdot            z18.d,   z19.h,   z4.h          // suw_1
        stp             q20, q19, [sp, #160]
        stp             q11, q16, [sp]                  // su2_0, su2_1
        sdot            z17.d,   z22.h,   z9.h          // suw_0
        sdot            z18.d,   z14.h,   z10.h         // suw_1
        stp             q17, q18, [sp, #96]             // suw_0, suw_1
        stp             q22, q14, [sp, #192]
.else
        ldp             q17, q18, [sp, #96]             // suw_0, suw_1
        smlal           v11.4s,  v20.4h,  v20.4h        // su2_0
        smlal           v16.4s,  v19.4h,  v19.4h        // su2_1
        smlal           v17.4s,  v20.4h,  v3.4h         // suw_0
        smlal           v18.4s,  v19.4h,  v4.4h         // suw_1
        smlal2          v11.4s,  v20.8h,  v20.8h        // su2_0
        smlal2          v16.4s,  v19.8h,  v19.8h        // su2_1
        smlal2          v17.4s,  v20.8h,  v3.8h         // suw_0
        smlal2          v18.4s,  v14.8h,  v10.8h        // suw_1
        smlal           v11.4s,  v22.4h,  v22.4h        // su2_0
        smlal           v16.4s,  v14.4h,  v14.4h        // su2_1
        smlal           v17.4s,  v22.4h,  v9.4h         // suw_0
        smlal           v18.4s,  v14.4h,  v10.4h        // suw_1
        smlal2          v11.4s,  v22.8h,  v22.8h        // su2_0
        smlal2          v16.4s,  v14.8h,  v14.8h        // su2_1
        smlal2          v17.4s,  v22.8h,  v9.8h         // suw_0
        smlal2          v18.4s,  v19.8h,  v4.8h         // suw_1
        cmp             w13, w16                        // py < h - 2
        stp             q11, q16, [sp]                  // su2_0, su2_1
        stp             q17, q18, [sp, #96]             // suw_0, suw_1
        stp             q22, q14, [sp, #192]
        stp             q20, q19, [sp, #160]
.endif

        // If needed, compute tmp0/tmp1 for the next two lines (otherwise
        // reuse the last line), then compute the vertical gradients for the
        // current two lines.
.ifc \isa, neon
        movi            v16.8h,  #42
        movi            v11.8h,  #5
.endif
        b.lt            5f

        // We reached the end of the block, compute the vertical gradient
        // reusing the last line as needed. The result for the very last line
        // is right-shifted by 5 to account for e2 = 1.

        // Compute the vertical gradient for the low halves of the current two lines.
        // in:  line 0: [v24, v28], line 1: [v25, v29], line 2: [v26, v30],
        //      line 3: [v27, v31], line 4: [v27, v31], line 5: [v27, v31]
        // out: line 0: [v5,  -],  line 1: [v19, -]
        sub             v5.8h,   v27.8h,  v25.8h         // q2 - q1 (lo line 0)
        sub             v24.8h,  v27.8h,  v24.8h         // q3 - q0 (lo line 0)
        sub             v19.8h,  v27.8h,  v26.8h         // q2 - q1 (lo line 1)
        sub             v25.8h,  v27.8h,  v25.8h         // q3 - q0 (lo line 1)
.ifc \isa, sve
        mul             z5.h,    z5.h,    #42            // (q2 - q1) * 42 (lo line 0)
        mul             z24.h,   z24.h,   #5             // (q3 - q0) * 5  (lo line 0)
        mul             z19.h,   z19.h,   #42            // (q2 - q1) * 42 (lo line 1)
        mul             z25.h,   z25.h,   #5             // (q3 - q0) * 5  (lo line 1)
.else
        mul             v5.8h,   v5.8h,   v16.8h         // (q2 - q1) * 42 (lo line 0)
        mul             v24.8h,  v24.8h,  v11.8h         // (q3 - q0) * 5  (lo line 0)
        mul             v19.8h,  v19.8h,  v16.8h         // (q2 - q1) * 42 (lo line 1)
        mul             v25.8h,  v25.8h,  v11.8h         // (q3 - q0) * 5  (lo line 1)
.endif
        // Form y0 = (p2 - p1) * 42 - (p3 - p0) * 5 without widening.
        // SHSUB computes floor(y0 / 2), avoiding the 17-bit subtraction and
        // consuming one bit of the final right shift.
        //
        // The *42 term is even, so the *5 term determines y0 parity. SHSUB
        // already applies the required correction for negative odd y0; use
        // the parity and sign bits to subtract one only for negative even y0.
        shsub           v5.8h,   v5.8h,   v24.8h         // y0 / 2 (lo line 0)
        shsub           v19.8h,  v19.8h,  v25.8h         // y0 / 2 (lo line 1)
        shl             v24.8h,  v24.8h,  #15            // Move y0 parity to sign bit (lo line 0)
        shl             v25.8h,  v25.8h,  #15            // Move y0 parity to sign bit (lo line 1)
        bic             v24.16b, v5.16b,  v24.16b        // Sign set if y0 < 0 and even (lo line 0)
        bic             v25.16b, v19.16b, v25.16b        // Sign set if y0 < 0 and even (lo line 1)
        ssra            v5.8h,   v24.8h,  #15            // Adjust for SRSHR rounding up (lo line 0)
        ssra            v19.8h,  v25.8h,  #15            // Adjust for SRSHR rounding up (lo line 1)
        srshr           v5.8h,   v5.8h,   #6             // y0 (lo line 0)
        srshr           v19.8h,  v19.8h,  #5             // y0 (lo line 1)
        // Compute the vertical gradient for the high halves of the current two lines.
        // in:  line 0: [-, v28], line 1: [-, v29], line 2: [-, v30],
        //      line 3: [-, v31], line 4: [-, v31], line 5: [-, v31]
        // out: line 0: [-,  v14], line 1: [-,  v15]
        sub             v14.8h,  v31.8h,  v29.8h         // q2 - q1 (hi line 0)
        sub             v28.8h,  v31.8h,  v28.8h         // q3 - q0 (hi line 0)
        sub             v15.8h,  v31.8h,  v30.8h         // q2 - q1 (hi line 1)
        sub             v29.8h,  v31.8h,  v29.8h         // q3 - q0 (hi line 1)
.ifc \isa, sve
        mul             z14.h,   z14.h,   #42            // (q2 - q1) * 42 (hi line 0)
        mul             z28.h,   z28.h,   #5             // (q3 - q0) * 5  (hi line 0)
        mul             z15.h,   z15.h,   #42            // (q2 - q1) * 42 (hi line 1)
        mul             z29.h,   z29.h,   #5             // (q3 - q0) * 5  (hi line 1)
.else
        mul             v14.8h,  v14.8h,  v16.8h         // (q2 - q1) * 42 (hi line 0)
        mul             v28.8h,  v28.8h,  v11.8h         // (q3 - q0) * 5  (hi line 0)
        mul             v15.8h,  v15.8h,  v16.8h         // (q2 - q1) * 42 (hi line 1)
        mul             v29.8h,  v29.8h,  v11.8h         // (q3 - q0) * 5  (hi line 1)
.endif
        shsub           v14.8h,  v14.8h,  v28.8h         // y0 / 2 (hi line 0)
        shsub           v15.8h,  v15.8h,  v29.8h         // y0 / 2 (hi line 1)
        shl             v28.8h,  v28.8h,  #15            // Move y0 parity to sign bit (hi line 0)
        shl             v29.8h,  v29.8h,  #15            // Move y0 parity to sign bit (hi line 1)
        bic             v28.16b, v14.16b, v28.16b        // Sign set if y0 < 0 and even (hi line 0)
        bic             v29.16b, v15.16b, v29.16b        // Sign set if y0 < 0 and even (hi line 1)
        ssra            v14.8h,  v28.8h,  #15            // Adjust for SRSHR rounding up (hi line 0)
        ssra            v15.8h,  v29.8h,  #15            // Adjust for SRSHR rounding up (hi line 1)
        srshr           v14.8h,  v14.8h,  #6             // y0 (hi line 0)
        srshr           v15.8h,  v15.8h,  #5             // y0 (hi line 1)
        b               6f

5:
        // Compute tmp0 and tmp1 for the next two lines.
        // in:  line 2: bpc-specific p0/p1 registers
        //      line 3: bpc-specific p0/p1 registers
        // out: line 2: tmp0 [v1,  v2],  tmp1 [v8,  v21]
        //      line 3: tmp0 [v20, v22], tmp1 [v23, v13]
        \compute_next_rows
        dup             v17.8h,  w19

        // Compute the vertical gradient for the low halves of the current two lines.
        // in:  line 0: [v24, -], line 1: [v25, -], line 2: [v26, -],
        //      line 3: [v27, -], line 4: [v1,  -], line 5: [v20, -]
        // out: line 0: [v5,  -],  line 1: [v19, -]
        sub             v5.8h,   v27.8h,  v25.8h         // q2 - q1 (lo line 0)
        sub             v24.8h,  v1.8h,   v24.8h         // q3 - q0 (lo line 0)
        sub             v19.8h,  v1.8h,   v26.8h         // q2 - q1 (lo line 1)
        sub             v25.8h,  v20.8h,  v25.8h         // q3 - q0 (lo line 1)
.ifc \isa, sve
        mul             z5.h,    z5.h,    #42            // (q2 - q1) * 42 (lo line 0)
        mul             z24.h,   z24.h,   #5             // (q3 - q0) * 5  (lo line 0)
        mul             z19.h,   z19.h,   #42            // (q2 - q1) * 42 (lo line 1)
        mul             z25.h,   z25.h,   #5             // (q3 - q0) * 5  (lo line 1)
.else
        mul             v5.8h,   v5.8h,   v16.8h         // (q2 - q1) * 42 (lo line 0)
        mul             v24.8h,  v24.8h,  v11.8h         // (q3 - q0) * 5  (lo line 0)
        mul             v19.8h,  v19.8h,  v16.8h         // (q2 - q1) * 42 (lo line 1)
        mul             v25.8h,  v25.8h,  v11.8h         // (q3 - q0) * 5  (lo line 1)
.endif
        // Form y0 = (p2 - p1) * 42 - (p3 - p0) * 5 without widening.
        // SHSUB computes floor(y0 / 2), avoiding the 17-bit subtraction and
        // consuming one bit of the final right shift.
        //
        // The *42 term is even, so the *5 term determines y0 parity. SHSUB
        // already applies the required correction for negative odd y0; use
        // the parity and sign bits to subtract one only for negative even y0.
        shsub           v5.8h,   v5.8h,   v24.8h         // y0 / 2 (lo line 0)
        shsub           v19.8h,  v19.8h,  v25.8h         // y0 / 2 (lo line 1)
        shl             v24.8h,  v24.8h,  #15            // Move y0 parity to sign bit (lo line 0)
        shl             v25.8h,  v25.8h,  #15            // Move y0 parity to sign bit (lo line 1)
        bic             v24.16b, v5.16b,  v24.16b        // Sign set if y0 < 0 and even (lo line 0)
        bic             v25.16b, v19.16b, v25.16b        // Sign set if y0 < 0 and even (lo line 1)
        ssra            v5.8h,   v24.8h,  #15            // Adjust for SRSHL rounding up (lo line 0)
        ssra            v19.8h,  v25.8h,  #15            // Adjust for SRSHR rounding up (lo line 1)
        mov             v24.16b, v26.16b
        mov             v25.16b, v27.16b
        srshl           v5.8h,   v5.8h,   v17.8h         // y0 (lo line 0)
        srshr           v19.8h,  v19.8h,  #6             // y0 (lo line 1)
        mov             v26.16b, v1.16b
        // Compute the vertical gradient for the high halves of the current two lines.
        // in:  line 0: [-, v28], line 1: [-, v29], line 2: [-, v30],
        //      line 3: [-, v31], line 4: [-,  v2], line 5: [-, v22]
        // out: line 0: [-,  v14], line 1: [-,  v15]
        sub             v14.8h,  v31.8h,  v29.8h         // q2 - q1 (hi line 0)
        sub             v28.8h,  v2.8h,   v28.8h         // q3 - q0 (hi line 0)
        mov             v27.16b, v20.16b
        sub             v15.8h,  v2.8h,   v30.8h         // q2 - q1 (hi line 1)
        sub             v29.8h,  v22.8h,  v29.8h         // q3 - q0 (hi line 1)
.ifc \isa, sve
        mul             z14.h,   z14.h,   #42            // (q2 - q1) * 42 (hi line 0)
        mul             z28.h,   z28.h,   #5             // (q3 - q0) * 5  (hi line 0)
        mul             z15.h,   z15.h,   #42            // (q2 - q1) * 42 (hi line 1)
        mul             z29.h,   z29.h,   #5             // (q3 - q0) * 5  (hi line 1)
.else
        mul             v14.8h,  v14.8h,  v16.8h         // (q2 - q1) * 42 (hi line 0)
        mul             v28.8h,  v28.8h,  v11.8h         // (q3 - q0) * 5  (hi line 0)
        mul             v15.8h,  v15.8h,  v16.8h         // (q2 - q1) * 42 (hi line 1)
        mul             v29.8h,  v29.8h,  v11.8h         // (q3 - q0) * 5  (hi line 1)
.endif
        shsub           v14.8h,  v14.8h,  v28.8h         // y0 / 2 (hi line 0)
        shsub           v15.8h,  v15.8h,  v29.8h         // y0 / 2 (hi line 1)
        shl             v28.8h,  v28.8h,  #15            // Move y0 parity to sign bit (hi line 0)
        shl             v29.8h,  v29.8h,  #15            // Move y0 parity to sign bit (hi line 1)
        bic             v28.16b, v14.16b, v28.16b        // Sign set if y0 < 0 and even (hi line 0)
        bic             v29.16b, v15.16b, v29.16b        // Sign set if y0 < 0 and even (hi line 1)
        ssra            v14.8h,  v28.8h,  #15            // Adjust for SRSHL rounding up (hi line 0)
        ssra            v15.8h,  v29.8h,  #15            // Adjust for SRSHR rounding up (hi line 1)
        srshl           v14.8h,  v14.8h,  v17.8h         // y0 (hi line 0)
        srshr           v15.8h,  v15.8h,  #6             // y0 (hi line 1)
        mov             v28.16b, v30.16b
        mov             v29.16b, v31.16b
        // For all lines after y = 0 use the regular shift value.
        mov             w19, #-6
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

.ifc \isa, sve
        sdot            z12.d,   z1.h,    z5.h          // suv_0
        sdot            z22.d,   z2.h,    z14.h         // suv_1
        sdot            z16.d,   z5.h,    z5.h          // sv2_0
        sdot            z17.d,   z14.h,   z14.h         // sv2_1
        sdot            z18.d,   z5.h,    z3.h          // svw_0
        sdot            z20.d,   z14.h,   z4.h          // svw_1

        sdot            z12.d,   z6.h,    z19.h         // suv_0
        sdot            z22.d,   z7.h,    z15.h         // suv_1
        sdot            z16.d,   z19.h,   z19.h         // sv2_0
        sdot            z17.d,   z15.h,   z15.h         // sv2_1
        sdot            z18.d,   z19.h,   z9.h          // svw_0
        sdot            z20.d,   z15.h,   z10.h         // svw_1
.else
        smlal           v12.4s,  v1.4h,   v5.4h         // suv_0
        smlal           v22.4s,  v2.4h,   v14.4h        // suv_1
        smlal           v16.4s,  v5.4h,   v5.4h         // sv2_0
        smlal           v17.4s,  v14.4h,  v14.4h        // sv2_1
        smlal           v18.4s,  v5.4h,   v3.4h         // svw_0
        smlal           v20.4s,  v14.4h,  v4.4h         // svw_1

        smlal2          v12.4s,  v1.8h,   v5.8h         // suv_0
        smlal2          v22.4s,  v2.8h,   v14.8h        // suv_1
        smlal2          v16.4s,  v5.8h,   v5.8h         // sv2_0
        smlal2          v17.4s,  v14.8h,  v14.8h        // sv2_1
        smlal2          v18.4s,  v5.8h,   v3.8h         // svw_0
        smlal2          v20.4s,  v14.8h,  v4.8h         // svw_1

        smlal           v12.4s,  v6.4h,   v19.4h        // suv_0
        smlal           v22.4s,  v7.4h,   v15.4h        // suv_1
        smlal           v16.4s,  v19.4h,  v19.4h        // sv2_0
        smlal           v17.4s,  v15.4h,  v15.4h        // sv2_1
        smlal           v18.4s,  v19.4h,  v9.4h         // svw_0
        smlal           v20.4s,  v15.4h,  v10.4h        // svw_1

        smlal2          v12.4s,  v6.8h,   v19.8h        // suv_0
        smlal2          v22.4s,  v7.8h,   v15.8h        // suv_1
        smlal2          v16.4s,  v19.8h,  v19.8h        // sv2_0
        smlal2          v17.4s,  v15.8h,  v15.8h        // sv2_1
        smlal2          v18.4s,  v19.8h,  v9.8h         // svw_0
        smlal2          v20.4s,  v15.8h,  v10.8h        // svw_1
.endif

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

.ifc \isa, sve
        addp            d18,     v18.2d                 // svw_0
        addp            d19,     v19.2d                 // svw_1
        uzp1            v21.4s,  v21.4s,  v12.4s        // su2_0, suv_0
        uzp1            v14.4s,  v14.4s,  v16.4s        // sv2_0, suw_0
        uzp1            v11.4s,  v11.4s,  v13.4s        // su2_1, suv_1
        uzp1            v15.4s,  v15.4s,  v17.4s        // sv2_1, suw_1
.else
        addv            s18,     v18.4s                 // svw_0
        addv            s19,     v19.4s                 // svw_1
        addp            v21.4s,  v21.4s,  v12.4s        // su2_0, suv_0
        addp            v14.4s,  v14.4s,  v16.4s        // sv2_0, suw_0
        addp            v11.4s,  v11.4s,  v13.4s        // su2_1, suv_1
        addp            v15.4s,  v15.4s,  v17.4s        // sv2_1, suw_1
.endif
        str             s18, [x15, #16]                 // out[0].svw
        addp            v21.4s,  v21.4s,  v14.4s        // su2_0, suv_0, sv2_0, suw_0
        addp            v11.4s,  v11.4s,  v15.4s        // su2_1, suv_1, sv2_1, suw_1
        str             s19, [x15, #36]                 // out[1].svw
        add             v21.4s,  v21.4s,  v20.4s        // add bs * bs to su2_0 and sv2_0
        add             v11.4s,  v11.4s,  v20.4s        // add bs * bs to su2_1 and sv2_1
        mov             x13, #20
        lsr             x17, x5,  #3
        str             q21, [x15]                      // out[0].{su2, suv, sv2, suw}
        str             q11, [x15, #20]                 // out[1].{su2, suv, sv2, suw}

        madd            x15, x17, x13, x15              // out += width >> 3 (20 bytes per struct)
        b.ne            3b

        add             w9,  w9,  #16                   // bx += 16
        add             x1,  x1,  #\src_inc
        cmp             w9,  w5                         // bx < w
        add             x0,  x0,  #40                   // 2 * out
        add             x3,  x3,  #\src_inc
        b.ne            2b

        add             sp,  sp,  #224
.endm

.macro opfl_refine_mv_small compute_next_rows, isa
        mov             v28.16b, v4.16b
        mov             v29.16b, v4.16b
        mov             v30.16b, v4.16b
        mov             v31.16b, v6.16b
.ifc \isa, neon
        movi            v9.8h,   #42
        movi            v27.8h,  #5
.endif
        // This decides how much to shift y0 after SHSUB has consumed one
        // right shift. It's a shift right by 6 in most cases, unless e2 is 1
        // in which case a shift right by 5 allows to skip the multiplication
        // by (1 + e2). This is true for y = 0, so initialize for this special
        // case, then later overwrite it for the general case.
        mov             w12, #-5
2:
        mov             w10, w9                      // py = y
        movi            v10.2d,  #0
        movi            v11.2d,  #0
        movi            v12.2d,  #0
        movi            v13.2d,  #0
        movi            v14.2d,  #0
        add             w17, w9,  w7                 // py_end = y + bs
.ifc \isa, neon
        movi            v15.4s,  #0                  // su2_1
        movi            v16.4s,  #0                  // suv_1
        movi            v17.4s,  #0                  // sv2_1
        movi            v18.4s,  #0                  // suw_1
        movi            v19.4s,  #0                  // svw_1
.endif
3:
        // Compute the horizontal gradient for the current two lines.
        // in:  line 0: [v30], line 1: [v31]
        // out: line 0: [v2], line 1: [v25]
        dup             v20.8h,  v30.h[0]                // min_x (line 0)
        dup             v21.8h,  v30.h[7]                // max_x (line 0)
        ext             v2.16b,  v30.16b, v21.16b, #2    // p2 (line 0)
        ext             v1.16b,  v20.16b, v30.16b, #14   // p1 (line 0)
        ext             v22.16b, v20.16b, v30.16b, #12   // p0 (line 0)
        ext             v3.16b,  v30.16b, v21.16b, #4    // p3 (line 0)
        dup             v20.8h,  v31.h[0]                // min_x (line 1)
        dup             v21.8h,  v31.h[7]                // max_x (line 1)

        sub             v2.8h,   v2.8h,   v1.8h          // p2 - p1 (line 0)
        sub             v3.8h,   v3.8h,   v22.8h         // p3 - p0 (line 0)
        ext             v23.16b, v20.16b, v31.16b, #12   // p0 (line 1)
        ext             v26.16b, v31.16b, v21.16b, #4    // p3 (line 1)
.ifc \isa, sve
        mul             z2.h,    z2.h,    #42            // (p2 - p1) * 42 (line 0)
.else
        mul             v2.8h,   v2.8h,   v9.8h          // (p2 - p1) * 42 (line 0)
.endif
        ext             v24.16b, v20.16b, v31.16b, #14   // p1 (line 1)
        ext             v25.16b, v31.16b, v21.16b, #2    // p2 (line 1)
.ifc \isa, sve
        mul             z3.h,    z3.h,    #5             // (p3 - p0) * 5  (line 0)
.else
        mul             v3.8h,   v3.8h,   v27.8h         // (p3 - p0) * 5  (line 0)
.endif
        sub             v25.8h,  v25.8h,  v24.8h         // p2 - p1 (line 1)
        sub             v26.8h,  v26.8h,  v23.8h         // p3 - p0 (line 1)
.ifc \isa, sve
        mul             z25.h,   z25.h,   #42            // (p2 - p1) * 42 (line 1)
        mul             z26.h,   z26.h,   #5             // (p3 - p0) * 5  (line 1)
.else
        mul             v25.8h,  v25.8h,  v9.8h          // (p2 - p1) * 42 (line 1)
        mul             v26.8h,  v26.8h,  v27.8h         // (p3 - p0) * 5  (line 1)
.endif
        // Form x0 = (p2 - p1) * 42 - (p3 - p0) * 5 without widening.
        // SHSUB computes floor(x0 / 2), avoiding the 17-bit subtraction and
        // consuming one bit of the final right shift.
        //
        // The *42 term is even, so the *5 term determines x0 parity. SHSUB
        // already applies the required correction for negative odd x0; use
        // the parity and sign bits to subtract one only for negative even x0.
        shsub           v2.8h,   v2.8h,   v3.8h          // x0 / 2 (line 0)
        shsub           v25.8h,  v25.8h,  v26.8h         // x0 / 2 (line 1)
        shl             v3.8h,   v3.8h,   #15            // Move x0 parity to sign bit (line 0)
        shl             v26.8h,  v26.8h,  #15            // Move x0 parity to sign bit (line 1)
        bic             v3.16b,  v2.16b,  v3.16b         // Sign set if x0 < 0 and even (line 0)
        bic             v26.16b, v25.16b, v26.16b        // Sign set if x0 < 0 and even (line 1)
        ssra            v2.8h,   v3.8h,   #15            // Adjust for SRSHL rounding up (line 0)
        ssra            v25.8h,  v26.8h,  #15            // Adjust for SRSHL rounding up (line 1)
        srshl           v2.8h,   v2.8h,   v8.8h          // x0 (line 0)
        srshl           v25.8h,  v25.8h,  v8.8h          // x0 (line 1)

        cmp             w10, w11                         // py < h - 2
        // Start accumulating the results that don't need the vertical gradient
        // (su2 and suw).
.ifc \isa, sve
        sdot            z10.d,   z25.h,   z25.h          // su2_0, su2_1
        sdot            z13.d,   z25.h,   z7.h           // suw_0, suw_1
        sdot            z10.d,   z2.h,    z2.h           // su2_0, su2_1
        sdot            z13.d,   z2.h,    z5.h           // suw_0, suw_1
.else
        smlal           v10.4s,  v25.4h,  v25.4h         // su2_0
        smlal2          v15.4s,  v25.8h,  v25.8h         // su2_1
        smlal           v13.4s,  v25.4h,  v7.4h          // suw_0
        smlal2          v18.4s,  v25.8h,  v7.8h          // suw_1
        smlal           v10.4s,  v2.4h,   v2.4h          // su2_0
        smlal2          v15.4s,  v2.8h,   v2.8h          // su2_1
        smlal           v13.4s,  v2.4h,   v5.4h          // suw_0
        smlal2          v18.4s,  v2.8h,   v5.8h          // suw_1
.endif
        b.lt            4f

        // We reached the end of the block, compute the vertical gradient
        // reusing the last line as needed. The result for the very last line
        // is right-shifted by 5 to account for e2 = 1.

        // Compute the vertical gradient for both rows.
        // in:  line 0: [v28], line 1: [v29], line 2: [v30]
        //      line 3: [v31], line 4: [v31], line 5: [v31]
        // out: line 0: [v24], line 1: [v26]
        sub             v24.8h,  v31.8h,  v29.8h         // q2 - q1 (line 0)
        sub             v1.8h,   v31.8h,  v28.8h         // q3 - q0 (line 0)
        sub             v22.8h,  v31.8h,  v30.8h         // q2 - q1 (line 1)
        sub             v23.8h,  v31.8h,  v29.8h         // q3 - q0 (line 1)
.ifc \isa, sve
        mul             z24.h,   z24.h,   #42            // (q2 - q1) * 42 (line 0)
        mul             z1.h,    z1.h,    #5             // (q3 - q0) * 5  (line 0)
        mul             z22.h,   z22.h,   #42            // (q2 - q1) * 42 (line 1)
        mul             z23.h,   z23.h,   #5             // (q3 - q0) * 5  (line 1)
.else
        mul             v24.8h,  v24.8h,  v9.8h          // (q2 - q1) * 42 (line 0)
        mul             v1.8h,   v1.8h,   v27.8h         // (q3 - q0) * 5  (line 0)
        mul             v22.8h,  v22.8h,  v9.8h          // (q2 - q1) * 42 (line 1)
        mul             v23.8h,  v23.8h,  v27.8h         // (q3 - q0) * 5  (line 1)
.endif
        // Form y0 = (p2 - p1) * 42 - (p3 - p0) * 5 without widening.
        // SHSUB computes floor(y0 / 2), avoiding the 17-bit subtraction and
        // consuming one bit of the final right shift.
        //
        // The *42 term is even, so the *5 term determines y0 parity. SHSUB
        // already applies the required correction for negative odd y0; use
        // the parity and sign bits to subtract one only for negative even y0.
        shsub           v24.8h,  v24.8h,  v1.8h          // y0 / 2 (line 0)
        shsub           v22.8h,  v22.8h,  v23.8h         // y0 / 2 (line 1)
        shl             v1.8h,   v1.8h,   #15            // Move y0 parity to sign bit (line 0)
        shl             v23.8h,  v23.8h,  #15            // Move y0 parity to sign bit (line 1)
        bic             v1.16b,  v24.16b, v1.16b         // Sign set if y0 < 0 and even (line 0)
        bic             v23.16b, v22.16b, v23.16b        // Sign set if y0 < 0 and even (line 1)
        ssra            v24.8h,  v1.8h,   #15            // Adjust for SRSHR rounding up (line 0)
        ssra            v22.8h,  v23.8h,  #15            // Adjust for SRSHR rounding up (line 1)
        srshr           v24.8h,  v24.8h,  #6             // y0 (line 0)
        srshr           v26.8h,  v22.8h,  #5             // y0 (line 1)
        // No need to move anything, it's the last iteration.
        b               5f

4:      // Compute tmp0/tmp1 for the next two lines.
        // in:  line 2: [v22, v23] (p0, p1)
        //      line 3: [v2,  v3]  (p0, p1)
        // out: line 2: tmp0 [v4], tmp1 [v20]
        //      line 3: tmp0 [v6], tmp1 [v21]
        \compute_next_rows
        // Compute vertical gradient for the current two lines.
        // in:  line 0: [v28], line 1: [v29], line 2: [v30],
        //      line 3: [v31], line 4: [v4],  line 5: [v6]
        // out: line 0: [v24], line 1: [v26]
        sub             v1.8h,   v4.8h,   v28.8h        // q3 - q0 (line 0)
        sub             v24.8h,  v31.8h,  v29.8h        // q2 - q1 (line 0)
        sub             v22.8h,  v4.8h,   v30.8h        // q2 - q1 (line 1)
        sub             v23.8h,  v6.8h,   v29.8h        // q3 - q0 (line 1)
        dup             v28.8h,  w12
        // For all lines after y = 0 use the regular shift value.
        mov             w12, #-6
.ifc \isa, sve
        mul             z24.h,   z24.h,   #42           // (q2 - q1) * 42 (line 0)
        mul             z1.h,    z1.h,    #5            // (q3 - q0) * 5  (line 0)
        mul             z22.h,   z22.h,   #42           // (q2 - q1) * 42 (line 1)
        mul             z23.h,   z23.h,   #5            // (q3 - q0) * 5  (line 1)
.else
        mul             v24.8h,  v24.8h,  v9.8h         // (q2 - q1) * 42 (line 0)
        mul             v1.8h,   v1.8h,   v27.8h        // (q3 - q0) * 5  (line 0)
        mul             v22.8h,  v22.8h,  v9.8h         // (q2 - q1) * 42 (line 1)
        mul             v23.8h,  v23.8h,  v27.8h        // (q3 - q0) * 5  (line 1)
.endif
        // Form y0 = (p2 - p1) * 42 - (p3 - p0) * 5 without widening.
        // SHSUB computes floor(y0 / 2), avoiding the 17-bit subtraction and
        // consuming one bit of the final right shift.
        //
        // The *42 term is even, so the *5 term determines y0 parity. SHSUB
        // already applies the required correction for negative odd y0; use
        // the parity and sign bits to subtract one only for negative even y0.
        shsub           v24.8h,  v24.8h,  v1.8h         // y0 / 2 (line 0)
        shsub           v22.8h,  v22.8h,  v23.8h        // y0 / 2 (line 1)
        shl             v1.8h,   v1.8h,   #15           // Move y0 parity to sign bit (line 0)
        shl             v23.8h,  v23.8h,  #15           // Move y0 parity to sign bit (line 1)
        bic             v1.16b,  v24.16b, v1.16b        // Sign set if y0 < 0 and even (line 0)
        bic             v23.16b, v22.16b, v23.16b       // Sign set if y0 < 0 and even (line 1)
        ssra            v24.8h,  v1.8h,   #15           // Adjust for SRSHL rounding up (line 0)
        ssra            v22.8h,  v23.8h,  #15           // Adjust for SRSHR rounding up (line 1)
        srshl           v24.8h,  v24.8h,  v28.8h        // y0 (line 0)
        srshr           v26.8h,  v22.8h,  #6            // y0 (line 1)
        mov             v28.16b, v30.16b
        mov             v29.16b, v31.16b
        mov             v30.16b, v4.16b
        mov             v31.16b, v6.16b
5:
        // v0 = v24, v1 = v26, u0 = v2, u1 = v25, w0 = v5, w1 = v7
        // Do the rest of the accumulating (sv2, suv, svw).
.ifc \isa, sve
        sdot            z14.d,   z24.h,   z5.h          // svw_0, svw_1
        add             w10, w10, #2                    // py += 2
        sdot            z14.d,   z26.h,   z7.h          // svw_0, svw_1
        sdot            z11.d,   z2.h,    z24.h         // suv_0, suv_1
        sdot            z12.d,   z24.h,   z24.h         // sv2_0, sv2_1
        mov             v5.16b,  v20.16b
        mov             v7.16b,  v21.16b
        sdot            z11.d,   z25.h,   z26.h         // suv_0, suv_1
        sdot            z12.d,   z26.h,   z26.h         // sv2_0, sv2_1
.else
        smlal           v14.4s,  v24.4h,  v5.4h         // svw_0
        smlal2          v19.4s,  v24.8h,  v5.8h         // svw_1
        add             w10, w10, #2                    // py += 2
        smlal           v14.4s,  v26.4h,  v7.4h         // svw_0
        smlal2          v19.4s,  v26.8h,  v7.8h         // svw_1
        smlal           v11.4s,  v2.4h,   v24.4h        // suv_0
        smlal2          v16.4s,  v2.8h,   v24.8h        // suv_1
        smlal           v12.4s,  v24.4h,  v24.4h        // sv2_0
        smlal2          v17.4s,  v24.8h,  v24.8h        // sv2_1
        mov             v5.16b,  v20.16b
        mov             v7.16b,  v21.16b
        smlal           v11.4s,  v25.4h,  v26.4h        // suv_0
        smlal2          v16.4s,  v25.8h,  v26.8h        // suv_1
        smlal           v12.4s,  v26.4h,  v26.4h        // sv2_0
        smlal2          v17.4s,  v26.8h,  v26.8h        // sv2_1
.endif

        cmp             w10, w17                        // py < py_end
        b.ne            3b

        // Accumulate and store to `out`.
        cmp             w7,  #4                         // bs
        dup             v20.2d,  x16                    // [0, bs * bs, 0, bs * bs]
        b.ne            6f

        // bs == 4
.ifc \isa, sve
        trn1            v10.4s,  v10.4s,  v11.4s        // su2_0, suv_0, su2_1, suv_1
        trn1            v12.4s,  v12.4s,  v13.4s        // sv2_0, suw_0, sv2_1, suw_1
        add             x15, x0,  #36
        zip1            v17.2d,  v10.2d,  v12.2d        // su2_0, suv_0, sv2_0, suw_0
        zip2            v18.2d,  v10.2d,  v12.2d        // su2_1, suv_1, sv2_1, suw_1
        str             s14, [x0, #16]                  // out[0].svw
        add             v17.4s,  v17.4s,  v20.4s        // add bs * bs to su2_0 and sv2_0
        str             q17, [x0]                       // out[0].{su2, suv, sv2, suw}
        add             v18.4s,  v18.4s,  v20.4s        // add bs * bs to su2_1 and sv2_1
        st1             {v14.s}[2], [x15]               // out[1].svw
        str             q18, [x0, #20]                  // out[1].{su2, suv, sv2, suw}
.else
        addv            s14,     v14.4s                 // svw_0
        addv            s19,     v19.4s                 // svw_1
        addp            v10.4s,  v10.4s,  v11.4s        // su2_0, suv_0
        addp            v12.4s,  v12.4s,  v13.4s        // sv2_0, suw_0
        addp            v15.4s,  v15.4s,  v16.4s        // su2_1, suv_1
        addp            v17.4s,  v17.4s,  v18.4s        // sv2_1, suw_1
        addp            v10.4s,  v10.4s,  v12.4s        // su2_0, suv_0, sv2_0, suw_0
        addp            v15.4s,  v15.4s,  v17.4s        // su2_1, suv_1, sv2_1, suw_1
        str             s14, [x0, #16]                  // out[0].svw
        str             s19, [x0, #36]                  // out[1].svw
        add             v10.4s,  v10.4s,  v20.4s        // add bs * bs to su2_0 and sv2_0
        add             v15.4s,  v15.4s,  v20.4s        // add bs * bs to su2_1 and sv2_1
        str             q10, [x0]                       // out[0].{su2, suv, sv2, suw}
        str             q15, [x0, #20]                  // out[1].{su2, suv, sv2, suw}
.endif
        add             x0,  x0,  #40                   // out += 2
        b               7f
6:      // bs == 8
.ifc \isa, sve
        addp            d14,     v14.2d                 // svw
        uzp1            v10.4s,  v10.4s,  v11.4s        // su2, suv
        uzp1            v12.4s,  v12.4s,  v13.4s        // sv2, suw
.else
        add             v10.4s,  v10.4s,  v15.4s        // su2 = su2_0 + su2_1
        add             v11.4s,  v11.4s,  v16.4s        // suv = suv_0 + suv_1
        add             v12.4s,  v12.4s,  v17.4s        // sv2 = sv2_0 + sv2_1
        add             v13.4s,  v13.4s,  v18.4s        // suw = suw_0 + suw_1
        add             v14.4s,  v14.4s,  v19.4s        // svw = svw_0 + svw_1
        addv            s14,     v14.4s                 // svw
        addp            v10.4s,  v10.4s,  v11.4s        // su2, suv
        addp            v12.4s,  v12.4s,  v13.4s        // sv2, suw
.endif
        addp            v10.4s,  v10.4s,  v12.4s        // su2, suv, sv2, suw
        add             v10.4s,  v10.4s,  v20.4s        // add bs * bs to su2 and sv2
        str             s14, [x0, #16]                  // out->svw
        str             q10, [x0]                       // out->{su2, suv, sv2, suw}
        add             x0,  x0,  #20                   // out++
7:
        add             w9,  w9,  w7                    // y += bs
        cmp             w9,  w6                         // y < h
        b.ne            2b
.endm
