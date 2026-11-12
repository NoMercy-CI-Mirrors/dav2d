#include "src/cpu.h"
#include "src/cdef.h"

decl_cdef_dir_fn(BF(dav2d_cdef_find_dir_vl128, rvv));
decl_cdef_dir_fn(BF(dav2d_cdef_find_dir_vl256, rvv));
decl_cdef_dir_fn(BF(dav2d_cdef_find_dir_vl512, rvv));
decl_cdef_dir_fn(BF(dav2d_cdef_find_dir_vl1024, rvv));

decl_cdef_fn(BF(dav2d_cdef_filter_4x4, rvv));
decl_cdef_fn(BF(dav2d_cdef_filter_4x8, rvv));
decl_cdef_fn(BF(dav2d_cdef_filter_8x8, rvv));

static ALWAYS_INLINE void cdef_dsp_init_riscv(Dav2dCdefDSPContext *const c) {
    const unsigned flags = dav2d_get_cpu_flags();
    if (!(flags & DAV2D_RISCV_CPU_FLAG_V)) return;

    if(dav2d_get_vlen() == 128)
        c->dir   = BF(dav2d_cdef_find_dir_vl128, rvv);
    else if(dav2d_get_vlen() == 256)
        c->dir   = BF(dav2d_cdef_find_dir_vl256, rvv);
    else if(dav2d_get_vlen() == 512)
        c->dir   = BF(dav2d_cdef_find_dir_vl512, rvv);
    else if(dav2d_get_vlen() >= 1024)
        c->dir   = BF(dav2d_cdef_find_dir_vl1024, rvv);

    c->fb[0] = BF(dav2d_cdef_filter_8x8, rvv);
    c->fb[1] = BF(dav2d_cdef_filter_4x8, rvv);
    c->fb[2] = BF(dav2d_cdef_filter_4x4, rvv);
}
