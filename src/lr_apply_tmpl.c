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

#include <string.h>

#include "common/attributes.h"
#include "common/intops.h"

#include "src/lr_apply.h"

enum FirstSbInTileRow {
    FIRST_SB_NONE = 0,
    FIRST_SB_TOP,
    FIRST_SB_BOTTOM,
};

static void lr_stripe(const Dav2dFrameContext *const f, pixel *const p[3],
                      const pixel (*left)[8],
                      const pixel (*const left_uv[2])[2],
                      const int x, int y, const int w, const int row_h,
                      const Av2RestorationUnit *const lr[3],
                      enum LrEdgeFlags edges,
                      const enum FirstSbInTileRow first_sby_in_tile_row,
                      const int tile_row_m1, const int restore_planes)
{
    pixel *ptrs[3] = { p[0], p[1], p[2] };
    const pixel (*left_uv_ptrs[2])[2] = { left_uv[0], left_uv[1] };
    const Dav2dDSPContext *const dsp = f->dsp;
    const enum Dav2dPixelLayout layout = f->cur.p.p.layout;
    const int ss_hor = layout != DAV2D_PIXEL_LAYOUT_I444;
    const int ss_ver = layout == DAV2D_PIXEL_LAYOUT_I420;
    const ptrdiff_t *const strides = f->cur.p.stride;
    const int by64 = (y + (y ? 8 : 0)) >> 6;
    const int uv_idx = DAV2D_PIXEL_LAYOUT_I444 - layout;
    const wienerfilter_uv_luma_fn wiener_uv_l_fn = dsp->lr.wiener_uv_luma[uv_idx];

    const pixel *lpf[3], *lpfb[3], *top[3];

    if ((edges & (LR_HAVE_TOP | LR_HAVE_TOP_INTEGRATED)) ==
                 (LR_HAVE_TOP | LR_HAVE_TOP_INTEGRATED))
    {
        top[0] = f->lf.lr_cdef_line[0] +
                 tile_row_m1 * 6 * PXSTRIDE(strides[0]) + x;
        const ptrdiff_t uv_off = tile_row_m1 * 2 * PXSTRIDE(strides[1]) +
                                 (x >> ss_hor);
        top[1] = f->lf.lr_cdef_line[1] + uv_off;
        top[2] = f->lf.lr_cdef_line[2] + uv_off;
    } else {
        top[0] = top[1] = top[2] = NULL;
    }

    if (f->c->n_tc > 1) {
        const int top_row = by64 * 4 - 4;
        lpf[0] = &f->lf.lr_db_line[0][top_row * PXSTRIDE(strides[0]) + x];
        lpfb[0] = lpf[0] + 6 * PXSTRIDE(strides[0]);
        const ptrdiff_t uv_off = top_row * PXSTRIDE(strides[1]) + (x >> ss_hor);
        lpf[1] = &f->lf.lr_db_line[1][uv_off];
        lpf[2] = &f->lf.lr_db_line[2][uv_off];
        lpfb[1] = lpf[1] + 6 * PXSTRIDE(strides[1]);
        lpfb[2] = lpf[2] + 6 * PXSTRIDE(strides[1]);
    } else {
        const int top_row = f->lf.top_lr_db_toggle * 4;
        const int bot_row = (!f->lf.top_lr_db_toggle * 4 + 2);
        const ptrdiff_t uv_off = top_row * PXSTRIDE(strides[1]) + (x >> ss_hor);
        const ptrdiff_t uv_off_bot = bot_row * PXSTRIDE(strides[1]) +
                                     (x >> ss_hor);
        lpf[0] = &f->lf.lr_db_line[0][top_row * PXSTRIDE(strides[0]) + x];
        lpfb[0] = &f->lf.lr_db_line[0][bot_row * PXSTRIDE(strides[0]) + x];
        lpf[1] = &f->lf.lr_db_line[1][uv_off];
        lpf[2] = &f->lf.lr_db_line[2][uv_off];
        lpfb[1] = &f->lf.lr_db_line[1][uv_off_bot];
        lpfb[2] = &f->lf.lr_db_line[2][uv_off_bot];
    }

    const int sb256x = x >> 8;
    const int sb64x_idx = (x >> 6) & 3;

    // The first stripe of the frame is shorter by 8 luma pixel rows.
    int stripe_h = imin(64 - 8 * !!first_sby_in_tile_row, row_h - y);

    const int8_t *uv_filter[2] = { NULL, NULL };
    const int ds_flt = f->seq_hdr->cfl_ds_filter_index;

    const int gdf_scale = f->frame_hdr->gdf.scale;
    wienerfilter_fn wiener_fn = NULL;
    WienerParams wiener_params;
    uint16_t noskip_mask[64 + 2];
    int multi_wiener = 0;
    // TODO: We copy from a 16x18 array. That array should be 16x16 in the first place.
    int8_t luma_filters[16][16];

    if (f->c->inloop_filters & DAV2D_INLOOPFILTER_WIENER) {
        for (int pl = 1; pl <= 2; pl++) {
            const struct Dav2dNSWienerPlane *const pd = &f->frame_hdr->restoration.p[pl].ns;
            if (restore_planes & (1 << pl) &&
                lr[pl]->type == DAV2D_RESTORATION_NS_WIENER)
            {
                if (pd->frame_filters_on)
                    uv_filter[pl - 1] = pd->filter[0];
                else
                    uv_filter[pl - 1] = lr[pl]->ns_filter[0];
            }
        }

        const struct Dav2dNSWienerPlane *const pd = &f->frame_hdr->restoration.p[0].ns;
        const enum Dav2dRestorationType wiener_type = lr[0]->type;

        if (wiener_type == DAV2D_RESTORATION_NS_WIENER) {
            if (pd->frame_filters_on) {
                if (pd->num_classes == 1) {
                    wiener_fn = dsp->lr.ns_wiener_single;
                    wiener_params.single.filter = pd->filter[0];
                } else {
                    multi_wiener = 1;
                    wiener_fn = dsp->lr.ns_wiener_multi;
                    wiener_params.multi.class_lut = f->lf.ns_subclass_lut;
                    wiener_params.multi.qval_approx =
                        &f->lf.wiener_qval_approx_data;
                    wiener_params.multi.filters.user = luma_filters;
                    for (int i = 0; i < 16; i++) {
                        memcpy(luma_filters[i], pd->filter[i], sizeof(luma_filters[i]));
                    }
                }
            } else {
                wiener_fn = dsp->lr.ns_wiener_single;
                wiener_params.single.filter = lr[0]->ns_filter[0];
            }
        } else if (wiener_type == DAV2D_RESTORATION_PC_WIENER) {
            multi_wiener = 1;
            wiener_fn = dsp->lr.pc_wiener;
            wiener_params.multi.class_lut = f->lf.pc_subclass_lut;
            wiener_params.multi.qval_approx = &f->lf.wiener_qval_approx_data;
            wiener_params.multi.filters.pretrained = f->lf.pc_filters;
        }

        if (multi_wiener) {
            wiener_params.multi.noskip_mask = noskip_mask;
            for (int by = y >> 2, r = 0; by < row_h >> 2; by++, r++) {
                int by_idx = by & 63;
                // TODO: add outer loop so we don't compute and offset by the same sb256_idx most iterations
                int sb256_idx = f->sb256w * (by >> 6) + sb256x;
                uint16_t* noskip_row = f->lf.mask[sb256_idx].lr_noskip_mask[by_idx];
                noskip_mask[r] = noskip_row[sb64x_idx];
                // extend masks on the right edge
                if (!(edges & LR_HAVE_RIGHT) && w & 63) {
                    const int shift = ((w >> 2) & 15) - 1;
                    const int mask = noskip_mask[r];
                    const int edge = mask >> shift;
                    noskip_mask[r] |= edge << (shift + 1);
                }
            }
        }
    }

    union {
        ALIGN(int8_t gdf_err[64 * 64], 64);
        ALIGN(coef uv_luma[64 * 64], 64);
    } scratch;
    while (y + stripe_h <= row_h) {
        // Change the HAVE_BOTTOM bit in edges to (by64 + 1 != f->sb64h || y + stripe_h != row_h)
        edges ^= (-(by64 + 1 != f->sb64h || y + stripe_h != row_h) ^ edges) & LR_HAVE_BOTTOM;
        const int inc =
            (edges & (LR_HAVE_TOP | LR_HAVE_TOP_INTEGRATED |
                      LR_HAVE_BOTTOM_INTEGRATED)) == LR_HAVE_TOP &&
            y + 8 < f->bh * 4 ? 8 : 0;
        const int sb256_idx = f->sb256w * ((y + inc) >> 8) + sb256x;
        const int y4 = (y & 255) >> 2;
        const int gdf = (f->c->inloop_filters & DAV2D_INLOOPFILTER_GDF) &&
                        f->lf.mask[sb256_idx].gdf[(((y + inc) >> 4) & 12) +
                                                  sb64x_idx];
        const uint16_t (*ll_mask_y)[4] = (const uint16_t(*)[4])
                &f->lf.mask[sb256_idx].lossless_mask_y[y4][sb64x_idx];

        const uint16_t (*ll_mask_uv)[4];
        uint16_t ll_uv_mask_mem[16][4];
        if (!ss_hor) {
            ll_mask_uv = (const uint16_t(*)[4])
                &f->lf.mask[sb256_idx].lossless_mask_uv[y4][sb64x_idx];
        } else {
            ll_mask_uv = (const uint16_t(*)[4])
                &f->lf.mask[sb256_idx].lossless_mask_uv[y4 >> ss_ver][sb64x_idx];
            const int end_y = stripe_h >> 2 >> ss_ver;
            for (int yy = 0; yy < end_y; yy++, ll_mask_uv++)
                ll_uv_mask_mem[yy][0] = ll_mask_uv[0][0] | (ll_mask_uv[0][1] << 8);
            ll_mask_uv = ll_uv_mask_mem;
        }
        for (int pl = 1; pl <= 2; pl++) {
            if (uv_filter[pl - 1]) {
                const pixel *top_ptr = top[0] ? top[0] : lpf[0];
                const pixel *top_uv_ptr = top[pl] ? top[pl] : lpf[pl];
                wiener_uv_l_fn(scratch.uv_luma, ptrs[0], strides[0], left,
                               top_ptr, lpfb[0], uv_filter[pl - 1],
                               w >> ss_hor, stripe_h >> ss_ver, ds_flt, edges
                               HIGHBD_CALL_SUFFIX);
                dsp->lr.wiener_uv_chroma(ptrs[pl], strides[1], left_uv_ptrs[pl - 1],
                                         top_uv_ptr, lpfb[pl], scratch.uv_luma,
                                         uv_filter[pl - 1], ll_mask_uv,
                                         w >> ss_hor, stripe_h >> ss_ver, edges
                                         HIGHBD_CALL_SUFFIX);
            }
        }
        if (gdf) {
            dsp->lr.gdf_prep(scratch.gdf_err, ptrs[0], strides[0], left,
                             top[0] ? top[0] : lpf[0], lpfb[0],
                             f->lf.gdf_params, w, stripe_h, edges
                             HIGHBD_CALL_SUFFIX);
        }
        if (wiener_fn) {
            wiener_fn(ptrs[0], strides[0], left,
                      top[0] ? top[0] + 2 * PXSTRIDE(strides[0]) : lpf[0],
                      lpfb[0], &wiener_params, ll_mask_y, w, stripe_h, edges
                      HIGHBD_CALL_SUFFIX);
            if (multi_wiener)
                wiener_params.multi.noskip_mask += stripe_h >> 2;
        }
        if (gdf) {
            dsp->lr.gdf_add(ptrs[0], strides[0], scratch.gdf_err, ll_mask_y, w,
                            stripe_h, gdf_scale HIGHBD_CALL_SUFFIX);
        }
        // this loop runs twice at the bottom of a frame, if e.g. the sequence
        // height is 128px, the first slice is 56px, followed by a 72px slice
        // which is iterated twice in this loop - one 64px and one 8px
        edges &= ~(LR_HAVE_BOTTOM_INTEGRATED | LR_HAVE_TOP_INTEGRATED);
        left += stripe_h;
        left_uv_ptrs[0] += stripe_h >> ss_ver;
        left_uv_ptrs[1] += stripe_h >> ss_ver;
        y += stripe_h;
        ptrs[0] += stripe_h * PXSTRIDE(strides[0]);
        ptrs[1] += (stripe_h >> ss_ver) * PXSTRIDE(strides[1]);
        ptrs[2] += (stripe_h >> ss_ver) * PXSTRIDE(strides[1]);
        edges |= LR_HAVE_TOP;
        stripe_h = imin(64, row_h - y);
        if (stripe_h == 0) break;
        lpf[0] = &lpfb[0][-2 * PXSTRIDE(strides[0])];
        lpf[1] = &lpfb[1][-2 * PXSTRIDE(strides[1])];
        lpf[2] = &lpfb[2][-2 * PXSTRIDE(strides[1])];
        top[0] = top[1] = top[2] = NULL;
    }
}

static void backup_left_uv(pixel (*dst)[2], const pixel *src,
                           const ptrdiff_t src_stride, int u)
{
    for (; u > 0; u--, dst++, src += PXSTRIDE(src_stride))
        pixel_copy(dst[0], src - 2, 2);
}

static void backupNxU(pixel (*dst)[8], const pixel *src, const ptrdiff_t src_stride,
                      int u, const int n)
{
    for (; u > 0; u--, dst++, src += PXSTRIDE(src_stride))
        pixel_copy(&dst[0][8 - n], src - n, n);
}

static void lr_sbrow(const Dav2dFrameContext *const f, pixel *const p[3],
                     const int y, const int w, const int h, const int row_h,
                     const enum FirstSbInTileRow first_sby_in_tile_row,
                     const int tile_row_m1, const int restore_planes)
{
    pixel *ptrs[3] = { p[0], p[1], p[2] };
    const int ss_ver = f->cur.p.p.layout == DAV2D_PIXEL_LAYOUT_I420;
    const int ss_hor = f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I444;
    const ptrdiff_t *const strides = f->cur.p.stride;

    const int unit_size[2] = {
        1 << f->frame_hdr->restoration.unit_size[0],
        1 << f->frame_hdr->restoration.unit_size[1]
    };

    // Y coordinate of the sbrow (y is 8 luma pixel rows above row_y)
    const int row_y = y + 8 * !first_sby_in_tile_row;

    const int shift_hor = 8 - ss_hor;
    const int stripe_w_uv = 64 >> ss_hor;

    /* maximum sbrow height is 256 + 8 rows offset */
    ALIGN_STK_16(pixel, pre_lr_border_uv, 2, [2][256 + 8][2]);
    const pixel (*const pre_lr_border_uv_ptrs[2][2])[2] = {
        { pre_lr_border_uv[0][0], pre_lr_border_uv[0][1] },
        { pre_lr_border_uv[1][0], pre_lr_border_uv[1][1] }
    };
    ALIGN_STK_16(pixel, pre_lr_border_y, 2, [256 + 8][8]);
    const Av2RestorationUnit *lr[2][3];

    enum LrEdgeFlags edges = (y > 0 ? LR_HAVE_TOP : 0) | LR_HAVE_RIGHT;
    if (first_sby_in_tile_row == FIRST_SB_TOP) edges |= LR_HAVE_BOTTOM_INTEGRATED;
    if (first_sby_in_tile_row == FIRST_SB_BOTTOM && y > 0) edges |= LR_HAVE_TOP_INTEGRATED;

    int aligned_unit_pos_y = row_y & ~(unit_size[0] - 1);
    if (aligned_unit_pos_y && aligned_unit_pos_y + (unit_size[0] >> 1) > h)
        aligned_unit_pos_y -= unit_size[0];
    int aligned_unit_pos_uv = (row_y >> ss_ver) & ~(unit_size[1] - 1);
    if (aligned_unit_pos_uv && aligned_unit_pos_uv + (unit_size[1] >> 1) > (h >> ss_ver))
        aligned_unit_pos_uv -= unit_size[1];
    aligned_unit_pos_uv <<= ss_ver;
    const int unit_idx[2] = {
        ((aligned_unit_pos_y >> 6) & 0x3) << 2,
        ((aligned_unit_pos_uv >> 6) & 0x3) << 2
    };
    const Av2Restoration *lr_mask_y = &f->lf.lr_mask[(aligned_unit_pos_y >> 8) * f->sb256w];
    const Av2Restoration *lr_mask_uv = &f->lf.lr_mask[(aligned_unit_pos_uv >> 8) * f->sb256w];
    lr[0][0] = &lr_mask_y->lr[0][unit_idx[0]];
    lr[0][1] = &lr_mask_uv->lr[1][unit_idx[1]];
    lr[0][2] = &lr_mask_uv->lr[2][unit_idx[1]];
    int restore = 1; // TODO: restore logic for disabling backups
    int x = 0, bit = 0;
    for (; x + 64 < w; edges |= LR_HAVE_LEFT, bit ^= 1) {
        const int next_x = x + 64;
        const int next_x_uv = next_x >> ss_hor;
        int next_iter_start_x[2] = {
            next_x & ~(unit_size[0] - 1),
            next_x_uv & ~(unit_size[1] - 1)
        };
        if (next_iter_start_x[0] && w - next_iter_start_x[0] < unit_size[0] >> 1)
            next_iter_start_x[0] -= unit_size[0];
        if (next_iter_start_x[1] && (w >> ss_hor) - next_iter_start_x[1] < unit_size[1] >> 1)
            next_iter_start_x[1] -= unit_size[1];
        const int next_u_idx[2] = {
            unit_idx[0] + ((next_iter_start_x[0] >> 6) & 3),
            unit_idx[1] + ((next_iter_start_x[1] >> (shift_hor - 2)) & 3),
        };
        const Av2Restoration *const next_rest_uv = &lr_mask_uv[next_iter_start_x[1] >> shift_hor];
        lr[!bit][0] = &lr_mask_y[next_iter_start_x[0] >> 8].lr[0][next_u_idx[0]];
        lr[!bit][1] = &next_rest_uv->lr[1][next_u_idx[1]];
        lr[!bit][2] = &next_rest_uv->lr[2][next_u_idx[1]];
        const int restore_next = 1;
        if (restore_next) {
            int rem_h = row_h - y;
            // FIXME could backup 4px for luma if gdf=off
            backupNxU(pre_lr_border_y[bit], ptrs[0] + 64, strides[0], rem_h, 8);
            if (restore_planes & LR_RESTORE_U)
                backup_left_uv(pre_lr_border_uv[bit][0], ptrs[1] + stripe_w_uv, strides[1], rem_h >> ss_ver);
            if (restore_planes & LR_RESTORE_V)
                backup_left_uv(pre_lr_border_uv[bit][1], ptrs[2] + stripe_w_uv, strides[1], rem_h >> ss_ver);
        }
        if (restore) {
            lr_stripe(f, ptrs, pre_lr_border_y[!bit],
                      pre_lr_border_uv_ptrs[!bit], x, y, 64, row_h, lr[bit],
                      edges, first_sby_in_tile_row, tile_row_m1,
                      restore_planes);
        }
        x = next_x;
        restore = restore_next;
        ptrs[0] += 64;
        ptrs[1] += stripe_w_uv;
        ptrs[2] += stripe_w_uv;
    }
    if (restore) {
        edges &= ~LR_HAVE_RIGHT;
        const int end_w = w - x;
        lr_stripe(f, ptrs, pre_lr_border_y[!bit], pre_lr_border_uv_ptrs[!bit],
                  x, y, end_w, row_h, lr[bit], edges, first_sby_in_tile_row,
                  tile_row_m1, restore_planes);
    }
}

static inline void copyNlines(pixel *dst, const pixel *src, const ptrdiff_t stride,
                              const int n)
{
    memcpy(dst, src, stride * n);
}

void bytefn(dav2d_lr_slice)(Dav2dFrameContext *const f, pixel *const dst[3],
                            const int by64)
{
    const int ss_ver = f->cur.p.p.layout == DAV2D_PIXEL_LAYOUT_I420;
    const int h = f->bh * 4;
    const int w = f->bw * 4;
    const ptrdiff_t *const dst_stride = f->cur.p.stride;
    const int restore_planes = f->lf.restore_planes;
    const int not_last = by64 + 1 < f->sb64h;
    const int sb128 = f->frame_hdr->sb128, sb64sz = 1 << sb128;
    int first_sby_in_tile_row = f->lf.start_of_tile_row[by64 >> sb128];
    const int tile_row = first_sby_in_tile_row >> 1;
    first_sby_in_tile_row &= !(by64 & (sb64sz - 1));
    const int next_row_y = (by64 + 1) << 6;
    const int row_h = imin(next_row_y - 8 * not_last, h);

    int offset_y = 8 * !!by64;
    int y_stripe = (by64 << 6) - offset_y;
    if (by64 && first_sby_in_tile_row) {
        pixel *ptrs[3] = {
            dst[0] - offset_y * PXSTRIDE(dst_stride[0]),
            dst[1] - (offset_y >> ss_ver) * PXSTRIDE(dst_stride[1]),
            dst[2] - (offset_y >> ss_ver) * PXSTRIDE(dst_stride[1]),
        };

        copyNlines(&f->lf.lr_cdef_line[0][6 * PXSTRIDE(dst_stride[0]) *
                                          (tile_row - 1)],
                   dst[0] - 6 * PXSTRIDE(dst_stride[0]), dst_stride[0], 6);
        if (restore_planes & LR_RESTORE_U)
            copyNlines(&f->lf.lr_cdef_line[1][2 * PXSTRIDE(dst_stride[1]) *
                                              (tile_row - 1)],
                       dst[1] - 2 * PXSTRIDE(dst_stride[1]), dst_stride[1], 2);
        if (restore_planes & LR_RESTORE_V)
            copyNlines(&f->lf.lr_cdef_line[2][2 * PXSTRIDE(dst_stride[1]) *
                                              (tile_row - 1)],
                       dst[2] - 2 * PXSTRIDE(dst_stride[1]), dst_stride[1], 2);
        lr_sbrow(f, ptrs, y_stripe, w, h, y_stripe + 8,
                 first_sby_in_tile_row * FIRST_SB_TOP, tile_row - 1,
                 restore_planes);

        offset_y = 0;
        y_stripe += 8;
    }

    pixel *ptrs[3] = {
        dst[0] - offset_y * PXSTRIDE(dst_stride[0]),
        dst[1] - (offset_y >> ss_ver) * PXSTRIDE(dst_stride[1]),
        dst[2] - (offset_y >> ss_ver) * PXSTRIDE(dst_stride[1]),
    };

    lr_sbrow(f, ptrs, y_stripe, w, h, row_h,
             first_sby_in_tile_row * FIRST_SB_BOTTOM, tile_row - 1,
             restore_planes);
}
