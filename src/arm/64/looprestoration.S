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

// static void gdf_add_c(pixel *p_line,
//                       const ptrdiff_t stride,
//                       const int8_t *err_line,
//                       const uint16_t (*const ll_mask)[4],
//                       const int w,
//                       const int h,
//                       const int scale)
function gdf_add_8bpc_neon, export=1
    dup             v6.16b,  w6                     // scale

1:  // by loop
    lsr             w8,  w4,   #2                   // bx_max
    ldrh            w7,  [x3], #8                   // ll_mask[by][0]
    mov             x9,  x2
    add             x10, x2,  #64
    add             x11, x2,  #128
    add             x12, x2,  #192
    mov             x13, x0
    add             x14, x0,  x1
    add             x15, x0,  x1, lsl #1
    add             x16, x14, x1, lsl #1

2:  // bx loop
    ldr             d0,        [x9],  #8
    ldr             d1,        [x11], #8
    ldr             d2,        [x13]
    ldr             d3,        [x15]
    ror             w7,  w7,  #2
    ld1             {v0.d}[1], [x10], #8
    ld1             {v1.d}[1], [x12], #8
    ld1             {v2.d}[1], [x14]
    ld1             {v3.d}[1], [x16]
    uzp1            v4.4s,   v0.4s,   v1.4s
    uzp2            v5.4s,   v0.4s,   v1.4s
    uzp1            v16.4s,  v2.4s,   v3.4s
    uzp2            v17.4s,  v2.4s,   v3.4s
    tbnz            w7,  #30, 3f
    abs             v18.16b, v4.16b
    cmlt            v19.16b, v4.16b,  #0
    mul             v20.16b, v18.16b, v6.16b
    urshr           v20.16b, v20.16b, #4            // (abs(diff) + rnd) >> shift
    uqsub           v21.16b, v16.16b, v20.16b
    uqadd           v16.16b, v16.16b, v20.16b
    bit             v16.16b, v21.16b, v19.16b       // p[x] = iclip_pixel(p[x] + apply_sign((abs(diff) + rnd) >> shift, diff))

3:
    tbnz            w7,  #31, 4f
    abs             v22.16b, v5.16b
    cmlt            v23.16b, v5.16b,  #0
    mul             v24.16b, v22.16b, v6.16b
    urshr           v24.16b, v24.16b, #4            // (abs(diff) + rnd) >> shift
    uqsub           v25.16b, v17.16b, v24.16b
    uqadd           v17.16b, v17.16b, v24.16b
    bit             v17.16b, v25.16b, v23.16b       // p[x] = iclip_pixel(p[x] + apply_sign((abs(diff) + rnd) >> shift, diff))

4:
    zip1            v0.4s,   v16.4s,  v17.4s
    zip2            v1.4s,   v16.4s,  v17.4s
    str             d0,  [x13], #8
    str             d1,  [x15], #8
    st1             {v0.d}[1], [x14], #8
    st1             {v1.d}[1], [x16], #8
    sub             w8,  w8,  #2                    // bx_max -= 2
    cbnz            w8,  2b
    sub             w5,  w5,  #4                    // by_max --
    add             x0,  x0,  x1, lsl #2            // p_line += stride * 4
    add             x2,  x2,  #256                  // err_line += 64 * 4
    cbnz            w5,  1b
    ret
endfunc
