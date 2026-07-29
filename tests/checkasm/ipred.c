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
#include "src/ipred.h"
#include "src/levels.h"

#include <stdio.h>

static const char *const intra_pred_mode_names[N_IMPL_INTRA_PRED_MODES] = {
    [DC_PRED]       = "dc",
    [DC_128_PRED]   = "dc_128",
    [TOP_DC_PRED]   = "dc_top",
    [LEFT_DC_PRED]  = "dc_left",
    [HOR_PRED]      = "h",
    [VERT_PRED]     = "v",
    [PAETH_PRED]    = "paeth",
    [SMOOTH_PRED]   = "smooth",
    [SMOOTH_V_PRED] = "smooth_v",
    [SMOOTH_H_PRED] = "smooth_h",
    [Z1_PRED]       = "z1",
    [Z2_PRED]       = "z2",
    [Z3_PRED]       = "z3",
    [DIP_PRED]      = "dip"
};

static const char *const cfl_pred_type_names[3] = { "cfl_explicit", "cfl_implicit" };
static const char *const cfl_luma_filter_names[3] = { "uniform", "vstrip", "gauss" };
static const char cfl_mh_dir_names[3] = { 'c', 't', 'l' };
static const char *const layout_names[3] = { "420", "422", "444" };

static const uint8_t z_angles[27] = {
     3,  6,  9,
    14, 17, 20, 23, 26, 29, 32,
    36, 39, 42, 45, 48, 51, 54,
    58, 61, 64, 67, 70, 73, 76,
    81, 84, 87
};

/* Generate max_width/max_height values that covers all edge cases */
static int gen_z_max_wh(const int sz) {
    const int n = rnd();
    if (n & (1 << 17)) /* edge block */
        return (n & (sz - 1)) + 1;
    if (n & (1 << 16)) /* max size, exceeds uint16_t */
        return 65536;
    return (n & 65535) + 1;
}

static void check_intra_pred(Dav2dIntraPredDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    ALIGN_STK_64(pixel, topleft_buf, 64 * 8 + 2 * 1 + 2 * 9,);
#if BITDEPTH == 16
    const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
    const int bitdepth_max = 0xff;
#endif

    declare_func(void, pixel *dst, ptrdiff_t stride, const pixel *topleft,
                 int width, int height, int angle, int max_width, int max_height
                 HIGHBD_DECL_SUFFIX);

    for (int i = 0; i < 64 * 8 + 2 * 1 + 2 * 9; i++)
        topleft_buf[i] = rnd() & bitdepth_max;

    for (int mode = 0; mode < N_IMPL_INTRA_PRED_MODES; mode++) {
        for (int w = 4; w <= 64; w <<= 1) {
            pixel *const u_dst = w == 64 ? a_dst : a_dst + 4;
            if (check_func(c->intra_pred[mode], "intra_pred_%s_w%d_%dbpc",
                intra_pred_mode_names[mode], w, BITDEPTH))
            {
                for (int h = 4; h <= 64; h <<= 1) {
                    const ptrdiff_t stride = c_dst_stride;
                    int nb_iters = (mode >= Z1_PRED && mode <= Z3_PRED) ? 5 : 1;

                    for (int iter = 0; iter < nb_iters; iter++) {
                        int a = 0, maxw = 0, maxh = 0;
                        if (mode >= Z1_PRED && mode <= Z3_PRED) { /* angle */
                            a = (90 * (mode - Z1_PRED) + z_angles[rnd() % 27]) |
                                (rnd() & 0xffe00);
                            if (imin(w, h) == 4)
                                a &= ~(ANGLE_MULTI_MRL_FLAG | ANGLE_IBP_FLAG);
                            if (a & ANGLE_MULTI_MRL_FLAG) a |= ANGLE_IS_LUMA;
                            maxw = gen_z_max_wh(w);
                            maxh = gen_z_max_wh(h);
                        } else if (mode == DIP_PRED) {
                            /* dip_idx */
                            a = (rnd() % 5) | (rnd() & 16);
                        } else if (mode == HOR_PRED || mode == VERT_PRED) {
                            if (imax(w, h) > 4)
                                a = (rnd() & 1) * ANGLE_MULTI_MRL_FLAG;
                        } else if (mode == DC_PRED || mode == LEFT_DC_PRED ||
                                   mode == TOP_DC_PRED)
                        {
                            if (imax(w, h) > 4)
                                a = (rnd() & 1) * ANGLE_IBP_FLAG;
                        }
                        pixel *const topleft = topleft_buf + 128 + 9;

                        CLEAR_PIXEL_RECT(c_dst);
                        CLEAR_PIXEL_RECT(a_dst);
                        call_ref(c_dst, stride, topleft, w, h, a, maxw, maxh
                                 HIGHBD_TAIL_SUFFIX);
                        call_new(u_dst, stride, topleft, w, h, a, maxw, maxh
                                 HIGHBD_TAIL_SUFFIX);
                        if (checkasm_check_pixel_padded(c_dst, stride,
                                                        u_dst, stride,
                                                        w, h, "dst"))
                        {
                            if (mode >= Z1_PRED && mode <= Z3_PRED)
                                fprintf(stderr, "angle = %d (0x%05x), "
                                        "max_width = %d, max_height = %d\n",
                                        a & 0x1ff, a & 0xffe00, maxw, maxh);
                            else if (mode == DIP_PRED)
                                fprintf(stderr, "dip tp = %d, mode = %d\n", a > 7, a & 7);
                            else if (mode == HOR_PRED || mode == VERT_PRED)
                                fprintf(stderr, "multimrl=%d\n", !!a);
                            else if (mode == DC_PRED || mode == LEFT_DC_PRED ||
                                     mode == TOP_DC_PRED)
                            {
                                fprintf(stderr, "ibp=%d\n", !!a);
                            }
                            break;
                        }

                        bench_new(a_dst, stride, topleft, w, h, a, 128, 128
                                  HIGHBD_TAIL_SUFFIX);
                    }
                }
            }
        }
    }
    report("intra_pred");
}

static void check_cfl_pred(Dav2dIntraPredDSPContext *const c) {
    PIXEL_RECT(y, 128, 128);
    PIXEL_RECT(c_u, 128, 128);
    PIXEL_RECT(c_v, 128, 128);
    PIXEL_RECT(a_u, 128, 128);
    PIXEL_RECT(a_v, 128, 128);
    ALIGN_STK_64(pixel, top_sb, 3 * 128,);
    pixel *const c_u0 = c_u, *const c_v0 = c_v, *const y0 = y;
    pixel *const a_u0 = a_u, *const a_v0 = a_v;
    const int itse = rnd() & CFL_IS_TOP_SB_EDGE;
#if BITDEPTH == 16
    const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
    const int bitdepth_max = 0xff;
#endif

    declare_func(void, pixel *const *ptrs, const ptrdiff_t *stride,
                 int wpad, int hpad, int w, int h, int flags HIGHBD_DECL_SUFFIX);

    for (enum CflType type = CFL_EXPLICIT; type <= CFL_IMPLICIT; type++) {
        if (type == CFL_EXPLICIT) {
            INIT_PIXEL_RECT(y_buf);
            if (itse)
                INIT_PIXEL_RECT(top_sb);
        } else {
            // pathological test pixel values generate 0 alphas, but we still
            // need to test for overflow during luma regression
            if (!(rnd() & 3)) {
                for (unsigned i = 0; i < ARRAY_SIZE(y_buf); i++)
                    y_buf[i] = bitdepth_max;
                if (itse)
                    for (unsigned i = 0; i < ARRAY_SIZE(top_sb); i++)
                        top_sb[i] = bitdepth_max;
            } else {
                RAND_PIXEL_RECT(y_buf);
                if (itse)
                    RAND_PIXEL_RECT(top_sb);
            }
        }

        for (int layout = 1; layout <= DAV2D_PIXEL_LAYOUT_I444; layout++) {
            const int ss_hor = layout != DAV2D_PIXEL_LAYOUT_I444;
            const int ss_ver = layout == DAV2D_PIXEL_LAYOUT_I420;
            const ptrdiff_t strides[2] = { y_stride, c_u_stride >> ss_hor };
            for (int w = 4; w <= 64; w <<= 1)
                for (int padding = 0; padding <= 1; padding++)
                    for (int rng0 = 1; rng0 >= 0; rng0--)
                        for (int flt_type = CFL_FLT_TYPE_UNIFORM;
                             flt_type <= CFL_FLT_TYPE_GAUSS; flt_type++)
                        {
                            if (check_func(c->cfl_pred[type][layout - 1],
                                "%s_%s_w%d_pad%d_%s_%s_%dbpc",
                                cfl_pred_type_names[type], layout_names[layout - 1],
                                w, padding, rng0 ? "uv" : "u_or_v",
                                cfl_luma_filter_names[flt_type], BITDEPTH))
                            {
                                const int h0 = padding && w < 16 ? 16 : 4;
                                for (int h = h0; h <= 64; h <<= 1) {
                                    int wpad = 0, hpad = 0;
                                    if (padding) {
                                        wpad = imax(w > 8, rnd() & imax(w / 8 - 1, 0));
                                        hpad = imax(h > 8, rnd() & imax(h / 8 - 1, 0));
                                    }

                                    int flags = flt_type | itse |
                                        (rnd() & (CFL_HAS_TOP | CFL_HAS_LEFT));
                                    if (type == CFL_EXPLICIT) {
                                        int alpha_u = 1 - (rnd() & 2); // sign
                                        int alpha_v = 1 - (rnd() & 2);
                                        alpha_u *= rng0 + (rnd() % (9 - rng0));
                                        alpha_v *= rng0 == 0 && alpha_u ? 0 :
                                            1 + (rnd() % 8);
                                        flags |= (alpha_u * (1 << CFL_ALPHA_U_SHIFT)) & CFL_ALPHA_U_MASK;
                                        flags |= (alpha_v * (1 << CFL_ALPHA_V_SHIFT)) & CFL_ALPHA_V_MASK;
                                    }

                                    const int unaligned_offset = imax(w / 4, 4);
                                    y = y0 + (unaligned_offset << ss_hor);
                                    c_u = c_u0 + unaligned_offset;
                                    a_u = a_u0 + unaligned_offset;
                                    c_v = c_v0 + unaligned_offset;
                                    a_v = a_v0 + unaligned_offset;
                                    pixel *ytop = itse ? top_sb : y - (1 + ss_ver) * strides[0];
                                    pixel *utop = itse ? top_sb + 128 : c_u - strides[1];
                                    pixel *vtop = itse ? top_sb + 256 : c_v - strides[1];
                                    pixel *const c_ptrs[6] = { ytop, utop, vtop, y, c_u, c_v };
                                    pixel *const a_ptrs[6] = { ytop, utop, vtop, y, a_u, a_v };

                                    if (type == CFL_EXPLICIT) {
                                        INIT_PIXEL_RECT(c_u_buf);
                                        INIT_PIXEL_RECT(c_v_buf);
                                    } else {
                                        RAND_PIXEL_RECT(c_u_buf);
                                        if (rng0)
                                            RAND_PIXEL_RECT(c_v_buf);
                                        else
                                            memset(c_v_buf, 0, sizeof(c_v_buf));
                                    }
                                    memcpy(a_u_buf, c_u_buf, c_u_buf_h * c_u_stride);
                                    memcpy(a_v_buf, c_v_buf, c_v_buf_h * c_v_stride);

                                    call_ref(c_ptrs, strides, wpad, hpad, w, h, flags HIGHBD_TAIL_SUFFIX);
                                    call_new(a_ptrs, strides, wpad, hpad, w, h, flags HIGHBD_TAIL_SUFFIX);

                                    checkasm_check_pixel_padded(c_u, strides[1],
                                                                a_u, strides[1], w, h, "u_dst");
                                    checkasm_check_pixel_padded(c_v, strides[1],
                                                                a_v, strides[1], w, h, "v_dst");

                                    if (padding) {
                                        wpad = imax(w / 8 - 1, 0);
                                        hpad = imax(h / 8 - 1, 0);
                                    }
                                    // re-init luma buffers to prevent 0 alphas
                                    if (type == CFL_IMPLICIT) {
                                        RAND_PIXEL_RECT(y_buf);
                                        RAND_PIXEL_RECT(top_sb);
                                    }

                                    bench_new(a_ptrs, strides, wpad, hpad, w, h,
                                              flags | (CFL_HAS_TOP | CFL_HAS_LEFT)
                                              HIGHBD_TAIL_SUFFIX);
                                }
                            }
                        }
        }
        report("%s", cfl_pred_type_names[type]);
    }
}

static void check_cfl_mh_gen_y(Dav2dIntraPredDSPContext *const c) {
    PIXEL_RECT(src0, 128, 128);
    ALIGN_STK_64(pixel, top_sb0, 64+128,);
    ALIGN_STK_64(pixel, c_dst, CFL_MH_MAX_LUMA_SIZE,);
    ALIGN_STK_64(pixel, a_dst, CFL_MH_MAX_LUMA_SIZE,);
#if BITDEPTH == 16
    const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
    const int bitdepth_max = 0xff;
#endif

    declare_func(void, pixel *dst, const pixel *src, const pixel *top_sb_edge,
                 ptrdiff_t src_stride, int refw, int refh, int w, int h, int flags);

    INIT_PIXEL_RECT(src0_buf);
    INIT_PIXEL_RECT(top_sb0);

    for (int layout = 1; layout <= DAV2D_PIXEL_LAYOUT_I444; layout++) {
        const int ss_hor = layout != DAV2D_PIXEL_LAYOUT_I444;
        const int ss_ver = layout == DAV2D_PIXEL_LAYOUT_I420;
        for (int w = 4; w <= 64; w <<= 1)
#define BENCH_DIR 0
#if BENCH_DIR
            for (int dir = CFL_DIR_CENTER; dir < CFL_DIR_ALL; dir++)
#endif
            for (int padding = 0; padding <= 1; padding++)
                for (int flt_type = CFL_FLT_TYPE_UNIFORM;
                     flt_type <= CFL_FLT_TYPE_GAUSS; flt_type++)
                {
#if BENCH_DIR
                    if (check_func(c->cfl_mh_gen_y[layout - 1][flt_type],
                        "cfl_mh_gen_y_%s_%s_w%d_%c_pad%d_%dbpc",
                        layout_names[layout - 1], cfl_luma_filter_names[flt_type],
                        w, cfl_mh_dir_names[dir], padding, BITDEPTH))
#else
                    if (check_func(c->cfl_mh_gen_y[layout - 1][flt_type],
                        "cfl_mh_gen_y_%s_%s_w%d_pad%d_%dbpc",
                        layout_names[layout - 1], cfl_luma_filter_names[flt_type],
                        w, padding, BITDEPTH))
#endif
                    {
#if !BENCH_DIR
                        for (int dir = CFL_DIR_CENTER; dir < CFL_DIR_ALL; dir++) {
#endif
                            const int h0 = padding && w < 16 ? 16 : 4;
                            for (int h = h0; h <= 64; h <<= 1) {
                                int wpad = 0, hpad = 0;
                                if (padding) {
                                    wpad = imax(w > 8, rnd() & imax(w / 8 - 1, 0));
                                    hpad = imax(h > 8, rnd() & imax(h / 8 - 1, 0));
                                }

                                const int has_t = rnd() & CFL_HAS_TOP;
                                const int has_l = rnd() & CFL_HAS_LEFT;
                                const int itse = rnd() & CFL_IS_TOP_SB_EDGE;
                                const int flags = dir | has_t | has_l | itse;
                                const int dir_l = dir == CFL_DIR_LEFT;

                                int refw = w - wpad * 4 + 2 * !!has_l;
                                int refh = h - hpad * 4;
                                int subleft = has_l && !dir_l;
                                if (has_t && !wpad) {
                                    const int avail = rnd() % (3 - (w == 4));
                                    if (avail == 1) // full
                                        refw += w;
                                    else if (avail == 2) // partial
                                        refw += (rnd() % w) & ~3;
                                }
                                if (has_l && !hpad) {
                                    const int avail = rnd() % 3;
                                    if (avail == 1)
                                        refh += (rnd() % h) & ~3;
                                    else if (avail == 2)
                                        refh += h;
                                }
                                if (refw > 128 >> ss_hor) {
                                    refw = 128 >> ss_hor;
                                    subleft = 0;
                                }
                                refh = imin(refh, (128 >> ss_ver) - 2 * !!has_t);

                                const int unaligned_offset = imax(w / 4, 4);
                                pixel *const src = src0 + (unaligned_offset << ss_hor);
                                pixel *const top_sb = itse ? top_sb0 + 64 : NULL;

                                call_ref(c_dst, src, top_sb, src0_stride,
                                         refw - subleft, refh, w, h, flags);
                                call_new(a_dst, src, top_sb, src0_stride,
                                         refw - subleft, refh, w, h, flags);

                                const int n_top = has_t ? 1 + (dir == CFL_DIR_TOP) : 0;
                                const int n_left = has_l ? 1 + (dir == CFL_DIR_LEFT) : 0;
                                const int blk_off = n_top * CFL_MH_TOP_STRIDE;
                                const pixel *const c_left = c_dst + blk_off + 64 * 64;
                                const pixel *const a_left = a_dst + blk_off + 64 * 64;
                                const pixel *const c_blk = c_dst + blk_off;
                                const pixel *const a_blk = a_dst + blk_off;

                                checkasm_check_pixel(c_dst, CFL_MH_TOP_STRIDE * sizeof(pixel),
                                                     a_dst, CFL_MH_TOP_STRIDE * sizeof(pixel),
                                                     refw - subleft, n_top, "top");
                                checkasm_check_pixel(c_left, n_left, a_left, n_left,
                                                     n_left, refh, "left");
                                checkasm_check_pixel(c_blk, w, a_blk, w, w, h, "blk");

                                bench_new(a_dst, src, top_sb, src0_stride,
                                          refw - subleft, refh, w, h,
                                          flags | CFL_HAS_TOP | CFL_HAS_LEFT);
                            }
#if !BENCH_DIR
                        }
#endif
                    }
                }
    }

    report("cfl_mh_gen_y");
}

static void check_cfl_mh_gen_mat(Dav2dIntraPredDSPContext *const c) {
    ALIGN_STK_64(pixel, luma, CFL_MH_MAX_LUMA_SIZE,);
    uint16_t c_imat[2][CFL_MH_MAX_EDGE_SAMPLES];
    uint16_t a_imat[2][CFL_MH_MAX_EDGE_SAMPLES];
    int32_t c_mat[3][3], *c_mat_ptr = (int32_t *) c_mat;
    int32_t a_mat[3][3], *a_mat_ptr = (int32_t *) a_mat;
    const ptrdiff_t mat_stride = 3 * sizeof(int32_t);
#if BITDEPTH == 16
    const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
    const int bitdepth_max = 0xff;
#endif

    declare_func(void, int32_t mat[3][3], uint16_t imat[2][CFL_MH_MAX_EDGE_SAMPLES],
                 const pixel *luma, int refw, int refh, int edge_flags HIGHBD_DECL_SUFFIX);

    INIT_PIXEL_RECT(luma);

    for (int dir = CFL_DIR_CENTER; dir < CFL_DIR_ALL; dir++)
        if (check_func(c->cfl_mh_gen_mat[dir], "cfl_mh_gen_mat_%c_%dbpc",
            cfl_mh_dir_names[dir], BITDEPTH))
        {
            const int has_t = rnd() & 1;
            const int has_l = has_t ? rnd() & 1 : 1;
            const int n_left = has_l ? 1 + (dir == CFL_DIR_LEFT) : 0;
            const int refw = imin(4 + 4 * (rnd() & 31) + n_left, 128);
            const int refh = imin(4 + 4 * (rnd() & 31), 128 - has_t);
            const int edge_flags = (has_t * CFL_HAS_TOP) | (has_l * CFL_HAS_LEFT);

            call_ref(c_mat, c_imat, luma, refw, refh, edge_flags HIGHBD_TAIL_SUFFIX);
            call_new(a_mat, a_imat, luma, refw, refh, edge_flags HIGHBD_TAIL_SUFFIX);

            checkasm_check1d(uint16_t, c_imat[0], a_imat[0],
                             has_t * (refw - 2) + has_l * (refh - 2), "imat0");
            checkasm_check1d(uint16_t, c_imat[1], a_imat[1],
                             has_t * (refw - 2) + has_l * (refh - 2), "imat1");
            checkasm_check2d(int32_t, c_mat_ptr, mat_stride, a_mat_ptr, mat_stride,
                             3, 3, "mat");

            bench_new(a_mat, a_imat, luma, refw, refh, edge_flags HIGHBD_TAIL_SUFFIX);
        }

    report("cfl_mh_gen_mat");
}

static void check_cfl_mh_calc_alphas(Dav2dIntraPredDSPContext *const c) {
    PIXEL_RECT(chroma, 129, 129);
    pixel luma[CFL_MH_MAX_EDGE_SAMPLES];
    uint16_t imat[2][CFL_MH_MAX_EDGE_SAMPLES];
    int32_t mat[3][3] = {{ 0 }};
#if BITDEPTH == 16
    const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
    const int bitdepth_max = 0xff;
#endif
    const int bd = bitdepth_from_max(bitdepth_max);
    const int mid = 1 << (bd - 1);
    int c_alpha[3], a_alpha[3];

    declare_func(void, int alpha[3], const pixel *c, const pixel *top_sb_edge,
                 ptrdiff_t stride, int refw, int refh, const int32_t mat[3][3],
                 const uint16_t imat[2][CFL_MH_MAX_EDGE_SAMPLES],
                 int edge_flags HIGHBD_DECL_SUFFIX);

    INIT_PIXEL_RECT(chroma_buf);
    INIT_PIXEL_RECT(luma);

    if (check_func(c->cfl_mh_calc_alphas, "cfl_mh_calc_alphas_%dbpc", BITDEPTH)) {
        const int has_t = rnd() & 1;
        const int has_l = has_t ? rnd() & 1 : 1;
        const int itse = rnd() & 1;
        const int dir = rnd() % 3;
        const int n_left = has_l ? 1 + (dir == CFL_DIR_LEFT) : 0;
        const int refw = imin(4 + 4 * (rnd() & 31) + n_left, 128);
        const int refh = imin(4 + 4 * (rnd() & 31), 128 - has_t);
        const int edge_flags = (has_t * CFL_HAS_TOP) | (has_l * CFL_HAS_LEFT);
        int n;

        for (n = 0; n < has_t * (refw - 2) + has_l * (refh - 2); n++) {
            const int v0 = luma[n];
            int v1 = dir == CFL_DIR_CENTER ? v0 :
                rnd() & 1 ? // allow_far_neighbor
                    rnd() & bitdepth_max : iclip_pixel(v0 + (rnd() & 15) - 8);
            v1 = (v1 * v1 + mid) >> bd;

            imat[0][n] = v0;
            imat[1][n] = v1;
            mat[0][0] += v0 * v0;
            mat[0][1] += v0 * v1;
            mat[0][2] += v0 << (bd - 1);
            mat[1][1] += v1 * v1;
            mat[1][2] += v1 << (bd - 1);
        }
        mat[2][2] = n << ((bd - 1) << 1);

        const int nl2 = 31 - clz(n);
        const int mat_sh = 22 - 2 * bd - nl2 - !!(n & ((1 << nl2) - 1));
        if (mat_sh > 0)
            for (int i = 0; i < 3; i++)
                for (int j = i; j < 3; j++)
                    mat[i][j] <<= mat_sh;
        else if (mat_sh < 0)
            for (int i = 0; i < 3; i++)
                for (int j = i; j < 3; j++)
                    mat[i][j] >>= -mat_sh;
        mat[0][0] += 2 << (bd - 8);
        mat[1][1] += 2 << (bd - 8);
        mat[2][2] += 2 << (bd - 8);
        mat[1][0] = mat[0][1];
        mat[2][0] = mat[0][2];
        mat[2][1] = mat[1][2];

        call_ref(c_alpha, chroma, itse ? chroma + PXSTRIDE(chroma_stride) : NULL,
                 chroma_stride, refw, refh, mat, imat, edge_flags HIGHBD_TAIL_SUFFIX);
        call_new(a_alpha, chroma, itse ? chroma + PXSTRIDE(chroma_stride) : NULL,
                 chroma_stride, refw, refh, mat, imat, edge_flags HIGHBD_TAIL_SUFFIX);

        if (memcmp(c_alpha, a_alpha, sizeof(c_alpha)) && fail())
            fprintf(stderr, "expected { %d, %d, %d }, got { %d, %d, %d }\n",
                    c_alpha[0], c_alpha[1], c_alpha[2],
                    a_alpha[0], a_alpha[1], a_alpha[2]);

        bench_new(a_alpha, chroma, itse ? chroma + PXSTRIDE(chroma_stride) : NULL,
                  chroma_stride, refw, refh, mat, imat, edge_flags HIGHBD_TAIL_SUFFIX);
    }

    report("cfl_calc_alphas");
}

static void check_cfl_mh_pred(Dav2dIntraPredDSPContext *const c) {
    ALIGN_STK_64(pixel, luma_buf, CFL_MH_MAX_LUMA_SIZE,);
    PIXEL_RECT(c_chroma, 64, 64);
    PIXEL_RECT(a_chroma, 64, 64);
    int alpha[3];
#if BITDEPTH == 16
    const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
    const int bitdepth_max = 0xff;
#endif

    INIT_PIXEL_RECT(luma_buf);
    for (int i = 0; i < 3; i++)
        alpha[i] = -0x20000 + rnd() % (0x40001);

    declare_func(void, pixel *dst, ptrdiff_t dst_stride, const pixel *src,
                 int w, int h, const int alpha[3], int edge_flags HIGHBD_DECL_SUFFIX);

    for (int dir = CFL_DIR_CENTER; dir < CFL_DIR_ALL; dir++)
        for (int w = 4; w <= 64; w <<= 1)
            if (check_func(c->cfl_mh_pred[dir], "cfl_mh_pred_%c_w%d_%dbpc",
                           cfl_mh_dir_names[dir], w, BITDEPTH))
                for (int h = 4; h <= 64; h <<= 1) {
                    const int has_t = rnd() & CFL_HAS_TOP;
                    const int has_l = rnd() & CFL_HAS_LEFT;
                    const int edge_flags = has_t | has_l;
                    const int n_top = has_t ? 1 + (dir == CFL_DIR_TOP) : 0;
                    const pixel *luma = luma_buf + n_top * 128;

                    CLEAR_PIXEL_RECT(c_chroma);
                    CLEAR_PIXEL_RECT(a_chroma);

                    call_ref(c_chroma, c_chroma_stride, luma, w, h, alpha,
                             edge_flags HIGHBD_TAIL_SUFFIX);
                    call_new(a_chroma, a_chroma_stride, luma, w, h, alpha,
                             edge_flags HIGHBD_TAIL_SUFFIX);

                    checkasm_check_pixel_padded(c_chroma, c_chroma_stride,
                                                a_chroma, a_chroma_stride, w, h, "dst");

                    luma = luma_buf + (1 + (dir == CFL_DIR_TOP)) * 128;
                    bench_new(a_chroma, a_chroma_stride, luma, w, h, alpha,
                              edge_flags | CFL_HAS_TOP | CFL_HAS_LEFT HIGHBD_TAIL_SUFFIX);
                }

    report("cfl_mh_pred");
}

static void check_pal_pred(Dav2dIntraPredDSPContext *const c) {
    PIXEL_RECT(c_dst, 64, 64);
    PIXEL_RECT(a_dst, 64, 64);
    ALIGN_STK_64(uint8_t, idx, 32 * 64,);
    ALIGN_STK_16(pixel, pal, 8,);

    declare_func(void, pixel *dst, ptrdiff_t stride, const pixel *pal,
                 const uint8_t *idx, int w, int h);

    for (int w = 4; w <= 64; w <<= 1) {
        pixel *const u_dst = w == 64 ? a_dst : a_dst + 4;
        if (check_func(c->pal_pred, "pal_pred_w%d_%dbpc", w, BITDEPTH))
            for (int h = imax(4, 64 / w); h <= 64; h <<= 1) {
#if BITDEPTH == 16
                const int bitdepth_max = rnd() & 1 ? 0x3ff : 0xfff;
#else
                const int bitdepth_max = 0xff;
#endif

                for (int i = 0; i < 8; i++)
                    pal[i] = rnd() & bitdepth_max;

                for (int i = 0; i < w * h / 2; i++)
                    idx[i] = rnd() & 0x77;

                CLEAR_PIXEL_RECT(c_dst);
                CLEAR_PIXEL_RECT(a_dst);

                call_ref(c_dst, c_dst_stride, pal, idx, w, h);
                call_new(u_dst, a_dst_stride, pal, idx, w, h);
                checkasm_check_pixel_padded(c_dst, c_dst_stride,
                                            u_dst, a_dst_stride, w, h, "dst");

                bench_new(a_dst, a_dst_stride, pal, idx, w, h);
            }
    }
    report("pal_pred");
}

void bitfn(checkasm_check_ipred)(void) {
    Dav2dIntraPredDSPContext c = {{ 0 }};
    bitfn(dav2d_intra_pred_dsp_init)(&c);

    check_intra_pred(&c);
    check_cfl_pred(&c);
    check_cfl_mh_gen_y(&c);
    check_cfl_mh_gen_mat(&c);
    check_cfl_mh_calc_alphas(&c);
    check_cfl_mh_pred(&c);
    check_pal_pred(&c);
}
