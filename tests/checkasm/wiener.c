/*
 * Copyright © 2018, VideoLAN and dav2d authors
 * Copyright © 2018, Two Orioles, LLC
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

#include "tests/checkasm/internal.h"

#include <stdio.h>
#include <string.h>

#include "src/levels.h"
#include "src/looprestoration.h"
#include "src/tables.h"
#include "src/quantizer.h"
#include "src/wiener_tables.h"

static int to_binary(int x) { /* 0-63 -> 000000-111111 */
    return (x & 1) + 5 * (x & 2) + 25 * (x & 4) + 125 * (x & 8) +
        625 * (x & 16) + 3125 * (x & 32);
}

static void init_tmp(pixel *buf, const ptrdiff_t stride,
                     const int w, const int h, const int bitdepth_max)
{
    const int noise_mask = bitdepth_max >> 4;
    const int x_off = rnd() & 7, y_off = rnd() & 7;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            buf[x] = (((x + x_off) ^ (y + y_off)) & 8 ? bitdepth_max : 0) ^
                     (rnd() & noise_mask);
        }
        buf += PXSTRIDE(stride);
    }
}

static void init_filter(int8_t* filter, const int chroma) {
    const int8_t (*const range)[2] = chroma ? dav2d_ns_wiener_coef_range_uv :
                                              dav2d_ns_wiener_coef_range_y;
    int n_coeffs = 16 + 2 * !!chroma;
    int filter_type = rnd() % 3;

    switch (filter_type){
    case 0: // random
        for (int i = 0; i < n_coeffs; i++) {
            int min = range[i][1];
            int size = 1 << range[i][0];
            filter[i] = min + rnd() % size;
        }
        break;
    case 1: // pos max
        for (int i = 0; i < n_coeffs; i++) {
            int min = range[i][1];
            int size = 1 << range[i][0];
            filter[i] = min + size - 1;
        }
        break;
    case 2: // neg max
        for (int i = 0; i < n_coeffs; i++) {
            int min = range[i][1];
            filter[i] = min;
        }
        break;
    }
}

static void check_wiener_single(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    PIXEL_RECT(top, 64, 4);
    PIXEL_RECT(bottom, 64, 4);
    uint16_t ll_mask[64][4];
    pixel left[64][8];
    int8_t filter[16];
    WienerParams params;
    params.single.filter = filter;

    declare_func(void, pixel *dst, ptrdiff_t dst_stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom, int w, int h,
                 const WienerParams *params, enum LrEdgeFlags edges,
                 const uint16_t (*ll_mask)[4] HIGHBD_DECL_SUFFIX);

    if (check_func(c->ns_wiener_single, "wiener_single_%dbpc", BITDEPTH)) {
        const int base_w = 8 * (1 + (rnd() & 7));
        const int base_h = 8 * (1 + (rnd() & 7));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;
        init_filter(filter, 0);

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 6, c_dst_stride, 64 + 12, 64, bitdepth_max);
        init_tmp(top - 6, top_stride, 64 + 12, 8, bitdepth_max);
        init_tmp(bottom - 6, bottom_stride, 64 + 12, 8, bitdepth_max);
        init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if ((edges & LR_HAVE_TOP && edges & LR_HAVE_TOP_INTEGRATED) ||
                (edges & LR_HAVE_BOTTOM && edges & LR_HAVE_BOTTOM_INTEGRATED))
            {
                continue;
            }

            for (int i = 0; i < 64; i++)
                ll_mask[i][0] = rnd() & 0xffff;

            const int w = edges & LR_HAVE_RIGHT ? 64 : base_w;
            const int h =
                (edges & (LR_HAVE_BOTTOM | LR_HAVE_BOTTOM_INTEGRATED)) ?
                    64 : base_h;

            assert(c_dst_stride == a_dst_stride);
            assert(c_dst_buf_h == a_dst_buf_h);
            memcpy(a_dst_buf, c_dst_buf, a_dst_stride * a_dst_buf_h);

            assert(c_dst_stride == top_stride);
            assert(c_dst_stride == bottom_stride);
            call_ref(c_dst, c_dst_stride, left, top, bottom,
                     w, h, &params, edges, ll_mask HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom,
                     w, h, &params, edges, ll_mask HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %04d\n",
                        w, h, to_binary(edges));
                break;
            }
        }

        // lossless speeds up the reference code
        for (int i = 0; i < 64; i++)
            ll_mask[i][0] = 0;
        bench_new(alternate(c_dst, a_dst), a_dst_stride, left, top, bottom,
                  64, 64, &params, 0xf, ll_mask HIGHBD_TAIL_SUFFIX);
    }
}

static void check_wiener_multi(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    PIXEL_RECT(top, 64, 4);
    PIXEL_RECT(bottom, 64, 4);
    uint16_t ll_mask[64][4];
    uint16_t noskip_mask[64];
    pixel left[64][8];
    int8_t filters[16][16];
    WienerParams params;
    WienerQValApproxData qval_approx;
    params.multi.filters.user = filters;
    params.multi.noskip_mask = noskip_mask;
    params.multi.qval_approx = &qval_approx;

    declare_func(void, pixel *dst, ptrdiff_t dst_stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom, int w, int h,
                 const WienerParams *params, enum LrEdgeFlags edges,
                 const uint16_t (*ll_mask)[4] HIGHBD_DECL_SUFFIX);

    if (check_func(c->ns_wiener_multi, "wiener_multi_user_%dbpc", BITDEPTH)) {
        const int base_w = 8 * (1 + (rnd() & 7));
        const int base_h = 8 * (1 + (rnd() & 7));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 6, c_dst_stride, 64 + 12, 64, bitdepth_max);
        init_tmp(top - 6, top_stride, 64 + 12, 8, bitdepth_max);
        init_tmp(bottom - 6, bottom_stride, 64 + 12, 8, bitdepth_max);
        init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if ((edges & LR_HAVE_TOP && edges & LR_HAVE_TOP_INTEGRATED) ||
                (edges & LR_HAVE_BOTTOM && edges & LR_HAVE_BOTTOM_INTEGRATED))
            {
                continue;
            }

            for (int i = 0; i < 16; i++)
                init_filter(filters[i], 0);

            for (int i = 0; i < 64; i++) {
                ll_mask[i][0] = rnd() & 0xffff;
                noskip_mask[i] = rnd() & 0xffff;
            }

            const int num_classes = 1 + rnd() % 7;
            const int qidx = rnd() % (256 + 24 * (bpc - 8));
            int idx = 3;
            if (qidx < 130) {
                idx = 0;
            } else if (qidx < 190) {
                idx = 1;
            } else if (qidx < 220) {
                idx = 2;
            }
            int base_q = dav2d_dq_lookup(qidx);
            int qstep = (base_q + (1 << (bpc - 8) >> 1)) >> (bpc - 8);

            ptrdiff_t lut_offset = 0;
            setup_wiener_qval_approx_data(&qval_approx, &lut_offset, qstep);
            params.multi.class_lut = dav2d_user_wiener_class[idx][num_classes - 1] +
                                     lut_offset;

            const int w = edges & LR_HAVE_RIGHT ? 64 : base_w;
            const int h =
                (edges & (LR_HAVE_BOTTOM | LR_HAVE_BOTTOM_INTEGRATED)) ?
                    64 : base_h;

            assert(c_dst_stride == a_dst_stride);
            assert(c_dst_buf_h == a_dst_buf_h);
            memcpy(a_dst_buf, c_dst_buf, a_dst_stride * a_dst_buf_h);

            assert(c_dst_stride == top_stride);
            assert(c_dst_stride == bottom_stride);
            call_ref(c_dst, c_dst_stride, left, top, bottom,
                     w, h, &params, edges, ll_mask HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom,
                     w, h, &params, edges, ll_mask HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
                break;
            }
            if (edges == 0xf) {
                for (int i = 0; i < 64; i++)
                    ll_mask[i][0] = 0;
                bench_new(alternate(c_dst, a_dst), a_dst_stride, left,
                          top, bottom, 64, 64, &params, 0xf, ll_mask
                          HIGHBD_TAIL_SUFFIX);
            }
        }
    }
}

static void check_wiener_pretrained(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    PIXEL_RECT(top, 64, 4);
    PIXEL_RECT(bottom, 64, 4);
    uint16_t ll_mask[64][4];
    uint16_t noskip_mask[64];
    pixel left[64][8];
    WienerParams params;
    WienerQValApproxData qval_approx;
    params.multi.noskip_mask = noskip_mask;
    params.multi.qval_approx = &qval_approx;

    declare_func(void, pixel *dst, ptrdiff_t dst_stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom, int w, int h,
                 const WienerParams *params, enum LrEdgeFlags edges,
                 const uint16_t (*ll_mask)[4] HIGHBD_DECL_SUFFIX);

    if (check_func(c->pc_wiener, "wiener_multi_pretrained_%dbpc", BITDEPTH)) {
        const int base_w = 8 * (1 + (rnd() & 7));
        const int base_h = 8 * (1 + (rnd() & 7));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 6, c_dst_stride, 64 + 12, 64, bitdepth_max);
        init_tmp(top - 6, top_stride, 64 + 12, 8, bitdepth_max);
        init_tmp(bottom - 6, bottom_stride, 64 + 12, 8, bitdepth_max);
        init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if ((edges & LR_HAVE_TOP && edges & LR_HAVE_TOP_INTEGRATED) ||
                (edges & LR_HAVE_BOTTOM && edges & LR_HAVE_BOTTOM_INTEGRATED))
            {
                continue;
            }

            for (int i = 0; i < 64; i++) {
                ll_mask[i][0] = rnd() & 0xffff;
                noskip_mask[i] = rnd() & 0xffff;
            }

            const int qidx = rnd() % (256 + 24 * (bpc - 8));
            const int idx = rnd() & 3;
            const int base_q = dav2d_dq_lookup(qidx);
            const int qstep = (base_q + (1 << (bpc - 8) >> 1)) >> (bpc - 8);

            ptrdiff_t lut_offset = 0;
            setup_wiener_qval_approx_data(&qval_approx, &lut_offset, qstep);

            params.multi.class_lut = dav2d_pretrained_wiener_class[idx] +
                                     lut_offset;
            params.multi.filters.pretrained = dav2d_pc_wiener_filters[idx];

            const int w = edges & LR_HAVE_RIGHT ? 64 : base_w;
            const int h =
                (edges & (LR_HAVE_BOTTOM | LR_HAVE_BOTTOM_INTEGRATED)) ?
                    64 : base_h;

            assert(c_dst_stride == a_dst_stride);
            assert(c_dst_buf_h == a_dst_buf_h);
            memcpy(a_dst_buf, c_dst_buf, a_dst_stride * a_dst_buf_h);

            assert(c_dst_stride == top_stride);
            assert(c_dst_stride == bottom_stride);
            call_ref(c_dst, c_dst_stride, left, top, bottom,
                     w, h, &params, edges, ll_mask HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom,
                     w, h, &params, edges, ll_mask HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
                break;
            }
            if (edges == 0xf) {
                for (int i = 0; i < 64; i++)
                    ll_mask[i][0] = 0;
                bench_new(alternate(c_dst, a_dst), a_dst_stride, left,
                          top, bottom, 64, 64, &params, 0xf, ll_mask
                          HIGHBD_TAIL_SUFFIX);
            }
        }
    }
}

void bitfn(checkasm_check_wiener)(void) {
    Dav2dLoopRestorationDSPContext c;
    bitfn(dav2d_loop_restoration_dsp_init)(&c);

    dav2d_init_wiener_classes();
    check_wiener_single(&c);
    check_wiener_multi(&c);
    check_wiener_pretrained(&c);
    report("wiener");
}
