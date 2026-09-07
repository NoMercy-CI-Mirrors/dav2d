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

#ifndef DAV2D_SRC_LOOPRESTORATION_H
#define DAV2D_SRC_LOOPRESTORATION_H

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>

#include "common/attributes.h"
#include "common/bitdepth.h"
#include "common/intops.h"

// Some of the luma wiener filters select different filters based pixel data
// and the pixels within skipped/unskipped blocks. This process can be sped up
// by approximating the skip portion of the calculation then correcting error
// with a lut.
// There are 4 different sub-indices that are calculated and combined to create
// the full index. The first is purely based on skip counts, so we look that up
// directly.
typedef struct WienerQValApproxData {
    // skip is calculated on a 6x6 region, the largest value is 36.
    // There are 37 entries in the lookup table + padding.
    int8_t error_lut[3 /* vert, diag, anti-diag */ * 64];
    int32_t offsets[3 /* vert, diag, anti-diag */];
    int16_t slopes[3 /* vert, diag, anti-diag */];

    // First index doesn't depend on pixel data, so we can calculate it ahead
    // of time. Additionally, it only ever uses 2 values and only decreases.
    int16_t idx0_changeover;
} WienerQValApproxData;

#define GDF_PARAMS(...) struct {   \
    uint16_t scale;                \
    int16_t bias[3];               \
    uint16_t gradient_alpha[4];    \
    int16_t gradient_weight[4];    \
    uint16_t alpha[9][2];          \
    int16_t weight1[7][2];         \
    int16_t weight2[2][4];         \
    int16_t weight3[2][2];         \
    int16_t weight4[2][2];         \
    int8_t error_lut[__VA_ARGS__]; \
}

PACKED(typedef GDF_PARAMS()) ALIGN(Dav2dGdfParams, 8);
CHECK_SIZE(Dav2dGdfParams, 120);

PACKED(typedef union {
    ALIGN(Dav2dGdfParams p, 8);
    GDF_PARAMS(4096);
}) ALIGN(Dav2dGdfIntraParams, 8);
CHECK_SIZE(Dav2dGdfIntraParams, 4216);

PACKED(typedef union {
    ALIGN(Dav2dGdfParams p, 8);
    GDF_PARAMS(1000);
}) ALIGN(Dav2dGdfInterParams, 8);
CHECK_SIZE(Dav2dGdfInterParams, 1120);
#undef GDF_PARAMS

EXTERN const Dav2dGdfIntraParams dav2d_gdf_intra_params[6];
EXTERN const Dav2dGdfInterParams dav2d_gdf_inter_params[5][6];

static inline void
setup_wiener_qval_approx_data(WienerQValApproxData *const data,
                              ptrdiff_t *const class_lut_offset,
                              const int qstep)
{
    const int16_t mode_weights[ 4 ][ 3 ] = {
        { -527, 15325, 321 },
        { 26436, -17705, 17905 },
        { 366, -147, -194 },
        { 202, -267, -179 }
    };
    static const int16_t mode_offsets[ 4 ] = { -547, -21565, -573, -680 };

    int init_idx0 = 0;
    int idx0_low = 0;
    int idx0_changeover = -1;
    for (int s = 0; s <= 36; s++) {
        int tskip = s * 7;
        int prod = (tskip * qstep + 128) >> 8;
        int qval = mode_weights[0][0] * (tskip << 5) +
                   mode_weights[0][1] * qstep +
                   mode_weights[0][2] * prod;
        int abs_qval = abs(qval);
        qval = apply_sign((abs_qval + 4096) >> 13, qval);
        qval = 255 * (mode_offsets[0] + qval);
        qval = (imax(0, qval) + 8192) >> 14;
        qval = imin(qval, 255) >> 5;
        if (s == 0) {
            idx0_low = init_idx0 = qval;
        } else if (qval != init_idx0) {
            assert(qval < init_idx0);
            idx0_low = qval;
            idx0_changeover = s;
            break;
        }
    }
    data->idx0_changeover = idx0_changeover;
    *class_lut_offset = idx0_low << 9;

    int32_t tmp_table[37];
    for (int i = 0; i < 3; i++) {
        int slope = 7 * 32 * mode_weights[i+1][0] +
                    (int) ((7 * mode_weights[i+1][2] *
                            (long long) qstep) >> 8);
        slope = (slope + 4096) >> 13;
        for (int s = 0; s <= 36; s++) {
            int tskip = s * 7;
            int prod = (tskip * qstep + 128) >> 8;
            int qval = mode_weights[i+1][0] * (tskip << 5) +
                       mode_weights[i+1][1] * qstep +
                       mode_weights[i+1][2] * prod;
            int abs_qval = abs(qval);
            qval = apply_sign((abs_qval + 4096) >> 13, qval);
            qval = mode_offsets[i+1] + qval;
            tmp_table[s] = qval - s * slope;
        }

        data->slopes[i] = slope;
        data->offsets[i] = tmp_table[0];
        for (int s = 0; s <= 36; s++) {
            data->error_lut[i*64 + s] = tmp_table[s] - tmp_table[0];
        }
    }
}

enum LrEdgeFlags {
    LR_HAVE_LEFT = 1 << 0,
    LR_HAVE_RIGHT = 1 << 1,
    LR_HAVE_TOP = 1 << 2,
    LR_HAVE_BOTTOM = 1 << 3,
    // top (or bottom) edges are at tile row boundaries and consist of
    // post-cdef/ccso instead of pre-cdef/ccso data. This also means they
    // contain 4 lines of pixel data instead of 2.
    LR_HAVE_TOP_INTEGRATED = 1 << 4,
    LR_HAVE_BOTTOM_INTEGRATED = 1 << 5,
};

#ifdef BITDEPTH
typedef const pixel (*const_left_pixel_row)[8];
typedef const pixel (*const_left_pixel_row_uv)[2];
#else
typedef const void *const_left_pixel_row;
typedef const void *const_left_pixel_row_uv;
#endif

typedef union WienerParams {
    struct {
        const int8_t *filter;
    } single;
    struct {
        union {
            const int8_t (*user)[16];
            const int8_t (*pretrained)[13];
        } filters;
        const uint8_t *class_lut;
        const uint16_t *noskip_mask;
        const WienerQValApproxData *qval_approx;
    } multi;
} WienerParams;

// Although the spec applies restoration filters over 4x4 blocks,
// they can be applied to a bigger surface.
//    * w is constrained by the smallest gdf block size (w <= 64)
//    * h is constrained by the stripe height (h <= 64)
// The filter functions are allowed to do aligned writes past the right
// edge of the buffer, aligned up to the minimum loop restoration unit size
// (which is 32 pixels for subsampled chroma and 64 pixels for luma).
#define decl_wiener_filter_fn(name) \
void (name)(pixel *dst, ptrdiff_t dst_stride, \
            const_left_pixel_row left, \
            const pixel *top, const pixel *bottom, \
            const WienerParams *params, const uint16_t (*ll_mask)[4], \
            int w, int h, enum LrEdgeFlags edges \
            HIGHBD_DECL_SUFFIX)
typedef decl_wiener_filter_fn(*wienerfilter_fn);

// sum the luma component of the chroma filter
// dst has a constant stride of 64 coefs (this applies to the chroma part too)
#define decl_wiener_filter_uv_luma_fn(name) \
void (name)(coef *dst, const pixel *luma, const ptrdiff_t stride, \
            const_left_pixel_row left, const pixel *top, const pixel *bottom, \
            const int8_t *filter, int w, int h, int ds_flt, \
            enum LrEdgeFlags edges)
typedef decl_wiener_filter_uv_luma_fn(*wienerfilter_uv_luma_fn);

// compute and add the chroma component of the chroma filter to the luma filter
#define decl_wiener_filter_uv_chroma_fn(name) \
void (name)(pixel *p, const ptrdiff_t stride, const_left_pixel_row_uv left, \
            const pixel *top, const pixel *bottom, const coef *luma, \
            const int8_t *filter, const uint16_t (*ll_mask)[4], \
            int w, int h, enum LrEdgeFlags edges HIGHBD_DECL_SUFFIX)
typedef decl_wiener_filter_uv_chroma_fn(*wienerfilter_uv_chroma_fn);

#define decl_gdf_prep_fn(name) \
void (name)(int8_t *dst, const pixel *p, ptrdiff_t stride, \
            const_left_pixel_row left, const pixel *top, \
            const pixel *bottom, const Dav2dGdfParams *params, \
            int w, int h, enum LrEdgeFlags edges HIGHBD_DECL_SUFFIX)
typedef decl_gdf_prep_fn(*gdf_prep_fn);

#define decl_gdf_add_fn(name) \
void (name)(pixel *p, ptrdiff_t p_stride, const int8_t *err, \
            const uint16_t (*ll_mask)[4], int w, int h, \
            int scale HIGHBD_DECL_SUFFIX)
typedef decl_gdf_add_fn(*gdf_add_fn);

typedef struct Dav2dLoopRestorationDSPContext {
    wienerfilter_fn ns_wiener_single;
    wienerfilter_fn ns_wiener_multi;
    wienerfilter_fn pc_wiener;
    wienerfilter_uv_luma_fn wiener_uv_luma[3 /* 444/luma, 422, 420 */];
    wienerfilter_uv_chroma_fn wiener_uv_chroma;
    gdf_prep_fn gdf_prep;
    gdf_add_fn gdf_add;
} Dav2dLoopRestorationDSPContext;

bitfn_decls(void dav2d_loop_restoration_dsp_init, Dav2dLoopRestorationDSPContext *c);

#endif /* DAV2D_SRC_LOOPRESTORATION_H */
