/******************************************************************************
 * Copyright © 2026, Arm Limited
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
 *****************************************************************************/

#include "src/arm/asm.S"
#include "util.S"

// void cctx_16bpc_neon(coef *const u, coef *const v, const int16_t angle[3],
//                      const size_t sz, const int bitdepth_max)
function cctx_16bpc_neon, export=1
        mov             w7,  #127
        ldr             s31, [x2]
        orr             w7,  w7,  w4,  lsl #7
        sxtl            v31.4s,  v31.4h
        dup             v30.4s,  w7
        mvn             v29.16b, v30.16b

1:
        ldp             q0,  q1,  [x0]
        ldp             q2,  q3,  [x0, #32]
        mul             v16.4s,  v0.4s,   v31.s[1]
        mul             v17.4s,  v1.4s,   v31.s[1]
        ldp             q4,  q5,  [x1]
        ldp             q6,  q7,  [x1, #32]
        mul             v18.4s,  v2.4s,   v31.s[1]
        mul             v19.4s,  v3.4s,   v31.s[1]
        add             x0,  x0,  #64
        add             x1,  x1,  #64

        mls             v16.4s,  v4.4s,   v31.s[0]
        mls             v17.4s,  v5.4s,   v31.s[0]
        mls             v18.4s,  v6.4s,   v31.s[0]
        mls             v19.4s,  v7.4s,   v31.s[0]

        mul             v20.4s,  v0.4s,   v31.s[0]
        mul             v21.4s,  v1.4s,   v31.s[0]
        ssra            v16.4s,  v16.4s,  #31
        ssra            v17.4s,  v17.4s,  #31
        mul             v22.4s,  v2.4s,   v31.s[0]
        mul             v23.4s,  v3.4s,   v31.s[0]
        ssra            v18.4s,  v18.4s,  #31
        ssra            v19.4s,  v19.4s,  #31

        mla             v20.4s,  v4.4s,   v31.s[1]
        mla             v21.4s,  v5.4s,   v31.s[1]
        srshr           v16.4s,  v16.4s,  #8
        srshr           v17.4s,  v17.4s,  #8
        mla             v22.4s,  v6.4s,   v31.s[1]
        mla             v23.4s,  v7.4s,   v31.s[1]
        srshr           v18.4s,  v18.4s,  #8
        srshr           v19.4s,  v19.4s,  #8

        ssra            v20.4s,  v20.4s,  #31
        ssra            v21.4s,  v21.4s,  #31
        ssra            v22.4s,  v22.4s,  #31
        ssra            v23.4s,  v23.4s,  #31

        srshr           v20.4s,  v20.4s,  #8
        srshr           v21.4s,  v21.4s,  #8
        srshr           v22.4s,  v22.4s,  #8
        srshr           v23.4s,  v23.4s,  #8

        smin            v16.4s,  v16.4s,  v30.4s
        smin            v17.4s,  v17.4s,  v30.4s
        smin            v18.4s,  v18.4s,  v30.4s
        smin            v19.4s,  v19.4s,  v30.4s

        smin            v20.4s,  v20.4s,  v30.4s
        smin            v21.4s,  v21.4s,  v30.4s
        smin            v22.4s,  v22.4s,  v30.4s
        smin            v23.4s,  v23.4s,  v30.4s

        smax            v16.4s,  v16.4s,  v29.4s
        smax            v17.4s,  v17.4s,  v29.4s
        smax            v18.4s,  v18.4s,  v29.4s
        smax            v19.4s,  v19.4s,  v29.4s

        subs            w3,  w3,  #16
        smax            v20.4s,  v20.4s,  v29.4s
        smax            v21.4s,  v21.4s,  v29.4s
        smax            v22.4s,  v22.4s,  v29.4s
        stp             q16, q17, [x0, #-64]
        smax            v23.4s,  v23.4s,  v29.4s
        stp             q18, q19, [x0, #-32]
        stp             q20, q21, [x1, #-64]
        stp             q22, q23, [x1, #-32]
        b.gt            1b

        ret
endfunc
