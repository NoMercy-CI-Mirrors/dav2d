/*
 * Copyright © 2018-2021, VideoLAN and dav2d authors
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

#include "src/cpu.h"
#include "src/ipred.h"

#define decl_fn(type, name) \
    decl_##type##_fn(BF(dav2d_##name, ssse3)); \
    decl_##type##_fn(BF(dav2d_##name, avx2)); \
    decl_##type##_fn(BF(dav2d_##name, avx512icl))

#define init_fn(type0, type1, name, suffix) \
    c->type0[type1] = BF(dav2d_##name, suffix)

#define init_angular_ipred_fn(type, name, suffix) \
    init_fn(intra_pred, type, name, suffix)

#define init_cfl_pred_fn(type, type_name, layout, suffix) \
    init_fn(cfl_pred[CFL_##type], DAV2D_PIXEL_LAYOUT_I##layout - 1, \
            cfl_##type_name##_##layout, suffix)

#define init_cfl_explicit_fn(layout, suffix) \
    init_cfl_pred_fn(EXPLICIT, explicit, layout, suffix)

#define init_cfl_implicit_fn(layout, suffix) \
    init_cfl_pred_fn(IMPLICIT, implicit, layout, suffix)

#define init_cfl_fns(layout, suffix) \
    init_cfl_explicit_fn(layout, suffix); \
    init_cfl_implicit_fn(layout, suffix)

#define init_cfl_mh_gen_y_fn(layout, flt_type, flt_name, suffix) \
    init_fn(cfl_mh_gen_y[DAV2D_PIXEL_LAYOUT_I##layout - 1], CFL_FLT_TYPE_##flt_type, \
            cfl_mh_gen_y_##layout##_##flt_name, suffix)

#define init_cfl_mh_gen_y_fns(layout, suffix) \
    init_cfl_mh_gen_y_fn(layout, UNIFORM, uniform, suffix); \
    init_cfl_mh_gen_y_fn(layout, VSTRIP, vstrip, suffix); \
    init_cfl_mh_gen_y_fn(layout, GAUSS, gauss, suffix)

#define init_cfl_mh_pred_fn(dir, dir_name, suffix) \
    init_fn(cfl_mh_pred, dir, cfl_mh_pred_##dir_name, suffix)

#define init_cfl_mh_pred_fns(suffix) \
    init_cfl_mh_pred_fn(CFL_DIR_CENTER, c, suffix); \
    init_cfl_mh_pred_fn(CFL_DIR_TOP,    t, suffix); \
    init_cfl_mh_pred_fn(CFL_DIR_LEFT,   l, suffix)

#define init_cfl_mh_fns(suffix) \
    init_cfl_mh_gen_y_fns(420, suffix); \
    c->cfl_mh_gen_mat = BF(dav2d_cfl_mh_gen_mat, suffix); \
    c->cfl_mh_calc_alphas = BF(dav2d_cfl_mh_calc_alphas, suffix); \
    init_cfl_mh_pred_fns(suffix)

decl_fn(angular_ipred, ipred_dc);
decl_fn(angular_ipred, ipred_dc_128);
decl_fn(angular_ipred, ipred_dc_top);
decl_fn(angular_ipred, ipred_dc_left);
decl_fn(angular_ipred, ipred_h);
decl_fn(angular_ipred, ipred_v);
decl_fn(angular_ipred, ipred_paeth);
decl_fn(angular_ipred, ipred_smooth);
decl_fn(angular_ipred, ipred_smooth_h);
decl_fn(angular_ipred, ipred_smooth_v);
decl_fn(angular_ipred, ipred_z1);
decl_fn(angular_ipred, ipred_z2);
decl_fn(angular_ipred, ipred_z3);
decl_fn(angular_ipred, ipred_dip);

decl_fn(cfl_pred,           cfl_explicit_420);
decl_fn(cfl_pred,           cfl_implicit_420);
decl_fn(cfl_mh_gen_y,       cfl_mh_gen_y_420_uniform);
decl_fn(cfl_mh_gen_y,       cfl_mh_gen_y_420_vstrip);
decl_fn(cfl_mh_gen_y,       cfl_mh_gen_y_420_gauss);
decl_fn(cfl_mh_gen_mat,     cfl_mh_gen_mat);
decl_fn(cfl_mh_calc_alphas, cfl_mh_calc_alphas);
decl_fn(cfl_mh_pred,        cfl_mh_pred_c);
decl_fn(cfl_mh_pred,        cfl_mh_pred_t);
decl_fn(cfl_mh_pred,        cfl_mh_pred_l);

decl_fn(pal_pred, pal_pred);

static ALWAYS_INLINE void intra_pred_dsp_init_x86(Dav2dIntraPredDSPContext *const c) {
    const unsigned flags = dav2d_get_cpu_flags();

    if (!(flags & DAV2D_X86_CPU_FLAG_SSSE3)) return;

#if 0
    init_angular_ipred_fn(DC_PRED,       ipred_dc,       ssse3);
#endif
    init_angular_ipred_fn(DC_128_PRED,   ipred_dc_128,   ssse3);
#if 0
    init_angular_ipred_fn(TOP_DC_PRED,   ipred_dc_top,   ssse3);
    init_angular_ipred_fn(LEFT_DC_PRED,  ipred_dc_left,  ssse3);
    init_angular_ipred_fn(HOR_PRED,      ipred_h,        ssse3);
    init_angular_ipred_fn(VERT_PRED,     ipred_v,        ssse3);
#endif
    init_angular_ipred_fn(PAETH_PRED,    ipred_paeth,    ssse3);
#if 0
    init_angular_ipred_fn(SMOOTH_PRED,   ipred_smooth,   ssse3);
    init_angular_ipred_fn(SMOOTH_H_PRED, ipred_smooth_h, ssse3);
    init_angular_ipred_fn(SMOOTH_V_PRED, ipred_smooth_v, ssse3);
    init_angular_ipred_fn(Z1_PRED,       ipred_z1,       ssse3);
    init_angular_ipred_fn(Z2_PRED,       ipred_z2,       ssse3);
    init_angular_ipred_fn(Z3_PRED,       ipred_z3,       ssse3);
    init_angular_ipred_fn(DIP_PRED,      ipred_dip,   ssse3);
#endif

    c->pal_pred = BF(dav2d_pal_pred, ssse3);

    if (!(flags & DAV2D_X86_CPU_FLAG_AVX2)) return;

#if BITDEPTH == 8
    init_angular_ipred_fn(DC_PRED,       ipred_dc,       avx2);
#endif
    init_angular_ipred_fn(DC_128_PRED,   ipred_dc_128,   avx2);
#if BITDEPTH == 8
    init_angular_ipred_fn(TOP_DC_PRED,   ipred_dc_top,   avx2);
    init_angular_ipred_fn(LEFT_DC_PRED,  ipred_dc_left,  avx2);
    init_angular_ipred_fn(HOR_PRED,      ipred_h,        avx2);
    init_angular_ipred_fn(VERT_PRED,     ipred_v,        avx2);
#endif
    init_angular_ipred_fn(PAETH_PRED,    ipred_paeth,    avx2);
#if BITDEPTH == 8
    init_angular_ipred_fn(SMOOTH_PRED,   ipred_smooth,   avx2);
    init_angular_ipred_fn(SMOOTH_H_PRED, ipred_smooth_h, avx2);
    init_angular_ipred_fn(SMOOTH_V_PRED, ipred_smooth_v, avx2);
#endif
#if 0
    init_angular_ipred_fn(Z1_PRED,       ipred_z1,       avx2);
    init_angular_ipred_fn(Z2_PRED,       ipred_z2,       avx2);
    init_angular_ipred_fn(Z3_PRED,       ipred_z3,       avx2);
#endif
#if BITDEPTH == 8
    init_angular_ipred_fn(DIP_PRED,      ipred_dip,      avx2);
    init_cfl_fns(420, avx2);
    init_cfl_mh_fns(avx2);
#endif

    c->pal_pred = BF(dav2d_pal_pred, avx2);

    if (!(flags & DAV2D_X86_CPU_FLAG_AVX512ICL)) return;

#if BITDEPTH == 8
#if 0
    init_angular_ipred_fn(DC_PRED,       ipred_dc,       avx512icl);
#endif
    init_angular_ipred_fn(DC_128_PRED,   ipred_dc_128,   avx512icl);
#if 0
    init_angular_ipred_fn(TOP_DC_PRED,   ipred_dc_top,   avx512icl);
    init_angular_ipred_fn(LEFT_DC_PRED,  ipred_dc_left,  avx512icl);
    init_angular_ipred_fn(HOR_PRED,      ipred_h,        avx512icl);
    init_angular_ipred_fn(VERT_PRED,     ipred_v,        avx512icl);
#endif
#endif
    init_angular_ipred_fn(PAETH_PRED,    ipred_paeth,    avx512icl);
#if 0
    init_angular_ipred_fn(SMOOTH_PRED,   ipred_smooth,   avx512icl);
    init_angular_ipred_fn(SMOOTH_H_PRED, ipred_smooth_h, avx512icl);
    init_angular_ipred_fn(SMOOTH_V_PRED, ipred_smooth_v, avx512icl);
    init_angular_ipred_fn(Z1_PRED,       ipred_z1,       avx512icl);
    init_angular_ipred_fn(Z2_PRED,       ipred_z2,       avx512icl);
    init_angular_ipred_fn(Z3_PRED,       ipred_z3,       avx512icl);
    init_angular_ipred_fn(DIP_PRED,      ipred_dip,      avx512icl);
#endif

    c->pal_pred = BF(dav2d_pal_pred, avx512icl);
}
