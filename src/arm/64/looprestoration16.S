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

// void gdf_add_16bpc_neon(pixel *p_line, const ptrdiff_t stride,
//                         const int8_t *err_line, const uint16_t (*const ll_mask)[4],
//                         const int w, const int h, const int scale, int bitdepth_max)
function gdf_add_16bpc_neon, export=1
        dup             v31.8h,   w7                    // bitdepth_max
        lsl             x12, x1,  #1                    // stride line 2
        sub             w7,  w7,  #0x3ff                // 10bpc or 12bpc path
        dup             v30.8b,   w6                    // scale
        add             x13, x1,  x12                   // stride line 3

1:      // by loop
        ldrh            w16, [x3], #8                   // ll_mask[by][0]
        lsr             w8,  w4,   #2                   // bx_max
        mov             x9,  x2
        mov             x10, x0

2:      // bx loop
        and             w17, w16, w16, lsr #1           // w17[0] = bit0 & bit1
        tbnz            w17, #0, 4f                     // skip if the two first bits of ll_mask are 1
        ldr             d1,  [x9, #64]
        ldr             d2,  [x9, #128]
        lsl             w14, w16, #31                   // MSB of w14 = first bit of ll_mask
        ldr             d3,  [x9, #192]
        asr             w14, w14, #31                   // extend first bit of ll_mask across w14
        ldr             d0,  [x9],#8
        lsl             x15, x16, #62                   // MSB of x15 = second bit of ll_mask
        ldr             q4,  [x10]
        orr             x14, x14, x15, asr #31          // x14: lower 32b = first bit of ll_mask, upper 32b = second bit of ll_mask
        ldr             q5,  [x10, x1]
        fmov            d29, x14
        lsr             w16,  w16,  #2
        ldr             q6,  [x10, x12]
        ldr             q7,  [x10, x13]
        bic             v28.8b,  v30.8b,  v29.8b
        smull           v16.8h,  v0.8b,   v28.8b        // diff = err*scale
        smull           v17.8h,  v1.8b,   v28.8b
        smull           v18.8h,  v2.8b,   v28.8b
        smull           v19.8h,  v3.8b,   v28.8b
        cbnz            w7, 3f                          // for 12 bpc : shift = 0 => apply_sign((abs(diff) + rnd) >> shift, diff) = diff
        cmlt            v20.8b,  v0.8b,   #0
        cmlt            v21.8b,  v1.8b,   #0
        cmlt            v22.8b,  v2.8b,   #0
        cmlt            v23.8b,  v3.8b,   #0
        saddw           v16.8h,  v16.8h,  v20.8b
        saddw           v17.8h,  v17.8h,  v21.8b
        saddw           v18.8h,  v18.8h,  v22.8b
        saddw           v19.8h,  v19.8h,  v23.8b
        srshr           v16.8h,  v16.8h,  #2            // apply_sign((abs(diff) + rnd) >> shift, diff)
        srshr           v17.8h,  v17.8h,  #2
        srshr           v18.8h,  v18.8h,  #2
        srshr           v19.8h,  v19.8h,  #2
3:
        usqadd          v4.8h,   v16.8h                 // p[x] = p[x] + apply_sign(...)
        usqadd          v5.8h,   v17.8h
        usqadd          v6.8h,   v18.8h
        usqadd          v7.8h,   v19.8h
        umin            v4.8h,   v4.8h,   v31.8h        // iclip_pixel
        umin            v5.8h,   v5.8h,   v31.8h
        umin            v6.8h,   v6.8h,   v31.8h
        umin            v7.8h,   v7.8h,   v31.8h
        sub             w8,  w8,  #2                    // bx_max -= 2
        str             q5,  [x10, x1]
        str             q6,  [x10, x12]
        str             q7,  [x10, x13]
        str             q4,  [x10], #16
        cbnz            w8,  2b
        b               5f
4:
        sub             w8,  w8,  #2
        add             x9,  x9,  #8
        add             x10, x10, #16
        lsr             w16, w16, #2
        cbnz            w8,  2b
5:
        sub             w5,  w5,  #4                    // by_max --
        add             x0,  x0,  x1,  lsl #2           // p_line += stride * 4
        add             x2,  x2,  #256                  // err_line += 64 * 4
        cbnz            w5,  1b
        ret
endfunc
