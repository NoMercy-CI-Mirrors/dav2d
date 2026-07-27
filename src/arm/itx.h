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

#include "config.h"

#include "src/cpu.h"
#include "src/itx.h"
#include "src/itx_1d.h"
#include "src/scan.h"
#include "src/tables.h"

#if BITDEPTH == 8

#define decl_itx_1d_row_fn(name)                                               \
  void(name)(coef *dst, ptrdiff_t dst_stride, const coef *c, ptrdiff_t stride, \
             uint64_t shift, uint64_t do_scale,                                \
             uint64_t howmany HIGHBD_DECL_SUFFIX)
typedef decl_itx_1d_row_fn(*itx_1d_fn_row);

#define decl_itx_1d_col_fn(name)                                               \
  void(name)(pixel *dst, ptrdiff_t dst_stride, const coef *c,                  \
             ptrdiff_t stride, uint64_t w, uint64_t h, uint64_t shift,         \
             uint64_t howmany HIGHBD_DECL_SUFFIX)
typedef decl_itx_1d_col_fn(*itx_1d_fn_col);

#define decl_itx_2d_fn(name)                                                   \
  void(name)(pixel *dst, ptrdiff_t dst_stride, coef *coeff,                    \
             enum TxfmType txtp HIGHBD_DECL_SUFFIX)
typedef decl_itx_2d_fn(*itx_2d_fn);

#define decl_residual_add_fn(name)                                             \
  void(name)(pixel* dst, ptrdiff_t dst_stride, const coef *c, uint64_t w,      \
             uint64_t h, uint64_t shift,                                       \
             enum TxfmType txtp HIGHBD_DECL_SUFFIX)

#define decl_itx_1d_pair(name) \
decl_itx_1d_row_fn(BF(dav2d_inv_##name##_1d_row, neon)); \
decl_itx_1d_col_fn(BF(dav2d_inv_##name##_1d_col, neon))

#define decl_residual_add_idtx_fn(sz) \
decl_residual_add_fn(BF(dav2d_residual_add_idtx##sz, neon))

#define decl_itx_2d(size, hor, ver) \
decl_itx_2d_fn(BF(dav2d_inv_txfm_add_##size##_##hor##_##ver, neon))

decl_itx_1d_pair(dct4);
decl_itx_1d_pair(dct8);
decl_itx_1d_pair(dct16);
decl_itx_1d_pair(dct32);
decl_itx_1d_pair(adst4);
decl_itx_1d_pair(flipadst4);
decl_itx_1d_pair(adst8);
decl_itx_1d_pair(flipadst8);
decl_itx_1d_pair(ddt8);
decl_itx_1d_pair(flipddt8);
decl_itx_1d_pair(adst16);
decl_itx_1d_pair(flipadst16);
decl_itx_1d_pair(ddt16);
decl_itx_1d_pair(flipddt16);
decl_itx_1d_pair(identity4);
decl_itx_1d_pair(identity8);
decl_itx_1d_pair(identity16);
decl_itx_1d_pair(identity32);

decl_residual_add_idtx_fn(4);
decl_residual_add_idtx_fn(8);
decl_residual_add_idtx_fn(16);
decl_residual_add_idtx_fn(32);

decl_itx_2d(4x4, dct,      dct);
decl_itx_2d(4x4, dct,      identity);
decl_itx_2d(4x4, dct,      adst);
decl_itx_2d(4x4, dct,      flipadst);
decl_itx_2d(4x4, identity, dct);
decl_itx_2d(4x4, identity, identity);
decl_itx_2d(4x4, identity, adst);
decl_itx_2d(4x4, identity, flipadst);
decl_itx_2d(4x4, adst,     dct);
decl_itx_2d(4x4, adst,     identity);
decl_itx_2d(4x4, adst,     adst);
decl_itx_2d(4x4, adst,     flipadst);
decl_itx_2d(4x4, flipadst, dct);
decl_itx_2d(4x4, flipadst, identity);
decl_itx_2d(4x4, flipadst, adst);
decl_itx_2d(4x4, flipadst, flipadst);

// Special-case IDTX + DPCM to fuse the final identity with residual_add.
decl_itx_2d_fn(BF(dav2d_inv_txfm_add_4x4_identity_identity_dpcm, neon));
decl_itx_2d_fn(BF(dav2d_inv_txfm_add_4x4_wht_wht, neon));

void BF(dav2d_itx_dc_only, neon)(pixel *dst, ptrdiff_t stride, coef *coeff,
                                 uint64_t shift0, uint64_t shift1, uint64_t w,
                                 uint64_t h, uint64_t is_rect2
                                 HIGHBD_DECL_SUFFIX);

static const itx_1d_fn_col itx_1d_x4_fns_col[N_TX_SIZES][N_TX_1D_TYPES - 1] = {
    [TX_4X4] = {
        [DCT]      = BF(dav2d_inv_dct4_1d_col, neon),
        [ADST]     = BF(dav2d_inv_adst4_1d_col, neon),
        [FLIPADST] = BF(dav2d_inv_flipadst4_1d_col, neon),
        [IDENTITY] = BF(dav2d_inv_identity4_1d_col, neon),
    }, [TX_8X8] = {
        [DCT]      = BF(dav2d_inv_dct8_1d_col, neon),
        [ADST]     = BF(dav2d_inv_adst8_1d_col, neon),
        [FLIPADST] = BF(dav2d_inv_flipadst8_1d_col, neon),
        [IDENTITY] = BF(dav2d_inv_identity8_1d_col, neon),
        [DDT]      = BF(dav2d_inv_ddt8_1d_col, neon),
        [FLIPDDT]  = BF(dav2d_inv_flipddt8_1d_col, neon),
    }, [TX_16X16] = {
        [DCT]      = BF(dav2d_inv_dct16_1d_col, neon),
        [ADST]     = BF(dav2d_inv_adst16_1d_col, neon),
        [FLIPADST] = BF(dav2d_inv_flipadst16_1d_col, neon),
        [IDENTITY] = BF(dav2d_inv_identity16_1d_col, neon),
        [DDT]      = BF(dav2d_inv_ddt16_1d_col, neon),
        [FLIPDDT]  = BF(dav2d_inv_flipddt16_1d_col, neon),
    }, [TX_32X32] = {
        [DCT]      = BF(dav2d_inv_dct32_1d_col, neon),
        [IDENTITY] = BF(dav2d_inv_identity32_1d_col, neon),
    }, [TX_64X64] = {
        [DCT]      = BF(dav2d_inv_dct32_1d_col, neon),
    },
};

static const itx_1d_fn_row itx_1d_x4_fns_row[N_TX_SIZES][N_TX_1D_TYPES - 1] = {
    [TX_4X4] = {
        [DCT]      = BF(dav2d_inv_dct4_1d_row, neon),
        [ADST]     = BF(dav2d_inv_adst4_1d_row, neon),
        [FLIPADST] = BF(dav2d_inv_flipadst4_1d_row, neon),
        [IDENTITY] = BF(dav2d_inv_identity4_1d_row, neon),
    }, [TX_8X8] = {
        [DCT]      = BF(dav2d_inv_dct8_1d_row, neon),
        [ADST]     = BF(dav2d_inv_adst8_1d_row, neon),
        [FLIPADST] = BF(dav2d_inv_flipadst8_1d_row, neon),
        [IDENTITY] = BF(dav2d_inv_identity8_1d_row, neon),
        [DDT]      = BF(dav2d_inv_ddt8_1d_row, neon),
        [FLIPDDT]  = BF(dav2d_inv_flipddt8_1d_row, neon),
    }, [TX_16X16] = {
        [DCT]      = BF(dav2d_inv_dct16_1d_row, neon),
        [ADST]     = BF(dav2d_inv_adst16_1d_row, neon),
        [FLIPADST] = BF(dav2d_inv_flipadst16_1d_row, neon),
        [IDENTITY] = BF(dav2d_inv_identity16_1d_row, neon),
        [DDT]      = BF(dav2d_inv_ddt16_1d_row, neon),
        [FLIPDDT]  = BF(dav2d_inv_flipddt16_1d_row, neon),
    }, [TX_32X32] = {
        [DCT]      = BF(dav2d_inv_dct32_1d_row, neon),
        [IDENTITY] = BF(dav2d_inv_identity32_1d_row, neon),
    }, [TX_64X64] = {
        [DCT]      = BF(dav2d_inv_dct32_1d_row, neon),
    },
};

static const itx_2d_fn itx_4x4_fns[N_TX_1D_TYPES - 1][N_TX_1D_TYPES - 1] = {
    [DCT] = {
        [DCT]      = BF(dav2d_inv_txfm_add_4x4_dct_dct, neon),
        [IDENTITY] = BF(dav2d_inv_txfm_add_4x4_dct_identity, neon),
        [ADST]     = BF(dav2d_inv_txfm_add_4x4_dct_adst, neon),
        [FLIPADST] = BF(dav2d_inv_txfm_add_4x4_dct_flipadst, neon),
    }, [IDENTITY] = {
        [DCT]      = BF(dav2d_inv_txfm_add_4x4_identity_dct, neon),
        [IDENTITY] = BF(dav2d_inv_txfm_add_4x4_identity_identity, neon),
        [ADST]     = BF(dav2d_inv_txfm_add_4x4_identity_adst, neon),
        [FLIPADST] = BF(dav2d_inv_txfm_add_4x4_identity_flipadst, neon),
    }, [ADST] = {
        [DCT]      = BF(dav2d_inv_txfm_add_4x4_adst_dct, neon),
        [IDENTITY] = BF(dav2d_inv_txfm_add_4x4_adst_identity, neon),
        [ADST]     = BF(dav2d_inv_txfm_add_4x4_adst_adst, neon),
        [FLIPADST] = BF(dav2d_inv_txfm_add_4x4_adst_flipadst, neon),
    }, [FLIPADST] = {
        [DCT]      = BF(dav2d_inv_txfm_add_4x4_flipadst_dct, neon),
        [IDENTITY] = BF(dav2d_inv_txfm_add_4x4_flipadst_identity, neon),
        [ADST]     = BF(dav2d_inv_txfm_add_4x4_flipadst_adst, neon),
        [FLIPADST] = BF(dav2d_inv_txfm_add_4x4_flipadst_flipadst, neon),
    },
};

static ALWAYS_INLINE int itx_first_pass_howmany(const int tx_class,
                                                const int sh, const int lw,
                                                const int eob, const int tx)
{
    if (tx_class == TX_CLASS_2D) {
        const uint16_t *last_eob = dav2d_last_eob_per_col.table +
                                   dav2d_last_eob_per_col.offset[tx];
        int howmany = 4;
        while (howmany < sh && eob > *last_eob++) {
            howmany += 4;
        }
        return howmany;
    }

    int last_nz_col;
    if (tx_class == TX_CLASS_H) {
        last_nz_col = imin(sh - 1, eob);
    } else if (tx_class == TX_CLASS_V) {
        last_nz_col = imin(sh - 1, eob >> (lw + 2));
    } else {
        last_nz_col = sh - 1;
    }
    return imin(sh, (last_nz_col + 4) & ~3);
}

#define ITX_WRAP(w, h, lw, lh, shift0, shift1, rect2, sw, sh, tx) \
static void BF(dav2d_inv_txfm_add_##w##x##h, neon)(pixel *dst, \
                                                   const ptrdiff_t stride, \
                                                   coef *const coeff, \
                                                   const enum TxfmType txtp, \
                                                   const int eob HIGHBD_DECL_SUFFIX) \
{ \
    assert(eob >= 0 && eob < 32 * 32); \
    if (eob == 0 && txtp == DCT_DCT) { \
        BF(dav2d_itx_dc_only, neon)(dst, stride, coeff, shift0, shift1, \
                                    w, h, rect2 HIGHBD_TAIL_SUFFIX); \
        return; \
    } \
    const enum TxfmType base_txtp = txtp & 0xff; \
    const itx_1d_fn_row first_1d_fn = itx_1d_x4_fns_row[lw][base_txtp & 7]; \
    const itx_1d_fn_col second_1d_fn = itx_1d_x4_fns_col[lh][base_txtp >> 5]; \
    assert(first_1d_fn); \
    assert(second_1d_fn); \
    const int tx_class = (txtp >> 3) & 3; \
    const int howmany = itx_first_pass_howmany(tx_class, sh, lw, eob, tx); \
    coef tmp[sw * sh]; \
    /* Special-case IDTX + DPCM to fuse the final identity with residual_add. */ \
    if (txtp >> 8) { \
        assert((txtp & 0xe7) == IDTX); \
        BF(dav2d_inv_identity##sw##_1d_row, neon)(tmp, sw, coeff, sh, shift0, rect2, \
                                                  howmany HIGHBD_TAIL_SUFFIX); \
        BF(dav2d_residual_add_idtx##sh, neon)(dst, stride, tmp, w, h, shift1, txtp \
                                              HIGHBD_TAIL_SUFFIX); \
        return; \
    } \
    first_1d_fn(tmp, sw, coeff, sh, shift0, rect2, howmany HIGHBD_TAIL_SUFFIX); \
    second_1d_fn(dst, stride, tmp, sw, w, h, shift1, sw HIGHBD_TAIL_SUFFIX); \
}

static void BF(dav2d_inv_txfm_add_4x4, neon)(pixel *dst,
                                             const ptrdiff_t dst_stride,
                                             coef *const coeff,
                                             const enum TxfmType txtp,
                                             const int eob
                                             HIGHBD_DECL_SUFFIX)
{
    const enum TxfmType base_txtp = txtp & 0xff;
    if (base_txtp == WHT_WHT) {
        BF(dav2d_inv_txfm_add_4x4_wht_wht, neon)(dst, dst_stride, coeff, txtp
                                                 HIGHBD_TAIL_SUFFIX);
        return;
    }

    assert(eob >= 0 && eob < 32 * 32);

    // Special-case IDTX + DPCM to fuse the final identity with residual_add.
    if (txtp >> 8) {
        assert((txtp & 0xe7) == IDTX);
        const itx_2d_fn fn =
            BF(dav2d_inv_txfm_add_4x4_identity_identity_dpcm, neon);
        fn(dst, dst_stride, coeff, txtp HIGHBD_TAIL_SUFFIX);
        return;
    }

    if (eob == 0 && txtp == DCT_DCT) {
        BF(dav2d_itx_dc_only, neon)(dst, dst_stride, coeff, 7, 10, 4, 4, 0
                                    HIGHBD_TAIL_SUFFIX);
        return;
    }

    const itx_2d_fn fn = itx_4x4_fns[base_txtp & 7][base_txtp >> 5];
    assert(fn);
    fn(dst, dst_stride, coeff, txtp HIGHBD_TAIL_SUFFIX);
}

//        w   h lw lh shift0 shift1 rect2  sw  sh  tx
ITX_WRAP( 4,  8, 0, 1,     7,    10,    1,  4,  8, RTX_4X8)
ITX_WRAP( 4, 16, 0, 2,     6,    12,    0,  4, 16, RTX_4X16)
ITX_WRAP( 4, 32, 0, 3,     7,    11,    1,  4, 32, RTX_4X32)
ITX_WRAP( 4, 64, 0, 4,     6,    13,    0,  4, 32, RTX_4X64)
ITX_WRAP( 8,  4, 1, 0,     7,    10,    1,  8,  4, RTX_8X4)
ITX_WRAP( 8,  8, 1, 1,     7,    11,    0,  8,  8, TX_8X8)
ITX_WRAP( 8, 16, 1, 2,     7,    11,    1,  8, 16, RTX_8X16)
ITX_WRAP( 8, 32, 1, 3,     6,    13,    0,  8, 32, RTX_8X32)
ITX_WRAP( 8, 64, 1, 4,     6,    12,    1,  8, 32, RTX_8X64)
ITX_WRAP(16,  4, 2, 0,     6,    12,    0, 16,  4, RTX_16X4)
ITX_WRAP(16,  8, 2, 1,     7,    11,    1, 16,  8, RTX_16X8)
ITX_WRAP(16, 16, 2, 2,     6,    13,    0, 16, 16, TX_16X16)
ITX_WRAP(16, 32, 2, 3,     6,    12,    1, 16, 32, RTX_16X32)
ITX_WRAP(16, 64, 2, 4,     6,    13,    0, 16, 32, RTX_16X64)
ITX_WRAP(32,  4, 3, 0,     7,    11,    1, 32,  4, RTX_32X4)
ITX_WRAP(32,  8, 3, 1,     6,    13,    0, 32,  8, RTX_32X8)
ITX_WRAP(32, 16, 3, 2,     6,    12,    1, 32, 16, RTX_32X16)
ITX_WRAP(32, 32, 3, 3,     6,    13,    0, 32, 32, TX_32X32)
ITX_WRAP(32, 64, 3, 4,     6,    12,    1, 32, 32, RTX_32X64)
ITX_WRAP(64,  4, 4, 0,     6,    13,    0, 32,  4, RTX_64X4)
ITX_WRAP(64,  8, 4, 1,     6,    12,    1, 32,  8, RTX_64X8)
ITX_WRAP(64, 16, 4, 2,     6,    13,    0, 32, 16, RTX_64X16)
ITX_WRAP(64, 32, 4, 3,     6,    12,    1, 32, 32, RTX_64X32)
ITX_WRAP(64, 64, 4, 4,     6,    13,    0, 32, 32, TX_64X64)

#undef ITX_WRAP
#undef decl_itx_1d_col_fn
#undef decl_itx_1d_pair
#undef decl_itx_1d_row_fn
#undef decl_itx_2d
#undef decl_itx_2d_fn
#undef decl_residual_add_fn
#undef decl_residual_add_idtx_fn

#endif

decl_cctx_fn(BF(dav2d_cctx, neon));

static ALWAYS_INLINE void itx_dsp_init_arm(Dav2dInvTxfmDSPContext *const c)
{
    const unsigned flags = dav2d_get_cpu_flags();

    if (!(flags & DAV2D_ARM_CPU_FLAG_NEON)) return;

#if BITDEPTH == 8
    assign_itx_fn( ,  4,  4, neon);
    assign_itx_fn(R,  4,  8, neon);
    assign_itx_fn(R,  4, 16, neon);
    assign_itx_fn(R,  4, 32, neon);
    assign_itx_fn(R,  4, 64, neon);
    assign_itx_fn(R,  8,  4, neon);
    assign_itx_fn( ,  8,  8, neon);
    assign_itx_fn(R,  8, 16, neon);
    assign_itx_fn(R,  8, 32, neon);
    assign_itx_fn(R,  8, 64, neon);
    assign_itx_fn(R, 16,  4, neon);
    assign_itx_fn(R, 16,  8, neon);
    assign_itx_fn( , 16, 16, neon);
    assign_itx_fn(R, 16, 32, neon);
    assign_itx_fn(R, 16, 64, neon);
    assign_itx_fn(R, 32,  4, neon);
    assign_itx_fn(R, 32,  8, neon);
    assign_itx_fn(R, 32, 16, neon);
    assign_itx_fn( , 32, 32, neon);
    assign_itx_fn(R, 32, 64, neon);
    assign_itx_fn(R, 64,  4, neon);
    assign_itx_fn(R, 64,  8, neon);
    assign_itx_fn(R, 64, 16, neon);
    assign_itx_fn(R, 64, 32, neon);
    assign_itx_fn( , 64, 64, neon);
#endif

    c->cctx = BF(dav2d_cctx, neon);
}
