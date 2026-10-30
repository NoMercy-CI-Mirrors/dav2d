/*
 * Copyright © 2021, VideoLAN and dav2d authors
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
#include "common/attributes.h"
#include "src/env.h"
#include "src/refmvs.h"
#include "src/wedge.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static inline enum BlockSize bs_from_bwh4(const int bw4, const int bh4) {
    for (enum BlockSize bs = 0; bs < N_BS_SIZES; bs++) {
        const uint8_t *const b_dim = dav2d_block_dimensions[bs];
        if (b_dim[0] == bw4 && b_dim[1] == bh4) return bs;
    }
    return BS_INVALID;
}

static inline int gen_mv(const int total_bits, int spel_bits) {
    int bits = rnd() & ((1 << spel_bits) - 1);
    do {
        bits |= (rnd() & 1) << spel_bits;
    } while (rnd() & 1 && ++spel_bits < total_bits);
    // the do/while makes it relatively more likely to be close to zero (fpel)
    // than far away
    return rnd() & 1 ? -bits : bits;
}

static void dump_spatial_mv(const char *const tag, const refmvs_block *const a,
                            const int is_warp)
{
    fprintf(stderr, "%s: mv0=y:%d,x:%d|mv1=y:%d,x:%d|ref=%d,%d|bs=%d|mf=%d|bx4=%d,by4=%d",
            tag, a->mv[0].y, a->mv[0].x, a->mv[1].y, a->mv[1].x,
            a->ref.ref[0], a->ref.ref[1], a->bs, a->mf, a->bx4, a->by4);
    if (is_warp)
        fprintf(stderr, "|lmv0=y:%d,x:%d|lmv1=y:%d,x:%d|mat=%d,%d,%d,%d,%d,%d",
                a->lmv[0].y, a->lmv[0].x, a->lmv[1].y, a->lmv[1].x,
                a->m[0], a->m[1], a->m[2], a->m[3], a->m[4], a->m[5]);
    fprintf(stderr, "\n");
}

static int check_spatial_mv(const refmvs_block *a, const ptrdiff_t as,
                            const refmvs_block *b, const ptrdiff_t bs,
                            const int w, const int h, const int is_warp)
{
    for (int y = 0; y < h; y++) {
        // only the right-most 3 columns are filled in, except for the last line
        for (int x = (y + 1 == h ? 0 : imax(w - 3, 0)); x < w; x++)
            if (memcmp(&a[x], &b[x],
                       is_warp ? sizeof(refmvs_block) : offsetof(refmvs_block, lmv)))
            {
                if (fail()) {
                    fprintf(stderr, "spatial %dx%d,y4=%d,x4=%d\n", w * 4, h * 4, y, x);
                    dump_spatial_mv("c", &a[x], is_warp);
                    dump_spatial_mv("s", &b[x], is_warp);
                }
                return 1;
            }
        a += as;
        b += bs;
    }
    return 0;
}

static void dump_temporal_mv(const char *const tag,
                             const refmvs_temporal_block *const a,
                             const ptrdiff_t sub_pos)
{
    fprintf(stderr, "%s: mv0=y:%d,x:%d|mv1=y:%d,x:%d|ref=%d,%d\n",
            tag, a->mv[sub_pos].mv[0].y, a->mv[sub_pos].mv[0].x,
            a->mv[sub_pos].mv[1].y, a->mv[sub_pos].mv[1].x,
            a->ref[sub_pos].ref[0], a->ref[sub_pos].ref[1]);
}

static int check_temporal_mv(const refmvs_temporal_block *a, const ptrdiff_t as,
                             const refmvs_temporal_block *b, const ptrdiff_t bs,
                             const int w, const int h)
{
    const int th = (h + 1) >> 1, tw = (w + 1) >> 1;
    for (int y = 0; y < th; y++) {
        for (int x = 0; x < tw; x++) {
            if (a[x >> 5].mv[x & 31].n != b[x >> 5].mv[x & 31].n ||
                a[x >> 5].ref[x & 31].pair != b[x >> 5].ref[x & 31].pair)
            {
                if (fail()) {
                    fprintf(stderr, "temporal %dx%d,y8=%d,x8=%d\n", w * 4, h * 4, y, x);
                    dump_temporal_mv("c", &a[x >> 5], x & 31);
                    dump_temporal_mv("s", &b[x >> 5], x & 31);
                }
                return 1;
            }
        }
        a += as >> 5;
        b += bs >> 5;
    }
    return 0;
}

static void check_splat_mv(const Dav2dRefmvsDSPContext *const c) {
    refmvs_block s_dst[64 * 128], s_src;
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    refmvs_temporal_block c_t_dst[32], a_t_dst[32];

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t off_x8,
                 ptrdiff_t t_stride, int bw4, int bh4,
                 union qmvpair mv, union refpair ref);

    for (int t = 0; t < 2; t++) {
        for (int w = 1; w <= 64; w *= 2) {
            if (check_func(c->splat_mv, "splat_%s_mv_w%d",
                           t ? "spatialtemporal" : "spatial", w * 4))
            {
                const int h_min = w <= 16 ? 1 : w >> 1;
                const int h_max = w < 16 ? 16 : imin(w * 2, 64);
                for (int h = h_min; h <= h_max; h *= 2) {
                    s_src.ref.ref[0] = (rnd() & 7) - 1;
                    s_src.ref.ref[1] = s_src.ref.ref[0] == -1 ? -1 : (rnd() & 7) - 1;
                    for (int n = 0; n < 2; n++) {
                        if (s_src.ref.ref[n] == -1) {
                            s_src.mv[n].n = INVALID_MV;
                        } else {
                            s_src.mv[n].y = gen_mv(17, 3);
                            s_src.mv[n].x = gen_mv(17, 3);
                        }
                    }
                    s_src.mf = rnd() & 0xfd;
                    s_src.bs = bs_from_bwh4(w, h);
                    s_src.bx4 = rnd() % (0x4000 - w);
                    s_src.by4 = rnd() % (0x4000 - h);

                    union qmvpair t_mv;
                    t_mv.mv[0] = quantize_mv(s_src.mv[0]);
                    t_mv.mv[1] = quantize_mv(s_src.mv[1]);
                    union refpair t_ref;
                    if (t_mv.mv[0].n == INVALID_TRAJ) {
                        if (t_mv.mv[1].n == INVALID_TRAJ) {
                            t_ref.pair = -1;
                        } else {
                            t_mv.mv[0] = t_mv.mv[1];
                            t_ref.pair = s_src.ref.ref[1] * 0x101;
                        }
                    } else if (t_mv.mv[1].n == INVALID_TRAJ) {
                        t_mv.mv[1] = t_mv.mv[0];
                        t_ref.pair = s_src.ref.ref[0] * 0x101;
                    } else {
                        t_ref.pair = s_src.ref.pair;
                    }
                    const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                    memset(s_dst, -1, sizeof(*s_dst) * 64 * 128);
                    memset(c_t_dst, -1, sizeof(*c_t_dst) * 32);
                    memset(a_t_dst, -1, sizeof(*a_t_dst) * 32);
                    call_ref(c_s_dst, &s_src, t ? c_t_dst : NULL, t_off, 32,
                             w, h, t_mv, t_ref);
                    call_new(a_s_dst, &s_src, t ? a_t_dst : NULL, t_off, 32,
                             w, h, t_mv, t_ref);

                    if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, 0) && t) {
                        check_temporal_mv(c_t_dst, 32, a_t_dst, 32, w, h);
                    }

                    if (w == h) {
                        bench_new(a_s_dst, &s_src, t ? a_t_dst : NULL, 0, 32,
                                  w, h, t_mv, t_ref);
                    }
                }
            }
        }
    }
    report("splat_mv");
}

static void check_splat_warpmv(const Dav2dRefmvsDSPContext *const c) {
    refmvs_block s_dst[64 * 128], s_src;
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    refmvs_temporal_block c_t_dst[32], a_t_dst[32];

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t off_x8,
                 ptrdiff_t t_stride, int bw4, int bh4,
                 union refpair ref, const int32_t *matrix);

    for (int g = 0; g < 2; g++)
        for (int t = 0; t < 2; t++) {
            for (int w = 2; w <= 64; w *= 2) {
                if (check_func(c->splat_warpmv, "splat_%s_warp%smv_w%d",
                               t ? "spatialtemporal" : "spatial",
                               g ? "global" : "", w * 4))
                {
                    const int h_min = w <= 16 ? 2 : w >> 1;
                    const int h_max = w < 16 ? 16 : imin(w * 2, 64);
                    for (int h = h_min; h <= h_max; h *= 2) {
                        const int wide = rnd() & 1;
                        s_src.ref.ref[0] = rnd() % 7;
                        union refpair t_ref;
                        t_ref.pair = 0x101 * s_src.ref.ref[0];
                        s_src.ref.ref[1] = -1;
                        // increase chance that quantized temporal MV is invalid
                        s_src.mv[0].y = wide ? gen_mv(8, 12) : gen_mv(17, 3);
                        s_src.mv[0].x = gen_mv(17, 3);
                        s_src.mv[1].n = INVALID_MV;
                        if (!g) {
                            COPY2MV(s_src.lmv, s_src.mv);
                        }
                        s_src.mf = (rnd() & 0xfc) | (!g << 1) | g;
                        s_src.bs = bs_from_bwh4(w, h);
                        s_src.bx4 = rnd() % ((0x4000 >> (!wide * 7)) - w);
                        s_src.by4 = rnd() % ((0x4000 >> (!wide * 7)) - h);
                        int32_t gmv_mat[6], *const mat = g ? gmv_mat : s_src.m;
                        mat[0] = s_src.mv[0].x * (1 << 13);
                        mat[1] = s_src.mv[0].y * (1 << 13);
                        const int range = 0x3ff >> (!wide * 4);
                        const int bias = 0x1ff >> (!wide * 4);
                        mat[2] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;
                        mat[3] =  ((rnd() % range) - bias) * (1 << 6);
                        mat[4] =  ((rnd() % range) - bias) * (1 << 6);
                        mat[5] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;

                        const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                        memset(s_dst, -1, sizeof(*s_dst) * 64 * 128);
                        memset(c_t_dst, -1, sizeof(*c_t_dst) * 32);
                        memset(a_t_dst, -1, sizeof(*a_t_dst) * 32);
                        call_ref(c_s_dst, &s_src, t ? c_t_dst : NULL, t_off, 32,
                                 w, h, t_ref, mat);
                        call_new(a_s_dst, &s_src, t ? a_t_dst : NULL, t_off, 32,
                                 w, h, t_ref, mat);

                        if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, !g) && t) {
                            check_temporal_mv(c_t_dst, 32, a_t_dst, 32, w, h);
                        }

                        if (w == h) {
                            bench_new(a_s_dst, &s_src, t ? a_t_dst : NULL, 0, 32,
                                      w, h, t_ref, mat);
                        }
                    }
                }
            }
        }
    report("splat_warpmv");
}

static void check_splat_comp_warpmv(const Dav2dRefmvsDSPContext *const c) {
    refmvs_block s_dst[64 * 128], s_src;
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    refmvs_temporal_block c_t_dst[32], a_t_dst[32];

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t off_x8,
                 ptrdiff_t t_stride, int bw4, int bh4, union refpair ref,
                 const int32_t *matrix1, const int32_t *matrix2,
                 intptr_t t_swap, const uint8_t *wedge, intptr_t w_mask);

    for (int g = 0; g < 2; g++)
        for (int t = 0; t < 2; t++) {
            for (int w = 2; w <= 64; w *= 2) {
                if (check_func(c->splat_comp_warpmv, "splat_%s_comp_warp%smv_w%d",
                               t ? "spatialtemporal" : "spatial",
                               g ? "global" : "", w * 4))
                {
                    const int h_min = w <= 16 ? 2 : w >> 1;
                    const int h_max = w < 16 ? 16 : imin(w * 2, 64);
                    for (int h = h_min; h <= h_max; h *= 2) {
                        const int t_swap = rnd() & 1;
                        const int wide = rnd() & 1;

                        union refpair t_ref;
                        s_src.ref.ref[0] = t_ref.ref[t_swap] = rnd() % 7;
                        s_src.ref.ref[1] = t_ref.ref[!t_swap] = rnd() % 7;
                        for (int n = 0; n < 2; n++) {
                            // increase chance that quantized temporal MV is invalid
                            s_src.mv[n].y = wide ? gen_mv(8, 12) : gen_mv(17, 3);
                            s_src.mv[n].x = gen_mv(17, 3);
                        }
                        if (!g) {
                            COPY2MV(s_src.lmv, s_src.mv);
                        }
                        s_src.mf = (rnd() & 0xfc) | (!g << 1) | g;
                        s_src.bs = bs_from_bwh4(w, h);
                        s_src.bx4 = rnd() % ((0x4000 >> (!wide * 7)) - w);
                        s_src.by4 = rnd() % ((0x4000 >> (!wide * 7)) - h);
                        const int widx = rnd() % 68;
                        const uint8_t *const mask = w <= 16 && h <= 16 && rnd() & 1 ?
                            WEDGE_TMVP(s_src.bs, w, h, widx) : NULL;
                        const int w_swap = mask && rnd() & 1;

                        int32_t gmv_mat[2][6], *const mat[2] = { g ? gmv_mat[0] : s_src.m, gmv_mat[g] };
                        const int range = 0x3ff >> (!wide * 4);
                        const int bias = 0x1ff >> (!wide * 4);
                        for (int n = 0; n < 2; n++) {
                            mat[n][0] = s_src.mv[n].x * (1 << 13);
                            mat[n][1] = s_src.mv[n].y * (1 << 13);
                            mat[n][2] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;
                            mat[n][3] =  ((rnd() % range) - bias) * (1 << 6);
                            mat[n][4] =  ((rnd() % range) - bias) * (1 << 6);
                            mat[n][5] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;
                        }

                        const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                        memset(s_dst, -1, sizeof(*s_dst) * 64 * 128);
                        memset(c_t_dst, -1, sizeof(*c_t_dst) * 32);
                        memset(a_t_dst, -1, sizeof(*a_t_dst) * 32);
                        call_ref(c_s_dst, &s_src, t ? c_t_dst : NULL, t_off, 32,
                                 w, h, t_ref, mat[0], mat[1], t_swap, mask, w_swap);
                        call_new(a_s_dst, &s_src, t ? a_t_dst : NULL, t_off, 32,
                                 w, h, t_ref, mat[0], mat[1], t_swap, mask, w_swap);

                        if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, !g) && t) {
                            check_temporal_mv(c_t_dst, 32, a_t_dst, 32, w, h);
                        }

                        if (w == h) {
                            bench_new(a_s_dst, &s_src, t ? a_t_dst : NULL, 0, 32,
                                      w, h, t_ref, mat[0], mat[1], t_swap,
                                      mask, w_swap);
                        }
                    }
                }
            }
        }
    report("splat_comp_warpmv");
}

static void check_splat_comp_wedgemv(const Dav2dRefmvsDSPContext *const c) {
    refmvs_block s_dst[64 * 128], s_src;
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    refmvs_temporal_block c_t_dst[32], a_t_dst[32];

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t off_x8,
                 ptrdiff_t t_stride, int bw4, int bh4,
                 union qmvpair mv, union refpair ref,
                 const uint8_t *wedge, intptr_t w_mask);

    for (int t = 0; t < 2; t++) {
        for (int w = 2; w <= 16; w *= 2) {
            if (check_func(c->splat_comp_wedgemv, "splat_%s_comp_wedgemv_w%d",
                           t ? "spatialtemporal" : "spatial", w * 4))
            {
                for (int h = 2; h <= 16; h *= 2) {
                    s_src.ref.ref[0] = rnd() % 7;
                    s_src.ref.ref[1] = rnd() % 7;
                    for (int n = 0; n < 2; n++) {
                        // increase chance that quantized temporal MV is invalid
                        s_src.mv[n].y = rnd() & 1 ? gen_mv(8, 12) : gen_mv(17, 3);
                        s_src.mv[n].x = gen_mv(17, 3);
                    }
                    s_src.mf = rnd() & 0xfd;
                    s_src.bs = bs_from_bwh4(w, h);
                    s_src.bx4 = rnd() % (0x4000 - w);
                    s_src.by4 = rnd() % (0x4000 - h);
                    const int widx = rnd() % 68;
                    const uint8_t *const mask = WEDGE_TMVP(s_src.bs, w, h, widx);
                    const int w_swap = rnd() & 1;

                    union refpair t_ref;
                    t_ref.pair = s_src.ref.pair;
                    union qmvpair t_mv;
                    t_mv.mv[0] = quantize_mv(s_src.mv[0]);
                    t_mv.mv[1] = quantize_mv(s_src.mv[1]);
                    const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                    memset(s_dst, -1, sizeof(*s_dst) * 64 * 128);
                    memset(c_t_dst, -1, sizeof(*c_t_dst) * 32);
                    memset(a_t_dst, -1, sizeof(*a_t_dst) * 32);
                    call_ref(c_s_dst, &s_src, t ? c_t_dst : NULL, t_off, 32,
                             w, h, t_mv, t_ref, mask, w_swap);
                    call_new(a_s_dst, &s_src, t ? a_t_dst : NULL, t_off, 32,
                             w, h, t_mv, t_ref, mask, w_swap);

                    if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, 0) && t) {
                        check_temporal_mv(c_t_dst, 32, a_t_dst, 32, w, h);
                    }

                    if (w == h) {
                        bench_new(a_s_dst, &s_src, t ? a_t_dst : NULL, 0, 32,
                                  w, h, t_mv, t_ref, mask, w_swap);
                    }
                }
            }
        }
    }
    report("splat_comp_wedgemv");
}

static void dump_tip_proj(const char *const tag,
                          const refmvs_sngl_mv_block *const a,
                          const ptrdiff_t sub_pos, const int check_all_refs)
{
    if (a->mv[sub_pos].n != INVALID_TMV) {
        fprintf(stderr, "%s: mv=y:%d,x:%d,ref:%d\n", tag,
                a->mv[sub_pos].y, a->mv[sub_pos].x, a->refdist[sub_pos]);
    } else if (check_all_refs) {
        fprintf(stderr, "%s: mv=y:0x%x[invalid],ref:%d\n", tag,
                a->mv[sub_pos].n, a->refdist[sub_pos]);
    } else {
        fprintf(stderr, "%s: mv=y:0x%x[invalid]\n", tag, a->mv[sub_pos].n);
    }
}

static int check_tip_proj(const refmvs_sngl_mv_block *const a, const ptrdiff_t as,
                          const refmvs_sngl_mv_block *const b, const ptrdiff_t bs,
                          const int col_start8, const int col_end8,
                          const int h8, const int sample_step,
                          const int check_all_refs)
{
    for (int y = 0; y < h8; y += sample_step) {
        for (int x = col_start8; x < col_end8; x += sample_step) {
            const ptrdiff_t a_pos = (y * as + x) >> 5;
            const ptrdiff_t b_pos = (y * bs + x) >> 5;
            const ptrdiff_t sub_pos = x & 31;
            if (a[a_pos].mv[sub_pos].n != b[b_pos].mv[sub_pos].n ||
                ((a[a_pos].mv[sub_pos].n != INVALID_TMV || check_all_refs) &&
                 a[a_pos].refdist[sub_pos] != b[b_pos].refdist[sub_pos]))
            {
                if (fail()) {
                    fprintf(stderr, "tip_proj y8=%d,x8=%d\n", y, x);
                    dump_tip_proj("c", &a[a_pos], sub_pos, check_all_refs);
                    dump_tip_proj("s", &b[b_pos], sub_pos, check_all_refs);
                }
                return 1;
            }
        }
    }

    return 0;
}

static void check_tip_projection_fn(const Dav2dRefmvsDSPContext *const c) {
    refmvs_sngl_mv_block c_dst[256], a_dst[256];

    declare_func(void, refmvs_sngl_mv_block *rp_proj, ptrdiff_t stride,
                 int col_start8, int col_end8, int h8,
                 int tmvp_sample_step, int tip_delta);

    for (int sample_step = 1; sample_step <= 2; sample_step++)
        if (check_func(c->tip_projection, "tip_projection_ss%d", sample_step)) {
            const int sb128 = sample_step == 1 ? rnd() % 3 : 1 + (rnd() & 1);
            const int sbsz8 = 8 << sb128;
            const int tip_delta = 1 + (rnd() % 31);
            const ptrdiff_t stride = 256;

            const int have_right = rnd() & 1;
            const int col_start8 = (rnd() & 255) & ~(sbsz8 - 1);
            const int w8 = have_right ?
                (sbsz8 + (rnd() % (257 - sbsz8 - col_start8))) & ~(sbsz8 - 1) :
                1 + (rnd() % (256 - col_start8));
            assert(w8 > 0);
            const int col_end8 = col_start8 + w8;
            assert(col_start8 >= 0 && col_end8 <= 256 && col_start8 < col_end8);
            const int h8 = 1 + (rnd() & (sbsz8 - 1));

            for (int y = 0; y < 32; y += sample_step) {
                // initialize full rows for bench
                for (int x = 0; x < 256; x += sample_step) {
                    const ptrdiff_t pos = (y * stride + x) >> 5;
                    const ptrdiff_t sub_pos = x & 31;
                    if (rnd() & 1) {
                        a_dst[pos].mv[sub_pos].n = INVALID_TMV;
                    } else {
                        a_dst[pos].mv[sub_pos].y = gen_mv(11, 3);
                        a_dst[pos].mv[sub_pos].x = gen_mv(11, 3);
                        a_dst[pos].refdist[sub_pos] = 1 + (rnd() % 31);
                    }
                }
            }
            memcpy(c_dst, a_dst, sizeof(*a_dst) * stride);

            call_ref(c_dst, stride, col_start8, col_end8, h8,
                     sample_step, tip_delta);
            call_new(a_dst, stride, col_start8, col_end8, h8,
                     sample_step, tip_delta);
            // check one block before/after each, not just the parts
            // written to by the code, to ensure the area around it
            // was left unclobbered
            check_tip_proj(c_dst, stride, a_dst, stride,
                           imax(0, col_start8 - sample_step), have_right ?
                           imin(col_end8 + sample_step, 256) : col_end8,
                           h8, sample_step, 1);
            bench_new(alternate(c_dst, a_dst), stride,
                      0, 256, 32, sample_step, tip_delta);
        }

    report("tip_projection");
}

static void check_tip_fn(const tip_fn fn, const char *const name) {
    refmvs_sngl_mv_block c_dst[256], a_dst[256];

    declare_func(void, refmvs_sngl_mv_block *rp_proj, ptrdiff_t stride,
                 int col_start8, int col_end8, int h8, int tmvp_sample_step);

    for (int sample_step = 1; sample_step <= 2; sample_step++)
        if (check_func(fn, "%s_ss%d", name, sample_step)) {
            const int sb128 = sample_step == 1 ? rnd() % 3 : 1 + (rnd() & 1);
            const int sbsz8 = 8 << sb128;
            const int tip_delta = 1 + (rnd() % 31);
            const ptrdiff_t stride = 256;

            const int have_right = rnd() & 1;
            const int col_start8 = (rnd() & 255) & ~(sbsz8 - 1);
            const int w8 = have_right ?
                (sbsz8 + (rnd() % (257 - sbsz8 - col_start8))) & ~(sbsz8 - 1) :
                1 + (rnd() % (256 - col_start8));
            assert(w8 > 0);
            const int col_end8 = col_start8 + w8;
            assert(col_start8 >= 0 && col_end8 <= 256 && col_start8 < col_end8);
            const int h8 = 1 + (rnd() & (sbsz8 - 1));

            for (int y = 0; y < 32; y += sample_step) {
                // initialize full rows for bench
                for (int x = 0; x < 256; x += sample_step) {
                    const ptrdiff_t pos = (y * stride + x) >> 5;
                    const ptrdiff_t sub_pos = x & 31;
                    a_dst[pos].refdist[sub_pos] = tip_delta;
                    if (rnd() & 1) {
                        a_dst[pos].mv[sub_pos].n = INVALID_TMV;
                    } else {
                        a_dst[pos].mv[sub_pos].y = gen_mv(11, 3);
                        a_dst[pos].mv[sub_pos].x = gen_mv(11, 3);
                    }
                }
            }
            memcpy(c_dst, a_dst, sizeof(*a_dst) * stride);

            call_ref(c_dst, stride, col_start8, col_end8, h8, sample_step);
            call_new(a_dst, stride, col_start8, col_end8, h8, sample_step);
            // check one block before/after each, not just the parts
            // written to by the code, to ensure the area around it
            // was left unclobbered
            check_tip_proj(c_dst, stride, a_dst, stride,
                           imax(0, col_start8 - sample_step), have_right ?
                           imin(col_end8 + sample_step, 256) : col_end8,
                           h8, sample_step, 1);
            bench_new(alternate(c_dst, a_dst), stride, 0, 256, 32, sample_step);
        }

    report("%s", name);
}

static void check_fill_gap_proj_fn(const Dav2dRefmvsDSPContext *const c) {
    refmvs_sngl_mv_block c_dst[256], a_dst[256];

    declare_func(void, refmvs_sngl_mv_block *rp_proj, ptrdiff_t stride,
                 int col_start8, int col_end8, int h8);

    if (check_func(c->fill_gap_proj, "fill_gap_proj")) {
        const int sb128 = 1 + (rnd() & 1);
        const int sbsz8 = 8 << sb128;
        const int sample_step = 2;
        const ptrdiff_t stride = 256;

        const int have_right = rnd() & 1;
        const int col_start8 = (rnd() & 255) & ~(sbsz8 - 1);
        const int w8 = have_right ?
            (sbsz8 + (rnd() % (257 - sbsz8 - col_start8))) & ~(sbsz8 - 1) :
            1 + (rnd() % (256 - col_start8));
        assert(w8 > 0);
        const int col_end8 = col_start8 + w8;
        assert(col_start8 >= 0 && col_end8 <= 256 && col_start8 < col_end8);
        const int h8 = 1 + (rnd() & (sbsz8 - 1));

        for (int y = 0; y < 32; y += sample_step) {
            // initialize full rows for bench
            for (int x = 0; x < 256; x += sample_step) {
                const ptrdiff_t pos = (y * stride + x) >> 5;
                const ptrdiff_t sub_pos = x & 31;
                if (rnd() & 1) {
                    a_dst[pos].mv[sub_pos].n = INVALID_TMV;
                } else {
                    a_dst[pos].mv[sub_pos].y = gen_mv(11, 3);
                    a_dst[pos].mv[sub_pos].x = gen_mv(11, 3);
                    a_dst[pos].refdist[sub_pos] = 1 + (rnd() % 31);
                }
            }
        }
        memcpy(c_dst, a_dst, sizeof(*a_dst) * stride);

        call_ref(c_dst, stride, col_start8, col_end8, h8);
        call_new(a_dst, stride, col_start8, col_end8, h8);
        // check one block before/after each, not just the parts
        // written to by the code, to ensure the area around it
        // was left unclobbered
        check_tip_proj(c_dst, stride, a_dst, stride,
                       imax(0, col_start8 - sample_step), have_right ?
                       imin(col_end8 + sample_step, 256) : col_end8,
                       h8, 1, 0);
        bench_new(alternate(c_dst, a_dst), stride, 0, 256, 32);
    }

    report("fill_gap_proj");
}

static void dump_tip_traj(const char *const tag, const union tmv *const a) {
    if (a->n == INVALID_TMV) {
        fprintf(stderr, "%s: mv=y:0x%x[invalid]\n", tag, a->n);
    } else {
        fprintf(stderr, "%s: mv=y:%d,x:%d\n", tag, a->y, a->x);
    }
}

static int check_tip_traj(const union tmv *const a, const ptrdiff_t as,
                          const union tmv *const b, const ptrdiff_t bs,
                          const int col_start8, const int col_end8,
                          const int h8, const int sample_step)
{
    for (int y = 0; y < h8; y += sample_step) {
        for (int x = col_start8; x < col_end8; x += sample_step) {
            const ptrdiff_t a_pos = y * as + x;
            const ptrdiff_t b_pos = y * bs + x;
            if (a[a_pos].n != b[b_pos].n) {
                if (fail()) {
                    fprintf(stderr, "tip_traj y8=%d,x8=%d\n", y, x);
                    dump_tip_traj("c", &a[a_pos]);
                    dump_tip_traj("s", &b[b_pos]);
                }
                return 1;
            }
        }
    }

    return 0;
}

static void check_fill_gap_traj_fn(const Dav2dRefmvsDSPContext *const c) {
    ALIGN_STK_64(union tmv, c_dst, 32 * 256,);
    ALIGN_STK_64(union tmv, a_dst, 32 * 256,);

    declare_func(void, union tmv *rp_traj, ptrdiff_t stride,
                 int col_start8, int col_end8, int h8);

    if (check_func(c->fill_gap_traj, "fill_gap_traj")) {
        const int sb128 = 1 + (rnd() & 1);
        const int sbsz8 = 8 << sb128;
        const int sample_step = 2;
        const ptrdiff_t stride = 256;

        const int have_right = rnd() & 1;
        const int col_start8 = (rnd() & 255) & ~(sbsz8 - 1);
        const int w8 = have_right ?
            (sbsz8 + (rnd() % (257 - sbsz8 - col_start8))) & ~(sbsz8 - 1) :
            1 + (rnd() % (256 - col_start8));
        assert(w8 > 0);
        const int col_end8 = col_start8 + w8;
        assert(col_start8 >= 0 && col_end8 <= 256 && col_start8 < col_end8);
        const int h8 = 1 + (rnd() & (sbsz8 - 1));

        for (int y = 0; y < 32; y += sample_step) {
            // initialize full rows for bench
            for (int x = 0; x < 256; x += sample_step) {
                const ptrdiff_t pos = y * stride + x;
                if (rnd() & 1) {
                    a_dst[pos].n = INVALID_TMV;
                } else {
                    a_dst[pos].y = gen_mv(11, 3);
                    a_dst[pos].x = gen_mv(11, 3);
                }
            }
        }
        memcpy(c_dst, a_dst, sizeof(*a_dst) * 32 * stride);

        call_ref(c_dst, stride, col_start8, col_end8, h8);
        call_new(a_dst, stride, col_start8, col_end8, h8);
        // check one block before/after each, not just the parts
        // written to by the code, to ensure the area around it
        // was left unclobbered
        check_tip_traj(c_dst, stride, a_dst, stride,
                       imax(0, col_start8 - sample_step), have_right ?
                       imin(col_end8 + sample_step, 256) : col_end8, h8, 1);
        bench_new(alternate(c_dst, a_dst), stride, 0, 256, 32);
    }

    report("fill_gap_traj");
}

static void dump_tip_traj_map(const char *const tag,
                              const refmvs_traj_map *const a)
{
    if (a->n == INVALID_TRAJ) {
        fprintf(stderr, "%s: map=n:%d[invalid]\n", tag, a->n);
    } else {
        fprintf(stderr, "%s: map=y:%d,x:%d\n", tag, a->y, a->x);
    }
}

static int check_tip_traj_map(const refmvs_traj_map *const a, const ptrdiff_t as,
                              const refmvs_traj_map *const b, const ptrdiff_t bs,
                              const int col_start8, const int col_end8,
                              const int h8, const int sample_step)
{
    for (int y = 0; y < h8; y += sample_step) {
        for (int x = col_start8; x < col_end8; x += sample_step) {
            const ptrdiff_t a_pos = y * as + x;
            const ptrdiff_t b_pos = y * bs + x;
            if (a[a_pos].n != b[b_pos].n) {
                if (fail()) {
                    fprintf(stderr, "tip_traj_map y8=%d,x8=%d\n", y, x);
                    dump_tip_traj_map("c", &a[a_pos]);
                    dump_tip_traj_map("s", &b[b_pos]);
                }
                return 1;
            }
        }
    }

    return 0;
}

static const uint16_t div_mult[32] = {
       0, 16384, 8192, 5461, 4096, 3276, 2730, 2340,
    2048,  1820, 1638, 1489, 1365, 1260, 1170, 1092,
    1024,   963,  910,  862,  819,  780,  744,  712,
     682,   655,  630,  606,  585,  564,  546,  528
};

static void check_load_tmvs_refs_fn(const Dav2dRefmvsDSPContext *const c) {
    ALIGN_STK_64(union tmv, c_dst_traj_mem, 7, [32 * 256]);
    ALIGN_STK_64(union tmv, a_dst_traj_mem, 7, [32 * 256]);
    ALIGN_STK_64(refmvs_traj_map, c_dst_map_mem, 3, [7][32 * 256]);
    ALIGN_STK_64(refmvs_traj_map, a_dst_map_mem, 3, [7][32 * 256]);
    refmvs_sngl_mv_block c_dst_proj[256], a_dst_proj[256];
    refmvs_traj_map *c_dst_map[3][7], *a_dst_map[3][7];
    union tmv *c_dst_traj[7], *a_dst_traj[7];
    refmvs_frame rf;
    Dav2dSequenceHeader seq_hdr;
    Dav2dFrameHeader frm_hdr;

    declare_func(void, const refmvs_frame *rf, refmvs_sngl_mv_block *rp_proj,
                 ptrdiff_t stride, union tmv *rp_traj[7], refmvs_traj_map *rp_map[3][7],
                 int col_start8, int col_end8, int row_start8, int row_end8,
                 int sample_step);

    for (int traj = 0; traj <= 1; traj++)
        for (int mfmv = 0; mfmv < 5; mfmv++)
            for (int sample_step = 1; sample_step <= 2; sample_step++)
                if (check_func(c->load_tmvs_refs,
                               "load_tmvs_refs_traj%d_mfmv%d_ss%d",
                               traj, mfmv, sample_step))
                {
                    const int sb128 = sample_step == 1 ? rnd() % 3 : 1 + (rnd() & 1);
                    const int sbsz8 = 8 << sb128;
                    frm_hdr.tmvp_sample_step = sample_step;
                    const int mfmv_sb128 = sb128 && sample_step > 1;
                    const int mfmv_sbsz8 = rf.mfmv_sbsz8 = 8 << mfmv_sb128;
                    const ptrdiff_t stride = rf.rp_stride = 256;

                    for (int n = 0; n < 7; n++) {
                        c_dst_traj[n] = c_dst_traj_mem[n];
                        a_dst_traj[n] = a_dst_traj_mem[n];
                        for (int k = 0; k < 3; k++) {
                            c_dst_map[k][n] = c_dst_map_mem[k][n];
                            a_dst_map[k][n] = a_dst_map_mem[k][n];
                        }
                    }
                    rf.seq_hdr = &seq_hdr;
                    rf.frm_hdr = &frm_hdr;
                    seq_hdr.mv_traj = traj;
                    rf.mfmv_edge = mfmv_sbsz8 >> (sample_step == 1);
                    rf.sbsz = sbsz8 << 1;
                    rf.mfmv_k_shift = 3 + mfmv_sb128;
                    refmvs_temporal_block *rp_ref[7];
                    rf.rp_ref = rp_ref;

                    rf.iw8 = 1 + (rnd() & 0xff);
                    rf.ih8 = 1 + (rnd() & 0xff);
                    refmvs_temporal_block *rp_ref_mem =
                        malloc(stride * 256 * 4 * sizeof(refmvs_temporal_block));
                    if (!rp_ref_mem) goto end;

                    rf.n_mfmvs = mfmv;
                    const int order_hint_n_bits = 1 + (rnd() & 15);
                    const unsigned mask = (1 << order_hint_n_bits) - 1;
                    int ref_poc[7], ref_ref_poc[7][7];
                    const int poc = rnd() & mask; // current frame
                    for (int n = 0; n < 7; n++) {
                        const int rpoc = (poc - 32 + (rnd() % 65)) & mask;
                        ref_poc[n] = rpoc;
                    }
                    for (int n = 0; n < 7; n++) {
                        memcpy(ref_ref_poc[n], ref_poc, sizeof(**ref_ref_poc) * 7);
                        const int rpoc = (poc - 32 + (rnd() % 65)) & mask;
                        ref_poc[n] = rpoc; // update reference list
                    }

                    int i = 0;
                    uint8_t done[7][2] = {{ 0 }};
                    if (rf.n_mfmvs && rnd() & 1) {
                        const int r0 = rf.mfmv[0].ref = rnd() % 7;
                        int r1;
                        do {
                            r1 = rf.mfmv[0].tgt = rnd() % 7;
                        } while (r1 == r0);
                        const int dir = rf.mfmv[0].dir =
                            get_poc_diff(order_hint_n_bits, ref_poc[r0],
                                         ref_poc[r1]) < 0;
                        done[r0][dir] = 1;
                        i = 1;
                    }
                    for (; i < rf.n_mfmvs; i++) {
                        rf.mfmv[i].tgt = -1;
                        int r0, dir;
                        do {
                            r0 = rf.mfmv[i].ref = rnd() % 7;
                            dir = rf.mfmv[i].dir = rnd() & 1;
                        } while (done[r0][dir]);
                        done[r0][dir] = 1;
                    }
                    for (int n = 0; n < rf.n_mfmvs; n++) {
                        const int rpoc = ref_poc[rf.mfmv[n].ref];
                        const int diff1 = get_poc_diff(order_hint_n_bits, rpoc, poc);
                        if (abs(diff1) > 31) {
                            rf.mfmv_ref2cur[n] = INVALID_REF2CUR;
                        } else {
                            rf.mfmv_ref2cur[n] = diff1;
                            for (int m = 0; m < 7; m++) {
                                const int rrpoc = ref_ref_poc[rf.mfmv[n].ref][m];
                                const int diff2 = get_poc_diff(order_hint_n_bits,
                                                               rpoc, rrpoc);
                                rf.mfmv_ref2ref[n][m] = diff2 + 31U < 63U ? diff2 : 0;
                                int l = 7;
                                if (diff2)
                                    for (l = 0; l < 7; l++)
                                        if (rrpoc == ref_poc[l])
                                            break;
                                rf.mfmv_ref2idx[n][m] = l == 7 ? -1 : l;
                                const int d1 = rf.mfmv_ref2cur[n];
                                const int d2 = rf.mfmv_ref2ref[n][m];
                                const int dv = div_mult[imin(abs(d2), 31)];
                                rf.mfmv_ref2sf[n][m][0] = imin(abs(d1), 31) * dv;
                                if ((d1 < 0) ^ (d2 < 0)) rf.mfmv_ref2sf[n][m][0] *= -1;
                                const int d3 = d1 - d2;
                                rf.mfmv_ref2sf[n][m][1] = imin(abs(d3), 31) * dv;
                                if ((d3 < 0) ^ (d2 > 0)) rf.mfmv_ref2sf[n][m][1] *= -1;
                            }
                        }
                    }

                    const int col_start8 = (rnd() % rf.iw8) & ~(sbsz8 - 1);
                    const int have_right = rf.iw8 - col_start8 > 2 * sbsz8 ?
                                           rnd() & 1 : 0;
                    const int w8 = have_right ?
                        (sbsz8 + (rnd() % (rf.iw8 + 1 - sbsz8 - col_start8))) & ~(sbsz8 - 1) :
                        1 + (rnd() % (rf.iw8 - col_start8));
                    assert(w8 > 0);
                    const int col_end8 = col_start8 + w8;
                    assert(col_start8 >= 0 && col_end8 <= rf.iw8 &&
                           col_start8 < col_end8);
                    const int row_start8 = (rnd() % rf.ih8) & ~(sbsz8 - 1);
                    const int row_start8_align32 = row_start8 & ~31;
                    const int row_end8 = imin(row_start8 + sbsz8, rf.ih8);
                    assert(row_start8 < row_end8 && row_end8 <= rf.ih8);

                    for (int n = 0; n < rf.n_mfmvs; n++) {
                        refmvs_temporal_block *r = rp_ref[rf.mfmv[n].ref] =
                            &rp_ref_mem[n * stride * 256];
                        for (int y = row_start8_align32; y < row_start8_align32 + 32;
                             y += sample_step)
                        {
                            // initialize full rows for bench
                            for (int x = 0; x < 256; x += sample_step) {
                                const ptrdiff_t pos = y * stride + x;
                                for (int n = 0; n < 2; n++) {
                                    union mv mv;
                                    if (rnd() & 1) {
                                        mv.n = INVALID_MV;
                                    } else {
                                        mv.y = gen_mv(11, 3);
                                        mv.x = gen_mv(11, 3);
                                    }
                                    const union qmv tmv =
                                    r[pos >> 5].mv[pos & 31].mv[n] = quantize_mv(mv);
                                    r[pos >> 5].ref[pos & 31].ref[n] =
                                        tmv.n == INVALID_TRAJ ? -1 : rnd() % 7;
                                }
                            }
                        }
                    }
                    // write default data (that should be unclobbered)
                    memset(c_dst_proj, 0, sizeof(*c_dst_proj) * 256);
                    memset(a_dst_proj, 0, sizeof(*a_dst_proj) * 256);
                    memset(c_dst_map_mem, 0, sizeof(*c_dst_map_mem) * 3);
                    memset(a_dst_map_mem, 0, sizeof(*a_dst_map_mem) * 3);
                    memset(c_dst_traj_mem, 0, sizeof(*c_dst_traj_mem) * 7);
                    memset(a_dst_traj_mem, 0, sizeof(*a_dst_traj_mem) * 7);

                    call_ref(&rf, c_dst_proj, stride, c_dst_traj, c_dst_map,
                             col_start8, col_end8, row_start8, row_end8,
                             sample_step);
                    call_new(&rf, a_dst_proj, stride, a_dst_traj, a_dst_map,
                             col_start8, col_end8, row_start8, row_end8,
                             sample_step);

                    // check one block before/after each, not just the parts
                    // written to by the code, to ensure the area around it
                    // was left unclobbered
                    const int h8 = row_end8 - row_start8;
                    const int col_end8_check = have_right ?
                        imin(256, col_end8 + sample_step) : col_end8;
                    int res = check_tip_proj(c_dst_proj, stride, a_dst_proj, stride,
                                             imax(0, col_start8 - sample_step),
                                             col_end8_check, h8, sample_step, 0);
                    for (int n = 0; n < 7 && !res; n++) {
                        res |= check_tip_traj(c_dst_traj[n], stride, a_dst_traj[n], stride,
                                              imax(0, col_start8 - sample_step),
                                              col_end8_check, h8, sample_step);
                        const int mask = mfmv_sbsz8 - 1;
                        for (int k = -1; k <= +1 && !res; k++) {
                            const int x_start =
                                imax(0, col_start8 - k * mfmv_sbsz8 - sample_step);
                            const int x_end =
                                imin(rf.iw8, ((col_end8 + mask) & ~mask) -
                                             k * mfmv_sbsz8 +
                                             have_right * sample_step);
                            res |= check_tip_traj_map(c_dst_map[k + 1][n], stride,
                                                      a_dst_map[k + 1][n], stride,
                                                      x_start, x_end, h8,
                                                      sample_step);
                        }
                    }
                    rf.iw8 = rf.ih8 = 256;
                    bench_new(&rf, alternate(c_dst_proj, a_dst_proj), stride,
                              alternate(c_dst_traj, a_dst_traj),
                              alternate(c_dst_map, a_dst_map), 0, 256,
                              row_start8_align32, row_start8_align32 + 32, sample_step);

                    free(rp_ref_mem);
                }

end:
    report("load_tmvs_refs");
}

void checkasm_check_refmvs(void) {
    Dav2dRefmvsDSPContext c;
    dav2d_refmvs_dsp_init(&c);

    dav2d_init_ii_wedge_masks();

    check_splat_mv(&c);
    check_splat_warpmv(&c);
    check_splat_comp_warpmv(&c);
    check_splat_comp_wedgemv(&c);

    check_tip_projection_fn(&c);
    check_tip_fn(c.tip_fill_holes, "tip_fill_holes");
    check_tip_fn(c.tip_smoothen, "tip_smoothen");
    check_fill_gap_proj_fn(&c);
    check_fill_gap_traj_fn(&c);
    check_load_tmvs_refs_fn(&c);
}
