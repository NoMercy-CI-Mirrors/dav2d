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

#include "config.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "common/attributes.h"
#include "common/bitdepth.h"

#include "src/looprestoration.h"

// 64 + 6 + 6
#define REST_UNIT_STRIDE (76)

//         C
//   E     A     F
//       6 2 7
//     8 4 0 5 9
// D B 3 1   1 3 B D
//     9 5 0 4 8
//       7 2 6
//   F     A     E
//         C
static const int8_t wiener_ns_config_y[16][2] = {
    { 1, 0 }, { 0, 1 }, { 2, 0 }, { 0, 2 },
    { 1, 1 }, { -1, 1 }, { 2, 1 }, { 2, -1 },
    { 1, 2 }, { 1, -2 }, { 3, 0 }, { 0, 3 },
    { 4, 0 }, { 0, 4 }, { 3, 3 }, { 3, -3 },
};

//     4
//   2 0 3
// 5 1   1 5
//   3 0 2
//     4
static const int8_t wiener_ns_config_uv[6][2] = {
    { 1, 0 }, { 0, 1 }, { 1, 1 }, { -1, 1 }, { 2, 0 }, { 0, 2 },
};

//     9
//   5 1 6
// B 3   2 A
//   7 0 4
//     8
static const int8_t wiener_ns_config_uv_from_y[12][2] = {
    { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, -1 },
    { -1, 1 }, { 1, -1 }, { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 },
};

//       A
//     6 2 7
//   8 4 0 5 9
// B 3 1 C 1 3 B
//   9 5 0 4 8
//     7 2 6
//       A
static const int8_t pc_wiener_config[12][2] = {
    {  1,  0 }, {  0,  1 }, {  2,  0 }, {  0,  2 }, {  1,  1 }, { -1,  1 },
    {  2,  1 }, {  2, -1 }, {  1,  2 }, {  1, -2 }, {  3,  0 }, {  0,  3 },
};

static const uint16_t pc_wiener_normalizer[3] = { 3739, 3273, 3074 };

static void backup_row(pixel *dst, const pixel *src, const pixel *left,
                       const int w, const int edge_len, const int left_w,
                       const enum LrEdgeFlags edges)
{
    if (edges & LR_HAVE_LEFT)
        for (int x = -edge_len; x < 0; x++)
            dst[x] = left[x + left_w];
    else
        for (int x = -edge_len; x < 0; x++)
            dst[x] = src[0];

    for (int x = 0; x < w; x++)
        dst[x] = src[x];

    if (edges & LR_HAVE_RIGHT)
        for (int x = w; x < w + edge_len; x++)
            dst[x] = src[x];
    else
        for (int x = w; x < w + edge_len; x++)
            dst[x] = src[w - 1];
}

static void backup_row_lpf(pixel *dst, const pixel *src, const int w,
                           const int edge_len, const enum LrEdgeFlags edges)
{
    if (edges & LR_HAVE_LEFT) {
        for (int x = -edge_len; x < 0; x++)
            dst[x] = src[x];
    } else {
        for (int x = -edge_len; x < 0; x++)
            dst[x] = src[0];
    }

    for (int x = 0; x < w; x++)
        dst[x] = src[x];

    if (edges & LR_HAVE_RIGHT) {
        for (int x = w; x < w + edge_len; x++)
            dst[x] = src[x];
    } else {
        for (int x = w; x < w + edge_len; x++)
            dst[x] = src[w - 1];
    }
}

static void backup_row_luma(pixel *dst, const pixel *src,
                            const ptrdiff_t src_stride,
                            const pixel (*left)[8],
                            const int w, const enum LrEdgeFlags edges,
                            const int ss_hor, const int ss_ver,
                            const int cfl_ds_flt)
{
    if (!ss_ver) {
        if (edges & LR_HAVE_LEFT) {
            for (int x = -(4 >> ss_hor); x < 0; x++)
                dst[x] = src[x * (1 << ss_hor)];
        } else {
            for (int x = -(4 >> ss_hor); x < 0; x++)
                dst[x] = src[0];
        }

        for (int x = 0; x < w; x++)
            dst[x] = src[x << ss_hor];

        if (edges & LR_HAVE_RIGHT) {
            for (int x = w; x < w + (4 >> ss_hor); x++)
                dst[x] = src[x << ss_hor];
        } else {
            for (int x = w; x < w + (4 >> ss_hor); x++)
                dst[x] = dst[w - 1];
        }
        return;
    }

    assert(ss_hor);
    const pixel *src2 = &src[PXSTRIDE(src_stride)];
    switch (cfl_ds_flt) {
    case 0:
        for (int x = 0, x2 = 0; x < w; x++, x2 += 2) {
            dst[x] = (src[x2] + src2[x2] + src[x2 + 1] + src2[x2 + 1]) >> 2;
        }
        break;
    case 1:
        for (int x = 0, x2 = 0; x < w; x++, x2 += 2)
            dst[x] = (src[x2] + src2[x2]) >> 1;
        break;
    default:
        dav2d_unreachable();
        // fall-through in non-debug mode
    case 2:
        for (int x = 0, x2 = 0; x < w; x++, x2 += 2)
            dst[x] = src[x2];
        break;
    }

    const pixel *left1, *left2;
    if (left) {
        left1 = left[0] + 8;
        left2 = left[1] + 8;
    } else {
        left1 = src;
        left2 = src2;
    }
    if (edges & LR_HAVE_LEFT) {
        switch (cfl_ds_flt) {
        case 0:
            for (int x = -2, x2 = -4; x < 0; x++, x2 += 2)
                dst[x] = (left1[x2] + left2[x2] +
                          left1[x2 + 1] + left2[x2 + 1]) >> 2;
            break;
        case 1:
            for (int x = -2, x2 = -4; x < 0; x++, x2 += 2)
                dst[x] = (left1[x2] + left2[x2]) >> 1;
            break;
        default:
            dav2d_unreachable();
            // fall-through in non-debug mode
        case 2:
            for (int x = -2, x2 = -4; x < 0; x++, x2 += 2)
                dst[x] = left1[x2];
            break;
        }
    } else {
        for (int x = -2; x < 0; x++)
            dst[x] = dst[0];
    }

    if (edges & LR_HAVE_RIGHT) {
        switch (cfl_ds_flt) {
        case 0:
            for (int x = w, x2 = w << 1; x < w + 2; x++, x2 += 2)
                dst[x] = (src[x2] + src2[x2] + src[x2 + 1] + src2[x2 + 1]) >> 2;
            break;
        case 1:
            for (int x = w, x2 = w << 1; x < w + 2; x++, x2 += 2)
                dst[x] = (src[x2] + src2[x2]) >> 1;
            break;
        default:
            dav2d_unreachable();
            // fall-through in non-debug mode
        case 2:
            for (int x = w, x2 = w << 1; x < w + 2; x++, x2 += 2)
                dst[x] = src[x2];
            break;
        }
    } else {
        for (int x = w; x < w + 2; x++)
            dst[x] = dst[w - 1];
    }
}

static void ns_wiener_single_y_c(pixel *p, const ptrdiff_t stride,
                                 const pixel (*left)[8],
                                 const pixel *lpf, const pixel *lpf_bottom,
                                 const WienerParams *params,
                                 const uint16_t (*ll_mask)[4],
                                 const int w, int h,
                                 const enum LrEdgeFlags edges
                                 HIGHBD_DECL_SUFFIX)
{
    const int8_t *filter = params->single.filter;
    pixel row_buffers[9][REST_UNIT_STRIDE];
    pixel *bak_rows[9];
    const pixel *ptrs[9];

    for (int i = 0; i < 9; i++)
        bak_rows[i] = row_buffers[i] + 6;

    backup_row(bak_rows[4], p, left[0], w, 4, 8, edges);
    ptrs[4] = bak_rows[4];
    if (edges & LR_HAVE_TOP_INTEGRATED) {
        lpf += 2 * PXSTRIDE(stride);
        for (int i = 0; i < 4; i++) {
            backup_row_lpf(bak_rows[i], lpf, w, 4, edges);
            lpf += PXSTRIDE(stride);
            ptrs[i] = bak_rows[i];
        }
    } else if (edges & LR_HAVE_TOP) {
        // y = -2,-1
        backup_row_lpf(bak_rows[2], lpf, w, 4, edges);
        ptrs[2] = bak_rows[2];
        backup_row_lpf(bak_rows[3], lpf + PXSTRIDE(stride), w, 4, edges);
        ptrs[3] = bak_rows[3];

        // y = -3,-4
        ptrs[0] = ptrs[1] = ptrs[2];
    } else {
        ptrs[0] = ptrs[1] = ptrs[2] = ptrs[3] = ptrs[4];
    }

    backup_row(bak_rows[5], p + PXSTRIDE(stride), left[1], w, 4, 8, edges);
    ptrs[5] = bak_rows[5];
    backup_row(bak_rows[6], p + 2*PXSTRIDE(stride), left[2], w, 4, 8, edges);
    ptrs[6] = bak_rows[6];
    backup_row(bak_rows[7], p + 3*PXSTRIDE(stride), left[3], w, 4, 8, edges);
    ptrs[7] = bak_rows[7];
    int bak_idx = 8;

    for (int y = 0; y < h; y++) {
        if (y + 4 < h) {
            backup_row(bak_rows[bak_idx], p + 4*PXSTRIDE(stride), left[y + 4], w, 4, 8, edges);
            ptrs[8] = bak_rows[bak_idx];
        } else if (edges & LR_HAVE_BOTTOM_INTEGRATED) {
            backup_row_lpf(bak_rows[bak_idx], p + 4*PXSTRIDE(stride), w, 4, edges);
            ptrs[8] = bak_rows[bak_idx];
        } else if (y + 2 < h && edges & LR_HAVE_BOTTOM) {
            int offset_y = y + 4 - h;
            assert(offset_y < 2);
            backup_row_lpf(bak_rows[bak_idx], lpf_bottom + offset_y * PXSTRIDE(stride), w, 4, edges);
            ptrs[8] = bak_rows[bak_idx];
        } else {
            ptrs[8] = ptrs[7];
        }
        if (++bak_idx == 9) bak_idx = 0;

        for (int bx = 0; bx < (w >> 2); bx++) {
            if (ll_mask[y >> 2][0] & (1 << bx)) continue;
            for (int x = bx * 4; x < bx * 4 + 4; x++) {
                const int m = ptrs[4][x];
                int s = m << 7;
                for (int i = 0; i < 16; i++) {
                    const int dy = wiener_ns_config_y[i][0];
                    const int dx = wiener_ns_config_y[i][1];
                    const int diff = ptrs[4 + dy][x + dx] +
                        ptrs[4 - dy][x - dx] - 2 * m;
                    s += diff * filter[i];
                }
                const int v = (s + 64) >> 7;
                p[x] = iclip_pixel(v);
            }
        }

        for (int r = 0; r < 8; r++) ptrs[r] = ptrs[r+1];
        p += PXSTRIDE(stride);
    }
}

static NOINLINE void
wiener_uv_luma_c(coef *dst, const pixel *luma, const ptrdiff_t stride,
                 const pixel (*left)[8], const pixel *top, const pixel *bottom,
                 const int8_t *filter, const int w, const int h,
                 const int ss_hor, const int ss_ver, const int ds_flt,
                 const enum LrEdgeFlags edges)
{
    pixel row_buffers[5][REST_UNIT_STRIDE + 64];
    pixel *bak_rows[5];
    const pixel *ptrs[5];

    for (int i = 0; i < 5; i++)
        bak_rows[i] = row_buffers[i] + 6;

    ptrdiff_t row_step = 1 + ss_ver;

    backup_row_luma(bak_rows[2], luma, stride, left, w, edges,
                    ss_hor, ss_ver, ds_flt);
    luma += row_step * PXSTRIDE(stride);
    left += row_step;
    ptrs[2] = bak_rows[2];
    if (edges & LR_HAVE_TOP_INTEGRATED) {
        top += (6 - 2 * row_step) * PXSTRIDE(stride);
        backup_row_luma(bak_rows[0], top,
                        stride, NULL, w, edges, ss_hor, ss_ver, ds_flt);
        ptrs[0] = bak_rows[0];
        backup_row_luma(bak_rows[1], top + row_step * PXSTRIDE(stride),
                        stride, NULL, w, edges, ss_hor, ss_ver, ds_flt);
        ptrs[1] = bak_rows[1];
    } else if (edges & LR_HAVE_TOP) {
        backup_row_luma(bak_rows[0], top, 0, NULL, w, edges, ss_hor, ss_ver,
                        ds_flt);
        ptrs[0] = bak_rows[0];
        backup_row_luma(bak_rows[1], top, stride, NULL, w, edges, ss_hor, ss_ver,
                        ds_flt);
        ptrs[1] = bak_rows[1];
    } else {
        ptrs[0] = ptrs[1] = ptrs[2];
    }
    backup_row_luma(bak_rows[3], luma, stride, left, w, edges, ss_hor, ss_ver,
                    ds_flt);
    luma += row_step * PXSTRIDE(stride);
    left += row_step;
    ptrs[3] = bak_rows[3];
    int bak_idx = 4;

    for (int y = 0; y < h; y++) {
        if (y + 2 < h) {
            backup_row_luma(bak_rows[bak_idx], luma, stride, left, w,
                            edges, ss_hor, ss_ver, ds_flt);
            left += row_step;
            ptrs[4] = bak_rows[bak_idx];
        } else if (edges & LR_HAVE_BOTTOM_INTEGRATED) {
            backup_row_luma(bak_rows[bak_idx], luma, stride, NULL, w, edges,
                            ss_hor, ss_ver, ds_flt);
            ptrs[4] = bak_rows[bak_idx];
        } else if (!(edges & LR_HAVE_BOTTOM)) {
            ptrs[4] = ptrs[3];
        } else if (y + 2 == h) {
            backup_row_luma(bak_rows[bak_idx], bottom, stride, NULL, w, edges,
                            ss_hor, ss_ver, ds_flt);
            ptrs[4] = bak_rows[bak_idx];
        } else if (y + 1 == h) {
            backup_row_luma(bak_rows[bak_idx], bottom + PXSTRIDE(stride), 0,
                            NULL, w, edges, ss_hor, ss_ver, ds_flt);
            ptrs[4] = bak_rows[bak_idx];
        }
        if (++bak_idx == 5) bak_idx = 0;

        for (int x = 0; x < w; x++) {
            int s = 0;
            const int l = ptrs[2][x];
            for (int i = 0; i < 12; i++) {
                const int dy = wiener_ns_config_uv_from_y[i][0];
                const int dx = wiener_ns_config_uv_from_y[i][1];
                const int diff = ptrs[2 + dy][x + dx] - l;
                s += diff * filter[6 + i];
            }
            dst[x] = s;
        }

        for (int r = 0; r < 4; r++) ptrs[r] = ptrs[r + 1];
        dst += 64;
        luma += row_step * PXSTRIDE(stride);
    }
}

#define wiener_uv_luma_fn(ss_hor, ss_ver, name) \
static void \
wiener_uv_luma_##name##_c(coef *dst, \
                          const pixel *luma, const ptrdiff_t stride, \
                          const pixel (*left)[8], \
                          const pixel *top, const pixel *bottom, \
                          const int8_t *filter, const int w, const int h, \
                          const int ds_flt, const enum LrEdgeFlags edges) \
{ \
    wiener_uv_luma_c(dst, luma, stride, left, top, bottom, filter, w, h, \
                     ss_hor, ss_ver, ds_flt, edges); \
}

wiener_uv_luma_fn(1, 1, 420);
wiener_uv_luma_fn(1, 0, 422);
wiener_uv_luma_fn(0, 0, 444);

static void wiener_uv_chroma_c(pixel *p, const ptrdiff_t stride,
                               const pixel (*left)[2],
                               const pixel *lpf_top, const pixel *lpf_bottom,
                               const coef *luma, const int8_t *filter,
                               const uint16_t (*ll_mask)[4],
                               const int w, const int h,
                               const enum LrEdgeFlags edges HIGHBD_DECL_SUFFIX)
{
    pixel row_buffers[5][REST_UNIT_STRIDE];
    pixel *bak_rows[5];
    const pixel *ptrs[5];

    for (int i = 0; i < 5; i++)
        bak_rows[i] = row_buffers[i] + 6;

    backup_row(bak_rows[2], p, *left, w, 2, 2, edges);
    left++;
    ptrs[2] = bak_rows[2];
    if (edges & (LR_HAVE_TOP_INTEGRATED | LR_HAVE_TOP)) {
        // y = -2,-1
        for (int i = 0; i < 2; i++) {
            backup_row_lpf(bak_rows[i], lpf_top, w, 2, edges);
            ptrs[i] = bak_rows[i];
            lpf_top += PXSTRIDE(stride);
        }
    } else {
        ptrs[0] = ptrs[1] = ptrs[2];
    }

    backup_row(bak_rows[3], p + PXSTRIDE(stride), *left, w, 2, 2, edges);
    left++;
    ptrs[3] = bak_rows[3];
    int bak_idx = 4;

    for (int y = 0; y < h; y++) {
        if (y + 2 < h) {
            backup_row(bak_rows[bak_idx], p + 2*PXSTRIDE(stride), *left, w,
                       2, 2, edges);
            left++;
            ptrs[4] = bak_rows[bak_idx];
        } else if (edges & LR_HAVE_BOTTOM_INTEGRATED) {
            backup_row_lpf(bak_rows[bak_idx], p + 2*PXSTRIDE(stride), w, 2,
                           edges);
            ptrs[4] = bak_rows[bak_idx];
        } else if (edges & LR_HAVE_BOTTOM) {
            int offset_y = y + 2 - h;
            assert(offset_y < 2);
            backup_row_lpf(bak_rows[bak_idx],
            lpf_bottom + offset_y * PXSTRIDE(stride), w, 2, edges);
            ptrs[4] = bak_rows[bak_idx];
        } else {
            ptrs[4] = ptrs[3];
        }
        if (++bak_idx == 5) bak_idx = 0;

        for (int bx = 0; bx < (w >> 2); bx++) {
            if (ll_mask[y >> 2][0] & (1 << bx)) continue;
            for (int x = bx * 4; x < bx * 4 + 4; x++) {
                const int m = ptrs[2][x];
                int s = m << 7;
                for (int i = 0; i < 6; i++) {
                    const int dy = wiener_ns_config_uv[i][0];
                    const int dx = wiener_ns_config_uv[i][1];
                    const int diff = ptrs[2 + dy][x + dx] +
                                     ptrs[2 - dy][x - dx] - 2 * m;
                    s += diff * filter[i];
                }
                s += luma[x];
                const int v = (s + 64) >> 7;
                p[x] = iclip_pixel(v);
            }
        }

        for (int r = 0; r < 4; r++) ptrs[r] = ptrs[r + 1];
        p += PXSTRIDE(stride);
        luma += 64;
    }
}

static void calc_features_2x2(uint16_t f[3], const int x2, const int y2,
                              pixel *const *ptrs)
{
    f[0] = f[1] = f[2] = 0;
    for (int y = y2; y < y2 + 2; y++) {
        for (int x = x2; x < x2 + 2; x++) {
            const int m = ptrs[y][x];
            const int up = ptrs[y - 1][x];
            const int down = ptrs[y + 1][x];
            const int vert = up - 2 * m + down;

            const int up_right = ptrs[y - 1][x + 1];
            const int down_left = ptrs[y + 1][x - 1];
            const int anti_diag = up_right - 2 * m + down_left;

            const int down_right = ptrs[y + 1][x + 1];
            const int up_left = ptrs[y - 1][x - 1];
            const int diag = up_left - 2 * m + down_right;

            f[0] += abs(vert);
            f[1] += abs(anti_diag);
            f[2] += abs(diag);
        }
    }
}

static void add_features_2x2_u32(uint32_t f[3], const int x2, const int y2,
                                 pixel *const *ptrs)
{
    uint16_t tmp_f[3];
    calc_features_2x2(tmp_f, x2, y2, ptrs);
    for (int i = 0; i < 3; i++) {
        f[i] += tmp_f[i];
    }
}

static void cache_skip_count_row(uint8_t s[16], unsigned noskip_mask,
                                 const int bw)
{
    // pad edges
    noskip_mask = (noskip_mask << 1) |
                  (noskip_mask & 1) |
                  ((noskip_mask & 0x8000) << 2);
    noskip_mask = ~noskip_mask;
    for (int bx = 0; bx < bw; bx++) {
        s[bx] = 4 * ((noskip_mask >> 1) & 1) + // center
                (noskip_mask & 1) +            // right
                ((noskip_mask >> 2) & 1);      // left
        noskip_mask >>= 1;
    }
}

static void wiener_multi(pixel *p, const ptrdiff_t stride,
                         const pixel (*left)[8],
                         const pixel *lpf, const pixel *lpf_bottom,
                         const int w, int const h,
                         const int8_t (*filters_user)[16],
                         const int8_t (*filters_pretrained)[13],
                         const uint8_t *class_lut,
                         const uint16_t *noskip_mask,
                         const WienerQValApproxData *qval_approx,
                         const enum LrEdgeFlags edges,
                         const uint16_t (*ll_mask)[4] HIGHBD_DECL_SUFFIX)
{
    const int bitdepth_min_8 = bitdepth_from_max(bitdepth_max) - 8;
    const int bh = h >> 2;
    const int bw = w >> 2;

    pixel row_buffers[12][REST_UNIT_STRIDE];
    pixel *bak_rows[12];
    pixel *ptrs[12];

    uint8_t classes[16];
    uint8_t s_rows[3][16];

    // When accumulating features, there is some overlap between adjacent
    // blocks. The diagram below demonstrates how results are reused and
    // backed up.
    //
    //    -1 +0 +1 +2 +3 +4 +5 +6 +7 +8     -1 +0 +1 +2 +3 +4 +5 +6 +7 +8
    //   ┌─────┬─────┬─────┬─────┬─────┐   ┌─────┬─────┬─────┬─────┬─────┐
    // -1│*****│above│#+#+#│     │     │ -1│     │     │*****│above│#+#+#│
    //  0│*****│+++++│+#+#+│     │     │  0│     │     │*****│+++++│+#+#+│
    //   ├─────┼─────┼─────┼─────┼─────┤   ├─────┼─────┼─────┼─────┼─────┤
    // +1│*left│bx=0 │#####│     │     │ +1│     │  ┌─►│*left│bx=1 │#####│
    // +2│*****│ by=0│right│──┐  │     │ +2│     │  │  │*****│ by=0│right│
    //   ┼─────┼─────┼─────┼──│──┼─────┤   ├─────┼──│──┼─────┼─────┼─────┤
    // +3│*****│below│.#.#.│  │  │     │ +3│     │  │  │*****│below│.#.#.│
    // +4│*****│.....│#.#.#│  │  │     │ +4│     │  │  │*****│.....│#.#.#│
    //   └─────┴─────┴─────┴──│──┴─────┘   └─────┴──│──┴─────┴─────┴─────┘
    //            │           └─────────────────────┘
    //            └───────────────┐
    //    -1 +0 +1 +2 +3 +4 +5 +6 │
    //   ┌─────┬─────┬─────┬─────┐│
    // -1│     │  ┌───────────────┘
    //  0│     │  │  │     │     │
    //   ├─────┼──┼──┼─────┼─────┤
    // +1│     │  │  │     │     │
    // +2│     │  ▼  │     │     │
    //   ├─────┼─────┼─────┼─────┤
    // +3│*****│above│#+#+#│     │
    // +4│*****│+++++│+#+#+│     │
    //   ├─────┼─────┼─────┼─────┤
    // +5│*left│bx=0 │#####│     │
    // +6│*****│ by=1│right│     │
    //   ┼─────┼─────┼─────┼─────┤
    // +7│*****│below│.#.#.│     │
    // +8│*****│.....│#.#.#│     │
    //   └─────┴─────┴─────┴─────┘
    //
    // There is also a special case for the above left at the beginning of
    // each row.
    uint16_t f_a[32][3];
    uint32_t f_l[3];
    uint16_t f_al[3];

    for (int i = 0; i < 12; i++)
        bak_rows[i] = row_buffers[i] + 6;

    for (int y = 0; y < 8; y++)
        ptrs[y] = bak_rows[y];
    for (int y = 0; y < 4; y++)
        backup_row(ptrs[4+y], p + y*PXSTRIDE(stride), left[y], w, 4, 8, edges);
    if (edges & LR_HAVE_TOP_INTEGRATED) {
        lpf += 2 * PXSTRIDE(stride);
        for (int i = 0; i < 4; i++) {
            backup_row_lpf(ptrs[i], lpf, w, 4, edges);
            lpf += PXSTRIDE(stride);
        }
    } else if (edges & LR_HAVE_TOP) {
        // y = -2,-1
        backup_row_lpf(bak_rows[2], lpf + 0*PXSTRIDE(stride), w, 4, edges);
        backup_row_lpf(bak_rows[3], lpf + 1*PXSTRIDE(stride), w, 4, edges);
        // y = -3,-4
        ptrs[0] = ptrs[1] = ptrs[2];
    } else {
        ptrs[0] = ptrs[1] = ptrs[2] = ptrs[3] = ptrs[4];
    }
    int bak_idx = 8;

    cache_skip_count_row(s_rows[0], *noskip_mask, bw);
    memcpy(s_rows[1], s_rows[0], sizeof(s_rows[0]));

    calc_features_2x2(f_al, -1, 4 - 1, ptrs);
    for (int x = 1, i = 0; x < w + 1; x += 2, i++) {
        calc_features_2x2(f_a[i], x, 4 - 1, ptrs);
    }

    for (int by = 0; by < bh; by++) {
        // Backup the next 4 lines
        for (int y = 0; y < 4; y++)
            ptrs[8+y] = bak_rows[bak_idx+y];
        bak_idx += 4;
        if (bak_idx == 12) bak_idx = 0;
        if (by + 1 < bh) {
            for (int y = 0; y < 4; y++)
                backup_row(ptrs[8+y], p + (4+y)*PXSTRIDE(stride),
                           left[(by << 2) + 4+y], w, 4, 8, edges);
        } else if (edges & LR_HAVE_BOTTOM_INTEGRATED) {
            for (int y = 0; y < 4; y++)
                backup_row_lpf(ptrs[8+y], p + (4+y)*PXSTRIDE(stride), w, 4, edges);
        } else if (edges & LR_HAVE_BOTTOM) {
            backup_row_lpf(ptrs[8], lpf_bottom + 0*PXSTRIDE(stride), w, 4, edges);
            backup_row_lpf(ptrs[9], lpf_bottom + 1*PXSTRIDE(stride), w, 4, edges);
            ptrs[10] = ptrs[11] = ptrs[9];
        } else {
            for (int y = 0; y < 4; y++)
                ptrs[8+y] = ptrs[7];
        }

        if (by + 1 < bh)
            cache_skip_count_row(s_rows[2], noskip_mask[by + 1], bw);
        else
            memcpy(s_rows[2], s_rows[1], sizeof(s_rows[1]));

        // above-left
        for (int i = 0; i < 3; i++)
            f_l[i] = f_al[i];
        // center-left
        add_features_2x2_u32(f_l, -1, 4 + 1, ptrs);
        // below-left: replace f_al for the next row
        calc_features_2x2(f_al, -1, 4 + 3, ptrs);
        for (int i = 0; i < 3; i++)
            f_l[i] += f_al[i];

        for (int bx = 0; bx < bw; bx++) {
            const int fi = bx << 1;
            const int x = bx << 2;
            uint32_t f[3];

            // left
            for (int i = 0; i < 3; i++)
                f[i] = f_l[i];

            // above-center
            for (int i = 0; i < 3; i++)
                f[i] += f_a[fi][i];
            // center-center
            add_features_2x2_u32(f, x + 1, 4 + 1, ptrs);
            // below-center
            calc_features_2x2(f_a[fi], x + 1, 4 + 3, ptrs);
            for (int i = 0; i < 3; i++)
                f[i] += f_a[fi][i];

            // right: create the next left sum and add it to 'f'
            // above-right
            for (int i = 0; i < 3; i++)
                f_l[i] = f_a[fi + 1][i];
            // center-right
            add_features_2x2_u32(f_l, x + 3, 4 + 1, ptrs);
            // below-right
            calc_features_2x2(f_a[fi + 1], x + 3, 4 + 3, ptrs);
            for (int i = 0; i < 3; i++) {
                f_l[i] += f_a[fi + 1][i];
                f[i] += f_l[i];
            }

            const int s = s_rows[0][bx] + 4 * s_rows[1][bx] + s_rows[2][bx];
            const int rnd = 1 << bitdepth_min_8 >> 1;
            for (int i = 0; i < 3; i++) {
                f[i] = (f[i] * pc_wiener_normalizer[i] + rnd) >> bitdepth_min_8;
            }

            int lut_idx = (s < qval_approx->idx0_changeover) << 9;
            for (int i = 0; i < 3; i++) {
                const int qval = qval_approx->slopes[i] * s +
                                 qval_approx->error_lut[i*64 + s] +
                                 qval_approx->offsets[i];
                int sub_idx = (imax(0, f[i] + 255 * qval) + 8192) >> 14;
                sub_idx = imin(sub_idx, 255) >> 5;
                lut_idx |= sub_idx << (3 * (2-i));
            }
            classes[bx] = class_lut[lut_idx];
        }

        memcpy(s_rows[0], s_rows[1], sizeof(s_rows[1]));
        memcpy(s_rows[1], s_rows[2], sizeof(s_rows[2]));

        for (int y = by << 2; y < (by << 2) + 4; y++) {
            for (int bx = 0; bx < bw; bx++) {
                if (ll_mask[by][0] & (1 << bx)) continue;
                if (filters_user) {
                    const int8_t *filter = filters_user[classes[bx]];
                    for (int x = bx << 2; x < (bx << 2) + 4; x++) {
                        const int m = ptrs[4][x];
                        int s = m << 7;
                        for (int i = 0; i < 16; i++) {
                            const int dy = wiener_ns_config_y[i][0];
                            const int dx = wiener_ns_config_y[i][1];
                            const int diff = ptrs[4 + dy][x + dx] +
                                ptrs[4 - dy][x - dx] - 2 * m;
                            s += diff * filter[i];
                        }
                        const int v = (s + 64) >> 7;
                        p[x] = iclip_pixel(v);
                    }
                } else {
                    const int8_t *filter = filters_pretrained[classes[bx]];
                    for (int x = bx << 2; x < (bx << 2) + 4; x++) {
                        int s = 2 * ptrs[4][x] * filter[12];
                        for (int i = 0; i < 12; i++) {
                            const int dy = pc_wiener_config[i][0];
                            const int dx = pc_wiener_config[i][1];
                            s += filter[i] *
                                (ptrs[4 + dy][x + dx] + ptrs[4 - dy][x - dx]);
                        }
                        const int v = (s + 64) >> 7;
                        p[x] = iclip_pixel(v);
                    }
                }
            }
            for (int r = 0; r < 11; r++) ptrs[r] = ptrs[r+1];
            p += PXSTRIDE(stride);
        }
    }
}

static void ns_wiener_multi_c(pixel *p, const ptrdiff_t stride,
                              const pixel (*left)[8],
                              const pixel *lpf, const pixel *lpf_bottom,
                              const WienerParams *params,
                              const uint16_t (*ll_mask)[4],
                              const int w, const int h,
                              const enum LrEdgeFlags edges
                              HIGHBD_DECL_SUFFIX)
{
    wiener_multi(p, stride, left, lpf, lpf_bottom, w, h,
                 params->multi.filters.user, NULL,
                 params->multi.class_lut, params->multi.noskip_mask,
                 params->multi.qval_approx,
                 edges, ll_mask HIGHBD_TAIL_SUFFIX);
}

static void pc_wiener_c(pixel *p, const ptrdiff_t stride,
                        const pixel (*left)[8],
                        const pixel *lpf, const pixel *lpf_bottom,
                        const WienerParams *params,
                        const uint16_t (*ll_mask)[4],
                        const int w, const int h,
                        const enum LrEdgeFlags edges
                        HIGHBD_DECL_SUFFIX)
{
    wiener_multi(p, stride, left, lpf, lpf_bottom, w, h,
                 NULL, params->multi.filters.pretrained,
                 params->multi.class_lut, params->multi.noskip_mask,
                 params->multi.qval_approx,
                 edges, ll_mask HIGHBD_TAIL_SUFFIX);
}

#if BITDEPTH == 8
#define up_shift 2
#define down_shift 0
#define HBD_SHIFT_DECL
#define HBD_SHIFT
#else
#define up_shift 0
#define HBD_SHIFT_DECL , const int down_shift
#define HBD_SHIFT , down_shift
#endif

static void gdf_backup_row(uint16_t *dst, const pixel *src, const pixel *left,
                           const int w, const enum LrEdgeFlags edges HBD_SHIFT_DECL)
{
    if (edges & LR_HAVE_LEFT)
        for (int x = -6; x < 0; x++)
            dst[x] = (left[x + 8] << up_shift) >> down_shift;
    else
        for (int x = -6; x < 0; x++)
            dst[x] = (src[0] << up_shift) >> down_shift;

    for (int x = 0; x < w; x++)
        dst[x] = (src[x] << up_shift) >> down_shift;

    if (edges & LR_HAVE_RIGHT)
        for (int x = w; x < w + 6; x++)
            dst[x] = (src[x] << up_shift) >> down_shift;
    else
        for (int x = w; x < w + 6; x++)
            dst[x] = (src[w - 1] << up_shift) >> down_shift;
}

static void gdf_backup_row_lpf(uint16_t *dst, const pixel *src, const int w,
                               const enum LrEdgeFlags edges HBD_SHIFT_DECL)
{
    if (edges & LR_HAVE_LEFT) {
        for (int x = -6; x < 0; x++)
            dst[x] = (src[x] << up_shift) >> down_shift;
    } else {
        for (int x = -6; x < 0; x++)
            dst[x] = (src[0] << up_shift) >> down_shift;
    }

    for (int x = 0; x < w; x++)
        dst[x] = (src[x] << up_shift) >> down_shift;

    if (edges & LR_HAVE_RIGHT) {
        for (int x = w; x < w + 6; x++)
            dst[x] = (src[x] << up_shift) >> down_shift;
    } else {
        for (int x = w; x < w + 6; x++)
            dst[x] = (src[w - 1] << up_shift) >> down_shift;
    }
}

// Sum 2x2 rows of gradients and store in dst
static void compute_gradient_row(uint16_t (*dst)[4], const uint16_t **src, const int w) {
    uint16_t tmp[33][4];

    for (int x1 = 0; x1 < w + 2; x1 += 2) {
        static const int8_t offs[4][2] = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { -1, 1 } };
        for (int d = 0; d < 4; d++) {
            int grad = 0;
            for (int x2 = 0; x2 < 2; x2++) {
                int x = x1 + x2;
                for (int y = 0; y < 2; y++) {
                    const int dy = offs[d][0];
                    const int dx = offs[d][1];
                    const int a = src[y - 1 - dy][x - 1 - dx];
                    const int b = src[y - 1][x - 1];
                    const int c = src[y - 1 + dy][x - 1 + dx];
                    grad += abs(b * 2 - a - c);
                }
            }
            tmp[x1 >> 1][d] = grad;
        }
    }

    for (int x = 0; x < (w >> 1); x++)
        for (int d = 0; d < 4; d++)
            dst[x][d] = tmp[x][d] + tmp[x + 1][d];
}

static inline int gdf_sum(int a, int b, const int alpha, const int m) {
    a = iclip(a - m, -alpha, alpha);
    b = iclip(b - m, -alpha, alpha);
    return iclip(a + b, -512, 511);
}

static void gdf_prep_c(int8_t *dst, const pixel *p, const ptrdiff_t stride,
                       const pixel (*const left)[8], const pixel *const lpf,
                       const pixel *const lpf_bottom,
                       const Dav2dGdfParams *const params,
                       const int w, const int h,
                       enum LrEdgeFlags edges HIGHBD_DECL_SUFFIX)
{
    assert(w > 0 && w <= 64 && !(w & 7));
    assert(h > 0 && h <= 64 && !(h & 7));
#if BITDEPTH == 16
    const int down_shift = bitdepth_from_max(bitdepth_max) - 10;
#endif
    const int scale = params->scale;
    assert(scale == 5 || scale == 8);

    uint16_t grad[2][32][4];
    uint16_t row_buffers[13][REST_UNIT_STRIDE]; // Normalized to 10-bit
    int32_t bias[32];
    uint8_t cls[32];
    uint16_t *bak_rows[13];
    const uint16_t *ptrs[13];

    for (int i = 0; i < 13; i++)
        bak_rows[i] = row_buffers[i] + 6;

    gdf_backup_row(bak_rows[6], p, left[0], w, edges HBD_SHIFT);
    ptrs[6] = bak_rows[6];
    if (edges & LR_HAVE_TOP_INTEGRATED) {
        for (int n = 0; n < 6; n++) {
            gdf_backup_row_lpf(bak_rows[n], lpf + n * PXSTRIDE(stride), w, edges HBD_SHIFT);
            ptrs[n] = bak_rows[n];
        }
    } else if (edges & LR_HAVE_TOP) {
        // y = -2,-1
        gdf_backup_row_lpf(bak_rows[4], lpf, w, edges HBD_SHIFT);
        ptrs[4] = bak_rows[4];
        gdf_backup_row_lpf(bak_rows[5], lpf + PXSTRIDE(stride), w, edges HBD_SHIFT);
        ptrs[5] = bak_rows[5];

        // y = -3,-4,-5,-6
        ptrs[0] = ptrs[1] = ptrs[2] = ptrs[3] = ptrs[4];
    } else {
        ptrs[0] = ptrs[1] = ptrs[2] = ptrs[3] = ptrs[4] = ptrs[5] = ptrs[6];
    }

    int bak_idx = 7;
    for (int y = 1; y < 6; y++, bak_idx++) {
        gdf_backup_row(bak_rows[bak_idx], p + y * PXSTRIDE(stride), left[y], w, edges HBD_SHIFT);
        ptrs[bak_idx] = bak_rows[bak_idx];
    }

    compute_gradient_row(grad[1], &ptrs[6], w);

    for (int y = 0; y < h; y++) {
        if (y + 6 < h) {
            gdf_backup_row(bak_rows[bak_idx], p + 6*PXSTRIDE(stride), left[y + 6], w, edges HBD_SHIFT);
            ptrs[12] = bak_rows[bak_idx];
        } else if (edges & LR_HAVE_BOTTOM_INTEGRATED) {
            gdf_backup_row_lpf(bak_rows[bak_idx], p + 6*PXSTRIDE(stride), w, edges HBD_SHIFT);
            ptrs[12] = bak_rows[bak_idx];
        } else if (y + 4 < h && edges & LR_HAVE_BOTTOM) {
            int offset_y = y + 6 - h;
            assert(offset_y < 2);
            gdf_backup_row_lpf(bak_rows[bak_idx], lpf_bottom + offset_y * PXSTRIDE(stride), w, edges HBD_SHIFT);
            ptrs[12] = bak_rows[bak_idx];
        } else {
            ptrs[12] = ptrs[11];
        }
        if (++bak_idx == 13) bak_idx = 0;
        if ((y & 1) == 0) {
            // Compute gradients over a 4x4 region
            compute_gradient_row(grad[(y & 2) >> 1], &ptrs[8], w);
            for (int x = 0; x < (w >> 1); x++) {
                uint16_t grad_sums[4];
                bias[x] = params->bias[2];
                for (int d = 0; d < 4; d++) {
                    grad_sums[d] = grad[0][x][d] + grad[1][x][d];
                    const int v = imin(grad_sums[d] >> 4, params->gradient_alpha[d]);
                    bias[x] += v * params->gradient_weight[d];
                }
                cls[x] = (grad_sums[0] <= grad_sums[1]) | ((grad_sums[2] <= grad_sums[3]) << 1);
            }
        }

        for (int x1 = 0; x1 < (w >> 1); x1++) {
            const int filter_class = cls[x1];
            for (int x2 = 0; x2 < 2; x2++) {
                int idx_vals[3] = { params->bias[0], params->bias[1], bias[x1] };
                const int x = x1 * 2 + x2;
                const int m = ptrs[6][x];

                #define SWAP_PAIR_IF_CLS(c, a0, a1, b0, b1) \
                do {                                        \
                    if (filter_class & c) {                 \
                        int tmp = a0; a0 = b0; b0 = tmp;    \
                            tmp = a1; a1 = b1; b1 = tmp;    \
                    }                                       \
                } while (0)

                // { 1, 0 }, { 0, 1 } .. { 6, 0 }, { 0, 6 }
                for (int k = 0; k < 6; k++) {
                    int above = ptrs[5 - k][x];
                    int below = ptrs[7 + k][x];
                    int left  = ptrs[6][x - k - 1];
                    int right = ptrs[6][x + k + 1];
                    SWAP_PAIR_IF_CLS(1, above, below, left, right);
                    const int sum_v = gdf_sum(above, below, params->alpha[k][0], m);
                    const int sum_h = gdf_sum(left,  right, params->alpha[k][1], m);
                    if (k < 2) {
                        for (int idx = 0; idx < 3; idx++)
                            idx_vals[idx] += sum_v * params->weight1[k * 3 + idx][0] +
                                             sum_h * params->weight1[k * 3 + idx][1];
                    } else {
                        idx_vals[0] += sum_v * params->weight2[0][k - 2];
                        idx_vals[1] += sum_h * params->weight2[1][k - 2];
                        if (k == 2)
                            idx_vals[2] += sum_v * params->weight1[6][0] +
                                           sum_h * params->weight1[6][1];
                    }
                }

                // { 1, 1 }, { 1, -1 }
                {
                    int tl = ptrs[5][x - 1];
                    int br = ptrs[7][x + 1];
                    int tr = ptrs[5][x + 1];
                    int bl = ptrs[7][x - 1];
                    SWAP_PAIR_IF_CLS(2, tl, br, tr, bl);
                    const int sum_dr = gdf_sum(tl, br, params->alpha[6][0], m);
                    const int sum_dl = gdf_sum(tr, bl, params->alpha[6][1], m);
                    idx_vals[0] += sum_dr * params->weight3[0][0] +
                                   sum_dl * params->weight3[0][1];
                    idx_vals[1] += sum_dr * params->weight3[1][0] +
                                   sum_dl * params->weight3[1][1];
                }

                // { 1, 2 }, { 1, -2 }, { 2, 1 }, { 2, -1 }
                {
                    int ttl = ptrs[4][x - 1];
                    int bbr = ptrs[8][x + 1];
                    int tll = ptrs[5][x - 2];
                    int brr = ptrs[7][x + 2];
                    int ttr = ptrs[4][x + 1];
                    int bbl = ptrs[8][x - 1];
                    int trr = ptrs[5][x + 2];
                    int bll = ptrs[7][x - 2];
                    SWAP_PAIR_IF_CLS(1, ttl, bbr, tll, brr);
                    SWAP_PAIR_IF_CLS(1, ttr, bbl, trr, bll);
                    SWAP_PAIR_IF_CLS(2, ttl, bbr, ttr, bbl);
                    SWAP_PAIR_IF_CLS(2, tll, brr, trr, bll);
                    const int sum_ddr = gdf_sum(ttl, bbr, params->alpha[7][0], m);
                    const int sum_ddl = gdf_sum(ttr, bbl, params->alpha[7][1], m);
                    const int sum_drr = gdf_sum(tll, brr, params->alpha[8][0], m);
                    const int sum_dll = gdf_sum(trr, bll, params->alpha[8][1], m);
                    idx_vals[0] += sum_ddr * params->weight4[0][0] +
                                   sum_ddl * params->weight4[0][1];
                    idx_vals[1] += sum_drr * params->weight4[1][0] +
                                   sum_dll * params->weight4[1][1];
                }

                int full_idx = 0;
                for (int idx = 0; idx < 3; idx++) {
                    int v = idx_vals[idx] * scale;
                    v = apply_sign((abs(v) + (1 << 14)) >> 15, v);
                    const int sub_idx = iclip(v, -scale, scale - 1) + scale;
                    full_idx = full_idx * scale * 2 + sub_idx;
                }
                dst[x] = params->error_lut[full_idx];
            }
        }

        for (int r = 0; r < 12; r++) ptrs[r] = ptrs[r+1];
        dst += 64;
        p += PXSTRIDE(stride);
    }
}

static void gdf_add_c(pixel *p_line, const ptrdiff_t stride,
                      const int8_t *err_line, const uint16_t (*const ll_mask)[4],
                      const int w, const int h, const int scale HIGHBD_DECL_SUFFIX)
{
    assert(w > 0 && w <= 64 && !(w & 7));
    assert(h > 0 && h <= 64 && !(h & 7));
    assert(scale > 0 && scale <= 4);
    const int shift = 12 - bitdepth_from_max(bitdepth_max);
    const int rnd = 1 << shift >> 1;
    for (int by = 0; by < h >> 2; by++) {
        for (int bx = 0; bx < w >> 2; bx++) {
            if (ll_mask[by][0] & (1 << bx)) continue;
            pixel *p = p_line;
            const int8_t *err = err_line;
            for (int y = by * 4; y < by * 4 + 4; y++) {
                for (int x = bx * 4; x < bx * 4 + 4; x++) {
                    int diff = err[x] * scale;
                    p[x] = iclip_pixel(p[x] + apply_sign((abs(diff) + rnd) >> shift, diff));
                }
                p += PXSTRIDE(stride);
                err += 64;
            }
        }
        p_line += PXSTRIDE(stride) * 4;
        err_line += 64 * 4;
    }
}

#if HAVE_ASM
#if ARCH_AARCH64 || ARCH_ARM
#include "src/arm/looprestoration.h"
#elif ARCH_X86
#include "src/x86/looprestoration.h"
#endif
#endif

COLD void bitfn(dav2d_loop_restoration_dsp_init)(Dav2dLoopRestorationDSPContext *const c) {
    c->ns_wiener_single = ns_wiener_single_y_c;
    c->ns_wiener_multi = ns_wiener_multi_c;
    c->pc_wiener = pc_wiener_c;
    c->wiener_uv_luma[0] = wiener_uv_luma_444_c;
    c->wiener_uv_luma[1] = wiener_uv_luma_422_c;
    c->wiener_uv_luma[2] = wiener_uv_luma_420_c;
    c->wiener_uv_chroma = wiener_uv_chroma_c;

    c->gdf_add = gdf_add_c;
    c->gdf_prep = gdf_prep_c;

#if HAVE_ASM
#if ARCH_AARCH64 || ARCH_ARM
    looprestoration_dsp_init_arm(c);
#elif ARCH_X86
    loop_restoration_dsp_init_x86(c);
#endif
#endif
}
