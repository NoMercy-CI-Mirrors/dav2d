/*
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
 */

#include "util.S"

.macro cdef_dir_table w, stride
const cdef_directions\w, export=1
        .byte           -1 * \stride + 1, -2 * \stride + 2
        .byte            0 * \stride + 1, -1 * \stride + 2
        .byte            0 * \stride + 1,  0 * \stride + 2
        .byte            0 * \stride + 1,  1 * \stride + 2
        .byte            1 * \stride + 1,  2 * \stride + 2
        .byte            1 * \stride + 0,  2 * \stride + 1
        .byte            1 * \stride + 0,  2 * \stride + 0
        .byte            1 * \stride + 0,  2 * \stride - 1
// Repeated, to avoid & 7
        .byte           -1 * \stride + 1, -2 * \stride + 2
        .byte            0 * \stride + 1, -1 * \stride + 2
        .byte            0 * \stride + 1,  0 * \stride + 2
        .byte            0 * \stride + 1,  1 * \stride + 2
        .byte            1 * \stride + 1,  2 * \stride + 2
        .byte            1 * \stride + 0,  2 * \stride + 1
endconst
.endm

cdef_dir_table 8, 16
cdef_dir_table 4, 8

const cdef_pri_taps, export=1
        .byte           4, 2, 3, 3
endconst

const cdef_div_table, export=1, align=4
        .short          840, 420, 280, 210, 168, 140, 120, 105
endconst

const cdef_alt_fact, export=1
        .short          420, 210, 140, 105, 105, 105, 105, 105, 140, 210, 420, 0
endconst

const deblock_comparisons, export=1, align=4
        .byte           0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
        .byte           0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
        .byte           0, 0, 0, 0, 0, 0, 0, 0
        .byte           1, 1, 1, 1, 1, 1, 1, 1
endconst

// Replace the shift right by 7 with a shift right by 6 when e1 = 1, allowing
// to skip the multiplication by (e1 + 1).
const opfl_shift_large, export=1, align=4
        .short          -6, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -6
endconst

const opfl_shift_small, export=1, align=4
        .short          -6, -7, -7, -7, -7, -7, -7, -6
endconst
