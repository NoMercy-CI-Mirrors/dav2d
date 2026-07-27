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
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%include "config.asm"
%include "ext/x86/x86inc.asm"

%if ARCH_X86_64

SECTION_RODATA 32

band_mask: dw 0x0000, 0x0080, 0x00c0, 0x00e0, 0x00f0, 0x00f8, 0x00fc, 0x00fe
band_mul:  dw 0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000

SECTION .text

INIT_YMM avx2
cglobal ccso_prep_444_bo_8bpc, 3, 4, 4, dst, src, ss, mbl2
    mov               mbl2d, mbl2m
    lea                  r6, [band_mask]
    vpbroadcastb         m0, [r6+mbl2q*2+ 0]
    vpbroadcastw         m1, [r6+mbl2q*2+16]
    DEFINE_ARGS dst, src, ss, h
    mov                  hd, 8
.loop_y:
    pand                 m2, m0, [srcq+0*mmsize]
    pand                 m3, m0, [srcq+1*mmsize]
    add                srcq, ssq
    REPX    {pmulhuw x, m1}, m2, m3
    mova    [dstq+0*mmsize], m2
    mova    [dstq+1*mmsize], m3
    add                dstq, 64
    dec                  hd
    jg .loop_y
    RET

cglobal ccso_prep_420_bo_8bpc, 3, 4, 4, dst, src, ss, mbl2
    mov               mbl2d, mbl2m
    lea                  r6, [band_mask]
    vpbroadcastw         m0, [r6+mbl2q*2+ 0]
    vpbroadcastw         m1, [r6+mbl2q*2+16]
    DEFINE_ARGS dst, src, ss, h
    mov                  hd, 4
.loop_y:
    pand                 m2, m0, [srcq+0*mmsize]
    pand                 m3, m0, [srcq+1*mmsize]
    packuswb             m2, m3
    vpermq               m2, m2, q3120
    lea                srcq, [srcq+ssq*2]
    pmulhuw              m2, m1
    mova             [dstq], m2
    add                dstq, 32
    dec                  hd
    jg .loop_y
    RET

%endif ; ARCH_X86_64
