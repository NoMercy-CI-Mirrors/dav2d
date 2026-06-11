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

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "common/intops.h"

#include "src/db_apply.h"
#include "src/lr_apply.h"
#include "src/quantizer.h"

static unsigned deblock_quant_thr(const int hbd, const int qidx) {
    const int qmax = 255 + 48 * hbd;
    return (dav2d_dq_lookup(iclip(qidx, 0, qmax)) + 4) >> (3 + 6);
}

static unsigned deblock_side_thr(const int hbd, const int qidx) {
    const int bitdepth_min_8 = 2 * hbd;
    const int q_ind = iclip(qidx - 24 * bitdepth_min_8, 0, 296 - 1);
    const int side_thr = dav2d_deblock_side_thresholds[q_ind];
    return imax(side_thr + (1 << 4 >> bitdepth_min_8), 0) >> (5 - bitdepth_min_8);
}

static void init_deblock_thr_lut_y(const Dav2dFrameHeader *const frame_hdr,
                                   const int hbd, const int n_seg,
                                   const int dir, const int qidx,
                                   pixel lut[2][16])
{
    const int qmax = 255 + 48 * hbd;
    for (int i = 0; i < n_seg; i++) {
        const int yac = frame_hdr->segmentation.enabled ?
            iclip(qidx + frame_hdr->segmentation.d.delta_q[i], 0, qmax) : qidx;
        const int dir_yac = yac + 8 * frame_hdr->deblock.delta_q_y[dir];
        lut[0][i] = deblock_quant_thr(hbd, dir_yac);
        lut[1][i] = deblock_side_thr(hbd, dir_yac);
    }
}

static void init_deblock_thr_lut_uv(const Dav2dFrameHeader *const frame_hdr,
                                    const int hbd, const int n_seg,
                                    const int qidx, pixel lut[2][2][16])
{
    const int qmax = 255 + 48 * hbd;
    for (int i = 0; i < n_seg; i++) {
        const int yac = frame_hdr->segmentation.enabled ?
            iclip(qidx + frame_hdr->segmentation.d.delta_q[i], 0, qmax) : qidx;
        const int uac = yac + frame_hdr->quant.uac_delta +
                        8 * frame_hdr->deblock.delta_q_u;
        lut[0][0][i] = deblock_quant_thr(hbd, uac);
        lut[0][1][i] = deblock_side_thr(hbd, uac);
        const int vac = yac + frame_hdr->quant.vac_delta +
                        8 * frame_hdr->deblock.delta_q_v;
        lut[1][0][i] = deblock_quant_thr(hbd, vac);
        lut[1][1][i] = deblock_side_thr(hbd, vac);
    }
}

// The deblock buffer stores 12 rows of pixels. A superblock block will
// contain at most 2 stripes. Each stripe requires 4 rows pixels (2 above
// and 2 below) the final 4 rows are used to swap the bottom of the last
// stripe with the top of the next super block row.
static void backup_db(const Dav2dFrameContext *const f,
                      pixel *dst, const pixel *src, const ptrdiff_t stride,
                      const int ss_ver, int y64, const int w)
{
    // The first stripe of the frame is shorter by 8 luma pixel rows.
    src += ((56 >> ss_ver) - 2) * PXSTRIDE(stride);
    if (y64 * 64 + 56 < f->bh * 4) {
        for (int i = 0; i < 4; i++) {
            pixel_copy(dst, src, w);
            dst += PXSTRIDE(stride);
            src += PXSTRIDE(stride);
        }
    }
}

void bytefn(dav2d_copy_db_slice)(Dav2dFrameContext *const f,
                                 /*const*/ pixel *const src[3], const int y64)
{
    const int have_tt = f->c->n_tc > 1;
    const ptrdiff_t *const stride = f->cur.p.stride;
    const int tt_off = (have_tt ? y64 : f->lf.top_lr_db_toggle) * 4;
    pixel *const dst[3] = {
        f->lf.lr_db_line[0] + tt_off * PXSTRIDE(stride[0]),
        f->lf.lr_db_line[1] + tt_off * PXSTRIDE(stride[1]),
        f->lf.lr_db_line[2] + tt_off * PXSTRIDE(stride[1])
    };

    // TODO Also check block level restore type to reduce copying.
    const int restore_planes = f->lf.restore_planes;

    if (f->seq_hdr->cdef || restore_planes & LR_RESTORE_Y) {
        const int w = f->bw << 2;
        backup_db(f, dst[0], src[0], stride[0], 0, y64, w);
    }
    if ((f->seq_hdr->cdef || restore_planes & (LR_RESTORE_U | LR_RESTORE_V)) &&
        f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I400)
    {
        const int ss_ver = f->cur.p.p.layout == DAV2D_PIXEL_LAYOUT_I420;
        const int ss_hor = f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I444;
        const int w = f->bw << (2 - ss_hor);
        if (f->seq_hdr->cdef || restore_planes & LR_RESTORE_U) {
            backup_db(f, dst[1], src[1], stride[1], ss_ver, y64, w);
        }
        if (f->seq_hdr->cdef || restore_planes & LR_RESTORE_V) {
            backup_db(f, dst[2],  src[2], stride[1], ss_ver, y64, w);
        }
    }

    if (f->c->n_tc == 1)
        f->lf.top_lr_db_toggle ^= 1;
}

static void transpose_lossless_mask(uint16_t dst_mask[17],
                                    const uint16_t (*const src_mask)[4],
                                    const int x64,
                                    const int ss_hor, const int ss_ver)
{
    // copy previous sb column
    dst_mask[0] = dst_mask[16 >> ss_hor];

    // transpose the original mask
    // TODO: Use a faster bit matrix transpose implementation
    for (int x = 0; x < 16 >> ss_hor; x++) {
        unsigned col_mask = 0;
        for (int y = 0; y < 16 >> ss_ver; y++) {
            col_mask |= (1 & (src_mask[y][x64] >> x)) << y;
        }
        dst_mask[x+1] = col_mask;
    }
}

static inline void filter_plane_cols_y(const Dav2dFrameContext *const f,
                                       const int have_left,
                                       const uint16_t (*const mask)[5][4],
                                       const uint16_t (*const ll_mask),
                                       const pixel (*thr)[16 * 16],
                                       pixel *dst, const ptrdiff_t ls,
                                       const int w4, const int h4, int tile_edge)
{
    const Dav2dDSPContext *const dsp = f->dsp;

    // filter edges between columns (e.g. block1 | block2)
    const pixel *q_thr = thr[0], *side_thr = thr[1];
    for (int x = 0; x < w4; x++, q_thr += 16, side_thr += 16) {
        if (!have_left && !x) continue;
        uint16_t hmask[4] = {
            mask[x][0][0], mask[x][1][0], mask[x][2][0], mask[x][3][0]
        };
        dsp->lf.deblock_sb[0][0](&dst[x * 4], ls, hmask, ll_mask + x,
                                 q_thr, side_thr, tile_edge, h4
                                 HIGHBD_CALL_SUFFIX);
        tile_edge = 0;
    }
}

static inline void filter_plane_rows_y(const Dav2dFrameContext *const f,
                                       const int have_top,
                                       const uint16_t (*const mask)[5][4],
                                       const uint16_t (*const ll_mask),
                                       const pixel (*thr)[16 * 16],
                                       pixel *dst, const ptrdiff_t ls,
                                       const int w4, const int h4)
{
    const Dav2dDSPContext *const dsp = f->dsp;

    //                                 block1
    // filter edges between rows (e.g. ------)
    //                                 block2
    const pixel *q_thr = thr[0], *side_thr = thr[1];
    for (int y = 0; y < h4;
         y++, dst += 4 * PXSTRIDE(ls), q_thr += 16, side_thr += 16)
    {
        if (!have_top && !y) continue;
        const uint16_t vmask[4] = {
            mask[y][0][0], mask[y][1][0], mask[y][2][0], mask[y][3][0]
        };
        dsp->lf.deblock_sb[0][1](dst, ls, vmask, ll_mask + y,
                                 q_thr, side_thr, !y, w4
                                 HIGHBD_CALL_SUFFIX);
    }
}

static inline void filter_plane_cols_uv(const Dav2dFrameContext *const f,
                                        const int have_left,
                                        const uint16_t (*const mask)[5][4],
                                        const uint16_t (*const ll_mask),
                                        const pixel (*thr)[2][16 * 16],
                                        pixel *const u, pixel *const v,
                                        const ptrdiff_t ls,
                                        const int w4, const int h4,
                                        int tile_edge, const int ss_ver)
{
    const Dav2dDSPContext *const dsp = f->dsp;
    const int apply_u = f->frame_hdr->deblock.level_u;
    const int apply_v = f->frame_hdr->deblock.level_v;

    // filter edges between columns (e.g. block1 | block2)
    const pixel *u_q_thr = thr[0][0], *u_side_thr = thr[0][1];
    const pixel *v_q_thr = thr[1][0], *v_side_thr = thr[1][1];
    for (int x = 0; x < w4; x++, u_q_thr += 16, u_side_thr += 16,
                                 v_q_thr += 16, v_side_thr += 16)
    {
        if (!have_left && !x) continue;
        uint16_t hmask[3] = {
            mask[x][0][0], mask[x][1][0], mask[x][2][0],
        };
        if (apply_u)
            dsp->lf.deblock_sb[1][0](&u[x * 4], ls, hmask, ll_mask + x,
                                     u_q_thr, u_side_thr, tile_edge, h4
                                     HIGHBD_CALL_SUFFIX);
        if (apply_v)
            dsp->lf.deblock_sb[1][0](&v[x * 4], ls, hmask, ll_mask + x,
                                     v_q_thr, v_side_thr, tile_edge, h4
                                     HIGHBD_CALL_SUFFIX);
        tile_edge = 0;
    }
}

static inline void filter_plane_rows_uv(const Dav2dFrameContext *const f,
                                        const int have_top,
                                        const uint16_t (*const mask)[5][4],
                                        const uint16_t (*const ll_mask),
                                        const pixel (*thr)[2][16 * 16],
                                        pixel *const u, pixel *const v,
                                        const ptrdiff_t ls,
                                        const int w4, const int h4,
                                        const int ss_hor)
{
    const Dav2dDSPContext *const dsp = f->dsp;
    ptrdiff_t off_l = 0;
    const int apply_u = f->frame_hdr->deblock.level_u;
    const int apply_v = f->frame_hdr->deblock.level_v;

    //                                 block1
    // filter edges between rows (e.g. ------)
    //                                 block2
    const pixel *u_q_thr = thr[0][0], *u_side_thr = thr[0][1];
    const pixel *v_q_thr = thr[1][0], *v_side_thr = thr[1][1];
    for (int y = 0; y < h4; y++, off_l += 4 * PXSTRIDE(ls),
                            u_q_thr += 16, u_side_thr += 16,
                            v_q_thr += 16, v_side_thr += 16)
    {
        if (!have_top && !y) continue;
        const uint16_t vmask[3] = {
            mask[y][0][0], mask[y][1][0], mask[y][2][0]
        };
        if (apply_u)
            dsp->lf.deblock_sb[1][1](&u[off_l], ls, vmask, ll_mask + y,
                                     u_q_thr, u_side_thr, !y, w4
                                     HIGHBD_CALL_SUFFIX);
        if (apply_v)
            dsp->lf.deblock_sb[1][1](&v[off_l], ls, vmask, ll_mask + y,
                                     v_q_thr, v_side_thr, !y, w4
                                     HIGHBD_CALL_SUFFIX);
    }
}

static const uint16_t placeholder_ll_mask[17] = { 0 };

void bytefn(dav2d_deblock_slice_cols)(const Dav2dFrameContext *const f,
                                      pixel *const p[3], Av2Filter *const lflvl,
                                      int y64, const int start_of_tile_row)
{
    int x64, have_left;
    const int sb128 = f->frame_hdr->sb128;
    const int starty4 = (y64 * 16) & 0x30;
    const int sbl2 = 4 + f->frame_hdr->sb128;
    const int halign = (f->bh + 63) & ~63;
    const int ss_ver = f->cur.p.p.layout == DAV2D_PIXEL_LAYOUT_I420;
    const int ss_hor = f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I444;
    const int h4 = imin(f->bh - y64 * 16, 16);
    const int uv_h4 = h4 >> ss_ver;
    const int hbd = f->seq_hdr->hbd;

    const int y64idx = (y64 & 3) << 2;

    const ptrdiff_t seg_stride = f->cur_segmap ? f->b4_stride : 0;
    const uint8_t *const segmap =
        f->cur_segmap ? &f->cur_segmap[y64 * 16 * seg_stride] : NULL;

    // fix lpf strength at tile col boundaries
    if (f->frame_hdr->tip.frame_mode != 2) {
        const uint8_t *lpf_y = &f->lf.tx_db_right_edge[0][y64 * 16];
        const uint8_t *lpf_uv = &f->lf.tx_db_right_edge[1][y64 * 16 >> ss_ver];
        for (int tile_col = 1;; tile_col++) {
            const int sbx = f->frame_hdr->tiling.t.col_start_sb[tile_col];
            if ((sbx << sbl2) >= f->bw) break;
            const int bx4 = (sbx << sbl2) & 0x30, cbx4 = bx4 >> ss_hor;
            const int x256 = sbx >> (2 - sb128);

            uint16_t (*const y_hmask)[4] = lflvl[x256].filter_y[0][bx4];
            int sidx = y64 & 3;
            for (int y4 = 0; y4 < h4; y4++) {
                const unsigned smask = 1 << y4;
                const int idx = 3 * !!(y_hmask[3][sidx] & smask) +
                                2 * !!(y_hmask[2][sidx] & smask) +
                                !!(y_hmask[1][sidx] & smask);
                y_hmask[3][sidx] &= ~smask;
                y_hmask[2][sidx] &= ~smask;
                y_hmask[1][sidx] &= ~smask;
                y_hmask[0][sidx] &= ~smask;
                y_hmask[imin(idx, lpf_y[y4])][sidx] |= smask;
            }
            lpf_y += halign;

            if (f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I400) {
                uint16_t (*const uv_hmask)[4] = lflvl[x256].filter_uv[0][cbx4];
                sidx = y64 & 3;
                for (int y4 = 0; y4 < uv_h4; y4++) {
                    const unsigned smask = 1 << y4;
                    const int idx = 2 * !!(uv_hmask[2][sidx] & smask) +
                                    !!(uv_hmask[1][sidx] & smask);
                    uv_hmask[2][sidx] &= ~smask;
                    uv_hmask[1][sidx] &= ~smask;
                    uv_hmask[0][sidx] &= ~smask;
                    uv_hmask[imin(idx, lpf_uv[y4])][sidx] |= smask;
                }
            }
            lpf_uv += halign >> ss_ver;
        }

        // fix lpf strength at tile row boundaries
        if (start_of_tile_row) {
            const BlockContext *a;
            int x256;
            const int uv_submask = 0xf >> ss_hor;
            for (x256 = 0, a = &f->a[f->sb256w * (start_of_tile_row - 1)];
                 x256 < f->sb256w; x256++, a++)
            {
                uint16_t (*const y_vmask)[4] = lflvl[x256].filter_y[1][starty4];
                const int w = imin(64, f->bw - (x256 << 6));
                for (int i = 0; i < w; i++) {
                    const int sidx = i >> 4;
                    const unsigned smask = 1 << (i & 0xf);
                    const int idx = 3 * !!(y_vmask[3][sidx] & smask) +
                                    2 * !!(y_vmask[2][sidx] & smask) +
                                        !!(y_vmask[1][sidx] & smask);
                    y_vmask[3][sidx] &= ~smask;
                    y_vmask[2][sidx] &= ~smask;
                    y_vmask[1][sidx] &= ~smask;
                    y_vmask[0][sidx] &= ~smask;
                    y_vmask[imin(idx, a->tx_lpf_y[i])][sidx] |= smask;
                }

                if (f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I400) {
                    const int cw = w >> ss_hor;
                    uint16_t (*const uv_vmask)[4] = lflvl[x256].filter_uv[1][starty4 >> ss_ver];
                    for (int i = 0; i < cw; i++) {
                        const int sidx = i >> (4 - ss_hor);
                        const unsigned smask = 1 << (i & uv_submask);
                        const int idx = 2 * !!(uv_vmask[2][sidx] & smask) +
                                        !!(uv_vmask[1][sidx] & smask);
                        uv_vmask[2][sidx] &= ~smask;
                        uv_vmask[1][sidx] &= ~smask;
                        uv_vmask[0][sidx] &= ~smask;
                        uv_vmask[imin(idx, a->tx_lpf_uv[i])][sidx] |= smask;
                    }
                }
            }
        }
    }

    // Crop deblock size on the bottom of the frame
    if ((y64 + 1) * 16 + 4 > f->bh) {
        // For luma, we crop 32 long tx edges that overhang by 24 pixels.
        // Frame dimensions are multiples of 8 so we only need to crop a single row.
        const int luma_crop_y4 = starty4 + h4 - 2;

        // check if this was handled by the previous sb row
        if (luma_crop_y4 >= 0) {
            for (int x256 = 0; x256 < f->sb256w; x256++) {
                const int w = imin(64, f->bw - (x256 << 6));
                uint16_t (*const y_vmask)[4] = lflvl[x256].filter_y[1][luma_crop_y4];
                for (int i = 0; i < (w + 15) >> 4; i++) {
                    unsigned mask = y_vmask[3][i];
                    y_vmask[3][i] = 0;
                    y_vmask[2][i] |= mask;
                }
            }
        }
    }

    const int any_ll = f->frame_hdr->any_lossless;
    const int seg = f->frame_hdr->segmentation.enabled;
    const int by64 = y64 & 3;
    const Dav2dDSPContext *const dsp = f->dsp;
    if (f->frame_hdr->deblock.level_y[0]) {
        int l_qidx = -1; // left q_idx
        pixel lut[2][16];
        ALIGN_STK_64(pixel, edge_thr, 2, [16 * 16]);
        pixel left_thr[2][16] = {{ 0 }};
        uint16_t ll_mask_mem[17];
        ll_mask_mem[0] = 0;
        const uint16_t *const ll_mask = any_ll ? ll_mask_mem : placeholder_ll_mask;
        pixel *ptr;
        int tile_col = 1;
        int tile_end = f->frame_hdr->tiling.t.col_start_sb[tile_col] << sbl2;
        for (ptr = p[0], have_left = 0, x64 = 0; x64 < (f->bw + 15) >> 4;
             x64++, have_left = 1, ptr += 64)
        {
            if (x64 * 16 > tile_end) {
                tile_col++;
                tile_end = f->frame_hdr->tiling.t.col_start_sb[tile_col] << sbl2;
            }

            const Av2Filter *const col_lflvl = &lflvl[x64 >> 2];
            const int bx64 = x64 & 3;
            const int cur_qidx = col_lflvl->qidx[bx64 + y64idx];
            if (cur_qidx != l_qidx)
                init_deblock_thr_lut_y(f->frame_hdr, hbd, f->n_seg,
                                       0, cur_qidx, lut);

            const int bx4 = bx64 * 16;
            const int w4 = imin(f->bw - x64 * 16, 16);
            const uint16_t (*masks)[5][4] =
                (const uint16_t(*)[5][4]) &col_lflvl->filter_y[0][bx4][0][by64];
            if (seg) {
                assert(segmap);
                dsp->lf.setup_thr_sb_seg[0](edge_thr, &segmap[x64 * 16],
                                            seg_stride, masks, lut,
                                            left_thr, w4, h4);
            } else if (cur_qidx != l_qidx) {
                dsp->lf.setup_thr_sb_dq[0](edge_thr, masks, lut,
                                           w4, h4, left_thr);
            } else {
                dsp->lf.setup_thr_sb_simple(edge_thr, masks, lut, w4, h4);
            }
            l_qidx = cur_qidx;
            if (any_ll)
                transpose_lossless_mask(ll_mask_mem,
                                        &col_lflvl->lossless_mask_y[starty4],
                                        bx64, 0, 0);
            filter_plane_cols_y(f, have_left, masks,
                                ll_mask, edge_thr, ptr, f->cur.p.stride[0],
                                w4, h4, tile_end == x64 * 16);
        }
    }

    if (!f->frame_hdr->deblock.level_u && !f->frame_hdr->deblock.level_v)
        return;

    int prev_qidx = -1;
    pixel lut[2][2][16];
    const ptrdiff_t uv_seg_stride = f->lf.segmap_uv ? f->lf.uv_segmap_stride : 0;
    const uint8_t *const uv_segmap =
        f->lf.segmap_uv ? &f->lf.segmap_uv[y64 * (16 >> ss_ver) * uv_seg_stride] : NULL;
    ALIGN_STK_64(pixel, edge_thr, 2, [2][16 * 16]);
    pixel left_thr[2][2][16] = {{{ 0 }}};
    uint16_t ll_mask_mem[17];
    ll_mask_mem[0] = 0;
    const uint16_t *const ll_mask = any_ll ? ll_mask_mem : placeholder_ll_mask;
    ptrdiff_t uv_off;
    int tile_col = 1;
    int tile_end = f->frame_hdr->tiling.t.col_start_sb[tile_col] << sbl2;
    for (uv_off = 0, have_left = 0, x64 = 0; x64 < (f->bw + 15) >> 4;
         x64++, have_left = 1, uv_off += 64 >> ss_hor)
    {
        if (x64 * 16 > tile_end) {
            tile_col++;
            tile_end = f->frame_hdr->tiling.t.col_start_sb[tile_col] << sbl2;
        }

        const Av2Filter *const col_lflvl = &lflvl[x64 >> 2];
        const int bx64 = x64 & 3;
        const int cur_qidx = col_lflvl->qidx[bx64 + y64idx];
        if (cur_qidx != prev_qidx)
            init_deblock_thr_lut_uv(f->frame_hdr, hbd, f->n_seg, cur_qidx, lut);

        const int bx4ss = bx64 * 16 >> ss_hor;
        const int uv_w4 = imin(f->bw - x64 * 16, 16) >> ss_hor;
        const uint16_t (*masks)[5][4] =
            (const uint16_t(*)[5][4]) &col_lflvl->filter_uv[0][bx4ss][0][by64];
        if (seg) {
            assert(uv_segmap);
            const uint8_t *const col_seg = &uv_segmap[x64 * (16 >> ss_hor)];
            for (int pl = 0; pl < 2; pl++)
                dsp->lf.setup_thr_sb_seg[0](edge_thr[pl], col_seg,
                                            uv_seg_stride, masks,
                                            lut[pl], left_thr[pl],
                                            uv_w4, uv_h4);
        } else if (prev_qidx != cur_qidx) {
            for (int pl = 0; pl < 2; pl++)
                dsp->lf.setup_thr_sb_dq[0](edge_thr[pl], masks, lut[pl],
                                           uv_w4, uv_h4, left_thr[pl]);
        } else {
            for (int pl = 0; pl < 2; pl++)
                dsp->lf.setup_thr_sb_simple(edge_thr[pl], masks,
                                            lut[pl], uv_w4, uv_h4);
        }
        prev_qidx = cur_qidx;
        if (any_ll)
            transpose_lossless_mask(ll_mask_mem,
                                    &col_lflvl->lossless_mask_uv[starty4 >> ss_ver],
                                    bx64, ss_hor, ss_ver);
        filter_plane_cols_uv(f, have_left, masks, ll_mask, edge_thr,
                             &p[1][uv_off], &p[2][uv_off], f->cur.p.stride[1],
                             uv_w4, uv_h4, tile_end == x64 * 16, ss_ver);
    }
}

void bytefn(dav2d_deblock_slice_rows)(const Dav2dFrameContext *const f,
                                      pixel *const p[3], Av2Filter *const lflvl,
                                      int y64)
{
    int x64;
    // Don't filter outside the frame
    const int have_top = y64 > 0;
    const int starty4 = (y64 * 16) & 0x30;
    const int ss_ver = f->cur.p.p.layout == DAV2D_PIXEL_LAYOUT_I420;
    const int ss_hor = f->cur.p.p.layout != DAV2D_PIXEL_LAYOUT_I444;
    const int h4 = imin(f->bh - y64 * 16, 16);
    const int uv_h4 = h4 >> ss_ver;
    const int hbd = f->seq_hdr->hbd;

    const int y64idx = (y64 & 3) << 2;
    const Av2Filter *const a_lflvl = have_top ? &lflvl[-f->sb256w * (starty4 == 0)] : NULL;
    const int a_y64idx = ((y64 + 3) & 3) << 2;

    const ptrdiff_t seg_stride = f->cur_segmap ? f->b4_stride : 0;
    const uint8_t *const segmap =
        f->cur_segmap ? &f->cur_segmap[y64 * 16 * seg_stride] : NULL;

    const int any_ll = f->frame_hdr->any_lossless;
    const int seg = f->frame_hdr->segmentation.enabled;
    const Dav2dDSPContext *const dsp = f->dsp;
    if (f->frame_hdr->deblock.level_y[1]) {
        pixel *ptr;
        int l_qidx = -1, al_qidx = -1; // left and above left
        pixel lut[2][16];
        pixel a_lut[2][16];
        pixel (*const a_lut_ptr)[16] = a_lflvl ? a_lut : NULL;
        ALIGN_STK_64(pixel, edge_thr, 2, [16 * 16]);
        uint16_t ll_mask_mem[17];
        ll_mask_mem[0] = 0;
        const uint16_t *const ll_mask = any_ll ? ll_mask_mem : placeholder_ll_mask;

        for (ptr = p[0], x64 = 0; x64 < (f->bw + 15) >> 4; x64++, ptr += 64) {
            const Av2Filter *const col_lflvl = &lflvl[x64 >> 2];

            const int bx64 = x64 & 3;
            if (any_ll)
                for (int y = 0; y < h4; y++)
                    ll_mask_mem[y + 1] = col_lflvl->lossless_mask_y[starty4 + y][bx64];

            const int cur_qidx = col_lflvl->qidx[bx64 + y64idx];
            if (cur_qidx != l_qidx) {
                init_deblock_thr_lut_y(f->frame_hdr, hbd, f->n_seg,
                                       1, cur_qidx, lut);
                l_qidx = cur_qidx;
            }
            int a_qidx;
            if (a_lut_ptr) {
                if (any_ll)
                    ll_mask_mem[0] = a_lflvl[x64 >> 2].lossless_mask_y[(starty4 + 63) & 63][bx64];

                a_qidx = a_lflvl[x64 >> 2].qidx[bx64 + a_y64idx];
                if (a_qidx != al_qidx) {
                    init_deblock_thr_lut_y(f->frame_hdr, hbd, f->n_seg,
                                           1, a_qidx, a_lut_ptr);
                    al_qidx = a_qidx;
                }
            }
            const int w4 = imin(f->bw - x64 * 16, 16);
            const uint16_t (*masks)[5][4] =
                (const uint16_t(*)[5][4]) &col_lflvl->filter_y[1][starty4][0][bx64];
            if (seg) {
                assert(segmap);
                dsp->lf.setup_thr_sb_seg[1](edge_thr, &segmap[x64 * 16],
                                            seg_stride, masks, lut,
                                            a_lut_ptr, h4, w4);
            } else if (a_lflvl && a_qidx != cur_qidx) {
                dsp->lf.setup_thr_sb_dq[1](edge_thr, masks, lut,
                                           h4, w4, a_lut_ptr);
            } else {
                dsp->lf.setup_thr_sb_simple(edge_thr, masks, lut, h4, w4);
            }
            filter_plane_rows_y(f, have_top, masks, ll_mask, edge_thr,
                                ptr, f->cur.p.stride[0], w4, h4);
        }
    }

    if (!f->frame_hdr->deblock.level_u && !f->frame_hdr->deblock.level_v)
        return;

    const ptrdiff_t uv_seg_stride = f->lf.segmap_uv ? f->lf.uv_segmap_stride : 0;
    const uint8_t *const uv_segmap =
        f->lf.segmap_uv ? &f->lf.segmap_uv[y64 * (16 >> ss_ver) * uv_seg_stride] : NULL;
    int l_qidx = -1, al_qidx = -1; // left and above left
    pixel lut[2][2][16];
    pixel a_lut[2][2][16];
    pixel (*const a_lut_ptr)[2][16] = a_lflvl ? a_lut : NULL;
    ALIGN_STK_64(pixel, edge_thr, 2, [2][16 * 16]);
    uint16_t ll_mask_mem[17];
    ll_mask_mem[0] = 0;
    const uint16_t *const ll_mask = any_ll ? ll_mask_mem : placeholder_ll_mask;
    ptrdiff_t uv_off;
    for (uv_off = 0, x64 = 0; x64 < (f->bw + 15) >> 4; x64++, uv_off += 64 >> ss_hor) {
        const Av2Filter *const col_lflvl = &lflvl[x64 >> 2];
        const int bx64 = x64 & 3;
        if (any_ll)
            for (int y = 0; y < uv_h4; y++)
                ll_mask_mem[y + 1] = col_lflvl->lossless_mask_uv[(starty4 >> ss_ver) + y][bx64];

        const int cur_qidx = col_lflvl->qidx[bx64 + y64idx];
        if (cur_qidx != l_qidx) {
            init_deblock_thr_lut_uv(f->frame_hdr, hbd, f->n_seg, cur_qidx, lut);
            l_qidx = cur_qidx;
        }
        int a_qidx;
        if (a_lut_ptr) {
            if (any_ll)
                ll_mask_mem[0] = a_lflvl[x64 >> 2].lossless_mask_uv[((starty4 + 63) & 63) >> ss_ver][bx64];

            a_qidx = a_lflvl[x64 >> 2].qidx[bx64 + a_y64idx];
            if (a_qidx != al_qidx) {
                init_deblock_thr_lut_uv(f->frame_hdr, hbd, f->n_seg,
                                        a_qidx, a_lut_ptr);
                al_qidx = a_qidx;
            }
        }

        const int uv_w4 = imin(f->bw - x64 * 16, 16) >> ss_hor;
        const uint16_t (*masks)[5][4] = (const uint16_t(*)[5][4])
            &col_lflvl->filter_uv[1][starty4 >> ss_ver][0][bx64];
        if (seg) {
            const uint8_t *const col_seg = &uv_segmap[x64 * (16 >> ss_hor)];
            for (int pl = 0; pl < 2; pl++)
                dsp->lf.setup_thr_sb_seg[1](edge_thr[pl], col_seg,
                                            uv_seg_stride, masks,
                                            lut[pl], a_lut_ptr ?
                                                a_lut_ptr[pl] : NULL,
                                            uv_h4, uv_w4);
        } else if (a_lut_ptr && a_qidx != cur_qidx) {
            for (int pl = 0; pl < 2; pl++)
                dsp->lf.setup_thr_sb_dq[1](edge_thr[pl], masks, lut[pl],
                                           uv_h4, uv_w4, a_lut_ptr[pl]);
        } else {
            for (int pl = 0; pl < 2; pl++)
                dsp->lf.setup_thr_sb_simple(edge_thr[pl], masks,
                                            lut[pl], uv_h4, uv_w4);
        }
        filter_plane_rows_uv(f, have_top, masks, ll_mask, edge_thr,
                             &p[1][uv_off], &p[2][uv_off], f->cur.p.stride[1],
                             uv_w4, uv_h4, ss_hor);
    }
}
