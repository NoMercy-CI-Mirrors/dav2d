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

#include "tests/checkasm/internal.h"

#include <stdio.h>
#include <string.h>

#include "src/ccso.h"
#include "src/tables.h"

static int get_rnd_width(const int ss_hor, const int edges)
{
    return edges & CDEF_HAVE_RIGHT ? 64 >> ss_hor :
                                     (1 + (rnd() & 7)) * (8 >> ss_hor);
}

static int get_rnd_bitdepth_max(void)
{
#if BITDEPTH == 16
    return rnd() & 1 ? 0x3ff : 0xfff;
#else
    return 0xff;
#endif
}

static void init_pixels(pixel *const buf, const int n, const int bitdepth_max)
{
    for (int i = 0; i < n; ++i)
        buf[i] = rnd() & bitdepth_max;
}

static void init_prep_buffers(pixel *const src_buf, pixel *const top_buf,
                              pixel *const bot_buf, pixel (*left)[2],
                              const int bitdepth_max)
{
    // Need (+2)x2 to accommodate CDEF_HAVE_LEFT and CDEF_HAVE_RIGHT padding,
    // rounded up to 64x2 to maintain alignment.
    init_pixels(src_buf, 8 * 64 + 128, bitdepth_max);
    init_pixels(top_buf, 2 * 64 + 128, bitdepth_max);
    init_pixels(bot_buf, 2 * 64 + 128, bitdepth_max);
    init_pixels(&left[0][0], 8 * 2, bitdepth_max);
}

static void check_ccso_prep_bo(const ccso_prep_bo_fn fn, const int ss_hor,
                               const int ss_ver, const char *name)
{
    const int h = 8 >> ss_ver;

    ALIGN_STK_64(uint8_t, c_dst, 8 * 64,);
    ALIGN_STK_64(uint8_t, a_dst, 8 * 64,);
    ALIGN_STK_64(pixel, src_buf, 8 * 64,);

    declare_func(void, uint8_t *dst, ptrdiff_t dst_stride, const pixel *src,
                 ptrdiff_t src_stride, unsigned max_band_log2, int w, int h
                 HIGHBD_DECL_SUFFIX);

    const ptrdiff_t src_stride = 64 * sizeof(pixel);
    const ptrdiff_t dst_stride = 64;
    pixel *const src = src_buf;

    if (!check_func(fn, "ccso_prep_%s_bo_%dbpc", name, BITDEPTH))
        return;

    for (unsigned max_band_log2 = 0; max_band_log2 <= 7; max_band_log2++) {
        const int w = get_rnd_width(ss_hor, 0xf);
        const int bitdepth_max = get_rnd_bitdepth_max();
        init_pixels(src_buf, 8 * 64, bitdepth_max);

        memset(c_dst, 0x88, sizeof(c_dst));
        memset(a_dst, 0x88, sizeof(a_dst));

        call_ref(c_dst, dst_stride, src, src_stride, max_band_log2, w, h
                 HIGHBD_TAIL_SUFFIX);
        call_new(a_dst, dst_stride, src, src_stride, max_band_log2, w, h
                 HIGHBD_TAIL_SUFFIX);
        if (checkasm_check(uint8_t, c_dst, dst_stride, a_dst, dst_stride, w, h,
                           "dst"))
        {
            fprintf(stderr, "name=%s w=%d h=%d max_band_log2=%u\n", name, w, h,
                    max_band_log2);
            return;
        }
    }

    const int w = get_rnd_width(ss_hor, 0xf);
    const int bitdepth_max = get_rnd_bitdepth_max();
    init_pixels(src_buf, 8 * 64, bitdepth_max);
    bench_new(a_dst, dst_stride, src, src_stride, 7, w, h HIGHBD_TAIL_SUFFIX);
}

static void check_ccso_prep_clf(const ccso_prep_clf_fn fn, const int ss_hor,
                                const int ss_ver, const char *name)
{
    const int h = 8 >> ss_ver;

    ALIGN_STK_64(uint8_t, c_dst, 8 * 64,);
    ALIGN_STK_64(uint8_t, a_dst, 8 * 64,);

    // Need (+2)x2 to accommodate CDEF_HAVE_LEFT and CDEF_HAVE_RIGHT padding,
    // rounded up to 64x2 to maintain alignment.
    ALIGN_STK_64(pixel, src_buf, 8 * 64 + 128,);
    ALIGN_STK_64(pixel, top_buf, 2 * 64 + 128,);
    ALIGN_STK_64(pixel, bot_buf, 2 * 64 + 128,);
    ALIGN_STK_16(pixel, left, 8, [2]);

    declare_func(void, uint8_t *dst, ptrdiff_t dst_stride, const pixel *src,
                 ptrdiff_t src_stride, const pixel (*left)[2], const pixel *top,
                 const pixel *bottom, unsigned max_band_log2,
                 unsigned ext_filter, unsigned quant_step, int edge_clf, int w,
                 int h, enum CdefEdgeFlags edges HIGHBD_DECL_SUFFIX);

    const ptrdiff_t src_stride = 64 * sizeof(pixel);
    const ptrdiff_t dst_stride = 64;

    // Adjust pointers to leave space on the left for CDEF_HAVE_LEFT.
    pixel *const src = src_buf + 64;
    pixel *const top = top_buf + 64;
    pixel *const bot = bot_buf + 64;

    if (!check_func(fn, "ccso_prep_%s_clf_%dbpc", name, BITDEPTH))
        return;

    for (enum CdefEdgeFlags edges = 0; edges <= 0xf; ++edges) {
        const int w = get_rnd_width(ss_hor, edges);
        for (unsigned ext_filter = 0; ext_filter < 7; ++ext_filter)
            for (unsigned max_band_log2 = 0; max_band_log2 <= 3;
                 max_band_log2++)
                for (int scale_idx = 0; scale_idx < 4; ++scale_idx)
                    for (int quant_idx = 0; quant_idx < 4; ++quant_idx) {
                        const unsigned quant_step =
                            dav2d_ccso_quant_sz[scale_idx][quant_idx];
                        const int n_edge_clf = quant_step ? 2 : 1;

                        for (int edge_clf = 0; edge_clf < n_edge_clf;
                             ++edge_clf)
                        {
                            const int bitdepth_max = get_rnd_bitdepth_max();
                            init_prep_buffers(src_buf, top_buf, bot_buf, left,
                                              bitdepth_max);

                            memset(c_dst, 0x88, sizeof(c_dst));
                            memset(a_dst, 0x88, sizeof(a_dst));

                            call_ref(c_dst, dst_stride, src, src_stride, left,
                                     top, bot, max_band_log2, ext_filter,
                                     quant_step, edge_clf, w, h, edges
                                     HIGHBD_TAIL_SUFFIX);
                            call_new(a_dst, dst_stride, src, src_stride, left,
                                     top, bot, max_band_log2, ext_filter,
                                     quant_step, edge_clf, w, h, edges
                                     HIGHBD_TAIL_SUFFIX);
                            if (checkasm_check(uint8_t, c_dst, dst_stride,
                                               a_dst, dst_stride, w, h, "dst"))
                            {
                                fprintf(stderr, "name=%s w=%d h=%d edges=%x "
                                        "ext_filter=%u max_band_log2=%u "
                                        "quant_step=%u edge_clf=%d\n",
                                        name, w, h, edges, ext_filter,
                                        max_band_log2, quant_step, edge_clf);
                                return;
                            }
                        }
                    }
    }

#define bench_ccso_prep_clf_case(edges, ext_filter, max_band_log2, quant_step, \
                                 edge_clf) \
    do { \
        const int w = 64 >> ss_hor; \
        const int bitdepth_max = get_rnd_bitdepth_max(); \
        init_prep_buffers(src_buf, top_buf, bot_buf, left, bitdepth_max); \
\
        bench_new(a_dst, dst_stride, src, src_stride, left, top, bot, \
                  max_band_log2, ext_filter, quant_step, edge_clf, w, h, 0xf \
                  HIGHBD_TAIL_SUFFIX); \
    } while (0)

    bench_ccso_prep_clf_case(0xf, 0, 3, 64, 0);
    bench_ccso_prep_clf_case(0xf, 0, 3, 64, 1);

#undef bench_ccso_prep_clf_case
}

static void init_add_buffers(pixel *const c_dst, pixel *const a_dst,
                             uint8_t *const idx, uint8_t *const offset_idxs,
                             const int bitdepth_max)
{
    init_pixels(c_dst, 8 * 64, bitdepth_max);
    memcpy(a_dst, c_dst, 8 * 64 * sizeof(*c_dst));

    // Offset first table index range is 0-127 inclusive, indexing into
    // four-bit entries in `offset_idxs_tbl`: top six bits select byte, low bit
    // selects within the byte.
    for (int i = 0; i < 8 * 64; ++i)
        idx[i] = rnd() & 0x7f;

    // Offset second table range is 0-7 inclusive, indexing into
    // `offset_lut_tbl` (loaded from `dav2d_ccso_offset`), with each value
    // packed into four bits.
    for (int i = 0; i < 64; ++i) {
        const unsigned lo = rnd() & 7;
        const unsigned hi = rnd() & 7;
        offset_idxs[i] = lo | (hi << 4);
    }
}

static void init_ll_mask(uint16_t (*ll_mask)[4], int w, int h)
{
    const int blocks = (w + 3) / 4;
    const uint16_t valid_mask = (1u << blocks) - 1;

    // Only the 0th value in the inner array is used.
    ll_mask[0][0] = rnd() & valid_mask;
    ll_mask[1][0] = rnd() & valid_mask;
}

static void check_ccso_add(const ccso_add_fn fn, int ss_hor, int ss_ver,
                           const char *name)
{
    const int h = 8 >> ss_ver;

    ALIGN_STK_64(pixel, c_dst, 8 * 64,);
    ALIGN_STK_64(pixel, a_dst, 8 * 64,);
    ALIGN_STK_64(uint8_t, idx, 8 * 64,);
    ALIGN_STK_64(uint8_t, offset_idxs, 64,);
    ALIGN_STK_16(uint16_t, ll_mask, 2, [4]);

    declare_func(void, pixel *dst, ptrdiff_t dst_stride, const uint8_t *idx,
                 ptrdiff_t idx_stride, const uint8_t *offset_idxs,
                 const int8_t *offset_lut, int w, int h,
                 const uint16_t (*ll_mask)[4] HIGHBD_DECL_SUFFIX);

    const ptrdiff_t dst_stride = 64 * sizeof(pixel);
    const ptrdiff_t idx_stride = 64;

    if (!check_func(fn, "ccso_add_%s_%dbpc", name, BITDEPTH))
        return;

    for (int scale_idx = 0; scale_idx < 4; ++scale_idx) {
        const int w = get_rnd_width(ss_hor, 0xf);
        const int bitdepth_max = get_rnd_bitdepth_max();
        init_add_buffers(c_dst, a_dst, idx, offset_idxs, bitdepth_max);
        init_ll_mask(ll_mask, w, h);

        call_ref(c_dst, dst_stride, idx, idx_stride, offset_idxs,
                 dav2d_ccso_offset[scale_idx], w, h, ll_mask
                 HIGHBD_TAIL_SUFFIX);
        call_new(a_dst, dst_stride, idx, idx_stride, offset_idxs,
                 dav2d_ccso_offset[scale_idx], w, h, ll_mask
                 HIGHBD_TAIL_SUFFIX);
        if (checkasm_check_pixel(c_dst, dst_stride, a_dst, dst_stride, w, h,
                                 "dst"))
        {
            fprintf(stderr, "name=%s bpc=%d w=%d h=%d scale_idx=%d "
                    "ll_mask=%04x,%04x\n",
                    name, bitdepth_from_max(bitdepth_max), w, h, scale_idx,
                    ll_mask[0][0], ll_mask[1][0]);
            return;
        }
    }

    const int w = 64 >> ss_hor;
    const int bitdepth_max = get_rnd_bitdepth_max();
    init_add_buffers(c_dst, a_dst, idx, offset_idxs, bitdepth_max);
    memset(ll_mask, 0, sizeof(ll_mask));

    bench_new(a_dst, dst_stride, idx, idx_stride, offset_idxs,
              dav2d_ccso_offset[0], w, h, ll_mask HIGHBD_TAIL_SUFFIX);
}

void bitfn(checkasm_check_ccso)(void)
{
    Dav2dCcsoDSPContext c;
    bitfn(dav2d_ccso_dsp_init)(&c);

    check_ccso_prep_bo(c.prep_bo[0], 0, 0, "444");
    check_ccso_prep_bo(c.prep_bo[1], 1, 0, "422");
    check_ccso_prep_bo(c.prep_bo[2], 1, 1, "420");
    report("ccso_prep_bo");

    check_ccso_prep_clf(c.prep_clf[0], 0, 0, "444");
    check_ccso_prep_clf(c.prep_clf[1], 1, 0, "422");
    check_ccso_prep_clf(c.prep_clf[2], 1, 1, "420");
    report("ccso_prep_clf");

    check_ccso_add(c.add, 0, 0, "444");
    check_ccso_add(c.add, 1, 0, "422");
    check_ccso_add(c.add, 1, 1, "420");
    report("ccso_add");
}
