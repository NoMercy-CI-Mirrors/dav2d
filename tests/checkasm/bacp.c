/*
 * Copyright © 2026, VideoLAN and dav2d authors
 * Copyright © 2026, Two Orioles, LLC
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
#include "src/bacp.h"

#include <stdio.h>
#include <string.h>

static void check_bacp_mask(const Dav2dBACPDSPContext *const c) {
    ALIGN_STK_64(uint8_t, c_dst, 64 * 64,);
    ALIGN_STK_64(uint8_t, a_dst, 64 * 64,);

    declare_func(void, uint8_t *dst, ptrdiff_t stride,
                 int bw, int bh, int x0, int y0, int x1, int y1,
                 unsigned fw, unsigned fh);

    for (int bw = 4; bw <= 64; bw <<= 1) {
        if (check_func(c->mask, "bacp_mask_w%d", bw)) {
            for (int bh = 4; bh <= 64; bh <<= 1) {
                const ptrdiff_t stride = rnd() & 1 ? 64 : bw;
                const int fw = 1 + (rnd() & 0xffff);
                const int fh = 1 + (rnd() & 0xffff);

                // bias towards MVs that partially-overhang the left or
                // right image edges
#define pos(wh) rnd() & 1 ? -(rnd() & (b##wh - 1)) : /* left overhang */ \
                rnd() & 1 ? f##wh - (rnd() & (b##wh - 1)) : /* right overhang */ \
                (rnd() % (fw + 0x10000)) - 0x8000 /* random */
                const int x0 = pos(w);
                const int x1 = pos(w);
                const int y0 = pos(h);
                const int y1 = pos(h);
#undef pos

                memset(c_dst, 0xff, stride * bh);
                memset(a_dst, 0xff, stride * bh);

                call_ref(c_dst, stride, bw, bh, x0, y0, x1, y1, fw, fh);
                call_new(a_dst, stride, bw, bh, x0, y0, x1, y1, fw, fh);
                checkasm_check(uint8_t, c_dst, stride, a_dst, stride,
                               bw, bh, "dst");

                if (bw == bh)
                    bench_new(a_dst, bw, bw, bh, x0, y0, x1, y1, fw, fh);
            }
        }
    }

    report("bacp_mask");
}

void checkasm_check_bacp(void) {
    Dav2dBACPDSPContext c;
    dav2d_bacp_dsp_init(&c);
    check_bacp_mask(&c);
}
