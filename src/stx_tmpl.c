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

#include <stdlib.h>

#include "common/intops.h"

#include "src/levels.h"
#include "src/stx.h"
#include "src/stx_tables.h"
#include "src/tables.h"

static NOINLINE void stxfm_c(coef *const cf_out,
                             const coef *const cf,
                             const int8_t *kernel,
                             const int sz,
                             const int eob HIGHBD_DECL_SUFFIX)
{
    assert(sz == 16 || sz == 48);
    assert(eob >= 0 && eob < (sz == 16 ? 8 : 32));
    const int min = -128 * (1 + BITDEPTH_MAX);
    const int max = 128 * (1 + BITDEPTH_MAX) - 1;
    const int h = eob + 1;
    for (int x = 0; x < sz; x++) {
        int sum = 0;
        for (int y = 0; y < h; y++)
            sum += cf[y] * kernel[y * sz + x];
        sum = apply_sign((abs(sum) + 64) >> 7, sum);
        cf_out[x] = iclip(sum, min, max);
    }
}

static void stxfm4_c(coef *const cf, const ptrdiff_t stride,
                     const int transpose, const int8_t *const kernel,
                     const int eob HIGHBD_DECL_SUFFIX)
{
    assert(stride >= 4 && stride <= 32 && !(stride & (stride - 1)));
    coef sums[16];
    stxfm_c(sums, cf, kernel, 16, eob HIGHBD_TAIL_SUFFIX);
    memset(&cf[4], 0, 4 * sizeof(coef));
    if (transpose) {
        for (int y = 0; y < 4; y++)
            for (int x = 0; x < 4; x++)
                cf[y * stride + x] = sums[y * 4 + x];
    } else {
        for (int y = 0; y < 4; y++)
            for (int x = 0; x < 4; x++)
                cf[x * stride + y] = sums[y * 4 + x];
    }
}

static void stxfm8_c(coef *const cf, const ptrdiff_t stride,
                     const int transpose, const int map_idx,
                     const int8_t *const kernel, const int eob
                     HIGHBD_DECL_SUFFIX)
{
    assert(stride >= 8 && stride <= 32 && !(stride & (stride - 1)));
    coef sums[48];
    stxfm_c(sums, cf, kernel, 48, eob HIGHBD_TAIL_SUFFIX);
    // for the write-out, an avx512 (or similar) implementation supporting
    // wide shuffles could write-out an 8x8 block using a inverse scan table
    // generated from dav2d_coeff8x8_mapping[]. We don't do that here since
    // it would increase the loop count below from 48 -> 64.
    memset(cf, 0, 32 * sizeof(coef));
    const uint8_t *mapping = dav2d_coeff8x8_mapping[map_idx];
    if (!transpose) {
        for (int n = 0; n < 48; n++) {
            const int rc = mapping[n], x = rc & 7, y = rc >> 3;
            cf[x * stride + y] = sums[n];
        }
    } else if (stride > 8) {
        for (int n = 0; n < 48; n++) {
            const int rc = mapping[n], x = rc & 7, y = rc >> 3;
            cf[y * stride + x] = sums[n];
        }
    } else {
        for (int n = 0; n < 48; n++) {
            const int rc = mapping[n];
            assert((unsigned) rc < 64U);
            cf[rc] = sums[n];
        }
    }
}

#if HAVE_ASM
#if ARCH_X86
#include "src/x86/stx.h"
#endif
#endif

COLD void bitfn(dav2d_stx_dsp_init)(Dav2dStxDSPContext *const c) {
    c->stxfm4 = stxfm4_c;
    c->stxfm8 = stxfm8_c;

#if HAVE_ASM
#if ARCH_X86
    stx_dsp_init_x86(c);
#endif
#endif
}
