; Copyright © 2026, VideoLAN and dav2d authors
; Copyright © 2026, Two Orioles, LLC
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHr4wT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%include "config.asm"
%include "ext/x86/x86inc.asm"

SECTION_RODATA 32

gdf_llm_mul: dw 128, 32768, 64, 16384, 32, 8192, 16, 4096
             dw   8,  2048,  4,  1024,  2,  512,  1,  256

SECTION .text

%macro GDF_ADD 2 ; err_off, p
    mova              m0, [errq+%1]
    mova              m3, %2
    pabsb             m2, m0
    punpcklbw         m1, m2, m2 ; abs(err) << 8. lower bits will be shifted out
    punpckhbw         m2, m2     ; so a dedicated zero register isn't required
    pmulhrsw          m1, m5
    pmulhrsw          m2, m5
    packuswb          m1, m2     ; (abs(diff) + rnd) >> shift
    psubusb           m2, m3, m1
    paddusb           m1, m3
    vpblendvb         m1, m2, m0 ; apply_sign()
    vblendvps         m1, m3, m4 ; ll_mask
    mova              %2, m1
%endmacro

INIT_YMM avx2
cglobal gdf_add_8bpc, 4, 7, 7, p, ps, err, llm, w, h, scale
    vpbroadcastw      m5, scalem
    mova              m6, [gdf_llm_mul]
    mov               hd, hm
    movifnidn         wd, wm
    lea             llmq, [llmq+hq*2]
    neg               hq
    psllw             m5, 3
    lea               r6, [psq*3]
.loop:
    vpbroadcastw      m4, [llmq+hq*2]
    pmullw            m4, m6
    GDF_ADD         32*0, [pq+psq*0+32*0]
    GDF_ADD         32*2, [pq+psq*1+32*0]
    add             errq, 32*8
    GDF_ADD        -32*4, [pq+psq*2+32*0]
    GDF_ADD        -32*2, [pq+r6   +32*0]
    cmp               wd, 32
    jle .loop_end
    pslld             m4, 16
    GDF_ADD        -32*7, [pq+psq*0+32*1]
    GDF_ADD        -32*5, [pq+psq*1+32*1]
    GDF_ADD        -32*3, [pq+psq*2+32*1]
    GDF_ADD        -32*1, [pq+r6   +32*1]
.loop_end:
    lea               pq, [pq+psq*4]
    add               hq, 4
    jl .loop
    RET
