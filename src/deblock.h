/*
 * Copyright © 2018-2026, VideoLAN and dav2d authors
 * Copyright © 2018-2026, Two Orioles, LLC
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

#ifndef DAV2D_SRC_DEBLOCK_H
#define DAV2D_SRC_DEBLOCK_H

#include <stdint.h>
#include <stddef.h>

#include "common/bitdepth.h"

#include "src/levels.h"

#define decl_deblock_sb_fn(name) \
void (name)(pixel *dst, ptrdiff_t stride, const uint16_t *mask, \
            const uint16_t *ll_mask, \
            const pixel *q_thr, const pixel *side_thr, int edge, \
            int w HIGHBD_DECL_SUFFIX)
typedef decl_deblock_sb_fn(*deblock_sb_fn);

/*
 * For _seg and _dq, the "prev" arugment should be considered "const"
 * for the rows variant. For the cols variant, it'll be filled with
 * the right-most values in the current block to serve as left edge
 * in subsequent calls.
 */
#define decl_setup_thr_sb_seg_fn(name) \
void (name)(pixel (*dst_thr)[16 * 16], const uint8_t *seg_map, \
            ptrdiff_t seg_stride, const uint16_t (*mask)[5][4], \
            const pixel (*lut)[16], pixel (*prev)[16], int w4, int h4)
typedef decl_setup_thr_sb_seg_fn(*setup_thr_sb_seg_fn);

#define decl_setup_thr_sb_dq_fn(name) \
void (name)(pixel (*dst_thr)[16 * 16], const uint16_t (*mask)[5][4], \
            const pixel (*lut)[16], pixel (*prev)[16], int w4, int h4)
typedef decl_setup_thr_sb_dq_fn(*setup_thr_sb_dq_fn);

#define decl_setup_thr_sb_simple_fn(name) \
void (name)(pixel (*dst_thr)[16 * 16], const uint16_t (*mask)[5][4], \
            const pixel (*lut)[16], int w4, int h4)
typedef decl_setup_thr_sb_simple_fn(*setup_thr_sb_simple_fn);

typedef struct Dav2dDeblockDSPContext {
    /*
     * dimension 1: plane (0=luma, 1=chroma)
     * dimension 2: 0=col-edge filter (h), 1=row-edge filter (v)
     *
     * dst/stride are aligned by 32
     */
    deblock_sb_fn deblock_sb[2][2];
    /*
     * threshold generation
     * 0=col-edge filter (h), 1=row-edge filter (v)
     */
    setup_thr_sb_seg_fn setup_thr_sb_seg[2];
    setup_thr_sb_dq_fn setup_thr_sb_dq[2];
    setup_thr_sb_simple_fn setup_thr_sb_simple[2];
} Dav2dDeblockDSPContext;

bitfn_decls(void dav2d_deblock_dsp_init, Dav2dDeblockDSPContext *c);

#endif /* DAV2D_SRC_DEBLOCK_H */
