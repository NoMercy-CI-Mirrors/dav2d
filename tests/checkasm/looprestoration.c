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

static int is_edge_combination_valid(const enum LrEdgeFlags edges) {
    if ((edges & LR_HAVE_TOP) && (edges & LR_HAVE_TOP_INTEGRATED))
        return 0;
    if ((edges & LR_HAVE_BOTTOM) && (edges & LR_HAVE_BOTTOM_INTEGRATED))
        return 0;
    return 1;
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

static const char ss_name[][4] = {
    [DAV2D_PIXEL_LAYOUT_I420 - 1] = "420",
    [DAV2D_PIXEL_LAYOUT_I422 - 1] = "422",
    [DAV2D_PIXEL_LAYOUT_I444 - 1] = "444",
};

static void check_wiener_uv_luma(Dav2dLoopRestorationDSPContext *const c,
                                 int layout_idx)
{
    ALIGN_STK_64(coef, c_dst, 64 * 64, );
    ALIGN_STK_64(coef, a_dst, 64 * 64, );
    PIXEL_RECT(luma, 128, 64);
    PIXEL_RECT(top, 128, 6);
    PIXEL_RECT(bottom, 128, 4);
    ALIGN_STK_16(pixel, left[64], 8, );
    int8_t filter[18];
    const enum Dav2dPixelLayout layout = layout_idx + 1;
    const int ss_hor = layout != DAV2D_PIXEL_LAYOUT_I444;
    const int ss_ver = layout == DAV2D_PIXEL_LAYOUT_I420;

    declare_func(void, coef *dst, const pixel *luma, const ptrdiff_t stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom,
                 const int8_t *filter, int w, int h, int ds_flt,
                 enum LrEdgeFlags edges);

    if (check_func(c->wiener_uv_luma[DAV2D_PIXEL_LAYOUT_I444 - layout],
                   "wiener_uv_luma_%s_%dbpc", ss_name[layout_idx], BITDEPTH))
    {
        // ds_flt does nothing for 422/444
        int max_ds_flt = layout == DAV2D_PIXEL_LAYOUT_I420 ? 2 : 0;
        for (int ds_flt = 0; ds_flt <= max_ds_flt; ds_flt++) {
            const int base_w = (8 >> ss_hor) * (1 + (rnd() & 7));
            const int base_h = (8 >> ss_ver) * (1 + (rnd() & 7));
            const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
            const int bitdepth_max = (1 << bpc) - 1;
            init_filter(filter, 1);

            init_tmp(luma - 4, luma_stride, 128 + 8, 64 + 4, bitdepth_max);
            init_tmp(top + (6 - (2 << ss_ver)) * top_stride - 4, top_stride,
                     128 + 8, (2 * ss_ver), bitdepth_max);
            init_tmp(bottom - 4, bottom_stride, 128 + 8, 4, bitdepth_max);
            init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

            for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
                if (!is_edge_combination_valid(edges))
                    continue;

                const int w = edges & LR_HAVE_RIGHT ? 64 >> ss_hor : base_w;
                const int h =
                    (edges & (LR_HAVE_BOTTOM | LR_HAVE_BOTTOM_INTEGRATED)) ?
                        64 >> ss_ver : base_h;

                assert(luma_stride == top_stride);
                assert(luma_stride == bottom_stride);
                call_ref(c_dst, luma, luma_stride, left, top, bottom, filter,
                         w, h, ds_flt, edges);
                call_new(a_dst, luma, luma_stride, left, top, bottom, filter,
                         w, h, ds_flt, edges);
                if (checkasm_check_coef(c_dst, 64 * sizeof(*c_dst),
                                        a_dst, 64 * sizeof(*a_dst),
                                        w, h, "dst"))
                {
                    fprintf(stderr, "size = %dx%d, edges = %06d, dst_flt = %d\n",
                            w, h, to_binary(edges), ds_flt);
                }
            }

            bench_new(alternate(c_dst, a_dst), luma, luma_stride, left, top,
                      bottom, filter, 64 >> ss_hor, 64 >> ss_ver, 0, 0xf);
        }
    }
}

static void check_wiener_uv_chroma(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    ALIGN_STK_64(coef, luma, 64 * 64, );
    PIXEL_RECT(top, 64, 4);
    PIXEL_RECT(bottom, 64, 4);
    ALIGN_STK_16(pixel, left[64], 2, );
    uint16_t ll_mask[64][4];
    int8_t filter[18];

    declare_func(void, pixel *p, const ptrdiff_t stride,
                 const pixel (*const left)[2],
                 const pixel *top, const pixel *bottom, const coef *luma,
                 const int8_t *filter, const uint16_t (*ll_mask)[4],
                 int w, int h, enum LrEdgeFlags edges HIGHBD_DECL_SUFFIX);

    if (check_func(c->wiener_uv_chroma, "wiener_uv_chroma_%dbpc", BITDEPTH)) {
        const int base_w = 4 * (1 + (rnd() & 15));
        const int base_h = 4 * (1 + (rnd() & 15));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;
        const int luma_max = bitdepth_max << 7;
        init_filter(filter, 1);

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 4, c_dst_stride, 64 + 8, 64 + 4, bitdepth_max);
        init_tmp(top - 4, top_stride, 64 + 8, 4, bitdepth_max);
        init_tmp(bottom - 4, bottom_stride, 64 + 8, 4, bitdepth_max);
        init_tmp((pixel *) left, 2 * sizeof(pixel), 2, 64, bitdepth_max);
        for (int i = 0; i < 64 * 64; i++)
            luma[i] = rnd() % (luma_max << 1) - luma_max;

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if (!is_edge_combination_valid(edges))
                continue;

            for (int i = 0; i < 64; i++)
                ll_mask[i][0] = rnd() & 0xffff;

            const int w = edges & LR_HAVE_RIGHT ? 64 >> (rnd() & 1) : base_w;
            const int h =
                (edges & (LR_HAVE_BOTTOM | LR_HAVE_BOTTOM_INTEGRATED)) ?
                    64 >> (rnd() & 1) : base_h;

            assert(c_dst_stride == a_dst_stride);
            assert(c_dst_buf_h == a_dst_buf_h);
            memcpy(a_dst_buf, c_dst_buf, a_dst_stride * a_dst_buf_h);

            assert(c_dst_stride == top_stride);
            assert(c_dst_stride == bottom_stride);
            call_ref(c_dst, c_dst_stride, left, top, bottom, luma, filter, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom, luma, filter, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
            }
        }

        memset(ll_mask, 0, sizeof(ll_mask));
        bench_new(alternate(c_dst, a_dst), a_dst_stride, left, top, bottom, luma, filter, ll_mask,
                  32, 32, 0xf HIGHBD_TAIL_SUFFIX);
    }
}

static void check_wiener_single(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    PIXEL_RECT(top, 64, 6);
    PIXEL_RECT(bottom, 64, 4);
    uint16_t ll_mask[64][4];
    ALIGN_STK_16(pixel, left[64], 8, );
    int8_t filter[16];
    WienerParams params;
    params.single.filter = filter;

    declare_func(void, pixel *dst, ptrdiff_t dst_stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom,
                 const WienerParams *params,
                 const uint16_t (*ll_mask)[4],
                 int w, int h, enum LrEdgeFlags edges
                 HIGHBD_DECL_SUFFIX);

    if (check_func(c->ns_wiener_single, "wiener_single_%dbpc", BITDEPTH)) {
        const int base_w = 8 * (1 + (rnd() & 7));
        const int base_h = 8 * (1 + (rnd() & 7));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;
        init_filter(filter, 0);

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 4, c_dst_stride, 64 + 8, 64 + 4, bitdepth_max);
        init_tmp(top + 2 * top_stride - 4, top_stride, 64 + 8, 4, bitdepth_max);
        init_tmp(bottom - 4, bottom_stride, 64 + 8, 4, bitdepth_max);
        init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if (!is_edge_combination_valid(edges))
                continue;

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
            call_ref(c_dst, c_dst_stride, left, top, bottom, &params, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom, &params, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
                break;
            }
        }

        // lossless speeds up the reference code
        memset(ll_mask, 0, sizeof(ll_mask));
        bench_new(alternate(c_dst, a_dst), a_dst_stride, left,
                  top, bottom, &params, ll_mask, 64, 64, 0xf
                  HIGHBD_TAIL_SUFFIX);
    }
}

static void check_wiener_multi(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    PIXEL_RECT(top, 64, 6);
    PIXEL_RECT(bottom, 64, 4);
    uint16_t ll_mask[64][4];
    uint16_t noskip_mask[64];
    ALIGN_STK_16(pixel, left[64], 8, );
    int8_t filters[16][16];
    WienerParams params;
    WienerQValApproxData qval_approx;
    params.multi.filters.user = filters;
    params.multi.noskip_mask = noskip_mask;
    params.multi.qval_approx = &qval_approx;

    declare_func(void, pixel *dst, ptrdiff_t dst_stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom,
                 const WienerParams *params,
                 const uint16_t (*ll_mask)[4],
                 int w, int h, enum LrEdgeFlags edges
                 HIGHBD_DECL_SUFFIX);

    if (check_func(c->ns_wiener_multi, "wiener_multi_user_%dbpc", BITDEPTH)) {
        const int base_w = 8 * (1 + (rnd() & 7));
        const int base_h = 8 * (1 + (rnd() & 7));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 4, c_dst_stride, 64 + 8, 64 + 4, bitdepth_max);
        init_tmp(top + 2 * top_stride - 4, top_stride, 64 + 8, 4, bitdepth_max);
        init_tmp(bottom - 4, bottom_stride, 64 + 8, 4, bitdepth_max);
        init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if (!is_edge_combination_valid(edges))
                continue;

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
            call_ref(c_dst, c_dst_stride, left, top, bottom, &params, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom, &params, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
                break;
            }
        }
        memset(ll_mask, 0, sizeof(ll_mask));
        bench_new(alternate(c_dst, a_dst), a_dst_stride, left,
                  top, bottom, &params, ll_mask, 64, 64, 0xf
                  HIGHBD_TAIL_SUFFIX);
    }
}

static void check_wiener_pretrained(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    PIXEL_RECT(top, 64, 4);
    PIXEL_RECT(bottom, 64, 4);
    uint16_t ll_mask[64][4];
    uint16_t noskip_mask[64];
    ALIGN_STK_16(pixel, left[64], 8, );
    WienerParams params;
    WienerQValApproxData qval_approx;
    params.multi.noskip_mask = noskip_mask;
    params.multi.qval_approx = &qval_approx;

    declare_func(void, pixel *dst, ptrdiff_t dst_stride,
                 const pixel (*const left)[8],
                 const pixel *top, const pixel *bottom,
                 const WienerParams *params,
                 const uint16_t (*ll_mask)[4],
                 int w, int h, enum LrEdgeFlags edges
                 HIGHBD_DECL_SUFFIX);

    if (check_func(c->pc_wiener, "wiener_multi_pretrained_%dbpc", BITDEPTH)) {
        const int base_w = 8 * (1 + (rnd() & 7));
        const int base_h = 8 * (1 + (rnd() & 7));
        const int bpc = BITDEPTH == 8 ? 8 : 10 + (rnd() & 2);
        const int bitdepth_max = (1 << bpc) - 1;

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst - 4, c_dst_stride, 64 + 8, 64 + 4, bitdepth_max);
        init_tmp(top - 4, top_stride, 64 + 8, 4, bitdepth_max);
        init_tmp(bottom - 4, bottom_stride, 64 + 8, 4, bitdepth_max);
        init_tmp((pixel *) left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if (!is_edge_combination_valid(edges))
                continue;

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
            call_ref(c_dst, c_dst_stride, left, top, bottom, &params, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, a_dst_stride, left, top, bottom, &params, ll_mask,
                     w, h, edges HIGHBD_TAIL_SUFFIX);
            if (checkasm_check_pixel_padded_align(c_dst, c_dst_stride,
                                                  a_dst, a_dst_stride,
                                                  w, h, "dst", 64, 1))
            {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
                break;
            }
            memset(ll_mask, 0, sizeof(ll_mask));
            bench_new(alternate(c_dst, a_dst), a_dst_stride, left,
                      top, bottom, &params, ll_mask, 64, 64, 0xf
                      HIGHBD_TAIL_SUFFIX);
        }
    }
}

static void check_gdf_prep(Dav2dLoopRestorationDSPContext *const c) {
    ALIGN_STK_64(int8_t, c_dst, 64 * 64,);
    ALIGN_STK_64(int8_t, a_dst, 64 * 64,);
    ALIGN_STK_64(pixel, left, 64, [8]);
    PIXEL_RECT(p, 64, 64);
    PIXEL_RECT(top, 64, 6);
    PIXEL_RECT(bottom, 64, 6);
    const Dav2dGdfParams *params;

    declare_func(void, int8_t *dst, const pixel *p, ptrdiff_t stride,
                 const pixel (*left)[8], const pixel *lpf,
                 const pixel *lpf_bottom, const Dav2dGdfParams *params,
                 int w, int h, enum LrEdgeFlags edges HIGHBD_DECL_SUFFIX);

    if (check_func(c->gdf_prep, "gdf_prep_%dbpc", BITDEPTH)) {
#if BITDEPTH == 16
        const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
        const int bitdepth_max = 0xff;
#endif
        const int base_w = (1 + (rnd() & 7)) * 8;
        const int base_h = (1 + (rnd() & 7)) * 8;

        init_tmp(p - 6, p_stride, 64 + 12, 64 + 6, bitdepth_max);
        init_tmp(top - 6, top_stride, 64 + 12, 6, bitdepth_max);
        init_tmp(bottom - 6, bottom_stride, 64 + 12, 6, bitdepth_max);
        init_tmp(*left, 8 * sizeof(pixel), 8, 64, bitdepth_max);

        for (enum LrEdgeFlags edges = 0; edges <= 0x3f; edges++) {
            if (!is_edge_combination_valid(edges))
                continue;

            const int w = edges & LR_HAVE_RIGHT ? 64 : base_w;
            const int h = (edges & (LR_HAVE_BOTTOM | LR_HAVE_BOTTOM_INTEGRATED)) ?
                          64 : base_h;
            const int ref_dst_idx = rnd() % 6;
            const int qp_idx = rnd() % 6;
            params = ref_dst_idx ? &dav2d_gdf_inter_params[ref_dst_idx - 1][qp_idx].p
                                 : &dav2d_gdf_intra_params[qp_idx].p;

            memset(c_dst, 0xaa, 64 * 64);
            memset(a_dst, 0xaa, 64 * 64);

            call_ref(c_dst, p, p_stride, left, top, bottom,
                     params, w, h, edges HIGHBD_TAIL_SUFFIX);
            call_new(a_dst, p, p_stride, left, top, bottom,
                     params, w, h, edges HIGHBD_TAIL_SUFFIX);
            if (checkasm_check(int8_t, c_dst, 64, a_dst, 64, w, h, "dst")) {
                fprintf(stderr, "size = %dx%d, edges = %06d\n",
                        w, h, to_binary(edges));
                break;
            }
        }

        bench_new(a_dst, p, p_stride, left, top, bottom,
                  params, 64, 64, 0xf HIGHBD_TAIL_SUFFIX);
    }
}

static void check_gdf_add(Dav2dLoopRestorationDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    ALIGN_STK_64(int8_t, err, 64 * 64,);
    uint16_t ll_mask[16][4];

    declare_func(void, pixel *p, ptrdiff_t p_stride,
                 const int8_t *err, const uint16_t (*ll_mask)[4],
                 int w, int h, int scale HIGHBD_DECL_SUFFIX);

    if (check_func(c->gdf_add, "gdf_add_%dbpc", BITDEPTH)) {
#if BITDEPTH == 16
        const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
        const int bitdepth_max = 0xff;
#endif
        const int w = (1 + (rnd() & 7)) * 8;
        const int h = (1 + (rnd() & 7)) * 8;
        const int scale = 1 + (rnd() & 3);

        CLEAR_PIXEL_RECT(c_dst);
        init_tmp(c_dst, c_dst_stride, 64, 64, bitdepth_max);
        memcpy(a_dst_buf, c_dst_buf, a_dst_stride * a_dst_buf_h);

        for (int i = 0; i < 64 * 64; i++)
            err[i] = (rnd() % 96) - 53; // -53..42

        for (int i = 0; i < 16; i++)
            for (int j = 0; j < 4; j++)
                ll_mask[i][j] = rnd() & 0xffff;

        call_ref(c_dst, c_dst_stride, err, ll_mask, w, h, scale HIGHBD_TAIL_SUFFIX);
        call_new(a_dst, a_dst_stride, err, ll_mask, w, h, scale HIGHBD_TAIL_SUFFIX);
        checkasm_check_pixel_padded_align(c_dst, c_dst_stride, a_dst, a_dst_stride,
                                          w, h, "dst", 64, 8);

        memset(ll_mask, 0, sizeof(ll_mask));
        bench_new(alternate(c_dst, a_dst), c_dst_stride, err,
                  ll_mask, 64, 64, scale HIGHBD_TAIL_SUFFIX);
    }
}

void bitfn(checkasm_check_looprestoration)(void) {
    Dav2dLoopRestorationDSPContext c;
    bitfn(dav2d_loop_restoration_dsp_init)(&c);

    dav2d_init_wiener_classes();
    check_wiener_single(&c);
    check_wiener_multi(&c);
    check_wiener_pretrained(&c);
    for (int layout_idx = 0; layout_idx < 3; layout_idx++)
        check_wiener_uv_luma(&c, layout_idx);
    check_wiener_uv_chroma(&c);
    report("wiener");

    check_gdf_prep(&c);
    check_gdf_add(&c);
    report("gdf");
}
