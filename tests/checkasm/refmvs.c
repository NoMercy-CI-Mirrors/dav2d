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

static int check_temporal_mv(const refmvs_temporal_block *a, const ptrdiff_t as,
                             const refmvs_temporal_block *b, const ptrdiff_t bs,
                             const int w, const int h)
{
    const int th = (h + 1) >> 1, tw = (w + 1) >> 1;
    for (int y = 0; y < th; y++) {
        for (int x = 0; x < tw; x++)
            if (memcmp(&a[x], &b[x], sizeof(refmvs_temporal_block))) {
                if (fail()) {
                    fprintf(stderr, "temporal %dx%d,y8=%d,x8=%d\n", w, h, y, x);
                    fprintf(stderr, "c: mv0=y:%d,x:%d|mv1=y:%d,x:%d|ref=%d,%d\n",
                            a[x].mv.mv[0].y, a[x].mv.mv[0].x,
                            a[x].mv.mv[1].y, a[x].mv.mv[1].x,
                            a[x].ref.ref[0], a[x].ref.ref[1]);
                    fprintf(stderr, "s: mv0=y:%d,x:%d|mv1=y:%d,x:%d|ref=%d,%d\n",
                            b[x].mv.mv[0].y, b[x].mv.mv[0].x,
                            b[x].mv.mv[1].y, b[x].mv.mv[1].x,
                            b[x].ref.ref[0], b[x].ref.ref[1]);
                }
                return 1;
            }
        a += as;
        b += bs;
    }
    return 0;
}

#if 0
static inline int get_min_mv_val(const int idx) {
    if      (idx <= 9)  return idx;
    else if (idx <= 18) return (idx - 9) * 10;
    else if (idx <= 27) return (idx - 18) * 100;
    else if (idx <= 36) return (idx - 27) * 1000;
    else                return (idx - 36) * 10000;
}

static inline void gen_tmv(refmvs_temporal_block *const rb, const int8_t *const ref2ref) {
    rb->ref.ref[1] = -1;
    rb->ref.ref[0] = rnd() % 7;
    if (!rb->ref.ref[0]) return;
    static const int x_prob[] = {
        26447556, 6800591, 3708783,  2198592, 1635940, 1145901, 1052602, 1261759,
         1099739,  755108, 6075404,  4355916, 3254908, 2897157, 2273676, 2154432,
         1937436, 1694818, 1466863, 10203087, 5241546, 3328819, 2187483, 1458997,
         1030842,  806863,  587219,   525024, 1858953,  422368,  114626,   16992
    };
    static const int y_prob[] = {
        33845001, 7591218,  6425971, 4115838, 4032161, 2515962, 2614601, 2343656,
         2898897, 1397254, 10125350, 5124449, 3232914, 2185499, 1608775, 1342585,
          980208,  795714,   649665, 3369250, 1298716,  486002,  279588,  235990,
          110318,   89372,    66895,   46980,  153322,   32960,    4500,     389
    };
    const int prob = rnd() % 100000000;
    int acc = 0;
    for (unsigned i = 0; i < ARRAY_SIZE(x_prob); i++) {
        acc += x_prob[i];
        if (prob < acc) {
            const int min = get_min_mv_val(i);
            const int max = get_min_mv_val(i + 1);
            const int val = min + rnd() % (max - min);
            rb->mv.mv[0].x = iclip(val * ref2ref[rb->ref.ref[0]], -(1 << 15), (1 << 15) - 1);
            break;
        }
    }
    acc = 0;
    for (unsigned i = 0; i < ARRAY_SIZE(y_prob); i++) {
        acc += y_prob[i];
        if (prob < acc) {
            const int min = get_min_mv_val(i);
            const int max = get_min_mv_val(i + 1);
            const int val = min + rnd() % (max - min);
            rb->mv.mv[0].y = iclip(val * ref2ref[rb->ref.ref[0]], -(1 << 15), (1 << 15) - 1);
            break;
        }
    }
}

static inline int get_ref2cur(void) {
    const int prob = rnd() % 100;
    static const uint8_t ref2cur[11] = { 35, 55, 67, 73, 78, 83, 84, 87, 90, 93, 100 };
    for (int i = 0; i < 11; i++)
        if (prob < ref2cur[i])
            return rnd() & 1 ? -(i + 1) : i + 1;
    return 0;
}

static inline int get_seqlen(void) {
    int len = 0, max_len;
    const int prob = rnd() % 100000;
    // =1 =2 =3 =4  <8  =8 <16 =16 <32 =32 <48 =48 <64 =64 >64 eq240
    //  5 17 1.5 16  5  10  5   7   4   3  1.5  2   1    2   20   15   chimera blocks
    // 25 38 2.5 19 3.5 5.5 2 1.87 .86 .4  .18 .2 .067 .165 .478 .28   chimera sequences

    if      (prob < 25000) len = 1;       // =1   5%
    else if (prob < 63000) len = 2;       // =2   17%
    else if (prob < 65500) len = 3;       // =3   1.5%
    else if (prob < 84500) len = 4;       // =4   16%
    else if (prob < 88000) max_len = 7;   // <8   5% (43.5% tot <8)
    else if (prob < 93500) len = 8;       // =8   10%
    else if (prob < 95500) max_len = 15;  // <16  5%
    else if (prob < 97370) len = 16;      // =16  7%
    else if (prob < 98230) max_len = 31;  // <32  4%
    else if (prob < 98630) len = 32;      // =32  3%
    else if (prob < 98810) max_len = 47;  // <48  1.5%
    else if (prob < 99010) len = 48;      // =48  2%
    else if (prob < 99077) max_len = 63;  // <64  1%
    else if (prob < 99242) len = 64;      // =64  2%
    else if (prob < 99720) max_len = 239; // <240 5%
    else                   len = 240;     // =240 15%

    if (!len) len = 1 + rnd() % max_len;
    return len;
}

static inline void init_rp_ref(refmvs_frame const *const rf,
                               const int col_start8, const int col_end8,
                               const int row_start8, const int row_end8)
{
    const int col_start8i = imax(col_start8 - 8, 0);
    const int col_end8i = imin(col_end8 + 8, rf->iw8);
    for (int n = 0; n < rf->n_mfmvs; n++) {
        refmvs_temporal_block *rp_ref = rf->rp_ref[rf->mfmv[n].ref];
        for (int i = row_start8; i < imin(row_end8, rf->ih8); i++) {
            for (int j = col_start8i; j < col_end8i;) {
                refmvs_temporal_block rb;
                gen_tmv(&rb, rf->mfmv_ref2ref[n]);
                for (int k = get_seqlen(); k && j < col_end8i; k--, j++)
                    rp_ref[i * rf->iw8 + j] = rb;
            }
        }
    }
}

static void check_load_tmvs(const Dav2dRefmvsDSPContext *const c) {
    refmvs_temporal_block *rp_ref[7] = {0};
    refmvs_temporal_block c_rp_proj[240 * 63];
    refmvs_temporal_block a_rp_proj[240 * 63];
    refmvs_frame rf = {
        .rp_ref = rp_ref,
        .rp_stride = 240, .iw8 = 240, .ih8 = 63,
        .n_mfmvs = 3
    };
    const size_t rp_ref_sz = rf.ih8 * rf.rp_stride * sizeof(refmvs_temporal_block);

    declare_func(void, const refmvs_frame *rf, int tile_row_idx,
                 int col_start8, int col_end8, int row_start8, int row_end8);

    if (check_func(c->load_tmvs, "load_tmvs")) {
        const int row_start8 = (rnd() & 3) << 4;
        const int row_end8 = row_start8 + 16;
        const int col_start8 = rnd() & 31;
        const int col_end8 = rf.iw8 - (rnd() & 31);

        for (int n = 0; n < rf.n_mfmvs; n++) {
            rf.mfmv_ref[n] = rnd() % 7;
            rf.mfmv_ref2cur[n] = get_ref2cur();
            for (int r = 0; r < 7; r++)
                rf.mfmv_ref2ref[n][r] = rnd() & 31;
        }
        for (int n = 0; n < rf.n_mfmvs; n++) {
            refmvs_temporal_block **p_rp_ref = &rp_ref[rf.mfmv_ref[n]];
            if (!*p_rp_ref)
                *p_rp_ref = malloc(rp_ref_sz);
        }
        init_rp_ref(&rf, 0, rf.iw8, row_start8, row_end8);
        for (int i = 0; i < rf.iw8 * rf.ih8; i++) {
            c_rp_proj[i].mv.n = a_rp_proj[i].mv.n = 0xdeadbeef;
            c_rp_proj[i].ref = a_rp_proj[i].ref = 0xdd;
        }

        rf.n_tile_threads = 1;

        rf.rp_proj = c_rp_proj;
        call_ref(&rf, 0, col_start8, col_end8, row_start8, row_end8);
        rf.rp_proj = a_rp_proj;
        call_new(&rf, 0, col_start8, col_end8, row_start8, row_end8);

        for (int i = 0; i < rf.ih8; i++)
            for (int j = 0; j < rf.iw8; j++)
                if (c_rp_proj[i * rf.iw8 + j].mv.n != a_rp_proj[i * rf.iw8 + j].mv.n ||
                    (c_rp_proj[i * rf.iw8 + j].ref != a_rp_proj[i * rf.iw8 + j].ref &&
                     c_rp_proj[i * rf.iw8 + j].mv.n != INVALID_MV))
                {
                    if (fail()) {
                        fprintf(stderr, "[%d][%d] c_rp.mv.x = 0x%x a_rp.mv.x = 0x%x\n",
                                i, j, c_rp_proj[i * rf.iw8 + j].mv.x, a_rp_proj[i * rf.iw8 + j].mv.x);
                        fprintf(stderr, "[%d][%d] c_rp.mv.y = 0x%x a_rp.mv.y = 0x%x\n",
                                i, j, c_rp_proj[i * rf.iw8 + j].mv.y, a_rp_proj[i * rf.iw8 + j].mv.y);
                        fprintf(stderr, "[%d][%d] c_rp.ref = %u a_rp.ref = %u\n",
                                i, j, c_rp_proj[i * rf.iw8 + j].ref, a_rp_proj[i * rf.iw8 + j].ref);
                    }
                }

        if (checkasm_bench_func()) {
            for (int n = 0; n < rf.n_mfmvs; n++) {
                rf.mfmv_ref2cur[n] = 1;
                for (int r = 0; r < 7; r++)
                    rf.mfmv_ref2ref[n][r] = 1;
            }
            bench_new(&rf, 0, 0, rf.iw8, row_start8, row_end8);
        }

        for (int n = 0; n < rf.n_mfmvs; n++) {
            free(rp_ref[rf.mfmv_ref[n]]);
            rp_ref[rf.mfmv_ref[n]] = NULL;
        }
    }

    report("load_tmvs");
}
#endif

static void check_splat_mv(const Dav2dRefmvsDSPContext *const c) {
    ALIGN_STK_64(refmvs_block, s_dst, 64 * 128,);
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    ALIGN_STK_64(refmvs_block, s_src, 1,);
    ALIGN_STK_64(refmvs_temporal_block, c_t_dst, 32 * 32,);
    ALIGN_STK_64(refmvs_temporal_block, a_t_dst, 32 * 32,);
    refmvs_temporal_block t_src;

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t t_stride,
                 refmvs_temporal_block *t_src, int bw4, int bh4);

    for (int t = 0; t < 2; t++) {
        for (int w = 1; w <= 64; w *= 2) {
            if (check_func(c->splat_mv, "splat_%s_mv_w%d",
                           t ? "spatialtemporal" : "spatial", w * 4))
            {
                const int h_min = w <= 16 ? 1 : w >> 1;
                const int h_max = w < 16 ? 16 : imin(w * 2, 64);
                for (int h = h_min; h <= h_max; h *= 2) {
                    s_src[0].ref.ref[0] = (rnd() & 7) - 1;
                    s_src[0].ref.ref[1] = s_src[0].ref.ref[0] == -1 ? -1 : (rnd() & 7) - 1;
                    for (int n = 0; n < 2; n++) {
                        if (s_src[0].ref.ref[n] == -1) {
                            s_src[0].mv[n].y = INVALID_MV;
                            s_src[0].mv[n].x = 0;
                        } else {
                            s_src[0].mv[n].y = gen_mv(17, 3);
                            s_src[0].mv[n].x = gen_mv(17, 3);
                        }
                    }
                    s_src[0].mf = rnd() & 0xfd;
                    s_src[0].bs = bs_from_bwh4(w, h);
                    s_src[0].bx4 = rnd() % (0x4000 - w);
                    s_src[0].by4 = rnd() % (0x4000 - h);

                    t_src.mv.mv[0] = quantize_mv(s_src[0].mv[0]);
                    t_src.mv.mv[1] = quantize_mv(s_src[0].mv[1]);
                    if (t_src.mv.mv[0].n == INVALID_TRAJ) {
                        if (t_src.mv.mv[1].n == INVALID_TRAJ) {
                            t_src.ref.pair = -1;
                        } else {
                            t_src.mv.mv[0] = t_src.mv.mv[1];
                            t_src.ref.ref[0] = t_src.ref.ref[1];
                        }
                    } else if (t_src.mv.mv[1].n == INVALID_TRAJ) {
                        t_src.mv.mv[1] = t_src.mv.mv[0];
                        t_src.ref.ref[1] = t_src.ref.ref[0];
                    } else {
                        t_src.ref.pair = s_src[0].ref.pair;
                    }
                    const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                    call_ref(c_s_dst, s_src, t ? &c_t_dst[t_off] : NULL, 32, &t_src, w, h);
                    call_new(a_s_dst, s_src, t ? &a_t_dst[t_off] : NULL, 32, &t_src, w, h);

                    if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, 0) && t) {
                        check_temporal_mv(&c_t_dst[t_off], 32,
                                          &a_t_dst[t_off], 32, w, h);
                    }

                    if (w == h) {
                        bench_new(a_s_dst, s_src, t ? a_t_dst : NULL, 32, &t_src, w, h);
                    }
                }
            }
        }
    }
    report("splat_mv");
}

static void check_splat_warpmv(const Dav2dRefmvsDSPContext *const c) {
    ALIGN_STK_64(refmvs_block, s_dst, 64 * 128,);
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    ALIGN_STK_64(refmvs_block, s_src, 1,);
    ALIGN_STK_64(refmvs_temporal_block, c_t_dst, 32 * 32,);
    ALIGN_STK_64(refmvs_temporal_block, a_t_dst, 32 * 32,);
    refmvs_temporal_block t_src;

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t t_stride,
                 refmvs_temporal_block *t_src, int bw4, int bh4,
                 const int32_t *matrix);

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
                        s_src[0].ref.ref[0] = rnd() % 7;
                        t_src.ref.pair = 0x101 * s_src[0].ref.ref[0];
                        s_src[0].ref.ref[1] = -1;
                        // increase chance that quantized temporal MV is invalid
                        s_src[0].mv[0].y = wide ? gen_mv(8, 12) : gen_mv(17, 3);
                        s_src[0].mv[0].x = gen_mv(17, 3);
                        s_src[0].mv[1].y = INVALID_MV;
                        s_src[0].mv[1].x = 0;
                        if (!g) {
                            COPY2MV(s_src[0].lmv, s_src[0].mv);
                        }
                        s_src[0].mf = (rnd() & 0xfc) | (!g << 1) | g;
                        s_src[0].bs = bs_from_bwh4(w, h);
                        s_src[0].bx4 = rnd() % ((0x4000 >> (!wide * 7)) - w);
                        s_src[0].by4 = rnd() % ((0x4000 >> (!wide * 7)) - h);
                        int32_t *const mat = s_src[0].m;
                        mat[0] = s_src[0].mv[0].x * (1 << 13);
                        mat[1] = s_src[0].mv[0].y * (1 << 13);
                        const int range = 0x3ff >> (!wide * 4);
                        const int bias = 0x1ff >> (!wide * 4);
                        mat[2] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;
                        mat[3] =  ((rnd() % range) - bias) * (1 << 6);
                        mat[4] =  ((rnd() % range) - bias) * (1 << 6);
                        mat[5] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;

                        const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                        call_ref(c_s_dst, s_src, t ? &c_t_dst[t_off] : NULL, 32, &t_src,
                                 w, h, mat);
                        call_new(a_s_dst, s_src, t ? &a_t_dst[t_off] : NULL, 32, &t_src,
                                 w, h, mat);

                        if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, !g) && t) {
                            check_temporal_mv(&c_t_dst[t_off], 32,
                                              &a_t_dst[t_off], 32, w, h);
                        }

                        if (w == h) {
                            bench_new(a_s_dst, s_src, t ? a_t_dst : NULL, 32, &t_src,
                                      w, h, mat);
                        }
                    }
                }
            }
        }
    report("splat_warpmv");
}

static void check_splat_comp_warpmv(const Dav2dRefmvsDSPContext *const c) {
    ALIGN_STK_64(refmvs_block, s_dst, 64 * 128,);
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    ALIGN_STK_64(refmvs_block, s_src, 1,);
    ALIGN_STK_64(refmvs_temporal_block, c_t_dst, 32 * 32,);
    ALIGN_STK_64(refmvs_temporal_block, a_t_dst, 32 * 32,);
    refmvs_temporal_block t_src;

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t t_stride,
                 refmvs_temporal_block *t_src, int bw4, int bh4,
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

                        s_src[0].ref.ref[0] = t_src.ref.ref[t_swap] = rnd() % 7;
                        s_src[0].ref.ref[1] = t_src.ref.ref[!t_swap] = rnd() % 7;
                        for (int n = 0; n < 2; n++) {
                            // increase chance that quantized temporal MV is invalid
                            s_src[0].mv[n].y = wide ? gen_mv(8, 12) : gen_mv(17, 3);
                            s_src[0].mv[n].x = gen_mv(17, 3);
                        }
                        if (!g) {
                            COPY2MV(s_src[0].lmv, s_src[0].mv);
                        }
                        s_src[0].mf = (rnd() & 0xfc) | (!g << 1) | g;
                        s_src[0].bs = bs_from_bwh4(w, h);
                        s_src[0].bx4 = rnd() % ((0x4000 >> (!wide * 7)) - w);
                        s_src[0].by4 = rnd() % ((0x4000 >> (!wide * 7)) - h);
                        const int widx = rnd() % 68;
                        const uint8_t *const mask = w <= 16 && h <= 16 && rnd() & 1 ?
                            WEDGE_TMVP(s_src[0].bs, w, h, widx) : NULL;
                        const int w_swap = mask && rnd() & 1;

                        int32_t matrix[6], *const mat[2] = { s_src[0].m, matrix };
                        const int range = 0x3ff >> (!wide * 4);
                        const int bias = 0x1ff >> (!wide * 4);
                        for (int n = 0; n < 2; n++) {
                            mat[n][0] = s_src[0].mv[n].x * (1 << 13);
                            mat[n][1] = s_src[0].mv[n].y * (1 << 13);
                            mat[n][2] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;
                            mat[n][3] =  ((rnd() % range) - bias) * (1 << 6);
                            mat[n][4] =  ((rnd() % range) - bias) * (1 << 6);
                            mat[n][5] = (((rnd() % range) - bias) * (1 << 6)) + 0x10000;
                        }

                        const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                        call_ref(c_s_dst, s_src, t ? &c_t_dst[t_off] : NULL, 32, &t_src,
                                 w, h, mat[0], mat[1], t_swap, mask, w_swap);
                        call_new(a_s_dst, s_src, t ? &a_t_dst[t_off] : NULL, 32, &t_src,
                                 w, h, mat[0], mat[1], t_swap, mask, w_swap);

                        if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, !g) && t) {
                            check_temporal_mv(&c_t_dst[t_off], 32,
                                              &a_t_dst[t_off], 32, w, h);
                        }

                        if (w == h) {
                            bench_new(a_s_dst, s_src, t ? a_t_dst : NULL, 32, &t_src,
                                      w, h, mat[0], mat[1], t_swap, mask, w_swap);
                        }
                    }
                }
            }
        }
    report("splat_comp_warpmv");
}

static void check_splat_comp_wedgemv(const Dav2dRefmvsDSPContext *const c) {
    ALIGN_STK_64(refmvs_block, s_dst, 64 * 128,);
    refmvs_block *const c_s_dst = s_dst, *const a_s_dst = &s_dst[64];
    ALIGN_STK_64(refmvs_block, s_src, 1,);
    ALIGN_STK_64(refmvs_temporal_block, c_t_dst, 32 * 32,);
    ALIGN_STK_64(refmvs_temporal_block, a_t_dst, 32 * 32,);
    refmvs_temporal_block t_src;

    declare_func(void, refmvs_block *s_dst, refmvs_block *s_src,
                 refmvs_temporal_block *t_dst, ptrdiff_t t_stride,
                 refmvs_temporal_block *t_src, int bw4, int bh4,
                 const uint8_t *wedge, intptr_t w_mask);

    for (int t = 0; t < 2; t++) {
        for (int w = 2; w <= 16; w *= 2) {
            if (check_func(c->splat_comp_wedgemv, "splat_%s_comp_wedgemv_w%d",
                           t ? "spatialtemporal" : "spatial", w * 4))
            {
                for (int h = 2; h <= 16; h *= 2) {
                    s_src[0].ref.ref[0] = rnd() % 7;
                    s_src[0].ref.ref[1] = rnd() % 7;
                    for (int n = 0; n < 2; n++) {
                        // increase chance that quantized temporal MV is invalid
                        s_src[0].mv[n].y = rnd() & 1 ? gen_mv(8, 12) : gen_mv(17, 3);
                        s_src[0].mv[n].x = gen_mv(17, 3);
                    }
                    s_src[0].mf = rnd() & 0xfd;
                    s_src[0].bs = bs_from_bwh4(w, h);
                    s_src[0].bx4 = rnd() % (0x4000 - w);
                    s_src[0].by4 = rnd() % (0x4000 - h);
                    const int widx = rnd() % 68;
                    const uint8_t *const mask = WEDGE_TMVP(s_src[0].bs, w, h, widx);
                    const int w_swap = rnd() & 1;

                    t_src.ref.pair = s_src[0].ref.pair;
                    t_src.mv.mv[0] = quantize_mv(s_src[0].mv[0]);
                    t_src.mv.mv[1] = quantize_mv(s_src[0].mv[1]);
                    const ptrdiff_t t_off = w >= 16 ? (w >> 1) & 31 : 1;

                    call_ref(c_s_dst, s_src, t ? &c_t_dst[t_off] : NULL, 32, &t_src,
                             w, h, mask, w_swap);
                    call_new(a_s_dst, s_src, t ? &a_t_dst[t_off] : NULL, 32, &t_src,
                             w, h, mask, w_swap);

                    if (!check_spatial_mv(c_s_dst, 128, a_s_dst, 128, w, h, 0) && t) {
                        check_temporal_mv(&c_t_dst[t_off], 32,
                                          &a_t_dst[t_off], 32, w, h);
                    }

                    if (w == h) {
                        bench_new(a_s_dst, s_src, t ? a_t_dst : NULL, 32, &t_src,
                                  w, h, mask, w_swap);
                    }
                }
            }
        }
    }
    report("splat_comp_wedgemv");
}

void checkasm_check_refmvs(void) {
    Dav2dRefmvsDSPContext c;
    dav2d_refmvs_dsp_init(&c);

    check_splat_mv(&c);
    check_splat_warpmv(&c);
    check_splat_comp_warpmv(&c);
    check_splat_comp_wedgemv(&c);
}
