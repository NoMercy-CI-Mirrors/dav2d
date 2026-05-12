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

#include <math.h>
#include <stdio.h>

#include "src/stx.h"
#include "src/stx_tables.h"

static void check_stxfm4(const Dav2dStxDSPContext *const c) {
    ALIGN_STK_64(coef, coeff, 2, [4 * 32]);

    declare_func(void, coef *cf, ptrdiff_t stride, int transpose,
                 const int8_t *kernel, int eob HIGHBD_DECL_SUFFIX);

    for (int transpose = 0; transpose < 2; transpose++)
        for (int packed_stride = 0; packed_stride < 2; packed_stride++)
            if (check_func(c->stxfm4, "stx4_tp%d_pck%d_%dbpc",
                           transpose, packed_stride, BITDEPTH))
            {
#if BITDEPTH == 16
                const int bpc = (rnd() & 1) ? 10 : 12;
                const int bitdepth_max = (1 << bpc) - 1;
#else
                const int bpc = 8;
#endif
                const int coef_max = (1 << (bpc + 8)) - 1;
                const int coef_sign = (coef_max + 1) >> 1;

                const int stride = packed_stride ? 4 : 8 << (rnd() % 3);
                const int eob = rnd() & 7;
                const int set = rnd() % 14, type = rnd() % 3;
                const int8_t *const kernel = dav2d_stx_4x4_kernel[set][type][0];

                for (int i = 0; i <= eob; i++)
                    coeff[0][i] = (rnd() & coef_max) - coef_sign;
                memset(&coeff[0][eob + 1], 0, (4 * 32 - (eob + 1)) * sizeof(**coeff));
                memcpy(coeff[1], coeff[0], 4 * 32 * sizeof(**coeff));

                call_ref(coeff[0], stride, transpose, kernel, eob HIGHBD_TAIL_SUFFIX);
                call_new(coeff[1], stride, transpose, kernel, eob HIGHBD_TAIL_SUFFIX);
                checkasm_check_coef(coeff[0], stride * sizeof(**coeff),
                                    coeff[1], stride * sizeof(**coeff),
                                    stride, 4, "coeff");
                bench_new(alternate(coeff[0], coeff[1]), stride, transpose, kernel, eob
                          HIGHBD_TAIL_SUFFIX);
            }
    report("stx4");
}

static void check_stxfm8(const Dav2dStxDSPContext *const c) {
    ALIGN_STK_64(coef, coeff, 2, [8 * 32]);

    declare_func(void, coef *cf, ptrdiff_t stride, int transpose,
                 int map_idx, const int8_t *kernel, int eob HIGHBD_DECL_SUFFIX);

    for (int transpose = 0; transpose < 2; transpose++)
        for (int packed_stride = 0; packed_stride < 2; packed_stride++)
            if (check_func(c->stxfm8, "stx8_tp%d_pck%d_%dbpc",
                           transpose, packed_stride, BITDEPTH))
            {
#if BITDEPTH == 16
                const int bpc = (rnd() & 1) ? 10 : 12;
                const int bitdepth_max = (1 << bpc) - 1;
#else
                const int bpc = 8;
#endif
                const int coef_max = (1 << (bpc + 8)) - 1;
                const int coef_sign = (coef_max + 1) >> 1;
                const int stride = packed_stride ? 8 : 16 << (rnd() & 1);
                const int eob = rnd() & 31;
                const int set = rnd() % 11, type = rnd() % 3;
                const int8_t *const kernel = dav2d_stx_8x8_kernel[set][type][0];
                const int map_idx = rnd() % 3;

                for (int i = 0; i <= eob; i++)
                    coeff[0][i] = (rnd() & coef_max) - coef_sign;
                memset(&coeff[0][eob + 1], 0, (8 * 32 - (eob + 1)) * sizeof(**coeff));
                memcpy(coeff[1], coeff[0], 8 * 32 * sizeof(**coeff));

                call_ref(coeff[0], stride, transpose, map_idx, kernel, eob HIGHBD_TAIL_SUFFIX);
                call_new(coeff[1], stride, transpose, map_idx, kernel, eob HIGHBD_TAIL_SUFFIX);
                checkasm_check_coef(coeff[0], stride * sizeof(**coeff),
                                    coeff[1], stride * sizeof(**coeff),
                                    stride, 8, "coeff");
                bench_new(alternate(coeff[0], coeff[1]), stride, transpose, map_idx,
                          kernel, eob HIGHBD_TAIL_SUFFIX);
            }
    report("stx8");
}

void bitfn(checkasm_check_stx)(void) {
    Dav2dStxDSPContext c;
    bitfn(dav2d_stx_dsp_init)(&c);

    check_stxfm4(&c);
    check_stxfm8(&c);
}
