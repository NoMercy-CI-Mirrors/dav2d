/*
 * Copyright © 2018, VideoLAN and dav2d authors
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
#include "src/looprestoration.h"

#define decl_wiener_filter_fns(ext) \
decl_wiener_filter_fn(BF(dav2d_wiener_multi, ext)); \
decl_wiener_filter_fn(BF(dav2d_wiener_pretrained, ext));

decl_gdf_prep_fn(BF(dav2d_gdf_prep, avx2));
decl_gdf_add_fn(BF(dav2d_gdf_add, avx2));

decl_wiener_filter_fns(avx2);

#if BITDEPTH == 8
// Placeholder implementation for single wiener filter
union ZeroData {
    uint8_t class_lut[1024];
    WienerQValApproxData qval_approx;
};
static void BF(wiener_single, avx2)(pixel *p, const ptrdiff_t stride,
                                    const pixel (*left)[8],
                                    const pixel *lpf, const pixel *lpf_bottom,
                                    const WienerParams *in_params,
                                    const uint16_t (*ll_mask)[4],
                                    const int w, const int h,
                                    const enum LrEdgeFlags edges
                                    HIGHBD_DECL_SUFFIX)
{
    const union ZeroData zero = { 0 };
    uint16_t noskip_mask[16];
    WienerParams params;
    ALIGN_STK_64(int8_t, filters, 16, [16]);
    memcpy(filters[0], in_params->single.filter, sizeof(filters[0]));
    params.multi.noskip_mask = noskip_mask;
    params.multi.qval_approx = &zero.qval_approx;
    params.multi.filters.user = filters;
    params.multi.class_lut = zero.class_lut;
    BF(dav2d_wiener_multi, avx2)(p, stride, left, lpf, lpf_bottom, &params,
                                 ll_mask, w, h, edges HIGHBD_TAIL_SUFFIX);
}
#endif

static ALWAYS_INLINE void loop_restoration_dsp_init_x86(Dav2dLoopRestorationDSPContext *const c) {
    const unsigned flags = dav2d_get_cpu_flags();

    if (!(flags & DAV2D_X86_CPU_FLAG_AVX2)) return;

#if BITDEPTH == 8
    c->gdf_prep = BF(dav2d_gdf_prep, avx2);
    c->gdf_add = BF(dav2d_gdf_add, avx2);
    c->pc_wiener = BF(dav2d_wiener_pretrained, avx2);
    c->ns_wiener_multi = BF(dav2d_wiener_multi, avx2);
    c->ns_wiener_single = BF(wiener_single, avx2);
#endif

}
