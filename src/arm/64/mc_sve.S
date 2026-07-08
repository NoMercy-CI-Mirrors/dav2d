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

#if HAVE_SVE2
ENABLE_SVE
ENABLE_SVE2

// LUT to combine reordering the elements after the SMLALB/T instruction,
// shifting a 32-bit value by 8 and narrowing it to 16 bits.
const narrow_shift_tbl, align=4
        .byte 1, 2, 17, 18, 5, 6, 21, 22, 9, 10, 25, 26, 13, 14, 29, 30
endconst

// void morph_sve2(pixel *dst, const ptrdiff_t dst_stride,
//                 const int alpha, const int beta,
//                 const int w, const int h HIGHBD_DECL_SUFFIX)
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
DISABLE_SVE
#endif  // HAVE_SVE2
