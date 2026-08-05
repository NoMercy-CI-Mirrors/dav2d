/******************************************************************************
 * Copyright © 2026, VideoLAN and dav2d authors
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

// void gdf_add_8bpc_neon(pixel *p_line, const ptrdiff_t stride,
//                        const int8_t *err_line, const uint16_t (*const ll_mask)[4],
//                        const int w, const int h, const int scale)
function gdf_add_8bpc_neon, export=1
        dup             v30.16b, w6                     // scale

1:      // by loop
        ldrh            w7, [x3], #8                    // ll_mask[by][0]
        lsr             w8,  w4,  #2                    // bx_max
        mov             x9,  x2
        add             x10, x2,  #64
        add             x11, x2,  #128
        add             x12, x2,  #192
        mov             x13, x0
        add             x14, x0,  x1
        add             x15, x0,  x1,  lsl #1
        add             x16, x14, x1,  lsl #1

2:      // bx loop
        and             w17, w7,  w7,  lsr #1           // w17[0] = bit0 & bit1
        tbnz            w17, #0,  3f                    // skip if the two first bits of ll_mask are 1
        ldr             d0,        [x9],  #8
        ldr             d1,        [x11], #8
        lsl             w6,  w7,  #31                   // MSB of w6 = first bit of ll_mask
        ldr             d2,        [x13]
        asr             w6,  w6,  #31                   // extend first bit of ll_mask across w6
        ldr             d3,        [x15]
        lsl             x17, x7,  #62                   // MSB of x17 = second bit of ll_mask
        ld1             {v0.d}[1], [x10], #8
        orr             x6,  x6,  x17, asr #31          // x6: lower 32b = first bit of ll_mask, upper 32b = second bit of ll_mask
        ld1             {v1.d}[1], [x12], #8
        dup             v29.2d,   x6
        lsr             w7,  w7,  #2
        ld1             {v2.d}[1], [x14]
        ld1             {v3.d}[1], [x16]
        bic             v28.16b, v30.16b, v29.16b
        abs             v16.16b, v0.16b                 // abs(err)
        abs             v20.16b, v1.16b
        cmlt            v17.16b, v0.16b,  #0
        cmlt            v21.16b, v1.16b,  #0
        mul             v18.16b, v16.16b, v28.16b       // abs(diff) = abs(err) * scale
        mul             v22.16b, v20.16b, v28.16b
        urshr           v18.16b, v18.16b, #4            // (abs(diff) + rnd) >> shift
        urshr           v22.16b, v22.16b, #4
        uqsub           v19.16b, v2.16b,  v18.16b
        uqsub           v23.16b, v3.16b,  v22.16b
        uqadd           v2.16b,  v2.16b,  v18.16b
        uqadd           v3.16b,  v3.16b,  v22.16b
        bit             v2.16b,  v19.16b, v17.16b       // p[x] = iclip_pixel(p[x] + apply_sign((abs(diff) + rnd) >> shift, diff))
        bit             v3.16b,  v23.16b, v21.16b
        str             d2,        [x13], #8
        str             d3,        [x15], #8
        sub             w8,  w8,  #2                    // bx_max -= 2
        st1             {v2.d}[1], [x14], #8
        st1             {v3.d}[1], [x16], #8
        cbnz            w8,  2b
        b               4f
3:
        sub             w8,  w8,  #2
        add             x9,  x9,  #8
        add             x10, x10, #8
        add             x11, x11, #8
        add             x12, x12, #8
        add             x13, x13, #8
        add             x14, x14, #8
        add             x15, x15, #8
        add             x16, x16, #8
        lsr             w7,  w7,  #2
        cbnz            w8,  2b
4:
        sub             w5,  w5,  #4                    // by_max --
        add             x0,  x0,  x1,  lsl #2           // p_line += stride * 4
        add             x2,  x2,  #256                  // err_line += 64 * 4
        cbnz            w5,  1b
        ret
endfunc
